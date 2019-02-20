local updateTimer = require 'ac.timer'
local mover = require 'ac.mover'
local unit = require 'ac.unit'
local message = require 'jass.message'
local jass = require 'jass.common'
local Flag = {}
local LastSelecting

local function updateSelect()
    local selecting = ac.unit(message.selection())
    local isNewSelect = LastSelecting ~= selecting
    LastSelecting = selecting
    if not selecting then
        return
    end
    if selecting._skill then
        if isNewSelect then
            selecting._skill:checkRefreshItem()
            selecting._skill:checkRefreshAbility()
            return
        end
        if selecting._skill:checkRefreshItem() then
            if ac.world.flag 'ignore update select' then
                return
            end
            local dummy
            for hero in ac.localPlayer():eachHero() do
                if hero ~= selecting and hero:isAlive() then
                    dummy = hero
                    break
                end
            end
            if dummy then
                jass.ClearSelection()
                jass.SelectUnit(dummy._handle, true)
                ac.world.flag('ignore update select', true)
                ac.wait(0.05, function ()
                    jass.ClearSelection()
                    jass.SelectUnit(selecting._handle, true)
                    ac.world.flag('ignore update select', false)
                end)
            end
            return
        end
        if selecting._skill:checkRefreshAbility() then
            if ac.world.flag 'ignore update select' then
                return
            end
            jass.SelectUnit(selecting._handle, true)
            return
        end
    end

    if selecting._shop then
        for private in selecting._shop._private:pairs() do
            if private:getOwner() == ac.localPlayer() then
                jass.ClearSelection()
                jass.SelectUnit(private._handle, true)
            end
        end
    end
end

local Tick = 0
local function update(delta)
    Tick = Tick + 1
    if Tick % 3 == 0 then
        mover.update(delta * 3)
    end
    if Tick % 10 == 0 then
        unit.update(delta * 10)
    end
    updateSelect()
    updateTimer(delta)
end

local function getTick()
    return Tick
end

local function flag(key, value)
    if value == nil then
        return Flag[key]
    else
        Flag[key] = value
    end
end

ac.world = {
    update = update,
    tick = getTick,
    flag = flag,
}
