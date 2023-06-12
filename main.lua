--[[
    Hewalex Pool Heat Pump integration
    @author ikubicki
]]

function QuickApp:setThermostatMode(mode)
    if self.properties.thermostatMode ~= "Heat" and mode == "Heat" then
        QuickApp:debug("Heat on")
        self:_setMode("Heat")
    elseif self.properties.thermostatMode ~= "Silent" and mode == "Silent" then
        QuickApp:debug("Heat on (silent)")
        self:_setMode("Silent")
    elseif self.properties.thermostatMode ~= "Off" and mode == "Off" then
        QuickApp:debug("Heat off")
        self:_setMode("Off")
    else 
        QuickApp:debug("Heat reamins " .. self.properties.thermostatMode)
    end
end

function QuickApp:setHeatingThermostatSetpoint(value) 
    self:debug("Value set to " .. value)
    if value > 35 then
        value = 35
    end
    if value < 15 then
        self:_setTemperature(16)
        self:setThermostatMode("Off")
        return false
    end
    if value >= 15 then
        self:setThermostatMode("Heat")
    end
    self:_setTemperature(value)
end


function QuickApp:_setMode(value)
    
    local modeCallback = function(data)
        self:updateDevices()
    end
    if value == "Off" then
        local muteCallback = function(data)
            self.aquatemp:setPower(0, modeCallback)
        end
        self.aquatemp:setMute(0, muteCallback)
    elseif value == "Silent" then
        local muteCallback = function(data)
            self.aquatemp:setPower(1, modeCallback)
        end
        self.aquatemp:setMute(1, muteCallback)
    else
        local muteCallback = function(data)
            self.aquatemp:setPower(1, modeCallback)
        end
        self.aquatemp:setMute(0, muteCallback)
    end
    self:ui_setMode(value)
end

function QuickApp:ui_setMode(value)
    self:updateProperty("thermostatMode", value)
end

function QuickApp:_setTemperature(value)
    local temperatureCallback = function(data)
        self:updateDevices()
    end
    self.aquatemp:setTemperature(value, temperatureCallback)
    self:ui_setTemperature(value)
end

function QuickApp:ui_setTemperature(value)
    self:updateProperty("heatingThermostatSetpoint", { value = value })
end

function QuickApp:onInit()

    self.config = Config:new(self)
    self.aquatemp = AquaTemp:new(self.config)
    self.i18n = i18n:new(api.get("/settings/info").defaultLanguage)
    self:trace('')
    self:trace(string.format(self.i18n:get('name'), self.name))
    self:updateProperty('manufacturer', 'Hewalex')
    self:updateProperty('model', 'Pool water heat pump')

    self.childrenIDs = {}
    self.powerStatus = nil

    -- set supported modes for thermostat
    self:updateProperty("supportedThermostatModes", {"Off", "Heat", "Silent"})
    self:updateProperty("heatingThermostatSetpointCapabilitiesMin", 15)
    self:updateProperty("heatingThermostatSetpointCapabilitiesMax", 35)
    self:updateProperty("heatingThermostatSetpointStep", {
        C = 1,
        F = 1
    })
    
    self:setupChildren()

    -- setup default values
    self:ui_setTemperature(15)
    self:ui_setMode("Off")
    self:run()
end

function QuickApp:run()
    self:updateDevices()
    local interval = self.config:getInterval()
    if self.properties.dead then
        interval = 3600000
    end
    if interval > 0 then
        fibaro.setTimeout(interval, function() self:run() end)
    end
end

function QuickApp:updateButton1(text)
    self:updateView("btn_1", "text", text)
end

function QuickApp:updateButton2(text)
    self:updateView("btn_2", "text", text)
end

function QuickApp:updateLabel(text)
    self:updateView("label", "text", text)
end

function QuickApp:updateT1(text)
    local unit = self.properties.unit
    self:updateView("t1", "text", text .. " º" .. unit)
end

function QuickApp:updateT2(text)
    local unit = self.properties.unit
    self:updateView("t2", "text", text .. " º" .. unit)
end

function QuickApp:updateT3(text)
    local unit = self.properties.unit
    self:updateView("t3", "text", text .. " º" .. unit)
end

function QuickApp:updateT4(text)
    local unit = self.properties.unit
    self:updateView("t4", "text", text .. " º" .. unit)
end

