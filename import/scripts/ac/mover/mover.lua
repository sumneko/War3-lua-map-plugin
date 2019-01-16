local moverTarget = require 'ac.mover.target'
local moverLine = require 'ac.mover.line'
local parabola = require 'ac.mover.parabola'

local Movers = ac.list()

local mt = {}
mt.__index = mt

mt.type = 'mover'
mt.source = nil
mt._process = 0.0
mt._height = 0.0


local function eventNotify(mover, name, ...)
    local method = mover[name]
    if not method then
        return
    end
    local suc, res = xpcall(method, log.error, mover, ...)
    if suc then
        return res
    end
end

local function updateHeight(mover)
    local height = mover.heightEquation(mover._process)
    local delta = height - mover._height
    if delta == 0.0 then
        return
    end
    mover._height = height
    mover.mover:addHeight(delta)
end

local function updateMove(mover, delta)
    mover.project.onMove(mover, delta)
end

local function updateFinish(mover)
    if mover._finish then
        eventNotify(mover, 'onFinish')
        mover:remove()
    end
end

local function update(delta)
    -- 1. 更新移动
    for mover in Movers:pairs() do
        updateMove(mover, delta)
        updateHeight(mover)
    end

    -- 2. 检查碰撞

    -- 3. 检查完成
    for mover in Movers:pairs() do
        updateFinish(mover)
    end

    -- 4. 清理
    Movers:clean()
end

local function createMover(mover)
    if ac.isUnit(mover.mover) then
        return true
    end
    if type(mover.mover) == 'string' then
        local dummy = mover.source:createUnit(mover.mover, mover.start, mover.angle)
        if dummy then
            mover.mover = dummy
            mover._needKillMover = true
            return true
        end
    end
    if mover.model then
        local dummy = mover.source:createUnit('@运动马甲', mover.start, mover.angle)
        if dummy then
            mover.mover = dummy
            mover._needKillMover = true
            mover._needDestroyParicle = dummy:particle(mover.model, 'origin')
            return true
        end
    end
    mover.mover = nil
    return false, '没有运动单位'
end

local function computeParams(mover)
    if not ac.isUnit(mover.source) then
        return nil, '来源必须是单位'
    end
    if not ac.isPoint(mover.start) then
        mover.start = mover.source:getPoint()
    end
    if mover.fix then
        mover.start = mover.start - {mover.fix[1] + mover.source:getFacing(), mover.fix[2]}
    end
    if not mover.heightEquation then
        local start  = ac.toNumber(mover.startHeight)
        local finish = ac.toNumber(mover.finishHeight)
        local middle = ac.toNumber(mover.middleHeight, (start + finish) / 2)
        mover.heightEquation = parabola(start, middle, finish)
    end
    return true
end

local function create(data)
    local mover = setmetatable(data, mt)

    if mover.moverType == 'target' then
        mover.project = moverTarget
    elseif mover.moverType == 'line' then
        mover.project = moverLine
    else
        return nil, '未知的运动类型'
    end

    local ok, err = computeParams(mover)
    if not ok then
        return nil, err
    end

    local ok, err = mover.project.onCreate(mover)
    if not ok then
        return nil, err
    end

    local ok, err = createMover(mover)
    if not ok then
        return nil, err
    end

    Movers:insert(mover)
    updateHeight(mover)

    return mover
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    Movers:remove(self)
    if self._needKillMover then
        self.source:kill(self.mover)
    end
    if self._needDestroyParicle then
        self._needDestroyParicle()
    end
end

function mt:finish()
    self._finish = true
end

function mt:setAngle(angle)
    self._angle = angle
    self.mover:setFacing(angle)
end

function mt:stepProcess(a)
    if a <= 0.0 then
        return
    end
    self._process = self._process + (1.0 - self._process) * a
end

function mt:setProcess(n)
    if n > 1.0 then
        n = 1.0
    end
    if n <= self._process then
        return
    end
    self._process = n
end

return {
    update = update,
    create = create,
}
