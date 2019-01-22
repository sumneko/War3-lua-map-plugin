# skill

### getOwner
```lua
skill:getOwner()
    -> unit
```

### getName
```lua
skill:getName()
    -> string
```

### remove
```lua
skill:remove()
```

### set
```lua
skill:set(key: string, value: any)
```

### get
```lua
skill:get(key: string)
    -> any
```

### loadString
```lua
skill:loadString(string)
    -> string
```

### getOrder
```lua
skill:getOrder()
    -> string
```

### getTarget
```lua
skill:getTarget()
    -> unit/point
```

### isCast
```lua
skill:isCast()
    -> boolean
```

## event

### onAdd
```lua
function skill:onAdd()
end
```

### onRemove
```lua
function skill:onRemove()
end
```

### onUpgrade
```lua
function skill:onUpgrade()
end
```

### onCastStart
```lua
function skill:onCastStart()
end
```

### onCastChannel
```lua
function skill:onCastChannel()
end
```

### onCastShot
```lua
function skill:onCastShot()
end
```

### onCastFinish
```lua
function skill:onCastFinish()
end
```

### onCastStop
```lua
function skill:onCastStop()
end
```

### onCastBreak
```lua
function skill:onCastBreak()
end
```
