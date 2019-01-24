local jass = require 'jass.common'

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

function mt:inLine(point, angle, length, width)
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
        units = selectInLine(self._point, self._angle, self._length, self._width)
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
