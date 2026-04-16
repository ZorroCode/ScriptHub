local Config = {}

Config.WindowTitle = "Atlas Template"
Config.WindowToggleKey = Enum.KeyCode.RightAlt

Config.TabName = "Main"
Config.TabIcon = "rbxassetid://0"
Config.TabHeaderTitle = "Atlas"
Config.TabHeaderSubtitle = "Template game module"

Config.UpdateInterval = 0.10

function Config.CreateSettings()
    return {
        Diagnostics = {
            Enabled = false,
        },
        Actions = {
            Enabled = false,
        },
    }
end

function Config.GetFeatureList()
    return {
        {
            Key = "Diagnostics",
            Title = "Diagnostics",
            Description = "General diagnostic feature group",
        },
        {
            Key = "Actions",
            Title = "Actions",
            Description = "General action feature group",
        },
    }
end

return Config