local Tabs = {}

function Tabs.Create(window, options)
    options = options or {}

    local name = options.Name or "Main"
    local icon = options.Icon or ""
    local headerTitle = options.HeaderTitle or name
    local headerSubtitle = options.HeaderSubtitle or ""

    local tab = window:CreateTab(name, icon)
    tab:SetHeader(headerTitle, headerSubtitle)

    return tab
end

return Tabs