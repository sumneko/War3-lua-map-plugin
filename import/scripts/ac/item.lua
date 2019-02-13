local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local Pool
local Cache = {}
local Items = {}
local SLOT_MAX = 6

local mt = {}
mt.__index = mt
mt.type = 'item'

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

local function create(name, target)
    init()

    local data = ac.item[name]
    if not data then
        return
    end

    local id = poolGet()
    if not id then
        log.error('无法分配新的物品')
        return nil
    end

    local handle
    if ac.isPoint(target) then
        local x, y = target:getXY()
        handle = jass.CreateItem(ac.id[id], x, y)
        if handle == 0 then
            poolAdd(id)
            return nil
        end
    end

    if not Cache[id] then
        Cache[id] = {}
    end

    local self = setmetatable({
        _id = id,
        _handle = handle,
        _name = name,
        _data = data,
        _slk = slk.item[id],
        _cache = Cache[id],
    }, mt)

    self:updateAll()

    Items[handle] = self

    return self
end

local function createDefine(name)
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return nil
    end
    return setmetatable({}, { __index = data })
end

local function isBagFull(unit)
    for i = 1, SLOT_MAX do
        if jass.UnitItemInSlot(unit._handle, i-1) == 0 then
            return false
        end
    end
    return true
end

local function findFirstEmptyInBag(unit)
    for i = 1, SLOT_MAX do
        if jass.UnitItemInSlot(unit._handle, i-1) == 0 then
            return i
        end
    end
    return 0
end

local function onLootOrder(unit, handle)
    local item = Items[handle]
    if not item then
        return
    end
    if isBagFull(unit) then
        unit:stop()
    end
end

local function onPickUp(unit, handle)
    local item = Items[handle]
    if not item then
        return
    end

    if isBagFull(unit) then
    end

    local id = item._id
    item._handle = 0
    item._id = nil
    Items[handle] = nil
    jass.RemoveItem(handle)
    poolAdd(id)

    local skillName = item._data.skill
    if skillName then
        local slot = findFirstEmptyInBag(unit)
        local skill = unit:addSkill(skillName, '物品', slot)
        if skill then
            skill._item = item
        end
    end
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

    return item
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

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    local handle = self._handle
    local id = self._id
    self._handle = 0
    self._id = nil

    Items[handle] = nil
    jass.RemoveItem(handle)
    poolAdd(id)
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
}
