local GameSchema = {}

function GameSchema.Create(name)
    return {
        Name = name or "New Module",
        Pages = {
            { Key = "Overview", Name = "Overview", HeaderTitle = name or "Overview", HeaderSubtitle = "Main control surface" },
            { Key = "Settings", Name = "Settings", HeaderTitle = "Settings", HeaderSubtitle = "Theme, toggles, and module behavior" },
            { Key = "Info", Name = "Info", HeaderTitle = "Info", HeaderSubtitle = "Diagnostics and environment info" },
        },
        Settings = {},
        Features = {},
    }
end

return GameSchema
