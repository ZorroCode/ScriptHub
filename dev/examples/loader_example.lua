-- Example loader usage

local URL = "https://raw.githubusercontent.com/ZorroCode/ScriptHub/refs/heads/main/loader/init.lua"

print("[Example] Loading ScriptHub...")

local success, result = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)

if not success then
    warn("[Example] Failed to load ScriptHub:", result)
else
    print("[Example] ScriptHub loaded successfully.")
end