local jass = require 'jass.common'
local mt = {}

local function showTime(td, time)
    local show
    if time then
        local want = time // 1.0
        show = want + 0.8
    else
        show = -1.0
    end
    jass.TimerDialogSetRealTimeRemaining(td._handle, show)
end

local function update(td)
    if td._watch then
        td._watch:remove()
    end
    if not td._timer then
        showTime(td, nil)
        return
    end
    if td._timer._removed then
        td:remove()
        return
    end
    local remaining = td._timer:remaining()
    if remaining % 0.5 > 0.0 then
        showTime(td, remaining)
        td._watch = ac.wait(remaining % 0.5, function ()
            update(td)
        end)
    else
        td._watch = ac.loop(0.5, function (t)
            if not td._timer then
                t:remove()
                jass.TimerDialogSetRealTimeRemaining(td._handle, -1.0)
                return
            end
            remaining = td._timer:remaining()
            showTime(td, remaining)
            if td._timer._removed then
                td:remove()
                return
            end
        end)
        td._watch()
    end
end

mt.__index = mt
mt.type = 'timer dialog'
function mt:__tostring()
    return ('{timer dialog|%s|%s}'):format(self._handle, self._title)
end

function mt:setTitle(title)
    if self._removed then
        return
    end
    if title == nil then
        title = ''
    else
        title = tostring(title)
    end
    self._title = title
    jass.TimerDialogSetTitle(self._handle, title)
end

function mt:setTimer(timer)
    if self._removed then
        return
    end
    if self._needRemoveTimer then
        self._needRemoveTimer = false
        self._timer:remove()
    end
    if ac.isTimer(timer) then
        self._timer = timer
    elseif ac.isNumber(timer) then
        self._timer = ac.wait(timer)
        self._needRemoveTimer = true
    else
        self._timer = nil
    end
    update(self)
end

function mt:getTimer()
    return self._timer
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.DestroyTimerDialog(self._handle)
    self._handle = 0
    if self._watch then
        self._watch:remove()
    end
    if self._needRemoveTimer then
        self._timer:remove()
    end
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
