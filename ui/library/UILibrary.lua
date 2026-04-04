--// Neon Gaming UI Library (Revamp / Recode) - FULLY UPDATED
--// Style: sharp, layered, neon-accent “command console”
--// API:
--//   local UI = loadstring(game:HttpGet(url))()
--//   local Win = UI:CreateWindow("Title", Enum.KeyCode.RightAlt)
--//   local Tab = Win:CreateTab("Fish", "rbxassetid://ICON") -- icon optional
--//   Tab:Label / Divider / Button / Toggle / Slider / Dropdown / Textbox / ColorPicker
--//
--// Fixes preserved:
--//   - Dropdown search/clear header is clickable (no click-through)
--//   - Settings/Close overlays are TRUE modal (no interacting behind)
--//   - On close: all toggles forced OFF (their callbacks fire) before UI destroy
--//
--// NEW changes in this version:
--//   1) Hero header height reduced (less vertical space)
--//   2) Rainbow mode now correctly recolors ON toggles/switches (no “turns black”)
--//      - Adds a small ThemeSync system so toggles can re-sync after theme changes
--//   3) Dropdown: optional PrioritySelection (multi) => shows selected values in click order
--//   4) Toggle keybind: Backspace clears/unbinds while rebinding (Escape cancels)

local Library = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Theme
Library.Theme = {
    -- Base
    Background = Color3.fromRGB(10, 10, 14),
    Surface    = Color3.fromRGB(18, 18, 26),
    Panel      = Color3.fromRGB(22, 22, 34),
    Card       = Color3.fromRGB(16, 16, 26),

    -- Text
    Text       = Color3.fromRGB(245, 245, 255),
    Muted      = Color3.fromRGB(170, 170, 190),

    -- Accent (purple default)
    Accent     = Color3.fromRGB(176, 66, 255),

    -- Lines / strokes
    StrokeDark = Color3.fromRGB(0, 0, 0),
    StrokeLite = Color3.fromRGB(80, 80, 110),
}

-- Optional art (disabled)
Library.Assets = {
    UseGlowImages = false,
    GlowSoft      = nil,
    Shadow        = nil,
}

-- =========================================================
-- Helpers
-- =========================================================
local function clamp(n, mn, mx)
    n = tonumber(n) or mn
    if n < mn then return mn end
    if n > mx then return mx end
    return n
end

local function snap(n, step)
    step = step or 1
    if step <= 0 then step = 1 end
    return math.floor((n / step) + 0.5) * step
end

local function roundToInt(n)
    return math.floor((tonumber(n) or 0) + 0.5)
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =========================================================
-- Maid
-- =========================================================
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({ _tasks = {} }, Maid) end

function Maid:Give(task)
    table.insert(self._tasks, task); return task
end

function Maid:DoCleaning()
    for i = #self._tasks, 1, -1 do
        local t = self._tasks[i]
        self._tasks[i] = nil
        local tt = typeof(t)
        if tt == "RBXScriptConnection" then
            pcall(function() t:Disconnect() end)
        elseif tt == "Instance" then
            pcall(function() t:Destroy() end)
        elseif tt == "function" then
            pcall(t)
        elseif tt == "table" and type(t.Destroy) == "function" then
            pcall(function() t:Destroy() end)
        end
    end
end

-- =========================================================
-- Theme binder + ThemeSync
-- =========================================================
local function ThemeBinder(window)
    window._themeBindings = {}

    function window:_BindTheme(obj, prop, key)
        table.insert(self._themeBindings, { obj = obj, prop = prop, key = key })
        pcall(function() obj[prop] = Library.Theme[key] end)
    end

    function window:_ApplyTheme()
        for _, b in ipairs(self._themeBindings) do
            if b.obj and b.obj.Parent then
                pcall(function() b.obj[b.prop] = Library.Theme[b.key] end)
            end
        end

        if self._selectedTabButton and self._selectedTabButton.Parent then
            pcall(function()
                self._selectedTabButton.BackgroundColor3 = Library.Theme.Accent
                self._selectedTabButton.TextColor3 = Color3.new(1, 1, 1)
            end)
        end

        -- NEW: theme sync callbacks (toggles, switches, etc.)
        if self._themeSyncs then
            for _, fn in ipairs(self._themeSyncs) do
                pcall(fn)
            end
        end
    end
end

-- =========================================================
-- Styling primitives (the “revamp” part)
-- =========================================================
local function addCorner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = inst
    return c
end

local function addStroke(inst, thickness, color, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Color = color or Color3.new(1, 1, 1)
    s.Transparency = transparency ~= nil and transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = inst
    return s
end

local function addGradient(inst, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c0),
        ColorSequenceKeypoint.new(1, c1),
    })
    g.Rotation = rot or 90
    g.Parent = inst
    return g
end

local function addSoftGlowBehind(parent, bindThemeFn, accentKey)
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 0.82
    glow.ZIndex = parent.ZIndex - 1
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.Parent = parent
    addCorner(glow, 14)

    if Library.Assets.UseGlowImages and Library.Assets.GlowSoft then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Image = Library.Assets.GlowSoft
        img.ImageTransparency = 0.4
        img.ScaleType = Enum.ScaleType.Slice
        img.SliceCenter = Rect.new(16, 16, 240, 240)
        img.Size = UDim2.new(1, 40, 1, 40)
        img.Position = UDim2.new(0, -20, 0, -20)
        img.ZIndex = glow.ZIndex
        img.Parent = glow
    end

    if bindThemeFn then
        bindThemeFn(glow, "BackgroundColor3", accentKey or "Accent")
    else
        glow.BackgroundColor3 = Library.Theme.Accent
    end
    return glow
end

local function mkCard(container, window, height)
    local cardWrap = Instance.new("Frame")
    cardWrap.BackgroundTransparency = 1
    cardWrap.Size = UDim2.new(1, -10, 0, height)
    cardWrap.Parent = container

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromScale(1, 1)
    card.BackgroundColor3 = Library.Theme.Card
    card.Parent = cardWrap
    addCorner(card, 12)
    window:_BindTheme(card, "BackgroundColor3", "Card")

    addStroke(card, 1, Library.Theme.StrokeDark, 0.35)
    window:_BindTheme(card.UIStroke, "Color", "StrokeDark")

    local inner = addStroke(card, 1, Library.Theme.StrokeLite, 0.72)
    inner.Name = "InnerStroke"
    inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    window:_BindTheme(inner, "Color", "StrokeLite")

    addSoftGlowBehind(card, function(obj, prop, key) window:_BindTheme(obj, prop, key) end, "Accent").Visible = false

    return cardWrap, card
end

local function mkPillSwitch(window, parent)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(56, 24)
    sw.BackgroundColor3 = Library.Theme.Surface
    sw.Parent = parent
    addCorner(sw, 999)
    window:_BindTheme(sw, "BackgroundColor3", "Surface")
    addStroke(sw, 1, Library.Theme.StrokeLite, 0.75).Name = "Stroke"
    window:_BindTheme(sw.Stroke, "Color", "StrokeLite")

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Library.Theme.Muted
    knob.Parent = sw
    addCorner(knob, 999)
    window:_BindTheme(knob, "BackgroundColor3", "Muted")

    local glow = addSoftGlowBehind(sw, function(obj, prop, key) window:_BindTheme(obj, prop, key) end, "Accent")
    glow.BackgroundTransparency = 0.86
    glow.Visible = false

    return sw, knob, glow
