local japi = require 'jass.japi'

local Add = {
    ['硬直'] = function (unit)
        japi.EXPauseUnit(unit._handle, true)
    end,
}

local Remove = {
    ['硬直'] = function (unit)
        japi.EXPauseUnit(unit._handle, false)
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
        Add[k](unit)
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
        Remove[k](unit)
    end
end

return function (unit, restriction)
    local obj = setmetatable({
        _unit = unit,
    }, mt)

    if type(restriction) == 'table' then
        for _, k in ipairs(restriction) do
            obj:addRestriction(k)
        end
    end

    return obj
end
