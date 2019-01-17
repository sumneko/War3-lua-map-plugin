local jass = require 'jass.common'
local hotkey = require 'ac.war3.hotkey'

local DialogHandle = {}

local function onClick(dialog, btn)
end

local function getDialogHandle(player)
    if DialogHandle[player] then
        return DialogHandle[player]
    end
    local handle = jass.DialogCreate()
    local trg = jass.CreateTrigger()
    jass.TriggerRegisterDialogEvent(trg, handle)
    jass.TriggerAddCondition(trg, jass.Condition(function ()
        local btn = jass.GetClickedButton()
    end))

    DialogHandle[player] = handle
    return handle
end

local mt = {}
mt.__index = mt
mt.type = 'dialog'

function mt:__tostring()
    return ('{dialog|%s}'):format(self._handle)
end

function mt:setTitle(title)
    if type(title) ~= 'string' then
        return
    end
    self._title = title
end

function mt:addButton(name, key, description)
    if type(name) ~= 'string' then
        return
    end
    if description == nil then
        description = name
    else
        description = tostring(description)
    end
    self._button[#self._button+1] = {
        name = name,
        hotkey = key,
        description = description,
    }
end

function mt:refresh()
    jass.DialogClear(self._handle)
    jass.DialogSetMessage(self._handle, self._title)
    for _, button in ipairs(self._button) do
        jass.DialogAddButton(self._handle, button.description, hotkey[button.hotkey] or 0)
    end
end

function mt:show()
    jass.DialogDisplay(self._owner._handle, self._handle, true)
end

function mt:hide()
    jass.DialogDisplay(self._owner._handle, self._handle, false)
end

return function (player, data)
    if not ac.isPlayer(player) then
        return nil
    end
    if type(data) ~= 'table' then
        return nil
    end
    local handle = getDialogHandle(player)

    local dialog = setmetatable({
        _owner = player,
        _handle = handle,
        _button = {},
    }, mt)

    dialog:setTitle(dialog, data[1])
    for _, info in ipairs(data) do
        if type(info) == 'table' then
            dialog:addButton(info[1], info[2], info[3])
        end
    end
    dialog:refresh()
    dialog:show()

    return dialog
end
