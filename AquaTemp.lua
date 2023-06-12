--[[
AquaTemp SDK
@author ikubicki
]]
class 'AquaTemp'

AquaTemp.debug = false

function AquaTemp:new(config)
    self.config = config
    self.token = Globals:get('aquatemp_xtoken', '')
    self.token_time = tonumber(Globals:get('aquatemp_xtoken_time', 0))
    self.http = HTTPClient:new({
        baseUrl = config:getUrl()
    })
    return self
end


function AquaTemp:searchDevices(callback)
    local buildDevice = function(data)
        return {
            id = data.device_id,
            name = data.device_nick_name,
            code = data.device_code,
            product = data.product_id,
            status = data.device_status
        }
    end
    local deviceListCallback = function(response)
        local devices = {}
        if response.error_msg ~= "Success" then
            QuickApp:error("Unable to pull AquaTemp devices: " .. response.error_msg)
            return callback(devices)
        end
        for _, d in ipairs(response.object_result) do
            table.insert(devices, buildDevice(d))
        end
        callback(devices)
    end
    local authCallback = function(response)
        AquaTemp:deviceList(deviceListCallback)
    end
    AquaTemp:auth(authCallback)
end

function AquaTemp:getProperties(callback, fail)
    if self.config:getDeviceID() == "" or self.config:getDeviceID() == nil then
        if fail ~= nil then
            fail()
        end
        return
    end
    local getDeviceStatusCallback = function(statusResponse)  
        local getDataByCodeCallback = function(dataResponse)
            dataResponse["status"] = statusResponse["status"]
            dataResponse["is_fault"] = statusResponse["is_fault"]
            callback(dataResponse)
        end
        AquaTemp:getDataByCode(getDataByCodeCallback, fail)
    end
    local authCallback = function(response)
        AquaTemp:getDeviceStatus(getDeviceStatusCallback, fail)
    end
    AquaTemp:auth(authCallback)
end

function AquaTemp:setPower(power, callback, fail)
    if self.config:getDeviceID() == "" or self.config:getDeviceID() == nil then
        if fail ~= nil then
            fail()
        end
        return
    end
    local data = {
        param = {{
            device_code = self.config:getDeviceID(),
            protocol_code = "power",
            value = power,
        }}
    }
    local authCallback = function(response)
        AquaTemp:control(data, callback, fail)
    end
    AquaTemp:auth(authCallback)
end

function AquaTemp:setTemperature(temperature, callback, fail)
    if self.config:getDeviceID() == "" or self.config:getDeviceID() == nil then
        if fail ~= nil then
            fail()
        end
        return
    end
    local data = {
        param = {{
            device_code = self.config:getDeviceID(),
            protocol_code = "Set_Temp",
            value = temperature,
        },{
            device_code = self.config:getDeviceID(),
            protocol_code = "R02",
            value = temperature,
        },{
            device_code = self.config:getDeviceID(),
            protocol_code = "R03",
            value = temperature,
        }}
    }
    local authCallback = function(response)
        AquaTemp:control(data, callback, fail)
    end
    AquaTemp:auth(authCallback)
end

function AquaTemp:setMute(mute, callback, fail)
    if self.config:getDeviceID() == "" or self.config:getDeviceID() == nil then
        if fail ~= nil then
            fail()
        end
        return
    end
    local data = {
        param = {{
            device_code = self.config:getDeviceID(),
            protocol_code = "Manual-mute",
            value = mute,
        }}
    }
    local authCallback = function(response)
        AquaTemp:control(data, callback, fail)
    end
    AquaTemp:auth(authCallback)
end


-- pass: 022
function AquaTemp:translateProperties(properties)
    local newProperties = {
        temperature_unit = "C",
    }
    if properties["T02"] ~= nil then newProperties["inlet_temperature"] = properties["T02"] end
    if properties["T03"] ~= nil then newProperties["outlet_temperature"] = properties["T03"] end
    if properties["T04"] ~= nil then newProperties["coil_temperature"] = properties["T04"] end
    if properties["T05"] ~= nil then newProperties["ambient_temperature"] = properties["T05"] end
    if properties["R01"] ~= nil then newProperties["target_temperture_cool"] = properties["R01"] end
    if properties["R02"] ~= nil then newProperties["target_temperture_heat"] = properties["R02"] end
    if properties["R03"] ~= nil then newProperties["target_temperture_auto"] = properties["R03"] end
    if properties["R10"] ~= nil then newProperties["minimum_temperture"] = properties["R10"] end
    if properties["R11"] ~= nil then newProperties["maximum_temperture"] = properties["R11"] end
    if properties["Mode"] ~= nil then newProperties["mode"] = properties["Mode"] end
    if properties["Power"] ~= nil then newProperties["power"] = properties["Power"] end
    if properties["Manual-mute"] ~= nil then newProperties["mute"] = properties["Manual-mute"] end
    if properties["Set_Temp"] ~= nil then newProperties["temperature_setpoint"] = properties["Set_Temp"] end
    if properties["H03"] == 1 then newProperties["temperature_unit"] = "F" end
    return newProperties
end

function AquaTemp:formatProperties(data)
    local properties = {}
    for _, data in pairs(data) do
        properties[data.code] = data.value
    end
    return self:translateProperties(properties)
end

