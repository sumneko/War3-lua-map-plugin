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

### pulse
心跳周期: number

可选参数，每隔这个时间触发一次`onPulse`事件。注意，如果`time`恰好是`pulse`的整数倍，则状态移除的那个时候不会触发`onPulse`事件。

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

### remaining
```lua
buff:remaining()
    -> time: number

buff:remaining(time: number)
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

### onPulse
```lua
function buff:onPulse()
end
```
