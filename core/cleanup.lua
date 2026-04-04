local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new()
    local self = setmetatable({}, Cleanup)
    self._tasks = {}
    return self
end

function Cleanup:Add(task)
    if task == nil then
        return nil
    end

    table.insert(self._tasks, task)
    return task
end

function Cleanup:Run()
    for i = #self._tasks, 1, -1 do
        local taskItem = self._tasks[i]
        self._tasks[i] = nil

        pcall(function()
            if type(taskItem) == "function" then
                taskItem()
            elseif typeof(taskItem) == "RBXScriptConnection" then
                taskItem:Disconnect()
            elseif type(taskItem) == "table" and type(taskItem.Destroy) == "function" then
                taskItem:Destroy()
            elseif type(taskItem) == "table" and type(taskItem.Disconnect) == "function" then
                taskItem:Disconnect()
            end
        end)
    end
end

return Cleanup