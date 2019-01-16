local mt = {}

mt.info = {
    name = 'lua引擎',
    version = 1.1,
    author = '最萌小汐',
    description = '让obj格式的地图使用本地的lua脚本。'
}

local currentpath = [[
package.path = package.path .. ';%s\scripts\?.lua;%s\scripts\?\init.lua;%s\w3x2lni\plugin\import\scripts\?.lua;%s\w3x2lni\plugin\import\scripts\?\init.lua'
]]

local luapath = [[
package.path = package.path .. ';scripts\\?.lua;scripts\\?\\init.lua;w3x2lni\\plugin\\import\\scripts\\?.lua;w3x2lni\\plugin\\import\\scripts\\?\\init.lua'
]]

local function injectJass(w2l, buf)
    if not buf then
        return nil
    end
    local _, pos = buf:find('function main takes nothing returns nothing', 1, true)
    local bufs = {}
    bufs[#bufs+1] = buf:sub(1, pos)
    bufs[#bufs+1] = '//Lua 引擎开始\r\n'
    bufs[#bufs+1] = [===[
        call Cheat("exec-lua:_luapath")
        call Cheat("exec-lua:_currentpath")
        call Cheat("exec-lua:ac")
        call Cheat("exec-lua:main")
    ]===]
    bufs[#bufs+1] = '//Lua 引擎结束'
    bufs[#bufs+1] = buf:sub(pos+1)
    return table.concat(bufs)
end

local function injectFiles(w2l)
    local input = w2l.setting.input:string()
    w2l:file_save('map', '_luapath.lua', luapath)
    w2l:file_save('map', 'scripts\\_currentpath.lua', currentpath:format(input, input, input, input):gsub('\\', '\\\\'))
    local buf = injectJass(w2l, w2l:file_load('map', 'war3map.j'))
    if buf then
        w2l:file_save('map', 'war3map.j', buf)
    end
    local buf = injectJass(w2l, w2l:file_load('map', 'scripts\\war3map.j'))
    if buf then
        w2l:file_save('map', 'scripts\\war3map.j', buf)
    end
end

local function reduceJass(w2l, name)
    local buf = w2l:file_load('map', name)
    if not buf then
        return
    end
    buf = buf:gsub('//Lua 引擎开始.-//Lua 引擎结束', '')
    w2l:file_save('map', name, buf)
end

local function reduceFiles(w2l)
    w2l:file_remove('map', '_luapath.lua')
    w2l:file_remove('map', 'scripts\\_currentpath.lua')
    reduceJass(w2l, 'war3map.j')
    reduceJass(w2l, 'scripts\\war3map.j')
end

function mt:on_full(w2l)
    if w2l.setting.mode == 'lni' then
        reduceFiles(w2l)
    elseif w2l.setting.remove_we_only then
        injectFiles(w2l)
    else
        local file_save = w2l.file_save
        function w2l:file_save(type, name, buf)
            if type == 'scripts' and name ~= 'blizzard.j' and name ~= 'common.j' then
                return
            end
            return file_save(self, type, name, buf)
        end

        if not w2l:file_load('map', 'scripts\\_currentpath.lua') then
            injectFiles(w2l)
        end
    end
end

function mt:on_pack(w2l, output_ar)
    local buf = injectJass(w2l, output_ar:get 'war3map.j')
    if buf then
        output_ar:set('war3map.j', buf)
    end
    local buf = injectJass(w2l, output_ar:get 'scripts\\war3map.j')
    if buf then
        output_ar:set('scripts\\war3map.j', buf)
    end
end

return mt
