local Config = {}
Config.__index = Config

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

function Config.new(defaults)
    local self = setmetatable({}, Config)

    self._defaults = deepCopy(defaults or {})
    self._values = deepCopy(self._defaults)

    return self
end

function Config:Get(key, fallback)
    local value = self._values[key]

    if value == nil then
        return fallback
    end

    return value
end

function Config:Set(key, value)
    self._values[key] = value
end

function Config:Has(key)
    return self._values[key] ~= nil
end

function Config:Reset(key)
    self._values[key] = deepCopy(self._defaults[key])
end

function Config:ResetAll()
    self._values = deepCopy(self._defaults)
end

function Config:GetAll()
    return deepCopy(self._values)
end

function Config:GetDefaults()
    return deepCopy(self._defaults)
end

return Config