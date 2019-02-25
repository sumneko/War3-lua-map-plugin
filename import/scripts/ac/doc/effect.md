# effect
```lua
player:effect {
    target = point,
    model = string,
    [size = number,]
    [xScale = number,]
    [yScale = number,]
    [zScale = number,]
    [height = number,]
    [speed = number,]
    [angle = number,]
    [time = number,]
    [skipDeath = boolean,]
    [sight = function,]
}
    -> effect
```

## parameter

### target
位置: point

### model
模型: string

### size
缩放: number

可选参数。

### xScale
X轴缩放: number

可选参数，优先于`size`。

### yScale
Y轴缩放: number

可选参数，优先于`size`。

### zScale
Z轴缩放: number

可选参数，优先于`size`。

### height
高度: number

可选参数。

### speed
高度: number

可选参数。

### angle
朝向: number

可选参数。

### time
持续时间: number

可选参数。

### skipDeath
跳过死亡动画: boolean

可选参数。

### sight
可见性: function

可选参数，会以一个player为参数回调此函数，返回`true`表示该玩家能看到此特效。

```lua
sync = function (player)
    return player == ac.player(1)
end
```

## method

### blink
```lua
effect:blink(point)
```

### size
```lua
effect:size(size: number)

effect:size(xScale: number, yScale: number, zScale: number)

effect:size()
    -> xScale: number, yScale: number, zScale: number
```

### speed
```lua
effect:speed(number)

effect:speed()
    -> number
```

### height
```lua
effect:height(number)

effect:height()
    -> number
```

### angle
```lua
effect:angle(number)

effect:angle()
    -> number
```

### remaining
```lua
effect:remaining(number)

effect:remaining()
    -> number
```

### remove
```lua
effect:remove()
```