end

-- =========================================================
-- Window
-- =========================================================
function Library:CreateWindow(title, toggleKey)
    local Window = {}
    Window._maid = Maid.new()
    Window._tabButtons = {}
    Window._closed = false
    Window._minimized = false
    Window._rainbow = false
    Window._rainbowConn = nil
    Window._toggleControllers = {}

    ThemeBinder(Window)

    -- NEW: Theme sync system (for controls that depend on Accent/Surface at runtime)
    Window._themeSyncs = {}
    function Window:_AddThemeSync(fn)
        table.insert(self._themeSyncs, fn)
    end

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeonUILibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = CoreGui
    Window._maid:Give(ScreenGui)

    -- Main shell
    local Main = Instance.new("Frame")
    Main.Size = UDim2.fromOffset(760, 460)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Parent = ScreenGui
    addCorner(Main, 16)
    Window:_BindTheme(Main, "BackgroundColor3", "Background")
    addStroke(Main, 1, Library.Theme.StrokeDark, 0.25).Name = "MainStroke"
    Window:_BindTheme(Main.MainStroke, "Color", "StrokeDark")

    -- Inner panel (for layered depth)
    local Inner = Instance.new("Frame")
    Inner.Size = UDim2.new(1, -16, 1, -16)
    Inner.Position = UDim2.fromOffset(8, 8)
    Inner.Parent = Main
    addCorner(Inner, 14)
    Window:_BindTheme(Inner, "BackgroundColor3", "Panel")
    addStroke(Inner, 1, Library.Theme.StrokeLite, 0.78).Name = "InnerStroke"
    Window:_BindTheme(Inner.InnerStroke, "Color", "StrokeLite")

    -- Topbar (beveled)
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 54)
    TopBar.Parent = Inner
    addCorner(TopBar, 14)
    Window:_BindTheme(TopBar, "BackgroundColor3", "Surface")
    addStroke(TopBar, 1, Library.Theme.StrokeDark, 0.4).Name = "TopStroke"
    Window:_BindTheme(TopBar.TopStroke, "Color", "StrokeDark")

    -- Accent line
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(1, -24, 0, 2)
    AccentLine.Position = UDim2.fromOffset(12, 52)
    AccentLine.BorderSizePixel = 0
    AccentLine.Parent = TopBar
    Window:_BindTheme(AccentLine, "BackgroundColor3", "Accent")
    AccentLine.BackgroundTransparency = 0.2

    -- Branding
    local Brand = Instance.new("TextLabel")
    Brand.Size = UDim2.new(1, -170, 1, 0)
    Brand.Position = UDim2.fromOffset(16, 0)
    Brand.BackgroundTransparency = 1
    Brand.TextXAlignment = Enum.TextXAlignment.Left
    Brand.Text = (title or "BRAND")
    Brand.Font = Enum.Font.GothamBlack
    Brand.TextSize = 22
    Brand.Parent = TopBar
    Window:_BindTheme(Brand, "TextColor3", "Text")

    -- Top right buttons
    local function mkTopBtn(text, xOffset)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(38, 32)
        b.Position = UDim2.new(1, xOffset, 0, 11)
        b.Text = text
        b.Font = Enum.Font.GothamBlack
        b.TextSize = 16
        b.AutoButtonColor = false
        b.Parent = TopBar
        addCorner(b, 10)
        Window:_BindTheme(b, "BackgroundColor3", "Panel")
        Window:_BindTheme(b, "TextColor3", "Text")
        addStroke(b, 1, Library.Theme.StrokeLite, 0.78).Name = "Stroke"
        Window:_BindTheme(b.Stroke, "Color", "StrokeLite")
        return b
    end

    local CloseBtn = mkTopBtn("X", -50)
    local MinBtn   = mkTopBtn("—", -92)
    local SetBtn   = mkTopBtn("⚙", -134)

    MakeDraggable(Main, TopBar)

    -- Layout areas
    local Body = Instance.new("Frame")
    Body.BackgroundTransparency = 1
    Body.Size = UDim2.new(1, 0, 1, -64)
    Body.Position = UDim2.fromOffset(0, 64)
    Body.Parent = Inner

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 190, 1, 0)
    Sidebar.Parent = Body
    addCorner(Sidebar, 12)
    Window:_BindTheme(Sidebar, "BackgroundColor3", "Surface")
    addStroke(Sidebar, 1, Library.Theme.StrokeDark, 0.45).Name = "SideStroke"
    Window:_BindTheme(Sidebar.SideStroke, "Color", "StrokeDark")

    local ContentWrap = Instance.new("Frame")
    ContentWrap.Size = UDim2.new(1, -200, 1, 0)
    ContentWrap.Position = UDim2.fromOffset(200, 0)
    ContentWrap.BackgroundTransparency = 1
    ContentWrap.Parent = Body

    -- Sidebar layout
    local SidePad = Instance.new("UIPadding", Sidebar)
    SidePad.PaddingTop = UDim.new(0, 12)
    SidePad.PaddingLeft = UDim.new(0, 12)
    SidePad.PaddingRight = UDim.new(0, 12)

    local SideList = Instance.new("UIListLayout", Sidebar)
    SideList.Padding = UDim.new(0, 10)
    SideList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Content pages
    local Content = Instance.new("Frame")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Parent = ContentWrap

    local PageLayout = Instance.new("UIPageLayout", Content)
    PageLayout.FillDirection = Enum.FillDirection.Horizontal
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.EasingStyle = Enum.EasingStyle.Quad
    PageLayout.TweenTime = 0.2

    -- =========================================================
    -- Modal overlays (TRUE modal)
    -- =========================================================
    local function mkModalOverlay()
        local o = Instance.new("Frame")
        o.Size = UDim2.fromScale(1, 1)
        o.BackgroundColor3 = Color3.new(0, 0, 0)
        o.BackgroundTransparency = 0.45
        o.Visible = false
        o.ZIndex = 200
        o.Parent = ScreenGui
        Window._maid:Give(o)

        local blocker = Instance.new("TextButton")
        blocker.Size = UDim2.fromScale(1, 1)
        blocker.BackgroundTransparency = 1
        blocker.Text = ""
        blocker.AutoButtonColor = false
        blocker.ZIndex = 201
        blocker.Parent = o

        return o
    end

    local CloseOverlay = mkModalOverlay()
    local SettingsOverlay = mkModalOverlay()

    local function closeAllOverlays()
        CloseOverlay.Visible = false
        SettingsOverlay.Visible = false
    end

    -- Close confirm popup
    local ClosePopup = Instance.new("Frame")
    ClosePopup.Size = UDim2.fromOffset(420, 170)
    ClosePopup.Position = UDim2.fromScale(0.5, 0.5)
    ClosePopup.AnchorPoint = Vector2.new(0.5, 0.5)
    ClosePopup.ZIndex = 210
    ClosePopup.Parent = CloseOverlay
    addCorner(ClosePopup, 14)
    Window:_BindTheme(ClosePopup, "BackgroundColor3", "Panel")
    addStroke(ClosePopup, 1, Library.Theme.StrokeLite, 0.75).Name = "Stroke"
    Window:_BindTheme(ClosePopup.Stroke, "Color", "StrokeLite")

    local CPT = Instance.new("TextLabel")
    CPT.BackgroundTransparency = 1
    CPT.Position = UDim2.fromOffset(16, 14)
    CPT.Size = UDim2.new(1, -32, 0, 28)
    CPT.TextXAlignment = Enum.TextXAlignment.Left
    CPT.Font = Enum.Font.GothamBlack
    CPT.TextSize = 18
    CPT.Text = "Close UI?"
    CPT.ZIndex = 211
    CPT.Parent = ClosePopup
    Window:_BindTheme(CPT, "TextColor3", "Text")

    local CPD = Instance.new("TextLabel")
    CPD.BackgroundTransparency = 1
    CPD.Position = UDim2.fromOffset(16, 46)
    CPD.Size = UDim2.new(1, -32, 0, 44)
    CPD.TextXAlignment = Enum.TextXAlignment.Left
    CPD.TextYAlignment = Enum.TextYAlignment.Top
    CPD.Font = Enum.Font.Gotham
    CPD.TextSize = 13
    CPD.Text = "This will delete the UI."
    CPD.ZIndex = 211
    CPD.Parent = ClosePopup
    Window:_BindTheme(CPD, "TextColor3", "Muted")

    local function mkPopupBtn(text, x, isAccent)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(170, 36)
        b.Position = UDim2.fromOffset(x, 118)
        b.Text = text
        b.Font = Enum.Font.GothamBlack
        b.TextSize = 14
        b.AutoButtonColor = false
        b.ZIndex = 211
        b.Parent = ClosePopup
        addCorner(b, 10)
        if isAccent then
            Window:_BindTheme(b, "BackgroundColor3", "Accent")
            b.TextColor3 = Color3.new(1, 1, 1)
        else
            Window:_BindTheme(b, "BackgroundColor3", "Surface")
            Window:_BindTheme(b, "TextColor3", "Text")
        end
        addStroke(b, 1, Library.Theme.StrokeLite, 0.8).Name = "Stroke"
        Window:_BindTheme(b.Stroke, "Color", "StrokeLite")
        return b
    end

    local YesBtn              = mkPopupBtn("YES", 16, true)
    local NoBtn               = mkPopupBtn("NO", 234, false)

    -- Settings popup
    local SettingsPopup       = Instance.new("Frame")
    SettingsPopup.Size        = UDim2.fromOffset(520, 300)
    SettingsPopup.Position    = UDim2.fromScale(0.5, 0.5)
    SettingsPopup.AnchorPoint = Vector2.new(0.5, 0.5)
    SettingsPopup.ZIndex      = 210
    SettingsPopup.Parent      = SettingsOverlay
    addCorner(SettingsPopup, 14)
    Window:_BindTheme(SettingsPopup, "BackgroundColor3", "Panel")
    addStroke(SettingsPopup, 1, Library.Theme.StrokeLite, 0.75).Name = "Stroke"
    Window:_BindTheme(SettingsPopup.Stroke, "Color", "StrokeLite")

    local SPT = Instance.new("TextLabel")
    SPT.BackgroundTransparency = 1
    SPT.Position = UDim2.fromOffset(16, 14)
    SPT.Size = UDim2.new(1, -72, 0, 28)
    SPT.TextXAlignment = Enum.TextXAlignment.Left
    SPT.Font = Enum.Font.GothamBlack
    SPT.TextSize = 18
    SPT.Text = "UI SETTINGS"
    SPT.ZIndex = 211
    SPT.Parent = SettingsPopup
    Window:_BindTheme(SPT, "TextColor3", "Text")

    local SPClose = Instance.new("TextButton")
    SPClose.Size = UDim2.fromOffset(38, 32)
    SPClose.Position = UDim2.new(1, -54, 0, 12)
    SPClose.Text = "X"
    SPClose.Font = Enum.Font.GothamBlack
    SPClose.TextSize = 16
    SPClose.AutoButtonColor = false
    SPClose.ZIndex = 211
    SPClose.Parent = SettingsPopup
    addCorner(SPClose, 10)
    Window:_BindTheme(SPClose, "BackgroundColor3", "Surface")
    Window:_BindTheme(SPClose, "TextColor3", "Text")
    addStroke(SPClose, 1, Library.Theme.StrokeLite, 0.8).Name = "Stroke"
    Window:_BindTheme(SPClose.Stroke, "Color", "StrokeLite")

    SPClose.MouseButton1Click:Connect(function()
        SettingsOverlay.Visible = false
    end)

    -- =========================================================
    -- Public / behavior
    -- =========================================================
    function Window:GiveTask(task) return self._maid:Give(task) end

    function Window:IsClosed() return self._closed end

    function Window:IsMinimized() return self._minimized end

    -- Keep these near SetMinimized (CreateWindow scope)
    local fullSize = Main.Size
    local MINIMIZED_HEIGHT = 76

    local function addOffsetUDim2(pos, dx, dy)
        return UDim2.new(
            pos.X.Scale, pos.X.Offset + dx,
            pos.Y.Scale, pos.Y.Offset + dy
        )
    end

    function Window:SetMinimized(min)
        if self._closed then return end
        local wantMin = not not min
        if self._minimized == wantMin then return end
        self._minimized = wantMin

        closeAllOverlays()

        local anchor = Main.AnchorPoint
        local fullW, fullH = fullSize.X.Offset, fullSize.Y.Offset
        local miniW, miniH = fullW, MINIMIZED_HEIGHT

        if self._minimized then
            -- Going FULL -> MINI
            -- Keep top-left fixed: shift center by (mini - full) * anchor
            local dx = (miniW - fullW) * anchor.X
            local dy = (miniH - fullH) * anchor.Y

            Main.Position = addOffsetUDim2(Main.Position, dx, dy)
            Main.Size = UDim2.fromOffset(miniW, miniH)
            Body.Visible = false
        else
            -- Going MINI -> FULL
            -- Keep top-left fixed: shift center by (full - mini) * anchor
            local dx = (fullW - miniW) * anchor.X
            local dy = (fullH - miniH) * anchor.Y

            Main.Position = addOffsetUDim2(Main.Position, dx, dy)
            Main.Size = fullSize
            Body.Visible = true
        end
    end

    function Window:SetAccentColor(color3)
        if typeof(color3) ~= "Color3" then return end
        Library.Theme.Accent = color3
        self:_ApplyTheme()
    end

    function Window:SetRainbowMode(enabled)
        self._rainbow = enabled and true or false
        if self._rainbowConn then
            self._rainbowConn:Disconnect()
            self._rainbowConn = nil
        end
        if self._rainbow then
            local t = 0
            self._rainbowConn = RunService.RenderStepped:Connect(function(dt)
                if self._closed then return end
                t += dt
                local hue = (t * 0.08) % 1
                Library.Theme.Accent = Color3.fromHSV(hue, 1, 1)
                self:_ApplyTheme()
            end)
            self:GiveTask(self._rainbowConn)
        else
            self:_ApplyTheme()
        end
    end

    function Window:_ForceOffAllToggles()
        for _, t in ipairs(self._toggleControllers) do
            pcall(function()
                if t and t.Set then
                    t:Set(false)
                end
            end)
        end
    end

    function Window:Destroy()
        if self._closed then return end
        self._closed = true
        pcall(function() self:_ForceOffAllToggles() end)
        self._maid:DoCleaning()
    end

    -- Topbar actions
    CloseBtn.MouseButton1Click:Connect(function()
        if Window._closed then return end
        closeAllOverlays()
        CloseOverlay.Visible = true
    end)
    NoBtn.MouseButton1Click:Connect(function() CloseOverlay.Visible = false end)
    YesBtn.MouseButton1Click:Connect(function()
        CloseOverlay.Visible = false; Window:Destroy()
    end)

    MinBtn.MouseButton1Click:Connect(function()
        Window:SetMinimized(not Window._minimized)
    end)
    SetBtn.MouseButton1Click:Connect(function()
        if Window._closed then return end
        closeAllOverlays()
        SettingsOverlay.Visible = true
    end)

    -- Toggle UI visibility hotkey
    if toggleKey then
        local DEFAULT_TOGGLE_KEY = Enum.KeyCode.RightAlt

        Window:GiveTask(UserInputService.InputBegan:Connect(function(i, gpe)
            if gpe or Window._closed then return end
            if i.KeyCode == DEFAULT_TOGGLE_KEY then
                Main.Visible = not Main.Visible
            end
        end))
    end

    -- =========================================================
    -- Settings content (Rainbow + Accent RGB)
    -- =========================================================
    local SettingsList = Instance.new("Frame")
    SettingsList.BackgroundTransparency = 1
    SettingsList.Position = UDim2.fromOffset(16, 54)
    SettingsList.Size = UDim2.new(1, -32, 1, -70)
    SettingsList.ZIndex = 211
    SettingsList.Parent = SettingsPopup

    local SL = Instance.new("UIListLayout", SettingsList)
    SL.Padding = UDim.new(0, 12)
    SL.SortOrder = Enum.SortOrder.LayoutOrder

    local function mkSettingRow(height)
        local wrap, card = mkCard(SettingsList, Window, height)
        wrap.ZIndex = 211
        card.ZIndex = 211
        return wrap, card
    end

    -- Rainbow row
    do
        local _, card = mkSettingRow(56)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.fromOffset(14, 0)
        lbl.Size = UDim2.new(1, -120, 1, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Text = "Rainbow Mode"
        lbl.ZIndex = 212
        lbl.Parent = card
        Window:_BindTheme(lbl, "TextColor3", "Text")

        local sw, knob, glow = mkPillSwitch(Window, card)
        sw.Position = UDim2.new(1, -80, 0.5, -12)
        sw.ZIndex = 212
        knob.ZIndex = 213
        glow.ZIndex = 211

        local hit = Instance.new("TextButton")
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.AutoButtonColor = false
        hit.Size = UDim2.fromScale(1, 1)
        hit.ZIndex = 214
        hit.Parent = card

        local function sync(animated)
            local on = Window._rainbow
            local knobX = on and (56 - 18 - 3) or 3
            local targetSw = on and Library.Theme.Accent or Library.Theme.Surface
            local targetKnob = on and Color3.new(1, 1, 1) or Library.Theme.Muted

            glow.Visible = on
            if animated then
                TweenService:Create(sw, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = targetSw
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.fromOffset(knobX, 3),
                    BackgroundColor3 = targetKnob
                }):Play()
            else
                sw.BackgroundColor3 = targetSw
                knob.Position = UDim2.fromOffset(knobX, 3)
                knob.BackgroundColor3 = targetKnob
            end
        end

        -- NEW: re-sync after any theme application (rainbow updates accent constantly)
        Window:_AddThemeSync(function()
            sync(false)
        end)

        hit.MouseButton1Click:Connect(function()
            Window:SetRainbowMode(not Window._rainbow)
            sync(true)
        end)
        sync(false)
    end

    -- Accent RGB row
    do
        local _, card = mkSettingRow(160)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Position = UDim2.fromOffset(14, 10)
        titleLbl.Size = UDim2.new(1, -70, 0, 20)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 14
        titleLbl.Text = "Accent Color"
        titleLbl.ZIndex = 212
        titleLbl.Parent = card
        Window:_BindTheme(titleLbl, "TextColor3", "Text")

        local preview = Instance.new("Frame")
        preview.Size = UDim2.fromOffset(36, 36)
        preview.Position = UDim2.new(1, -52, 0, 8)
        preview.ZIndex = 212
        preview.Parent = card
        addCorner(preview, 10)

        local r = roundToInt(Library.Theme.Accent.R * 255)
        local g = roundToInt(Library.Theme.Accent.G * 255)
        local b = roundToInt(Library.Theme.Accent.B * 255)

        local function emitAccent()
            local c = Color3.fromRGB(r, g, b)
            preview.BackgroundColor3 = c
            if not Window._rainbow then
                Window:SetAccentColor(c)
            end
        end

        local function makeChannel(y, name, getter, setter)
            local lab = Instance.new("TextLabel")
            lab.BackgroundTransparency = 1
            lab.Position = UDim2.fromOffset(14, y)
            lab.Size = UDim2.fromOffset(20, 16)
            lab.TextXAlignment = Enum.TextXAlignment.Left
            lab.Font = Enum.Font.GothamBlack
            lab.TextSize = 12
            lab.Text = name
            lab.ZIndex = 212
            lab.Parent = card
            Window:_BindTheme(lab, "TextColor3", "Muted")

            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(40, y + 3)
            bar.Size = UDim2.new(1, -110, 0, 10)
            bar.ZIndex = 212
            bar.Parent = card
            addCorner(bar, 8)
            Window:_BindTheme(bar, "BackgroundColor3", "Surface")
            addStroke(bar, 1, Library.Theme.StrokeLite, 0.8).Name = "Stroke"
            Window:_BindTheme(bar.Stroke, "Color", "StrokeLite")

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(getter() / 255, 0, 1, 0)
            fill.ZIndex = 213
            fill.Parent = bar
            addCorner(fill, 8)
            Window:_BindTheme(fill, "BackgroundColor3", "Accent")

            local val = Instance.new("TextLabel")
            val.BackgroundTransparency = 1
            val.Position = UDim2.new(1, -62, 0, y)
            val.Size = UDim2.fromOffset(48, 16)
            val.TextXAlignment = Enum.TextXAlignment.Right
            val.Font = Enum.Font.Gotham
            val.TextSize = 12
            val.Text = tostring(getter())
            val.ZIndex = 212
            val.Parent = card
            Window:_BindTheme(val, "TextColor3", "Muted")

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Size = UDim2.fromScale(1, 1)
            hit.ZIndex = 214
            hit.Parent = bar

            local dragging = false

            local function fromMouse()
                local mx = UserInputService:GetMouseLocation().X
                local x = bar.AbsolutePosition.X
                local w = bar.AbsoluteSize.X
                return roundToInt(snap(clamp((mx - x) / w, 0, 1) * 255, 1))
            end

            local function setV(v)
                v = roundToInt(clamp(v, 0, 255))
                setter(v)
                val.Text = tostring(v)
                fill.Size = UDim2.new(v / 255, 0, 1, 0)
                emitAccent()
            end

            hit.MouseButton1Down:Connect(function()
                dragging = true
                setV(fromMouse())
            end)

            Window:GiveTask(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end))

            Window:GiveTask(RunService.RenderStepped:Connect(function()
                if dragging then setV(fromMouse()) end
            end))
        end

        makeChannel(44, "R", function() return r end, function(v) r = v end)
        makeChannel(74, "G", function() return g end, function(v) g = v end)
        makeChannel(104, "B", function() return b end, function(v) b = v end)

        emitAccent()
    end

    -- =========================================================
    -- Tabs / Pages (with hero header + card modules)
    -- =========================================================
    function Window:CreateTab(name, iconImage)
        local Tab = {}
        local elementOrder = 0
        local function nextOrder()
            elementOrder += 1
            return elementOrder
        end

        -- Sidebar button (icon + label)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 44)
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.Parent = Sidebar
        addCorner(TabBtn, 12)
        Window:_BindTheme(TabBtn, "BackgroundColor3", "Panel")
        addStroke(TabBtn, 1, Library.Theme.StrokeLite, 0.85).Name = "Stroke"
        Window:_BindTheme(TabBtn.Stroke, "Color", "StrokeLite")

        local TabGlow = addSoftGlowBehind(TabBtn, function(obj, prop, key) Window:_BindTheme(obj, prop, key) end,
            "Accent")
        TabGlow.Visible = false
        TabGlow.BackgroundTransparency = 0.86

        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromOffset(22, 22)
        icon.Position = UDim2.fromOffset(12, 11)
        icon.Image = iconImage or ""
        icon.ImageTransparency = (iconImage and iconImage ~= "") and 0 or 1
        icon.Parent = TabBtn

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.fromOffset(42, 0)
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 15
        lbl.Text = tostring(name or "Tab")
        lbl.Parent = TabBtn
        Window:_BindTheme(lbl, "TextColor3", "Muted")

        table.insert(Window._tabButtons, TabBtn)

        -- Page
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.fromScale(1, 1)
        Page.BackgroundTransparency = 1
        Page.ScrollBarImageTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Parent = Content

        local pad = Instance.new("UIPadding", Page)
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 12)

        local layout = Instance.new("UIListLayout", Page)
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local function selectTab()
            PageLayout:JumpTo(Page)
            for _, b in ipairs(Window._tabButtons) do
                local glow = b:FindFirstChild("Glow")
                if glow then glow.Visible = false end
                b.BackgroundColor3 = Library.Theme.Panel
                local t = b:FindFirstChildWhichIsA("TextLabel", true)
                if t then t.TextColor3 = Library.Theme.Muted end
            end

            TabBtn.BackgroundColor3 = Library.Theme.Accent
            lbl.TextColor3 = Color3.new(1, 1, 1)
            TabGlow.Visible = true
            Window._selectedTabButton = TabBtn
        end

        TabBtn.MouseButton1Click:Connect(selectTab)
        if PageLayout.CurrentPage == nil then
            task.wait(); selectTab()
        end

        -- Hero header per tab (UPDATED smaller height)
        local heroWrap, hero = mkCard(Page, Window, 78) -- was 120
        heroWrap.LayoutOrder = nextOrder()
        heroWrap.Name = "HeroWrap"
        hero.Name = "Hero"
        Window:_BindTheme(hero, "BackgroundColor3", "Surface")

        local heroAccent = Instance.new("Frame")
        heroAccent.BackgroundTransparency = 0.35
        heroAccent.Size = UDim2.new(1, -16, 0, 2)
        heroAccent.Position = UDim2.fromOffset(8, 40) -- was 44 (tuned for smaller hero)
        heroAccent.ZIndex = 3
        heroAccent.Parent = hero
        Window:_BindTheme(heroAccent, "BackgroundColor3", "Accent")

        local heroTitle = Instance.new("TextLabel")
        heroTitle.BackgroundTransparency = 1
        heroTitle.Position = UDim2.fromOffset(16, 14)
        heroTitle.Size = UDim2.new(1, -32, 0, 28)
        heroTitle.TextXAlignment = Enum.TextXAlignment.Left
        heroTitle.Font = Enum.Font.GothamBlack
        heroTitle.TextSize = 22 -- was 24
        heroTitle.Text = (tostring(name or "TAB")):upper()
        heroTitle.ZIndex = 4
        heroTitle.Parent = hero
        Window:_BindTheme(heroTitle, "TextColor3", "Text")

        function Tab:SetHeader(titleText, subtitleText)
            heroTitle.Text = tostring(titleText or heroTitle.Text)
        end

        -- =========================================================
        -- Elements
        -- =========================================================
        function Tab:Label(text)
            local wrap, card = mkCard(Page, Window, 36)
            wrap.LayoutOrder = nextOrder()

            local L = Instance.new("TextLabel")
            L.BackgroundTransparency = 1
            L.Position = UDim2.fromOffset(14, 0)
            L.Size = UDim2.new(1, -28, 1, 0)
            L.TextXAlignment = Enum.TextXAlignment.Left
            L.Font = Enum.Font.Gotham
            L.TextSize = 13
            L.Text = tostring(text or "")
            L.Parent = card
            Window:_BindTheme(L, "TextColor3", "Muted")

            return {
                Set = function(_, newText) L.Text = tostring(newText or "") end,
                Get = function() return L.Text end,
                Destroy = function() wrap:Destroy() end,
            }
        end

        function Tab:Divider(text)
            local wrap, card = mkCard(Page, Window, 36)
            wrap.LayoutOrder = nextOrder()
            card.BackgroundTransparency = 1
            if card:FindFirstChild("UIStroke") then card.UIStroke:Destroy() end

            local T = Instance.new("TextLabel")
            T.BackgroundTransparency = 1
            T.Position = UDim2.fromOffset(6, 0)
            T.Size = UDim2.new(1, -12, 1, 0)
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.Font = Enum.Font.GothamBlack
            T.TextSize = 12
            T.Text = tostring(text or "")
            T.Parent = wrap
            Window:_BindTheme(T, "TextColor3", "Muted")

            local line = Instance.new("Frame")
            line.BorderSizePixel = 0
            line.Size = UDim2.new(1, -6, 0, 2)
            line.Position = UDim2.new(0, 3, 1, -8)
            line.Parent = wrap
            Window:_BindTheme(line, "BackgroundColor3", "Accent")
            line.BackgroundTransparency = 0.65
        end

        function Tab:Button(text, callback)
            local wrap, card = mkCard(Page, Window, 52)
            wrap.LayoutOrder = nextOrder()

            local btn = Instance.new("TextButton")
            btn.BackgroundTransparency = 1
            btn.Size = UDim2.fromScale(1, 1)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = card

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.fromOffset(14, 0)
            label.Size = UDim2.new(1, -28, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = tostring(text or "Button")
            label.Parent = card
            Window:_BindTheme(label, "TextColor3", "Text")

            btn.MouseEnter:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = Library.Theme.Surface }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = Library.Theme.Card }):Play()
            end)

            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Tab:Toggle(text, default, callback, config)
            config = config or {}
            local state = default or false
            local keybind = config.Keybind
            local listeningForKey = false

            local wrap, card = mkCard(Page, Window, 62)
            wrap.LayoutOrder = nextOrder()

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(14, 10)
            title.Size = UDim2.new(1, -170, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.Text = tostring(text or "Toggle")
            title.Parent = card
            Window:_BindTheme(title, "TextColor3", "Text")

            local keyLbl = Instance.new("TextLabel")
            keyLbl.BackgroundTransparency = 1
            keyLbl.Position = UDim2.new(1, -230, 0, 12)
            keyLbl.Size = UDim2.fromOffset(140, 18)
            keyLbl.TextXAlignment = Enum.TextXAlignment.Right
            keyLbl.Font = Enum.Font.Gotham
            keyLbl.TextSize = 12
            keyLbl.Parent = card
            Window:_BindTheme(keyLbl, "TextColor3", "Muted")

            local sw, knob, glow = mkPillSwitch(Window, card)
            sw.Position = UDim2.new(1, -84, 0.5, -12)

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Size = UDim2.fromScale(1, 1)
            hit.Parent = card

            local function updateKeyLabel()
                if listeningForKey then
                    keyLbl.Text = "[Press key...]  (Backspace to clear)"
                elseif keybind then
                    keyLbl.Text = "[" .. keybind.Name .. "]  (RMB to rebind)"
                else
                    keyLbl.Text = "(RMB to bind)"
                end
            end

            local function sync(animated)
                updateKeyLabel()
                local on = state
                local knobX = on and (56 - 18 - 3) or 3
                local targetSw = on and Library.Theme.Accent or Library.Theme.Surface
                local targetKnob = on and Color3.new(1, 1, 1) or Library.Theme.Muted
                glow.Visible = on

                if animated then
                    TweenService:Create(sw, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { BackgroundColor3 = targetSw }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.fromOffset(knobX, 3),
                        BackgroundColor3 = targetKnob
                    }):Play()
                else
                    sw.BackgroundColor3 = targetSw
                    knob.Position = UDim2.fromOffset(knobX, 3)
                    knob.BackgroundColor3 = targetKnob
                end
            end

            -- NEW: re-sync after theme applies (fix rainbow overriding switch colors)
            Window:_AddThemeSync(function()
                sync(false)
            end)

            local function setState(v, fire)
                state = not not v
                sync(true)
                if callback and fire then callback(state) end
            end

            hit.MouseButton1Click:Connect(function()
                if listeningForKey then return end
                setState(not state, true)
            end)

            hit.MouseButton2Click:Connect(function()
                listeningForKey = true
                sync(false)
            end)

            Window:GiveTask(UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe or Window._closed then return end

                if listeningForKey then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        -- Backspace clears/unbinds
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            keybind = nil
                            listeningForKey = false
                            sync(false)
                            return
                        end
                        -- Escape cancels without changes (nice UX)
                        if input.KeyCode == Enum.KeyCode.Escape then
                            listeningForKey = false
                            sync(false)
                            return
                        end

                        keybind = input.KeyCode
                        listeningForKey = false
                        sync(false)
                    end
                    return
                end

                if keybind and input.KeyCode == keybind then
                    setState(not state, true)
                end
            end))

            sync(false)
            if callback then callback(state) end

            local controller = {
                Set = function(_, v) setState(v, true) end,
                Get = function() return state end,
                SetKey = function(_, k)
                    keybind = k; listeningForKey = false; sync(false)
                end,
                GetKey = function() return keybind end,
            }
            table.insert(Window._toggleControllers, controller)
            return controller
        end

        function Tab:Slider(text, minVal, maxVal, defaultVal, callback)
            minVal = roundToInt(minVal or 0)
            maxVal = roundToInt(maxVal or 100)
            if maxVal < minVal then minVal, maxVal = maxVal, minVal end
            local step = 1

            local value = roundToInt(defaultVal or minVal)
            value = clamp(value, minVal, maxVal)

            local wrap, card = mkCard(Page, Window, 74)
            wrap.LayoutOrder = nextOrder()

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(14, 10)
            title.Size = UDim2.new(1, -120, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.Text = tostring(text or "Slider")
            title.Parent = card
            Window:_BindTheme(title, "TextColor3", "Text")

            local valLbl = Instance.new("TextLabel")
            valLbl.BackgroundTransparency = 1
            valLbl.Position = UDim2.new(1, -90, 10 / 74, 0)
            valLbl.AnchorPoint = Vector2.new(0, 0)
            valLbl.Size = UDim2.fromOffset(76, 20)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.Font = Enum.Font.Gotham
            valLbl.TextSize = 13
            valLbl.Parent = card
            Window:_BindTheme(valLbl, "TextColor3", "Muted")

            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(14, 46)
            bar.Size = UDim2.new(1, -28, 0, 12)
            bar.Parent = card
            addCorner(bar, 10)
            Window:_BindTheme(bar, "BackgroundColor3", "Surface")
            addStroke(bar, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
            Window:_BindTheme(bar.Stroke, "Color", "StrokeLite")

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = bar
            addCorner(fill, 10)
            Window:_BindTheme(fill, "BackgroundColor3", "Accent")

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Size = UDim2.fromScale(1, 1)
            hit.Parent = bar

            local dragging = false

            local function setValue(v, fire)
                v = snap(v, step)
                v = roundToInt(clamp(v, minVal, maxVal))
                value = v
                valLbl.Text = tostring(v)
                local alpha = (maxVal == minVal) and 0 or ((v - minVal) / (maxVal - minVal))
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                if callback and fire then callback(value) end
            end

            local function valueFromMouse()
                local mx = UserInputService:GetMouseLocation().X
                local x = bar.AbsolutePosition.X
                local w = bar.AbsoluteSize.X
                local a = clamp((mx - x) / w, 0, 1)
                return minVal + (maxVal - minVal) * a
            end

            hit.MouseButton1Down:Connect(function()
                dragging = true
                setValue(valueFromMouse(), true)
            end)

            Window:GiveTask(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end))

            Window:GiveTask(RunService.RenderStepped:Connect(function()
                if dragging then setValue(valueFromMouse(), true) end
            end))

            setValue(value, false)
            if callback then callback(value) end

            return {
                Set = function(_, v) setValue(v, true) end,
                Get = function() return value end,
            }
        end

        function Tab:Dropdown(text, options, defaultOption, callback, config)
            options = options or {}
            config = config or {}
            local isMulti = (config.Multi == true)
            local NONE_VALUE = config.NoneValue or "None"

            -- NEW: PrioritySelection (multi) => show selected in click order
            local priority = (config.PrioritySelection == true)
            local selectedOrder = {} -- preserves click order (multi only)

            local open = false
            local searchQuery = ""

            local selectedSingle = defaultOption or options[1] or NONE_VALUE
            local selectedSet = {}

            local function setMultiDefault(def)
                table.clear(selectedSet)
                table.clear(selectedOrder)

                local function add(v)
                    if v == nil then return end
                    if not selectedSet[v] then
                        selectedSet[v] = true
                        table.insert(selectedOrder, v)
                    end
                end

                if typeof(def) == "table" then
                    for _, v in ipairs(def) do add(v) end
                elseif def ~= nil then
                    add(def)
                end
            end
            if isMulti then setMultiDefault(defaultOption) end

            local function buildSelectedList()
                local out = {}
                if not isMulti then return out end

                if priority then
                    for _, opt in ipairs(selectedOrder) do
                        if selectedSet[opt] then
                            table.insert(out, opt)
                        end
                    end
                else
                    for _, opt in ipairs(options) do
                        if selectedSet[opt] then table.insert(out, opt) end
                    end
                end
                return out
            end

            local wrap, card = mkCard(Page, Window, 66)
            wrap.LayoutOrder = nextOrder()
            card.ClipsDescendants = true

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(14, 8)
            title.Size = UDim2.new(1, -260, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.Text = tostring(text or "Dropdown")
            title.Parent = card
            Window:_BindTheme(title, "TextColor3", "Text")

            local current = Instance.new("TextLabel")
            current.BackgroundTransparency = 1
            current.Position = UDim2.fromOffset(14, 32)
            current.Size = UDim2.new(1, -260, 0, 18)
            current.TextXAlignment = Enum.TextXAlignment.Left
            current.Font = Enum.Font.Gotham
            current.TextSize = 13
            current.Parent = card
            Window:_BindTheme(current, "TextColor3", "Muted")

            local search = Instance.new("TextBox")
            search.Size = UDim2.fromOffset(130, 30)
            search.Position = UDim2.new(1, -230, 0, 18)
            search.ClearTextOnFocus = false
            search.PlaceholderText = "Search..."
            search.Font = Enum.Font.Gotham
            search.TextSize = 13
            search.TextXAlignment = Enum.TextXAlignment.Left
            search.Parent = card
            search.ZIndex = 10
            addCorner(search, 10)
            Window:_BindTheme(search, "BackgroundColor3", "Surface")
            Window:_BindTheme(search, "TextColor3", "Text")
            Window:_BindTheme(search, "PlaceholderColor3", "Muted")
            addStroke(search, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
            Window:_BindTheme(search.Stroke, "Color", "StrokeLite")

            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.fromOffset(78, 30)
            clearBtn.Position = UDim2.new(1, -92, 0, 18)
            clearBtn.Text = "CLEAR"
            clearBtn.Font = Enum.Font.GothamBlack
            clearBtn.TextSize = 12
            clearBtn.AutoButtonColor = false
            clearBtn.Parent = card
            clearBtn.ZIndex = 10
            addCorner(clearBtn, 10)
            Window:_BindTheme(clearBtn, "BackgroundColor3", "Surface")
            Window:_BindTheme(clearBtn, "TextColor3", "Text")
            addStroke(clearBtn, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
            Window:_BindTheme(clearBtn.Stroke, "Color", "StrokeLite")

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text = ""
            toggleBtn.AutoButtonColor = false
            toggleBtn.Size = UDim2.new(1, -260, 1, 0)
            toggleBtn.Parent = card
            toggleBtn.ZIndex = 1

            local list = Instance.new("Frame")
            list.BackgroundTransparency = 1
            list.Position = UDim2.fromOffset(14, 66)
            list.Size = UDim2.new(1, -28, 0, 0)
            list.Visible = false
            list.Parent = card
            list.ZIndex = 5

            local listLayout = Instance.new("UIListLayout", list)
            listLayout.Padding = UDim.new(0, 8)

            local function updateCurrent()
                if isMulti then
                    local arr = buildSelectedList()
                    if #arr == 0 then
                        current.Text = NONE_VALUE
                    elseif #arr <= 4 then
                        current.Text = table.concat(arr, ", ")
                    else
                        current.Text = tostring(#arr) .. " selected"
                    end
                else
                    current.Text = tostring(selectedSingle)
                end
            end

            local function fire()
                if not callback then return end
                if isMulti then callback(buildSelectedList()) else callback(selectedSingle) end
            end

            local function passes(opt)
                if searchQuery == "" then return true end
                return tostring(opt):lower():find(searchQuery, 1, true) ~= nil
            end

            local function rebuild()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end

                local shown = 0
                for _, opt in ipairs(options) do
                    if passes(opt) then
                        shown += 1
                        local ob = Instance.new("TextButton")
                        ob.AutoButtonColor = false
                        ob.Size = UDim2.new(1, 0, 0, 34)
                        ob.Parent = list
                        ob.ZIndex = 6
                        addCorner(ob, 12)
                        Window:_BindTheme(ob, "BackgroundColor3", "Surface")
                        addStroke(ob, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
                        Window:_BindTheme(ob.Stroke, "Color", "StrokeLite")
                        ob.Font = Enum.Font.GothamBold
                        ob.TextSize = 13
                        Window:_BindTheme(ob, "TextColor3", "Text")

                        local function refresh()
                            if isMulti then
                                ob.Text = (selectedSet[opt] and "✓  " or "   ") .. tostring(opt)
                            else
                                ob.Text = tostring(opt)
                            end
                        end
                        refresh()

                        ob.MouseButton1Click:Connect(function()
                            if isMulti then
                                local now = not selectedSet[opt]
                                selectedSet[opt] = now

                                if priority then
                                    if now then
                                        if not table.find(selectedOrder, opt) then
                                            table.insert(selectedOrder, opt)
                                        end
                                    else
                                        local idx = table.find(selectedOrder, opt)
                                        if idx then table.remove(selectedOrder, idx) end
                                    end
                                end

                                refresh()
                                updateCurrent()
                                fire()
                            else
                                selectedSingle = opt
                                updateCurrent()
                                fire()
                                open = false
                                list.Visible = false
                                wrap.Size = UDim2.new(1, -10, 0, 66)
                            end
                        end)
                    end
                end
                return shown
            end

            local function resizeOpen(shown)
                local h = shown > 0 and (shown * 34 + (shown - 1) * 8 + 10) or 40
                wrap.Size = UDim2.new(1, -10, 0, 66 + h)
                list.Size = UDim2.new(1, -28, 0, h)
            end

            local function openDD()
                if open then return end
                open = true
                list.Visible = true
                local shown = rebuild()
                resizeOpen(shown)
            end

            local function closeDD()
                open = false
                list.Visible = false
                wrap.Size = UDim2.new(1, -10, 0, 66)
            end

            toggleBtn.MouseButton1Click:Connect(function()
                if open then closeDD() else openDD() end
            end)

            clearBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    table.clear(selectedSet)
                    table.clear(selectedOrder)
                else
                    selectedSingle = NONE_VALUE
                end
                updateCurrent()
                fire()
                if open then
                    local shown = rebuild()
                    resizeOpen(shown)
                end
            end)

            search.Focused:Connect(function() openDD() end)
            search:GetPropertyChangedSignal("Text"):Connect(function()
                searchQuery = tostring(search.Text or ""):lower()
                openDD()
                local shown = rebuild()
                resizeOpen(shown)
            end)

            updateCurrent()
            fire()

            return {
                Get = function()
                    if isMulti then return buildSelectedList() end
                    return selectedSingle
                end,
                Set = function(_, v)
                    if isMulti then
                        setMultiDefault(v)
                    else
                        selectedSingle = (v ~= nil and v or NONE_VALUE)
                    end
                    updateCurrent()
                    fire()
                    if open then
                        local shown = rebuild()
                        resizeOpen(shown)
                    end
                end,
                Close = function() closeDD() end,
                SetOptions = function(_, newOptions)
                    options = newOptions or {}
                    if isMulti then
                        local keep = {}
                        for _, opt in ipairs(options) do
                            if selectedSet[opt] then keep[opt] = true end
                        end
                        selectedSet = keep

                        if priority then
                            local newOrder = {}
                            for _, v in ipairs(selectedOrder) do
                                if keep[v] then table.insert(newOrder, v) end
                            end
                            selectedOrder = newOrder
                        end
                    else
                        if table.find(options, selectedSingle) == nil then
                            selectedSingle = options[1] or NONE_VALUE
                        end
                    end
                    updateCurrent()
                    fire()
                    if open then
                        local shown = rebuild()
                        resizeOpen(shown)
                    end
                end
            }
        end

        function Tab:Textbox(labelText, placeholder, callback)
            local wrap, card = mkCard(Page, Window, 74)
            wrap.LayoutOrder = nextOrder()

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(14, 10)
            title.Size = UDim2.new(1, -28, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.Text = tostring(labelText or "Input")
            title.Parent = card
            Window:_BindTheme(title, "TextColor3", "Text")

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -28, 0, 30)
            box.Position = UDim2.fromOffset(14, 38)
            box.ClearTextOnFocus = false
            box.PlaceholderText = placeholder or "Type here..."
            box.Font = Enum.Font.Gotham
            box.TextSize = 13
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Parent = card
            addCorner(box, 10)
            Window:_BindTheme(box, "BackgroundColor3", "Surface")
            Window:_BindTheme(box, "TextColor3", "Text")
            Window:_BindTheme(box, "PlaceholderColor3", "Muted")
            addStroke(box, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
            Window:_BindTheme(box.Stroke, "Color", "StrokeLite")

            box.FocusLost:Connect(function(enterPressed)
                if callback then callback(box.Text, enterPressed) end
            end)

            return {
                Set = function(_, v) box.Text = tostring(v) end,
                Get = function() return box.Text end,
                Clear = function() box.Text = "" end,
                Destroy = function() wrap:Destroy() end,
            }
        end

        function Tab:ColorPicker(labelText, defaultColor, callback)
            defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local r = roundToInt(defaultColor.R * 255)
            local g = roundToInt(defaultColor.G * 255)
            local b = roundToInt(defaultColor.B * 255)

            local wrap, card = mkCard(Page, Window, 156)
            wrap.LayoutOrder = nextOrder()

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(14, 10)
            title.Size = UDim2.new(1, -70, 0, 20)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.Text = tostring(labelText or "Color")
            title.Parent = card
            Window:_BindTheme(title, "TextColor3", "Text")

            local preview = Instance.new("Frame")
            preview.Size = UDim2.fromOffset(40, 40)
            preview.Position = UDim2.new(1, -56, 0, 8)
            preview.Parent = card
            addCorner(preview, 10)
            addStroke(preview, 1, Library.Theme.StrokeLite, 0.75)
            preview.BackgroundColor3 = Color3.fromRGB(r, g, b)

            local function emit()
                local c = Color3.fromRGB(r, g, b)
                preview.BackgroundColor3 = c
                if callback then callback(c) end
            end

            local function makeChannel(y, name, getter, setter)
                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Position = UDim2.fromOffset(14, y)
                lab.Size = UDim2.fromOffset(20, 16)
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Font = Enum.Font.GothamBlack
                lab.TextSize = 12
                lab.Text = name
                lab.Parent = card
                Window:_BindTheme(lab, "TextColor3", "Muted")

                local bar = Instance.new("Frame")
                bar.Position = UDim2.fromOffset(40, y + 3)
                bar.Size = UDim2.new(1, -110, 0, 12)
                bar.Parent = card
                addCorner(bar, 10)
                Window:_BindTheme(bar, "BackgroundColor3", "Surface")
                addStroke(bar, 1, Library.Theme.StrokeLite, 0.82).Name = "Stroke"
                Window:_BindTheme(bar.Stroke, "Color", "StrokeLite")

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(getter() / 255, 0, 1, 0)
                fill.Parent = bar
                addCorner(fill, 10)
                Window:_BindTheme(fill, "BackgroundColor3", "Accent")

                local val = Instance.new("TextLabel")
                val.BackgroundTransparency = 1
                val.Position = UDim2.new(1, -62, 0, y)
                val.Size = UDim2.fromOffset(48, 16)
                val.TextXAlignment = Enum.TextXAlignment.Right
                val.Font = Enum.Font.Gotham
                val.TextSize = 12
                val.Text = tostring(getter())
                val.Parent = card
                Window:_BindTheme(val, "TextColor3", "Muted")

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Text = ""
                hit.AutoButtonColor = false
                hit.Size = UDim2.fromScale(1, 1)
                hit.Parent = bar

                local dragging = false
                local function fromMouse()
                    local mx = UserInputService:GetMouseLocation().X
                    local x = bar.AbsolutePosition.X
                    local w = bar.AbsoluteSize.X
                    return roundToInt(snap(clamp((mx - x) / w, 0, 1) * 255, 1))
                end

                local function setV(v)
                    v = roundToInt(clamp(v, 0, 255))
                    setter(v)
                    val.Text = tostring(v)
                    fill.Size = UDim2.new(v / 255, 0, 1, 0)
                    emit()
                end

                hit.MouseButton1Down:Connect(function()
                    dragging = true
                    setV(fromMouse())
                end)

                Window:GiveTask(UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end))

                Window:GiveTask(RunService.RenderStepped:Connect(function()
                    if dragging then setV(fromMouse()) end
                end))
            end

            makeChannel(52, "R", function() return r end, function(v) r = v end)
            makeChannel(84, "G", function() return g end, function(v) g = v end)
            makeChannel(116, "B", function() return b end, function(v) b = v end)

            emit()

            return {
                Get = function() return Color3.fromRGB(r, g, b) end,
                Set = function(_, c)
                    c = c or Color3.new(1, 1, 1)
                    r = roundToInt(c.R * 255)
                    g = roundToInt(c.G * 255)
                    b = roundToInt(c.B * 255)
                    emit()
                end,
                Destroy = function() wrap:Destroy() end,
            }
        end

        return Tab
    end

    -- Apply theme
    Window:_ApplyTheme()

    return Window
end

return Library
