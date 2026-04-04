local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local UILibrary = ctx.Loader:LoadUILibrary()
    local window = UILibrary:CreateWindow(config.WindowTitle, config.WindowToggleKey)

    local tab = window:CreateTab(config.TabName, config.TabIcon)
    tab:SetHeader(config.TabHeaderTitle, config.TabHeaderSubtitle)

    local infoLabel = tab:Label("Status: ESP loaded")

    local function setStatus(text)
        infoLabel:Set("Status: " .. tostring(text))
    end

    local function addCategory(categoryName, displayName)
        tab:Divider(displayName .. " ESP")

        tab:Toggle(
            displayName .. " ESP",
            settings[categoryName].Enabled,
            function(value)
                settings[categoryName].Enabled = value

                if not value then
                    features.DestroyCategory(categoryName)
                end

                features.RefreshCategory(categoryName)
                setStatus(displayName .. " ESP " .. (value and "enabled" or "disabled"))
            end,
            {
                Keybind = config.DefaultESPKeybind,
            }
        )

        tab:Dropdown(
            displayName .. " Features",
            config.FeatureOptions[categoryName],
            settings[categoryName].Features,
            function(selectedList)
                settings[categoryName].Features = selectedList
                features.RefreshCategory(categoryName)
            end,
            {
                Multi = true,
                NoneValue = "None",
                PrioritySelection = false,
            }
        )
    end

    addCategory("Player", "Player")
    addCategory("Killer", "Killer")
    addCategory("Generator", "Generator")
    addCategory("Battery", "Battery")
    addCategory("Fuse", "Fuse")
    addCategory("Trap", "Trap")

    return {
        Window = window,
        Tab = tab,
        SetStatus = setStatus,
    }
end

return UIBuilder