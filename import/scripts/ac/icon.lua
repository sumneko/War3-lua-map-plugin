local japi = require 'jass.japi'

local DisIcons = {}

local function getDisIcon(path)
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

local IconCache = {}
local PoolCount = 0

local function add(path, mask)
    local newPath = mask .. '\\' .. path
    if not IconCache[newPath] then
        PoolCount = PoolCount + 1
        local resultPath = ('_resource\\blend\\result_%03d.blp'):format(PoolCount)
        IconCache[newPath] = resultPath
        japi.EXBlendButtonIcon(('_resource\\blend\\%s.blp'):format(mask), path, resultPath)
    end
    return IconCache[newPath]
end

return {
    getDisIcon = getDisIcon,
    add = add,
}
