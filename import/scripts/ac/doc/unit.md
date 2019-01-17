# unit

### getName
```lua
unit:getName()
    -> name: string
```

### set
```lua
unit:set(attributeName: string, attributeValue: number)

attributeName: string
    | '生命'
    | '生命上限'
    | '生命恢复'
    | '魔法'
    | '魔法上限'
    | '魔法恢复'
    | '攻击'
    | '护甲'
    | '移动速度'
    | '攻击速度'
    | '冷却缩减'
    | '减耗'
```

### get
```lua
unit:get(attributeName: string)
    -> value: number

attributeName: string
    | '生命'
    | '生命上限'
    | '生命恢复'
    | '魔法'
    | '魔法上限'
    | '魔法恢复'
    | '攻击'
    | '护甲'
    | '移动速度'
    | '攻击速度'
    | '冷却缩减'
    | '减耗'
```

### add
```lua
unit:add(attributeName: string, attributeValue: number)
    -> destructor: function

attributeName: string
    | '生命'
    | '生命上限'
    | '生命恢复'
    | '魔法'
    | '魔法上限'
    | '魔法恢复'
    | '攻击'
    | '护甲'
    | '移动速度'
    | '攻击速度'
    | '冷却缩减'
    | '减耗'
```

### addRestriction
```lua
unit:addRestriction(restrictionName: string)
    -> destructor: function

restrictionName: string
    | '硬直'
```

### removeRestriction
```lua
unit:removeRestriction(restrictionName: string)

restrictionName: string
    | '硬直'
```

### getRestriction
```lua
unit:getRestriction(restrictionName: string)
    -> count: integer

restrictionName: string
    | '硬直'
```

### hasRestriction
```lua
unit:hasRestriction(restrictionName: string)
    -> boolean

restrictionName: string
    | '硬直'
```

### isAlive
```lua
unit:isAlive()
    -> boolean
```

### isHero
```lua
unit:isHero()
    -> boolean
```

### kill
```lua
unit:kill([target: unit])
```

### remove
```lua
unit:remove()
```

### getPoint
```lua
unit:getPoint()
    -> point
```

### setPoint
```lua
unit:setPoint(point)
```

### getOwner
```lua
unit:getOwner()
    -> player
```

### setOwner
```lua
unit:setOwner(player[, changeColor: boolean])
    -> boolean
```

### particle
```lua
unit:particle(model: string, socket: string)
    -> destructor: function
```

### setFacing
```lua
unit:setFacing(angle: number[, time: number])
```

### getFacing
```lua
unit:getFacing()
    -> number
```

### createUnit
```lua
unit:createUnit(name: string, point, face: number)
    -> unit
```

### addHeight
```lua
unit:addHeight(number)
```

### getHeight
```lua
unit:getHeight()
    -> number
```

### getCollision
```lua
unit:getCollision()
    -> number
```

### addSkill
```lua
unit:addSkill(name: string, type: string[, slot: integer])
    -> skill

type: string
    | '技能'
    | '物品'
    | '隐藏'
```

### findSkill
```lua
unit:findSkill(name: string[, type: string])
    -> skill

type: string
    | '技能'
    | '物品'
    | '隐藏'
```

### eachSkill
```lua
for skill in unit:eachSkill([type: string]) do
end

type: string
    | '技能'
    | '物品'
    | '隐藏'
```

### event
```lua
unit:event(name: string, callback: function)
    -> trigger
```

### eventDispatch
```lua
unit:eventDispatch(name, ...)
    -> any
```

### eventNotify
```lua
unit:eventNotify(name, ...)
```

### moverTarget
```lua
unit:moverTarget(data)
    -> mover
```

### moverLine
```lua
unit:moverLine(data)
    -> mover
```

### walk
```lua
unit:walk(point/unit)
    -> boolean
```

### attack
```lua
unit:attack(point/unit)
    -> boolean
```

### blink
```lua
unit:blink(point)
    -> boolean
```

### reborn
```lua
unit:reborn(point, showEffect: boolean)
    -> boolean
```
