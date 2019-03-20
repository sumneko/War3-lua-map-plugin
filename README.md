# War3-lua-map-plugin

将插件放在地图内`w3x2lni`目录内即可使用。
脚本的搜索范围为`scripts`目录，入口为`main.lua`。
表的搜索范围为`scripts\table`目录。

## 实现原理

`W3x2lni`转换地图时会加载地图内`w3x2lni`目录中的插件，此项目作为一个插件，会在转换地图时修改地图中的物编并导入基础lua脚本与一些特殊的美术资源。

## API接口

见`import\scripts\ac\doc`目录。