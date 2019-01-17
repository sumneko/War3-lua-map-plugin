local jass = require 'jass.common'
local mt = {}

mt.__index = mt
mt.type = 'timer dialog'

function mt:setTitle(title)
    if self._removed then
        return
    end
    if title == nil then
        title = ''
    else
        title = tostring(title)
    end
    jass.TimerDialogSetTitle(self._handle, title)
end

function mt:setTimer(timer)
    if ac.isTimer(timer) then
        self._timer = timer
    else
        self._timer = nil
    end
    update(self)
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.DestroyTimerDialog(self._handle)
    self._handle = 0
end

return function (player, title, timer)
    if not ac.isPlayer(player) then
        return nil
    end
    if ac.clock() == 0.0 then
        log.error('计时器窗口不能在初始化时创建')
        return nil
    end

    local handle = jass.CreateTimerDialog(nil)
    local td = setmetatable({
        _handle = handle,
        _owner = player,
    }, mt)

    td:setTitle(title)
    td:setTimer(timer)

    if player == ac.localPlayer() then
        jass.TimerDialogDisplay(td._handle, true)
    end

    return td
end
