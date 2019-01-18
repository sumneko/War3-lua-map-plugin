local timerDialog = require 'ac.timerdialog'
local board = require 'ac.board'

function ac.game:timerDialog(...)
    return timerDialog(ac.localPlayer(), ...)
end

function ac.game:board(...)
    return board(nil, ...)
end
