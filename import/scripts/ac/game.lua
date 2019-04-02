local jass = require 'jass.common'
local timerDialog = require 'ac.timerdialog'
local board = require 'ac.board'

function ac.game:timerDialog(...)
    return timerDialog(ac.localPlayer(), ...)
end

function ac.game:board(...)
    return board(nil, ...)
end

function ac.game:pause()
	jass.PauseGame(true)
end

function ac.game:start()
	jass.PauseGame(false)
end

function ac.game:endGame()
	jass.EndGame(true)
end

function ac.game:fog(boolean)
	if not boolean then
		boolean = true
	end
	jass.FogEnable(boolean)
end

function ac.game:mask(boolean)
	if not boolean then
		boolean = true
	end
	jass.FogMaskEnable(boolean)
end