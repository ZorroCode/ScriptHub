local FeatureManager = {}
FeatureManager.__index = FeatureManager

function FeatureManager.new(logger)
    local self = setmetatable({}, FeatureManager)

    self.Logger = logger
    self.Definitions = {}
    self.Active = {}

    return self
end

function FeatureManager:Register(name, definition)
    if type(name) ~= "string" or name == "" then
        error("[FeatureManager] Feature name must be a non-empty string.")
    end

    if type(definition) ~= "table" then
        error(string.format("[FeatureManager] Definition for '%s' must be a table.", tostring(name)))
    end

    self.Definitions[name] = definition
end

function FeatureManager:GetDefinition(name)
    return self.Definitions[name]
end

function FeatureManager:GetDefinitions()
    local copy = {}

    for key, value in pairs(self.Definitions) do
        copy[key] = value
    end

    return copy
end

function FeatureManager:_safeCall(name, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        if self.Logger then
            self.Logger:Warn(string.format("Feature '%s' failed: %s", tostring(name), tostring(result)))
        end
        return false, result
    end

    return true, result
end

function FeatureManager:_destroyStored(name)
    local stored = self.Active[name]
    self.Active[name] = nil

    if stored == nil then
        return
    end

    if type(stored) == "function" then
        pcall(stored)
        return
    end

    if typeof(stored) == "RBXScriptConnection" then
        pcall(function()
            stored:Disconnect()
        end)
        return
    end

    if type(stored) == "table" and type(stored.Destroy) == "function" then
        pcall(function()
            stored:Destroy()
        end)
        return
    end

    if type(stored) == "table" and type(stored.Disconnect) == "function" then
        pcall(function()
            stored:Disconnect()
        end)
    end
end

function FeatureManager:IsEnabled(name)
    local definition = self.Definitions[name]
    if not definition then
        return false
    end

    if type(definition.Enabled) == "function" then
        local ok, result = pcall(definition.Enabled)
        return ok and result == true
    end

    return definition.Enabled == true
end

function FeatureManager:Refresh(name)
    local definition = self.Definitions[name]
    if not definition then
        if self.Logger then
            self.Logger:Warn("Unknown feature refresh requested: " .. tostring(name))
        end
        return
    end

    if not self:IsEnabled(name) then
        self:Destroy(name)
        return
    end

    if type(definition.Refresh) == "function" then
        local ok, result = self:_safeCall(name, definition.Refresh, self.Active[name])

        if ok and result ~= nil then
            self.Active[name] = result
        end
    end
end

function FeatureManager:RefreshAll()
    for name in pairs(self.Definitions) do
        self:Refresh(name)
    end
end

function FeatureManager:Destroy(name)
    local definition = self.Definitions[name]

    if definition and type(definition.Destroy) == "function" then
        self:_safeCall(name, definition.Destroy, self.Active[name])
    end

    self:_destroyStored(name)
end

function FeatureManager:DestroyAll()
    for name in pairs(self.Definitions) do
        self:Destroy(name)
    end
end

return FeatureManager