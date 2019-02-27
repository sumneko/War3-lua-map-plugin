# buff
```lua
ac.buff[buffName: string]
    -> mt: table
```

```lua
unit:addBuff(buffName: string) {
    time = number,
}
```

## parameter

### keep
死亡后保留: integer

可选参数，`1`表示死亡后保留。

### time
持续时间: number

可选参数。

## method

### getOwner
```lua
buff:getOwner()
    -> unit
```

### remove
```lua
buff:remove()
```

## event

### onAdd
```lua
function buff:onAdd()
end
```

### onRemove
```lua
function buff:onRemove()
end
```
