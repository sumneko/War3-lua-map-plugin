# rect

```lua
-- 获取在地形编辑中预设的区域，name为区域名
ac.rect(name: string)
    -> rect
-- 指定左下角与右上角创建区域
ac.rect(minPoint: point, maxPoint: point)
    -> rect
-- 指定中心点与宽高创建区域
ac.rect(center: point, width: number, height: number)
    -> rect
-- 指定边界坐标创建区域
ac.rect(minx: number, miny: number, maxx: number, maxy: number)
    -> rect
```

## method

### remove
```lua
rect:remove()
```

### getPoint
```lua
rect:getPoint()
    -> point
```

### width
```lua
rect:width()
    -> number
```

### height
```lua
rect:height()
    -> number
```

## event

### onEnter
```lua
function rect:onEnter(unit)
end
```

### onLeave
```lua
function rect:onLeave(unit)
end
```
