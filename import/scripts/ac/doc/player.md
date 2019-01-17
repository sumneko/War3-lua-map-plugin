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

### createUnit
```lua
player:createUnit(name, point, face)
    -> unit
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

### message
```lua
player:message(text: string, time: number(10.0))
player:message {
    text = '这是字符串{red:s}，这是整数{int:d}，这是保留三位小数的{number:.3f}',
    data = {
        red = '红色',
        int = 10,
        number = 3.1415926,
    },
    color = {
        red = 'ff1111',
    },
    time = 10.0,
    position = {0.5, 0.5},
}
```

### chat
```lua
player:chat(source: player/string, text: string, type: string('私人的'))
player:chat {
    source = '系统',
    text = '这是字符串{red:s}，这是整数{int:d}，这是保留三位小数的{number:.3f}',
    data = {
        red = '红色',
        int = 10,
        number = 3.1415926,
    },
    color = {
        red = 'ff1111',
    },
    type = '私人的',
}
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
