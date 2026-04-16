local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

Library.Themes = {
    Vanta = {
        Background = Color3.fromRGB(7, 10, 18),
        Surface = Color3.fromRGB(11, 16, 29),
        Surface2 = Color3.fromRGB(14, 22, 38),
        Sidebar = Color3.fromRGB(8, 13, 24),
        Card = Color3.fromRGB(12, 18, 31),
        CardAlt = Color3.fromRGB(15, 24, 40),
        Accent = Color3.fromRGB(0, 230, 255),
        Accent2 = Color3.fromRGB(126, 92, 255),
        Text = Color3.fromRGB(235, 244, 255),
        Muted = Color3.fromRGB(125, 145, 174),
        Border = Color3.fromRGB(58, 86, 125),
        Success = Color3.fromRGB(76, 220, 160),
        Danger = Color3.fromRGB(255, 98, 132),
    },
    Nebula = {
        Background = Color3.fromRGB(10, 8, 20),
        Surface = Color3.fromRGB(18, 13, 33),
        Surface2 = Color3.fromRGB(24, 17, 45),
        Sidebar = Color3.fromRGB(14, 10, 28),
        Card = Color3.fromRGB(20, 14, 36),
        CardAlt = Color3.fromRGB(26, 18, 48),
        Accent = Color3.fromRGB(255, 84, 183),
        Accent2 = Color3.fromRGB(122, 107, 255),
        Text = Color3.fromRGB(247, 238, 255),
        Muted = Color3.fromRGB(174, 156, 202),
        Border = Color3.fromRGB(97, 78, 137),
        Success = Color3.fromRGB(107, 215, 173),
        Danger = Color3.fromRGB(255, 111, 131),
    },
    Ember = {
        Background = Color3.fromRGB(16, 9, 10),
        Surface = Color3.fromRGB(27, 15, 16),
        Surface2 = Color3.fromRGB(40, 20, 20),
        Sidebar = Color3.fromRGB(22, 12, 14),
        Card = Color3.fromRGB(31, 17, 18),
        CardAlt = Color3.fromRGB(44, 22, 23),
        Accent = Color3.fromRGB(255, 106, 72),
        Accent2 = Color3.fromRGB(255, 182, 72),
        Text = Color3.fromRGB(255, 240, 236),
        Muted = Color3.fromRGB(200, 160, 150),
        Border = Color3.fromRGB(126, 73, 61),
        Success = Color3.fromRGB(98, 222, 164),
        Danger = Color3.fromRGB(255, 114, 114),
    }
}

Library.Theme = Library.Themes.Vanta

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft = UDim.new(0, px)
    p.PaddingRight = UDim.new(0, px)
    p.Parent = parent
    return p
end

local function gradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function makeLabel(parent, text, size, font, color, xalign)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextSize = size or 14
    lbl.Font = font or Enum.Font.Gotham
    lbl.TextColor3 = color or Library.Theme.Text
    lbl.TextXAlignment = xalign or Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Size = UDim2.new(1, 0, 0, size or 14)
    lbl.Parent = parent
    return lbl
end

local function makeButton(parent, text)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = text or ""
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.TextColor3 = Library.Theme.Text
    b.BackgroundColor3 = Library.Theme.CardAlt
    corner(b, 12)
    stroke(b, Library.Theme.Border, 0.35, 1)
    b.Parent = parent
    return b
end

local function isVisibleMatch(control, query)
    if query == "" then
        return true
    end

    return string.find(string.lower(control.SearchText or ""), query, 1, true) ~= nil
end

function Library:SetTheme(name)
    if self.Themes[name] then
        self.Theme = self.Themes[name]
    end
end

