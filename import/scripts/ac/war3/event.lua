local jass = require 'jass.common'
local item = require 'ac.item'
local ORDER = require 'ac.war3.order'

local EVENT = {
    Selected    = jass.EVENT_PLAYER_UNIT_SELECTED,
    Deselected  = jass.EVENT_PLAYER_UNIT_DESELECTED,
    Chat        = 96,
    Level       = jass.EVENT_PLAYER_HERO_LEVEL,
    Order		= jass.EVENT_PLAYER_UNIT_ISSUED_ORDER,
    PointOrder	= jass.EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER,
    TargetOrder = jass.EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER,
    PickUpItem  = jass.EVENT_PLAYER_UNIT_PICKUP_ITEM,
    DropItem    = jass.EVENT_PLAYER_UNIT_DROP_ITEM,
    Leave		= jass.EVENT_PLAYER_LEAVE,
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
    [EVENT.Order] = function ()
    	local unit = ac.unit(jass.GetTriggerUnit())
    	if unit then
	        local order = jass.GetIssuedOrderId()
	        local orderList = {
				['stop'] = '停止',
				['holdposition'] = '保持原位',
				['patrol'] = '警戒',
			}
	        local orderID = orderList[ORDER[order]]
	        if orderID then
		        unit:eventNotify('单位-发布命令', unit, orderID, nil)
	        end
        end
    end,
    [EVENT.PointOrder] = function ()
    	local unit = ac.unit(jass.GetTriggerUnit())
    	if unit then
	    	local order = jass.GetIssuedOrderId()
	    	local orderList = {
				['smart'] = '移动',
				['attack'] = '攻击',
				['patrol'] = '巡逻',
				['move'] = '移动',
				['AImove'] = '休眠',
			}
	        local orderID = orderList[ORDER[order]]
	        local x = jass.GetOrderPointX()
	        local y = jass.GetOrderPointY()
	        local target = ac.point(x,y)
	        if orderID and target then
	        	unit:eventNotify('单位-发布命令', unit, orderID, target)
	    	end
    	end
    end,
    [EVENT.TargetOrder] = function ()
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetOrderTargetItem()
        local order = jass.GetIssuedOrderId()
        --抛出事件
        local target = ac.unit(jass.GetOrderTargetUnit())
        if target then
			local orderList = {
				['smart'] = function()
					if unit:isEnemy(target) then
						return '攻击'
					else
						return '跟随'
					end
				end,
				['attack'] = '攻击',
				['patrol'] = '跟随',
			}
	        local orderID = orderList[ORDER[order]]
	        if orderID then
	        	unit:eventNotify('单位-发布命令', unit, orderID, target)
	    	end
    	end
        --拾取物品
        if handle ~= 0 then
            if order == ORDER['smart'] then
                item.onLootOrder(unit, handle)
            end
        end
    end,
    [EVENT.PickUpItem] = function ()
        if ac.world.flag 'ignore item' then
            return
        end
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetManipulatedItem()
        item.onPickUp(unit, handle)
    end,
    [EVENT.DropItem] = function ()
        if ac.world.flag 'ignore item' then
            return
        end
        local unit = ac.unit(jass.GetTriggerUnit())
        local handle = jass.GetManipulatedItem()
        ac.wait(0, function ()
            item.onDrop(unit, handle)
        end)
    end,
    [EVENT.Leave] = function()
    	local player = ac.player(jass.GetTriggerPlayer())
        if player and not player._isRemove then
            player:remove('失败')
        end
	end,
}

return function ()
    local trg = jass.CreateTrigger()
    for i = 0, 15 do
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Selected, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Deselected, nil)
        jass.TriggerRegisterPlayerChatEvent(trg, jass.Player(i), '', false)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Level, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.Order, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.PointOrder, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.TargetOrder, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.PickUpItem, nil)
        jass.TriggerRegisterPlayerUnitEvent(trg, jass.Player(i), EVENT.DropItem, nil)
        jass.TriggerRegisterPlayerEvent(trg, jass.Player(i), EVENT.Leave)
    end
    jass.TriggerAddCondition(trg, jass.Condition(function ()
        local eventId = jass.GetTriggerEventId()
        if CallBack[eventId] then
            CallBack[eventId]()
        end
    end))
end
