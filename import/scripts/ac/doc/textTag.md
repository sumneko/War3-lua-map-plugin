# text tag
```lua
ac.textTag()
    -> textTag
```

```lua
ac.textTag()
    : text('文字内容', 0.1)
    : at(ac.point(500, 500), 100)
    : speed(0.2, 45)
    : life(2, 1)
    : show(function (player)
        return player == ac.player(1)
    end)
```

### text
```lua
textTag:text(string[, size: number(0.05)])
    -> textTag
```

### at
```lua
textTag:at(point[, height: number(0.0)])
    -> textTag
```

### speed
```lua
textTag:speed(speed: number[, angle: number(90.0)])
    -> textTag
```

### life
```lua
textTag:life(life: number[, fade: number])
    -> textTag
```

### show
```lua
textTag:show(function (player)
    return isShowToPlayer: boolean
end)
    -> textTag
```

### pause
```lua
textTag:pause(boolean)
    -> textTag
```

### permanent
```lua
textTag:permanent(boolean)
    -> textTag
```

### age
```lua
textTag:age(number)
    -> textTag
```

### remove
```lua
textTag:remove()
```
