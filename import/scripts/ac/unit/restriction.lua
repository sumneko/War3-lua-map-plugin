local jass = require 'jass.common'
local japi = require 'jass.japi'

local function updateMoveType(self, unit)
    if self:has '定身' then
        japi.EXSetUnitMoveType(unit._handle, 0x01)
        return
    end

    if self:has '飞行' then
        japi.EXSetUnitMoveType(unit._handle, 0x04)
        return
    end

    if self:has '疾风步' then
        japi.EXSetUnitMoveType(unit._handle, 0x10)
    end

    if unit._slk.movetp == 'foot' then
        japi.EXSetUnitMoveType(unit._handle, 0x02)
        return
    end
    
    if unit._slk.movetp == 'horse' then
        japi.EXSetUnitMoveType(unit._handle, 0x02)
        return
    end

    if unit._slk.movetp == 'fly' then
        japi.EXSetUnitMoveType(unit._handle, 0x04)
        return
    end

    if unit._slk.movetp == 'hover' then
        japi.EXSetUnitMoveType(unit._handle, 0x02)
        return
    end

    if unit._slk.movetp == 'float' then
        japi.EXSetUnitMoveType(unit._handle, 0x40)
        return
    end

    if unit._slk.movetp == 'amph' then
        japi.EXSetUnitMoveType(unit._handle, 0x80)
        return
    end

    japi.EXSetUnitMoveType(unit._handle, 0x00)
end

local Add = {
    ['硬直'] = function (self, unit)
        japi.EXPauseUnit(unit._handle, true)
    end,
    ['无敌'] = function (self, unit)
        jass.SetUnitInvulnerable(unit._handle, true)
    end,
    ['幽灵'] = function (self, unit)
        japi.EXSetUnitCollisionType(false, unit._handle, 1)
    end,
    ['定身'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['飞行'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['疾风步'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['隐藏'] = function (self, unit)
        jass.ShowUnit(unit._handle, false)
    end,
    ['缴械'] = function (self, unit)
        jass.UnitAddAbility(unit._handle, ac.id['@BUN'])
    end,
    ['禁魔'] = function (self, unit)
        for skill in unit:eachSkill() do
            skill:updateIcon()
        end
    end,
}

local Remove = {
    ['硬直'] = function (self, unit)
        japi.EXPauseUnit(unit._handle, false)
    end,
    ['无敌'] = function (self, unit)
        jass.SetUnitInvulnerable(unit._handle, false)
    end,
    ['幽灵'] = function (self, unit)
        japi.EXSetUnitCollisionType(true, unit._handle, 1)
    end,
    ['定身'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['飞行'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['疾风步'] = function (self, unit)
        updateMoveType(self, unit)
    end,
    ['隐藏'] = function (self, unit)
        jass.ShowUnit(unit._handle, true)
    end,
    ['缴械'] = function (self, unit)
        jass.UnitRemoveAbility(unit._handle, ac.id['@BUN'])
    end,
    ['禁魔'] = function (self, unit)
        for skill in unit:eachSkill() do
            skill:updateIcon()
        end
    end,
}

local mt = {}
mt.__index = mt

mt.type = 'unit restriction'

function mt:add(k)
    if not Add[k] then
        log.error(('错误的行为限制名[%s]'):format(k))
        return nil
    end
    local unit = self._unit
    if unit._removed then
        return nil
    end
    self[k] = (self[k] or 0) + 1
    if self[k] == 1 then
        Add[k](self, unit)
    end

    local used
    return function ()
        if used then
            return
        end
        used = true
        self:remove(k)
    end
end

function mt:remove(k)
    if not Remove[k] then
        log.error(('错误的行为限制名[%s]'):format(k))
        return
    end
    local unit = self._unit
    if unit._removed then
        return
    end
    self[k] = (self[k] or 0) - 1
    if self[k] == 0 then
        Remove[k](self, unit)
    end
end

function mt:has(k)
    if self[k] and self[k] > 0 then
        return true
    else
        return false
    end
end

function mt:get(k)
    if self[k] then
        return self[k]
    else
        return 0
    end
end

return function (unit, restriction)
    local obj = setmetatable({
        _unit = unit,
    }, mt)

    if type(restriction) == 'table' then
        for _, k in ipairs(restriction) do
            obj:add(k)
        end
    end

    return obj
end
