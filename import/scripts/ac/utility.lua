local type = type

function ac.isUnit(obj)
    return type(obj) == 'table' and obj.type == 'unit'
end

function ac.isPoint(obj)
    return type(obj) == 'table' and obj.type == 'point'
end

function ac.isNumber(obj)
    return type(obj) == 'number'
end

function ac.isInteger(obj)
    return math.tointeger(obj) ~= nil
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
