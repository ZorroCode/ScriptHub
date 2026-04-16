local Bootstrap = {}

local function buildUrlMap(baseUrl)
    return {
        Core = {
            Config = baseUrl .. "/core/config.lua",
            State = baseUrl .. "/core/state.lua",
            Runtime = baseUrl .. "/core/runtime.lua",
            Cleanup = baseUrl .. "/core/cleanup.lua",
            Logger = baseUrl .. "/core/logger.lua",
            ModuleLoader = baseUrl .. "/core/module_loader.lua",
            FeatureManager = baseUrl .. "/core/feature_manager.lua",
            GameFactory = baseUrl .. "/core/game_factory.lua",
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
            Theme = baseUrl .. "/ui/vanta/theme.lua",
            App = baseUrl .. "/ui/vanta/app.lua",
        },
    }
end

local function loadCoreModules(loader, baseUrl)
    local urls = buildUrlMap(baseUrl)

    return {
        Urls = urls,

        Core = {
            Config = loader:LoadModule(urls.Core.Config),
            State = loader:LoadModule(urls.Core.State),
            Runtime = loader:LoadModule(urls.Core.Runtime),
            Cleanup = loader:LoadModule(urls.Core.Cleanup),
            Logger = loader:LoadModule(urls.Core.Logger),
            ModuleLoader = loader:LoadModule(urls.Core.ModuleLoader),
            FeatureManager = loader:LoadModule(urls.Core.FeatureManager),
            GameFactory = loader:LoadModule(urls.Core.GameFactory),
        },

        Shared = {
            Services = loader:LoadModule(urls.Shared.Services),
            Instances = loader:LoadModule(urls.Shared.Instances),
            Formatting = loader:LoadModule(urls.Shared.Formatting),
            Tables = loader:LoadModule(urls.Shared.Tables),
            Players = loader:LoadModule(urls.Shared.Players),
            Constants = loader:LoadModule(urls.Shared.Constants),
        },

        UI = {
            Window = loader:LoadModule(urls.UI.Window),
            Tabs = loader:LoadModule(urls.UI.Tabs),
            Controls = loader:LoadModule(urls.UI.Controls),
            Theme = loader:LoadModule(urls.UI.Theme),
            App = loader:LoadModule(urls.UI.App),
        },
    }
end

function Bootstrap.CreateContext(registry, selectedGame, moduleLoader)
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

    if type(moduleLoader) ~= "table" or type(moduleLoader.LoadModule) ~= "function" then
        error("[Bootstrap] ModuleLoader is missing or invalid.")
    end

    local loaded = loadCoreModules(moduleLoader, baseUrl)

    local services = loaded.Shared.Services.Get()
    local localPlayer = loaded.Shared.Players.GetLocalPlayer(services.Players)

    local logger = loaded.Core.Logger.new(registry.ProductName or "Atlas")
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
            ModuleLoader = loaded.Core.ModuleLoader,
            FeatureManager = loaded.Core.FeatureManager,
            GameFactory = loaded.Core.GameFactory,
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
            App = loaded.UI.App,
        },

        App = {
            Logger = logger,
            State = state,
            Cleanup = cleanup,
            Runtime = runtime,
        },
    }

    ctx.Loader = {}

    function ctx.Loader:Get(url, bypassCache)
        return moduleLoader:FetchSource(url, bypassCache)
    end

    function ctx.Loader:LoadModule(url, bypassCache)
        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:BuildUrl(relativePath)
        return moduleLoader:BuildUrl(baseUrl, relativePath)
    end

    function ctx.Loader:LoadGameModule(relativeKey, bypassCache)
        local sources = selectedGame.Sources or {}
        local url = sources[relativeKey]

        if not url then
            error(string.format("[Bootstrap] Missing game source key: %s", tostring(relativeKey)))
        end

        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:LoadUILibrary(bypassCache)
        local url = registry.UILibraryUrl

        if type(url) ~= "string" or url == "" then
            error("[Bootstrap] UILibraryUrl is missing from registry.")
        end

        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:LoadSharedModule(name, bypassCache)
        local url = loaded.Urls.Shared[name]
        if not url then
            error(string.format("[Bootstrap] Unknown shared module: %s", tostring(name)))
        end

        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:LoadCoreModule(name, bypassCache)
        local url = loaded.Urls.Core[name]
        if not url then
            error(string.format("[Bootstrap] Unknown core module: %s", tostring(name)))
        end

        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:LoadUIWrapper(name, bypassCache)
        local url = loaded.Urls.UI[name]
        if not url then
            error(string.format("[Bootstrap] Unknown UI wrapper: %s", tostring(name)))
        end

        return moduleLoader:LoadModule(url, bypassCache)
    end

    function ctx.Loader:ClearSourceCache(url)
        moduleLoader:ClearSourceCache(url)
    end

    function ctx.Loader:ClearModuleCache(url)
        moduleLoader:ClearModuleCache(url)
    end

    function ctx.Loader:ClearAllCache()
        moduleLoader:ClearAllCache()
    end

    return ctx
end

return Bootstrap