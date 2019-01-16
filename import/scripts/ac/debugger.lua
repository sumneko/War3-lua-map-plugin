local function tryDebugger()
	local dbg = require 'debugger'
	dbg:io 'listen:127.0.0.1:4279'
	dbg:start()
	print('Debugger startup, listen port: 4279')
end

if ac.test then
	pcall(tryDebugger)
end
