local jass = require 'jass.common'
local ability = require 'ac.skill.ability'
local item = require 'ac.skill.item'
local message = require 'jass.message'
local type = type
local rawget = rawget
local getmetatable = getmetatable
local setmetatable = setmetatable
local tostring = tostring
local pcall = pcall
local xpcall = xpcall
local select = select

local Count = 0

local METHOD = {
    ['onAdd']         = '技能-获得',
    ['onRemove']      = '技能-失去',
    ['onUpgrade']     = '技能-升级',
    ['onEnable']      = '技能-启用',
    ['onDisable']     = '技能-禁用',
    ['onCanCast']     = '技能-即将施法',
    ['onCastStart']   = '技能-施法开始',
    ['onCastChannel'] = '技能-施法引导',
    ['onCastShot']    = '技能-施法出手',
    ['onCastFinish']  = '技能-施法完成',
    ['onCastStop']    = '技能-施法停止',
    ['onCastBreak']   = '技能-施法打断',
}

-- 技能分为4层：
-- 1. data，通过ac.table.skill[name]访问，与lni中填写的内容一样
-- 2. define，通过ac.skill[name]访问，已根据技能的maxLevel字段
--    展开了数据，内部数据通过 ac.skill[name][key][level] 访问
-- 3. skill，单位身上的技能实例，技能数据为当前等级的值。0级技能
--    使用1级技能的数据。
-- 4. cast，每次施法的独立实例。

local DefinedData = {}
local DefinedDual = {}
local mt = {}
function mt:__tostring()
    if self._parent then
        return ('{cast|%s-%d} -> %s'):format(self:getName(), self._count, self:getOwner())
    else
        return ('{skill|%s-%d} -> %s'):format(self:getName(), self._count, self:getOwner())
    end
end

local function lockEvent(skill)
    skill:set('_lockEvent', skill._lockEvent + 1)
end

local function unlockEvent(skill)
    skill:set('_lockEvent', skill._lockEvent - 1)
    if skill._lockEvent ~= 0 then
        return
    end
    local first = table.remove(skill._lockList, 1)
    if first then
        skill:eventNotify(table.unpack(first, 1, first.n))
    end
end

local function callMethod(skill, name, ...)
    local method = skill[name]
    if not method then
        return
    end
    local suc, res = xpcall(method, log.error, skill, ...)
    if suc then
        return res
    end
end

