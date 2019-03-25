local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local iconBlender = require 'ac.icon'

local Pool
local Cache = {}

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
        if name then
            if name:sub(1, #'@物品-') == '@物品-' then
                poolAdd(id)
            end
        end
    end
end

local function releaseId(icon)
    local id = icon._id
    if not id then
        return
    end
    icon._id = nil
    poolAdd(id)
end

local function getSlotMax(unit)
    return jass.UnitInventorySize(unit._handle)
end

local function addItem(icon)
    local id = icon._id
    if not id then
        return false
    end
    local skill = icon._skill
    local unit = skill._owner

    local slot = ac.toInteger(skill._slot)
    if not slot or slot < 1 or slot > getSlotMax(unit) then
        return false
    end
    if jass.UnitItemInSlot(unit._handle, slot-1) ~= 0 then
        return false
    end

    local handle = jass.CreateItem(ac.id[id], 0.0, 0.0)
    if handle == 0 then
        return false
    end
    icon._handle = handle
    icon._ability = icon._slk.abilList
    icon:updateAll()

    local cheeses = {}
    for i = 1, slot - 1 do
        if jass.UnitItemInSlot(unit._handle, i-1) == 0 then
            cheeses[#cheeses+1] = jass.UnitAddItemById(unit._handle, ac.id['@CHE'])
        end
    end
    local suc = jass.UnitAddItem(unit._handle, handle)
    for _, cheese in ipairs(cheeses) do
        jass.RemoveItem(cheese)
    end

    if not suc then
        icon._handle = nil
        icon._ability = nil
        jass.RemoveItem(handle)
        return false
    end

    if skill.passive == 1 or not skill:isEnable() and not skill:getOwner():hasRestriction '禁魔' then
        jass.UnitRemoveAbility(unit._handle, ac.id[icon._ability])
    end
    return true
end

local function removeItem(icon)
    jass.RemoveItem(icon._handle)
    icon._handle = 0
end

local mt = {}
mt.__index = mt
mt.type = 'item icon'

function mt:__tostring()
    return ('{item icon|%s}'):format(self._handle)
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    self._ability = nil
    removeItem(self)
    releaseId(self)
end

function mt:handle()
    local unit = self._skill._owner
    local id = self._ability
    return japi.EXGetUnitAbility(unit._handle, ac.id[id])
end

function mt:updateTitle()
    local skill = self._skill
    local title = skill.title or skill.name or skill._name
    title = skill:loadString(title)
    if title == self._cache.title then
        return
    end
    self._cache.title = title
    japi.EXSetItemDataString(ac.id[self._id], 4, title)
    self:needRefreshItem()
end

function mt:updateDescription()
    local skill = self._skill
    local desc = skill.description
    desc = skill:loadString(desc)
    if desc == self._cache.description then
        return
    end
    skill._loadedDescription = desc
    self._cache.description = desc
    japi.EXSetItemDataString(ac.id[self._id], 3, desc)
    self:needRefreshItem()
end

function mt:updateIcon()
    local skill = self._skill
    local icon = skill.icon
    if not skill:isEnable() then
        icon = iconBlender.getDisIcon(icon)
    end
    if icon == self._cache.icon then
        return
    end
    self._cache.icon = icon
    japi.EXSetItemDataString(ac.id[self._id], 1, icon)
    self:needRefreshItem()
end

function mt:updateHotkey()
end

function mt:updateRange()
    local skill = self._skill
    local range = ac.toNumber(skill.range)
    if range == self._cache.range then
        return
    end
    self._cache.range = range
    japi.EXSetAbilityDataReal(self:handle(), 1, 0x6B, range)
end

function mt:updateTargetType()
    local skill = self._skill
    local targetType = skill.targetType
    if self._cache.targetType == targetType then
        return
    end
    self._cache.targetType = targetType
    if targetType == '单位' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 1)
        japi.EXSetAbilityDataInteger(self:handle(), 1, 0x64, 0x00)
    elseif targetType == '点' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 2)
    elseif targetType == '单位或点' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 3)
        japi.EXSetAbilityDataInteger(self:handle(), 1, 0x64, 0x00)
    elseif targetType == '物品' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 1)
        japi.EXSetAbilityDataInteger(self:handle(), 1, 0x64, 0x20)
    else
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 0)
    end
    -- 刷新一下
    self:refresh()
end

function mt:updateCost()
    local skill = self._skill
    local cost = ac.toInteger(skill._cost)
    if cost == self._cache.cost then
        return
    end
    self._cache.cost = cost
    japi.EXSetAbilityDataInteger(self:handle(), 1, 0x68, cost)
end

function mt:updateStack()
    local skill = self._skill
    local stack = ac.nearInteger(skill._stack)
    if stack == self._cache.stack then
        return
    end
    self._cache.stack = stack
    jass.SetItemCharges(self._handle, stack)
end

function mt:refresh()
    local skill = self._skill
    local unit = skill._owner
    local id = self._ability
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 2)
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 1)
end

function mt:updateSlot()
    removeItem(self)
    return addItem(self)
end

function mt:updateAll()
    self:updateTitle()
    self:updateDescription()
    self:updateIcon()
    self:updateHotkey()
    self:updateRange()
    self:updateTargetType()
    self:updateCost()
    self:updateStack()
end

function mt:getOrder()
    return ''
end

function mt:needRefreshItem()
    local skill = self._skill
    local unit = skill._owner
    local mgr = unit._skill
    if not jass.IsItemOwned(self._handle) then
        return
    end
    mgr._needRefreshItem = true
end

function mt:forceRefresh()
    local skill = self._skill
    local unit = skill._owner
    self:refresh()
    ac.world.flag('ignore item', true)
    jass.SetItemPosition(self._handle, 0.0, 0.0)
    jass.UnitAddItem(unit._handle, self._handle)
    ac.world.flag('ignore item', false)
end

function mt:setMaxCd(maxCd)
    if maxCd == self._cache.maxCd then
        return
    end
    self._cache.maxCd = maxCd
    japi.EXSetAbilityDataReal(self:handle(), 1, 0x69, maxCd)
end

function mt:setCd(cd)
    japi.EXSetAbilityState(self:handle(), 1, cd)
end

return function (skill)
    init()

    local id = poolGet()
    if not id then
        log.error('无法为技能分配物品图标')
        return nil
    end

    if not Cache[id] then
        Cache[id] = {}
    end

    local icon = setmetatable({
        _id = id,
        _skill = skill,
        _cache = Cache[id],
        _slk = slk.item[id],
    }, mt)

    local dummy = jass.CreateItem(ac.id[id], 0, 0)
    icon:updateIcon()
    jass.RemoveItem(dummy)

    local ok = addItem(icon)
    if not ok then
        releaseId(icon)
        return nil
    end

    return icon
end
