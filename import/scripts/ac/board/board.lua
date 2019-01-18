local jass = require 'jass.common'
local item = require 'ac.board.item'
local mt = {}

local function fillItems(board, row, col)
    for row = 1, row do
        board[row] = {}
        for col = 1, col do
            board[row][col] = item(board, row, col)
        end
    end
end

mt.__index = mt
mt.type = 'board'

function mt:__tostring()
    return ('{board|%s|%s}'):format(self._handle, self._title)
end

function mt:_check(filter)
    if self._removed then
        return false
    end
    filter = filter or self._filter
    if not filter then
        return true
    end
    return filter(ac.localPlayer())
end

function mt:show(filter)
    if self._removed then
        return false
    end
    filter = filter or self._filter
    if not filter or filter(ac.localPlayer()) then
        jass.MultiboardDisplay(self._handle, true)
    end
end

function mt:hide(filter)
    if self:_check(filter) then
        jass.MultiboardDisplay(self._handle, false)
    end
end

function mt:maximize(filter)
    if self:_check(filter) then
        jass.MultiboardMinimize(self._handle, true)
    end
end

function mt:minimize(filter)
    if self:_check(filter) then
        jass.MultiboardMinimize(self._handle, false)
    end
end

function mt:title(title, filter)
    if self:_check(filter) then
        jass.MultiboardSetTitleText(self._handle, title)
    end
end

function mt:text(text, filter)
    if self:_check(filter) then
        jass.MultiboardSetItemsValue(self._handle, text)
    end
end

function mt:icon(icon, filter)
    if self:_check(filter) then
        jass.MultiboardSetItemsIcon(self._handle, icon)
    end
end

function mt:width(width, filter)
    if self:_check(filter) then
        jass.MultiboardSetItemsWidth(self._handle, width)
    end
end

function mt:style(showValue, showIcon, filter)
    if self:_check(filter) then
        jass.MultiboardSetItemsStyle(self._handle, ac.toBoolean(showValue), ac.toBoolean(showIcon))
    end
end

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    for row = 1, self._row do
        for col = 1, self._col do
            self[row][col]:_remove()
        end
    end
    jass.DestroyMultiboard(self._handle)
    self._handle = 0
end

return function (filter, row, col, title)
    if not ac.isInteger(row) then
        return nil
    end
    if not ac.isInteger(col) then
        return nil
    end
    if ac.clock() == 0.0 then
        log.error('不能在初始化时创建多面板')
        return nil
    end
    local handle = jass.CreateMultiboard()
    jass.MultiboardSetRowCount(handle, row)
    jass.MultiboardSetColumnCount(handle, col)

    local board = setmetatable({
        _handle = handle,
        _title = title,
        _filter = filter,
        _row = row,
        _col = col,
    }, mt)

    fillItems(board, row, col)
    if title then
        board:title(title)
    end

    return board
end
