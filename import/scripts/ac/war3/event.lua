local jass = require 'jass.common'

local EVENT = {
    Selected    = jass.EVENT_PLAYER_UNIT_SELECTED,
    Deselected  = jass.EVENT_PLAYER_UNIT_DESELECTED,
    Chat        = 96,
}
local CallBack = {
    [EVENT.Selected] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local player = ac.player(jass.GetTriggerPlayer())
        if unit and player then
            player:eventNotify('玩家-选中单位', player, unit)
        end
    end,
    [EVENT.Deselected] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local player = ac.player(jass.GetTriggerPlayer())
        if unit and player then
            player:eventNotify('玩家-取消选中', player, unit)
        end
    end,
    [EVENT.Chat] = function ()
        local player = ac.player(jass.GetTriggerPlayer())
        local str = jass.GetEventPlayerChatString()
        if player and str then
            player:eventNotify('玩家-聊天', player, str)
        end
    end,
}

return function ()
    local trg = jass.CreateTrigger()
    for i = 0, 15 do
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Selected, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Deselected, nil)
        jass.TriggerRegisterPlayerChatEvent(trg, jass.Player(i), '', false)
    end
    jass.TriggerAddCondition(trg, jass.Condition(function ()
        local eventId = jass.GetTriggerEventId()
        if CallBack[eventId] then
            CallBack[eventId]()
        end
    end))
end
