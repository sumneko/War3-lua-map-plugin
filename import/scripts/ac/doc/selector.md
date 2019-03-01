# selector

```lua
for _, u in ac.selector()
    : inRange(point, radius)
    : of {'英雄', '建筑'}
    : ofNot '机械'
    : isEnemy(hero)
    : isVisible(hero)
    : ofNotIllusion()
    : allowDead()
    : filter(function (u)
        return u:get '生命' / u:get '生命上限' <= 0.5
    end)
    : ipairs()
do
end

for _, it in ac.selecot()
    : mode '物品'
    : inRange(point, radius)
    : ipairs()
do
end
```

### ac.selector
```lua
ac.selector()
    -> selector
```

### inRange
```lua
selector:inRange(point/unit, radius: number)
    -> selector
```

### inSector
```lua
selector:inSector(point/unit, radius: number, angle: number, section: number)
    -> selector
```

### inLine
```lua
selector:inLine(start: point/unit, length: number, angle: number, width: number)
    -> selector
```

### mode
默认模式为`单位`。在`物品`模式下，选取器规则只有形状有效。

```lua
selector:mode(mode: string)
    -> selector

mode: string
    | '单位'
    | '物品'
```

### filter
```lua
selector:filter(function(unit)
    return isUnitSelected
end)
    -> selector
```

### isNot
```lua
selector:isNot(unit)
    -> selector
```

### isEnemy
```lua
selector:isEnemy(unit)
    -> selector
```

### isAlly
```lua
selector:isAlly(unit)
    -> selector
```

### isVisible
```lua
selector:isVisible(unit)
    -> selector
```

### of
```lua
selector:of(type: string/table[string])
    -> selector
```

### ofNot
```lua
selector:ofNot(type: string/table[string])
    -> selector
```

### ofIllusion
```lua
selector:ofIllusion()
    -> selector
```

### ofNotIllusion
```lua
selector:ofNotIllusion()
    -> selector
```

### allowDead
```lua
selector:allowDead()
    -> selector
```

### allowGod
```lua
selector:allowGod()
    -> selector
```

### get
```lua
selector:get()
    -> table[unit]
```

### ipairs
```lua
for i, unit in selector:ipairs() do
end
```

### random
```lua
selector:random()
    -> unit
```
