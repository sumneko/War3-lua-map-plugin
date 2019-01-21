# math

### sin
```lua
ac.math.sin(number)
    -> number
```

### cos
```lua
ac.math.cos(number)
    -> number
```

### tan
```lua
ac.math.tan(number)
    -> number
```

### asin
```lua
ac.math.asin(number)
    -> number
```

### acos
```lua
ac.math.acos(number)
    -> number
```

### atan
```lua
ac.math.atan(y: number[, x: number])
    -> number
```

### randomFloat
```lua
ac.math.randomFloat(min: number, max: number)
    -> number
```

### includedAngle
```lua
ac.math.includedAngle(angle1: number, angle2: number)
    -> angle: number, rate: integer
```
第一个返回值为2个角度的夹角，取值范围为`[0, 180)`。
第二个返回值为旋转方向，`1`表示角度1顺时针旋转为角度2，`-1`表示角度1逆时针旋转位角度2，即满足`angle1 + angle * rate == angle2`

# utility

### isUnit
```lua
ac.isUnit(any)
    -> boolean
```

### isPoint
```lua
ac.isPoint(any)
    -> boolean
```

### isPlayer
```lua
ac.isPlayer(any)
    -> boolean
```

### isTimer
```lua
ac.isTimer(any)
    -> boolean
```

### isNumber
```lua
ac.isNumber(any)
    -> boolean
```

### isInteger
```lua
ac.isInteger(any)
    -> boolean
```

### isTable
```lua
ac.isTable(any)
    -> boolean
```

### isString
```lua
ac.isString(any)
    -> boolean
```

### toNumber
```lua
ac.toNumber(any[, default: number])
    -> number
```

### toInteger
```lua
ac.toInteger(any[, default: integer])
    -> integer
```
