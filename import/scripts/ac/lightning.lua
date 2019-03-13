local jass = require 'jass.common'
local japi = require 'jass.japi'

local List = ac.list()

local function update()
    for ln in List:pairs() do
        ln:_update()
    end
end

local function getHeight(obj)
    local x, y = obj:getXY()
    local z = ac.world.getZ(x, y)
    if ac.isUnit(obj) then
        z = z + obj:getHeight()
    end
    return z
end

local mt = {}
mt.__index = mt
mt.type = 'lightning'

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.DestroyLightning(self._handle)
    self._handle = 0
    List:remove(self)
end

function mt:_update()
    local x1, y1 = self.source:getXY()
    local x2, y2 = self.target:getXY()
    local z1 = getHeight(self.source) + self.sourceHeight
    local z2 = getHeight(self.target) + self.targetHeight

    jass.MoveLightningEx(self._handle, false, x1, y1, z1, x2, y2, z2)
end

function ac.lightning(data)
    if not ac.isUnit(data.source) and not ac.isPoint(data.source) then
        log.error('来源必须是点或单位')
        return nil
    end
    if not ac.isUnit(data.target) and not ac.isPoint(data.target) then
        log.error('目标必须是点或单位')
        return nil
    end
    if not ac.isString(data.model) then
        log.error('闪电模型必须是字符串')
        return nil
    end
    local x1, y1 = data.source:getXY()
    local x2, y2 = data.target:getXY()
    local z1 = getHeight(data.source) + ac.toNumber(data.sourceHeight)
    local z2 = getHeight(data.target) + ac.toNumber(data.targetHeight)

    local handle = jass.AddLightningEx(data.model, false, x1, y1, z1, x2, y2, z2)

    local self = setmetatable({
        _handle = handle,
        source = data.source,
        target = data.target,
        sourceHeight = ac.toNumber(data.sourceHeight),
        targetHeight = ac.toNumber(data.targetHeight),
    }, mt)

    List:insert(self)

    return self
end

return {
    update = update,
}
