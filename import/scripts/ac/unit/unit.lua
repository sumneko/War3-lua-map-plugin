local jass = require 'jass.common'
local japi = require 'jass.japi'
local slk = require 'jass.slk'
local dbg = require 'jass.debug'
local attribute = require 'ac.unit.attribute'
local restriction = require 'ac.unit.restriction'
local attack = require 'ac.attack'
local mover = require 'ac.mover'
local skill = require 'ac.skill'
local ORDER = require 'ac.war3.order'

local All = {}
local IdMap

local function getIdMap()
    if IdMap then
        return IdMap
    end
    IdMap = {}
    for name, data in pairs(ac.table.unit) do
        local id = ('>I4'):unpack(data.id)
        local obj = slk.unit[id]
        if not obj then
            log.error(('单位[%s]的id[%s]无效'):format(name, id))
            goto CONTINUE
        end
        IdMap[id] = name
        ::CONTINUE::
    end
    return IdMap
end

local function update(delta)
    -- 由于key是整数，因此遍历顺序是固定的
    for handle, u in pairs(All) do
        if u._dead then
            -- 如果单位死亡后被魔兽移除，则在Lua中移除
            if jass.GetUnitTypeId(handle) == 0 then
                u:remove()
                goto CONTINUE
            end
        end
        if u.class == '生物' then
            local life = delta / 1000 * u:get '生命恢复'
            if life > 0 then
                u:add('生命', life)
            end
            local mana = delta / 1000 * u:get '魔法恢复'
            if mana > 0 then
                u:add('魔法', mana)
            end
        end
        ::CONTINUE::
    end
end

local function createDestructor(unit, callback)
    if not unit._destructor then
        unit._destructor = {}
        unit._destructorIndex = 0
    end
    local function destructor()
        -- 保证每个析构器只调用一次
        if not unit._destructor[destructor] then
            return
        end
        unit._destructor[destructor] = nil
        callback()
    end
    local index = unit._destructorIndex + 1
    unit._destructor[destructor] = index
    unit._destructorIndex = index
    return destructor
end

