local type = type
local tableSort = table.sort
local tableInsert = table.insert
local mathFloor = math.floor
local mathTointeger = math.tointeger
local tonumber = tonumber

function ac.isUnit(obj)
    return type(obj) == 'table' and obj.type == 'unit'
end

function ac.isItem(obj)
    return type(obj) == 'table' and obj.type == 'item'
end

function ac.isPoint(obj)
    return type(obj) == 'table' and obj.type == 'point'
end

function ac.isPlayer(obj)
    return type(obj) == 'table' and obj.type == 'player'
end

function ac.isSkill(obj)
    return type(obj) == 'table' and obj.type == 'skill'
end

function ac.isTimer(obj)
    return type(obj) == 'table' and obj.type == 'timer'
end

function ac.isNumber(obj)
    return type(obj) == 'number'
end

function ac.isInteger(obj)
    return mathTointeger(obj) ~= nil
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
    local int = mathTointeger(obj)
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

function ac.nearInteger(obj)
    local n = tonumber(obj) or 0.0
    return mathFloor(n + 0.5)
end

function ac.isInTable(tbl,val)
	for k,v in pairs(tbl) do
		if k == val or v == val then
			return true
		end
	end
	return false
end

--复制一个表
function ac.copytable(tbl)
	local list = {}
	for a,b in pairs(tbl) do
		if type(b) == 'table' then
			list[a] = ac.copytable(b)
		else
			list[a] = b
		end
	end
	return list
end

--分割字符串
function ac.split(str, p)
	local rt = {}
	string.gsub(str, '[^' .. p .. ']+', function (w) table.insert(rt, w) end)
	return rt
end

-- 只能存放对象，能按添加顺序遍历的数据结构
local mt = {}
mt.__index = mt
function mt:insert(obj)
    if not obj then
        return false
    end
    local list = self.list
    if list[obj] then
        return false
    end
    local n = #list+1
    list[n] = obj
    list[obj] = n
    return true
end
function mt:insertBefore(obj, other)
    if not obj then
        return false
    end
    local list = self.list
    if list[obj] then
        return false
    end
    local n = list[other]
    if n then
        tableInsert(list, n, obj)
        for i = n, #list do
            local obj = list[i]
            list[obj] = i
        end
    else
        n = #list+1
        list[n] = obj
        list[obj] = n
        return true
    end
end
function mt:remove(obj)
    local list = self.list
    local n = list[obj]
    if not n then
        return false
    end
    list[n] = false
    list[obj] = nil
    self:clean()
    return true
end
function mt:has(obj)
    local list = self.list
    return list[obj] ~= nil
end
function mt:pairs()
    local i = 0
    local list = self.list
    local function nextObject()
        i = i + 1
        local obj = list[i]
        if obj then
            return obj
        elseif obj == nil then
            return nil
        else
            return nextObject()
        end
    end
    return nextObject
end
function mt:clean()
    if self.cleaning then
        return
    end
    local list = self.list
    local max = #list
    if max < self.max then
        return
    end
    self.cleaning = true
    ac.wait(0, function ()
        self.cleaning = false
        local alive = 0
        for i = 1, #list do
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
    end)
end
function ac.list()
    return setmetatable({
        max = 10,
        list = {},
        cleaning = false,
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

ac.pairs = pairs

local stdNext = next
local cantPairs = {
    ['table'] = true,
    ['thread'] = true,
    ['userdata'] = true,
    ['function'] = true,
}

function next(...)
    local key, value = stdNext(...)
    if cantPairs[type(key)] then
        error('不能遍历索引为gc对象的表')
    end
    return key, value
end

function pairs(t)
    local mt = getmetatable(t)
    if mt and mt.__pairs then
        return mt.__pairs(t)
    end
    next(t)
    return stdNext, t, nil
end
