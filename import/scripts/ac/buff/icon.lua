local jass = require 'jass.common'
local japi = require 'jass.japi'
local slk = require 'jass.slk'

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
    for id, ability in pairs(slk.ability) do
        local name = ability.Name
        if name and name:sub(1, #'@状态技能') == '@状态技能' then
            poolAdd(id)
        end
    end
end

local function addAbility(icon)
    local id = icon._id
    if not id then
        return false
    end
    local unit = icon._buff._owner
    return jass.UnitAddAbility(unit._handle, ac.id[id])
end

local mt = {}
mt.__index = mt

mt.type = 'buff icon'

function mt:__tostring()
    return ('{buff icon|%s-%d}'):format(self._name, self._handle)
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    self._ability = nil
    poolAdd(self._id)
    local unit = self._buff._owner
    jass.UnitRemoveAbility(unit._handle, ac.id[self._id])
end

function mt:updateTitle()
    local buff = self._buff
    local title = buff.title
    if title == self._cache.title then
        return
    end
    self._cache.title = title
    japi.EXSetBuffDataString(ac.id[self._buffId], 2, title)
end

function mt:updateDescription()
    local buff = self._buff
    local desc = buff.description
    if desc == self._cache.description then
        return
    end
    self._cache.description = desc
    japi.EXSetBuffDataString(ac.id[self._buffId], 3, desc)
end

function mt:updateIcon()
    local buff = self._buff
    local icon = buff.icon
    if icon == self._cache.icon then
        return
    end
    self._cache.icon = icon
    japi.EXSetBuffDataString(ac.id[self._buffId], 1, icon)
end

function mt:updateAll()
    self:updateTitle()
    self:updateDescription()
    self:updateIcon()
end

return function (buff)
    init()

    local id = poolGet()
    if not id then
        log.error('无法分配新的状态图标')
        return nil
    end

    if not Cache[id] then
        Cache[id] = {}
    end

    local slkData = slk.ability[id]
    local self = setmetatable({
        _id = id,
        _buff = buff,
        _name = buff._name,
        _slk = slkData,
        _cache = Cache[id],
        _ability = id,
        _buffId = slkData.BuffID1,
    }, mt)

    local ok = addAbility(self)
    if not ok then
        poolAdd(id)
        return nil
    end

    self:updateAll()

    return self
end
