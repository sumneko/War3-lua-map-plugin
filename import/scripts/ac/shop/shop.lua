local jass = require 'jass.common'

local function canBuy(shop, buyer)
    if not ac.isUnit(buyer) then
        return false, '没有购买者'
    end
    if not buyer:isAlive() then
        return false, '购买者已经死亡'
    end
    local unit = shop._unit
    local range = unit:getPoint() * buyer:getPoint()
    if range > shop.range then
        return false, '购买者距离太远'
    end
    return true
end

local function checkBuyer(shop, player, buyer)
    if buyer then
        local suc, err = canBuy(shop, buyer)
        if not suc then
            return nil, err
        end
    else
        for hero in player:eachHero() do
            if canBuy(shop, hero) then
                buyer = hero
                break
            end
        end
        if not buyer then
            return nil, '附近没有购买者'
        end
    end
    return buyer
end

local function checkItemPrice(player, item)
    if type(item.price) == 'table' then
        for _, data in ipairs(item.price) do
            local left = player:get(data.type) - data.value
            if left < 0 then
                return false, ('缺少 %.f %s'):format(-left, data.type)
            end
        end
    end
    return true
end

local function costPrice(player, item)
    if type(item.price) == 'table' then
        for _, data in ipairs(item.price) do
            player:add(data.type, - data.value)
        end
    end
end

local function checkBag(buyer)
    if buyer:isBagFull() then
        return false, '购买者物品栏已满'
    end
    return true
end

local mt = {}
mt.__index = mt
mt.type = 'shop'
mt.range = 9999999

function mt:__tostring()
    return ('{shop|%s}'):format(self._unit:getName())
end

function mt:setItem(name, index)
    local unit = self._unit
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return false
    end
    local skill = unit:findSkill(index, '技能') or unit:addSkill('@商店物品', '技能', index)
    skill.item = data
    skill.itemName = name
    skill.shop = self
    skill:update()
    return true
end

function mt:buyItem(name, buyer)
    local player = self._unit:getOwner()
    local data = ac.table.item[name]
    local suc, err
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return nil, '物品不存在'
    end

    buyer, err = checkBuyer(self, player, buyer)
    if not buyer then
        return nil, err
    end

    suc, err = checkBag(buyer)
    if not suc then
        return nil, err
    end

    suc, err = checkItemPrice(player, data)
    if not suc then
        return nil, err
    end

    local item = buyer:createItem(name)
    if not item then
        return nil, '购买失败'
    end

    costPrice(player, item)

    return item
end

function mt:setBuyRange(n)
    self.range = n
end

local function create(unit)
    local shop = setmetatable({
        _unit = unit,
    }, mt)
    unit:removeSkill('@命令')
    unit:addHeight(100000)
    jass.UnitAddAbility(unit._handle, ac.id['AInv'])
    if unit:getOwner() == ac.localPlayer() then
        unit:addHeight(-100000)
    end
    jass.UnitRemoveAbility(unit._handle, ac.id['Amov'])
    return shop
end

return {
    create = create,
}
