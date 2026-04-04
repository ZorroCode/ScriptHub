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

local function buildShared()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")

    return {
        Services = {
            Players = Players,
            RunService = RunService,
            Workspace = Workspace,
            HttpService = HttpService,
            UserInputService = UserInputService,
        },

        LocalPlayer = Players.LocalPlayer,

        Utils = {},
    }
end

function Bootstrap.CreateContext(registry, selectedGame)
    if type(registry) ~= "table" then
        error("[Bootstrap] Registry is missing or invalid.")
    end

    if type(selectedGame) ~= "table" then
        error("[Bootstrap] Selected game is missing or invalid.")
    end

    local ctx = {
        BaseUrl = registry.BaseUrl,
        Registry = registry,
        Game = selectedGame,
        Shared = buildShared(),
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

        if not url or url == "" then
            error("[Bootstrap] UILibraryUrl is missing from registry.")
        end

        return loadRemoteModule(url)
    end

    function ctx.Loader:SafeCall(label, fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then
            warn(string.format("[Bootstrap] %s failed: %s", tostring(label), tostring(result)))
            return false, result
        end
        return true, result
    end

    return ctx
end

return Bootstrap