local jass = require 'jass.common'
local item = require 'ac.item'
local ORDER = require 'ac.war3.order'

local EVENT = {
    Selected    = jass.EVENT_PLAYER_UNIT_SELECTED,
    Deselected  = jass.EVENT_PLAYER_UNIT_DESELECTED,
    Chat        = 96,
    Level       = jass.EVENT_PLAYER_HERO_LEVEL,
    TargetOrder = jass.EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER,
    PickUpItem  = jass.EVENT_PLAYER_UNIT_PICKUP_ITEM,
    DropItem    = jass.EVENT_PLAYER_UNIT_DROP_ITEM,
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
    [EVENT.Level] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        if unit then
            unit:_onLevel()
        end
    end,
    [EVENT.TargetOrder] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetOrderTargetItem()
        if handle ~= 0 then
            local order = jass.GetIssuedOrderId()
            if order == ORDER['smart'] then
                item.onLootOrder(unit, handle)
            end
        end
    end,
    [EVENT.PickUpItem] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetManipulatedItem()
        item.onPickUp(unit, handle)
    end,
    [EVENT.DropItem] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetManipulatedItem()
        ac.wait(0, function ()
            item.onDrop(unit, handle)
        end)
    end,
}

return function ()
    local trg = jass.CreateTrigger()
    for i = 0, 15 do
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Selected, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Deselected, nil)
        jass.TriggerRegisterPlayerChatEvent(trg, jass.Player(i), '', false)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Level, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.TargetOrder, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.PickUpItem, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.DropItem, nil)
    end
    jass.TriggerAddCondition(trg, jass.Condition(function ()
        local eventId = jass.GetTriggerEventId()
        if CallBack[eventId] then
            CallBack[eventId]()
        end
    end))
end
