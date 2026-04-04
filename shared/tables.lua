local Tables = {}

function Tables.CloneArray(list)
    local out = {}

    for i, value in ipairs(list or {}) do
        out[i] = value
    end

    return out
end

function Tables.ArrayToMap(list)
    local map = {}

    for _, value in ipairs(list or {}) do
        map[value] = true
    end

    return map
end

function Tables.ShallowCopy(tbl)
    local out = {}

    for key, value in pairs(tbl or {}) do
        out[key] = value
    end

    return out
end

function Tables.Merge(base, extra)
    local out = Tables.ShallowCopy(base)

    for key, value in pairs(extra or {}) do
        out[key] = value
    end

    return out
end

return Tables