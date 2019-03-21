local damage = require 'ac.damage'
local japi = require 'jass.japi'

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
        _commonAttack = true,
    }
    self._owner:eventNotify('单位-攻击出手', self._owner, target, dmg)
    damage.dispatch(dmg)
end

function mt:shotMissile(target)
    local dmg = damage.create {
        source = self._owner,
        target = target,
        skill  = self,
        damage = self._owner:get '攻击',
        _commonAttack = true,
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

    self._owner:eventNotify('单位-攻击出手', self._owner, target, dmg, mover)
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

    unit:set('攻击范围', ac.toNumber(attack.range, 100.0))

    return setmetatable({
        type = attack.type,
        range = attack.range,
        mover = attack.mover,
        _owner = unit,
    }, mt)
end
