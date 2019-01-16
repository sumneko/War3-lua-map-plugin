
log = require 'jass.log'

log.path = '日志\\test.txt'

local stdPrint = print
function print(...)
	log.info(...)
	return stdPrint(...)
end

local logError = log.error
function log.error(...)
	local trc = debug.traceback()
	logError(...)
	logError(trc)
	stdPrint(...)
	stdPrint(trc)
end
