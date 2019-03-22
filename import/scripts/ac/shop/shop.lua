local jass = require 'jass.common'
local japi = require 'jass.japi'
local item = require 'ac.item'

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

local function activeCd(skill, item)
    local cd = ac.toNumber(item.cool)
    if cd > 0 then
        skill:activeCd(cd)
    end
end

local function checkBag(shop, itemData, buyer)
    local res, msg = item.onCanBuy(itemData, buyer, shop)
    if res ~= nil then
        return res, msg
    end
    if itemData.rune == 1 then
        return true
    end
    if buyer:isBagFull() then
        return false, '购买者物品栏已满'
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

local function setItemShow(itemSkill, buyerSkill)
    if buyerSkill then
        itemSkill:setOption('title', buyerSkill.title)
        itemSkill:setOption('description', buyerSkill._loadedDescription or buyerSkill.description)
        itemSkill:setOption('icon', buyerSkill.icon)
        itemSkill:stack(buyerSkill:stack())
    else
        itemSkill:setOption('title', '空')
        itemSkill:setOption('description', '')
        itemSkill:setOption('icon', ac.table.skill['@商店物品栏'].icon)
        itemSkill:stack(0)
    end
end

local mt = {}
mt.__index = mt
mt.type = 'shop'
mt.range = 9999999

function mt:__tostring()
    return ('{shop|%s}'):format(self._unit:getName())
end

function mt:getItem(name)
    local unit = self._unit
    return unit:findSkill(name, '技能')
end

function mt:removeItem(name)
    local unit = self._unit
    local skill = unit:findSkill(name, '技能')
    if skill then
        return skill:remove()
    end
    return false
end

function mt:setItem(name, index, hotkey)
    local unit = self._unit
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return false
    end
    local skill = unit:addSkill('@商店物品', '技能', index)
    if not skill then
        log.error(('物品[%s]添加失败'):format(name))
        return false
    end
    skill.item = data
    skill.itemName = name
    skill.shop = self
    skill.index = index

    for k, v in pairs(data) do
        if skill[k] == nil then
            skill[k] = v
        end
    end

    skill:update()

    skill:setOption('hotkey', hotkey)
    return true
end

function mt:buyItem(name, buyer)
    local player
    if ac.isPlayer(buyer) then
        player = buyer
        buyer = nil
    elseif ac.isUnit(buyer) then
        player = buyer:getOwner()
    else
        return nil, '没有指定购买单位或购买玩家'
    end
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

    suc, err = checkBag(self, ac.item[name], buyer)
    if not suc then
        return nil, err
    end

    suc, err = checkItemPrice(player, data)
    if not suc then
        return nil, err
    end

    local item, err = buyer:createItem(name)
    if not item then
        return nil, err or '购买失败'
    end

    return item
end

function mt:setBuyRange(n)
    self.range = n
end

function mt:buyItemByClient(index, player)
    local unit = self._unit
    local item, err
    local skill = unit:findSkill(index, '技能')
    if skill then
        if skill:getCd() > 0.0 then
            return
        end
        item, err = self:buyItem(skill.itemName, player)
    else
        err = '未找到物品'
    end
    if item then
        costPrice(player, item)
        activeCd(skill, item)
        self:updateItem()
        return
    end
    if err then
        player:message {
            text = '{err}',
            data = {
                err = err,
            },
            color = {
                err = 'ffff11',
            }
        }
    end
end

function mt:updateItem()
    local buyer = checkBuyer(self, ac.localPlayer())
    local unit = self._unit
    if buyer then
        for i = 1, 6 do
            local shopSkill = unit:findSkill(i, '物品')
            if shopSkill then
                local buyerSkill = buyer:findSkill(i, '物品')
                setItemShow(shopSkill, buyerSkill)
            end
        end
    else
        for i = 1, 6 do
            local shopSkill = unit:findSkill(i, '物品')
            if shopSkill then
                setItemShow(shopSkill, nil)
            end
        end
    end
end

local function create(unit)
    local shop = setmetatable({
        _unit = unit,
        _private = ac.list()
    }, mt)
    unit:bagSize(6)
    jass.UnitAddAbility(unit._handle, ac.id['@SLC'])

    for i = 1, 6 do
        unit:addSkill('@商店物品栏', '物品', i)
    end

    unit._shop = shop

    shop._timer = ac.loop(1, function ()
        shop:updateItem()
    end)
    shop._trg1 = ac.game:event('物品-获得', function ()
        shop:updateItem()
    end)
    shop._trg2 = ac.game:event('物品-失去', function ()
        shop:updateItem()
    end)
    shop._trg3 = ac.game:event('物品-移动', function ()
        shop:updateItem()
    end)

    return shop
end

local function onDead(shop)
    local unit = shop._unit
    for i = 1, 6 do
        local skill = unit:findSkill(i, '物品')
        if skill then
            skill:remove()
        end
    end
    shop._timer:remove()
    shop._trg1:remove()
    shop._trg2:remove()
    shop._trg3:remove()
end

return {
    create = create,
    onDead = onDead,
}
