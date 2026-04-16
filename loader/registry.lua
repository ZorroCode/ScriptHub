local BASE_URL = "https://raw.githubusercontent.com/ZorroCode/ScriptHub/refs/heads/main"

local function makeGame(def)
    local key = def.Key
    local name = def.Name or key
    local folder = def.Folder or key
    local gameRoot = def.Root or (BASE_URL .. "/games/active/" .. folder)

    local sources = {
        Init = gameRoot .. "/init.lua",
        Config = gameRoot .. "/config.lua",
        UI = gameRoot .. "/ui.lua",
        Scanners = gameRoot .. "/scanners.lua",
        Features = gameRoot .. "/features.lua",
    }

    if type(def.Sources) == "table" then
        for sourceKey, sourceUrl in pairs(def.Sources) do
            sources[sourceKey] = sourceUrl
        end
    end

    return {
        Name = name,
        Key = key,
        Enabled = def.Enabled ~= false,
        PlaceIds = def.PlaceIds or {},
        Entry = def.Entry or sources.Init,
        Sources = sources,
        Tags = def.Tags or {},
    }
end

return {
    ProductName = "VANTA Hub",
    BaseUrl = BASE_URL,
    UILibraryUrl = BASE_URL .. "/ui/library/UILibrary.lua",

    Games = {
        makeGame({
            Name = "Bite By Night",
            Key = "BiteByNight",
            PlaceIds = {
                70845479499574,
            },
            Tags = {
                "active",
            },
        }),

        -- Example:
        -- makeGame({
        --     Name = "Another Game",
        --     Key = "AnotherGame",
        --     PlaceIds = {
        --         1234567890,
        --     },
        -- }),
    },

    Universal = {
        Enabled = false,
        Entry = BASE_URL .. "/games/active/universal/init.lua",
    },
}