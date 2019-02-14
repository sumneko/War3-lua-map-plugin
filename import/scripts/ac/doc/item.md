# item
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
