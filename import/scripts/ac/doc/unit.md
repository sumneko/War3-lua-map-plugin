# unit

### getName
```lua
unit:getName()
    -> name: string
```

### set
```lua
unit:set(attributeName: string, attributeValue: number)
```

### get
```lua
unit:get(attributeName: string)
    -> value: number
```

### add
```lua
unit:add(attributeName: string, attributeValue: number)
    -> destructor: function
```

### addRestriction
```lua
unit:addRestriction(restrictionName: string)
    -> destructor: function
```

### removeRestriction
```lua
unit:removeRestriction(restrictionName: string)
```

### getRestriction
```lua
unit:getRestriction(restrictionName: string)
    -> count: integer
```

### hasRestriction
```lua
unit:hasRestriction(restrictionName: string)
    -> boolean
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
```

### findSkill
```lua
unit:findSkill(name: string[, type: string])
    -> skill
```

### eachSkill
```lua
for skill in unit:eachSkill([type: string]) do
end
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
