local function onCreate(mover)
    if not ac.isNumber(mover.speed) then
        return false, '必须指定运动速度'
    end
    if ac.isPoint(mover.target) then
        mover.angle = mover.angle or mover.start / mover.target
        mover.distance = mover.distance or mover.start * mover.target
    end
    if not ac.isNumber(mover.angle) then
        return false, '必须指定运动方向'
    end
    if not ac.isNumber(mover.distance) then
        return false, '必须指定运动距离'
    end
    mover._moved = 0.0

    return true
end

local function onMove(mover, delta)
    local me = mover.mover:getPoint()
    local step = mover.speed * delta / 1000
    local distance = mover.distance - mover._moved
    local angle = mover.angle
    if step >= distance then
        mover.mover:setPoint(me - {angle, distance})
        mover:setProcess(1.0)
        mover:finish()
    else
        mover.mover:setPoint(me - {angle, step})
        mover:stepProcess(step / distance)
    end
end

return {
    onCreate = onCreate,
    onMove = onMove,
}
