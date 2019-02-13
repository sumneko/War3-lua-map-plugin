local jass = require 'jass.common'

local mt = {}
mt.__index = mt
mt.type = 'shop'

function mt:__tostring()
    return ('{shop|%s}'):format(self._unit:getName())
end

return function (unit)
    local shop = setmetatable({
        _unit = unit,
    }, mt)
    unit:removeSkill('@命令')
    unit:addHeight(100000)
    jass.UnitAddAbility(unit._handle, ac.id['@INV'])
    if unit:getOwner() == ac.localPlayer() then
        unit:addHeight(-100000)
    end
    jass.UnitRemoveAbility(unit._handle, ac.id['Amov'])
    return shop
end
