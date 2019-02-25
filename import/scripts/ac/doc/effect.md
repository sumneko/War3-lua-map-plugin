# effect
```lua
unit:effect {
    target = point,
    model = string,
    [size = number,]
    [xScale = number,]
    [yScale = number,]
    [zScale = number,]
    [height = number,]
    [speed = number,]
    [angle = number,]
}
    -> effect

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
