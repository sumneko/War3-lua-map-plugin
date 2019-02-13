# point

### getXY
```lua
point:getXY()
    -> x: number, y: number
```

### copy
```lua
point:copy()
    -> point
```

### getPoint
```lua
point:getPoint()
    -> point
```

### distance
```lua
point:distance(other: point)
    -> number
```

### angle
```lua
point:angle(other: point)
    -> number
```

### 极坐标
```lua
point - {angle: number, distance: number}
    -> point
```

### 求距离
```lua
point * point
    -> distance: number
```

### 求方向
```lua
point / point
    -> angle: number
```

### createItem
```lua
point:createItem(name: string)
    -> item
```

### ac.point
```lua
ac.point(x: number, y: number)
    -> point
```
