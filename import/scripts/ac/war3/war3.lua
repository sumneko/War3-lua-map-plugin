local jass = require 'jass.common'
local dbg = require 'jass.debug'

local initDamage = require 'ac.war3.damage'

local FRAME = 10

local function startTimer()
    local jTimer = jass.CreateTimer()
    dbg.handle_ref(jTimer)
    jass.TimerStart(jTimer, 0.001 * FRAME, true, function ()
        ac.world.update(FRAME)
    end)
end

local function searchPresetUnits()
    local g = jass.CreateGroup()
    for i = 0, 15 do
        jass.GroupEnumUnitsOfPlayer(g, jass.Player(i), nil)
        while true do
            local u = jass.FirstOfGroup(g)
            if u == 0 then
                break
            end
            jass.GroupRemoveUnit(g, u)
            ac.unit(u)
        end
    end
    jass.DestroyGroup(g)
end

ac.id = setmetatable({}, {__index = function (self, id)
    if type(id) == 'string' then
        self[id] = ('>I4'):unpack(id)
    else
        self[id] = ('>I4'):pack(id)
    end
    return self[id]
end})

local function start()
    -- 根据unit表注册地图上的预设单位
    searchPresetUnits()
    -- 注册任意单位受伤事件
    initDamage()
    -- 启动计时器，开始tick
    startTimer()
end

-- 在1帧后开始游戏逻辑
jass.TimerStart(jass.CreateTimer(), 0.0, false, start)