local function compileValue(name, k, v, maxLevel)
    if type(v) == 'table' and type(v[1]) == 'number' then
        -- 数列必须是刚好满足maxLevel，或是首项+尾项。其他情况直接丢弃。
        if #v == maxLevel then
            return v
        elseif maxLevel == 1 then
            log.error(('技能[%s]的[%s]不能为数列'):format(name, k))
            return nil
        elseif #v == 2 then
            local n = v[1]
            local m = v[#v]
            if type(m) ~= 'number' then
                log.error(('技能[%s]的[%s]尾项不是数字'):format(name, k))
                return nil
            end
            local o = (m - n) / (maxLevel - 1)
            local list = {}
            for i = 1, maxLevel do
                list[i] = n + o * (i - 1)
            end
            return list
        else
            log.error(('技能[%s]的[%s]数列长度不正确'):format(name, k))
            return nil
        end
    else
        local list = {}
        for i = 1, maxLevel do
            list[i] = v
        end
        return list
    end
end

local function compileDual(name, definedData, maxLevel)
    local dual = {}
    for lv = 1, maxLevel do
        dual[lv] = {}
        dual[lv]._name = name
        dual[lv].__index = dual[lv]
        dual[lv].__tostring = mt.__tostring
        setmetatable(dual[lv], mt)
    end
    for k, v in pairs(definedData) do
        for lv = 1, maxLevel do
            dual[lv][k] = v[lv]
        end
    end
    return dual
end

local function compileData(name, data)
    local maxLevel = ac.toInteger(data.maxLevel, 1)
    if maxLevel < 1 then
        log.error(('技能[%s]的等级上限小于1'):format(name))
        return nil
    end

    local definedData = {}
    for k, v in pairs(data) do
        definedData[k] = compileValue(name, k, v, maxLevel)
    end

    local definedDual = compileDual(name, definedData, maxLevel)

    DefinedData[name] = definedData
    DefinedDual[name] = definedDual

    definedData.__index = definedData
    return setmetatable({}, definedData )
end

-- 继承关系：
--  技能直接继承dual数据
--      skill[key] -> dual[key]
--  施法根据创建时的dual，选择使用的数据
--      cast[key] -> rawget(skill, key) | dual[key]

local function createSkill(name)
    local define = ac.skill[name]
    if not define then
        return nil
    end

    local definedDual = DefinedDual[name]
    if not definedDual then
        return nil
    end

    local skill = {}
    for k, v in pairs(define) do
        skill[k] = v
    end

    skill._maxLevel = #definedDual
    skill.__index = skill
    return setmetatable(skill, definedDual[1])
end

local function updateSkill(skill, level)
    local definedDual = DefinedDual[skill._name]
    if not definedDual then
        return
    end

    if level < 1 then
        level = 1
    elseif level > #definedDual then
        level = #definedDual
    end

    return setmetatable(skill, definedDual[level])
end

local castmt = {
    __index = function (self, key)
        local skill = self._parent
        local dual = self._dual
        local v = rawget(skill, key)
        if v == nil then
            v = dual[key]
        end
        return v
    end,
    __tostring = mt.__tostring,
}

local function createCast(skill)
    skill = skill._parent or skill
    return setmetatable({
        _parent = skill,
        _dual = getmetatable(skill),
    }, castmt)
end

local function createDefine(name)
    local data = ac.table.skill[name]
    if not data then
        log.error(('技能[%s]不存在'):format(name))
        return nil
    end
    -- 将data编译为define，展开等级数据
    local defined = compileData(name, data)
    if not defined then
        return nil
    end
    return defined
end

local function computeCost(skill)
    local cost = ac.toNumber(skill.cost)
    if cost == 0.0 then
        return 0.0
    end
    local costReduce = skill._owner:get '减耗'
    cost = cost * (1.0 - costReduce / 100.0)
    if cost < 0.0 then
        cost = 0.0
    end
    return cost
end

local function upgradeSkill(skill)
    local newLevel = skill._level + 1
    if newLevel > skill._maxLevel then
        return
    end
    skill._level = newLevel
    skill.level = newLevel
    updateSkill(skill, newLevel)
    if newLevel == 1 then
        skill:eventNotify('onAdd')
    else
        skill:eventNotify('onUpgrade')
    end
end

local function addSkill(mgr, name, tp, slot, onInit)
    local unit = mgr._owner
    if not unit then
        return nil
    end

    if tp ~= '技能' and tp ~= '物品' and tp ~= '隐藏' then
        log.error('技能类型错误')
        return nil
    end

    local skill = createSkill(name)
    if not skill then
        return nil
    end

    local list = mgr[tp]
    list:insert(skill)

    Count = Count + 1

    skill._owner = unit
    skill._level = 0
    skill._type = tp
    skill._slot = slot
    skill._cost = computeCost(skill)
    skill._mgr = mgr
    skill._count = Count
    skill._lockEvent = 0
    skill._lockList = {}
    skill.level = 0

    lockEvent(skill)
    for _ = 1, ac.toInteger(skill.initLevel, 1) do
        upgradeSkill(skill)
    end

    skill:updateIcon()

    if onInit then
        onInit(skill)
    end

    unlockEvent(skill)

    return skill
end

local function removeSkill(unit, skill)
    if skill._removed then
        return
    end
    skill._removed = true

    local mgr = unit._skill
    if not mgr then
        return false
    end

    local tp = skill._type
    local list = mgr[tp]
    if not list then
        return false
    end

    if not list:remove(skill) then
        return false
    end

    if skill._icon then
        skill._icon:remove()
        skill._icon = nil
    end

    skill:updateIcon()

    skill:eventNotify('onRemove')

    return true
end

local function findSkillByString(list, name)
    if not list then
        return nil
    end
    for skill in list:pairs() do
        if skill._name == name then
            return skill
        end
    end
    return nil
end

local function findSkillBySlot(list, slot)
    if not list then
        return nil
    end
    for skill in list:pairs() do
        if skill._slot == slot then
            return skill
        end
    end
    return nil
end

local function findSkill(mgr, name, tp)
    if type(name) == 'string' then
        if tp then
            local skill = findSkillByString(mgr[tp], name)
            return skill
        else
            local skill =  findSkillByString(mgr['技能'], name)
                        or findSkillByString(mgr['物品'], name)
                        or findSkillByString(mgr['隐藏'], name)
            return skill
        end
    else
        if not tp then
            log.error('使用索引查找技能必须指定类型')
            return nil
        end
        local skill = findSkillBySlot(mgr[tp], name)
        return skill
    end
end

local function eachSkill(mgr, tp)
    if tp then
        local list = mgr[tp]
        if not list then
            log.error('技能类型不正确')
            return function () end
        end
        return list:pairs()
    else
        local skills = {}
        for skill in mgr['技能']:pairs() do
            skills[#skills+1] = skill
        end
        for skill in mgr['物品']:pairs() do
            skills[#skills+1] = skill
        end
        for skill in mgr['隐藏']:pairs() do
            skills[#skills+1] = skill
        end
        local i = 0
        return function ()
            i = i + 1
            return skills[i]
        end
    end
end

local function removeSkillByName(mgr, name, onlyOne)
    local ok = false
    for skill in mgr['技能']:pairs() do
        if skill._name == name then
            ok = true
            skill:remove()
            if onlyOne then
                return true
            end
        end
    end
    for skill in mgr['物品']:pairs() do
        if skill._name == name then
            ok = true
            skill:remove()
            if onlyOne then
                return true
            end
        end
    end
    for skill in mgr['隐藏']:pairs() do
        if skill._name == name then
            ok = true
            skill:remove()
            if onlyOne then
                return true
            end
        end
    end
    return ok
end

local function currentSkill(mgr)
    return mgr._currentSkill
end

local function checkRefreshAbility(mgr)
    if mgr._needRefreshAbility then
        -- 检查右下角是不是取消键（判断是否处于目标选择状态）
        local _, order = message.button(3, 2)
        if order == 0xD000B then
            return false
        end
        mgr._needRefreshAbility = nil
        return true
    end
    return false
end

local function checkRefreshItem(mgr)
    if mgr._needRefreshItem then
        -- 检查右下角是不是取消键（判断是否处于目标选择状态）
        local _, order = message.button(3, 2)
        if order == 0xD000B then
            return false
        end
        mgr._needRefreshItem = nil
        mgr._needRefreshAbility = nil
        return true
    end
    return false
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

local function getMaxCd(skill, cool)
    local unit = skill._owner
    local cdReduce = unit:get '冷却缩减'
    local maxCd = ac.toNumber(cool or skill.cool) * (1 - cdReduce / 100.0)
    return maxCd
end

local function onCoolDown(skill)
    skill._maxCd = nil
    if skill._cdTimer then
        skill._cdTimer:remove()
    end
    if skill._icon then
        skill._icon:setCd(0.0)
    end
end

local function setCd(skill, cd)
    skill = skill._parent or skill
    if not skill._maxCd then
        return false
    end
    if cd > skill._maxCd then
        cd = skill._maxCd
    end
    if cd <= 0.0 then
        onCoolDown(skill)
        return true
    end

    if skill._cdTimer then
        skill._cdTimer:remove()
    end
    skill._cdTimer = ac.wait(cd, function ()
        onCoolDown(skill)
    end)

    if skill._icon then
        skill._icon:setCd(cd)
    end

    return true
end

local function activeCd(skill, ...)
    skill = skill._parent or skill
    local n = select('#', ...)
    local maxCd
    if n == 0 then
        maxCd = getMaxCd(skill)
    elseif n == 1 then
        local cool = ...
        maxCd = getMaxCd(skill, cool)
    elseif n == 2 then
        local cool, ignore = ...
        if ignore == true then
            maxCd = cool
        else
            maxCd = getMaxCd(skill, cool)
        end
    else
        return false
    end
    
    skill._maxCd = maxCd
    if skill._icon then
        skill._icon:setMaxCd(maxCd)
    end

    return setCd(skill, maxCd)
end

local function destroyCast(cast)
    if cast._stun then
        cast._stun()
    end
    if cast._timer then
        cast._timer:remove()
    end
    if cast._trg then
	    cast._trg:remove()
    end
    cast._mgr._currentSkill = nil
    --如果技能没CD，那么给个0.01秒CD打断技能
    if cast:getCd() == 0 and cast._parent and cast._parent._icon then
    	cast._parent._icon:setCd(0.01)
	end
end

local function onCastStop(cast)
    cast._step = 'stop'
    destroyCast(cast)

    cast:eventNotify('onCastStop')
end

local function onCastBreak(cast)
    cast._step = 'break'
    destroyCast(cast)

    cast:eventNotify('onCastBreak')
end

local function onCastFinish(cast)
    local unit = cast._owner

    cast._step = 'finish'

    cast:eventNotify('onCastFinish')

    local time = ac.toNumber(cast.castFinishTime)
    if time > 0 then
        cast._timer = ac.wait(time, function ()
            onCastStop(cast)
        end)
    else
        onCastStop(cast)
    end
end

local function onCastShot(cast)
    local unit = cast._owner

    cast._step = 'shot'

    cast:eventNotify('onCastShot')

    local time = ac.toNumber(cast.castShotTime)
    if time > 0 then
        cast._timer = ac.wait(time, function ()
            onCastFinish(cast)
        end)
    else
        onCastFinish(cast)
    end
end

local function onCastChannel(cast)
    local unit = cast._owner
    local mana = unit:get '魔法'
    if mana >= cast._cost then
        unit:add('魔法', - cast._cost)
    else
        return
    end

    activeCd(cast._parent)

    cast._step = 'channel'

    cast:eventNotify('onCastChannel')

    local time = ac.toNumber(cast.castChannelTime)
    if time > 0 then
        cast._timer = ac.wait(time, function ()
            onCastShot(cast)
        end)
    else
        onCastShot(cast)
    end
end

local function onCastStart(cast)
    local unit = cast._owner

    unit:stopCast()
    if cast.animation then
	    unit:animation(cast.animation)
    end

    cast._mgr._currentSkill = cast
    cast._stun = unit:addRestriction '硬直'
    cast._step = 'start'
	cast._trg = unit:event('单位-发布命令',function(_, _, orderID)
		if orderID == '停止' then
			cast:stop()
		end
	end)
    cast:eventNotify('onCastStart')

    local time = ac.toNumber(cast.castStartTime)
    if time > 0 then
        cast._timer = ac.wait(time, function ()
            onCastChannel(cast)
        end)
    else
        onCastChannel(cast)
    end

    --前摇CD动画
    local cd = time - 0.01
    if cast._parent and cast._parent._icon and time > 0 then
	    cast._parent._icon:setIconMaxCd(cd)
    	cast._parent._icon:setCd(cd)
	end
end

local function onCanCast(cast)
    local res = cast:eventDispatch('onCanCast')
    if res == false then
        return false
    end
    return true
end

local function onCast(cast)
    if not onCanCast(cast) then
        return false
    end
    onCastStart(cast)
    return true
end

local function addInitSkill(mgr, unit)
    local skill = unit._data.skill
    if ac.isTable(skill) then
        for slot, skillName in ac.sortPairs(skill) do
            addSkill(mgr, skillName, '技能', slot)
        end
    end
    local hideSkill = unit._data.hideSkill
    if ac.isTable(hideSkill) then
        for _, skillName in ipairs(hideSkill) do
            addSkill(mgr, skillName, '隐藏')
        end
    end
end

local function isOverlay(a, b)
    if not b then
        return true
    end
    if not b:isShow() then
        return true
    end
    local level1 = ac.toNumber(a.iconLevel, 0)
    local level2 = ac.toNumber(b.iconLevel, 0)
    return level1 >= level2
end

local function updateAllIcons(unit, tp)
    local list = {}
    for skill in unit:eachSkill(tp) do
        local slot = skill._slot
        if not slot then
            goto CONTINUE
        end
        if not skill:isShow() then
            if skill._icon then
                skill._icon:remove()
                skill._icon = nil
            end
            goto CONTINUE
        end
        local oldSkill = list[slot]
        if not isOverlay(skill, oldSkill) then
            goto CONTINUE
        end
        list[slot] = skill
        if oldSkill and oldSkill._icon then
            oldSkill._icon:remove()
            oldSkill._icon = nil
        end
        ::CONTINUE::
    end
    for _, skill in pairs(list) do
        if not skill._icon then
            if tp == '技能' then
                skill._icon = ability(skill)
            elseif tp == '物品' then
                skill._icon = item(skill)
            end
            local cd = skill:getCd()
            if cd > 0 then
	            setCd(skill,cd)
            end
        end
    end
end

local function iconLevel(mgr, tp, level)
    if tp ~= '技能' and tp ~= '物品' then
        log.error('类型必须是[技能]或[物品]')
        return
    end
    if ac.isNumber(level) then
        mgr._iconLevel[tp] = level
        updateAllIcons(mgr._owner, tp)
    else
        return mgr._iconLevel[tp]
    end
end

mt.__index = mt
mt.type = 'skill'

function mt:stop()
    if not self:isCast() then
        return false
    end
    if self._step == 'start' then
        onCastBreak(self)
    elseif self._step == 'channel' then
        onCastStop(self)
    elseif self._step == 'shot' then
        onCastStop(self)
    elseif self._step == 'finish' then
        onCastStop(self)
    end
    return true
end

function mt:getOwner()
    return self._owner
end

function mt:getName()
    return self._name
end

function mt:remove()
    return removeSkill(self._owner, self._parent or self)
end

function mt:set(k, v)
    local skill = self._parent or self
    skill[k] = v
end

function mt:get(k)
    local skill = self._parent or self
    return skill[k]
end

function mt:loadString(str)
    str = tostring(str)

    local suc, res = pcall(loadString, self, str)
    if suc then
        return res
    else
        return str
    end
end

function mt:updateIcon()
    updateAllIcons(self._owner, '技能')
    updateAllIcons(self._owner, '物品')
end

function mt:getOrder()
    local icon = self._icon
    if not icon then
        return nil
    end
    return icon:getOrder()
end

function mt:eventNotify(name, ...)
    if self._lockEvent == 0 then
        lockEvent(self)
        local event = METHOD[name]
        if event then
            ac.eventNotify(self, event, self, ...)
            self:getOwner():eventNotify(event, self, ...)
        end
        callMethod(self, name, ...)
        unlockEvent(self)
    else
        self._lockList[#self._lockList+1] = table.pack(name, ...)
    end
end

function mt:eventDispatch(name, ...)
    lockEvent(self)
    local event = METHOD[name]
    if event then
        local res, data = ac.eventDispatch(self, event, self, ...)
        if res ~= nil then
            unlockEvent(self)
            return res, data
        end
        local res, data = self:getOwner():eventDispatch(event, self, ...)
        if res ~= nil then
            unlockEvent(self)
            return res, data
        end
    end
    local res, data = callMethod(self, name, ...)
    unlockEvent(self)
    return res, data
end

function mt:cast(...)
    self = self._parent or self

    -- 不能发动冷却中的技能
    if self:getCd() > 0.0 then
        return false
    end

    -- 不能发动禁用的技能
    if not self:isEnable() then
        return false
    end

    -- 不能在死亡状态发动技能
    if not self._owner:isAlive() then
        return false
    end

    -- 不能处于禁魔状态
    if self._owner:hasRestriction '禁魔' then
        return false
    end

    local cast, target, data
    if self.targetType == '点' then
        target, data = ...
        if not ac.isPoint(target) then
            return false
        end
        cast = createCast(self)
        cast._targetType = '点'
        cast._targetPoint = target
    elseif self.targetType == '单位' then
        target, data = ...
        if not ac.isUnit(target) then
            return false
        end
        cast = createCast(self)
        cast._targetType = '单位'
        cast._targetUnit = target
    elseif self.targetType == '单位或点' then
        target, data = ...
        cast = createCast(self)
        cast._targetType = '单位或点'
        if ac.isUnit(target) then
            cast._targetUnit = target
        elseif ac.isPoint(target) then
            cast._targetPoint = target
        else
            return false
        end
    elseif self.targetType == '物品' then
        target, data = ...
        if not ac.isItem(target) then
            return false
        end
        cast = createCast(self)
        cast._targetType = '物品'
        cast._targetItem = target
    else
        data = ...
        cast = createCast(self)
    end

    if ac.isTable(data) then
        for k, v in pairs(data) do
            cast[k] = v
        end
    end

    return onCast(cast)
end

function mt:castByClient(target, x, y)
    self = self._parent or self

    -- 合法性检查
    if not self._icon then
        return false
    end

    -- 不能发动被动技能
    if self.passive == 1 then
        return false
    end

    -- 不能发动禁用的技能
    if not self:isEnable() then
        return false
    end

    -- 不能发动冷却中的技能
    if self:getCd() > 0.0 then
        return false
    end

    -- 不能在死亡状态发动技能
    if not self._owner:isAlive() then
        return false
    end

    -- 不能处于禁魔状态
    if self._owner:hasRestriction '禁魔' then
        return false
    end

    local cast
    if self.targetType == '点' then
        cast = createCast(self)
        cast._targetType = '点'
        cast._targetPoint = ac.point(x, y)
    elseif self.targetType == '单位' then
        if not ac.isUnit(target) then
            return false
        end
        cast = createCast(self)
        cast._targetType = '单位'
        cast._targetUnit = target
    elseif self.targetType == '单位或点' then
        cast = createCast(self)
        cast._targetType = '单位或点'
        cast._targetUnit = target
        cast._targetPoint = ac.point(x, y)
    elseif self.targetType == '物品' then
        if not ac.isItem(target) then
            return false
        end
        cast = createCast(self)
        cast._targetType = '物品'
        cast._targetItem = target
    else
        cast = createCast(self)
    end

    return onCast(cast)
end

function mt:getTarget()
    if self._targetType == '点' then
        return self._targetPoint
    elseif self._targetType == '单位' then
        return self._targetUnit
    elseif self._targetType == '单位或点' then
        if self._targetUnit then
            return self._targetUnit
        else
            return self._targetPoint
        end
    elseif self._targetType == '物品' then
        return self._targetItem
    else
        return nil
    end
end

function mt:isCast()
    if self._parent then
        return true
    else
        return false
    end
end

function mt:setOption(name, value)
    self = self._parent or self
    self[name] = value
    if name == 'title' then
        if self._icon then
            self._icon:updateTitle()
        end
    elseif name == 'description' then
        if self._icon then
            self._icon:updateDescription()
        end
    elseif name == 'icon' then
        if self._icon then
            self._icon:updateIcon()
        end
    elseif name == 'hotkey' then
        if self._icon then
            self._icon:updateHotkey()
        end
    elseif name == 'iconLevel' then
        self:updateIcon()
    elseif name == 'passive' then
        if self._icon then
            self._icon:remove()
            if self._type == '技能' then
                self._icon = ability(self)
            elseif self._type == '物品' then
                self._icon = item(self)
            end
        end
    elseif name == 'passiveIcon' then
        if self._icon then
            self._icon:updateIcon()
        end
    end
end

function mt:forceRefresh()
    if self._icon then
        self._icon:forceRefresh()
    end
end

function mt:getCd()
    if not self._cdTimer then
        return 0.0
    end
    return self._cdTimer:remaining()
end

function mt:activeCd(...)
    return activeCd(self._parent or self, ...)
end

function mt:setCd(cd)
    if not ac.isNumber(cd) then
        return false
    end
    return setCd(self._parent or self, cd)
end

function mt:stack(n)
    if ac.isNumber(n) then
        self:set('_stack', n)
        if self._icon then
            self._icon:updateStack()
        end
    else
        return self._stack or 0
    end
end

function mt:getItem()
    return self._item
end

function mt:disable()
    self = self._parent or self
    self._disable = (self._disable or 0) + 1
    if self._disable == 1 then
        if self._icon then
            self._icon:remove()
            self._icon = nil
            self:updateIcon()
        end
        local unit = self:getOwner()
        local cast = unit:currentSkill()
        if self:is(cast) then
            cast:stop()
        end
        self:eventNotify('onDisable')
    end
end

function mt:enable()
    self = self._parent or self
    self._disable = (self._disable or 0) - 1
    if self._disable == 0 then
        if self._icon then
            self._icon:remove()
            self._icon = nil
            self:updateIcon()
        end
        self:eventNotify('onEnable')
    end
end

function mt:isEnable()
    return not self._disable or self._disable == 0
end

function mt:is(dest)
    if not ac.isSkill(dest) then
        return false
    end
    self = self._parent or self
    dest = dest._parent or dest
    return self == dest
end

function mt:hide()
    self._hide = (self._hide or 0) + 1
    if self._hide == 1 then
        self:updateIcon()
    end
end

function mt:show()
    self._hide = (self._hide or 0) - 1
    if self._hide == 0 then
        self:updateIcon()
    end
end

function mt:isShow()
    if self._hide and self._hide ~= 0 then
        return false
    end
    local mgr = self._owner._skill
    if not mgr then
        return false
    end
    local level = mgr._iconLevel[self._type]
    if level and ac.toNumber(self.iconLevel) < level then
        return false
    end
    return true
end

ac.skill = setmetatable({}, {
    __index = function (self, name)
        local skill = createDefine(name)
        if skill then
            self[name] = skill
            return skill
        else
            return nil
        end
    end,
})

return function (unit)
    local mgr = {
        _owner = unit,
        _iconLevel = {
            ['技能'] = 0,
            ['物品'] = 0,
        },
        ['技能'] = ac.list(),
        ['物品'] = ac.list(),
        ['隐藏'] = ac.list(),

        addSkill  = addSkill,
        findSkill = findSkill,
        eachSkill = eachSkill,
        removeSkillByName = removeSkillByName,
        currentSkill = currentSkill,
        checkRefreshAbility = checkRefreshAbility,
        checkRefreshItem = checkRefreshItem,
        iconLevel = iconLevel,
    }

    unit._skill = mgr

    addInitSkill(mgr, unit)

    return mgr
end