function QuickApp:updateDevices()

    if self.config:getDeviceID() == nil or self.config:getDeviceID() == "" then
        return
    end

    self:updateButton1(self.i18n:get('refreshing'))

    local fail = function(data)
        self:updateButton1(self.i18n:get('refresh'))
        QuickApp:error('Unable to pull data for AquaTemp device')
        QuickApp:error(json.encode(data))
    end

    local getPropertiesCallback = function(data)
        -- QuickApp:debug(json.encode(data))
        self:updateButton1(self.i18n:get('refresh'))
        if data["status"] == "OFFLINE" then
            self:updateProperty("dead", true)
            self:updateProperty("deadReason", "Device offline")
            self:updateLabel(string.format(self.i18n:get('device-error'), 'ERROR'))
            self:updateLabel(self.i18n:get('device-unavailable'))

            self.childDevices[self.childrenIDs[1]]:setDead(true, "Device offline")
            self.childDevices[self.childrenIDs[2]]:setDead(true, "Device offline")
            self.childDevices[self.childrenIDs[3]]:setDead(true, "Device offline")
            self:ui_setMode("Off");
        else
            self:updateProperty("dead", false)
            self:updateProperty("deadReason", "")
            self:updateLabel(string.format(self.i18n:get('last-update'), os.date('%Y-%m-%d %H:%M:%S')))

            local powerChange = (self.powerStatus == data["power"])
            self.powerStatus = data["power"]

            if data["power"] == "0" then
                self:ui_setMode("Off")
                self:updateLabel(self.i18n:get('device-off'))
            elseif data["power"] == "1" and data["mute"] == "1" then
                self:ui_setMode("Silent")
            else
                self:ui_setMode("Heat")
            end
            if data["is_fault"] then
                -- @todo fault message handling
                self:updateLabel(string.format(self.i18n:get('last-update'), '<unknown>'))
            end
            self.childDevices[self.childrenIDs[1]]:setDead(false, "")
            self.childDevices[self.childrenIDs[2]]:setDead(false, "")
            self.childDevices[self.childrenIDs[3]]:setDead(false, "")
            if data["power"] == "1" then
                self.childDevices[self.childrenIDs[1]]:setUnit(data["temperature_unit"])
                self.childDevices[self.childrenIDs[1]]:setValue(data["inlet_temperature"])
                self.childDevices[self.childrenIDs[2]]:setUnit(data["temperature_unit"])
                self.childDevices[self.childrenIDs[2]]:setValue(data["outlet_temperature"])
                self.childDevices[self.childrenIDs[3]]:setUnit(data["temperature_unit"])
                self.childDevices[self.childrenIDs[3]]:setValue(data["ambient_temperature"]) 
            elseif powerChange then
                self.childDevices[self.childrenIDs[1]]:setValue(0)
                self.childDevices[self.childrenIDs[2]]:setValue(0)
                self.childDevices[self.childrenIDs[3]]:setValue(0) 
            end
            self:updateT2(data["inlet_temperature"])
            self:updateT3(data["outlet_temperature"])
            self:updateT4(data["ambient_temperature"])
        end
        self:updateProperty("unit", data["temperature_unit"])
        self:ui_setTemperature(tonumber(data["temperature_setpoint"]))
        self:updateProperty("heatingThermostatSetpointCapabilitiesMin", tonumber(data["minimum_temperture"]))
        self:updateProperty("heatingThermostatSetpointCapabilitiesMax", tonumber(data["maximum_temperture"]))
        self:updateT1(data["temperature_setpoint"])
    end

    self.aquatemp:getProperties(getPropertiesCallback, fail)
end

function QuickApp:setupChildren()

    self:initChildDevices({
        ["com.fibaro.temperatureSensor"] = AquaTempChild,
    })

    id = 0
    for _, device in pairs(self.childDevices) do
        id = id + 1
        table.insert(self.childrenIDs, device.id)
    end

    if self.config:getDeviceID() == "" or self.config:getDeviceID() == nil then
        if id > 0 then
            QuickApp:warning("Found " .. id .. " child devices for no device")
            for _, deviceId in pairs(self.childrenIDs) do
                -- api.delete("/devices/" .. deviceId)
            end
        end
    else 
        table.sort(self.childrenIDs)
        
        if #self.childrenIDs < 3 then
            QuickApp:warning("Adding child devices for device " .. self.config:getDeviceID())
        else 
            return
        end
        if #self.childrenIDs < 1 then
            table.insert(self.childrenIDs, self:createChild(self.i18n:get("device1-label"), "com.fibaro.temperatureSensor").id)
        end
        if #self.childrenIDs < 2 then
            table.insert(self.childrenIDs, self:createChild(self.i18n:get("device2-label"), "com.fibaro.temperatureSensor").id)
        end
        if #self.childrenIDs < 3 then
            table.insert(self.childrenIDs, self:createChild(self.i18n:get("device3-label"), "com.fibaro.temperatureSensor").id)
        end
    end
end

function QuickApp:createChild(name, type, class)
    return self:createChildDevice({
        name = name, type = type
    }, AquaTempChild)
end

function QuickApp:refreshEvent(event)
    self:updateDevices()
end

function QuickApp:t1Event(event)
    self:updateLabel(string.format(self.i18n:get('t1'), self.properties.heatingThermostatSetpoint.value, self.properties.unit))
end

function QuickApp:t2Event(event)
    self:updateLabel(string.format(self.i18n:get('t2'), self.childDevices[self.childrenIDs[1]].properties.value, self.properties.unit))
end

function QuickApp:t3Event(event)
    self:updateLabel(string.format(self.i18n:get('t3'), self.childDevices[self.childrenIDs[2]].properties.value, self.properties.unit))
end

function QuickApp:t4Event(event)
    self:updateLabel(string.format(self.i18n:get('t4'), self.childDevices[self.childrenIDs[3]].properties.value, self.properties.unit))
end

function QuickApp:searchEvent(param)
    self:debug(self.i18n:get('searching-devices'))
    self:updateButton2(self.i18n:get('searching-devices'))
    local searchDevicesCallback = function(devices)
        -- QuickApp:debug(json.encode(devices))
        self:updateButton2(self.i18n:get('search-devices'))
        -- printing results
        for _, device in pairs(devices) do
            QuickApp:trace(string.format(self.i18n:get('search-row-device'), device.name, device.code, device.status))
        end

        if #devices == 1 then
            self:updateLabel(string.format(self.i18n:get('assigning-device'), devices[1].code))
            self.config:setDeviceID(devices[1].code)
            self:setupChildren()
        else
            self:updateLabel(string.format(self.i18n:get('check-logs'), 'QUICKAPP' .. self.id))
        end
    end
    self.aquatemp:searchDevices(searchDevicesCallback)
end

function QuickApp:wakeUpDeadDevice()
    self:updateDevices()
end


