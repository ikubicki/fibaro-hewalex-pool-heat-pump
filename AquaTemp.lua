--[[
AquaTemp SDK
@author ikubicki
]]
class 'AquaTemp'

AquaTemp.debug = false

function AquaTemp:new(config)
    self.username = config:getUsername()
    self.password = config:getPassword()
    self.http = HTTPClient:new({
        baseUrl = config:getUrl()
    })
    return self
end

function AquaTemp:login(loadDevice, fail)
    local timestamp = os.time(os.date("!*t"))
    -- QuickApp:debug('aquatemp_xtoken=', Globals:get('aquatemp_xtoken'))
    -- QuickApp:debug('aquatemp_xtoken_time=', Globals:get('aquatemp_xtoken_time'))
    -- QuickApp:debug('Session life time=', timestamp - Globals:get('aquatemp_xtoken_time', 0))
    if timestamp - Globals:get('aquatemp_xtoken_time', 0) < 1 and string.len(Globals:get('aquatemp_xtoken', '')) > 0 then
        QuickApp:debug('Reusing existing xtoken')
        return Globals:get('aquatemp_xtoken', '')
    end

    local data = {
        user_name = self.username,
        password = self.password,
        type = 2
    }
    local headers = {
        ["Content-Type"] = "application/json; charset=utf-8"
    }
    local error = function(err)
        QuickApp:error('Unable to connect to remote server [' .. response.status .. ']')
        QuickApp:debug(err)
        if fail ~= nil then
            fail(err)
        end
    end
    local success = function(response)
        if response.status > 400 then
            QuickApp:error('login: Unable to connect to remote server [' .. response.status .. ']')
            return
        end
        local data = string.gsub(response.data, "null", "false")
        local jsonData = json.decode(data)
        if jsonData.object_result and jsonData.object_result["x-token"] then
            Globals:set('aquatemp_xtoken', jsonData.object_result["x-token"])
            Globals:set('aquatemp_xtoken_time', timestamp)
            if loadDevice then
                AquaTemp:getDeviceCode()
            end
        else
            QuickApp:error('login: Malformed response [' .. json.encode(jsonData) .. ']')
        end
    end
    self.http:post('/app/user/login.json', data, success, error, headers)
    return ''
end

function AquaTemp:getDeviceCode(fail)
    if string.len(Globals:get('aquatemp_device', '')) > 0 then
        return Globals:get('aquatemp_device', '')
    end
    local xtoken = Globals:get('aquatemp_xtoken', '')
    if xtoken == '' then
        -- QuickApp:debug('getDeviceCode: Not authorized')
        return ''
    end

    local headers = {
        ["Content-Type"] = "application/json; charset=utf-8",
        ["x-token"] = Globals:get('aquatemp_xtoken', '')
    }

    local error = function(err)
        QuickApp:error('getDeviceCode: Unable to connect to remote server [' .. response.status .. ']')
        QuickApp:debug(err)
        if fail ~= nil then
            fail(err)
        end
    end
    local success = function(response)
        if response.status > 400 then
            QuickApp:error('getDeviceCode: Unable to connect to remote server [' .. response.status .. ']')
            return
        end
        local data = string.gsub(response.data, "null", "false")
        local jsonData = json.decode(data)
        if jsonData.object_result and jsonData.object_result[1].device_code then
            Globals:set('aquatemp_device', jsonData.object_result[1].device_code)
        else
            QuickApp:error('getDeviceCode: Malformed response [' .. json.encode(jsonData) .. ']')
        end
    end
    self.http:get('/app/device/deviceList.json', success, error, headers)
    return ''
end

function AquaTemp:getParameters(callback, fail)

    local xtoken = Globals:get('aquatemp_xtoken', '')
    local device = Globals:get('aquatemp_device', '')
    if xtoken == '' then
        QuickApp:debug('getParameters: Not authorized')
        return {}
    end
    if device == '' then
        QuickApp:debug('getParameters: No device')
        return {}
    end
    
    local data = {
        device_code = device,
        protocal_codes = { "Power", "Mode", "T02", "T03", "T05", "T12", "R02", "R10", "R11", "H02", "H03" }
    }
    local headers = {
        ["Content-Type"] = "application/json; charset=utf-8",
        ["x-token"] = Globals:get('aquatemp_xtoken', '')
    }

    local error = function(err)
        QuickApp:error('getDeviceCode: Unable to connect to remote server [' .. response.status .. ']')
        QuickApp:debug(err)
        if fail ~= nil then
            fail(err)
        end
    end
    local success = function(response)
        if response.status > 400 then
            QuickApp:error('getDeviceCode: Unable to connect to remote server [' .. response.status .. ']')
            if callback ~= nil then
                fail(response)
            end
            return ''
        end
        local data = string.gsub(response.data, "null", "false")
        local jsonData = json.decode(data)
        local parameters = {}
        if jsonData and jsonData.object_result then
            for _, param in pairs(jsonData.object_result) do
                parameters[param.code] = param.value
            end
        end
        if callback ~= nil then
            callback(parameters)
        end
    end
    self.http:post('/app/device/getDataByCode.json', data, success, error, headers)
end