local timerDialog = require 'ac.timerdialog'

function ac.game:timerDialog(...)
    return timerDialog(ac.localPlayer(), ...)
end
