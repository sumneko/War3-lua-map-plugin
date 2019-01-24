local jass = require 'jass.common'
local slk = require 'jass.slk'

local MAX_COLLISION = slk.misc.MaxCollisionRadius
local GROUP = jass.CreateGroup()

local function selectInRange(point, radius)
    local units = {}
    local x, y = point:getXY()
    jass.GroupEnumUnitsInRange(GROUP, x, y, radius, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if unit then
            units[#units+1] = unit
        end
    end
    return units
end

local function selectInSector(point, radius, angle, section)
    local units = {}
    local x, y = point:getXY()
    jass.GroupEnumUnitsInRange(GROUP, x, y, radius, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if unit and ac.math.includedAngle(angle, point / unit:getPoint()) <= section then
            units[#units+1] = unit
        end
    end
    return units
end

local function selectInLine(point, angle, length, width)
    local units = {}
    local x1, y1 = point:getXY()
    local finish = point - {angle, length}
    local x2, y2 = finish:getXY()

    local a, b = y1 - y2, x2 - x1
    local c = - a * x1 - b * y1
    local l = (a * a + b * b) ^ 0.5
    local w = width / 2.0
    local r = length / 2.0

    local x, y = (x1 + x2) / 2.0, (y1 + y2) / 2.0

    jass.GroupEnumUnitsInRange(GROUP, x, y, r, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if unit then
            local x0, y0 = unit:getPoint():getXY()
            local d = math.abs(a * x0 + b * y0 + c) / l
            if d <= w + unit._collision then
                units[#units+1] = unit
            end
        end
    end
    return units
end

local mt = {}
mt.__index = mt

mt.type = 'selector'
mt._selectType = 'none'

function mt:__tostring()
    return ('{selector|%s}'):format(self._selectType)
end

function mt:inRange(point, radius)
    self._selectType = 'range'
    self._point = point
    self._radius = radius
    return self
end

function mt:inSector(point, radius, angle, section)
    self._selectType = 'sector'
    self._point = point
    self._radius = radius
    self._angle = angle
    self._section = section
    return self
end

function mt:inLine(point, angle, length, width)
    self._selectType = 'line'
    self._point = point
    self._angle = angle
    self._length = length
    self._width = width
    return self
end

function mt:addFilter(f)
    self._filters[#self._filters+1] = f
    return self
end

function mt:isNot(who)
    return self:addFilter(function (u)
        return who ~= u
    end)
end

function mt:isEnemy(who)
    return self:addFilter(function (u)
        return who:isEnemy(u)
    end)
end

function mt:isAlly(who)
    return self:addFilter(function (u)
        return who:isAlly(u)
    end)
end

function mt:get()
    local units
    if self._selectType == 'range' then
        units = selectInRange(self._point, self._radius)
    elseif self._selectType == 'sector' then
        units = selectInSector(self._point, self._radius, self._angle, self._section)
    elseif self._selectType == 'line' then
        units = selectInLine(self._point, self._angle, self._length, self._width)
    end
    return units
end

function mt:ipairs()
    return ipairs(self:get())
end

function mt:random()
    local g = self:get()
    if #g > 0 then
        return g[math.random(#g)]
    end
end

function ac.selector()
    return setmetatable({
        _filters = {},
    }, mt)
end
