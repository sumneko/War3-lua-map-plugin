local jass = require 'jass.common'
local sqrt = math.sqrt
local abs = math.abs

local GROUP = jass.CreateGroup()

local function selectInRange(point, radius)
    local units = {}
    local x, y = point:getXY()
    jass.GroupEnumUnitsInRange(GROUP, x, y, radius + ac.world.maxSelectedRadius, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if not unit then
            goto CONTINUE
        end
        if not unit:isInRange(point, radius) then
            goto CONTINUE
        end
        units[#units+1] = unit
        :: CONTINUE ::
    end
    return units
end

-- https://blog.csdn.net/zaffix/article/details/25005057
local function evaluatePointToLine(x, y, x1, y1, x2, y2)
    local a = y2 - y1
    local b = x1 - x2
    local c = x2 * y1 - x1 * y2
    return a * x + b * y + c
end

-- https://blog.csdn.net/zaffix/article/details/25160505
local function isCircleIntersectLineSeg(x, y, r, x1, y1, x2, y2)
    local vx1 = x - x1
    local vy1 = y - y1
    local vx2 = x2 - x1
    local vy2 = y2 - y1

    local len = sqrt(vx2 * vx2 + vy2 * vy2)

    vx2 = vx2 / len
    vy2 = vy2 / len

    local u = vx1 * vx2 + vy1 * vy2

    local x0
    local y0
    if u <= 0 then
        x0 = x1
        y0 = y1
    elseif u >= len then
        x0 = x2
        y0 = y2
    else
        x0 = x1 + vx2 * u
        y0 = y1 + vy2 * u
    end

    return (x - x0) * (x - x0) + (y - y0) * (y - y0) <= r * r
end

-- https://blog.csdn.net/zaffix/article/details/25339837
local function checkPointInSector(x, y, r, x1, y1, x2, y2, theta, radius)
    local dx = x - x1
    local dy = y - y1
    local dr = r + radius
    if dx * dx + dy * dy > dr * dr then
        return false
    end

    local vx = x2 - x1
    local vy = y2 - y1
    local h = theta / 2.0
    local c = ac.math.cos(h)
    local s = ac.math.sin(h)
    local x3 = x1 + (vx * c - vy * s)
    local y3 = y1 + (vx * s + vy * c)
    local x4 = x1 + (vx * c + vy * s)
    local y4 = y1 + (-vx * s + vy * c)

    local d1 = evaluatePointToLine(x, y, x1, y1, x3, y3)
    local d2 = evaluatePointToLine(x, y, x4, y4, x1, y1)
    if d1 >= 0 and d2 >= 0 then
        return true
    end

    if isCircleIntersectLineSeg(x, y, r, x1, y1, x3, y3) then
        return true
    end
    if isCircleIntersectLineSeg(x, y, r, x1, y1, x4, y4) then
        return true
    end

    return false
end

local function selectInSector(point, radius, angle, section)
    local units = {}
    local x1, y1 = point:getXY()
    local p2 = point:getPoint() - {angle, radius}
    local x2, y2 = p2:getXY()
    jass.GroupEnumUnitsInRange(GROUP, x1, y1, radius + ac.world.maxSelectedRadius, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if not unit then
            goto CONTINUE
        end
        local x, y = unit:getXY()
        if not checkPointInSector(x, y, unit:selectedRadius(), x1, y1, x2, y2, section, radius) then
            goto CONTINUE
        end
        units[#units+1] = unit
        :: CONTINUE ::
    end
    return units
end

-- https://blog.csdn.net/zaffix/article/details/25077835
local function distanceBetweenTwoPoints(x1, y1, x2, y2)
    return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

local function distanceFromPointToLine(x, y, x1, y1, x2, y2)
    local a = y2 - y1
    local b = x1 - x2
    local c = x2 * y1 - x1 * y2

    return abs(a * x + b * y + c) / sqrt(a * a + b * b)
end

local function isCircleIntersectRectangle(x, y, r, x0, y0, x1, y1, x2, y2)
    local w1 = distanceBetweenTwoPoints(x0, y0, x2, y2)
    local h1 = distanceBetweenTwoPoints(x0, y0, x1, y1)
    local w2 = distanceFromPointToLine(x, y, x0, y0, x1, y1)
    local h2 = distanceFromPointToLine(x, y, x0, y0, x2, y2)

    if w2 > w1 + r then
        return false
    end
    if h2 > h1 + r then
        return false
    end

    if w2 <= w1 then
        return true
    end
    if h2 <= h1 then
        return true
    end

    return (w2 - w1) * (w2 - w1) + (h2 - h1) * (h2 - h1) <= r * r
end

local function selectInLine(point, length, angle, width)
    local units = {}
    local x1, y1 = point:getXY()
    local x0 = x1 + length / 2.0 * ac.math.cos(angle)
    local y0 = y1 + length / 2.0 * ac.math.sin(angle)
    local r = math.max(length / 2.0, width / 2.0)
    local x2 = x0 + width / 2.0 * ac.math.cos(angle + 90.0)
    local y2 = y0 + width / 2.0 * ac.math.sin(angle + 90.0)

    jass.GroupEnumUnitsInRange(GROUP, x0, y0, r + ac.world.maxSelectedRadius, nil)
    while true do
        local u = jass.FirstOfGroup(GROUP)
        if u == 0 then
            break
        end
        jass.GroupRemoveUnit(GROUP, u)
        local unit = ac.unit(u)
        if not unit then
            goto CONTINUE
        end
        local x, y = unit:getXY()
        if not isCircleIntersectRectangle(x, y, unit:selectedRadius(), x0, y0, x1, y1, x2, y2) then
            goto CONTINUE
        end

        units[#units+1] = unit

        :: CONTINUE ::
    end
    return units
end

local function checkFilter(unit, filters)
    if not filters then
        return true
    end
    for j = 1, #filters do
        if not filters[j](unit) then
            return false
        end
    end
    return true
end

local function checkOf(unit, of)
    if not of then
        return true
    end
    local types = unit._type
    for tp in next, of do
        if types and types[tp] then
            return true
        end
    end
    return false
end

local function checkOfNot(unit, ofNot)
    if not ofNot then
        return true
    end
    local types = unit._type
    for tp in next, ofNot do
        if types and types[tp] then
            return false
        end
    end
    return true
end

local function checkAllow(unit, dead, god)
    if not dead and not unit:isAlive() then
        return false
    end
    if not god and unit:hasRestriction '无敌' then
        return false
    end
    return true
end

local function filter(units, selector)
    local passed = {}
    for i = 1, #units do
        local unit = units[i]
        if checkAllow(unit, selector._dead, selector._god) and
           checkOf(unit, selector._of) and
           checkOfNot(unit, selector._ofNot) and
           checkFilter(unit, selector._filters)
        then
            passed[#passed+1] = unit
        end
    end
    return passed
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

function mt:inLine(point, length, angle, width)
    self._selectType = 'line'
    self._point = point
    self._angle = angle
    self._length = length
    self._width = width
    return self
end

function mt:filter(f)
    if not self._filters then
        self._filters = {}
    end
    self._filters[#self._filters+1] = f
    return self
end

function mt:isNot(who)
    return self:filter(function (u)
        return who ~= u
    end)
end

function mt:isEnemy(who)
    return self:filter(function (u)
        return who:isEnemy(u)
    end)
end

function mt:isAlly(who)
    return self:filter(function (u)
        return who:isAlly(u)
    end)
end

function mt:isVisible(who)
    return self:filter(function (u)
        return who:isVisible(u)
    end)
end

function mt:ofIllusion()
    return self:filter(function (u)
        return u:isIllusion()
    end)
end

function mt:ofNotIllusion()
    return self:filter(function (u)
        return not u:isIllusion()
    end)
end

function mt:allowDead()
    self._dead = true
    return self
end

function mt:allowGod()
    self._god = true
    return self
end

function mt:of(data)
    if not self._of then
        self._of = {}
    end
    if ac.isString(data) then
        self._of[data] = true
    elseif ac.isTable(data) then
        for _, tp in ipairs(data) do
            if ac.isString(tp) then
                self._of[tp] = true
            end
        end
    end
    return self
end

function mt:ofNot(data)
    if not self._ofNot then
        self._ofNot = {}
    end
    if ac.isString(data) then
        self._ofNot[data] = true
    elseif ac.isTable(data) then
        for _, tp in ipairs(data) do
            if ac.isString(tp) then
                self._ofNot[tp] = true
            end
        end
    end
    return self
end

function mt:get()
    local units
    if self._selectType == 'range' then
        units = selectInRange(self._point, self._radius)
    elseif self._selectType == 'sector' then
        units = selectInSector(self._point, self._radius, self._angle, self._section)
    elseif self._selectType == 'line' then
        units = selectInLine(self._point, self._length, self._angle, self._width)
    end

    units = filter(units, self)

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
    return setmetatable({}, mt)
end
