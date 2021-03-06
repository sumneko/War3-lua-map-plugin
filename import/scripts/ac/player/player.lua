local jass = require 'jass.common'
local japi = require 'jass.japi'
local unit = require 'ac.unit'
local dialog = require 'ac.dialog'
local timerDialog = require 'ac.timerdialog'
local board = require 'ac.board'
local shop = require 'ac.shop'
local attribute = require 'ac.player.attribute'

local MIN_ID = 1
local MAX_ID = 16
local LocalPlayer
local All
local mt = {}

local function init()
    All = {}
    for id = MIN_ID, MAX_ID do
        local handle = jass.Player(id - 1)
        local name = jass.GetPlayerName(handle)
        local player = setmetatable({
            _handle = handle,
            _id = id,
            _hero = {},
            _hotkey = {},
            _originName = name,
        }, mt)
        player._attribute = attribute(player)
        All[id] = player
        All[handle] = player
    end
end

mt.__index = mt
mt.type = 'player'

function mt:__tostring()
    return ('{player|%d|%s}'):format(self:id(), self:name())
end

function mt:addHero(unit)
    if self._hero[unit] then
        return false
    end
    self._hero[#self._hero+1] = unit
    self._hero[unit] = true
    return true
end

function mt:removeHero(unit)
    if not self._hero[unit] then
        return false
    end
    self._hero[unit] = nil
    for i, u in ipairs(self._hero) do
        if u == unit then
            table.remove(self._hero, i)
            return true
        end
    end
    return false
end

function mt:getHero(n)
    if n == nil then
        for _, hero in ipairs(self._hero) do
            if hero._owner == self then
                return hero
            end
        end
    else
        local hero = self._hero[n]
        if hero and hero._owner == self then
            return hero
        end
    end
    return nil
end

function mt:eachHero()
    local list = {}
    for _, hero in ipairs(self._hero) do
        if hero._owner == self then
            list[#list+1] = hero
        end
    end
    local i = 0
    return function ()
        i = i + 1
        return list[i]
    end
end

function mt:selectUnit(unit)
    if self == ac.localPlayer() then
        jass.ClearSelection()
        jass.SelectUnit(unit._handle, true)
    end
end

function mt:createUnit(name, point, face)
    return unit.create(self, name, point, face)
end

function mt:createShop(name, point, face)
    local unit = unit.create(self, name, point, face)
    local shp = shop.create(unit)
    return shp
end

function mt:event(name, f)
    return ac.eventRegister(self, name, f)
end

function mt:eventDispatch(name, ...)
    local res, data = ac.eventDispatch(self, name, ...)
    if res ~= nil then
        return res
    end
    local res, data = ac.game:eventDispatch(name, ...)
    if res ~= nil then
        return res, data
    end
    return nil
end

function mt:eventNotify(name, ...)
    ac.eventNotify(self, name, ...)
    ac.game:eventNotify(name, ...)
end

function mt:message(...)
    if type(...) == 'table' then
        local data = ...
        local x, y
        if data.position then
            x = ac.toNumber(data.position[1])
            y = ac.toNumber(data.position[2])
        else
            x = 0.0
            y = 0.0
        end
        local text = ac.formatText(data.text, data.data, data.color)
        local time = ac.toNumber(data.time, 10.0)
        jass.DisplayTimedTextToPlayer(self._handle, x, y, time, text)
    else
        local text, time = ...
        jass.DisplayTimedTextToPlayer(self._handle, 0.0, 0.0, ac.toNumber(time, 10.0), tostring(text))
    end
end

function mt:chat(...)
    if self ~= ac.localPlayer() then
        return
    end
    local source, text, tp
    if type(...) == 'table' then
        local data = ...
        source = data.source
        text = ac.formatText(data.text, data.data, data.color)
        tp = data.type
    else
        source, text, tp = ...
        text = tostring(text)
    end
    if tp == '所有人' then
        tp = 0
    elseif tp == '盟友' then
        tp = 1
    elseif tp == '观看者' then
        tp = 2
    elseif tp == '私人的' then
        tp = 3
    else
        tp = 3
    end
    if ac.isPlayer(source) then
        japi.EXDisplayChat(source._handle, tp, text)
    else
        local dummyPlayer = ac.player(15)
        local name = jass.GetPlayerName(dummyPlayer._handle)
        jass.SetPlayerName(dummyPlayer._handle, ('|cffffffff%s|r'):format(source))
        japi.EXDisplayChat(dummyPlayer._handle, tp, text)
        jass.SetPlayerName(dummyPlayer._handle, name)
    end
end

function mt:dialog(data)
    return dialog(self, data)
end

function mt:moveCamera(point, time, height)
    if ac.localPlayer() ~= self then
        return
    end
    if not ac.isPoint(point) then
        return
    end
    if not ac.isNumber(height) then
        height = nil
    end
    local x, y = point:getXY()
    if height then
        jass.PanCameraToTimedWithZ(x, y, height, ac.toNumber(time))
    else
        jass.PanCameraToTimed(x, y, ac.toNumber(time))
    end
end

local CameraField = {
    ['距离'] = 0,
    ['远景截断'] = 1,
    ['X轴旋转'] = 2,
    ['镜头区域'] = 3,
    ['Y轴旋转'] = 4,
    ['Z轴旋转'] = 5,
    ['高度'] = 6,
}

function mt:setCamera(state, value, time)
    if ac.localPlayer() ~= self then
        return
    end
    local field = CameraField[state]
    if not field then
        return
    end
    if not ac.isNumber(value) then
        return
    end
    jass.SetCameraField(field, value, ac.toNumber(time))
end

function mt:addCamera(state, value, time)
    if ac.localPlayer() ~= self then
        return
    end
    local field = CameraField[state]
    if not field then
        return
    end
    if not ac.isNumber(value) then
        return
    end
    jass.AdjustCameraField(field, value, ac.toNumber(time))
end

function mt:resetCamera(time)
    if ac.localPlayer() ~= self then
        return
    end
    jass.ResetToGameCamera(ac.toNumber(time))
end

function mt:controller()
    local state = jass.GetPlayerController(self._handle)
    if state == 0 then
        return '用户'
    elseif state == 1 then
        return '电脑'
    elseif state == 2 then
        return '可营救'
    elseif state == 3 then
        return '中立'
    elseif state == 4 then
        return '野怪'
    elseif state == 5 then
        return '空位'
    else
        return '未知'
    end
end

function mt:gameState()
    local state = jass.GetPlayerSlotState(self._handle)
    if state == 0 then
        return '空位'
    elseif state == 1 then
        return '在线'
    elseif state == 2 then
        return '离线'
    else
        return '未知'
    end
end

function mt:timerDialog(...)
    return timerDialog(self, ...)
end

function mt:board(...)
    return board(...)
end

function mt:id()
    return self._id
end

function mt:name(name)
    if ac.isString(name) then
        jass.SetPlayerName(self._handle, name)
    else
        return jass.GetPlayerName(self._handle)
    end
end

function mt:originName()
	return self._originName
end

function mt:alliance(dest, tp, flag)
    if not ac.isPlayer(dest) then
        log.error('必须是玩家')
        return nil
    end
    if tp == '结盟' then
        tp = 0
    elseif tp == '请求' then
        tp = 1
    elseif tp == '回应' then
        tp = 2
    elseif tp == '经验' then
        tp = 3
    elseif tp == '技能' then
        tp = 4
    elseif tp == '视野' then
        tp = 5
    elseif tp == '控制' then
        tp = 6
    elseif tp == '高级控制' then
        tp = 7
    elseif tp == '救援' then
        tp = 8
    elseif tp == '队伍视野' then
        tp = 9
    else
        log.error('结盟类型不正确')
        return nil
    end
    if ac.isBoolean(flag) then
        jass.SetPlayerAlliance(self._handle, dest._handle, tp, flag)
    else
        return jass.GetPlayerAlliance(self._handle, dest._handle, tp)
    end
end

function mt:isEnemy(other)
    if ac.isPlayer(other) then
        return jass.IsPlayerEnemy(self._handle, other._handle)
    elseif ac.isUnit(other) then
        return jass.IsPlayerEnemy(self._handle, other._owner._handle)
    end
    return false
end

function mt:isAlly(other)
    if ac.isPlayer(other) then
        return jass.IsPlayerAlly(self._handle, other._handle)
    elseif ac.isUnit(other) then
        return jass.IsPlayerAlly(self._handle, other._owner._handle)
    end
    return false
end

function mt:isVisible(other)
    if ac.isUnit(other) then
        return jass.IsUnitVisible(other._handle, self._handle)
    else
        return false
    end
end

function mt:set(k, v)
    if not self._attribute then
        return
    end
    self._attribute:set(k, v)
end

function mt:get(k)
    if not self._attribute then
        return 0.0
    end
    return self._attribute:get(k)
end

function mt:add(k, v)
    if not self._attribute then
        return
    end
    return self._attribute:add(k, v)
end

function ac.eachPlayer()
    local i = 0
    return function ()
        i = i + 1
        return ac.player(i)
    end
end

function ac.player(id)
    if not All then
        init()
    end
    return All[id]
end

function ac.localPlayer()
    if not LocalPlayer then
        LocalPlayer = ac.player(jass.GetLocalPlayer())
    end
    return LocalPlayer
end

function mt:remove(typeName,message)
	if self._isRemove then
		return
	end
	local index
	if typeName == '胜利' then
		index = 0
	elseif typeName == '失败' then
		index = 1
	else
		log.error('没有填写移除玩家的原因（胜利/失败）')
		return false
	end
	self:eventNotify('玩家-退出游戏', self,typeName)
	jass.RemovePlayer(self._handle,index)
	self._isRemove = typeName
	if self:controller() ~= '电脑' then
		if message then
			local borad = self:dialog{
			    message,
				{'1', 'X', '退出游戏(X)|r'},
			}
			function borad:onClick()
				jass.EndGame(true)
			end
		end
    end
end

function mt:setFog(index,rect)
	if index == '黑色阴影' then
		index = 1
	elseif index == '战争迷雾' then
		index = 2
	elseif index == '可见' then
		index = 4
	else
		log.error('可见度类型不正确')
		return
	end
	if rect then
		jass.SetFogStateRect(self._handle, index, rect._handle, false)
	else
		log.error('未传入区域')
		return
	end
end

function mt:setFogArea(data)
	local target = data.target
	local area = data.area
	local rect = data.rect
	if (target and area and area > 0) or rect then
		local list = 
		{
			['阴影'] = 1,
			['迷雾'] = 2,
			['可见'] = 4,
		}
		local type = data.type or '可见'
		local handle
		if rect then
			handle = jass.CreateFogModifierRect(self._handle,list[type],rect._handle,true,false)
		else
			local x,y = data.target:getXY()
			local p = jass.Location(x,y)
			handle = jass.CreateFogModifierRadiusLoc(self._handle,list[type],p,area,true,false)
			jass.RemoveLocation(p)
		end
		local mt = {}
		function mt:remove()
			if not mt._isRemove then
				mt._isRemove = true
				jass.DestroyFogModifier(handle)
			end
		end
		function mt:enable()
			if not mt._isRemove then
				jass.FogModifierStart(handle)
			end
		end
		function mt:disable()
			if not mt._isRemove then
				jass.FogModifierStop(handle)
			end
		end
		mt:enable()
		local time = data.time
		if time then
			ac.wait(time,function()
				mt:remove()
			end)
		end
		return mt
	end
end

local KEYBORD = require 'ac.war3.hotkey'

function mt:setHotKey(slot,hotkey)
	local config = self._hotkey
	if not hotkey then
		config[slot] = nil
		return
	end
	if slot < 1 or slot > 12 then
		log.error('技能槽位不合法')
		return
	end
	if not KEYBORD[hotkey] then
		log.error('技能热键不合法')
		return
	end	
	if config[slot] ~= KEYBORD[hotkey] then
		if ac.isInTable(config,hotkey) == true then
			log.error('技能热键已被占用')
			return
		else
			config[slot] = KEYBORD[hotkey]
		end
	end
end