local Config = {}
Config.__index = Config

function Config.new(defaults)
    local self = setmetatable({}, Config)

    self._defaults = defaults or {}
    self._values = {}

    for key, value in pairs(self._defaults) do
        self._values[key] = value
    end

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
    self._values[key] = self._defaults[key]
end

function Config:ResetAll()
    self._values = {}

    for key, value in pairs(self._defaults) do
        self._values[key] = value
    end
end

function Config:GetAll()
    local out = {}

    for key, value in pairs(self._values) do
        out[key] = value
    end

    return out
end

return Config