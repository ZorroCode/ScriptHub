local Config = {}

Config.WindowTitle = "VANTA Hub"
Config.WindowToggleKey = Enum.KeyCode.RightAlt

Config.TabName = "Overview"
Config.TabIcon = "rbxassetid://0"
Config.TabHeaderTitle = "Bite By Night"
Config.TabHeaderSubtitle = "Recon / ESP / runtime controls"

Config.UpdateInterval = 0.10
Config.DefaultESPKeybind = Enum.KeyCode.X
Config.DefaultTheme = "Vanta"

Config.Colors = {
    Player = Color3.fromRGB(0, 255, 170),
    Killer = Color3.fromRGB(255, 84, 122),
    Generator = Color3.fromRGB(0, 204, 255),
    Battery = Color3.fromRGB(255, 215, 92),
    Fuse = Color3.fromRGB(255, 152, 69),
    Trap = Color3.fromRGB(182, 112, 255),
}

Config.FeatureOptions = {
    Player = { "NameTag", "Health", "Stamina", "Distance", "Highlight" },
    Killer = { "NameTag", "Health", "Stamina", "Distance", "Highlight" },
    Generator = { "Distance", "Highlight", "Progress Tracker" },
    Battery = { "Distance", "Highlight" },
    Fuse = { "Distance", "Highlight" },
    Trap = { "Distance", "Highlight" },
}

Config.DefaultFeatures = {
    Player = { "NameTag", "Health", "Highlight", "Distance" },
    Killer = { "NameTag", "Highlight", "Distance" },
    Generator = { "Highlight", "Progress Tracker", "Distance" },
    Battery = { "Highlight", "Distance" },
    Fuse = { "Highlight", "Distance" },
    Trap = { "Highlight", "Distance" },
}

local function cloneArray(list)
    local out = {}
    for i, value in ipairs(list or {}) do
        out[i] = value
    end
    return out
end

function Config.CreateSettings()
    return {
        Theme = Config.DefaultTheme,
        AutoRefresh = true,
        Notifications = true,
        CompactMode = false,
        Player = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Player),
        },
        Killer = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Killer),
        },
        Generator = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Generator),
        },
        Battery = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Battery),
        },
        Fuse = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Fuse),
        },
        Trap = {
            Enabled = false,
            Features = cloneArray(Config.DefaultFeatures.Trap),
        },
    }
end

return Config
