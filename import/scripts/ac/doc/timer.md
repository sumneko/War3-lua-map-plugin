# timer

### ac.clock
```lua
ac.clock()
    -> integer
```

### remove
```lua
timer:remove()
```

### pause
```lua
timer:pause()
```

### resume
```lua
timer:resume()
```

### restart
```lua
timer:restart()
```

### remaining
```lua
timer:remaining()
    -> number
```

### 立即执行一次
```lua
timer()
```

### ac.wait
```lua
ac.wait(timeout: number, callback: function)
    -> timer
```

### ac.loop
```lua
ac.loop(timeout: number, callback: function)
    -> timer
```

### ac.timer
```lua
ac.timer(timeout: number, count: integer, callback: function)
    -> timer
```
