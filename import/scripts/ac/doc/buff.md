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
