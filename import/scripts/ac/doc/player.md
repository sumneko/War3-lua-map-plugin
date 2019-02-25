# player

### addHero
```lua
player:addHero(unit)
    -> boolean
```

### removeHero
```lua
player:removeHero(unit)
    -> boolean
```

### getHero
```lua
player:getHero([index: integer])
    -> unit
```

### selectUnit
```lua
player:selectUnit(unit)
```

### createUnit
```lua
player:createUnit(name, point, face)
    -> unit
```

### event
```lua
player:event(name: string, callback: function)
    -> trigger
```

### eventDispatch
```lua
player:eventDispatch(name: string, ...)
    -> any
```

### eventNotify
```lua
player:eventNotify(name: string, ...)
    -> any
```

### message
```lua
player:message(text: string[, time: number(10.0)])
player:message {
    text = '这是字符串{red:s}，这是整数{int:d}，这是保留三位小数的{number:.3f}',
    [data = {
        red = '红色',
        int = 10,
        number = 3.1415926,
    },]
    [color = {
        red = 'ff1111',
    },]
    [time = 10.0,]
    [position = {0.5, 0.5},]
}
```

### chat
```lua
player:chat(source: player/string, text: string[, type: string('私人的')])
player:chat {
    source = '系统',
    text = '这是字符串{red:s}，这是整数{int:d}，这是保留三位小数的{number:.3f}',
    [data = {
        red = '红色',
        int = 10,
        number = 3.1415926,
    },]
    [color = {
        red = 'ff1111',
    },]
    [type = '私人的',]
}
type: string
    | '所有人'
    | '盟友'
    | '观看者'
    | '私人的'
```

### dialog
```lua
player:dialog {
    '对话框标题',
    {'选项1', 'Q', '显示的描述'},
    {'选项2', 'W'},
    {'选项3', 'E'},
    {'关闭', 'Esc'},
}
    -> dialog
```

### moveCamera
```lua
player:moveCamera(point[, duration: number])
```

### controller
```lua
player:controller()
    -> controller: string

controller: string
    | '用户'
    | '电脑'
    | '可营救'
    | '中立'
    | '野怪'
    | '空位'
```

### gameState
```lua
player:gameState()
    -> state: string

state: string
    | '空位'
    | '在线'
    | '离线'
```

### timerDialog
```lua
player:timerDialog(title: string[, timer/number])
    -> timer dialog
```

### board
```lua
player:board(row: integer, col: integer[, title: string])
    -> board
```

### id
```lua
player:id()
    -> integer
```

### name
```lua
player:name([newName: string])
    -> [name: string]
```

### alliance
```lua
player:alliance(other: player, type: string[, flag: boolean])
    -> [flag: boolean]

type: string
    | '结盟'
    | '请求'
    | '回应'
    | '经验'
    | '技能'
    | '视野'
    | '控制'
    | '高级控制'
    | '救援'
    | '队伍视野'
```

### isEnemy
```lua
player:isEnemy(other: unit/player)
    -> boolean
```

### isAlly
```lua
player:isAlly(other: unit/player)
    -> boolean
```

### isVisible
```lua
player:isVisible(other: unit)
    -> boolean
```

### set
```lua
player:set(attributeName: string, attributeValue: number)

attributeName: string
    | '金币'
    | '木材'
    | '食物'
    | '食物上限'
```

### get
```lua
player:get(attributeName: string)
    -> value: number

attributeName: string
    | '金币'
    | '木材'
    | '食物'
    | '食物上限'
```

### add
```lua
player:add(attributeName: string, attributeValue: number)
    -> destructor: function

attributeName: string
    | '金币'
    | '木材'
    | '食物'
    | '食物上限'
```

### eachPlayer
```lua
for player in ac.eachPlayer() do
end
```

### effect
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

### ac.player
```lua
ac.player(index: integer)
    -> player
```

### ac.localPlayer
```lua
ac.localPlayer()
    -> player
```
