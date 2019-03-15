local jass = require 'jass.common'
local japi = require 'jass.japi'

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
        self._moveType = self._moveType | 0x01
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
    end,
    ['飞行'] = function (self, unit)
        self._moveType = self._moveType | 0x04
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
    end,
    ['疾风步'] = function (self, unit)
        self._moveType = self._moveType | 0x10
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
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
        self._moveType = self._moveType ~ 0x01
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
    end,
    ['飞行'] = function (self, unit)
        self._moveType = self._moveType ~ 0x04
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
    end,
    ['疾风步'] = function (self, unit)
        self._moveType = self._moveType ~ 0x10
        japi.EXSetUnitMoveType(unit._handle, self._moveType)
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

    -- 探测单位的默认移动方式
    if unit._slk.movetp == 'foot' then
        obj._moveType = 0x02
    elseif unit._slk.movetp == 'horse' then
        obj._moveType = 0x02
    elseif unit._slk.movetp == 'fly' then
        obj._moveType = 0x04
    elseif unit._slk.movetp == 'hover' then
        obj._moveType = 0x02
    elseif unit._slk.movetp == 'float' then
        obj._moveType = 0x40
    elseif unit._slk.movetp == 'amph' then
        obj._moveType = 0x80
    else
        obj._moveType = 0
    end

    if type(restriction) == 'table' then
        for _, k in ipairs(restriction) do
            obj:add(k)
        end
    end

    return obj
end
