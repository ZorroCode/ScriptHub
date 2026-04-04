local UIBuilder = {}

function UIBuilder.Create(ctx, config, settings, features)
    local logger = ctx.App.Logger
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

    local infoLabel = ctx.UI.Controls.CreateStatusLabel(tab, "Status: ESP loaded")

    local function setStatus(text)
        infoLabel:Set("Status: " .. tostring(text))
    end

    local function addCategory(categoryName, displayName)
        ctx.UI.Controls.CreateDivider(tab, displayName .. " ESP")

        ctx.UI.Controls.CreateToggle(
            tab,
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

        ctx.UI.Controls.CreateDropdown(
            tab,
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

    logger:Info("Built Bite By Night UI.")

    return {
        Window = window,
        Tab = tab,
        SetStatus = setStatus,
    }
end

return UIBuilder