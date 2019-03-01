local w3r = require 'ac.rect.w3r'
local jass = require 'jass.common'

local Preset
local Condition
local RegionMap = {}
local Group = jass.CreateGroup()

local mt = {}
mt.__index = mt

function mt:__tostring()
    return ('{rect|%s}'):format(self._handle)
end

local function callMethod(rect, name, ...)
    local method = rect[name]
    if not method then
        return
    end
    local suc, res = xpcall(method, log.error, rect, ...)
    if suc then
        return res
    end
end

local function initCondition()
    if Condition then
        return
    end
    Condition = jass.Condition(function ()
        local region = jass.GetTriggeringRegion()
        local rect = RegionMap[region]
        if not rect then
            return false
        end
        if jass.GetTriggerEventId() == 5 then
            -- 进入
            if not rect.onEnter then
                return false
            end
            local unit = ac.unit(jass.GetEnteringUnit())
            if not unit or unit._class ~= '生物' then
                return false
            end
            rect._inside:insert(unit)
            callMethod(rect, 'onEnter', unit)
        else
            -- 离开
            if not rect.onLeave then
                return false
            end
            local unit = ac.unit(jass.GetLeavingUnit())
            if not rect._inside:has(unit) then
                return false
            end
            rect._inside:remove(unit)
            callMethod(rect, 'onLeave', unit)
        end
        return false
    end)
end

local function registerEvent(self)
    if self._removed then
        return
    end
    if self._trg then
        return
    end

    self._inside = ac.list()

    initCondition()

    self._region = jass.CreateRegion()
    jass.RegionAddRect(self._region, self._handle)
    RegionMap[self._region] = self

    self._trg = jass.CreateTrigger()
    jass.TriggerRegisterEnterRegion(self._trg, self._region, nil)
    jass.TriggerRegisterLeaveRegion(self._trg, self._region, nil)
    jass.TriggerAddCondition(self._trg, Condition)

    -- 选取初始就在区域内的单位，触发进入区域事件
    ac.wait(0, function ()
        if self._removed then
            return
        end
        local x, y = self._point:getXY()
        local dx = self._width
        local dy = self._height
        local r = (dx * dx + dy * dy) ^ 0.5 / 2.0 + ac.world.maxSelectedRadius + 32

        jass.GroupEnumUnitsInRange(Group, x, y, r, nil)
        local list = {}
        while true do
            local handle = jass.FirstOfGroup(Group)
            if handle == 0 then
                break
            end
            jass.GroupRemoveUnit(Group, handle)
            local unit = ac.unit(handle)
            if unit and jass.IsUnitInRegion(self._region, handle) then
                list[#list+1] = unit
            end
        end
        for _, unit in ipairs(list) do
            self._inside:insert(unit)
            callMethod(self, 'onEnter', unit)
        end
    end)
end

local function createByXY(minx, miny, maxx, maxy)
    local handle = jass.Rect(minx, miny, maxx, maxy)
    if not handle then
        return nil
    end
    local x = (minx + maxx) / 2.0
    local y = (miny + maxy) / 2.0
    local width = maxx - minx
    local height = maxy - miny

    local self = setmetatable({
        _handle = handle,
        _point = ac.point(x, y),
        _width = width,
        _height = height,
    }, mt)

    return self
end

local function createByCorner(minPoint, maxPoint)
    if not ac.isPoint(minPoint) then
        return nil
    end
    if not ac.isPoint(maxPoint) then
        return nil
    end
    local minx, miny = minPoint:getXY()
    local maxx, maxy = maxPoint:getXY()
    return createByXY(minx, miny, maxx, maxy)
end

local function createByCenter(point, width, height)
    if not ac.isPoint(point) then
        return nil
    end
    width = ac.toNumber(width)
    height = ac.toNumber(width)
    if width <= 0 or height <= 0 then
        return nil
    end
    local x, y = point:getXY()
    local minx = x - width / 2.0
    local maxx = x + width / 2.0
    local miny = y - height / 2.0
    local maxy = y + height / 2.0

    local handle = jass.Rect(minx, miny, maxx, maxy)
    if not handle then
        return nil
    end

    local self = setmetatable({
        _handle = handle,
        _point = point,
        _width = width,
        _height = height,
    }, mt)

    return self
end

local function initW3r()
    if Preset then
        return
    end

    Preset = {}

    if not w3r then
        return
    end

    for _, rect in ipairs(w3r) do
        local minx = rect[1]
        local miny = rect[2]
        local maxx = rect[3]
        local maxy = rect[4]
        local name = rect[5]
        Preset[name] = createByXY(minx, miny, maxx, maxy)
    end
end

local function presetRect(name)
    initW3r()

    return Preset[name]
end

function mt:__newindex(key, value)
    rawset(self, key, value)
    if key == 'onEnter' then
        registerEvent(self)
    elseif key == 'onLeave' then
        registerEvent(self)
    end
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.RemoveRect(self._handle)
    self._handle = 0

    if self._region then
        RegionMap[self._region] = nil
        jass.RemoveRegion(self._region)
        self._region = nil
    end
    if self._trg then
        jass.DestroyTrigger(self._trg)
        self._trg = nil
    end
    if self._inside then
        for unit in self._inside:pairs() do
            callMethod(self, 'onLeave', unit)
        end
    end
end

function mt:getPoint()
    return self._point
end

function mt:width()
    return self._width
end

function mt:height()
    return self._height
end

function ac.rect(...)
    local n = select('#', ...)
    if n == 1 then
        local name = ...
        return presetRect(name)
    elseif n == 2 then
        local minPoint, maxPoint = ...
        return createByCorner(minPoint, maxPoint)
    elseif n == 3 then
        local point, width, height = ...
        return createByCenter(point, width, height)
    elseif n == 4 then
        local minx, miny, maxx, maxy = ...
        return createByXY(minx, miny, maxx, maxy)
    end
    return nil
end
