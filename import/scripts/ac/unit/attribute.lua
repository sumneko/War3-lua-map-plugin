local jass = require 'jass.common'
local japi = require 'jass.japi'

local Care = {'生命', '生命上限', '生命恢复', '魔法', '魔法上限', '魔法恢复', '攻击', '护甲', '移动速度', '攻击速度'}

local Show = {
    ['生命'] = function (unit, v)
        if v > 1 then
            jass.SetWidgetLife(unit._handle, v)
        else
            jass.SetWidgetLife(unit._handle, 1)
        end
    end,
    ['生命上限'] = function (unit, v)
        if v > 1 then
            japi.SetUnitState(unit._handle, 1, v)
        else
            japi.SetUnitState(unit._handle, 1, 1)
        end
    end,
    ['魔法'] = function (unit, v)
        jass.SetUnitState(unit._handle, 2, v)
    end,
    ['魔法上限'] = function (unit, v)
        japi.SetUnitState(unit._handle, 3, v)
    end,
    ['攻击'] = function (unit, v)
        japi.SetUnitState(unit._handle, 0x12, v-1)
    end,
    ['护甲'] = function (unit, v)
        japi.SetUnitState(unit._handle, 0x20, v)
    end,
    ['移动速度'] = function (unit, v)
        jass.SetUnitMoveSpeed(unit._handle, v)
    end,
    ['攻击速度'] = function (unit, v)
        if v >= 0 then
            japi.SetUnitState(unit._handle, 0x51, 1 + v / 100)
        else
            --当攻击速度小于0的时候,每点相当于攻击间隔增加1%
            japi.SetUnitState(unit._handle, 0x51, 1 + v / (100 - v))
        end
    end,
}

local Set = {
    ['生命上限'] = function (attribute)
        local max = attribute:get '生命上限'
        local rate
        if max <= 0.0 then
            rate = 0.0
        else
            rate = attribute:get '生命' / max
        end
        return function ()
            attribute:set('生命', rate * attribute:get '生命上限')
        end
    end,
    ['魔法上限'] = function (attribute)
        local max = attribute:get '魔法上限'
        local rate
        if max <= 0.0 then
            rate = 0.0
        else
            rate = attribute:get '魔法' / max
        end
        return function ()
            attribute:set('魔法', rate * attribute:get '魔法上限')
        end
    end,
    ['生命'] = function (attribute)
        return function ()
            local life = attribute:get '生命'
            local max = attribute:get '生命上限'
            if life > max then
                attribute:set('生命', max)
            elseif life < 0 then
                attribute:set('生命', 0)
            end
        end
    end,
    ['魔法'] = function (attribute)
        return function ()
            local mana = attribute:get '魔法'
            local max = attribute:get '魔法上限'
            if mana > max then
                attribute:set('魔法', max)
            elseif mana < 0 then
                attribute:set('魔法', 0)
            end
        end
    end,
}

local Get = {
}

local mt = {}
mt.__index = mt

mt.type = 'unit attribute'

-- 设置固定值，会清除百分比部分
function mt:set(k, v)
    local ext = k:sub(-1)
    if ext == '%' then
        error('设置属性不能带属性')
    end
    local wait = self:onSet(k)
    self._base[k] = v
    self._rate[k] = 0.0
    if wait then
        wait()
    end
    self:onShow(k)
end

function mt:get(k)
    local base = self._base[k] or 0.0
    local rate = self._rate[k] or 0.0
    local v = base * (1.0 + rate / 100.0)
    if Get[k] then
        v = Get[k](self, v) or v
    end
    return v
end

function mt:add(k, v)
    local ext = k:sub(-1)
    if ext == '%' then
        k = k:sub(1, -2)
        local wait = self:onSet(k)
        self._rate[k] = self._rate[k] + v
        if wait then
            wait()
        end
        self:onShow(k)
    else
        local wait = self:onSet(k)
        self._base[k] = self._base[k] + v
        if wait then
            wait()
        end
        self:onShow(k)
    end
    local used
    return function ()
        if used then
            return
        end
        used = true
        self:add(k, -v)
    end
end

function mt:onShow(k)
    if not Show[k] then
        return
    end
    local v = self:get(k)
    local s = self._show[k]
    if v == s then
        return
    end
    local unit = self._unit
    if unit._removed then
        return
    end
    self._show[k] = v
    Show[k](unit, v)
end

function mt:onSet(k)
    if not Set[k] then
        return nil
    end
    return Set[k](self)
end

return function (unit, default)
    local obj = setmetatable({
        _unit = unit,
        _base = {},
        _rate = {},
        _show = {},
    }, mt)
    for _, k in ipairs(Care) do
        local v = default and default[k] or 0.0
        obj:set(k, v)
    end
    obj:set('生命', obj:get '生命上限')
    obj:set('魔法', obj:get '魔法上限')
    return obj
end
