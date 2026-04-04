local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)

    self._data = {}
    self._defaults = {}

    return self
end

function State:SetDefault(key, value)
    if self._data[key] == nil then
        self._data[key] = value
    end

    self._defaults[key] = value
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
    self._data = {}

    for key, value in pairs(self._defaults) do
        self._data[key] = value
    end
end

function State:GetAll()
    local copy = {}

    for key, value in pairs(self._data) do
        copy[key] = value
    end

    return copy
end

return State