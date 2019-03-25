local japi = require 'jass.japi'

local DisIcons = {}

local function getDisIcon(path)
    if not ac.isString(path) then
        return ''
    end
    if not DisIcons[path] then
        local name = path:match [[[^\]+$]]
        if name then
            DisIcons[path] = [[ReplaceableTextures\CommandButtonsDisabled\DIS]] .. name
            japi.EXDclareButtonIcon(path)
        else
            DisIcons[path] = ''
        end
    end
    return DisIcons[path]
end

return {
    getDisIcon = getDisIcon,
}
