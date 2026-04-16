local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local logger = ctx.App.Logger
    local services = ctx.Shared.Services
    local app = ctx.UI.App.Create(services, ctx.UI.Theme, {
        Title = "VANTA Hub",
        Subtitle = "Bite By Night module loaded",
        ToggleKey = config.WindowToggleKey,
        ThemeName = "Obsidian",
        DefaultPage = "home",
    })

    local categories = {
        { Key = "Player", Label = "Players", Description = "Alive survivors with names, health, stamina, distance, and highlight." },
        { Key = "Killer", Label = "Killer", Description = "Track the killer and keep pressure visible at all times." },
        { Key = "Generator", Label = "Generators", Description = "Show objectives with progress tracker support." },
        { Key = "Battery", Label = "Batteries", Description = "Find battery pickups faster." },
        { Key = "Fuse", Label = "Fuses", Description = "Spot fuse objectives instantly." },
        { Key = "Trap", Label = "Traps", Description = "Catch traps and minions before they screw you." },
    }

    local categoryControls = {}

    local function countEnabled()
        local total = 0
        for _, category in ipairs(categories) do
            if settings[category.Key] and settings[category.Key].Enabled then
                total = total + 1
            end
        end
        return total
    end

    local function featureCount()
        local total = 0
        for _, category in ipairs(categories) do
            total = total + #(settings[category.Key].Features or {})
        end
        return total
    end

    local home = app:AddPage({
        Id = "home",
        Title = "Overview",
        Subtitle = "Dashboard, quick actions, and game status",
    })

    home:AddHeroCard(
        "VANTA Hub / Bite By Night",
        "Full UI rework with page navigation, search, quick actions, live theme switching, and a cleaner ESP workflow. Hit the sidebar, flip what you need, and keep the rest lean.",
        "ACTIVE"
    )

    home:AddStatsRow({
        {
            Label = "Tracked Categories",
            Value = tostring(#categories),
            Subtext = "Players, killer, and world objects",
            ColorKey = "Accent",
        },
        {
            Label = "Enabled Right Now",
            Value = function() return tostring(countEnabled()) end,
            Subtext = "Live session state",
            ColorKey = "Success",
        },
        {
            Label = "Feature Flags",
            Value = tostring(featureCount()),
            Subtext = "Dropdown-selected ESP details",
            ColorKey = "Warning",
        },
    })

    local quick = home:AddSection({
        Title = "Quick Actions",
        Subtitle = "Fast control over the whole module.",
    })

    local function refreshAllCards()
        for _, category in ipairs(categories) do
            local control = categoryControls[category.Key]
            if control then
                control.Toggle:Set(settings[category.Key].Enabled, true)
                control.Features:Set(settings[category.Key].Features, true)
            end
            features.RefreshCategory(category.Key)
        end
    end

    quick:AddButton({
        Title = "Enable Everything",
        Callback = function()
            for _, category in ipairs(categories) do
                settings[category.Key].Enabled = true
            end
            refreshAllCards()
            app:Notify("VANTA Hub", "Enabled every ESP category.", 3)
        end,
    })

    quick:AddButton({
        Title = "Disable Everything",
        Style = "Danger",
        Callback = function()
            for _, category in ipairs(categories) do
                settings[category.Key].Enabled = false
                features.DestroyCategory(category.Key)
            end
            refreshAllCards()
            app:Notify("VANTA Hub", "Disabled every ESP category.", 3)
        end,
    })

    quick:AddButton({
        Title = "Refresh Targets",
        Style = "Success",
        Callback = function()
            features.RefreshAll()
            app:Notify("VANTA Hub", "Forced an ESP refresh.", 2)
        end,
    })

    local overview = home:AddSection({
        Title = "What Changed",
        Subtitle = "The hub now feels like a real product instead of a raw loader shell.",
    })

    overview:AddLabel("• Sidebar navigation with dedicated pages.")
    overview:AddLabel("• Search box filters the current page instantly.")
    overview:AddLabel("• Theme switcher with multiple dark presets.")
    overview:AddLabel("• Better category cards for toggles + feature sets.")
    overview:AddLabel("• Quick action workflow for mass enable, mass disable, and live refresh.")

    local espPage = app:AddPage({
        Id = "esp",
        Title = "ESP Controls",
        Subtitle = "Per-category controls with cleaner feature management",
    })

    for _, category in ipairs(categories) do
        local section = espPage:AddSection({
            Title = category.Label,
            Subtitle = category.Description,
        })

        local toggle = section:AddToggle({
            Title = category.Label .. " ESP",
            Description = "Enable or disable this target group.",
            Default = settings[category.Key].Enabled,
            Callback = function(value)
                settings[category.Key].Enabled = value
                if not value then
                    features.DestroyCategory(category.Key)
                end
                features.RefreshCategory(category.Key)
                app:Notify("ESP Updated", category.Label .. " set to " .. (value and "enabled" or "disabled") .. ".", 2)
            end,
        })

        local featureSelect = section:AddMultiSelect({
            Title = category.Label .. " Features",
            Options = config.FeatureOptions[category.Key],
            Default = settings[category.Key].Features,
            NoneText = "No feature selected",
            Callback = function(selected)
                settings[category.Key].Features = selected
                features.RefreshCategory(category.Key)
            end,
        })

        categoryControls[category.Key] = {
            Toggle = toggle,
            Features = featureSelect,
        }
    end

    local toolsPage = app:AddPage({
        Id = "tools",
        Title = "Session Tools",
        Subtitle = "Utility controls for this run",
    })

    local tools = toolsPage:AddSection({
        Title = "Runtime",
        Subtitle = "Small but useful actions for debugging and upkeep.",
    })

    tools:AddButton({
        Title = "Log Active Definitions",
        Callback = function()
            local defs = features.GetDefinitions()
            for name, def in pairs(defs) do
                logger:Info(string.format("[VANTA] %s enabled=%s", tostring(name), tostring(def.Enabled and def.Enabled())))
            end
            app:Notify("VANTA Hub", "Wrote active definitions to the logger.", 3)
        end,
    })

    tools:AddButton({
        Title = "Clear All ESP Drawings",
        Style = "Danger",
        Callback = function()
            features.DestroyAll()
            app:Notify("VANTA Hub", "Destroyed all current ESP drawings.", 3)
        end,
    })

    local settingsPage = app:AddPage({
        Id = "settings",
        Title = "Settings",
        Subtitle = "Theme, visuals, and hub preferences",
    })

    local appearance = settingsPage:AddSection({
        Title = "Appearance",
        Subtitle = "All presets stay in the dark lane; that fits VANTA better anyway.",
    })

    appearance:AddDropdown({
        Title = "Theme Preset",
        Options = app:GetThemeNames(),
        Default = "Obsidian",
        Callback = function(value)
            app:SetTheme(value)
            app:Notify("Theme Changed", "Switched to " .. tostring(value) .. ".", 2)
        end,
    })

    local infoPage = app:AddPage({
        Id = "info",
        Title = "Info",
        Subtitle = "Current game, loader state, and key details",
    })

    local infoSection = infoPage:AddSection({
        Title = "Session Info",
        Subtitle = "Useful metadata for the current match and module.",
    })

    infoSection:AddLabel("Game: Bite By Night")
    infoSection:AddLabel("PlaceId: " .. tostring(game.PlaceId))
    infoSection:AddLabel("GameId: " .. tostring(game.GameId))
    infoSection:AddLabel("Toggle Key: " .. tostring(config.WindowToggleKey.Name))

    app:Notify("VANTA Hub", "Bite By Night module loaded clean.", 4)
    logger:Info("Built VANTA Hub UI for Bite By Night.")

    return {
        App = app,
        RefreshCards = refreshAllCards,
    }
end

return UIBuilder
