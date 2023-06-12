--[[
AquaTemp child device handler
@author ikubicki
]]

class 'AquaTempChild' (QuickAppChild)

function AquaTempChild:__init(device)
    QuickAppChild.__init(self, device)
end

function AquaTempChild:setUnit(unit)
    self:updateProperty("unit", unit)
end

function AquaTempChild:setValue(value)
    self:updateProperty("value", tonumber(value))
end

function AquaTempChild:setDead(dead, deadReason)
    self:updateProperty("dead", dead)
    self:updateProperty("deadReason", deadReason)
end