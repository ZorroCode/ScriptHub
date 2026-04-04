return {
    Init = function(ctx)
        local Config = ctx.Loader:LoadGameModule("Config")
        local Scanners = ctx.Loader:LoadGameModule("Scanners")
        local Features = ctx.Loader:LoadGameModule("Features")
        local UI = ctx.Loader:LoadGameModule("UI")

        local settings = Config.CreateSettings()
        local scanners = Scanners.Create(ctx)
        local features = Features.Create(ctx, Config, scanners, settings)
        local ui = UI.Create(ctx, Config, settings, features)

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

        print(string.format("[%s] Loaded.", tostring(Config.WindowTitle)))
    end,
}