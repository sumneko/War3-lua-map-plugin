-- 抛物线构造器
--  起点高度
--  中点高度
--  终点高度

return function (start, middle, finish)
    local a =  2 * start - 4 * middle + 2 * finish
    local b = -3 * start + 4 * middle -     finish
    local c =      start

    return function (n)
        return a * n * n + b * n + c
    end
end
