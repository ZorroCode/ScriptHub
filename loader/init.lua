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

local Registry = loadRemoteModule(BASE_URL .. "/loader/registry.lua")
local Router = loadRemoteModule(BASE_URL .. "/loader/router.lua")
local Bootstrap = loadRemoteModule(BASE_URL .. "/loader/bootstrap.lua")

local selectedGame, routeMessage = Router.FindGame(Registry, game.PlaceId)

if not selectedGame then
    warn("[Loader] " .. tostring(routeMessage))
    return
end

local ctx = Bootstrap.CreateContext(Registry, selectedGame)

local gameEntryUrl = selectedGame.Entry
if not gameEntryUrl or gameEntryUrl == "" then
    error(string.format("[Loader] Missing Entry URL for game: %s", tostring(selectedGame.Name)))
end

local gameModule = ctx.Loader:LoadModule(gameEntryUrl)

if type(gameModule) ~= "table" then
    error(string.format("[Loader] Game entry did not return a table: %s", tostring(selectedGame.Name)))
end

if type(gameModule.Init) ~= "function" then
    error(string.format("[Loader] Game entry is missing Init(ctx): %s", tostring(selectedGame.Name)))
end

local ok, err = pcall(function()
    gameModule.Init(ctx)
end)

if not ok then
    error(string.format("[Loader] Failed to initialize game '%s': %s", tostring(selectedGame.Name), tostring(err)))
end