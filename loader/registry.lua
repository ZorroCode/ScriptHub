local BASE_URL = "https://raw.githubusercontent.com/ZorroCode/ScriptHub/refs/heads/main"

return {
    BaseUrl = BASE_URL,

    UILibraryUrl = BASE_URL .. "/ui/library/UILibrary.lua",

    Games = {
        {
            Name = "Bite By Night",
            Key = "BiteByNight",
            Enabled = true,

            -- Put the real PlaceId(s) here
            PlaceIds = {
                70845479499574,
            },

            Entry = BASE_URL .. "/games/active/BiteByNight/init.lua",

            Sources = {
                Init = BASE_URL .. "/games/active/BiteByNight/init.lua",
                Config = BASE_URL .. "/games/active/BiteByNight/config.lua",
                UI = BASE_URL .. "/games/active/BiteByNight/ui.lua",
                Scanners = BASE_URL .. "/games/active/BiteByNight/scanners.lua",
                Features = BASE_URL .. "/games/active/BiteByNight/features.lua",
            },
        },

        -- Example for future games:
        -- {
        --     Name = "Another Game",
        --     Key = "AnotherGame",
        --     Enabled = true,
        --     PlaceIds = {
        --         1234567890,
        --     },
        --     Entry = BASE_URL .. "/games/active/AnotherGame/init.lua",
        --     Sources = {
        --         Init = BASE_URL .. "/games/active/AnotherGame/init.lua",
        --         Config = BASE_URL .. "/games/active/AnotherGame/config.lua",
        --         UI = BASE_URL .. "/games/active/AnotherGame/ui.lua",
        --         Scanners = BASE_URL .. "/games/active/AnotherGame/scanners.lua",
        --         Features = BASE_URL .. "/games/active/AnotherGame/features.lua",
        --     },
        -- },
    },

    Universal = {
        Enabled = false,
        Entry = BASE_URL .. "/games/active/universal/init.lua",
    },
}