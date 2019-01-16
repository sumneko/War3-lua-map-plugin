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

### __sub
```lua
point - {angle: number, distance: number}
    -> point
```

### __mul
```lua
point * point
    -> distance: number
```

### __div
```lua
point / point
    -> angle: number
```

### ac.point
```lua
ac.point(x: number, y: number)
    -> point
```
