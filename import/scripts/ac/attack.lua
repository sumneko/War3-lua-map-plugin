local damage = require 'ac.damage'

local mt = {}
mt.__index = mt

mt.type = 'attack'
mt._owner = nil

function mt:shotInstant(target)
    local dmg = damage.create {
        source = self._owner,
        target = target,
        skill  = self,
        damage = self._owner:get '攻击',
    }
    damage.dispatch(dmg)
end

function mt:shotMissile(target)
    local dmg = damage.create {
        source = self._owner,
        target = target,
        skill  = self,
        damage = self._owner:get '攻击',
    }
    if not self.mover then
        return
    end

    local data = {}
    for k, v in pairs(self.mover) do
        data[k] = v
    end
    data.target = target
    data.finishHeight = target._data.hitHeight

    local mover, err = self._owner:moverTarget(data)
    if not mover then
        log.error(err)
        return
    end

    function mover:onFinish()
        damage.dispatch(dmg)
    end
end

function mt:dispatch(target)
    if self.type == '立即' then
        self:shotInstant(target)
    elseif self.type == '弹道' then
        self:shotMissile(target)
    end
end

return function (unit, attack)
    if not attack then
        return nil
    end

    return setmetatable({
        type = attack.type,
        range = attack.range,
        mover = attack.mover,
        _owner = unit,
    }, mt)
end
