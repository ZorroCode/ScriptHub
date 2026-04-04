local WindowWrapper = {}

function WindowWrapper.Create(uiLibrary, options)
    options = options or {}

    local title = options.Title or "Script Hub"
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightAlt

    return uiLibrary:CreateWindow(title, toggleKey)
end

return WindowWrapper