function AquaTemp:getDataByCode(callback, fail, attempt)
    if attempt == nil then
        attempt = 1
    end
    if fail == nil then
        fail = function(response)
            QuickApp:error('Unable to pull data by code')
            AquaTemp:setToken('')
            if attempt < 2 then
                attempt = attempt + 1
                fibaro.setTimeout(3000, function()
                    QuickApp:debug('AquaTemp:getDataByCode - Retry attempt #' .. attempt)
                    local authCallback = function(response)
                        self:getDataByCode(callback, nil, attempt)
                    end
                    AquaTemp:auth(authCallback)
                end)
            end
        end
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        if data.error_msg ~= "Success" then
            fail(response)
            return
        elseif callback ~= nil then
            callback(self:formatProperties(data.object_result))
        end
    end
    local url = "/app/device/getDataByCode.json"
    local headers = {
        ["x-token"] = self:getToken(),
        ["Content-Type"] = "application/json; charset=utf-8",
    }
    local data = {
        device_code = self.config:getDeviceID(),
        protocal_codes = {
            "Power",
            "Mode",
            "Manual-mute",
            "Set_Temp",
            "H03",
            "R01","R02","R03","R10","R11",
            "T02","T03","T04","T05"
        }
    }
    self.http:post(url, data, success, fail, headers)
end

function AquaTemp:getDeviceStatus(callback, fail, attempt)
    if attempt == nil then
        attempt = 1
    end
    if fail == nil then
        fail = function(response)
            QuickApp:error('Unable to pull device status')
            AquaTemp:setToken('')
            if attempt < 2 then
                attempt = attempt + 1
                fibaro.setTimeout(3000, function()
                    QuickApp:debug('AquaTemp:getDeviceStatus - Retry attempt #' .. attempt)
                    local authCallback = function(response)
                        self:getDeviceStatus(callback, nil, attempt)
                    end
                    AquaTemp:auth(authCallback)
                end)
            end
        end
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        if data.error_code ~= "0" then
            fail(response)
            return
        elseif callback ~= nil then
            callback(data.object_result)
        end
    end
    local url = "/app/device/getDeviceStatus.json"
    local headers = {
        ["x-token"] = self:getToken(),
        ["Content-Type"] = "application/json; charset=utf-8",
    }
    local data = {
        device_code = self.config:getDeviceID(),
    }
    self.http:post(url, data, success, fail, headers)
end

function AquaTemp:deviceList(callback, fail, attempt)
    if attempt == nil then
        attempt = 1
    end
    if fail == nil then
        fail = function(response)
            QuickApp:error('Unable to pull devices')
            AquaTemp:setToken('')
            if attempt < 2 then
                attempt = attempt + 1
                fibaro.setTimeout(3000, function()
                    QuickApp:debug('AquaTemp:deviceList - Retry attempt #' .. attempt)
                    local authCallback = function(response)
                        self:deviceList(callback, nil, attempt)
                    end
                    AquaTemp:auth(authCallback)
                end)
            end
        end
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        if callback ~= nil then
            callback(data)
        end
    end
    local url = "/app/device/deviceList.json"
    local headers = {
        ["x-token"] = self:getToken()
    }
    self.http:get(url, success, fail, headers)
end

function AquaTemp:control(data, callback, fail, attempt)
    if attempt == nil then
        attempt = 1
    end
    if fail == nil then
        fail = function(response)
            QuickApp:error('Unable to control the device')
            QuickApp:error(json.encode(response))
            AquaTemp:setToken('')
            if attempt < 2 then
                attempt = attempt + 1
                fibaro.setTimeout(3000, function()
                    QuickApp:debug('AquaTemp:control - Retry attempt #' .. attempt)
                    local authCallback = function(response)
                        self:deviceList(control, callback, nil, attempt)
                    end
                    AquaTemp:auth(authCallback)
                end)
            end
        end
    end
    local success = function(response)
        if response.status > 299 then
            fail(response)
            return
        end
        local data = json.decode(response.data)
        if callback ~= nil then
            callback(data)
        end
    end
    local url = "/app/device/control.json"
    local headers = {
        ["x-token"] = self:getToken(),
        ["Content-Type"] = "application/json; charset=utf-8",
    }
    self.http:post(url, data, success, fail, headers)
end



function AquaTemp:auth(callback)
    if string.len(self.token) > 1 then
        -- QuickApp:debug('Already authenticated')
        if callback ~= nil then
            callback({})
        end
        return
    end
    local fail = function(response)
        -- QuickApp:debug(json.encode(response))
        QuickApp:error('Unable to authenticate')
        AquaTemp:setToken('')
    end
    local success = function(response)
        local data = json.decode(response.data)
        if data.error_msg ~= "Success" then
            fail(response)
            return
        end
        AquaTemp:setToken(data.object_result["x-token"])
        if callback ~= nil then
            callback(data)
        end
    end
    local url = "/app/user/login.json"
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        user_name = self.config:getUsername(),
        password = self.config:getPassword(),
        type = 2
    }
    self.http:post(url, data, success, fail, headers)
end

-- token functions



function AquaTemp:setToken(token)
    self.token = token
    self.token_time = os.time(os.date("!*t"))
    Globals:set('aquatemp_xtoken', token)
    Globals:set('aquatemp_xtoken_time', self.token_time)
end

function AquaTemp:getToken()
    if not self:checkTokenTime() then
        self:setToken('')
        return ''
    end
    if string.len(self.token) > 10 then
        return self.token
    elseif string.len(Globals:get('aquatemp_xtoken', '')) > 10 then
        return Globals:get('aquatemp_xtoken', '')
    end
    return ''
end

function AquaTemp:checkTokenTime()
    if self.token_time < 1 then
        self.token_time = tonumber(Globals:get('aquatemp_xtoken_time', 0))
    end
    return self.token_time > 0 and os.time(os.date("!*t")) - self.token_time < 43200
end