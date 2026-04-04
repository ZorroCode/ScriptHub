local Services = {}

function Services.Get()
    return {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        Workspace = game:GetService("Workspace"),
        HttpService = game:GetService("HttpService"),
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        CoreGui = game:GetService("CoreGui"),
        Lighting = game:GetService("Lighting"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
    }
end

return Services