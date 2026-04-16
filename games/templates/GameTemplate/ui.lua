local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local hub, window = ctx.Core.GameFactory.CreatePagedWindow(ctx, config, {
        {
            Key = "Overview",
            Name = "Overview",
            HeaderTitle = config.TabHeaderTitle or "VANTA",
            HeaderSubtitle = config.TabHeaderSubtitle or "Template game module",
        },
        {
            Key = "Features",
            Name = "Features",
            HeaderTitle = "Feature Controls",
            HeaderSubtitle = "Fast scaffold for new game integrations",
        },
        {
            Key = "Settings",
            Name = "Settings",
            HeaderTitle = "Settings",
            HeaderSubtitle = "Theme and runtime controls",
        },
    })

    local overview = hub.Pages.Overview
    local featurePage = hub.Pages.Features
    local settingsPage = hub.Pages.Settings

    local statusLabel = overview:Label("Status: Ready")

    local function setStatus(text)
        statusLabel:Set("Status: " .. tostring(text))
    end

    overview:Divider("Template Notes")
    overview:Label("Use this module as the base when wiring a new supported game.")
    overview:Label("GameFactory handles refresh loop, cleanup, and character refresh hooks.")
    overview:Label("ui/wrappers/hub.lua handles multi-page layout creation.")

    local featureList = {}
    if type(config.GetFeatureList) == "function" then
        featureList = config.GetFeatureList()
    end

    featurePage:Divider("Feature Toggles")
    for _, featureInfo in ipairs(featureList) do
        local key = featureInfo.Key
        local title = featureInfo.Title or key
        local description = featureInfo.Description or ""

        featurePage:Label(description)
        featurePage:Toggle(title .. " Enabled", settings[key] and settings[key].Enabled == true, function(value)
            settings[key].Enabled = value

            if not value and type(features.DestroyCategory) == "function" then
                features.DestroyCategory(key)
            end

            if type(features.RefreshCategory) == "function" then
                features.RefreshCategory(key)
            end

            setStatus(title .. " " .. (value and "enabled" or "disabled"))
        end)
    end

    featurePage:Button("Refresh All", function()
        if type(features.RefreshAll) == "function" then
            features.RefreshAll()
        end
        setStatus("Manual refresh completed")
    end)

    settingsPage:Divider("Runtime")
    settingsPage:Toggle("Auto Refresh", settings.AutoRefresh ~= false, function(value)
        settings.AutoRefresh = value
        setStatus("Auto refresh " .. (value and "enabled" or "disabled"))
    end)
    settingsPage:Dropdown("Theme Preset", { "Vanta", "Nebula", "Ember" }, settings.Theme or "Vanta", function(value)
        settings.Theme = value
        local uiLibrary = ctx.Loader:LoadUILibrary()
        uiLibrary:SetTheme(value)
        if window._ApplyTheme then
            window:_ApplyTheme(value)
        end
        setStatus("Theme changed to " .. tostring(value))
    end)

    return {
        Window = window,
        SetStatus = setStatus,
    }
end

return UIBuilder
