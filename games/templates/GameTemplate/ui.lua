local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local UILibrary = ctx.Loader:LoadUILibrary()

    local window = ctx.UI.Window.Create(UILibrary, {
        Title = config.WindowTitle,
        ToggleKey = config.WindowToggleKey,
    })

    local tab = ctx.UI.Tabs.Create(window, {
        Name = config.TabName,
        Icon = config.TabIcon,
        HeaderTitle = config.TabHeaderTitle,
        HeaderSubtitle = config.TabHeaderSubtitle,
    })

    local statusLabel = ctx.UI.Controls.CreateStatusLabel(tab, "Status: Ready")

    local function setStatus(text)
        statusLabel:Set("Status: " .. tostring(text))
    end

    local featureList = {}
    if type(config.GetFeatureList) == "function" then
        featureList = config.GetFeatureList()
    end

    for _, featureInfo in ipairs(featureList) do
        local key = featureInfo.Key
        local title = featureInfo.Title or key
        local description = featureInfo.Description

        ctx.UI.Controls.CreateDivider(tab, title)

        if description and description ~= "" then
            ctx.UI.Controls.CreateLabel(tab, description)
        end

        local current = settings[key]
        local defaultEnabled = current and current.Enabled == true or false

        ctx.UI.Controls.CreateToggle(
            tab,
            title .. " Enabled",
            defaultEnabled,
            function(value)
                settings[key].Enabled = value

                if not value and type(features.DestroyCategory) == "function" then
                    features.DestroyCategory(key)
                end

                if type(features.RefreshCategory) == "function" then
                    features.RefreshCategory(key)
                end

                setStatus(title .. " " .. (value and "enabled" or "disabled"))
            end
        )
    end

    ctx.UI.Controls.CreateDivider(tab, "Actions")

    ctx.UI.Controls.CreateButton(tab, "Refresh All", function()
        if type(features.RefreshAll) == "function" then
            features.RefreshAll()
        end

        setStatus("Manual refresh completed")
    end)

    ctx.UI.Controls.CreateButton(tab, "Destroy All", function()
        if type(features.DestroyAll) == "function" then
            features.DestroyAll()
        end

        setStatus("All features destroyed")
    end)

    return {
        Window = window,
        Tab = tab,
        SetStatus = setStatus,
    }
end

return UIBuilder