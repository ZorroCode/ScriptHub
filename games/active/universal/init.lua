return {
    Init = function(ctx)
        local UILibrary = ctx.Loader:LoadUILibrary()

        local window = UILibrary:CreateWindow("Script Hub", Enum.KeyCode.RightAlt)
        local tab = window:CreateTab("Universal", "rbxassetid://0")

        tab:SetHeader("Universal", "No specific game loaded")

        tab:Label("Status: No supported game detected.")

        tab:Divider("Info")

        tab:Label("This game is not supported yet.")
        tab:Label("You can add support in /games/active/")

        tab:Divider("Debug")

        tab:Label("PlaceId: " .. tostring(game.PlaceId))
        tab:Label("GameId: " .. tostring(game.GameId))

        print("[ScriptHub] Universal fallback loaded.")
    end,
}