local function onRemove(unit)
    -- 解除玩家英雄
    if unit:isHero() then
        unit._owner:removeHero(unit)
    end

    -- 执行析构器
    local destructors = unit._destructor
    if destructors then
        -- 保证所有人都按固定的顺序执行
        local list = {}
        for f in pairs(destructors) do
            list[#list+1] = f
        end
        table.sort(list, function (a, b)
            return destructors[a] < destructors[b]
        end)
        for _, f in ipairs(list) do
            f()
        end
    end
end

local function create(player, name, point, face)
    local data = ac.table.unit[name]
    if not data then
        log.error(('单位[%s]不存在'):format(name))
        return nil
    end
    local x, y = point:getXY()
    local unitid = ac.id[data.id]
    local handle = jass.CreateUnit(player._handle, unitid, x, y, face)
    if handle == 0 then
        log.error(('单位[%s]创建失败'):format(name))
        return nil
    end
    local unit = ac.unit(handle)
    return unit
end

local mt = {}
function ac.unit(handle)
    if handle == 0 then
        return nil
    end
    if All[handle] then
        return All[handle]
    end

    local idMap = getIdMap()

    local id = jass.GetUnitTypeId(handle)
    local name = idMap[id]
    if not name then
        log.error(('ID[%s]对应的单位不存在'):format(id))
        return nil
    end
    local data = ac.table.unit[name]
    if not data then
        log.error(('名字[%s]对应的单位不存在'):format(name))
        return nil
    end
    local class = data.class
    if class ~= '弹道' and class ~= '生物' then
        log.error(('[%s]的class无效'):format(name))
        return nil
    end
    local slkUnit = slk.unit[id]

    local u = setmetatable({
        class = class,
        _gchash = handle,
        _handle = handle,
        _id = ac.id[id],
        _name = name,
        _data = data,
        _slk = slkUnit,
        _owner = ac.player(1+jass.GetPlayerId(jass.GetOwningPlayer(handle))),
        _collision = ac.toNumber(slkUnit.collision),
    }, mt)
    dbg.gchash(u, handle)
    dbg.handle_ref(handle)
    u._gchash = handle

    All[handle] = u

    if class == '生物' then
        -- 初始化单位属性
        u._attribute = attribute(u, u._data.attribute)
        -- 初始化行为限制
        u._restriction = restriction(u, u._data.restriction)

        ac.game:eventNotify('单位-初始化', u)

        -- 初始化攻击
        u._attack = attack(u, u._data.attack)
        -- 初始化技能
        u._skill = skill(u)
        -- 添加命令图标
        u:addSkill('@命令', '技能')
        -- 设置为玩家的英雄
        if u:isHero() then
            u._owner:addHero(u)
        end

        ac.game:eventNotify('单位-创建', u)
    elseif class == '弹道' then
        jass.UnitAddAbility(handle, ac.id.Aloc)
    end

    return u
end

mt.__index = mt

mt.type = 'unit'

function mt:__tostring()
    return ('{unit|%s|%s}'):format(self:getName(), self._handle)
end

function mt:getName()
    return self._name
end

function mt:set(k, v)
    if not self._attribute then
        return
    end
    self._attribute:set(k, v)
end

function mt:get(k)
    if not self._attribute then
        return 0.0
    end
    return self._attribute:get(k)
end

function mt:add(k, v)
    if not self._attribute then
        return
    end
    return self._attribute:add(k, v)
end

function mt:addRestriction(k)
    if not self._restriction then
        return
    end
    return self._restriction:add(k)
end

function mt:removeRestriction(k)
    if not self._restriction then
        return
    end
    self._restriction:remove(k)
end

function mt:getRestriction(k)
    if not self._restriction then
        return 0
    end
    return self._restriction:get(k)
end

function mt:hasRestriction(k)
    if not self._restriction then
        return false
    end
    self._restriction:has(k)
end

function mt:isAlive()
    return not self._dead
end

function mt:isHero()
    -- 通过检查单位id的第一个字母是否为大写决定是否是英雄
    local char = self._id:sub(1, 1)
    local code = char:byte()
    return code >= 65 and code <= 90
end

function mt:kill(target)
    if not ac.isUnit(target) then
        return
    end
    if target._dead then
        return
    end
    local handle = target._handle
    target._lastPoint = target:getPoint()
    target._dead = true
    jass.KillUnit(handle)
    target:eventNotify('单位-死亡', self)
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    if not self._dead then
        self:kill(self)
    end
    local handle = self._handle
    All[handle] = nil
    jass.RemoveUnit(handle)
    onRemove(self)

    self._handle = 0
    dbg.handle_unref(handle)
end

function mt:getPoint()
    if self._lastPoint then
        return self._lastPoint
    end
    -- 以后进行优化：在每帧脚本控制时间内，第一次获取点后将点缓存下来
    return ac.point(jass.GetUnitX(self._handle), jass.GetUnitY(self._handle))
end

function mt:setPoint(point)
    local x, y = point:getXY()
    jass.SetUnitX(self._handle, x)
    jass.SetUnitY(self._handle, y)
    if self._lastPoint then
        self._lastPoint = point
    end
end

function mt:getOwner()
    return self._owner
end

function mt:particle(model, socket)
    local handle = jass.AddSpecialEffectTarget(model, self._handle, socket)
    if handle == 0 then
        return nil
    else
        return createDestructor(self, function ()
            -- 这里不做引用计数保护，但析构器会保证这段代码只会运行一次
            jass.DestroyEffect(handle)
        end)
    end
end

function mt:setFacing(angle, time)
    if time then
        jass.SetUnitFacingTimed(self._handle, angle, time / 1000.0)
    else
        japi.EXSetUnitFacing(self._handle, angle)
    end
end

function mt:getFacing()
    return jass.GetUnitFacing(self._handle)
end

function mt:createUnit(name, point, face)
    return create(self:getOwner(), name, point, face)
end

function mt:addHeight(n)
    if n == 0.0 then
        return
    end
    if not self._height then
        self._height = 0.0
        jass.UnitAddAbility(self._handle, ac.id.Arav)
        jass.UnitRemoveAbility(self._handle, ac.id.Arav)
    end
    self._height = self._height + n
    jass.SetUnitFlyHeight(self._handle, self._height, 0.0)
end

function mt:getHeight()
    return self._height or 0.0
end

function mt:getCollision()
    return self._collision
end

function mt:addSkill(name, type, slot)
    if self._removed then
        return nil
    end
    if not self._skill then
        return nil
    end
    return self._skill:addSkill(name, type, slot)
end

function mt:findSkill(name, type)
    if self._removed then
        return nil
    end
    if not self._skill then
        return nil
    end
    return self._skill:findSkill(name, type)
end

function mt:eachSkill(tp)
    if not self._skill then
        return function () end
    end
    return self._skill:eachSkill(tp)
end

function mt:stopCast()
end

function mt:event(name, f)
    return ac.eventRegister(self, name, f)
end

function mt:eventDispatch(name, ...)
    local res = ac.eventDispatch(self, name, ...)
    if res ~= nil then
        return res
    end
    local res = self:getOwner():eventDispatch(name, ...)
    if res ~= nil then
        return res
    end
    return nil
end

function mt:eventNotify(name, ...)
    ac.eventNotify(self, name, ...)
    self:getOwner():eventNotify(name, ...)
end

function mt:moverTarget(data)
    data.source = self
    data.moverType = 'target'
    return mover.create(data)
end

function mt:moverLine(data)
    data.source = self
    data.moverType = 'line'
    return mover.create(data)
end

return {
    all = All,
    update = update,
    create = create,
}
