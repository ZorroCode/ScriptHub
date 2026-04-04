local Config = {}

Config.WindowTitle = "Game Template"
Config.WindowToggleKey = Enum.KeyCode.RightAlt

Config.TabName = "Main"
Config.TabIcon = "rbxassetid://0"
Config.TabHeaderTitle = "Main"
Config.TabHeaderSubtitle = "Template game module"

Config.UpdateInterval = 0.10
Config.DefaultESPKeybind = Enum.KeyCode.X

function Config.CreateSettings()
    return {
        Example = {
            Enabled = false,
            Features = {},
        },
    }
end

return Config