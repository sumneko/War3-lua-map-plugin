local jass = require 'jass.common'

local MIN_ID = 1
local MAX_ID = 16
local LocalPlayer
local All = {}
local mt = {}

local function create(id)
    if id < MIN_ID or id > MAX_ID then
        return nil
    end
    local handle = jass.Player(id - 1)
    local player = setmetatable({
        _handle = handle,
        _id = id,
        _hero = {}
    }, mt)
    All[id] = player
    All[handle] = player

    return player
end

mt.__index = mt

function mt:addHero(unit)
    if self._hero[unit] then
        return false
    end
    self._hero[#self._hero+1] = unit
    self._hero[unit] = true
    return true
end

function mt:removeHero(unit)
    if not self._hero[unit] then
        return false
    end
    self._hero[unit] = nil
    for i, u in ipairs(self._hero) do
        if u == unit then
            table.remove(self._hero, i)
            return true
        end
    end
    return false
end

function mt:getHero(n)
    if n == nil then
        n = 1
    end
    return self._hero[n]
end

function mt:selectUnit(unit)
    if self == ac.localPlayer() then
        jass.ClearSelection()
        jass.SelectUnit(unit._handle, true)
    end
end

function mt:event(name, f)
    return ac.eventRegister(self, name, f)
end

function mt:eventDispatch(name, ...)
    local res = ac.eventDispatch(self, name, ...)
    if res ~= nil then
        return res
    end
    local res = ac.game:eventDispatch(ac.game, name, ...)
    if res ~= nil then
        return res
    end
    return nil
end

function mt:eventNotify(name, ...)
    ac.eventNotify(self, name, ...)
    ac.game:eventNotify(name, ...)
end

function ac.player(id)
    if not All[id] then
        return create(id)
    end
    return All[id]
end

function ac.localPlayer()
    if not LocalPlayer then
        LocalPlayer = ac.player(jass.GetLocalPlayer())
    end
    return LocalPlayer
end
