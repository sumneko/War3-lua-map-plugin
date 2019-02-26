local type = type
local pairs = pairs
local tableSort = table.sort

function ac.isUnit(obj)
    return type(obj) == 'table' and obj.type == 'unit'
end

function ac.isPoint(obj)
    return type(obj) == 'table' and obj.type == 'point'
end

function ac.isPlayer(obj)
    return type(obj) == 'table' and obj.type == 'player'
end

function ac.isTimer(obj)
    return type(obj) == 'table' and obj.type == 'timer'
end

function ac.isNumber(obj)
    return type(obj) == 'number'
end

function ac.isInteger(obj)
    return math.tointeger(obj) ~= nil
end

function ac.isTable(obj)
    return type(obj) == 'table'
end

function ac.isString(obj)
    return type(obj) == 'string'
end

function ac.isBoolean(obj)
    return type(obj) == 'boolean'
end

function ac.isFunction(obj)
    return type(obj) == 'function'
end

function ac.toNumber(obj, default)
    return type(obj) == 'number' and obj or default or 0.0
end

function ac.toInteger(obj, default)
    local int = math.tointeger(obj)
    if int then
        return int
    else
        return default or 0
    end
end

function ac.toBoolean(obj)
    if obj then
        return true
    else
        return false
    end
end

-- 只能存放对象，能按添加顺序遍历的数据结构，需要显性清理，不支持递归遍历
local mt = {}
mt.__index = mt
function mt:insert(obj)
    if not obj then
        return false
    end
    local list = self.list
    local n = #list+1
    list[n] = obj
    list[obj] = n
    return true
end
function mt:remove(obj)
    local list = self.list
    local n = list[obj]
    if not n then
        return false
    end
    list[n] = false
    list[obj] = nil
    return true
end
function mt:pairs()
    local i = 0
    local list = self.list
    local function next()
        i = i + 1
        local obj = list[i]
        if obj then
            return obj
        elseif obj == nil then
            return nil
        else
            return next()
        end
    end
    return next
end
function mt:clean()
    local list = self.list
    local max = #list
    if max < self.max then
        return
    end
    local alive = 0
    for i = 1, max do
        local obj = list[i]
        if obj then
            alive = alive + 1
            if i ~= alive then
                list[alive] = obj
                list[obj] = alive
                list[i] = nil
            end
        else
            list[i] = nil
        end
    end
    local new = alive * 2
    if new > 10 then
        self.max = new
    else
        self.max = 10
    end
end
function ac.list()
    return setmetatable({
        max = 10,
        list = {},
    }, mt)
end

local function formatText(text, data, color)
    return text:gsub('%{(.-)%}', function (pat)
        local id, fmt
        local pos = pat:find(':', 1, true)
        if pos then
            id = pat:sub(1, pos-1)
            fmt = pat:sub(pos+1)
        else
            id = pat
            fmt = 's'
        end
        if not id then
            return
        end
        local str = ('%'..fmt):format(data[id])
        if color[id] then
            str = ('|cff%s%s|r'):format(color[id], str)
        end
        return str
    end)
end

function ac.formatText(text, data, color)
    text = tostring(text)
    if not data and not color then
        return text
    end
    local suc, res = pcall(formatText, text, data, color)
    if suc then
        return res
    else
        return text
    end
end

function ac.sortPairs(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys+1] = k
    end
    tableSort(keys)
    local i = 0
    return function ()
        i = i + 1
        local k = keys[i]
        return k, t[k]
    end
end
