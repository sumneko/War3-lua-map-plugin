local mt = {}

mt.info = {
    name = '预置对象',
    version = 1.0,
    author = '最萌小汐',
    description = '读取地图中的预置对象。',
}

local function parseW3r(buf)
    local count = ('L'):unpack(buf, 5)
    local rects = {}
    local pos = 9
    for i = 1, count do
        rects[i] = {}
        rects[i].minx,   pos = ('f') :unpack(buf, pos)
        rects[i].miny,   pos = ('f') :unpack(buf, pos)
        rects[i].maxx,   pos = ('f') :unpack(buf, pos)
        rects[i].maxy,   pos = ('f') :unpack(buf, pos)
        rects[i].name,   pos = ('z') :unpack(buf, pos)
        rects[i].index,  pos = ('L') :unpack(buf, pos)
        rects[i].weather,pos = ('c4'):unpack(buf, pos)
        rects[i].sound,  pos = ('z') :unpack(buf, pos)
        rects[i].color,  pos = ('c3'):unpack(buf, pos)
        pos = pos + 1
    end
    return rects
end

local function convertLua(data)
    local lines = {}
    lines[#lines+1] = 'local rects = {}'
    for i, rect in ipairs(data) do
        lines[#lines+1] = ('rects[%d] = { %.4f, %.4f, %.4f, %.4f, %q }'):format(i, rect.minx, rect.miny, rect.maxx, rect.maxy, rect.name)
    end
    lines[#lines+1] = 'return rects'
    lines[#lines+1] = ''
    return table.concat(lines, '\r\n')
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

function mt:on_convert(w2l)
    if isOpenByYDWE(w2l) then
        return
    end
    if w2l.setting.mode == 'lni' then
        return
    end
    local w3r = w2l:file_load('map', 'war3map.w3r')
    if not w3r then
        w2l:file_save('scripts', 'ac\\rect\\w3r.lua', '')
        return
    end
    local data = parseW3r(w3r)
    local lua = convertLua(data)
    w2l:file_save('scripts', 'ac\\rect\\w3r.lua', lua)
end

return mt
