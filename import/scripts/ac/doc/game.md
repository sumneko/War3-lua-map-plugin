# game

### timerDialog
```lua
ac.game:timerDialog(title: string[, timer/number])
    -> timer dialog
```

### board
```lua
ac.game:board(row: integer, col: integer[, title: string])
    -> board
```

### pause
```lua
ac.game:pause()
```

### start
```lua
ac.game:start()
```

### endGame
```lua
ac.game:endGame()
```

### ac.game:fog
```lua
ac.game:fog([boolean: boolean])
```

### ac.game:mask
```lua
ac.game:mask([boolean: boolean])
```

### ac.game:music
```lua
ac.game:music([string: boolean])
```

### ac.game:musicTheme
```lua
ac.game:musicTheme([string: boolean])
```

### ac.game:cameraBounds
```lua
ac.game:cameraBounds([MinX: number,MinY: number,MaxX: number,MaxY: number])
```

### ac.game:setDayTime
```lua
ac.game:setDayTime(time: number)
```

### ac.game:stopDayTime
```lua
ac.game:stopDayTime(boolean: boolean)
```

### ac.game:getDayTime
```lua
ac.game:getDayTime()
	-> number
```

### ac.game:ping
```lua
ac.game:ping(point:point[,time:number,data:table])
data = {
    r = 255,
    g = 255,
    b = 255,
    type = true,
}
```