local updateTimer = require 'ac.timer'
local mover = require 'ac.mover'
local unit = require 'ac.unit'

local Tick = 0
local function update(delta)
    Tick = Tick + 1
    if Tick % 3 == 0 then
        mover.update(delta * 3)
    end
    if Tick % 10 == 0 then
        unit.update(delta * 10)
    end
    updateTimer(delta)
end

local function getTick()
    return Tick
end

ac.world = {
    update = update,
    tick = getTick,
}
