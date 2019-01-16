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
unit:event('单位-死亡', function (trg, unit)
end)
```

# player

### 玩家-选中单位
```lua
unit:event('玩家-选中单位', function (trg, player, unit)
end)
```

### 玩家-取消选中
```lua
unit:event('玩家-取消选中', function (trg, player, unit)
end)
```
