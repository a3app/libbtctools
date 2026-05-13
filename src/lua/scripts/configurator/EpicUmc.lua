EpicUmc = oo.class({}, ExecutorBase)

function EpicUmc:__init(parent, context)
    local obj = ExecutorBase.__init(self, parent, context)
    obj:setStep("setConfig")
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

function EpicUmc:setConfig()
    local context = self.context
    local miner = context:miner()
    local pool1, pool2, pool3 = miner:pool1(), miner:pool2(), miner:pool3()

    local loginPassword = utils.getMinerLoginPassword('EpicUmc')
    if loginPassword == nil then
        self:setStep('end', 'require password')
        return
    end

    local coin = miner:opt("epic.coin")
    if coin == "" then
        coin = "BTC"
    end

    local stratumConfigs = {}
    if pool1:url() ~= "" then
        table.insert(stratumConfigs, {
            pool = pool1:url(),
            login = pool1:worker(),
            password = pool1:passwd()
        })
    end
    if pool2:url() ~= "" then
        table.insert(stratumConfigs, {
            pool = pool2:url(),
            login = pool2:worker(),
            password = pool2:passwd()
        })
    end
    if pool3:url() ~= "" then
        table.insert(stratumConfigs, {
            pool = pool3:url(),
            login = pool3:worker(),
            password = pool3:passwd()
        })
    end

    local body = utils.jsonEncode({
        param = {
            coin = coin,
            stratum_configs = stratumConfigs,
            unique_id = false
        },
        password = loginPassword.password
    })

    self:makeEpicRequest({
        method = "POST",
        path = "/coin",
        headers = { ["content-type"] = "application/json" },
        body = body
    })

    self:setStep("parseSetConfig", "setting config...")
end

function EpicUmc:parseSetConfig(httpResponse, stat)
    local obj = self:parseHttpResponseJson(httpResponse, stat)

    if not obj then
        return
    end

    if obj.result == true then
        self:setStep("end", "success")
    else
        local errMsg = "config failed"
        if type(obj.error) == "string" then
            errMsg = obj.error
        end
        self:setStep("end", errMsg)
    end
end
