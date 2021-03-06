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
	if boolean == nil then
		boolean = true
	end
	jass.FogEnable(boolean)
end

function ac.game:mask(boolean)
	if boolean == nil then
		boolean = true
	end
	jass.FogMaskEnable(boolean)
end

function ac.game:music(name)
	if not name then
		name = 'music'
	end
	jass.StopMusic(false)
	ac.wait(0,function()
		jass.PlayMusic(name)
	end)
end

function ac.game:musicTheme(name)
	if name then
		jass.PlayThematicMusic(name)
	end
end

function ac.game:cameraBounds(MinX,MinY,MaxX,MaxY)
	if not MinX or not MinY or not MaxX or not MaxY then
		MinX,MinY,MaxX,MaxY = ac.world.bounds()
	end
	jass.SetCameraBounds(MinX,MinY,MinX,MaxY,MaxX,MaxY,MaxX,MinX)
end

function ac.game:setDayTime(time)
	jass.SetFloatGameState(2,time)
end

function ac.game:stopDayTime(boolean)
	jass.SuspendTimeOfDay(boolean)
end

function ac.game:getDayTime()
	return jass.GetTimeOfDay()
end

function ac.game:ping(point,time,data)
	local x,y = point:getXY()
	--jass.PingMinimap(x,y,time or 1)
	data = data or {}
	jass.PingMinimapEx(x,y,time or 1,data.r or 255,data.g or 255,data.b or 255,data.type or false)
end