local jass = require 'jass.common'

local All = {}

local mt = {}
mt.__index = mt
mt.type = 'text tag'
mt._text = ''
mt._permanent = true

function mt:__tostring()
    return ('{text tag|%d|%s}'):format(self._handle, self._text)
end

function mt:text(str, size)
    if self._removed then
        return
    end
    jass.SetTextTagText(self._handle, str, ac.toNumber(size, 0.05))
    return self
end

function mt:at(point, height)
    if self._removed then
        return
    end
    if not ac.isPoint(point) then
        return self
    end
    local x, y = point:getXY()
    jass.SetTextTagPos(self._handle, x, y, ac.toNumber(height, 0.0))
    return self
end

function mt:speed(speed, angle)
    if self._removed then
        return
    end
    if not ac.isNumber(speed) then
        return self
    end
    angle = ac.toNumber(angle, 90.0)
    local x = speed * ac.math.cos(angle)
    local y = speed * ac.math.sin(angle)
    jass.SetTextTagVelocity(self._handle, x, y)
    return self
end

function mt:show(callback)
    if self._removed then
        return
    end
    if type(callback) ~= 'function' then
        return self
    end
    if callback(ac.localPlayer()) then
        jass.SetTextTagVisibility(self._handle, true)
    else
        jass.SetTextTagVisibility(self._handle, false)
    end
    return self
end

function mt:pause(flag)
    if self._removed then
        return
    end
    if not ac.isBoolean(flag) then
        return self
    end
    jass.SetTextTagSuspended(self._handle, flag)
    return self
end

function mt:permanent(flag)
    if self._removed then
        return
    end
    if not ac.isBoolean(flag) then
        return self
    end
    if self._permanent == flag then
        return self
    end
    jass.SetTextTagPermanent(self._handle, flag)
    self._permanent = flag
    return self
end

function mt:age(age)
    if self._removed then
        return
    end
    if not ac.isNumber(age) then
        return self
    end
    self:permanent(false)
    jass.SetTextTagAge(self._handle, age)
    return self
end

function mt:life(life, fade)
    if self._removed then
        return
    end
    if not ac.isNumber(life) then
        return self
    end
    self:permanent(false)
    jass.SetTextTagAge(self._handle, 0)
    jass.SetTextTagLifespan(self._handle, life)
    if ac.isNumber(fade) then
        jass.SetTextTagFadepoint(self._handle, fade)
    end
    return self
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.DestroyTextTag(self._handle)
    All[self._handle] = nil
    self._handle = nil
end

function ac.textTag()
    local handle = jass.CreateTextTag()
    if All[handle] then
        All[handle]._removed = true
        All[handle]._handle = nil
    end
    local self = setmetatable({
        _handle = handle,
    }, mt)
    All[handle] = self
    return self
end
