local japi = require 'jass.japi'
local jass = require 'jass.common'

local METHOD = {
    ['onAdd']         = '状态-获得',
    ['onRemove']      = '状态-失去',
}

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


local setmetatable = setmetatable
local mt = {}
mt.__index = mt
mt.type = 'buff'

function mt:__tostring()
    return ('{buff|%s}'):format(self._name)
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

    mgr._buffs:clean()
end

local function manager(unit)
    local mgr = {
        _owner = unit,
        _buffs = ac.list(),
        remove = remove,
        onDead = onDead,
    }

    unit._buff = mgr

    return mgr
end

local function onAdd(buff)
    if ac.isNumber(buff.time) then
        buff._timer = ac.wait(buff.time, function ()
            buff:remove()
        end)
    end

    eventNotify(buff, 'onAdd')
end

local function onRemove(buff)
    if buff._timer then
        buff._timer:remove()
    end

    eventNotify(buff, 'onRemove')
end

local function create(unit, name, data)
    local mgr = unit._buff
    if not mgr then
        return nil
    end
    if mgr._removed then
        return nil
    end

    local self = setmetatable(data, ac.buff[name])
    self._owner = unit

    if not unit:isAlive() and self.keep ~= 1 then
        return nil
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
