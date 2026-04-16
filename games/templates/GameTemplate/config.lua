local Config = {}

Config.WindowTitle = "VANTA Template"
Config.WindowToggleKey = Enum.KeyCode.RightAlt

Config.TabName = "Main"
Config.TabIcon = "rbxassetid://0"
Config.TabHeaderTitle = "VANTA"
Config.TabHeaderSubtitle = "Template game module"

Config.UpdateInterval = 0.10
Config.DefaultTheme = "Vanta"

function Config.CreateSettings()
    return {
        Theme = Config.DefaultTheme,
        AutoRefresh = true,
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