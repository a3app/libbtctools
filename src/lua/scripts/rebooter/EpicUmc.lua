EpicUmc = oo.class({}, ExecutorBase)

function EpicUmc:__init(parent, context)
    local obj = ExecutorBase.__init(self, parent, context)
    obj:setStep("reboot")
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

function EpicUmc:reboot()
    local loginPassword = utils.getMinerLoginPassword('EpicUmc')
    if loginPassword == nil then
        self:setStep('end', 'require password')
        return
    end

    local body = utils.jsonEncode({
        param = 0,
        password = loginPassword.password
    })

    self:makeEpicRequest({
        method = "POST",
        path = "/reboot",
        headers = { ["content-type"] = "application/json" },
        body = body
    })

    self:setStep("parseReboot", "rebooting...")
end

function EpicUmc:parseReboot(httpResponse, stat)
    local obj = self:parseHttpResponseJson(httpResponse, stat)

    if not obj then
        return
    end

    if obj.result ~= true then
        local errMsg = "reboot failed"
        if type(obj.error) == "string" then
            errMsg = obj.error
        end
        self:setStep("end", errMsg)
        return
    end

    self.context:miner():setOpt("check-reboot-finish-times", "0")
    self:setStep("waitFinish")
    self:disableRetry()
end

function EpicUmc:waitFinish()
    local context = self.context
    context:setRequestDelayTimeout(5)
    context:setRequestSessionTimeout(5)

    self:makeEpicRequest({ method = "GET", path = "/summary" })
    self:setStep("doWaitFinish", "wait finish...")
end

function EpicUmc:doWaitFinish(httpResponse, stat)
    local miner = self.context:miner()

    if stat == "success" then
        self:setStep("end", "rebooted")
        return
    end

    local times = tonumber(miner:opt("check-reboot-finish-times"))

    if times > 30 then
        self:setStep("end", "timeout, may succeeded")
        return
    end

    miner:setOpt("check-reboot-finish-times", tostring(times + 1))
    self:setStep("waitFinish", "not finish")
end
