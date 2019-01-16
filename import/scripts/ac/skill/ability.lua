local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local Pool
local Cache = {}

local function poolAdd(name, obj)
    local pool = Pool[name]
    if not pool then
        pool = {}
        Pool[name] = pool
    end
    pool[#pool+1] = obj
end

local function poolGet(name)
    local pool = Pool[name]
    if not pool then
        return nil
    end
    local max = #pool
    if max == 0 then
        return nil
    end
    local obj = pool[max]
    pool[max] = nil
    return obj
end

local function init()
    if Pool then
        return
    end
    Pool = {}
    for id, abil in pairs(slk.ability) do
        local name = abil.Name
        if name and name:sub(1, 1) == '@' then
            poolAdd(name, id)
        end
    end
end

local function getId(skill)
    if skill.id then
        return skill.id, skill.id
    end
    local slot = ac.toInteger(skill._slot)
    if not slot then
        return nil
    end
    local passive = ac.toInteger(skill.passive)
    local name
    if passive == 0 then
        name = '@主动技能-' .. tostring(slot)
    else
        name = '@被动技能-' .. tostring(slot)
    end
    local id = poolGet(name)
    if not id then
        log.error(('无法为[%s]分配图标'):format(name))
        return nil
    end
    return name, id
end

local function releaseId(icon)
    local name = icon._name
    local id = icon._id
    if not id then
        return
    end
    icon._id = nil
    poolAdd(name, id)
end

local function addAbility(icon)
    local id = icon._id
    if not id then
        return false
    end
    local unit = icon._skill._owner
    return jass.UnitAddAbility(unit._handle, ac.id[id])
end

local function removeAbility(icon)
    local id = icon._id
    if not id then
        return false
    end
    local unit = icon._skill._owner
    return jass.UnitRemoveAbility(unit._handle, ac.id[id])
end

local mt = {}
mt.__index = mt
mt.type = 'ability icon'

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    removeAbility(self)
    releaseId(self)
end

function mt:handle()
    local unit = self._skill._owner
    local id = self._id
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
    japi.EXSetAbilityString(ac.id[self._id], 1, 0xD7, title)
end

function mt:updateDescription()
    local skill = self._skill
    local desc = skill.description
    desc = skill:loadString(desc)
    if desc == self._cache.description then
        return
    end
    self._cache.description = desc
    japi.EXSetAbilityString(ac.id[self._id], 1, 0xDA, desc)
end

function mt:updateIcon()
    local skill = self._skill
    local icon = skill.icon
    if icon == self._cache.icon then
        return
    end
    self._cache.icon = icon
    japi.EXSetAbilityString(ac.id[self._id], 1, 0xCC, icon)
end

function mt:updateHotkey()
    local skill = self._skill
    local hotkey = skill.hotkey
    if hotkey == self._cache.hotkey then
        return
    end
    self._cache.hotkey = hotkey
    japi.EXSetAbilityDataInteger(self:handle(), 1, 0xC8, hotkey and hotkey:byte() or 0)
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
    local id = self._id
    if slk.ability[id].code ~= 'ANcl' then
        return
    end
    local skill = self._skill
    local targetType = skill.targetType
    if self._cache.targetType == targetType then
        return
    end
    self._cache.targetType = targetType
    if targetType == '单位' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 1)
    elseif targetType == '点' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 2)
    elseif targetType == '单位或点' then
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 3)
    else
        japi.EXSetAbilityDataReal(self:handle(), 1, 0x6D, 0)
    end
    -- 刷新一下
    self:refresh()
end

function mt:refresh()
    local skill = self._skill
    local unit = skill._owner
    local id = self._id
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 2)
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 1)
end

function mt:updateCost()
    local skill = self._skill
    local cost = ac.toNumber(skill.cost)
    if cost == self._cache.cost then
        return
    end
    self._cache.cost = cost
    japi.EXSetAbilityDataInteger(self:handle(), 1, 0x68, cost)
end

function mt:updateAll()
    self:updateTitle()
    self:updateDescription()
    self:updateIcon()
    self:updateHotkey()
    self:updateRange()
    self:updateTargetType()
    self:updateCost()
end

function mt:getOrder()
    return self._slk.DataF
end

return function (skill)
    init()

    local name, id = getId(skill)
    if not id then
        return nil
    end

    if not Cache[id] then
        Cache[id] = {}
    end

    local icon = setmetatable({
        _name = name,
        _id = id,
        _skill = skill,
        _cache = Cache[id],
        _slk = slk.ability[id],
    }, mt)

    local ok = addAbility(icon)
    if not ok then
        releaseId(icon)
        return nil
    end

    icon:updateAll()

    return icon
end
