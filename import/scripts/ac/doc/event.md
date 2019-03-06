# ac.game

### 游戏-造成伤害
```lua
ac.game:event('游戏-造成伤害', function (trg, unit, damage)
end)
```

# unit

### 单位-造成伤害
```lua
unit:event('单位-造成伤害', function (trg, unit, damage)
end)
```

### 单位-受到伤害
```lua
unit:event('单位-受到伤害', function (trg, unit, damage)
end)
```

### 单位-攻击出手
```lua
unit:event('单位-攻击出手', function (trg, unit, target, damage, mover)
end)
```

### 单位-初始化
```lua
unit:event('单位-初始化', function (trg, unit)
end)
```

### 单位-创建
```lua
unit:event('单位-创建', function (trg, unit)
end)
```

### 单位-死亡
```lua
unit:event('单位-死亡', function (trg, unit, killer)
end)
```

### 单位-复活
```lua
unit:event('单位-复活', function (trg, unit)
end)
```

### 单位-升级
```lua
unit:event('单位-升级', function (trg, unit)
end)
```

### 单位-降级
```lua
unit:event('单位-降级', function (trg, unit)
end)
```

### 单位-属性变化
```lua
unit:event('单位-属性变化', function (trg, unit, attributeName: string, delta: number)
end)
```

# player

### 玩家-选中单位
```lua
player:event('玩家-选中单位', function (trg, player, unit)
end)
```

### 玩家-取消选中
```lua
player:event('玩家-取消选中', function (trg, player, unit)
end)
```

### 玩家-聊天
```lua
player:event('玩家-聊天', function (trg, player, string)
end)
```

# skill

### 技能-获得
```lua
skill:event('技能-获得', function (trg, skill)
end)
```

### 技能-失去
```lua
skill:event('技能-失去', function (trg, skill)
end)
```

### 技能-升级
```lua
skill:event('技能-升级', function (trg, skill)
end)
```

### 技能-即将施法

返回`false`可以阻止技能发动。

```lua
skill:event('技能-即将施法', function (trg, skill)
    return false
end)
```

### 技能-施法开始
```lua
skill:event('技能-施法开始', function (trg, skill)
end)
```

### 技能-施法引导
```lua
skill:event('技能-施法引导', function (trg, skill)
end)
```

### 技能-施法出手
```lua
skill:event('技能-施法出手', function (trg, skill)
end)
```

### 技能-施法完成
```lua
skill:event('技能-施法完成', function (trg, skill)
end)
```

### 技能-施法停止
```lua
skill:event('技能-施法停止', function (trg, skill)
end)
```

### 技能-施法打断
```lua
skill:event('技能-施法打断', function (trg, skill)
end)
```

# item

### 物品-获得
```lua
item:event('物品-获得', function (trg, item)
end)
```

### 物品-失去
```lua
item:event('物品-失去', function (trg, item)
end)
```

### 物品-移动
```lua
item:event('物品-移动', function (trg, item[, otherItem: item])
end)
```

### 物品-即将获得

返回`true`可以无视物品栏限制获得物品；返回`false`可阻止单位获得物品。

```lua
item:event('物品-即将获得', function (trg, item, unit)
    return false
end)
```

### 物品-即将拾取

右键点击物品时触发，返回`true`可以无视物品栏限制拾取物品；返回`false`可阻止单位的拾取行为。

```lua
item:event('物品-即将拾取', function (trg, item, unit)
    return false
end)
```

### 物品-即将购买

购买物品时触发，此时的`item`并不是一个物品对象，因此只能进行数据读取等操作。返回`true`可以无视物品栏限制购买物品；返回`false`可以阻止购买物品。

```lua
item:event('物品-即将购买', function (trg, item, buyer: unit, shop)
    return false
end)
```
