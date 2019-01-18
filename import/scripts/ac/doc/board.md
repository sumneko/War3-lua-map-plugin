# board
```lua
ac.game:board(row: integer, col: integer[, title: string])
    -> board
```

```lua
player:board(row: integer, col: integer[, title: string])
    -> board
```

参数`async`用于异步，例：
```lua
-- 对所有人显示面板
local board = ac.game:board(1, 1)
board:show()

-- 只对玩家1显示面板
local board = ac.game:board(1, 1)
board:show(function (player)
    return player == ac.player(1)
end)

-- 只对玩家1显示面板
local board = ac.player(1):board(1, 1)
board:show()
```

### board item
```lua
board[row][col]
    -> board item
```

### show
```lua
board:show([async: function])
```

### hide
```lua
board:hide([async: function])
```

### maximize
```lua
board:maximize([async: function])
```

### minimize
```lua
board:minimize([async: function])
```

### title
```lua
board:title(string[, async: function])
```

### text
```lua
board:text(string[, async: function])
```

### icon
```lua
board:icon(string[, async: function])
```

### width
```lua
board:width(number[, async: function])
```

### style
```lua
board:style(showValue: boolean, showIcon: boolean[, async: function])
```

### remove
```lua
board:remove()
```
