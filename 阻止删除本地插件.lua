local mt = {}

mt.info = {
    name = '阻止删除本地插件',
    version = 1.0,
    author = '最萌小汐',
    description = '地图保存为lni时，不删除本地插件'
}

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
    local fsRemove = fs.remove
    local len = #w2l.setting.output:string()
    function fs.remove(path)
        local name = path:string():sub(len+2):gsub('/', '\\')
        if name:sub(1, #'w3x2lni\\plugin\\'):lower() == 'w3x2lni\\plugin\\' then
            return
        end
        fsRemove(path)
    end
end

function mt:on_convert(w2l)
    if w2l.setting.mode ~= 'lni' then
        return
    end

    removePlugin(w2l)
    preventRemoveFiles(w2l)
end

return mt
