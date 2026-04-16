local GameFactory = {}

function GameFactory.Boot(ctx, options)
    options = options or {}

    local logger = ctx.App.Logger
    local runtime = ctx.App.Runtime
    local cleanup = ctx.App.Cleanup
    local localPlayer = ctx.Shared.LocalPlayer

    local configModule = options.Config or ctx.Loader:LoadGameModule("Config")
    local scannersModule = options.Scanners or ctx.Loader:LoadGameModule("Scanners")
    local featuresModule = options.Features or ctx.Loader:LoadGameModule("Features")
    local uiModule = options.UI or ctx.Loader:LoadGameModule("UI")

    local settings = configModule.CreateSettings and configModule.CreateSettings() or {}
    local scanners = scannersModule.Create and scannersModule.Create(ctx, settings) or {}
    local features = featuresModule.Create and featuresModule.Create(ctx, configModule, scanners, settings) or {}
    local ui = uiModule.Create and uiModule.Create(ctx, configModule, settings, features) or nil

    if type(features.RefreshAll) == "function" and type(configModule.UpdateInterval) == "number" then
        runtime:Every(configModule.UpdateInterval, function()
            features.RefreshAll()
        end)
    end

    if localPlayer and type(features.RefreshAll) == "function" then
        runtime:Bind(localPlayer.CharacterAdded, function()
            task.wait(1)
            features.RefreshAll()
        end)
    end

    cleanup:Add(function()
        if features and type(features.DestroyAll) == "function" then
            features.DestroyAll()
        end
    end)

    logger:Info(string.format("[%s] Loaded.", tostring(configModule.WindowTitle or ctx.Game.Name or "Atlas")))

    return {
        UI = ui,
        Settings = settings,
        Scanners = scanners,
        Features = features,
    }
end

return GameFactory