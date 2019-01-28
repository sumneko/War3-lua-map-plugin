local mt = {}

mt.info = {
    name = 'Read slk',
    version = 1.0,
    author = 'sumneko',
    description = 'Use `slk.ability.Aloc.cost[1]` to read slk data.'
}

local function read_slk(buf, slk)
    local env = setmetatable({
        slk = slk,
    }, {
        __index = _ENV,
    })
    return buf:gsub('%<%?%=(.-)%?%>', function (str)
        local f = load(('return %s'):format(str), str, 't', env)
        if not f then
            return
        end
        local suc, res = pcall(f)
        if not suc then
            return
        end
        return tostring(res)
    end)
end

function mt:on_full(w2l)
    local filename
    if w2l:file_load('map', 'war3map.j') then
        filename = 'war3map.j'
    elseif w2l:file_load('map', 'scripts\\war3map.j') then
        filename = 'scripts\\war3map.j'
    else
        return
    end
    local buf = w2l:file_load('map', filename)
    local new_buf = read_slk(buf, w2l.slk)
    w2l:file_save('map', filename, new_buf)
end

return mt
