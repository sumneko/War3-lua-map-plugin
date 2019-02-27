# buff
```lua
local mt = ac.buff[buffName: string]

mt.keep = 1

function mt:onAdd()
end

function mt:onRemove()
end
```

```lua
unit:addBuff(buffName: string) {
    time = number,
    pulse = number,
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

### source
来源: unit

可选参数，影响`coverGlobal`属性。默认为获得状态的单位。

### coverType
共存模式: integer

* `0`: 独占模式，单位只能同时保留一个同名状态。on_cover可以决定哪个状态保留下来。
* `1`: 共存模式，单位可以同时保留多个同名状态。on_cover可以决定这些状态的排序。

可选参数，默认为`0`。

### coverGlobal
全局覆盖: integer

* `0`: 必须名字和来源都相同才视为同名状态，触发覆盖机制。
* `1`: 只要名字相同就会视为同名状态，触发覆盖机制。

可选参数，默认为`0`。

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

### pulse
```lua
buff:pulse()
    -> pulse: number

buff:pulse(pulse: number)
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

### onCover
```lua
function buff:onCover(newBuff: buff)
    return true
end
```

返回值的含义：

* 独占模式
    * `true`: 当前状态被移除，新的状态被添加。
    * `false`: 阻止新的状态添加。
* 共存模式
    * `true`: 新的状态排序到当前状态之前。
    * `false`: 新的状态排序到当前状态之后。

### onFinish
```lua
function buff:onFinish()
end
```
