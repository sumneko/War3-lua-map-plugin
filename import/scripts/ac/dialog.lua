local jass = require 'jass.common'

local Dialog = {}

local mt = {}

local function getDialog(player)
    if Dialog[player] then
        return Dialog[player]
    end
    local dialog = setmetatable({
        _handle = jass.DialogCreate(),
    }, mt)
end

mt.__index = mt
mt.type = 'dialog'

function mt:__tostring()
    return ('{dialog|%s}'):format(self._handle)
end

return function (player, data)
    if not ac.isPlayer(player) then
        return nil
    end
    local dialog = getDialog(player)
end
