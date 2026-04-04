local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local UILibrary = ctx.Loader:LoadUILibrary()
    local window = UILibrary:CreateWindow(config.WindowTitle, config.WindowToggleKey)

    local tab = window:CreateTab(config.TabName, config.TabIcon)
    tab:SetHeader(config.TabHeaderTitle, config.TabHeaderSubtitle)

    local status = tab:Label("Status: Template loaded")

    tab:Divider("Example")

    tab:Toggle("Example Toggle", settings.Example.Enabled, function(value)
        settings.Example.Enabled = value
        features.RefreshAll()
        status:Set("Status: Example Toggle " .. (value and "enabled" or "disabled"))
    end)

    return {
        Window = window,
        Tab = tab,
    }
end

return UIBuilder