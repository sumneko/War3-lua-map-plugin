local jass = require 'jass.common'
local mt = {}
mt.__index = mt
mt.type = 'board item'

function mt:__tostring()
    return ('{board item|%s|%s|%s}'):format(self._handle, self._row, self._col)
end

function mt:text(text, filter)
    if self._removed then
        return
    end
    if self._board:_check(filter) then
        jass.MultiboardSetItemValue(self._handle, text)
    end
end

function mt:icon(icon, filter)
    if self._removed then
        return
    end
    if self._board:_check(filter) then
        jass.MultiboardSetItemIcon(self._handle, icon)
    end
end

function mt:width(width, filter)
    if self._removed then
        return
    end
    if self._board:_check(filter) then
        jass.MultiboardSetItemWidth(self._handle, width)
    end
end

function mt:style(showValue, showIcon, filter)
    if self._removed then
        return
    end
    if self._board:_check(filter) then
        jass.MultiboardSetItemStyle(self._handle, ac.toBoolean(showValue), ac.toBoolean(showIcon))
    end
end

function mt:_remove()
    if self._removed then
        return
    end
    self._removed = true
    jass.MultiboardReleaseItem(self._handle)
    self._handle = 0
end

return function (board, row, col)
    local handle = board._handle
    local itemHandle = jass.MultiboardGetItem(handle, row-1, col-1)
    return setmetatable({
        _board = board,
        _handle = itemHandle,
        _row = row,
        _col = col,
    }, mt)
end
