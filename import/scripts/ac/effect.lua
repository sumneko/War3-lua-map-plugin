local jass = require 'jass.common'
local japi = require 'jass.japi'

local mt = {}
mt.__index = mt

mt._handle = 0
mt._xScale = 1.0
mt._yScale = 1.0
mt._zScale = 1.0
mt._speed = 1.0
mt._height = 0.0
mt._xRotate = 0.0
mt._yRotate = 0.0
mt._zRotate = 0.0
mt._x = 0.0
mt._y = 0.0

function mt:__tostring()
    return ('{effect|%s}'):format(self._handle)
end

function mt:blink(point)
    if not ac.isPoint(point) then
        return
    end
    local x, y = point:getXY()
    self._x = x
    self._y = y
    japi.EXSetEffectXY(self._handle, x, y)
end

function mt:size(...)
    local n = select('#', ...)
    if n == 0 then
        return self._xScale, self._yScale, self._zScale
    end
    if n == 1 then
        self._xScale = ...
        self._yScale = ...
        self._zScale = ...
    elseif n == 3 then
        self._xScale, self._yScale, self._zScale = ...
    end
    self._xScale = ac.toNumber(self._xScale, 1.0)
    self._yScale = ac.toNumber(self._yScale, 1.0)
    self._zScale = ac.toNumber(self._zScale, 1.0)
    japi.EXEffectMatScale(self._handle, self._xScale, self._yScale, self._zScale)
end

function mt:speed(n)
    if ac.isNumber(n) then
        self._speed = n
        japi.EXSetEffectSpeed(self._handle, n)
    else
        return self._speed
    end
end

function mt:height(n)
    if ac.isNumber(n) then
        self._height = n
        japi.EXSetEffectZ(self._handle, n)
    else
        return self._height
    end
end

function mt:angle(n)
    if ac.isNumber(n) then
        self._zRotate = n
        japi.EXEffectMatRotateZ(self._handle, n)
    else
        return self._zRotate
    end
end

function mt:remaining(n)
    if ac.isNumber(n) then
        if self._timer then
            self._timer:remove()
        end
        self._timer = ac.wait(n, function ()
            self:remove()
        end)
    else
        if self._timer then
            return self._timer:remaining()
        else
            return 0.0
        end
    end
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    if self._skipDeath then
        japi.EXSetEffectXY(self._handle, 100000000.0, 100000000.0)
        japi.EXSetEffectSize(self._handle, 0.0)
    end
    jass.DestroyEffect(self._handle)
    self._handle = 0
    if self._timer then
        self._timer:remove()
    end
end

function ac.effect(data)
    if not ac.isTable(data) then
        return nil
    end
    if not ac.isPoint(data.target) then
        return nil
    end
    local model = data.model
    if ac.isFunction(data.sight) then
        if not data.sight(ac.localPlayer()) then
            model = ''
        end
    end
    local x, y = data.target:getXY()
    local handle = jass.AddSpecialEffect(model, x, y)
    if handle == 0 then
        return nil
    end

    local self = setmetatable({
        _handle = handle,
        _x = x,
        _y = y,
        _skipDeath = data.skipDeath,
    }, mt)

    if data.size or data.xScale or data.yScale or data.zScale then
        self:size(data.xScale or data.size or 1.0, data.yScale or data.size or 1.0, data.zScale or data.size or 1.0)
    end
    if data.height then
        self:height(data.height)
    end
    if data.speed then
        self:speed(data.speed)
    end
    if data.angle then
        self:angle(data.angle)
    end
    if data.time then
        self:remaining(data.time)
    end

    return self
end
