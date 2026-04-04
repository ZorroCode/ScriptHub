local Bootstrap = {}

local function safeLoadString(source, chunkName)
    local compiled, err = loadstring(source, chunkName)

    if not compiled then
        error(string.format("[Bootstrap] Failed to compile %s: %s", tostring(chunkName), tostring(err)))
    end

    return compiled
end

local function loadRemoteSource(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error(string.format("[Bootstrap] Failed to fetch URL: %s\n%s", tostring(url), tostring(result)))
    end

    if type(result) ~= "string" or result == "" then
        error(string.format("[Bootstrap] Empty response from URL: %s", tostring(url)))
    end

    return result
end

local function loadRemoteModule(url)
    local source = loadRemoteSource(url)
    local chunk = safeLoadString(source, "@" .. tostring(url))

    local ok, result = pcall(chunk)
    if not ok then
        error(string.format("[Bootstrap] Failed to execute module: %s\n%s", tostring(url), tostring(result)))
    end

    return result
end

local function buildUrlMap(baseUrl)
    return {
        Core = {
            Config = baseUrl .. "/core/config.lua",
            State = baseUrl .. "/core/state.lua",
            Runtime = baseUrl .. "/core/runtime.lua",
            Cleanup = baseUrl .. "/core/cleanup.lua",
            Logger = baseUrl .. "/core/logger.lua",
        },

        Shared = {
            Services = baseUrl .. "/shared/services.lua",
            Instances = baseUrl .. "/shared/instances.lua",
            Formatting = baseUrl .. "/shared/formatting.lua",
            Tables = baseUrl .. "/shared/tables.lua",
            Players = baseUrl .. "/shared/players.lua",
            Constants = baseUrl .. "/shared/constants.lua",
        },

        UI = {
            Window = baseUrl .. "/ui/wrappers/window.lua",
            Tabs = baseUrl .. "/ui/wrappers/tabs.lua",
            Controls = baseUrl .. "/ui/wrappers/controls.lua",
            Theme = baseUrl .. "/ui/themes/default.lua",
        },
    }
end

local function loadCoreModules(baseUrl)
    local urls = buildUrlMap(baseUrl)

    return {
        Urls = urls,

        Core = {
            Config = loadRemoteModule(urls.Core.Config),
            State = loadRemoteModule(urls.Core.State),
            Runtime = loadRemoteModule(urls.Core.Runtime),
            Cleanup = loadRemoteModule(urls.Core.Cleanup),
            Logger = loadRemoteModule(urls.Core.Logger),
        },

        Shared = {
            Services = loadRemoteModule(urls.Shared.Services),
            Instances = loadRemoteModule(urls.Shared.Instances),
            Formatting = loadRemoteModule(urls.Shared.Formatting),
            Tables = loadRemoteModule(urls.Shared.Tables),
            Players = loadRemoteModule(urls.Shared.Players),
            Constants = loadRemoteModule(urls.Shared.Constants),
        },

        UI = {
            Window = loadRemoteModule(urls.UI.Window),
            Tabs = loadRemoteModule(urls.UI.Tabs),
            Controls = loadRemoteModule(urls.UI.Controls),
            Theme = loadRemoteModule(urls.UI.Theme),
        },
    }
end

function Bootstrap.CreateContext(registry, selectedGame)
    if type(registry) ~= "table" then
        error("[Bootstrap] Registry is missing or invalid.")
    end

    if type(selectedGame) ~= "table" then
        error("[Bootstrap] Selected game is missing or invalid.")
    end

    local baseUrl = registry.BaseUrl
    if type(baseUrl) ~= "string" or baseUrl == "" then
        error("[Bootstrap] Registry.BaseUrl is missing or invalid.")
    end

    local loaded = loadCoreModules(baseUrl)

    local services = loaded.Shared.Services.Get()
    local localPlayer = loaded.Shared.Players.GetLocalPlayer(services.Players)

    local logger = loaded.Core.Logger.new("ScriptHub")
    local state = loaded.Core.State.new()
    local cleanup = loaded.Core.Cleanup.new()
    local runtime = loaded.Core.Runtime.new(services.RunService)

    local ctx = {
        BaseUrl = baseUrl,
        Registry = registry,
        Game = selectedGame,

        Core = {
            Config = loaded.Core.Config,
            State = loaded.Core.State,
            Runtime = loaded.Core.Runtime,
            Cleanup = loaded.Core.Cleanup,
            Logger = loaded.Core.Logger,
        },

        Shared = {
            Services = services,
            LocalPlayer = localPlayer,

            Instances = loaded.Shared.Instances,
            Formatting = loaded.Shared.Formatting,
            Tables = loaded.Shared.Tables,
            Players = loaded.Shared.Players,
            Constants = loaded.Shared.Constants,
        },

        UI = {
            Window = loaded.UI.Window,
            Tabs = loaded.UI.Tabs,
            Controls = loaded.UI.Controls,
            Theme = loaded.UI.Theme,
        },

        App = {
            Logger = logger,
            State = state,
            Cleanup = cleanup,
            Runtime = runtime,
        },
    }

    ctx.Loader = {}

    function ctx.Loader:Get(url)
        return loadRemoteSource(url)
    end

    function ctx.Loader:LoadModule(url)
        return loadRemoteModule(url)
    end

    function ctx.Loader:LoadGameModule(relativeKey)
        local sources = selectedGame.Sources or {}
        local url = sources[relativeKey]

        if not url then
            error(string.format("[Bootstrap] Missing game source key: %s", tostring(relativeKey)))
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:LoadUILibrary()
        local url = registry.UILibraryUrl

        if type(url) ~= "string" or url == "" then
            error("[Bootstrap] UILibraryUrl is missing from registry.")
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:LoadSharedModule(name)
        local url = loaded.Urls.Shared[name]
        if not url then
            error(string.format("[Bootstrap] Unknown shared module: %s", tostring(name)))
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:LoadCoreModule(name)
        local url = loaded.Urls.Core[name]
        if not url then
            error(string.format("[Bootstrap] Unknown core module: %s", tostring(name)))
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:LoadUIWrapper(name)
        local url = loaded.Urls.UI[name]
        if not url then
            error(string.format("[Bootstrap] Unknown UI wrapper: %s", tostring(name)))
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:SafeCall(label, fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then
            logger:Warn(string.format("%s failed: %s", tostring(label), tostring(result)))
            return false, result
        end

        return true, result
    end

    logger:Info(string.format(
        "Bootstrapped game '%s' for PlaceId %s",
        tostring(selectedGame.Name or "Unknown"),
        tostring(game.PlaceId)
    ))

    return ctx
end

return Bootstrap