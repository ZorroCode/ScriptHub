local BASE_URL = "https://raw.githubusercontent.com/ZorroCode/ScriptHub/refs/heads/main"

local function loadRemoteModule(url)
    local source = game:HttpGet(url)
    local chunk, compileError = loadstring(source, "@" .. tostring(url))

    if not chunk then
        error(string.format("[Loader] Failed to compile %s: %s", tostring(url), tostring(compileError)))
    end

    local ok, result = pcall(chunk)

    if not ok then
        error(string.format("[Loader] Failed to execute %s: %s", tostring(url), tostring(result)))
    end

    return result
end

local ModuleLoader = loadRemoteModule(BASE_URL .. "/core/module_loader.lua")
local loader = ModuleLoader.new(function(url)
    return game:HttpGet(url)
end, loadstring)

local Registry = loader:LoadModule(BASE_URL .. "/loader/registry.lua")
local Router = loader:LoadModule(BASE_URL .. "/loader/router.lua")
local Bootstrap = loader:LoadModule(BASE_URL .. "/loader/bootstrap.lua")

local selectedGame, routeMessage = Router.FindGame(Registry, game.PlaceId)

if not selectedGame then
    warn("[Loader] " .. tostring(routeMessage))
    return
end

local ctx = Bootstrap.CreateContext(Registry, selectedGame, loader)

if routeMessage then
    ctx.App.Logger:Info(routeMessage)
end

local gameEntryUrl = selectedGame.Entry
if type(gameEntryUrl) ~= "string" or gameEntryUrl == "" then
    ctx.App.Logger:Error(string.format(
        "Missing Entry URL for game: %s",
        tostring(selectedGame.Name)
    ))
end

local gameModule = ctx.Loader:LoadModule(gameEntryUrl)

if type(gameModule) ~= "table" then
    ctx.App.Logger:Error(string.format(
        "Game entry did not return a table: %s",
        tostring(selectedGame.Name)
    ))
end

if type(gameModule.Init) ~= "function" then
    ctx.App.Logger:Error(string.format(
        "Game entry is missing Init(ctx): %s",
        tostring(selectedGame.Name)
    ))
end

local ok, err = pcall(function()
    gameModule.Init(ctx)
end)

if not ok then
    ctx.App.Logger:Warn(string.format(
        "Game init failed for '%s': %s",
        tostring(selectedGame.Name),
        tostring(err)
    ))

    pcall(function()
        ctx.App.Runtime:StopAll()
    end)

    pcall(function()
        ctx.App.Cleanup:Run()
    end)

    error(string.format(
        "[Loader] Failed to initialize game '%s': %s",
        tostring(selectedGame.Name),
        tostring(err)
    ))
end

ctx.App.Logger:Info(string.format(
    "Game '%s' initialized successfully.",
    tostring(selectedGame.Name)
))