--[[
    Hewalex Pool Heat Pump temperature sensor
    @author ikubicki
]]
function QuickApp:onInit()
    self.config = Config:new(self)
    self.aquatemp = AquaTemp:new(self.config)
    self.aquatemp:login(true)
    self.aquatemp:getDeviceCode()

    self.i18n = i18n:new(api.get("/settings/info").defaultLanguage)
    self:trace('')
    self:trace(self.i18n:get('name'))
    self:updateProperty('manufacturer', 'Hewalex')
    self:updateProperty('model', 'Temperature sensor')
    self:updateView("button1", "text", self.i18n:get('refresh'))
    self:run()
    self:updateView('label1', 'text', self.i18n:get('device-unavailable'))
    self:updateView('label2', 'text', '---')
    self:updateView('label3', 'text', '---')
    self:updateView('label4', 'text', '---')
end


function QuickApp:run()
    self:pullDataFromAPI()
    local interval = self.config:getTimeoutInterval()
    if (interval > 0) then
        fibaro.setTimeout(interval, function() self:run() end)
    end
end

function QuickApp:button1Event()
    self:pullDataFromAPI()
end

function QuickApp:pullDataFromAPI()
    self:updateView("button1", "text", self.i18n:get('please-wait'))
    local draw = function (parameters)

        if not parameters['T02'] then
            self:updateView('label1', 'text', self.i18n:get('device-unavailable'))
            self:updateView('label2', 'text', '---')
            self:updateView('label3', 'text', '---')
            self:updateView('label4', 'text', '---')
            return
        end
        local unit = 'C'
        local temp_inlet = tonumber(parameters['T02'])
        local temp_outlet = tonumber(parameters['T03'])
        local temp_set = tonumber(parameters['R02'])
        local temp_ambient = tonumber(parameters['T05'])
        local power = tonumber(parameters['Power'])
        local mode = tonumber(parameters['Mode'])
        if parameters['H03'] == 1 then
            unit = 'F'
        end
        -- QuickApp:debug('parameters = ', json.encode(parameters))

        self:updateProperty('unit', unit)
        self:updateProperty('value', temp_inlet)
        if power > 0 then
            self:updateView('label1', 'text', string.format(self.i18n:get('temperature-set'), temp_set, unit))
        else
            self:updateView('label1', 'text', self.i18n:get('device-off'))
        end
        self:updateView('label2', 'text', string.format(self.i18n:get('temperature-inlet'), temp_inlet, unit))
        self:updateView('label3', 'text', string.format(self.i18n:get('temperature-outlet'), temp_outlet, unit))
        self:updateView('label4', 'text', string.format(self.i18n:get('temperature-ambient'), temp_ambient, unit))

        self:updateView("button1", "text", self.i18n:get('refresh'))
        self:trace(self.i18n:get('device-updated'))
    end
    local err = function(data)
        self:updateView('label1', 'text', string.format(self.i18n:get('device-error'), data.code))
        self:updateView('label2', 'text', '---')
        self:updateView('label3', 'text', '---')
        self:updateView('label4', 'text', '---')
        self:updateView("button1", "text", self.i18n:get('refresh'))
    end

    self.aquatemp:getParameters(draw, err)
end
