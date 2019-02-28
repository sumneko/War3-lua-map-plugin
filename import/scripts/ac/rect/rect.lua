local w3r = require 'ac.rect.w3r'
local jass = require 'jass.common'

local Preset
local Condition
local RegionMap = {}

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
            rect._inside[unit] = true
            callMethod(rect, 'onEnter', unit)
        else
            -- 离开
            if not rect.onLeave then
                return false
            end
            local unit = ac.unit(jass.GetLeavingUnit())
            if not rect._inside[unit] then
                return false
            end
            rect._inside[unit] = nil
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

    self._inside = {}

    initCondition()

    self._region = jass.CreateRegion()
    jass.RegionAddRect(self._region, self._handle)
    RegionMap[self._region] = self

    self._trg = jass.CreateTrigger()
    jass.TriggerRegisterEnterRegion(self._trg, self._region, nil)
    jass.TriggerRegisterLeaveRegion(self._trg, self._region, nil)
    jass.TriggerAddCondition(self._trg, Condition)
end

local function createByXY(minx, miny, maxx, maxy)
    local handle = jass.Rect(minx, miny, maxx, maxy)
    if not handle then
        return nil
    end

    local self = setmetatable({
        _handle = handle,
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
    if key == 'onEnter' then
        registerEvent(self)
    elseif key == 'onLeave' then
        registerEvent(self)
    end
    rawset(self, key, value)
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
end

function ac.rect(...)
    local n = select('#', ...)
    if n == 1 then
        if type(...) == 'string' then
            local name = ...
            return presetRect(name)
        end
    end
end
