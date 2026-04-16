return {
    Init = function(ctx)
        local app = ctx.UI.App.Create(ctx.Shared.Services, ctx.UI.Theme, {
            Title = "VANTA Hub",
            Subtitle = "Universal fallback",
            ToggleKey = Enum.KeyCode.RightAlt,
            ThemeName = "Obsidian",
            DefaultPage = "home",
        })

        local home = app:AddPage({
            Id = "home",
            Title = "Unsupported Game",
            Subtitle = "Fallback mode is active",
        })

        home:AddHeroCard(
            "No dedicated module for this game",
            "The fallback loaded correctly, but this place does not have a custom implementation yet. The hub itself is alive, so adding support later is clean and easy.",
            "FALLBACK"
        )

        home:AddStatsRow({
            {
                Label = "PlaceId",
                Value = tostring(game.PlaceId),
                Subtext = "Current place",
                ColorKey = "Accent",
            },
            {
                Label = "GameId",
                Value = tostring(game.GameId),
                Subtext = "Universe identifier",
                ColorKey = "Warning",
            },
        })

        local section = home:AddSection({
            Title = "What To Do Next",
            Subtitle = "Clean fallback so you can ship support later without rebuilding the shell.",
        })

        section:AddLabel("• Drop a new game folder into /games/active/.")
        section:AddLabel("• Add the PlaceId in loader/registry.lua.")
        section:AddLabel("• Reuse the VANTA app pages instead of rebuilding UI from scratch.")

        local settings = app:AddPage({
            Id = "settings",
            Title = "Settings",
            Subtitle = "Theme control still works in fallback mode",
        })

        local appearance = settings:AddSection({
            Title = "Appearance",
            Subtitle = "Same dark preset stack used by the active game module.",
        })

        appearance:AddDropdown({
            Title = "Theme Preset",
            Options = app:GetThemeNames(),
            Default = "Obsidian",
            Callback = function(value)
                app:SetTheme(value)
            end,
        })

        app:Notify("VANTA Hub", "Universal fallback loaded.", 4)
        print("[VANTA Hub] Universal fallback loaded.")
    end,
}
