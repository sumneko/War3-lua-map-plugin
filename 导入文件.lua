local mt = {}

mt.info = {
    name = '导入文件',
    version = 1.2,
    author = '最萌小汐',
    description = '导入底层需要的文件'
}

local function scanDir(dir, callback)
    for path in dir:list_directory() do
        if fs.is_directory(path) then
            scanDir(path, callback)
        else
            callback(path)
        end
    end
end

local function importFiles(w2l)
    local needInsideLua = w2l.setting.remove_we_only
    local basePath = 'w3x2lni\\plugin\\import\\'
    local list = w2l.input_ar:list_file()
    local files = {}
    for _, name in ipairs(list) do
        if name:sub(1, #basePath):lower() == basePath then
            local buf = w2l.input_ar:get(name)
            w2l.input_ar:remove(name)
            files[name] = buf
            local newName = name:sub(#basePath+1)
            if needInsideLua or newName:sub(1, #'scripts\\') ~= 'scripts\\' then
                if not w2l.input_ar:get(newName) then
                    w2l.output_ar:set(newName, buf)
                end
            end
        end
    end
    for i = #list, 1, -1 do
        local name = list[i]
        if files[name] then
            table.remove(list, i)
        end
    end
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

local function removePlugin(w2l)
    local set = w2l.output_ar.set
    function w2l.output_ar:set(name, buf)
        if name:sub(1, #'w3x2lni\\plugin\\') == 'w3x2lni\\plugin\\' then
            return
        end
        set(self, name, buf)
    end
end

local function preventRemoveFiles(w2l)
    -- 导入一个插件，用于阻止保存地图时删除本地插件，这个插件会自我删除
    w2l:file_save('w3x2lni', 'plugin\\.config', '阻止删除本地插件')
    w2l:file_save('w3x2lni', 'plugin\\阻止删除本地插件.lua', w2l.input_ar:get 'w3x2lni\\plugin\\阻止删除本地插件.lua')
end

function mt:on_convert(w2l)
    if isOpenByYDWE(w2l) then
        preventRemoveFiles(w2l)
        removePlugin(w2l)
        return
    end
    if w2l.setting.mode == 'lni' then
        return
    end

    importFiles(w2l)
end

return mt
