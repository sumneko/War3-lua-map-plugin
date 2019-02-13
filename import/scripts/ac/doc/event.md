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
