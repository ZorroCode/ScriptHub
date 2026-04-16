local Theme = {}

Theme.Presets = {
    Obsidian = {
        Name = "Obsidian",
        Background = Color3.fromRGB(8, 10, 14),
        Surface = Color3.fromRGB(13, 16, 23),
        SurfaceAlt = Color3.fromRGB(18, 22, 31),
        Sidebar = Color3.fromRGB(11, 13, 19),
        Border = Color3.fromRGB(44, 52, 70),
        BorderSoft = Color3.fromRGB(28, 34, 46),
        Text = Color3.fromRGB(241, 245, 255),
        Muted = Color3.fromRGB(153, 164, 184),
        Accent = Color3.fromRGB(111, 103, 255),
        AccentSoft = Color3.fromRGB(72, 66, 151),
        Success = Color3.fromRGB(52, 199, 89),
        Danger = Color3.fromRGB(255, 82, 82),
        Warning = Color3.fromRGB(255, 173, 51),
        Overlay = Color3.fromRGB(0, 0, 0),
    },

    Crimson = {
        Name = "Crimson",
        Background = Color3.fromRGB(11, 8, 12),
        Surface = Color3.fromRGB(20, 12, 20),
        SurfaceAlt = Color3.fromRGB(28, 18, 28),
        Sidebar = Color3.fromRGB(16, 10, 17),
        Border = Color3.fromRGB(80, 40, 54),
        BorderSoft = Color3.fromRGB(46, 24, 34),
        Text = Color3.fromRGB(247, 241, 246),
        Muted = Color3.fromRGB(190, 158, 171),
        Accent = Color3.fromRGB(255, 71, 114),
        AccentSoft = Color3.fromRGB(161, 42, 74),
        Success = Color3.fromRGB(68, 220, 139),
        Danger = Color3.fromRGB(255, 96, 96),
        Warning = Color3.fromRGB(255, 180, 71),
        Overlay = Color3.fromRGB(0, 0, 0),
    },

    Eclipse = {
        Name = "Eclipse",
        Background = Color3.fromRGB(6, 9, 12),
        Surface = Color3.fromRGB(10, 15, 19),
        SurfaceAlt = Color3.fromRGB(13, 22, 27),
        Sidebar = Color3.fromRGB(8, 13, 17),
        Border = Color3.fromRGB(36, 57, 63),
        BorderSoft = Color3.fromRGB(21, 33, 37),
        Text = Color3.fromRGB(230, 247, 244),
        Muted = Color3.fromRGB(139, 173, 166),
        Accent = Color3.fromRGB(0, 216, 180),
        AccentSoft = Color3.fromRGB(0, 116, 98),
        Success = Color3.fromRGB(63, 207, 157),
        Danger = Color3.fromRGB(255, 97, 97),
        Warning = Color3.fromRGB(255, 182, 56),
        Overlay = Color3.fromRGB(0, 0, 0),
    },
}

function Theme.Get(name)
    return Theme.Presets[name] or Theme.Presets.Obsidian
end

function Theme.GetNames()
    local list = {}
    for name in pairs(Theme.Presets) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

return Theme
