local jass = require 'jass.common'

local mt = {}
mt.__index = mt
mt.type = 'shop'

function mt:__tostring()
    return ('{shop|%s}'):format(self._unit:getName())
end

function mt:setItem(index, name)
    local unit = self._unit
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return false
    end
    local skill = unit:findSkill(index, '技能') or unit:addSkill('@商店物品', '技能', index)
    skill.item = data
    skill:update()
end

return function (unit)
    local shop = setmetatable({
        _unit = unit,
    }, mt)
    unit:removeSkill('@命令')
    unit:addHeight(100000)
    jass.UnitAddAbility(unit._handle, ac.id['AInv'])
    if unit:getOwner() == ac.localPlayer() then
        unit:addHeight(-100000)
    end
    jass.UnitRemoveAbility(unit._handle, ac.id['Amov'])
    return shop
end
