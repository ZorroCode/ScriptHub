-- Basic smoke test for ScriptHub

local BASE_URL = "https://raw.githubusercontent.com/ZorroCode/ScriptHub/refs/heads/main"

local function loadModule(path)
    local url = BASE_URL .. path
    local source = game:HttpGet(url)
    local fn = loadstring(source, "@" .. url)
    return fn()
end

local ok, err = pcall(function()
    local registry = loadModule("/loader/registry.lua")
    local router = loadModule("/loader/router.lua")

    local gameEntry = router.FindGame(registry, game.PlaceId)

    print("[SmokeTest] Registry loaded:", registry ~= nil)
    print("[SmokeTest] Router loaded:", router ~= nil)
    print("[SmokeTest] Game found:", gameEntry ~= nil)
end)

if not ok then
    warn("[SmokeTest] Failed:", err)
else
    print("[SmokeTest] Passed.")
end