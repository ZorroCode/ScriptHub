local State = {}
State.__index = State

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(child, seen)
    end

    return copy
end

function State.new()
    local self = setmetatable({}, State)

    self._data = {}
    self._defaults = {}

    return self
end

function State:SetDefault(key, value)
    if self._data[key] == nil then
        self._data[key] = deepCopy(value)
    end

    self._defaults[key] = deepCopy(value)
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Get(key, fallback)
    local value = self._data[key]

    if value == nil then
        return fallback
    end

    return value
end

function State:Has(key)
    return self._data[key] ~= nil
end

function State:Remove(key)
    self._data[key] = nil
end

function State:Clear()
    table.clear(self._data)
end

function State:ResetToDefaults()
    self._data = deepCopy(self._defaults)
end

function State:GetAll()
    return deepCopy(self._data)
end

return State