local jass = require 'jass.common'

local mt = {}
mt.__index = mt
mt.type = 'shop'
mt.range = 9999999

function mt:__tostring()
    return ('{shop|%s}'):format(self._unit:getName())
end

function mt:setItem(index, name)
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
end

function mt:canBuy(buyer)
    if not ac.isUnit(buyer) then
        return false, '没有购买者'
    end
    if not buyer:isAlive() then
        return false, '购买者已经死亡'
    end
    local unit = self._unit
    local range = unit:getPoint() * buyer:getPoint()
    if range > self.range then
        return false, '购买者距离太远'
    end
    return true
end

function mt:checkBuyer(player, buyer)
    if buyer then
        local suc, err = self:canBuy(buyer)
        if not suc then
            return nil, err
        end
    else
        for hero in player:eachHero() do
            if self:canBuy(hero) then
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

function mt:checkItemPrice(player, item)
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

function mt:costPrice(player, item)
    if type(item.price) == 'table' then
        for _, data in ipairs(item.price) do
            player:add(data.type, - data.value)
        end
    end
end

function mt:checkBag(buyer, item)
    if buyer:isBagFull() then
        return false, '购买者物品栏已满'
    end
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

    buyer, err = self:checkBuyer(player, buyer)
    if not buyer then
        return nil, err
    end

    suc, err = self:checkBag(buyer, data)
    if not suc then
        return nil, err
    end

    suc, err = self:checkItemPrice(player, data)
    if not suc then
        return nil, err
    end

    local item = buyer:createItem(name)
    if not item then
        return nil, '购买失败'
    end

    self:costPrice(player, item)

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
