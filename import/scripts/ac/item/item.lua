local slk = require 'jass.slk'
local jass = require 'jass.common'
local japi = require 'jass.japi'

local Pool
local mt = {}
mt.__index = mt
mt.type = 'item'

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
        if name and name:sub(1, 7) == '@神符' then
            poolAdd(id)
        end
    end
end

local function create(name, target)
    init()

    local data = ac.item[name]
    if not data then
        return
    end

    local id = poolGet()
    if not id then
        log.error('无法分配新的物品')
        return nil
    end

    local handle
    if ac.isPoint(target) then
        local x, y = target:getXY()
        handle = jass.CreateItem(ac.id[id], x, y)
        if handle == 0 then
            poolAdd(id)
            return nil
        end
    end

    local self = setmetatable({
        _id = id,
        _handle = handle,
        _name = name,
    }, mt)

    return self
end

local function createDefine(name)
    local data = ac.table.item[name]
    if not data then
        log.error(('物品[%s]不存在'):format(name))
        return nil
    end
    return setmetatable({}, { __index = data })
end

ac.item = setmetatable({}, {
    __index = function (self, name)
        local item = createDefine(name)
        if item then
            self[name] = item
            return item
        else
            return nil
        end
    end,
})

return {
    create = create,
}
