local mt = {}
mt.__index = mt

mt.type = 'damage'
mt.source = nil
mt.target = nil
mt.damage = 0.0
mt.currentDamage = 0.0

local function onDefence(damage)
    local def = damage.target:get '护甲'
    if def < 0 then
        --每点负护甲相当于受到的伤害加深1%
        damage.currentDamage = damage.currentDamage * (1 - 0.01 * def)
    elseif def > 0 then
        --每点护甲相当于生命值增加1%
        damage.currentDamage = damage.currentDamage / (1 + 0.01 * def)
    end
end

local function costLife(damage)
    damage.target:add('生命', - damage.currentDamage)
end

local function checkKill(damage)
    if damage.target:get '生命' <= 0 then
        damage.source:kill(damage.target)
    end
end

local function notifyEvent(damage)
    damage.source:eventNotify('单位-造成伤害', damage.source, damage)
    damage.target:eventNotify('单位-受到伤害', damage.target, damage)
end

local function create(data)
    local damage = setmetatable(data, mt)
    return damage
end

local function dispatch(damage)
    local source = damage.source
    local target = damage.target
    local skill = damage.skill
    if not source then
        error('伤害没有来源')
    end
    if not target then
        error('伤害没有目标')
    end
    if not skill then
        error('伤害没有关联技能')
    end

    damage.currentDamage = damage.damage

    -- 检查伤害是否被上层接管
    local result = ac.game:eventDispatch('游戏-造成伤害', damage)
    if result ~= nil then
        return result
    end

    -- 如果没有上层接管伤害流程，则进行一套简单的默认流程
    onDefence(damage)
    costLife(damage)
    checkKill(damage)

    notifyEvent(damage)

    return true
end

return {
    dispatch = dispatch,
    create   = create,
}
