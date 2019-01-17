local jass = require 'jass.common'
local hotkey = require 'ac.war3.hotkey'

local DialogHandle = {}

local function onClick(dialog, btn)
    dialog:hide()
    if not dialog.onClick then
        return
    end
    for _, button in ipairs(dialog._button) do
        if button._handle == btn then
            dialog:onClick(button.name)
            break
        end
    end
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
        local dialog = player._dialog[1]
        if dialog then
            onClick(dialog, btn)
        end
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
    if self:isVisible() then
        jass.DialogSetMessage(self._handle, self._title)
    end
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
    if not self:isVisible() then
        return
    end
    jass.DialogClear(self._handle)
    jass.DialogSetMessage(self._handle, self._title)
    for _, button in ipairs(self._button) do
        button._handle = jass.DialogAddButton(self._handle, button.description, hotkey[button.hotkey] or 0)
    end
end

function mt:isVisible()
    return self._owner._dialog[1] == self
end

function mt:show()
    for i, dl in ipairs(self._owner._dialog) do
        if dl == self then
            table.remove(self._owner._dialog, i)
            break
        end
    end
    table.insert(self._owner._dialog, 1, self)
    self:refresh()
    jass.DialogDisplay(self._owner._handle, self._handle, true)
end

function mt:hide()
    for i, dl in ipairs(self._owner._dialog) do
        if dl == self then
            table.remove(self._owner._dialog, i)
            break
        end
    end
    if #self._owner._dialog == 0 then
        jass.DialogDisplay(self._owner._handle, self._handle, false)
    else
        self._owner._dialog[1]:show()
    end
end

return function (player, data)
    if not ac.isPlayer(player) then
        return nil
    end
    if type(data) ~= 'table' then
        return nil
    end
    if not player._dialog then
        player._dialog = {}
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
    dialog:show()

    return dialog
end
