
local setmetatable = setmetatable
local table = table
local Map = setmetatable({}, { __mode = 'kv' })

local mt = {}
mt.__index = mt

--结构
mt.type = 'trigger'

--是否允许
mt._enable = true

mt._removed = false

--事件
mt._event = nil

function mt:__tostring()
    return '[table:trigger]'
end

--禁用触发器
function mt:disable()
    self._enable = false
end

function mt:enable()
    self._enable = true
end

function mt:isEnable()
    return self._enable
end

--运行触发器
function mt:__call(...)
    if self._removed then
        return
    end
    if self._enable then
        return self:_callback(...)
    end
end

--摧毁触发器(移除全部事件)
function mt:remove()
    if not self._event then
        return
    end
    Map[self] = nil
    local event = self._event
    self._event = nil
    self._removed = true
    ac.wait(0, function()
        for i, trg in ipairs(event) do
            if trg == self then
                table.remove(event, i)
                break
            end
        end
        if #event == 0 then
            if event.remove then
                event:remove()
            end
        end
    end)
end

function ac.eachTrigger()
    return pairs(Map)
end

--创建触发器
function ac.trigger(event, callback)
    local trg = setmetatable({_event = event, _callback = callback}, mt)
    table.insert(event, trg)
    Map[trg] = true
    return trg
end
