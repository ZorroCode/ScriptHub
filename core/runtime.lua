local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(runService)
    local self = setmetatable({}, Runtime)

    self.RunService = runService or game:GetService("RunService")
    self._connections = {}

    return self
end

function Runtime:Every(interval, callback)
    local elapsed = 0

    local connection
    connection = self.RunService.Heartbeat:Connect(function(dt)
        elapsed += dt

        if elapsed < interval then
            return
        end

        elapsed = 0
        callback(dt)
    end)

    table.insert(self._connections, connection)
    return connection
end

function Runtime:Bind(event, callback)
    local connection = event:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Runtime:StopAll()
    for i = #self._connections, 1, -1 do
        local connection = self._connections[i]
        self._connections[i] = nil

        pcall(function()
            connection:Disconnect()
        end)
    end
end

return Runtime