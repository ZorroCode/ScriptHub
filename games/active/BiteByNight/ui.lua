local UIBuilder = {}

local CATEGORY_GROUPS = {
    { Key = "Player", Title = "Players", Description = "Survivor visibility and vitals" },
    { Key = "Killer", Title = "Killer", Description = "Threat tracking and live pursuit info" },
    { Key = "Generator", Title = "Generators", Description = "Objective progress and location cues" },
    { Key = "Battery", Title = "Batteries", Description = "Loot / pickup visibility" },
    { Key = "Fuse", Title = "Fuses", Description = "Objective item visibility" },
    { Key = "Trap", Title = "Traps", Description = "Environmental hazard awareness" },
}

function UIBuilder.Create(ctx, config, settings, features)
    local logger = ctx.App.Logger
    local UILibrary = ctx.Loader:LoadUILibrary()

    UILibrary:SetTheme(settings.Theme or config.DefaultTheme or "Vanta")

    local window = ctx.UI.Window.Create(UILibrary, {
        Title = config.WindowTitle,
        ToggleKey = config.WindowToggleKey,
    })

    local hub = ctx.UI.Hub.Create(window, {
        Pages = {
            {
                Key = "Overview",
                Name = "Overview",
                HeaderTitle = "Bite By Night",
                HeaderSubtitle = "Main control surface and fast actions",
            },
            {
                Key = "Entities",
                Name = "Entities",
                HeaderTitle = "Entity Matrix",
                HeaderSubtitle = "Per-category ESP controls and feature maps",
            },
            {
                Key = "Runtime",
                Name = "Runtime",
                HeaderTitle = "Runtime Tools",
                HeaderSubtitle = "Refresh, destroy, and operational controls",
            },
            {
                Key = "Settings",
                Name = "Settings",
                HeaderTitle = "Hub Settings",
                HeaderSubtitle = "Theme stack and UX tuning",
            },
            {
                Key = "Info",
                Name = "Info",
                HeaderTitle = "Session Intel",
                HeaderSubtitle = "Environment status and module information",
            },
        }
    })

    local overview = hub.Pages.Overview
    local entities = hub.Pages.Entities
    local runtime = hub.Pages.Runtime
    local settingsPage = hub.Pages.Settings
    local info = hub.Pages.Info

    local statusLabel = overview:Label("Status: VANTA initialized")
    local stateLabel = overview:Label("Armed categories: 0 / 6")
    local placeLabel = overview:Label("Detected PlaceId: " .. tostring(game.PlaceId))

    local function countEnabled()
        local total = 0
        for _, group in ipairs(CATEGORY_GROUPS) do
            if settings[group.Key] and settings[group.Key].Enabled then
                total = total + 1
            end
        end
        return total
    end

    local function setStatus(text)
        statusLabel:Set("Status: " .. tostring(text))
        stateLabel:Set(string.format("Armed categories: %d / %d", countEnabled(), #CATEGORY_GROUPS))
    end

    overview:Divider("Quick Actions")
    overview:Button("Refresh All Modules", function()
        features.RefreshAll()
        setStatus("Manual refresh complete")
        window:Notify("Refresh complete", "All active ESP categories were refreshed.", 3)
    end)
    overview:Button("Destroy All ESP", function()
        features.DestroyAll()
        for _, group in ipairs(CATEGORY_GROUPS) do
            settings[group.Key].Enabled = false
        end
        setStatus("Destroyed all category visuals")
        window:Notify("All visuals destroyed", "Every ESP category was cleared from the session.", 3)
    end)

    overview:Divider("Live Modules")
    for _, group in ipairs(CATEGORY_GROUPS) do
        overview:Label(string.format("%s — %s", group.Title, group.Description))
    end

    entities:Divider("Entity Control Matrix")

    local function addCategoryControls(tab, categoryName, displayName, description)
        tab:Label(description)
        tab:Toggle(displayName .. " ESP", settings[categoryName].Enabled, function(value)
            settings[categoryName].Enabled = value

            if not value then
                features.DestroyCategory(categoryName)
            end

            features.RefreshCategory(categoryName)
            setStatus(displayName .. " " .. (value and "enabled" or "disabled"))
            if settings.Notifications then
                window:Notify(displayName, value and "Category armed." or "Category disarmed.", 2.4)
            end
        end, {
            Description = "Toggle the entire " .. displayName .. " module",
        })

        tab:Dropdown(
            displayName .. " Feature Pack",
            config.FeatureOptions[categoryName],
            settings[categoryName].Features,
            function(selectedList)
                settings[categoryName].Features = selectedList
                features.RefreshCategory(categoryName)
                setStatus(displayName .. " feature map updated")
            end,
            {
                Multi = true,
                NoneValue = "No features",
            }
        )
    end

    for _, group in ipairs(CATEGORY_GROUPS) do
        entities:Divider(group.Title)
        addCategoryControls(entities, group.Key, group.Title, group.Description)
    end

    runtime:Divider("Automation")
    runtime:Toggle("Auto Refresh Loop", settings.AutoRefresh, function(value)
        settings.AutoRefresh = value
        setStatus("Auto refresh " .. (value and "enabled" or "disabled"))
    end, {
        Description = "Keep background refresh running for live ESP updates",
    })
    runtime:Button("Force Refresh Cycle", function()
        features.RefreshAll()
        setStatus("Forced one refresh cycle")
    end)
    runtime:Button("Clear All Drawings", function()
        features.DestroyAll()
        setStatus("Cleared all runtime visuals")
    end)

    runtime:Divider("Diagnostics")
    runtime:Label("Use search in the top-right to filter cards instantly.")
    runtime:Label("Runtime update interval: " .. tostring(config.UpdateInterval))
    runtime:Label("Default toggle key: " .. tostring(config.WindowToggleKey))

    settingsPage:Divider("Visual Stack")
    settingsPage:Dropdown("Theme Preset", { "Vanta", "Nebula", "Ember" }, settings.Theme, function(value)
        settings.Theme = value
        if UILibrary.SetTheme then
            UILibrary:SetTheme(value)
        end
        if window._ApplyTheme then
            window:_ApplyTheme(value)
        end
        setStatus("Theme switched to " .. tostring(value))
    end)
    settingsPage:Toggle("Notifications", settings.Notifications, function(value)
        settings.Notifications = value
        setStatus("Notifications " .. (value and "enabled" or "disabled"))
    end, {
        Description = "Show action toasts in the lower corner",
    })
    settingsPage:Toggle("Compact Mode", settings.CompactMode, function(value)
        settings.CompactMode = value
        setStatus("Compact mode flag set to " .. tostring(value))
    end, {
        Description = "Reserved for tighter card layouts in future modules",
    })

    info:Divider("Session")
    info:Label("Hub: VANTA Hub")
    info:Label("Game: Bite By Night")
    info:Label("Player: " .. tostring(ctx.Shared.LocalPlayer and ctx.Shared.LocalPlayer.Name or "Unknown"))
    info:Label("PlaceId: " .. tostring(game.PlaceId))
    info:Label("GameId: " .. tostring(game.GameId))

    info:Divider("Notes")
    info:Label("The Bite By Night module was migrated to the new VANTA card system.")
    info:Label("New game modules can reuse GameFactory + ui/wrappers/hub.lua for faster setup.")
    info:Label("The old flat wrapper styling was replaced by a tabbed control surface.")

    setStatus("ESP loaded")
    logger:Info("Built VANTA Bite By Night UI.")

    return {
        Window = window,
        SetStatus = setStatus,
    }
end

return UIBuilder
