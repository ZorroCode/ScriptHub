local Config = {}

Config.WindowTitle = "Bite By Night"
Config.WindowToggleKey = Enum.KeyCode.RightAlt

Config.TabName = "ESP"
Config.TabIcon = "rbxassetid://0"
Config.TabHeaderTitle = "ESP"
Config.TabHeaderSubtitle = "Players, killer, and world objects"

Config.UpdateInterval = 0.10
Config.DefaultESPKeybind = Enum.KeyCode.X

Config.Colors = {
    Player = Color3.fromRGB(0, 255, 0),
    Killer = Color3.fromRGB(255, 0, 0),
    Generator = Color3.fromRGB(0, 170, 255),
    Battery = Color3.fromRGB(255, 255, 0),
    Fuse = Color3.fromRGB(255, 140, 0),
    Trap = Color3.fromRGB(170, 0, 255),
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
    Player = { "NameTag", "Health", "Highlight" },
    Killer = { "NameTag", "Highlight" },
    Generator = { "Highlight", "Progress Tracker" },
    Battery = { "Highlight" },
    Fuse = { "Highlight" },
    Trap = { "Highlight" },
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
