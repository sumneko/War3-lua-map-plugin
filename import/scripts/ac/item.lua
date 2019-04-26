local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local Pool
local Cache = {}
local Items = {}
local Count = 0

local METHOD = {
    ['onAdd']     = '物品-获得',
    ['onRemove']  = '物品-失去',
    ['onCanAdd']  = '物品-即将获得',
    ['onCanLoot'] = '物品-即将拾取',
    ['onCanBuy']  = '物品-即将购买',
}

local mt = {}
mt.__index = mt
mt.type = 'item'
mt._handle = 0

function mt:__tostring()
    return ('{item|%s|%s}'):format(self._name, self._count)
end

local function poolAdd(id)
    Pool[#Pool+1] = id
end

local function poolGet()
    local max = #Pool
    if max == 0 then
        return nil
    end
    local id = Pool[max]
    Pool[max] = nil
    return id
end

local function init()
    if Pool then
        return
    end
    Pool = {}
    for id, item in pairs(slk.item) do
        local name = item.Name
        if name and name:sub(1, 7) == '@神符' then
            poolAdd(id)
        end
    end
end

local function callMethod(item, name, ...)
    local method = item[name]
    if not method then
        return
    end
    local suc, res, data = xpcall(method, log.error, item, ...)
    if suc then
        return res, data
    end
end

local function eventNotify(item, unit, name, ...)
    local event = METHOD[name]
    if event then
        item:eventNotify(event, item, ...)
        unit:eventNotify(event, item, ...)
    end
    callMethod(item, name, ...)
end

local function eventDispatch(item, unit, name, ...)
    local event = METHOD[name]
    if event then
        local res, data = item:eventDispatch(event, item, ...)
        if res ~= nil then
            return res, data
        end
        local res, data = unit:eventDispatch(event, item, ...)
        if res ~= nil then
            return res, data
        end
    end
    return callMethod(item, name, ...)
end

local function findFirstEmptyInBag(unit)
    for i = 1, jass.UnitInventorySize(unit._handle) do
        if jass.UnitItemInSlot(unit._handle, i-1) == 0 then
            return i
        end
    end
    return nil
end

local function addAttribute(item)
    local unit = item._owner
    if ac.isTable(item.attribute) then
        item._addedAttribute = {}
        for k, v in pairs(item.attribute) do
            item._addedAttribute[#item._addedAttribute+1] = unit:add(k, v)
        end
    end
end

local function onAdd(item)
    local unit = item._owner
    eventNotify(item, unit, 'onAdd')
end

local function onRemove(item)
    local unit = item._owner
    if item._addedAttribute then
        for _, destroyer in ipairs(item._addedAttribute) do
            destroyer()
        end
    end
    eventNotify(item, unit, 'onRemove')
    item._owner = nil
end

local function createItemDummySkill(item)
    local skillName = item._name .. '-马甲技能'
    if ac.table.skill[skillName] then
        local name
        local ok
        for i = 1, 1000 do
            name = skillName .. tostring(i)
            if not ac.table.skill[name] then
                skillName = name
                ok = true
                break
            end
        end
        if not ok then
            return nil
        end
    end
    ac.table.skill[skillName] = {
        passive = 1,
    }
    return skillName
end

local function fillSkillData(skillName, itemData)
    local skill = ac.skill[skillName]
    for k, v in pairs(itemData) do
        if skill[k] == nil then
            skill[k] = v
        end
    end
end

local function addSkill(item, slot)
    local unit = item._owner
    local skillName = item._data.skill
    if not skillName then
        skillName = createItemDummySkill(item)
    end
    if skillName then
        fillSkillData(skillName, ac.table.item[item._name])
        if not slot then
            slot = findFirstEmptyInBag(unit)
        end
        unit:addSkill(skillName, '物品', slot, function (skill)
            skill._item = item
            item._skill = skill
            skill:stack(item._stack)
            if item._targetCd then
                local remaining = item._targetCd - ac.clock()
                if remaining > 0.0 then
                    skill:activeCd()
                    skill:setCd(remaining)
                end
            end
            if skill._icon then
                jass.SetItemDroppable(skill._icon._handle, item.drop == 1)
                Items[skill._icon._handle] = item
            end
        end)
        addAttribute(item)
    end
end

local function isSlotEmpty(unit, slot)
    if slot < 1 or slot > jass.UnitInventorySize(unit._handle) then
        return false
    end
    if jass.UnitItemInSlot(unit._handle, slot-1) == 0 then
        return true
    else
        return false
    end
end

local function addToUnit(item, unit, slot)
    if item._removed then
        return false
    end
    local res, data = eventDispatch(item, unit, 'onCanAdd', unit)
    if res == false then
        return false, data
    end
    if res ~= true and not item:isRune() then
        if unit:isBagFull() then
            return false
        end
        if slot and not isSlotEmpty(unit, slot) then
            return false
        end
    end
    item._owner = unit
    local handle = item._handle
    item._handle = 0
    if handle ~= 0 then
        Items[handle] = nil
        jass.RemoveItem(handle)
    end

    if not item:isRune() then
        addSkill(item, slot)
    end

    onAdd(item)
    return true
end

local function create(name, target, slot)
    init()

    local data = ac.item[name]
    if not data then
        return nil
    end

    local id = poolGet()
    if not id then
        log.error('无法分配新的物品')
        return nil
    end

    if not Cache[id] then
        Cache[id] = {}
    end

    Count = Count + 1

    local self = setmetatable({
        _id = id,
        _data = data,
        _slk = slk.item[id],
        _cache = Cache[id],
        _count = Count,
    }, data)
	local hero
	if ac.isUnit(target) then
		if self:isRune() or target:isAlive() then
			local suc, data = addToUnit(self, target, slot)
	        if not suc then
	            return nil, data
	        end
	    --如果单位死亡是不能创建物品到物品栏的，因此非神符的物品无法被创建
		else
			if target:isHero() then
				--先把物品创建在地上并隐藏，等英雄复活了再丢给英雄
				hero = target
				target = target:getPoint()
			else
				return nil,data
			end
		end
    elseif ac.isPoint(target) then
        local x, y = target:getXY()
        self._handle = jass.CreateItem(ac.id[id], x, y)
        if self._handle == 0 then
            poolAdd(id)
            return nil
        end
        self:updateAll()
        Items[self._handle] = self
    else
        return nil
    end
	if hero then
		self:hide()
		local trg
		trg = hero:event('单位-复活',function()
			self:give(hero,slot)
			trg:remove()
		end)
	end
    return self
end

local function createDefine(name)
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return nil
    end
    local define = setmetatable({
        _name = name,
    }, mt)
    define.__index = define
    define.__tostring = mt.__tostring
    for k, v in pairs(data) do
        define[k] = v
    end
    return define
end

local function onLootOrder(unit, handle)
    local item = Items[handle]
    if not item then
        return
    end
    local res = eventDispatch(item, unit, 'onCanLoot', unit)
    if res == true then
        return
    end
    if res == false or unit:isBagFull() then
        unit:stop()
    end
end

local function drop(item, point)
    local skill = item._skill
    if not skill then
        return
    end
    item._stack = skill._stack
    item._targetCd = ac.clock() + skill:getCd()
    item._skill = nil
    skill._item = nil
    if skill._icon then
        Items[skill._icon._handle] = nil
    end
    skill:remove()

    local id = item._id
    local x, y = point:getXY()
    item._handle = jass.CreateItem(ac.id[id], x, y)
    if item._handle == 0 then
        item:remove()
        return nil
    end

    if not item:isShow() then
        jass.SetItemVisible(item._handle, false)
    end

    item:updateAll()

    Items[item._handle] = item

    onRemove(item)

    return item
end

local function onPawn(unit, handle)
	local item = Items[handle]	
	local sell = {}
	if type(item.price) == 'table' then
        for _,data in ipairs(item.price) do
	        sell[data.type] = data.value
        end
    end
	unit:eventNotify('单位-出售物品',unit,item,sell)
	--默认原价贩卖，可通过修改sell更改贩卖价格
	local player = unit:getOwner()
	for name,value in pairs(sell) do
		player:add(name,value)
		--漂浮文字
		if name == '金币' and value > 0 then
			ac.textTag()
	            : text('|cffffdd00+'..math.floor(value)..'|n', 0.025)
	            : at(unit:getPoint(),140)
	            : speed(0.025, 90)
	            : life(1.5, 0.8)
	            : show(function(p)
	                return player == p
	            end)
        elseif name == '木材' and value > 0 then
	        ac.textTag()
	            : text('|cff25cc75+'..math.floor(value)..'|n', 0.025)
	            : at(unit:getPoint(), 100)
	            : speed(0.025, 90)
	            : life(1.5, 0.8)
	            : show(function (p)
	                return player == p
	            end)
        end
	end
	item:remove()
end

local function onDrop(unit, handle)
    local x = jass.GetItemX(handle)
    local y = jass.GetItemY(handle)
    local item = Items[handle]
    jass.RemoveItem(handle)
    if item then
	    unit:eventNotify('单位-丢弃物品', unit, item)
        if item._owner ~= unit then
            return
        end
        return drop(item, ac.point(x, y))
    end
end

local function onPickUp(unit, handle)
    local item = Items[handle]
    if not item then
        return
    end

    drop(item, unit:getPoint())
    local suc = addToUnit(item, unit)
    if suc then
        return
    end

    local x, y = item:getXY()

    Items[handle] = nil
    jass.RemoveItem(handle)
    item._handle = jass.CreateItem(ac.id[item._id], x, y)
    if item._handle == 0 then
        item:remove()
        return nil
    end
    Items[item._handle] = item
    if not item:isShow() then
        jass.SetItemVisible(item._handle, false)
    end
end

local function onCanBuy(itemData, buyer, shop)
    return eventDispatch(itemData, buyer, 'onCanBuy', buyer, shop)
end

local function findItem(unit, name)
    if not unit._skill then
        return nil
    end
    for skill in unit._skill:eachSkill '物品' do
        if skill._item and skill._item._name == name then
            return skill._item
        end
    end
    return nil
end

local function eachItem(unit)
    if not unit._skill then
        return function () end
    end
    local items = {}
    for skill in unit._skill:eachSkill '物品' do
        if skill._item then
            items[#items+1] = skill._item
        end
    end
    local i = 0
    return function ()
        i = i + 1
        return items[i]
    end
end

local function findByHandle(handle)
    return Items[handle]
end

local function loadString(skill, str)
    return str:gsub('${(.-)}', function (pat)
        local pos = pat:find(':', 1, true)
        if pos then
            local key = pat:sub(1, pos-1)
            local f, err = load('return '..key, key, "t", skill)
            if not f then
                return err
            end
            local value = f()
            local fmt = pat:sub(pos+1)
            return ('%'..fmt):format(value)
        else
            local f, err = load('return '..pat, pat, "t", skill)
            if not f then
                return err
            end
            local value = f()
            return tostring(value)
        end
    end)
end

function mt:updateTitle()
    local item = self._data
    local skill = item.skill and ac.skill[item.skill]
    local title = skill and skill.title and skill.title[1] or item.title or item.name or self._name
    title = self:loadString(title)
    if title == self._cache.title then
        return
    end
    self._cache.title = title
    japi.EXSetItemDataString(ac.id[self._id], 4, title)
end

function mt:updateDescription()
    local item = self._data
    local skill = item.skill and ac.skill[item.skill]
    local desc = skill and skill.description and skill.description[1] or item.description
    desc = self:loadString(desc)
    if desc == self._cache.description then
        return
    end
    self._cache.description = desc
    japi.EXSetItemDataString(ac.id[self._id], 5, desc)
end

function mt:loadString(str)
    str = tostring(str)

    local skillName = self._data.skill
    local skillTable = ac.table.skill[skillName]

    local skill = setmetatable({}, {__index = function (_, k)
        local v = skillTable and skillTable[k] or self._data[k]
        return v
    end})

    local suc, res = pcall(loadString, skill, str)
    if suc then
        return res
    else
        return str
    end
end

function mt:updateAll()
    self:updateTitle()
    self:updateDescription()
end

function mt:getOwner()
    return self._owner
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true

    if self._handle == 0 then
        drop(self, self._owner:getPoint())
    end

    local handle = self._handle
    local id = self._id
    self._handle = 0
    self._id = nil

    Items[handle] = nil
    jass.RemoveItem(handle)
    poolAdd(id)
end

function mt:blink(point)
    local x, y = point:getXY()
    if self._handle == 0 then
        drop(self, point)
    else
        jass.SetItemPosition(self._handle, x, y)
    end
end

function mt:eventDispatch(name, ...)
    local res, data = ac.eventDispatch(self, name, ...)
    return res, data
end

function mt:eventNotify(event, ...)
    ac.eventNotify(self, event, ...)
end

function mt:getName()
    return self._name
end

function mt:isRune()
    return self.rune == 1
end

function mt:give(unit, slot)
    if self._removed then
        return false
    end
    if not ac.isUnit(unit) then
        return false
    end
    -- 如果单位和格子完全相同，就什么都不做
    if unit == self._owner and slot == self._skill._slot then
        return false
    end
    -- 检查目标位置是否合法
    if not self:isRune() then
        if slot then
            if not isSlotEmpty(unit, slot) then
                return false
            end
        else
            if unit:isBagFull() then
                return false
            end
        end
    end
    -- 如果在自己身上，则当场移动一下
    if self._owner == unit then
        self._skill._slot = slot
        if self._skill._icon then
            local suc = self._skill._icon:updateSlot()
            if not suc then
                return false
            end
            jass.SetItemDroppable(self._skill._icon._handle, self.drop == 1)
        end
        return false
    end
    -- 如果在其他人身上，则先扔到地上
    if self._owner then
        if self._skill._icon then
            Items[self._skill._icon._handle] = nil
        end
        self._stack = self._skill._stack
        self._targetCd = self._skill:getCd() + ac.clock()
        self._skill:remove()
        onRemove(self)
    end
    -- 添加给单位
    return addToUnit(self, unit, slot)
end

function mt:getSlot()
    if self._skill then
        return self._skill._slot
    else
        return 0
    end
end

function mt:stack(n)
    if ac.isNumber(n) then
        self._stack = n
        if self._skill then
            self._skill:stack(self._stack)
        end
    else
        if self._skill then
            return self._skill:stack()
        else
            return self._stack or 0
        end
    end
end

function mt:getPoint()
    if self._owner then
        return self._owner:getPoint()
    else
        return ac.point(jass.GetItemX(self._handle), jass.GetItemY(self._handle))
    end
end

function mt:getXY()
    if self._owner then
        return self._owner:getXY()
    else
        return jass.GetItemX(self._handle), jass.GetItemY(self._handle)
    end
end

function mt:show()
    self._hide = (self._hide or 0) - 1
    if self._hide == 0 then
        jass.SetItemVisible(self._handle, true)
    end
end

function mt:hide()
    self._hide = (self._hide or 0) + 1
    if self._hide == 1 then
        jass.SetItemVisible(self._handle, false)
    end
end

function mt:isShow()
    if not self._hide then
        return true
    end
    if self._hide == 0 then
        return true
    end
    return false
end

ac.item = setmetatable({}, {
    __index = function (self, name)
        local item = createDefine(name)
        if item then
            self[name] = item
            return item
        else
            return nil
        end
    end,
})

return {
    create = create,
    onLootOrder = onLootOrder,
    onPickUp = onPickUp,
    onPawn = onPawn,
    onDrop = onDrop,
    onCanBuy = onCanBuy,
    findItem = findItem,
    eachItem = eachItem,
    findByHandle = findByHandle,
    items = Items,
}
