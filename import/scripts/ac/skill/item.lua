local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local SLOT_MIN = 1
local SLOT_MAX = 6

local Pool

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
        if name and name:sub(1, 1) == '@' then
            poolAdd(id)
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

local function addItem(icon)
    local id = icon._id
    if not id then
        return false
    end
    local skill = icon._skill
    local unit = skill._owner

    local slot = ac.toInteger(skill._slot)
    if not slot or slot < SLOT_MIN or slot > SLOT_MAX then
        return false
    end
    if jass.UnitItemInSlot(unit._handle, slot-1) ~= 0 then
        return false
    end

    local cheeses = {}
    for i = 1, slot - 1 do
        if jass.UnitItemInSlot(unit._handle, i-1) == 0 then
            cheeses[#cheeses+1] = jass.UnitAddItemById(unit._handle, ac.id['@CHE'])
        end
    end
    local handle = jass.UnitAddItemById(unit._handle, ac.id[id])
    for _, cheese in ipairs(cheeses) do
        jass.RemoveItem(cheese)
    end

    if handle == 0 then
        return false
    end
    icon._handle = handle
    icon._ability = icon._slk.abilList
    return true
end

local function removeItem(icon)
    jass.RemoveItem(icon._handle)
    icon._handle = 0
end

local mt = {}
mt.__index = mt
mt.type = 'item icon'

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    removeItem(self)
    releaseId(self)
end

return function (skill)
    init()

    local id = poolGet()
    if not id then
        return nil
    end

    local icon = setmetatable({
        _id = id,
        _skill = skill,
        _slk = slk.item[id],
    }, mt)

    local ok = addItem(icon)
    if not ok then
        releaseId(icon)
        return nil
    end

    return icon
end
