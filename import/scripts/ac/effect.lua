local jass = require 'jass.common'
local japi = require 'jass.japi'

local mt = {}
mt.__index = mt

mt._handle = 0
mt._x_scale = 1.0
mt._y_scale = 1.0
mt._z_scale = 1.0
mt._speed = 1.0
mt._height = 0.0
mt._x_rotate = 0.0
mt._y_rotate = 0.0
mt._z_rotate = 0.0
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
        return self._x_scale, self._y_scale, self._z_scale
    end
    if n == 1 then
        self._x_scale = ...
        self._y_scale = ...
        self._z_scale = ...
    elseif n == 3 then
        self._x_scale, self._y_scale, self._z_scale = ...
    end
    self._x_scale = ac.toNumber(self._x_scale, 1.0)
    self._y_scale = ac.toNumber(self._y_scale, 1.0)
    self._z_scale = ac.toNumber(self._z_scale, 1.0)
    japi.EXEffectMatScale(self._handle, self._x_scale, self._y_scale, self._z_scale)
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
        self._z_rotate = n
        japi.EXEffectMatRotateZ(self._handle, n)
    else
        return self._z_rotate
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

local function create(owner, data)
    if not ac.isPlayer(owner) then
        return nil
    end
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
        _owner = owner,
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

return {
    create = create,
}
