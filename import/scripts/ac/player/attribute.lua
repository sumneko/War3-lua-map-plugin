local jass = require 'jass.common'

local Care = {'金币', '木材', '食物', '食物上限'}

local Show = {
    ['金币'] = function (player, v)
        jass.SetPlayerState(player._handle, 1, math.floor(v))
    end,
    ['木材'] = function (player, v)
        jass.SetPlayerState(player._handle, 2, math.floor(v))
    end,
    ['食物'] = function (player, v)
        jass.SetPlayerState(player._handle, 5, math.floor(v))
    end,
    ['食物上限'] = function (player, v)
        jass.SetPlayerState(player._handle, 4, math.floor(v))
    end,
}

local Set = {
}

local Get = {
}

local mt = {}
mt.__index = mt

mt.type = 'player attribute'

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
        if wait() == false then
            return
        end
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
        self._rate[k] = (self._rate[k] or 0.0) + v
        if wait then
            if wait() == false then
                return
            end
        end
        self:onShow(k)
    else
        local wait = self:onSet(k)
        self._base[k] = (self._base[k] or 0.0) + v
        if wait then
            if wait() == false then
                return
            end
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
    local player = self._player
    local delta = v - s
    self._show[k] = v
    Show[k](player, v)
    player:eventNotify('玩家-属性变化', player, k, delta)
end

function mt:onSet(k)
    if not Set[k] then
        return nil
    end
    return Set[k](self)
end

return function (player)
    local obj = setmetatable({
        _player = player,
        _base = {},
        _rate = {},
        _show = {},
    }, mt)
    for _, k in ipairs(Care) do
        obj:set(k, 0.0)
    end
    return obj
end
