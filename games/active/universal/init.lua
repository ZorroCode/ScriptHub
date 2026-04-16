return {
    Init = function(ctx)
        local UILibrary = ctx.Loader:LoadUILibrary()
        UILibrary:SetTheme("Vanta")

        local window = UILibrary:CreateWindow("VANTA Hub", Enum.KeyCode.RightAlt)
        local overview = window:CreateTab("Overview", "rbxassetid://0")
        overview:SetHeader("Universal Fallback", "No specific game module detected")

        overview:Divider("Status")
        overview:Label("This place does not have a dedicated VANTA module yet.")
        overview:Label("You can add support in games/active/ and register the PlaceId.")
        overview:Label("Detected PlaceId: " .. tostring(game.PlaceId))
        overview:Label("Detected GameId: " .. tostring(game.GameId))

        overview:Divider("Scaffold")
        overview:Label("Use games/templates/GameTemplate as the starting point for new modules.")
        overview:Label("Use ui/wrappers/hub.lua to build multi-page control surfaces faster.")

        if window.Notify then
            window:Notify("Universal mode", "Loaded fallback UI because no dedicated game handler matched.", 4)
        end

        print("[VANTA] Universal fallback loaded.")

        return {
            Window = window,
        }
    end,
}
