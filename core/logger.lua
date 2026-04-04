local Logger = {}
Logger.__index = Logger

function Logger.new(scope)
    local self = setmetatable({}, Logger)
    self.Scope = scope or "ScriptHub"
    self.Enabled = true
    return self
end

function Logger:SetEnabled(enabled)
    self.Enabled = not not enabled
end

function Logger:_format(level, message)
    return string.format("[%s][%s] %s", self.Scope, level, tostring(message))
end

function Logger:Info(message)
    if self.Enabled then
        print(self:_format("INFO", message))
    end
end

function Logger:Warn(message)
    if self.Enabled then
        warn(self:_format("WARN", message))
    end
end

function Logger:Error(message)
    error(self:_format("ERROR", message))
end

return Logger