--[[
Configuration handler
@author ikubicki
]]
class 'Config'

function Config:new(app)
    self.app = app
    self:init()
    return self
end

function Config:getUsername(alternative)
    return self.username
end

function Config:getPassword()
    return self.password
end

function Config:getUrl()
    return self.url
end

function Config:getTimeoutInterval()
    return tonumber(self.interval) * 60000
end

--[[
This function takes variables and sets as global variables if those are not set already.
This way, adding other devices might be optional and leaves option for users, 
what they want to add into HC3 virtual devices.
]]
function Config:init()
    self.username = self.app:getVariable('Username')
    self.password = self.app:getVariable('Password')
    self.url = self.app:getVariable('URL')

    if string.len(self.url) < 1 then
        self.url = 'https://cloud.linked-go.com/cloudservice/api'
    end

    self.interval = self.app:getVariable('Refresh Interval')

    if self.interval == '' or self.interval < 1 then
        self.interval = 1
    end

    local storedUsername = Globals:get('aquatemp_username', '')
    local storedPassword = Globals:get('aquatemp_password', '')
    local storedUrl = Globals:get('aquatemp_url', '')
    local storedInterval = Globals:get('aquatemp_interval', '')
    -- handling username
    if string.len(self.username) < 4 and string.len(storedUsername) > 3 then
        self.app:setVariable("Username", storedUsername)
        self.username = storedUsername
    elseif (storedUsername == '' and self.username) then -- or storedUsername ~= self.username then
        Globals:set('aquatemp_username', self.username)
    end
    -- handling password
    if string.len(self.password) < 4 and string.len(storedPassword) > 3 then
        self.app:setVariable("Password", storedPassword)
        self.password = storedPassword
    elseif (storedPassword == '' and self.password) then -- or storedPassword ~= self.password then
        Globals:set('aquatemp_password', self.password)
    end
    -- handling URL
    if string.len(self.url) < 4 and string.len(storedUrl) > 3 then
        self.app:setVariable("URL", storedUrl)
        self.url = storedUrl
    elseif (storedUrl == '' and self.url) then -- or storedUrl ~= self.url then
        Globals:set('aquatemp_url', self.url)
    end
    -- handling interval
    if not self.interval or self.interval == "" then
        if storedInterval and storedInterval ~= "" then
            self.app:setVariable("Refresh Interval", storedInterval)
            self.interval = storedInterval
        else
            self.interval = "1"
        end
    end
    if (storedInterval == "" and self.interval ~= "") then -- or storedInterval ~= self.interval then
        Globals:set('aquatemp_interval', self.interval)
    end
end