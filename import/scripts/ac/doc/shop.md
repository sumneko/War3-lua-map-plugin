# shop
```lua
player:createShop(name: string, point, face: number)
    -> shop
```

### setItem
```lua
shop:setItem(itemName: string, index: integer[, hotkey: string])
    -> boolean
```

### setBuyRange
```lua
shop:setBuyRange(number)
```

### buyItem
```lua
shop:buyItem(itemName: string[, buyer: unit])
```

### getItem
```lua
shop:getItem(itemName: string/integer)
    -> skill
```
