local jass = require 'jass.common'
local slk = require 'jass.slk'
local ORDER = require 'ac.war3.order'
local PROTO = require 'ac.message.proto'
local TRG = jass.CreateTrigger()
local CMD_ORDER = ORDER[slk.ability['@CMD'].DataF]

local StackedCommand = nil

local EVENT = {
    Order       = jass.EVENT_PLAYER_UNIT_ISSUED_ORDER,
    PointOrder  = jass.EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER,
    TargetOrder = jass.EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER,
    CastStart   = jass.EVENT_PLAYER_UNIT_SPELL_CHANNEL,
}

for i = 0, 15 do
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.Order, nil)
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.PointOrder, nil)
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.TargetOrder, nil)
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.CastStart, nil)
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.Selected, nil)
    jass.TriggerRegisterPlayerUnitEvent(TRG, jass.Player(i), EVENT.Deselected, nil)
end

local function stackCommand(cmd)
    StackedCommand = cmd
end

local function getStackedCommand()
    return StackedCommand
end

local function pointOrder(unit, order, ...)
    if select('#', ...) == 1 then
        local point = ...
        local x, y = point:getXY()
        jass.IssuePointOrderById(unit._handle, ORDER[order], x, y)
    else
        local x, y = ...
        jass.IssuePointOrderById(unit._handle, ORDER[order], x, y)
    end
end

local function targetOrder(unit, order, target)
    jass.IssueTargetOrderById(unit._handle, ORDER[order], target._handle)
end

local function order(unit, order)
    jass.IssueImmediateOrderById(unit._handle, ORDER[order])
end

local function onProto(unit, id, arg)
    if id == PROTO['休眠'] then
        pointOrder(unit, 'AImove', unit:getPoint() - {unit:getFacing(), 1})
        unit:_stopCastByClient()
    elseif id == PROTO['攻击'] then
        stackCommand '攻击'
    elseif id == PROTO['移动'] then
        stackCommand '移动'
    elseif id == PROTO['巡逻'] then
        stackCommand '巡逻'
    end
end

local function onCommand(unit, target)
    local x = jass.GetOrderPointX()
    local y = jass.GetOrderPointY()
    local cmd = getStackedCommand()
    if not cmd then
        return
    end
    if target then
        if cmd == '攻击' then
            targetOrder(unit, 'attack', target)
            unit:_stopCastByClient()
        elseif cmd == '移动' then
            targetOrder(unit, 'move', target)
            unit:_stopCastByClient()
        elseif cmd == '巡逻' then
            targetOrder(unit, 'patrol', target)
            unit:_stopCastByClient()
        end
    else
        if cmd == '攻击' then
            pointOrder(unit, 'attack', x, y)
            unit:_stopCastByClient()
        elseif cmd == '移动' then
            pointOrder(unit, 'move', x, y)
            unit:_stopCastByClient()
        elseif cmd == '巡逻' then
            pointOrder(unit, 'patrol', x, y)
            unit:_stopCastByClient()
        end
    end
end

local function onPointOrder(unit)
    local orderId = jass.GetIssuedOrderId()
    if orderId == ORDER['AImove'] then
        local id = jass.GetOrderPointX()
        local arg = jass.GetOrderPointY()
        onProto(unit, id, arg)
        return
    elseif orderId == CMD_ORDER then
        onCommand(unit)
        return
    end
end

local function onTargetOrder(unit, target)
    local orderId = jass.GetIssuedOrderId()
    if orderId == CMD_ORDER then
        onCommand(unit, target)
        return
    end
end

local function searchAbilityId(unit, id)
    for skill in unit:eachSkill() do
        if skill._icon and skill._icon._ability == id then
            return skill
        end
    end
    return nil
end

local function onCastStart(unit)
    local id = jass.GetSpellAbilityId()
    if id == ac.id['@CMD'] then
        order(unit, 'stop')
        unit:_stopCastByClient()
    else
        -- 检查发动技能
        local skill = searchAbilityId(unit, ac.id[id])
        if skill then
            local target = ac.unit(jass.GetSpellTargetUnit())
            local x = jass.GetSpellTargetX()
            local y = jass.GetSpellTargetY()
            order(unit, 'stop')
            skill:castByClient(target, x, y)
        end
    end
end

jass.TriggerAddCondition(TRG, jass.Condition(function ()
    local eventId = jass.GetTriggerEventId()
    local unit = ac.unit(jass.GetTriggerUnit())
    if not unit then
        return
    end
    if eventId == EVENT.PointOrder then
        onPointOrder(unit)
    elseif eventId == EVENT.TargetOrder then
        local target = ac.unit(jass.GetOrderTargetUnit())
        if target then
            onTargetOrder(unit, target)
        end
    elseif eventId == EVENT.CastStart then
        onCastStart(unit)
    end
end))
