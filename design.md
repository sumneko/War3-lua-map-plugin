# 设计思路

## 目标

这套lua框架的主要目标是实现通用性，让地图作者从繁重的物编马甲与特殊处理中解放出来。

## 框架

这套框架会接管所有与War3和jass的交互，理论上业务层只需要和脚本交互：

```
    地图代码（lua）
        ↓↑
    Lua框架（lua）
    ↓↑      ↓↑
  魔兽争霸 ←→ jass
```

为此，框架会将所有的jass封装为高级对象，例如创建然后杀死单位：

```jass
local unit u = CreateUnit(player, unitid, x, y, face)
KillUnit(u)
```

```lua
local u = player:createUnit(unitname, point, face)
u:kill(u)
```

状态尽可能保存在Lua中而不是魔兽中，例如：

```lua
u:set('力量', 999999999999)
u:get('力量') --> 999999999999
```

此时魔兽中看到的力量为`2147483647`，这是因为实际值已经超过了魔兽数字表达的上限，魔兽中的数字仅做显示用。

得益于强大的lua，很多功能拥有更好的解决方案。点、计时器、触发器已经完全通过Lua实现，将作者从排泄、麻烦的动态注册中解放出来。

框架的业务模块关系如下：

```
    game(world) ---------------------------
    ↓      ↓                              |
player   mover                            |
     ↓   ↓                                |
     unit ------------------------------- |
      ↓        ↓     ↓      ↓           ↓ ↓
   attack     buff  shop  skill ←------ item
               ↓           ↓             ↓
            buff-icon  skill-icon   placed-item
```

下面介绍一下这些模块

### game

这是逻辑上的全局环境，管理全局事件、单位与运动的tick等。

### player

与War3的player概念相同。

### unit

与War3的unit概念相同。

### attack

表示单位的攻击方式，可以通过替换单位的该属性来达到修改攻击方式、投射物模型等目的。

### mover

管理弹道或单位的运动（比如单位冲锋）

### buff

管理单位身上的状态。

### buff-icon

用于将身上的状态显示在状态栏中，使用`火焰披风`（War3技能，会给自己添加一个buff图标）技能实现。

### shop

商店，任何玩家都可以在商店中购买道具。

### skill

管理单位的技能，以及施法流程。

### skill-icon

如果技能显示在技能栏中，则使用`通魔`（War3技能）实现。为了做出区分，将用于显示的`通魔`称作`ability`。如果技能显示在物品栏中，则使用`奶酪`（War3物品）实现。

### item

管理物品，当单位获得物品时，表现为`skill`。当物品放置在地上时，表现为`placed-item`。

### placed-item

放在地上的物品，使用`奶酪`（War3物品）实现。

## 插件

为了尽可能兼容地图，减少对地图的定制，插件实现了许多功能。插件会在使用`w3x2lni`转换地图时执行，开发时通过点击VSCode状态栏的`Obj`与`Slk`来转换地图。

### lua引擎

向脚本中插入代码，使得地图会执行lua脚本。如果转为`Obj`格式，还会告诉Lua开发目录的路径，以便加载本地脚本。

### 导入文件

将整个框架代码导入到地图中。还会导入一些框架使用的资源，例如自动合成被动图标时使用的遮罩图标。

### 引用声明

避免`Slk`优化时将物编中的对象移除（因为优化时会根据静态引用分析找出没有用到的对象，但是写在Lua脚本中的对象无法正确分析出来）。

### 预置对象

将预置在地图上的矩形区域信息导入到框架中，以便业务层直接使用。

### 预设数据

标准化物编数据（例如将攻击护甲比例全部置为0、设置所有单位的基础攻击力为1等）。添加框架要用到的各种物编模板（比如`buff`用到的`火焰风衣`，`skill-icon`用到的`通魔`等）。

## 交互

Lua与War3、Lua与jass之间的交互有一些注意点，这里依次说明：

### jass -> lua

本框架中，仅用于初始化启动lua。在jass中调用特定的API即可加载lua。

### lua -> jass

本框架不会用到。

### lua -> War3

lua中导出了War3的API，通过这些API来操作War3。

```lua
local jass = require 'jass.common'
jass.CreateUnit(jass.Player(0), name, x, y, 0) --> integer, 单位的句柄id
```

注意！由于魔兽的同步机制要求，必须小心注意异步的情况。由于Lua遍历哈希表的顺序是随机的，目前的Lua引擎打了补丁，使得可以按照固定顺序遍历索引为`number`、`string`、`boolean`的哈希表（并不是插入顺序），但是依然无法按照固定顺序遍历索引为`table`的哈希表，下面是错误的代码：

```lua
local t = {}

for i = 1, 10 do
    local u = player:createUnit(name, point, face)
    t[u] = true
end

for u in pairs(t) do
    u:kill(u)
end
```

这段代码会导致不同玩家杀死单位的顺序不一致从而导致掉线。

此外，虽然可以按照固定顺序遍历索引为`number`的表，但是由于War3中一个对象（如单位）的handle本身就是不同步的，因此这样写也是错误的：

```lua
local t = {}

for i = 1, 10 do
    local handle = jass.CreateUnit(player, unitid, x, y, face)
    t[handle] = true
end

for handle in pairs(t) do
    jass.KillUnit(handle)
end
```

还有容易忽视的一点，随机数也必须要同步，因此这样写是错误的：

```lua
if ac.localPlayer() == ac.player(1) then
    math.random(1, 100)
end
unit:set('生命', math.random(1, 100))
```

### War3 -> lua

War3到lua是通过API的回调函数于事件实现的。由于实现的原因，每次在lua中注册回调或事件都会产生永久泄漏：

```lua
local t = jass.CreateTimer()
for i = 1, 100 do
    jass.TimerStart(t, i, false, function ()
        print('time up', i)
    end)
end
```

上面这段代码会创建100个泄漏。正确的做法是，只创建一次回调，然后由Lua自己分发事件。框架提供的计时器、事件、区域等功能都是基于这一原则实现的。
