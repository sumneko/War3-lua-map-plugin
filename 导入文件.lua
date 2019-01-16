local mt = {}

mt.info = {
    name = '导入文件',
    version = 1.0,
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

function mt:on_convert(w2l)
    -- TODO 如果是YDWE打开lni地图，则不执行以下代码
    if w2l.setting.mode == 'obj' and w2l.log_path:filename():string() == 'w3x2lni' then
        return
    end
    if w2l.setting.mode == 'lni' then
        return
    end
    if w2l.input_mode ~= 'lni' then
        return
    end

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
                w2l.output_ar:set(newName, buf)
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

return mt
