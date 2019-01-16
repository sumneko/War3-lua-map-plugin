local mt = {}
mt.__index = mt

mt.type = 'point'
mt[1] = 0.0
mt[2] = 0.0

function mt:__tostring()
    return ('{point|%.4f, %.4f}'):format(self:getXY())
end

function mt:getXY()
    return self[1], self[2]
end

function mt:copy()
    return ac.point(self[1], self[2])
end

function mt:getPoint()
    return self
end

function mt:distance(u)
    local x1, y1 = self:getXY()
    local x2, y2 = u:getXY()
    local x = x1 - x2
    local y = y1 - y2
    return math.sqrt(x * x + y * y)
end

function mt:angle(u)
    local x1, y1 = self:getXY()
    local x2, y2 = u:getXY()
    return ac.math.atan(y2 - y1, x2 - x1)
end

function mt:__sub(data)
    local x, y = self:getXY()
    local angle, distance = data[1], data[2]
    return ac.point(x + distance * ac.math.cos(angle), y + distance * ac.math.sin(angle))
end

function mt:__mul(dest)
    local x1, y1 = self:getXY()
    local x2, y2 = dest:getXY()
    local x0, y0 = x1 - x2, y1 - y2
    return math.sqrt(x0 * x0 + y0 * y0)
end

function mt:__div(dest)
    local x1, y1 = self:getXY()
    local x2, y2 = dest:getXY()
    return ac.math.atan(y2 - y1, x2 - x1)
end

function ac.point(x, y)
    return setmetatable({x, y}, mt)
end
