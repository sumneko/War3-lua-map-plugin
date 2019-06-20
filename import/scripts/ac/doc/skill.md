# skill
```lua
local mt = ac.skill[skillName: string]

function mt:onAdd()
end

function mt:onRemove()
end
```

## skill.ini

### maxLevel
等级上限

```lua
maxLevel = 3
```

### initLevel
初始等级

```lua
initLevel = 1
```

### title
标题

```lua
title = '测试技能 - 等级 ${level}'
```

### description
描述

```lua
description = '技能描述'
```

### icon
图标

```lua
icon = [[ReplaceableTextures\CommandButtons\BTNInvisibility.blp]]
```

### iconLevel
图标等级

当同一个格子上有多个技能时，优先显示等级高的

```lua
iconLevel = 10
```

### passiveIcon
被动图标

将图标转化为被动图标

```lua
passiveIcon = 1
```

### range
施法范围

```lua
range = 500
```

### targetType
目标类型

```lua
targetType = '无'
targetType = '点'
targetType = '单位'
targetType = '单位或点'
targetType = '物品'
```

### targetData
目标允许

```lua
targetData = {'地面','空中','敌人',...}
```

### passive
被动技能

```lua
passive = 1
```

### cool
冷却

```lua
cool = 1
```

### cost
消耗

```lua
cost = 100
```

### hotkey
快捷键

```lua
hotkey = 'Q'
```

### animation
动画

```lua
animation = 'attack'
```

### castStartTime
施法开始时间

```lua
castStartTime = 1
```

### castChannelTime
施法引导时间

```lua
castChannelTime = 1
```

### castShotTime
施法出手时间

```lua
castShotTime = 1
```

### castFinishTime
施法完成时间

```lua
castFinishTime = 1
```
### breakOrder
施法完成打断先前命令（仅对无目标技能有效）

```lua
breakOrder = any
```

## method

### getOwner
```lua
skill:getOwner()
    -> unit
```

### getName
```lua
skill:getName()
    -> string
```

### remove
```lua
skill:remove()
```

### set
```lua
skill:set(key: string, value: any)
```

### get
```lua
skill:get(key: string)
    -> any
```

### loadString
```lua
skill:loadString(string)
    -> string
```

### getOrder
```lua
skill:getOrder()
    -> string
```

### getTarget
```lua
skill:getTarget()
    -> unit/point
```

### isCast
```lua
skill:isCast()
    -> boolean
```

### getCd
```lua
skill:getCd()
    -> number
```

### activeCd
```lua
skill:activeCd()

skill:activeCd(maxCd: number)

skill:activeCd(maxCd: number, ignoreCdReduce: boolean)
```

### setCd
```lua
skill:setCd(number)
```

### stack
```lua
skill:stack(stack: number)

skill:stack()
    -> stack: number
```

### getItem
```lua
skill:getItem()
    -> item
```

### stop
```lua
skill:stop()
    -> boolean
```

### cast
```lua
skill:cast([target: any][, data: table])
    -> boolean
```

### disable
```lua
skill:disable()
```

### enable
```lua
skill:enable()
```

### isEnable
```lua
skill:isEnable()
    -> boolean
```

### is
```lua
skill:is(cast: skill)
    -> boolean
```

### show
```lua
skill:show()
```

### hide
```lua
skill:hide()
```

### isShow
```lua
skill:isShow()
    -> boolean
```

### setOption
```lua
skill:setOption(key: string, value: any)

key: string
    | 'title'
    | 'description'
    | 'icon'
    | 'hotkey'
    | 'iconLevel'
    | 'passive'
```
### upgrade

提升1级，等级不可倒退

```lua
skill:upgrade()
```

## event

### onAdd
```lua
function skill:onAdd()
end
```

### onRemove
```lua
function skill:onRemove()
end
```

### onUpgrade
```lua
function skill:onUpgrade()
end
```

### onEnable
```lua
function skill:onEnable()
end
```

### onDisable
```lua
function skill:onDisable()
end
```

### onCanCast

返回`false`可以阻止技能发动。

```lua
function skill:onCanCast()
    return false
end
```

### onCastStart
```lua
function skill:onCastStart()
end
```

### onCastChannel
```lua
function skill:onCastChannel()
end
```

### onCastShot
```lua
function skill:onCastShot()
end
```

### onCastFinish
```lua
function skill:onCastFinish()
end
```

### onCastStop
```lua
function skill:onCastStop()
end
```

### onCastBreak
```lua
function skill:onCastBreak()
end
```
