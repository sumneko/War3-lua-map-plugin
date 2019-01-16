# player

### addHero
```lua
player:addHero(unit)
    -> boolean
```

### removeHero
```lua
player:removeHero(unit)
    -> boolean
```

### getHero
```lua
player:getHero([index: integer])
    -> unit
```

### selectUnit
```lua
player:selectUnit(unit)
```

### event
```lua
player:event(name: string, callback: function)
    -> trigger
```

### eventDispatch
```lua
player:eventDispatch(name: string, ...)
    -> any
```

### eventNotify
```lua
player:eventNotify(name: string, ...)
    -> any
```

### ac.player
```lua
ac.player(index: integer)
    -> player
```

### ac.localPlayer
```lua
ac.localPlayer()
    -> player
```
