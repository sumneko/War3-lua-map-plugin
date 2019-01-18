local jass = require 'jass.common'
local unit = require 'ac.unit'

local Trg
local Condition = jass.Condition(function ()
    local source = ac.unit(jass.GetEventDamageSource())
    local target = ac.unit(jass.GetTriggerUnit())
    local dmg = jass.GetEventDamage()
    if source and target and dmg == 1.0 then
        if source._attack then
            source._attack:dispatch(target)
        end
    end
end)

local function createTrigger()
    if Trg then
        jass.DestroyTrigger(Trg)
    end
    Trg = jass.CreateTrigger()
    jass.TriggerAddCondition(Trg, Condition)
    for u in unit.list:pairs() do
        if jass.GetUnitAbilityLevel(u._handle, ac.id.Aloc) == 0 then
            jass.TriggerRegisterUnitEvent(Trg, u._handle, 52) -- EVENT_UNIT_DAMAGED
        end
    end
end

return function ()
    createTrigger()
    ac.loop(600, function ()
        createTrigger()
    end)
    ac.game:event('单位-初始化', function (_, u)
        jass.TriggerRegisterUnitEvent(Trg, u._handle, 52) -- EVENT_UNIT_DAMAGED
    end)
end