function Library:CreateWindow(title, toggleKey)
    local window = {
        _tabs = {},
        _currentTab = nil,
        _theme = self.Theme,
        _registry = {},
        _toggleKey = toggleKey or Enum.KeyCode.RightAlt,
        _minimized = false,
    }

    local theme = function(key)
        return window._theme[key]
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VantaHubUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui
    window.Gui = gui

    local shell = Instance.new("Frame")
    shell.Name = "Shell"
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.Position = UDim2.fromScale(0.5, 0.5)
    shell.Size = UDim2.fromOffset(1120, 720)
    shell.BackgroundColor3 = theme("Background")
    shell.Parent = gui
    corner(shell, 24)
    stroke(shell, theme("Border"), 0.25, 1)

    local glow = Instance.new("Frame")
    glow.BackgroundColor3 = theme("Accent")
    glow.BackgroundTransparency = 0.92
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.fromOffset(-10, -10)
    glow.ZIndex = 0
    glow.Parent = shell
    corner(glow, 28)

    local inner = Instance.new("Frame")
    inner.BackgroundColor3 = theme("Surface")
    inner.Size = UDim2.new(1, -18, 1, -18)
    inner.Position = UDim2.fromOffset(9, 9)
    inner.Parent = shell
    corner(inner, 20)
    stroke(inner, theme("Border"), 0.55, 1)

    local dragBar = Instance.new("Frame")
    dragBar.BackgroundTransparency = 1
    dragBar.Size = UDim2.new(1, 0, 0, 64)
    dragBar.Parent = inner

    local sidebar = Instance.new("Frame")
    sidebar.BackgroundColor3 = theme("Sidebar")
    sidebar.Size = UDim2.new(0, 248, 1, -18)
    sidebar.Position = UDim2.fromOffset(9, 9)
    sidebar.Parent = inner
    corner(sidebar, 18)
    stroke(sidebar, theme("Border"), 0.55, 1)

    local logoCard = Instance.new("Frame")
    logoCard.BackgroundColor3 = theme("Surface2")
    logoCard.Size = UDim2.new(1, -18, 0, 92)
    logoCard.Position = UDim2.fromOffset(9, 9)
    logoCard.Parent = sidebar
    corner(logoCard, 16)
    stroke(logoCard, theme("Border"), 0.45, 1)
    gradient(logoCard, theme("Surface2"), theme("CardAlt"), 45)

    local logo = Instance.new("TextLabel")
    logo.BackgroundColor3 = theme("Accent")
    logo.Size = UDim2.fromOffset(42, 42)
    logo.Position = UDim2.fromOffset(16, 16)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 26
    logo.Text = "V"
    logo.TextColor3 = Color3.new(1, 1, 1)
    logo.Parent = logoCard
    corner(logo, 12)
    local lg = gradient(logo, theme("Accent"), theme("Accent2"), 20)
    lg.Name = "LogoGradient"

    local titleLabel = makeLabel(logoCard, title or "VANTA Hub", 28, Enum.Font.GothamBlack, theme("Text"), Enum.TextXAlignment.Left)
    titleLabel.Position = UDim2.fromOffset(72, 14)
    titleLabel.Size = UDim2.new(1, -88, 0, 28)

    local subtitle = makeLabel(logoCard, "Adaptive exploit workspace", 13, Enum.Font.GothamMedium, theme("Muted"), Enum.TextXAlignment.Left)
    subtitle.Position = UDim2.fromOffset(72, 48)
    subtitle.Size = UDim2.new(1, -88, 0, 18)

    local placeLabel = makeLabel(sidebar, "PlaceId " .. tostring(game.PlaceId), 13, Enum.Font.GothamMedium, theme("Muted"), Enum.TextXAlignment.Left)
    placeLabel.Position = UDim2.fromOffset(16, 111)
    placeLabel.Size = UDim2.new(1, -32, 0, 18)

    local navHolder = Instance.new("ScrollingFrame")
    navHolder.BackgroundTransparency = 1
    navHolder.BorderSizePixel = 0
    navHolder.Size = UDim2.new(1, -18, 1, -230)
    navHolder.Position = UDim2.fromOffset(9, 136)
    navHolder.CanvasSize = UDim2.fromOffset(0, 0)
    navHolder.ScrollBarThickness = 2
    navHolder.ScrollBarImageColor3 = theme("Accent")
    navHolder.Parent = sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 8)
    navLayout.Parent = navHolder
    navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        navHolder.CanvasSize = UDim2.fromOffset(0, navLayout.AbsoluteContentSize.Y + 8)
    end)

    local footer = Instance.new("Frame")
    footer.BackgroundColor3 = theme("Surface2")
    footer.Size = UDim2.new(1, -18, 0, 76)
    footer.Position = UDim2.new(0, 9, 1, -85)
    footer.Parent = sidebar
    corner(footer, 16)
    stroke(footer, theme("Border"), 0.5, 1)

    local keyTitle = makeLabel(footer, "Toggle Interface", 13, Enum.Font.GothamBold, theme("Text"), Enum.TextXAlignment.Left)
    keyTitle.Position = UDim2.fromOffset(14, 12)
    keyTitle.Size = UDim2.new(1, -28, 0, 18)

    local keyValue = makeLabel(footer, tostring(window._toggleKey), 12, Enum.Font.Code, theme("Muted"), Enum.TextXAlignment.Left)
    keyValue.Position = UDim2.fromOffset(14, 34)
    keyValue.Size = UDim2.new(1, -28, 0, 18)

    local topbar = Instance.new("Frame")
    topbar.BackgroundTransparency = 1
    topbar.Size = UDim2.new(1, -276, 0, 64)
    topbar.Position = UDim2.fromOffset(266, 12)
    topbar.Parent = inner

    local pageTitle = makeLabel(topbar, "Overview", 26, Enum.Font.GothamBlack, theme("Text"), Enum.TextXAlignment.Left)
    pageTitle.Size = UDim2.new(1, -350, 0, 30)
    pageTitle.Position = UDim2.fromOffset(4, 2)

    local pageSubtitle = makeLabel(topbar, "", 13, Enum.Font.GothamMedium, theme("Muted"), Enum.TextXAlignment.Left)
    pageSubtitle.Size = UDim2.new(1, -350, 0, 18)
    pageSubtitle.Position = UDim2.fromOffset(4, 32)

    local search = Instance.new("TextBox")
    search.ClearTextOnFocus = false
    search.PlaceholderText = "Search current page"
    search.Text = ""
    search.TextSize = 14
    search.Font = Enum.Font.GothamMedium
    search.TextColor3 = theme("Text")
    search.PlaceholderColor3 = theme("Muted")
    search.BackgroundColor3 = theme("Card")
    search.Size = UDim2.fromOffset(290, 42)
    search.Position = UDim2.new(1, -382, 0, 6)
    search.Parent = topbar
    corner(search, 12)
    padding(search, 0)
    stroke(search, theme("Border"), 0.4, 1)

    local minimize = makeButton(topbar, "—")
    minimize.Size = UDim2.fromOffset(42, 42)
    minimize.Position = UDim2.new(1, -86, 0, 6)

    local close = makeButton(topbar, "✕")
    close.Size = UDim2.fromOffset(42, 42)
    close.Position = UDim2.new(1, -40, 0, 6)

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -276, 1, -96)
    content.Position = UDim2.fromOffset(266, 82)
    content.Parent = inner

    local pageContainer = Instance.new("Folder")
    pageContainer.Name = "Pages"
    pageContainer.Parent = content

    local notifyHolder = Instance.new("Frame")
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Size = UDim2.fromOffset(320, 280)
    notifyHolder.Position = UDim2.new(1, -332, 1, -292)
    notifyHolder.Parent = inner

    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.Padding = UDim.new(0, 8)
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyLayout.Parent = notifyHolder

    local dragging, dragStart, startPos
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = shell.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    function window:_ApplyTheme(newThemeName)
        if Library.Themes[newThemeName] then
            window._theme = Library.Themes[newThemeName]
        end
        local t = window._theme
        shell.BackgroundColor3 = t.Background
        glow.BackgroundColor3 = t.Accent
        inner.BackgroundColor3 = t.Surface
        sidebar.BackgroundColor3 = t.Sidebar
        logoCard.BackgroundColor3 = t.Surface2
        titleLabel.TextColor3 = t.Text
        subtitle.TextColor3 = t.Muted
        placeLabel.TextColor3 = t.Muted
        footer.BackgroundColor3 = t.Surface2
        keyTitle.TextColor3 = t.Text
        keyValue.TextColor3 = t.Muted
        pageTitle.TextColor3 = t.Text
        pageSubtitle.TextColor3 = t.Muted
        search.BackgroundColor3 = t.Card
        search.TextColor3 = t.Text
        search.PlaceholderColor3 = t.Muted
        lg.Color = ColorSequence.new(t.Accent, t.Accent2)
        logo.BackgroundColor3 = t.Accent
        for _, record in ipairs(window._registry) do
            pcall(record)
        end
        for _, tab in ipairs(window._tabs) do
            if tab._refreshTheme then
                tab:_refreshTheme()
            end
        end
    end

    function window:_RegisterThemeCallback(callback)
        table.insert(self._registry, callback)
    end

    function window:Notify(titleText, bodyText, duration)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = theme("Card")
        card.BackgroundTransparency = 0.06
        card.Parent = notifyHolder
        corner(card, 14)
        stroke(card, theme("Border"), 0.45, 1)
        gradient(card, theme("Card"), theme("CardAlt"), 0)

        local accent = Instance.new("Frame")
        accent.BackgroundColor3 = theme("Accent")
        accent.Size = UDim2.new(0, 4, 1, -16)
        accent.Position = UDim2.fromOffset(8, 8)
        accent.Parent = card
        corner(accent, 4)

        local heading = makeLabel(card, titleText or "VANTA", 15, Enum.Font.GothamBold, theme("Text"), Enum.TextXAlignment.Left)
        heading.Position = UDim2.fromOffset(22, 10)
        heading.Size = UDim2.new(1, -34, 0, 20)

        local body = makeLabel(card, bodyText or "", 13, Enum.Font.GothamMedium, theme("Muted"), Enum.TextXAlignment.Left)
        body.Position = UDim2.fromOffset(22, 34)
        body.Size = UDim2.new(1, -34, 0, 34)

        tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 78)})
        task.delay(duration or 3.5, function()
            if card.Parent then
                tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
                task.wait(0.22)
                if card then card:Destroy() end
            end
        end)
    end

    function window:_UpdateSearch()
        local q = string.lower(search.Text or "")
        local current = self._currentTab
        if not current then return end
        for _, control in ipairs(current._controls) do
            control.Frame.Visible = isVisibleMatch(control, q)
        end
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        window:_UpdateSearch()
    end)

    function window:_SelectTab(tab)
        for _, item in ipairs(self._tabs) do
            item.Page.Visible = item == tab
            local active = item == tab
            tween(item.Nav, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
                BackgroundColor3 = active and self._theme.Accent or self._theme.Card,
                BackgroundTransparency = active and 0.04 or 0.2,
            })
            item.NavTitle.TextColor3 = active and Color3.new(1,1,1) or self._theme.Text
            item.NavDesc.TextColor3 = active and Color3.fromRGB(225,240,255) or self._theme.Muted
        end
        self._currentTab = tab
        pageTitle.Text = tab.HeaderTitle or tab.Name
        pageSubtitle.Text = tab.HeaderSubtitle or ""
        search.Text = ""
        self:_UpdateSearch()
    end

    function window:CreateTab(name, icon)
        local tab = {
            Name = name or "Page",
            Icon = icon or "",
            HeaderTitle = name or "Page",
            HeaderSubtitle = "",
            _controls = {},
        }

        local nav = Instance.new("TextButton")
        nav.AutoButtonColor = false
        nav.Text = ""
        nav.Size = UDim2.new(1, -2, 0, 62)
        nav.BackgroundColor3 = theme("Card")
        nav.BackgroundTransparency = 0.2
        nav.Parent = navHolder
        corner(nav, 14)
        stroke(nav, theme("Border"), 0.45, 1)

        local badge = Instance.new("TextLabel")
        badge.BackgroundColor3 = theme("Surface2")
        badge.Size = UDim2.fromOffset(36, 36)
        badge.Position = UDim2.fromOffset(12, 13)
        badge.Font = Enum.Font.GothamBlack
        badge.TextSize = 16
        badge.TextColor3 = theme("Text")
        badge.Text = string.sub(name or "?", 1, 1)
        badge.Parent = nav
        corner(badge, 10)
        gradient(badge, theme("Accent"), theme("Accent2"), 35)

        local navTitle = makeLabel(nav, tab.Name, 15, Enum.Font.GothamBold, theme("Text"), Enum.TextXAlignment.Left)
        navTitle.Position = UDim2.fromOffset(58, 11)
        navTitle.Size = UDim2.new(1, -68, 0, 18)

        local navDesc = makeLabel(nav, "Open module", 12, Enum.Font.GothamMedium, theme("Muted"), Enum.TextXAlignment.Left)
        navDesc.Position = UDim2.fromOffset(58, 31)
        navDesc.Size = UDim2.new(1, -68, 0, 16)

        local page = Instance.new("ScrollingFrame")
        page.Name = tab.Name
        page.Visible = false
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = theme("Accent")
        page.Size = UDim2.fromScale(1, 1)
        page.CanvasSize = UDim2.fromOffset(0, 0)
        page.Parent = content

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 12)
        pageLayout.Parent = page
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 10)
        end)

        local tabObj = {
            Name = tab.Name,
            Nav = nav,
            NavTitle = navTitle,
            NavDesc = navDesc,
            Page = page,
            _controls = tab._controls,
            HeaderTitle = tab.HeaderTitle,
            HeaderSubtitle = tab.HeaderSubtitle,
        }

        function tabObj:_refreshTheme()
            local t = window._theme
            nav.BackgroundColor3 = t.Card
            navTitle.TextColor3 = t.Text
            navDesc.TextColor3 = t.Muted
            badge.TextColor3 = t.Text
            page.ScrollBarImageColor3 = t.Accent
        end

        function tabObj:_addControl(frame, searchText)
            table.insert(self._controls, {Frame = frame, SearchText = searchText or ""})
            return frame
        end

        function tabObj:SetHeader(head, sub)
            self.HeaderTitle = head or self.Name
            self.HeaderSubtitle = sub or ""
            navDesc.Text = self.HeaderSubtitle ~= "" and self.HeaderSubtitle or "Open module"
            if window._currentTab == self then
                pageTitle.Text = self.HeaderTitle
                pageSubtitle.Text = self.HeaderSubtitle
            end
        end

        local function makeCard(height)
            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = window._theme.Card
            frame.Size = UDim2.new(1, -8, 0, height)
            frame.Parent = page
            corner(frame, 16)
            stroke(frame, window._theme.Border, 0.45, 1)
            gradient(frame, window._theme.Card, window._theme.CardAlt, 0)
            return frame
        end

        function tabObj:Label(text)
            local card = makeCard(56)
            local label = makeLabel(card, text or "", 14, Enum.Font.GothamMedium, window._theme.Text, Enum.TextXAlignment.Left)
            label.Position = UDim2.fromOffset(16, 12)
            label.Size = UDim2.new(1, -32, 0, 32)
            self:_addControl(card, text or "")
            return {
                Set = function(_, nextText)
                    label.Text = tostring(nextText)
                end,
                Raw = label,
            }
        end

        function tabObj:Divider(text)
            local card = makeCard(48)
            local line = Instance.new("Frame")
            line.BackgroundColor3 = window._theme.Accent
            line.Size = UDim2.new(0, 4, 1, -16)
            line.Position = UDim2.fromOffset(10, 8)
            line.Parent = card
            corner(line, 4)
            local label = makeLabel(card, text or "SECTION", 15, Enum.Font.GothamBold, window._theme.Text, Enum.TextXAlignment.Left)
            label.Position = UDim2.fromOffset(24, 12)
            label.Size = UDim2.new(1, -32, 0, 20)
            self:_addControl(card, text or "")
            return card
        end

        function tabObj:Button(text, callback)
            local card = makeCard(64)
            local btn = makeButton(card, text or "Execute")
            btn.Size = UDim2.new(1, -24, 1, -20)
            btn.Position = UDim2.fromOffset(12, 10)
            gradient(btn, window._theme.CardAlt, window._theme.Surface2, 0)
            btn.MouseButton1Click:Connect(function()
                if callback then
                    task.spawn(callback)
                end
            end)
            self:_addControl(card, text or "")
            return btn
        end

        function tabObj:Toggle(text, default, callback, extra)
            local state = default == true
            local card = makeCard(72)
            local label = makeLabel(card, text or "Toggle", 15, Enum.Font.GothamBold, window._theme.Text, Enum.TextXAlignment.Left)
            label.Position = UDim2.fromOffset(16, 12)
            label.Size = UDim2.new(1, -120, 0, 20)
            local sub = makeLabel(card, extra and extra.Description or (state and "Enabled" or "Disabled"), 12, Enum.Font.GothamMedium, window._theme.Muted, Enum.TextXAlignment.Left)
            sub.Position = UDim2.fromOffset(16, 36)
            sub.Size = UDim2.new(1, -120, 0, 16)

            local toggle = Instance.new("TextButton")
            toggle.AutoButtonColor = false
            toggle.Text = ""
            toggle.Size = UDim2.fromOffset(64, 32)
            toggle.Position = UDim2.new(1, -80, 0, 20)
            toggle.BackgroundColor3 = state and window._theme.Accent or window._theme.Surface2
            toggle.Parent = card
            corner(toggle, 16)
            stroke(toggle, window._theme.Border, 0.4, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(24, 24)
            knob.Position = state and UDim2.fromOffset(36, 4) or UDim2.fromOffset(4, 4)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.Parent = toggle
            corner(knob, 12)

            local function set(val)
                state = val == true
                tween(toggle, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = state and window._theme.Accent or window._theme.Surface2,
                })
                tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                    Position = state and UDim2.fromOffset(36, 4) or UDim2.fromOffset(4, 4),
                })
                sub.Text = extra and extra.Description or (state and "Enabled" or "Disabled")
                if callback then
                    task.spawn(callback, state)
                end
            end

            toggle.MouseButton1Click:Connect(function()
                set(not state)
            end)

            self:_addControl(card, text or "")
            return {
                Set = function(_, val) set(val) end,
                Get = function() return state end,
            }
        end

        function tabObj:Dropdown(text, options, defaultValue, callback, extra)
            local multi = extra and extra.Multi == true
            local selected = {}
            if multi and type(defaultValue) == "table" then
                for _, value in ipairs(defaultValue) do
                    selected[value] = true
                end
            elseif not multi and defaultValue ~= nil then
                selected[defaultValue] = true
            end

            local card = makeCard(58)
            local open = false
            local header = makeButton(card, "")
            header.Size = UDim2.new(1, -20, 0, 38)
            header.Position = UDim2.fromOffset(10, 10)

            local headTitle = makeLabel(header, text or "Select", 14, Enum.Font.GothamSemibold, window._theme.Text, Enum.TextXAlignment.Left)
            headTitle.Position = UDim2.fromOffset(14, 10)
            headTitle.Size = UDim2.new(1, -110, 0, 18)

            local summary = makeLabel(header, "", 12, Enum.Font.GothamMedium, window._theme.Muted, Enum.TextXAlignment.Right)
            summary.Position = UDim2.fromOffset(140, 10)
            summary.Size = UDim2.new(1, -172, 0, 18)
            summary.TextXAlignment = Enum.TextXAlignment.Right

            local arrow = makeLabel(header, "⌄", 16, Enum.Font.GothamBold, window._theme.Text, Enum.TextXAlignment.Right)
            arrow.Position = UDim2.new(1, -32, 0, 8)
            arrow.Size = UDim2.fromOffset(18, 18)

            local list = Instance.new("Frame")
            list.BackgroundTransparency = 1
            list.Visible = false
            list.Size = UDim2.new(1, -20, 0, 0)
            list.Position = UDim2.fromOffset(10, 54)
            list.Parent = card

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 8)
            listLayout.Parent = list

            local function getValuesArray()
                local values = {}
                for _, option in ipairs(options or {}) do
                    if selected[option] then
                        table.insert(values, option)
                    end
                end
                return values
            end

            local function refreshSummary()
                local values = getValuesArray()
                if #values == 0 then
                    summary.Text = extra and extra.NoneValue or "None"
                elseif multi then
                    summary.Text = table.concat(values, ", ")
                else
                    summary.Text = values[1]
                end
            end

            local function emit()
                if callback then
                    if multi then
                        callback(getValuesArray())
                    else
                        callback(getValuesArray()[1])
                    end
                end
            end

            for _, option in ipairs(options or {}) do
                local opt = makeButton(list, option)
                opt.Size = UDim2.new(1, 0, 0, 36)
                opt.BackgroundColor3 = selected[option] and window._theme.Accent or window._theme.Surface2
                opt.TextColor3 = selected[option] and Color3.new(1, 1, 1) or window._theme.Text
                opt.MouseButton1Click:Connect(function()
                    if multi then
                        selected[option] = not selected[option]
                        opt.BackgroundColor3 = selected[option] and window._theme.Accent or window._theme.Surface2
                        opt.TextColor3 = selected[option] and Color3.new(1,1,1) or window._theme.Text
                    else
                        selected = {[option] = true}
                        for _, child in ipairs(list:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.BackgroundColor3 = window._theme.Surface2
                                child.TextColor3 = window._theme.Text
                            end
                        end
                        opt.BackgroundColor3 = window._theme.Accent
                        opt.TextColor3 = Color3.new(1,1,1)
                        open = false
                        list.Visible = false
                        card.Size = UDim2.new(1, -8, 0, 58)
                    end
                    refreshSummary()
                    emit()
                end)
            end

            local function applyOpen(nextState)
                open = nextState
                list.Visible = open
                arrow.Text = open and "⌃" or "⌄"
                local newHeight = 58
                if open then
                    local count = #options
                    newHeight = 58 + (count * 44)
                end
                card.Size = UDim2.new(1, -8, 0, newHeight)
                list.Size = UDim2.new(1, -20, 0, math.max(0, newHeight - 66))
            end

            header.MouseButton1Click:Connect(function()
                applyOpen(not open)
            end)

            refreshSummary()
            self:_addControl(card, (text or "") .. " " .. table.concat(options or {}, " "))
            return {
                Set = function(_, values)
                    selected = {}
                    if multi and type(values) == "table" then
                        for _, v in ipairs(values) do selected[v] = true end
                    else
                        selected[values] = true
                    end
                    refreshSummary()
                    emit()
                end,
                Get = function()
                    return multi and getValuesArray() or getValuesArray()[1]
                end,
            }
        end

        nav.MouseButton1Click:Connect(function()
            window:_SelectTab(tabObj)
        end)

        table.insert(window._tabs, tabObj)
        if not window._currentTab then
            window:_SelectTab(tabObj)
        end
        return tabObj
    end

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    minimize.MouseButton1Click:Connect(function()
        window._minimized = not window._minimized
        content.Visible = not window._minimized
        sidebar.Visible = not window._minimized
        tween(shell, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = window._minimized and UDim2.fromOffset(520, 84) or UDim2.fromOffset(1120, 720),
        })
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == window._toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    return window
end

return Library
