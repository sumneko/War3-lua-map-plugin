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

unit:createItem(name: string[, slot: integer])
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

### cool
购买冷却

```lua
cool = 1
```

### pawnable
可以卖掉

```lua
pawnable = 1
```

### rune
可以使用（图标可点击）

```lua
useable = 1
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

### stack
```lua
item:stack(stack: number)

item:stack()
    -> stack: number
```

### getPoint
```lua
item:getPoint()
    -> point
```

### show
```lua
item:show()
```

### hide
```lua
item:hide()
```

### isShow
```lua
item:isShow()
    -> boolean
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

返回`true`可以无视物品栏限制获得物品；返回`false`可阻止单位获得物品，如果在商店购买物品时发生，第二个返回值会显示在玩家屏幕上。

```lua
function item:onCanAdd(unit)
    return false, "不能购买"
end
```

### onCanLoot

右键点击物品时触发，返回`true`可以无视物品栏限制拾取物品；返回`false`可阻止单位的拾取行为。

```lua
function item:onCanLoot(unit)
    return false
end
```

### onCanBuy

购买物品时触发，此时的`self`并不是一个物品对象，因此只能进行数据读取等操作。返回`true`可以无视物品栏限制购买物品；返回`false`可以阻止购买物品，第二个返回值会显示在玩家屏幕上。

```lua
function item:onCanBuy(buyer: unit, shop)
    return false, "不能购买"
end
```
