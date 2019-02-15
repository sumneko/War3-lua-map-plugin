local mt = {}

mt.info = {
    name = '预设数据',
    version = 1.3,
    author = '最萌小汐',
    description = '将物编数据设置为标准值。'
}

local function deepCopy(t)
    local new = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            new[k] = deepCopy(v)
        else
            new[k] = v
        end
    end
    return new
end

local function newObject(slk, id, parent, level)
    return function (data)
        local new = deepCopy(slk[parent])
        new._parent = parent
        new._id = id
        new._obj = true

        for k, v in pairs(data) do
            new[k:lower()] = v
        end

        if level then
            for _, v in pairs(new) do
                if type(v) == 'table' then
                    if #v > level then
                        for i = level + 1, #v do
                            v[i] = nil
                        end
                    elseif #v < level then
                        for i = #v + 1, level do
                            v[i] = v[#v]
                        end
                    end
                end
            end
        end

        slk[id] = new
    end
end

local function insertUnit(w2l)
    newObject(w2l.slk.unit, '@DMY', 'ewsp') {
        -- 可建造建筑
        Builds = "",
        -- 名字
        Name = "通用马甲",
        -- 特殊效果
        Specialart = "",
        -- 普通
        abilList = "Aloc,Arav",
        -- 可以逃跑
        canFlee = 0,
        -- 动画 - 魔法施放回复
        castbsw = 0.0000,
        -- 碰撞体积
        collision = 0.0000,
        -- 死亡时间(秒)
        death = 10.0000,
        -- 防御升级奖励
        defUp = 0.0000,
        -- 高度变化 - 采样范围
        elevRad = 0.0000,
        -- 模型文件
        file = "model\\dummy-common.mdl",
        -- 占用人口
        fused = 0,
        -- 隐藏小地图显示
        hideOnMinimap = 1,
        -- 射弹碰撞偏移 - Z
        impactZ = 0.0000,
        -- X轴最大旋转角度(弧度)
        maxPitch = 0.0000,
        -- Y轴最大旋转角度(弧度)
        maxRoll = 0.0000,
        -- 类型
        movetp = "",
        -- 视野范围(夜晚)
        nsight = 0,
        -- 生命回复
        regenHP = 0.0000,
        -- 生命回复类型
        regenType = "",
        -- 视野范围(白天)
        sight = 0,
        -- 转身速度
        turnRate = 3.0000,
        -- 单位类别
        type = "ward",
        -- 使用科技
        upgrades = "",
    }

    newObject(w2l.slk.unit, '@MVR', 'ewsp') {
        -- 可建造建筑
        Builds = "",
        -- 名字
        Name = "通用马甲",
        -- 特殊效果
        Specialart = "",
        -- 普通
        abilList = "Aloc,Arav",
        -- 可以逃跑
        canFlee = 0,
        -- 动画 - 魔法施放回复
        castbsw = 0.0000,
        -- 碰撞体积
        collision = 0.0000,
        -- 死亡时间(秒)
        death = 10.0000,
        -- 防御升级奖励
        defUp = 0.0000,
        -- 高度变化 - 采样范围
        elevRad = 0.0000,
        -- 模型文件
        file = "model\\dummy-mover.mdl",
        -- 占用人口
        fused = 0,
        -- 隐藏小地图显示
        hideOnMinimap = 1,
        -- 射弹碰撞偏移 - Z
        impactZ = 0.0000,
        -- X轴最大旋转角度(弧度)
        maxPitch = 0.0000,
        -- Y轴最大旋转角度(弧度)
        maxRoll = 0.0000,
        -- 类型
        movetp = "",
        -- 视野范围(夜晚)
        nsight = 0,
        -- 生命回复
        regenHP = 0.0000,
        -- 生命回复类型
        regenType = "",
        -- 视野范围(白天)
        sight = 0,
        -- 转身速度
        turnRate = 3.0000,
        -- 单位类别
        type = "ward",
        -- 使用科技
        upgrades = "",
    }
end

local function idCreator(head)
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local index = -1
    return function ()
        index = index + 1
        local c3 = index % #chars + 1
        local c2 = index // #chars % #chars + 1
        local c1 = index // #chars // #chars % #chars + 1
        return head .. chars:sub(c1, c1) .. chars:sub(c2, c2) .. chars:sub(c3, c3)
    end
end

local function insertAbility(w2l)
    newObject(w2l.slk.ability, '@CMD', 'ANcl', 2) {
        -- 效果 - 施法动作
        Animnames = "",
        -- 按钮位置 - 普通 (X)
        Buttonpos_1 = 0,
        -- 效果 - 施法者
        CasterArt = "",
        -- 施法持续时间
        DataA = {0.0000, 0.0000},
        -- 目标类型
        DataB = {3, 3},
        -- 选项
        DataC = {1, 1},
        -- 动作持续时间
        DataD = {0.0000, 0.0000},
        -- 使其他技能无效
        DataE = {0, 0},
        -- 基础命令ID
        DataF = {
        "robogoblin",
        "robogoblin",
        },
        -- 效果 - 目标点
        EffectArt = "",
        -- 名字
        Name = "CMD",
        -- 施法距离
        Rng = {0.0000, 0.0000},
        -- 效果 - 目标
        TargetArt = "",
        -- 效果 - 目标附加点1
        Targetattach = "",
        -- 英雄技能
        hero = 0,
        -- 等级
        levels = 2,
    }
    newObject(w2l.slk.ability, '@PRT', 'ANcl') {
        -- 效果 - 施法动作
        Animnames = "",
        -- 效果 - 施法者
        CasterArt = "",
        -- 施法持续时间
        DataA = {0.0000},
        -- 目标类型
        DataB = {2},
        -- 动作持续时间
        DataD = {0.0000},
        -- 使其他技能无效
        DataE = {0},
        -- 基础命令ID
        DataF = {"channel"},
        -- 效果 - 目标点
        EffectArt = "",
        -- 名字
        Name = "CMD",
        -- 施法距离
        Rng = {999999},
        -- 效果 - 目标
        TargetArt = "",
        -- 效果 - 目标附加点1
        Targetattach = "",
        -- 英雄技能
        hero = 0,
        -- 等级
        levels = 1,
    }
    newObject(w2l.slk.ability, '@SLC', 'Ane2') {
        DataA = {999999},
        DataB = {4},
    }

    -- 通魔使用的命令字符串（共需要12个）
    local orderList = {
        'incineratearrowoff',
        'incineratearrowon',
        'incineratearrow',
        'volcano',
        'soulburn',
        'lavamonster',
        'transmute',
        'healingspray',
        'chemicalrage',
        'acidbomb',
        'summonfactory',
        'unrobogoblin',
    }

    -- 分配ID
    local nextId = idCreator '$'

    -- 为每个格子分配100个技能，共1200个
    local SIZE = 100
    local i = 0
    local slot = 0
    for y = 2, 0, -1 do
        for x = 0, 3 do
            slot = slot + 1
            for _ = 1, SIZE do
                i = i + 1
                local order = orderList[slot]
                newObject(w2l.slk.ability, nextId(), 'ANcl', 2) {
                    Name = '@主动技能-' .. tostring(slot),
                    Buttonpos_1 = x,
                    Buttonpos_2 = y,
                    UnButtonpos_1 = x,
                    UnButtonpos_2 = y,
                    Researchbuttonpos_1 = x,
                    Researchbuttonpos_2 = y,
                    EffectArt = '',
                    TargetArt = '',
                    Targetattach = '',
                    Animnames = '',
                    CasterArt = '',
                    hero = 0,
                    levels = 2,
                    DataA = {0, 0},
                    DataB = {0, 0},
                    DataC = {1, 1},
                    DataD = {0, 0},
                    DataE = {0, 0},
                    DataF = {order, order},
                    Rng = {0, 0},
                }

                newObject(w2l.slk.ability, nextId(), 'Amgl') {
                    Name = '@被动技能-' .. tostring(slot),
                    Buttonpos_1 = x,
                    Buttonpos_2 = y,
                    UnButtonpos_1 = x,
                    UnButtonpos_2 = y,
                    Researchbuttonpos_1 = x,
                    Researchbuttonpos_2 = y,
                    Requires = '',
                }
            end
        end
    end
end

local function insertItem(w2l)
    newObject(w2l.slk.item, '@CHE', 'ches') {}
    local nextId = idCreator '%'
    for i = 1, 300 do
        local abilityId = nextId()
        newObject(w2l.slk.ability, abilityId, 'ANcl', 2) {
            Name = '物品技能-' .. tostring(i),
            EffectArt = '',
            TargetArt = '',
            Targetattach = '',
            Animnames = '',
            CasterArt = '',
            hero = 0,
            levels = 2,
            DataA = {0, 0},
            DataB = {3, 3},
            DataC = {1, 1},
            DataD = {0, 0},
            DataE = {0, 0},
            Rng = {0, 0},
        }
        newObject(w2l.slk.item, nextId(), 'ches') {
            Name = '@物品-' .. tostring(i),
            usable = 1,
            abilList = abilityId,
        }
    end

    for i = 1, 1000 do
        newObject(w2l.slk.item, nextId(), 'ches') {
            Name = '@神符-' .. tostring(i),
            powerup = 1,
        }
    end
end

local function defaultUnit(w2l)
    -- 设置所有单位的默认数据
    for _, unit in pairs(w2l.slk.unit) do
        -- 生命回复类型
        unit.regentype = 'none'
        -- 魔法回复
        unit.regenmana = 0
        -- 武器类型
        unit.weaptp1 = 'instant'
        -- 攻击骰子数量
        unit.dice1 = 1
        -- 攻击骰子面数
        unit.sides1 = 1
        -- 魔法施放点
        unit.castpt = 0
        -- 魔法施放回复
        unit.castbsw = 0
        -- 投射物
        unit.missileart_1 = ''
    end
end

local function defaultMisc(w2l)
    -- 英雄属性 - 每点敏捷攻击速度奖励
    w2l.slk.misc.Misc.agiattackspeedbonus = 0.0000
    -- 英雄属性 -基础防御补正
    w2l.slk.misc.Misc.agidefensebase = 0.0000
    -- 英雄属性 - 每点敏捷防御奖励
    w2l.slk.misc.Misc.agidefensebonus = 0.0000
    -- 英雄属性 - 每点智力魔法值奖励
    w2l.slk.misc.Misc.intmanabonus = 0.0000
    -- 英雄属性 - 每点智力魔法回复奖励
    w2l.slk.misc.Misc.intregenbonus = 0.0000
    -- 英雄属性 - 每点主属性攻击奖励
    w2l.slk.misc.Misc.strattackbonus = 0.0000
    -- 英雄属性 - 每点力量生命值奖励
    w2l.slk.misc.Misc.strhitpointbonus = 0.0000
    -- 英雄属性 - 每点力量生命回复奖励
    w2l.slk.misc.Misc.strregenbonus = 0.0000
    -- 战斗 - 伤害奖励列表 - 混乱
    w2l.slk.misc.Misc.damagebonuschaos = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 英雄
    w2l.slk.misc.Misc.damagebonushero = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 魔法
    w2l.slk.misc.Misc.damagebonusmagic = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 普通
    w2l.slk.misc.Misc.damagebonusnormal = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 穿刺
    w2l.slk.misc.Misc.damagebonuspierce = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 攻城
    w2l.slk.misc.Misc.damagebonussiege = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
    -- 战斗 - 伤害奖励列表 - 法术
    w2l.slk.misc.Misc.damagebonusspells = "0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00"
end

local function isOpenByYDWE(w2l)
    if w2l.input_mode ~= 'lni' then
        return false
    end
    if w2l.setting.mode ~= 'obj' then
        return false
    end
    for _, plugin in ipairs(w2l.plugins) do
        if plugin.info.name == '日志路径' then
            return true
        end
    end
    return false
end

function mt:on_full(w2l)
    -- TODO 如果是YDWE打开lni地图，则不执行以下代码
    if isOpenByYDWE(w2l) then
        return
    end
    if w2l.setting.mode == 'lni' then
        return
    end

    insertUnit(w2l)
    insertAbility(w2l)
    insertItem(w2l)

    defaultUnit(w2l)
    defaultMisc(w2l)
end

return mt
