return {
    Init = function(ctx)
        local Config = ctx.Loader:LoadGameModule("Config")
        local ScannersModule = ctx.Loader:LoadGameModule("Scanners")
        local FeaturesModule = ctx.Loader:LoadGameModule("Features")
        local UIModule = ctx.Loader:LoadGameModule("UI")

        local settings = Config.CreateSettings()
        local scanners = ScannersModule.Create(ctx)
        local features = FeaturesModule.Create(ctx, Config, scanners, settings)
        local ui = UIModule.Create(ctx, Config, settings, features)

        local runService = ctx.Shared.Services.RunService
        local localPlayer = ctx.Shared.LocalPlayer

        do
            local elapsed = 0

            ui.Window:GiveTask(runService.Heartbeat:Connect(function(dt)
                elapsed += dt

                if elapsed < Config.UpdateInterval then
                    return
                end

                elapsed = 0
                features.RefreshAll()
            end))
        end

        if localPlayer then
            ui.Window:GiveTask(localPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                features.RefreshAll()
            end))
        end

        print("[Bite By Night] Loaded. Use RightAlt to toggle UI.")
    end,
}