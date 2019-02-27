local japi = require 'jass.japi'
local jass = require 'jass.common'

local METHOD = {
    ['onAdd']         = '状态-获得',
    ['onRemove']      = '状态-失去',
}
local Count = 0

local function callMethod(buff, name, ...)
    local method = buff[name]
    if not method then
        return
    end
    local suc, res = xpcall(method, log.error, buff, ...)
    if suc then
        return res
    end
end

local function eventNotify(buff, name, ...)
    local event = METHOD[name]
    if event then
        ac.eventNotify(buff, event, buff, ...)
        buff:getOwner():eventNotify(event, buff, ...)
    end
    callMethod(buff, name, ...)
end

local function eventDispatch(buff, name, ...)
    local event = METHOD[name]
    if event then
        local res = ac.eventDispatch(buff, event, buff, ...)
        if res ~= nil then
            return res
        end
        local res = buff:getOwner():eventDispatch(event, buff, ...)
        if res ~= nil then
            return res
        end
    end
    return callMethod(buff, name, ...)
end

local setmetatable = setmetatable
local mt = {}
mt.__index = mt
mt.type = 'buff'

function mt:__tostring()
    return ('{buff|%s-%d}'):format(self._name, self._count)
end

local function createDefine(name)
    local defined = {}
    defined.__index = defined
    defined.__tostring = mt.__tostring
    defined._name = name
    return setmetatable(defined, mt)
end

local function remove(mgr)
    if mgr._removed then
        return
    end
    mgr._removed = true
    for buff in mgr._buffs:pairs() do
        buff:remove()
    end
end

local function onDead(mgr)
    for buff in mgr._buffs:pairs() do
        if buff.keep ~= 1 then
            buff:remove()
        end
    end
end

local function findBuff(mgr, name)
    for buff in mgr._buffs:pairs() do
        if buff._name == name then
            return buff
        end
    end
    return nil
end

local function eachBuff(mgr)
    return mgr._buffs:pairs()
end

local function removeBuffByName(mgr, name, onlyOne)
    local ok = false
    for buff in mgr._buffs:pairs() do
        if buff._name == name then
            ok = true
            buff:remove()
            if onlyOne then
                return true
            end
        end
    end
    print('#', mgr._buffs.max, #mgr._buffs.list)
    return ok
end

local function manager(unit)
    local mgr = {
        _owner = unit,
        _buffs = ac.list(),
        remove = remove,
        onDead = onDead,
        findBuff = findBuff,
        eachBuff = eachBuff,
        removeBuffByName = removeBuffByName,
    }

    unit._buff = mgr

    return mgr
end

local function setRemainig(buff, time)
    if buff._timer then
        buff._timer:remove()
    end
    if time <= 0.0 then
        return
    end
    buff._timer = ac.wait(time, function ()
        eventNotify(buff, 'onFinish')
        buff:remove()
    end)
end

local function setPulse(buff, pulse)
    if buff._pulse then
        buff._pulse:remove()
    end
    if pulse <= 0.0 then
        return
    end
    buff._pulse = ac.loop(pulse, function ()
        eventNotify(buff, 'onPulse')
    end)
end

local function onAdd(buff)
    if ac.isNumber(buff.time) then
        setRemainig(buff, buff.time)
    end
    if ac.isNumber(buff.pulse) then
        setPulse(buff, buff.pulse)
    end

    eventNotify(buff, 'onAdd')
end

local function onRemove(buff)
    if buff._pulse then
        buff._pulse:remove()
    end
    if buff._timer then
        buff._timer:remove()
    end

    eventNotify(buff, 'onRemove')
end

local function isSameBuff(buff, name, source, coverGlobal)
    if coverGlobal == 0 then
        if buff._name == name and buff._source == source then
            return true
        end
    elseif coverGlobal == 1 then
        if buff._name == name then
            return true
        end
    end
    return false
end

local function create(unit, name, data)
    local mgr = unit._buff
    if not mgr then
        return nil
    end
    if mgr._removed then
        return nil
    end

    Count = Count + 1
    local self = setmetatable(data, ac.buff[name])
    self._owner = unit
    self._count = Count
    self._mgr = mgr
    self._source = ac.isUnit(self.source) and self.source or unit

    if not unit:isAlive() and self.keep ~= 1 then
        return nil
    end

    local coverGlobal = ac.toInteger(self.coverGlobal)
    local coverType = ac.toInteger(self.coverType)
    if coverType == 0 then
        for otherBuff in mgr._buffs:pairs() do
            if isSameBuff(otherBuff, name, self._source, coverGlobal) then
                local res = eventDispatch(otherBuff, 'onCover', self)
                if res == false then
                    return nil
                else
                    otherBuff:remove()
                end
            end
        end
    elseif coverType == 1 then
        for otherBuff in mgr._buffs:pairs() do
            if isSameBuff(otherBuff, name, self._source, coverGlobal) then
                local res = eventDispatch(otherBuff, 'onCover', self)
                if res == true then
                    mgr._buffs:insertBefore(self, otherBuff)
                    break
                end
            end
        end
    end

    mgr._buffs:insert(self)

    onAdd(self)

    return self
end

function mt:getOwner()
    return self._owner
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    local unit = self._owner
    local mgr = unit._buff
    mgr._buffs:remove(self)

    onRemove(self)
end

function mt:remaining(time)
    if ac.isNumber(time) then
        setRemainig(self, time)
    else
        if not self._timer then
            return ac.toNumber(self.time)
        end
        return self._timer:remaining()
    end
end

function mt:pulse(pulse)
    if ac.isNumber(pulse) then
        setPulse(self, pulse)
    else
        return ac.toNumber(self.pulse)
    end
end

ac.buff = setmetatable({}, {
    __index = function (self, name)
        local buff = createDefine(name)
        self[name] = buff
        return buff
    end,
})

return {
    create = create,
    manager = manager,
}
