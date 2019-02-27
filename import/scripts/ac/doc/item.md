# item
```lua
local mt = ac.item[itemName: string]

function mt:onAdd()
end

function mt:onRemove()
end
```

```lua
point:createItem(name: string)
    -> item

unit:createItem(name: string)
    -> item
```

## item.ini

### skill
关联技能

```lua
skill = '震荡波'
```

### title
标题

```lua
title = '物品名称'
```

### description
描述

```lua
description = '物品描述'
```

### icon
图标

```lua
icon = [[ReplaceableTextures\CommandButtons\BTNInvisibility.blp]]
```

### price
售价

```lua
[[.price]]
type = '金币'
value = 1000
```

### attribute
属性

```lua
attribute = {
'生命上限' = 1000,
'攻击' = 100,
}
```

### drop
可以丢弃

```lua
drop = 1
```

### rune
神符

```lua
rune = 1
```

## method

### getOwner
```lua
item:getOwner()
    -> unit
```

### remove
```lua
item:remove()
```

### blink
```lua
item:blink(point)
```

### getName
```lua
item:getName()
    -> string
```

### isRune
```lua
item:isRune()
    -> boolean
```

### give
```lua
item:give(unit[, slot: integer])
    -> boolean
```

### getSlot
```lua
item:getSlot()
    -> integer
```

## event

### onAdd
```lua
function item:onAdd()
end
```

### onRemove
```lua
function item:onRemove()
end
```

### onCanAdd

返回`false`可阻止单位获得物品

```lua
function item:onCanAdd(unit)
    return false
end
```

### onCanLoot

右键点击物品时触发，返回`false`可阻止单位的拾取行为

```lua
function item:onCanLoot(unit)
    return false
end
```
