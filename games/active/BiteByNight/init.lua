return {
    Init = function(ctx)
        local logger = ctx.App.Logger
        local runtime = ctx.App.Runtime
        local cleanup = ctx.App.Cleanup
        local localPlayer = ctx.Shared.LocalPlayer

        local Config = ctx.Loader:LoadGameModule("Config")
        local ScannersModule = ctx.Loader:LoadGameModule("Scanners")
        local FeaturesModule = ctx.Loader:LoadGameModule("Features")
        local UIModule = ctx.Loader:LoadGameModule("UI")

        local settings = Config.CreateSettings()
        local scanners = ScannersModule.Create(ctx)
        local features = FeaturesModule.Create(ctx, Config, scanners, settings)
        local ui = UIModule.Create(ctx, Config, settings, features)

        runtime:Every(Config.UpdateInterval, function()
            features.RefreshAll()
        end)

        if localPlayer then
            runtime:Bind(localPlayer.CharacterAdded, function()
                task.wait(1)
                features.RefreshAll()
            end)
        end

        cleanup:Add(function()
            features.DestroyAll()
        end)

        logger:Info("[Bite By Night] Loaded. Use RightAlt to toggle UI.")
    end,
}