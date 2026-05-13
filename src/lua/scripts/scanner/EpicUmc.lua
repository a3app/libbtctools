EpicUmc = oo.class({}, ExecutorBase)

function EpicUmc:__init(parent, context)
    local miner = context:miner()

    miner:setTypeStr("EpicUmc")

    local obj = ExecutorBase.__init(self, parent, context)
    obj:setStep("getSummary")
    return obj
end

function EpicUmc:makeEpicRequest(request)
    local context = self.context
    local miner = context:miner()
    local ip = miner:ip()

    request.host = ip
    request.ip = ip
    context:setRequestHost(ip)
    context:setRequestPort("4028")
    context:setRequestContent(http.makeRequest(request))
end

function EpicUmc:getSummary()
    self:makeEpicRequest({ method = "GET", path = "/summary" })
    self:setStep("parseSummary", "scan...")
end

function EpicUmc:parseSummary(httpResponse, stat)
    local miner = self.context:miner()
    local obj = self:parseHttpResponseJson(httpResponse, stat)

    if not obj or type(obj) ~= "table" or obj.Hostname == nil or obj.Session == nil then
        miner:setOpt("httpDetect", "unknown")
        miner:setTypeStr("unknown")
        miner:setFullTypeStr("")
        self:setStep("end", "not an ePIC miner")
        return
    end

    miner:setOpt("minerTypeFound", "true")

    -- Pool configuration
    if type(obj.StratumConfigs) == "table" then
        local pool1, pool2, pool3 = miner:pool1(), miner:pool2(), miner:pool3()
        local configs = obj.StratumConfigs

        if configs[1] then
            pool1:setUrl(configs[1].pool or "")
            pool1:setWorker(configs[1].login or "")
            pool1:setPasswd(configs[1].password or "")
        end
        if configs[2] then
            pool2:setUrl(configs[2].pool or "")
            pool2:setWorker(configs[2].login or "")
            pool2:setPasswd(configs[2].password or "")
        end
        if configs[3] then
            pool3:setUrl(configs[3].pool or "")
            pool3:setWorker(configs[3].login or "")
            pool3:setPasswd(configs[3].password or "")
        end
    end

    -- Hashrate (MH/s from API, convert to TH/s for display)
    if type(obj.Session) == "table" then
        local avgMhs = obj.Session["Average MHs"]
        if type(avgMhs) == "number" and avgMhs > 0 then
            miner:setOpt("hashrate_avg", string.format("%.2f TH/s", avgMhs / 1000000.0))
        end
    end

    -- Temperature per hashboard
    if type(obj.HBs) == "table" then
        local temps = {}
        for _, hb in ipairs(obj.HBs) do
            if hb.Temperature ~= nil then
                table.insert(temps, tostring(hb.Temperature))
            end
        end
        if #temps > 0 then
            miner:setOpt("temperature", table.concat(temps, " / "))
        end
    end

    -- Fan speed
    if type(obj.Fans) == "table" and obj.Fans["Fans Speed"] ~= nil then
        miner:setOpt("fan_speed", tostring(obj.Fans["Fans Speed"]) .. " RPM")
    end

    -- Software version
    if type(obj.Software) == "string" then
        miner:setOpt("software_version", obj.Software)
    end

    -- Current coin (preserved for configurator use)
    if type(obj.Mining) == "table" and type(obj.Mining.Coin) == "string" then
        miner:setOpt("epic.coin", obj.Mining.Coin)
    end

    self:setStep("getCapabilities", "success")
end

function EpicUmc:getCapabilities()
    self:makeEpicRequest({ method = "GET", path = "/capabilities" })
    self:setStep("parseCapabilities", "get model...")
end

function EpicUmc:parseCapabilities(httpResponse, stat)
    local miner = self.context:miner()
    local obj = self:parseHttpResponseJson(httpResponse, stat)

    if obj and type(obj) == "table" and type(obj.Model) == "string" and obj.Model ~= "" then
        miner:setFullTypeStr("ePIC " .. obj.Model)
    else
        miner:setFullTypeStr("ePIC UMC")
    end

    self:setStep("end", "success")
end
