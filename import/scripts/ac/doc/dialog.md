# dialog
```lua
player:dialog {
    '对话框标题',
    {'选项1', 'Q', '显示的描述'},
    {'选项2', 'W'},
    {'选项3', 'E'},
    {'关闭', 'Esc'},
}
    -> dialog
```

### setTitle
```lua
dialog:setTitle(string)
```

### addButton
```lua
dialog:addButton(name: string, key: string[, description: string])
```

### refresh
```lua
dialog:refresh()
```

### isVisible
```lua
dialog:isVisible()
    -> boolean
```

### show
```lua
dialog:show()
```

### hide
```lua
dialog:hide()
```

### onClick
```lua
function mt:onClick(name)
end
```
