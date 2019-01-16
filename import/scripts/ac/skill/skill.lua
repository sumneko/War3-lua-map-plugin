local ability = require 'ac.skill.ability'
local type = type
local rawget = rawget
local getmetatable = getmetatable
local setmetatable = setmetatable
local tostring = tostring
local pcall = pcall

local METHOD = {
    ['onAdd']         = '技能-获得',
    ['onRemove']      = '技能-失去',
    ['onUpgrade']     = '技能-升级',
    ['onCastStart']   = '技能-施法开始',
    ['onCastChannel'] = '技能-施法引导',
    ['onCastShot']    = '技能-施法出手',
    ['onCastFinish']  = '技能-施法完成',
    ['onCastStop']    = '技能-施法停止',
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

local function eventNotify(skill, name, ...)
    local event = METHOD[name]
    if event then
        ac.eventNotify(skill, event, ...)
        skill:getOwner():eventNotify(event, ...)
    end
    callMethod(skill, name, ...)
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
    local maxLevel = ac.toInteger(data, 1)
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
}

local function createCast(skill)
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

local function updateIcon(skill)
    if skill._icon then
        if skill._removed or skill._type == '隐藏' then
            skill._icon:remove()
            skill._icon = nil
        end
    else
        if skill._removed then
            return
        end
        if skill._type == '技能' then
            skill._icon = ability(skill)
        elseif skill._type == '物品' then
        end
    end
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
        eventNotify(skill, 'onAdd')
    else
        eventNotify(skill, 'onUpgrade')
    end
end

local function addSkill(mgr, name, tp, slot)
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

    skill._owner = unit
    skill._level = 0
    skill._type = tp
    skill._slot = slot
    skill.level = 0
    for _ = 1, ac.toInteger(skill.initLevel, 1) do
        upgradeSkill(skill)
    end

    updateIcon(skill)

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
    list:clean()

    updateIcon(skill)

    eventNotify(skill, 'onRemove')

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
    local skills = {}
    if tp then
        local list = mgr[tp]
        if not list then
            log.error('技能类型不正确')
            return function () end
        end
        for skill in list:pairs() do
            skills[#skills+1] = skill
        end
    else
        for skill in mgr['技能']:pairs() do
            skills[#skills+1] = skill
        end
        for skill in mgr['物品']:pairs() do
            skills[#skills+1] = skill
        end
        for skill in mgr['隐藏']:pairs() do
            skills[#skills+1] = skill
        end
    end
    local i = 0
    return function ()
        i = i + 1
        return skills[i]
    end
end

local function loadString(skill, str)
    return str:gsub('${(.-)}', function (pat)
        local pos = pat:find(':', 1, true)
        if pos then
            local key = pat:sub(1, pos-1)
            local value = skill[key]
            local fmt = pat:sub(pos+1)
            return ('%'..fmt):format(value)
        else
            local value = skill[pat]
            return tostring(value)
        end
    end)
end

local function onCastStop(cast)
    local unit = cast._owner

    if cast._stun then
        cast._stun()
    end

    callMethod(cast, 'onCastStop')
end

local function onCastFinish(cast)
    local unit = cast._owner

    callMethod(cast, 'onCastFinish')

    local time = ac.toNumber(cast.castFinishTime)
    if time > 0 then
        ac.wait(time * 1000, function ()
            onCastStop(cast)
        end)
    else
        onCastStop(cast)
    end
end

local function onCastShot(cast)
    local unit = cast._owner

    callMethod(cast, 'onCastShot')

    local time = ac.toNumber(cast.castShotTime)
    if time > 0 then
        ac.wait(time * 1000, function ()
            onCastFinish(cast)
        end)
    else
        onCastFinish(cast)
    end
end

local function onCastChannel(cast)
    local unit = cast._owner

    callMethod(cast, 'onCastChannel')

    local time = ac.toNumber(cast.castChannelTime)
    if time > 0 then
        ac.wait(time * 1000, function ()
            onCastShot(cast)
        end)
    else
        onCastShot(cast)
    end
end

local function onCastStart(cast)
    local unit = cast._owner

    unit:stopCast()
    cast._stun = unit:addRestriction '硬直'

    callMethod(cast, 'onCastStart')

    local time = ac.toNumber(cast.castStartTime)
    if time > 0 then
        ac.wait(time * 1000, function ()
            onCastChannel(cast)
        end)
    else
        onCastChannel(cast)
    end
end

mt.__index = mt
mt.type = 'skill'

function mt:__tostring()
    if self._parent then
        return ('{cast|%s} -> %s'):format(self:getName(), self:getOwner())
    else
        return ('{skill|%s} -> %s'):format(self:getName(), self:getOwner())
    end
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

function mt:getOrder()
    local icon = self._icon
    if not icon then
        return nil
    end
    return icon:getOrder()
end

function mt:castByClient(target, x, y)
    -- 合法性检查
    if not self._icon then
        return false
    end

    local cast
    if self.targetType == '点' then
        cast = createCast(self)
        cast._targetPoint = ac.point(x, y)
    elseif self.targetType == '单位' then
        if not target then
            return false
        end
        cast = createCast(self)
        cast._targetUnit = ac.point(x, y)
    elseif self.targetType == '单位或点' then
        cast = createCast(self)
        cast._targetUnit = target
        cast._targetPoint = ac.point(x, y)
    else
        cast = createCast(self)
    end

    onCastStart(cast)
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
    return {
        _owner = unit,
        ['技能'] = ac.list(),
        ['物品'] = ac.list(),
        ['隐藏'] = ac.list(),

        addSkill  = addSkill,
        findSkill = findSkill,
        eachSkill = eachSkill,
    }
end
