local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local iconBlender = require 'ac.icon'

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
        if name then
            if name:sub(1, #'@主动技能-') == '@主动技能-' then
                poolAdd(name, id)
            elseif name:sub(1, #'@被动技能-') == '@被动技能-' then
                poolAdd(name, id)
            end
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
    if passive == 0 and skill:isEnable() and not skill:getOwner():hasRestriction '禁魔' then
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

function mt:__tostring()
    return ('{ability icon|%s}'):format(self._ability)
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    self._ability = nil
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
    self:needRefreshAbility()
end

function mt:updateDescription()
    local skill = self._skill
    local desc = skill.description
    desc = skill:loadString(desc)
    skill._loadedDescription = desc
    if desc == self._cache.description then
        return
    end
    self._cache.description = desc
    japi.EXSetAbilityString(ac.id[self._id], 1, 0xDA, desc)
    self:needRefreshAbility()
end

function mt:updateIcon()
    local skill = self._skill
    local icon = tostring(skill.icon)
    if skill:isEnable() then
        if skill.passiveIcon == 1 then
            icon = iconBlender.add(icon, 'frame_passive')
        end
        local stack = ac.nearInteger(skill._stack)
        if stack > 0 then
            if stack >= 10 then
                icon = iconBlender.add(icon, 'stack_9+')
            else
                icon = iconBlender.add(icon, 'stack_' .. tostring(stack))
            end
        end
    else
        icon = iconBlender.getDisIcon(icon)
    end
    if icon == self._cache.icon then
        return
    end
    self._cache.icon = icon
    japi.EXSetAbilityString(ac.id[self._id], 1, 0xCC, icon)
    self:needRefreshAbility()
end

function mt:updateHotkey()
    local skill = self._skill
    local hotkey = skill.hotkey
    --由于Esc会被当成是E，所以村规一下
    if hotkey == 'Esc' then
	    return
    end
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

function mt:updateArea()
	local skill = self._skill
	local index = 1
	local area = ac.toNumber(skill.area)
	if skill.showArea == 1 and area > 0 then
		japi.EXSetAbilityDataReal(self:handle(), 1, 0x6A, area)
    	index = index + 2
	end
	if skill.ignoreAcmi == 1 then
		index = index + 8
	end
	japi.EXSetAbilityDataReal(self:handle(), 1, 0x6E, index)
end

--计算出目标允许的二进制
local convert_targets = {
	["地面"]	= 2 ^ 1,
    ["空中"]	= 2 ^ 2,
    ["建筑"]	= 2 ^ 3,
    ["守卫"]	= 2 ^ 4,
    ["物品"]	= 2 ^ 5,
    ["树木"]	= 2 ^ 6,
    ["墙"]		= 2 ^ 7,
    ["残骸"]	= 2 ^ 8,
    ["装饰物"]	= 2 ^ 9,
   	["桥"]		= 2 ^ 10,
    ["未知"]	= 2 ^ 11,
    ["自己"]	= 2 ^ 12,
    ["玩家单位"]	= 2 ^ 13,
    ["联盟"]	= 2 ^ 14,
    ["中立"]	= 2 ^ 15,
    ["敌人"]	= 2 ^ 16,
    ["未知"]	= 2 ^ 17,
    ["未知"]	= 2 ^ 18,
    ["未知"]	= 2 ^ 19,
    ["可攻击的"]	= 2 ^ 20,
    ["无敌"]	= 2 ^ 21,
    ["英雄"]	= 2 ^ 22,
    ["非-英雄"]	= 2 ^ 23,
    ["存活"]	= 2 ^ 24,
    ["死亡"]	= 2 ^ 25,
    ["有机生物"]	= 2 ^ 26,
    ["机械类"]	= 2 ^ 27,
    ["非-自爆工兵"]	= 2 ^ 28,
    ["自爆工兵"]	= 2 ^ 29,
    ["非-古树"]	= 2 ^ 30,
    ["古树"]	= 2 ^ 31,
}
local function convertTargets(targetData)
	local result = 0
	for _,name in ipairs(targetData) do
		local flag = convert_targets[name]
		if not flag then
			error('错误的目标允许类型: ' .. name)
		end
		result = result + flag
	end
	return result
end

function mt:updateTargetType()
    local id = self._id
    if slk.ability[id].code ~= 'ANcl' then
        return
    end
    local skill = self._skill
    --设置技能目标类型
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
    --设置技能目标允许
    local targetData = skill.targetData
    if targetData then
	    japi.EXSetAbilityDataInteger(self:handle(), 1, 0x64, convertTargets(targetData))
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
    self:updateIcon()
end

function mt:refresh()
    local skill = self._skill
    local unit = skill._owner
    local id = self._id
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 2)
    jass.SetUnitAbilityLevel(unit._handle, ac.id[id], 1)
end

function mt:updateSlot()
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
    self:updateArea()
end

function mt:getOrder()
    return self._slk.DataF
end

function mt:needRefreshAbility()
    local skill = self._skill
    local unit = skill._owner
    local mgr = unit._skill
    mgr._needRefreshAbility = true
end

function mt:forceRefresh()
    self:needRefreshAbility()
end

--仅设置图标的CD
function mt:setIconMaxCd(maxCd)
	maxCd = math.max(0.01,maxCd)
	japi.EXSetAbilityDataReal(self:handle(), 1, 0x69, maxCd)
end

function mt:setMaxCd(maxCd)
    --if maxCd == self._cache.maxCd then
    --    return
    --end
    self._cache.maxCd = maxCd
    self:setIconMaxCd(maxCd)
end

function mt:setCd(cd)
    japi.EXSetAbilityState(self:handle(), 1, cd)
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
        _ability = id,
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
