local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local Pool
local Cache = {}
local Items = {}

local METHOD = {
    ['onAdd']     = '物品-获得',
    ['onRemove']  = '物品-失去',
    ['onCanAdd']  = '物品-即将获得',
    ['onCanLoot'] = '物品-即将拾取',
}

local mt = {}
mt.__index = mt
mt.type = 'item'
mt._handle = 0

function mt:__tostring()
    return ('{item|%s|%s}'):format(self._name, self._handle)
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
    local suc, res = xpcall(method, log.error, item, ...)
    if suc then
        return res
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
        local res = item:eventDispatch(event, item, ...)
        if res ~= nil then
            return res
        end
        local res = unit:eventDispatch(event, item, ...)
        if res ~= nil then
            return res
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
    return 0
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

local function fillSkillData(skillName, item)
    local skill = ac.skill[skillName]
    if skill.title == nil then
        skill.title = item.title
    end
    if skill.description == nil then
        skill.description = item.description
    end
    if skill.icon == nil then
        skill.icon = item.icon
    end
end

local function addSkill(item, slot)
    local unit = item._owner
    local skillName = item._data.skill
    if not skillName then
        skillName = createItemDummySkill(item)
    end
    if skillName then
        fillSkillData(skillName, item)
        if not slot then
            slot = findFirstEmptyInBag(unit)
        end
        local skill = unit:addSkill(skillName, '物品', slot)
        if skill then
            skill._item = item
            item._skill = skill
            if skill._icon then
                jass.SetItemDroppable(skill._icon._handle, item.drop == 1)
            end
        end
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
    if unit:isBagFull() then
        return false
    end
    if slot and not isSlotEmpty(unit, slot) then
        return false
    end
    if eventDispatch(item, unit, 'onCanAdd', unit) == false then
        return false
    end
    item._owner = unit
    local id = item._id
    local handle = item._handle
    item._handle = 0
    item._id = nil
    if handle ~= 0 then
        Items[handle] = nil
        jass.RemoveItem(handle)
    end
    poolAdd(id)

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

    local self = setmetatable({
        _id = id,
        _name = name,
        _data = data,
        _slk = slk.item[id],
        _cache = Cache[id],
    }, data)

    if ac.isPoint(target) then
        local x, y = target:getXY()
        self._handle = jass.CreateItem(ac.id[id], x, y)
        if self._handle == 0 then
            poolAdd(id)
            return nil
        end
        self:updateAll()
        Items[self._handle] = self
    elseif ac.isUnit(target) then
        if not addToUnit(self, target, slot) then
            return nil
        end
    else
        return nil
    end

    return self
end

local function createDefine(name)
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return nil
    end
    local define = setmetatable({}, mt)
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
    if unit:isBagFull() then
        unit:stop()
    end
    if eventDispatch(item, unit, 'onCanLoot', unit) == false then
        unit:stop()
    end
end

local function onPickUp(unit, handle)
    local item = Items[handle]
    if not item then
        return
    end

    local suc = addToUnit(item, unit)
    if suc then
        return
    end

    local x = jass.GetItemX(handle)
    local y = jass.GetItemY(handle)

    Items[handle] = nil
    jass.RemoveItem(handle)
    item._handle = jass.CreateItem(ac.id[item._id], x, y)
    Items[item._handle] = item
end

local function onDrop(unit, handle)
    local x = jass.GetItemX(handle)
    local y = jass.GetItemY(handle)
    local item
    for skill in unit:eachSkill '物品' do
        if skill._icon and skill._icon._handle == handle then
            item = skill._item
            skill:remove()
            break
        end
    end
    if not item then
        return nil
    end

    local id = poolGet()
    if not id then
        log.error('无法分配新的物品')
        return nil
    end

    item._id = id
    item._handle = jass.CreateItem(ac.id[id], x, y)
    if item._handle == 0 then
        item:remove()
        return nil
    end

    item:updateAll()

    Items[item._handle] = item

    onRemove(item)

    return item
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

function mt:updateTitle()
    local item = self._data
    local title = item.title or item.name or item._name
    if title == self._cache.title then
        return
    end
    self._cache.title = title
    japi.EXSetItemDataString(ac.id[self._id], 4, title)
end

function mt:updateDescription()
    local item = self._data
    local desc = item.description
    if desc == self._cache.description then
        return
    end
    self._cache.description = desc
    japi.EXSetItemDataString(ac.id[self._id], 5, desc)
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
        self._skill:remove()
        onRemove(self)
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
        if self._skill._icon then
            jass.SetItemPosition(self._skill._icon._handle, x, y)
        end
    else
        jass.SetItemPosition(self._handle, x, y)
    end
end

function mt:eventDispatch(name, ...)
    local res = ac.eventDispatch(self, name, ...)
    return res
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
    if not ac.isUnit(unit) then
        return false
    end
    -- 如果单位和格子完全相同，就什么都不做
    if unit == self._owner and slot == self._skill._slot then
        return false
    end
    -- 检查目标位置是否合法
    if slot then
        if not isSlotEmpty(unit, slot) then
            return false
        end
    else
        if unit:isBagFull() then
            return false
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
        self._skill:remove()
        onRemove(self)
    end
    -- 添加给单位
    addToUnit(self, unit, slot)
    return true
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
    onDrop = onDrop,
    findItem = findItem,
    eachItem = eachItem,
}
