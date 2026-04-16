local VantaApp = {}
VantaApp.__index = VantaApp

local ThemeRegistry = require or nil

local function connect(conn)
    return conn
end

local function destroySafe(object)
    if object then
        pcall(function()
            object:Destroy()
        end)
    end
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ Tasks = {} }, Maid)
end

function Maid:Give(task)
    table.insert(self.Tasks, task)
    return task
end

function Maid:Clean()
    for i = #self.Tasks, 1, -1 do
        local task = self.Tasks[i]
        self.Tasks[i] = nil
        local kind = typeof(task)

        if kind == "RBXScriptConnection" then
            pcall(function() task:Disconnect() end)
        elseif kind == "Instance" then
            destroySafe(task)
        elseif kind == "function" then
            pcall(task)
        elseif kind == "table" and type(task.Destroy) == "function" then
            pcall(function() task:Destroy() end)
        end
    end
end

local function create(className, props)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    return obj
end

local function round(frame, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = frame,
    })
end

local function stroke(frame, thickness)
    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness or 1,
        Parent = frame,
    })
end

local function pad(frame, left, right, top, bottom)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = frame,
    })
end

local function list(frame, spacing)
    return create("UIListLayout", {
        Padding = UDim.new(0, spacing or 8),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
end

local function fit(frame)
    create("UISizeConstraint", {
        MinSize = Vector2.new(0, 0),
        Parent = frame,
    })
end

local function buttonify(btn)
    btn.AutoButtonColor = false
end

local function safeLower(value)
    return string.lower(tostring(value or ""))
end

local function shallowCopy(tbl)
    local out = {}
    for k, v in pairs(tbl or {}) do
        out[k] = v
    end
    return out
end

local function cloneArray(list)
    local out = {}
    for i, value in ipairs(list or {}) do
        out[i] = value
    end
    return out
end

local function arrayContains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function arrayRemove(list, value)
    for index = #list, 1, -1 do
        if list[index] == value then
            table.remove(list, index)
        end
    end
end

local function setCanvasSize(scrollingFrame, layout, extra)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
end

local function attachAutoCanvas(scrollingFrame, layout, extra)
    local function update()
        setCanvasSize(scrollingFrame, layout, extra)
    end

    update()
    return layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function applyTextColor(label, color)
    if label and label:IsA("TextLabel") or label and label:IsA("TextButton") then
        label.TextColor3 = color
    end
end

function VantaApp.Create(services, themeModule, options)
    local self = setmetatable({}, VantaApp)

    self.Services = services
    self.ThemeModule = themeModule
    self.Options = options or {}
    self.Maid = Maid.new()
    self.Pages = {}
    self.PageOrder = {}
    self.PageButtons = {}
    self.Binds = {}
    self.SearchEntries = {}
    self.Notifications = {}
    self.State = {
        Visible = true,
        ThemeName = self.Options.ThemeName or "Obsidian",
        Search = "",
    }

    self.Theme = themeModule.Get(self.State.ThemeName)
    self:_build()
    self:_applyTheme()
    self:SelectPage(self.Options.DefaultPage or "home")

    return self
end

function VantaApp:_bindTheme(instance, property, key, transformer)
    table.insert(self.Binds, {
        Instance = instance,
        Property = property,
        Key = key,
        Transformer = transformer,
    })
end

function VantaApp:_applyTheme()
    self.Theme = self.ThemeModule.Get(self.State.ThemeName)

    for _, binding in ipairs(self.Binds) do
        local instance = binding.Instance
        if instance and instance.Parent then
            local value = self.Theme[binding.Key]
            if binding.Transformer then
                value = binding.Transformer(value, self.Theme)
            end
            pcall(function()
                instance[binding.Property] = value
            end)
        end
    end

    for _, pageData in pairs(self.Pages) do
        self:_updatePageButton(pageData.Id)
    end

    if self.ActivePage and self.ActivePage.RefreshTheme then
        self.ActivePage:RefreshTheme()
    end
end

function VantaApp:_build()
    local services = self.Services
    local coreGui = services.CoreGui
    local tweenService = services.TweenService
    local inputService = services.UserInputService

    local existing = coreGui:FindFirstChild("VantaHubUI")
    if existing then
        existing:Destroy()
    end

    local gui = create("ScreenGui", {
        Name = "VantaHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = coreGui,
    })
    self.Gui = gui
    self.Maid:Give(gui)

    local overlay = create("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 0.35,
        Size = UDim2.fromScale(1, 1),
        Parent = gui,
    })
    self:_bindTheme(overlay, "BackgroundColor3", "Overlay")

    local root = create("Frame", {
        Name = "Root",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 980, 0, 640),
        Parent = gui,
    })
    self.Root = root
    self:_bindTheme(root, "BackgroundColor3", "Background")
    round(root, 20)
    local rootStroke = stroke(root, 1)
    self:_bindTheme(rootStroke, "Color", "Border")

    local glow = create("Frame", {
        Name = "Glow",
        BackgroundTransparency = 0.8,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 34, 1, 34),
        ZIndex = 0,
        Parent = root,
    })
    round(glow, 26)
    self:_bindTheme(glow, "BackgroundColor3", "Accent")

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 226, 1, 0),
        Parent = root,
    })
    self:_bindTheme(sidebar, "BackgroundColor3", "Sidebar")
    round(sidebar, 20)
    local sidebarStroke = stroke(sidebar, 1)
    self:_bindTheme(sidebarStroke, "Color", "BorderSoft")

    local divider = create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(0, 225, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = root,
    })
    self:_bindTheme(divider, "BackgroundColor3", "BorderSoft")

    local brand = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 88),
        Parent = sidebar,
    })
    pad(brand, 18, 18, 16, 8)

    local badge = create("Frame", {
        Size = UDim2.new(0, 42, 0, 42),
        Parent = brand,
    })
    self:_bindTheme(badge, "BackgroundColor3", "AccentSoft")
    round(badge, 12)
    local badgeStroke = stroke(badge, 1)
    self:_bindTheme(badgeStroke, "Color", "Accent")

    local badgeLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBlack,
        Text = "V",
        TextSize = 22,
        Parent = badge,
    })
    self:_bindTheme(badgeLabel, "TextColor3", "Accent")

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 56, 0, 0),
        Size = UDim2.new(1, -56, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = self.Options.Title or "VANTA Hub",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = brand,
    })
    self:_bindTheme(title, "TextColor3", "Text")

    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 56, 0, 28),
        Size = UDim2.new(1, -56, 0, 18),
        Font = Enum.Font.Gotham,
        Text = self.Options.Subtitle or "Polished, modular, and game-aware",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = brand,
    })
    self:_bindTheme(subtitle, "TextColor3", "Muted")

    local info = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 54),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = string.format("PlaceId %s", tostring(game.PlaceId)),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = brand,
    })
    self:_bindTheme(info, "TextColor3", "Muted")

    local navHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 92),
        Size = UDim2.new(1, 0, 1, -168),
        Parent = sidebar,
    })
    pad(navHolder, 12, 12, 8, 8)
    local navLayout = list(navHolder, 8)

    local footer = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 60),
        Parent = sidebar,
    })
    pad(footer, 16, 16, 8, 8)

    local footerLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "Toggle UI",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
    self:_bindTheme(footerLabel, "TextColor3", "Text")

    local footerValue = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = tostring(self.Options.ToggleKey or Enum.KeyCode.RightAlt.Name),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
    self:_bindTheme(footerValue, "TextColor3", "Muted")

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 226, 0, 0),
        Size = UDim2.new(1, -226, 1, 0),
        Parent = root,
    })

    local topbar = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 84),
        Parent = content,
    })
    pad(topbar, 22, 22, 18, 12)

    local pageTitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.45, 0, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "Overview",
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })
    self:_bindTheme(pageTitle, "TextColor3", "Text")
    self.PageTitle = pageTitle

    local pageSubtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(0.6, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })
    self:_bindTheme(pageSubtitle, "TextColor3", "Muted")
    self.PageSubtitle = pageSubtitle

    local searchBox = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 250, 0, 38),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search current page",
        Text = "",
        TextSize = 13,
        Parent = topbar,
    })
    buttonify(searchBox)
    round(searchBox, 12)
    local searchStroke = stroke(searchBox, 1)
    self:_bindTheme(searchBox, "BackgroundColor3", "SurfaceAlt")
    self:_bindTheme(searchBox, "TextColor3", "Text")
    self:_bindTheme(searchBox, "PlaceholderColor3", "Muted")
    self:_bindTheme(searchStroke, "Color", "BorderSoft")
    self.SearchBox = searchBox

    local body = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 84),
        Size = UDim2.new(1, 0, 1, -84),
        Parent = content,
    })
    self.Body = body

    local notificationHolder = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.new(0, 320, 1, -36),
        Parent = gui,
    })
    local notificationLayout = list(notificationHolder, 8)
    notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    self.NotificationHolder = notificationHolder

    local dragging = false
    local dragStart, startPosition
    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPosition = root.Position
    end

    local function updateDrag(input)
        if not dragging then
            return
        end

        local delta = input.Position - dragStart
        root.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    self.Maid:Give(connect(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag(input)
        end
    end)))

    self.Maid:Give(connect(inputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)))

    self.Maid:Give(connect(inputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)))

    self.Maid:Give(connect(inputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == (self.Options.ToggleKey or Enum.KeyCode.RightAlt) then
            self:SetVisible(not self.State.Visible)
        end
    end)))

    self.Maid:Give(connect(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.State.Search = searchBox.Text
        if self.ActivePage then
            self.ActivePage:ApplySearch(searchBox.Text)
        end
    end)))

    self.NavHolder = navHolder
    self.NavLayout = navLayout
    self.TweenService = tweenService
end

function VantaApp:SetVisible(state)
    self.State.Visible = state
    self.Root.Visible = state
    self.SearchBox:ReleaseFocus()
end

function VantaApp:_makeNavButton(id, title, subtitle)
    local button = create("TextButton", {
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 52),
        Text = "",
        Parent = self.NavHolder,
    })
    buttonify(button)
    round(button, 14)
    local buttonStroke = stroke(button, 1)
    self:_bindTheme(button, "BackgroundColor3", "Surface")
    self:_bindTheme(buttonStroke, "Color", "BorderSoft")

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -20, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })
    self:_bindTheme(titleLabel, "TextColor3", "Text")

    local subtitleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 25),
        Size = UDim2.new(1, -20, 0, 16),
        Font = Enum.Font.Gotham,
        Text = subtitle or "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })
    self:_bindTheme(subtitleLabel, "TextColor3", "Muted")

    self.Maid:Give(button.MouseButton1Click:Connect(function()
        self:SelectPage(id)
    end))

    return {
        Button = button,
        Stroke = buttonStroke,
        Title = titleLabel,
        Subtitle = subtitleLabel,
    }
end

function VantaApp:_updatePageButton(id)
    local pageData = self.Pages[id]
    local nav = self.PageButtons[id]
    if not pageData or not nav then
        return
    end

    local active = self.ActivePage and self.ActivePage.Id == id
    nav.Button.BackgroundColor3 = active and self.Theme.AccentSoft or self.Theme.Surface
    nav.Stroke.Color = active and self.Theme.Accent or self.Theme.BorderSoft
    nav.Title.TextColor3 = self.Theme.Text
    nav.Subtitle.TextColor3 = active and self.Theme.Text or self.Theme.Muted
end

function VantaApp:AddPage(def)
    local id = def.Id
    if not id then
        error("[VantaApp] Page Id is required.")
    end

    local pageFrame = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.Body,
    })
    self:_bindTheme(pageFrame, "ScrollBarImageColor3", "Accent")

    local layout = list(pageFrame, 14)
    pad(pageFrame, 22, 22, 8, 22)
    self.Maid:Give(attachAutoCanvas(pageFrame, layout, 8))

    local page = {
        App = self,
        Id = id,
        Title = def.Title or id,
        Subtitle = def.Subtitle or "",
        Frame = pageFrame,
        Layout = layout,
        Entries = {},
    }

    function page:ApplySearch(query)
        local lowered = safeLower(query)
        for _, entry in ipairs(self.Entries) do
            local visible = true
            if lowered ~= "" then
                visible = false
                for _, token in ipairs(entry.SearchTokens or {}) do
                    if string.find(safeLower(token), lowered, 1, true) then
                        visible = true
                        break
                    end
                end
            end
            entry.Root.Visible = visible
        end
    end

    function page:RefreshTheme()
        for _, entry in ipairs(self.Entries) do
            if type(entry.RefreshTheme) == "function" then
                entry:RefreshTheme()
            end
        end
    end

    function page:AddHeroCard(title, body, tag)
        local card = create("Frame", {
            Size = UDim2.new(1, 0, 0, 88),
            Parent = self.Frame,
        })
        self.App:_bindTheme(card, "BackgroundColor3", "Surface")
        round(card, 16)
        local cardStroke = stroke(card, 1)
        self.App:_bindTheme(cardStroke, "Color", "BorderSoft")
        pad(card, 18, 18, 16, 16)

        local titleLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -120, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
        self.App:_bindTheme(titleLabel, "TextColor3", "Text")

        local bodyLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 26),
            Size = UDim2.new(1, -18, 1, -26),
            Font = Enum.Font.Gotham,
            Text = body,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
        })
        self.App:_bindTheme(bodyLabel, "TextColor3", "Muted")

        if tag then
            local badge = create("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 100, 0, 24),
                Font = Enum.Font.GothamBold,
                Text = tag,
                TextSize = 11,
                Parent = card,
            })
            round(badge, 10)
            self.App:_bindTheme(badge, "BackgroundColor3", "AccentSoft")
            self.App:_bindTheme(badge, "TextColor3", "Accent")
        end

        table.insert(self.Entries, {
            Root = card,
            SearchTokens = { title, body, tag or "" },
        })
        return card
    end

    function page:AddStatsRow(stats)
        local row = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 84),
            Parent = self.Frame,
        })
        local rowLayout = create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = row,
        })
        self.App.Maid:Give(rowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            row.Size = UDim2.new(1, 0, 0, rowLayout.AbsoluteContentSize.Y)
        end))

        for _, stat in ipairs(stats or {}) do
            local card = create("Frame", {
                Size = UDim2.new(1 / math.max(#stats, 1), -8, 1, 0),
                Parent = row,
            })
            self.App:_bindTheme(card, "BackgroundColor3", "Surface")
            round(card, 16)
            local cardStroke = stroke(card, 1)
            self.App:_bindTheme(cardStroke, "Color", stat.ColorKey or "BorderSoft")
            pad(card, 16, 16, 14, 14)

            local label = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Font = Enum.Font.Gotham,
                Text = stat.Label or "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            self.App:_bindTheme(label, "TextColor3", "Muted")

            local statValue = type(stat.Value) == "function" and stat.Value() or tostring(stat.Value or "0")
            local value = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 24),
                Font = Enum.Font.GothamBold,
                Text = tostring(statValue),
                TextSize = 20,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            self.App:_bindTheme(value, "TextColor3", "Text")

            local sub = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 48),
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.Gotham,
                Text = stat.Subtext or "",
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })
            self.App:_bindTheme(sub, "TextColor3", stat.ColorKey or "Accent")
        end

        table.insert(self.Entries, {
            Root = row,
            SearchTokens = { "stats", self.Title },
        })

        return row
    end

    function page:AddSection(definition)
        local section = {}
        section.Page = self
        section.Title = definition.Title or "Section"
        section.Subtitle = definition.Subtitle or ""

        local card = create("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = self.Frame,
        })
        self.App:_bindTheme(card, "BackgroundColor3", "Surface")
        round(card, 18)
        local cardStroke = stroke(card, 1)
        self.App:_bindTheme(cardStroke, "Color", "BorderSoft")
        pad(card, 18, 18, 16, 18)

        local headerTitle = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 18),
            Font = Enum.Font.GothamBold,
            Text = section.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
        self.App:_bindTheme(headerTitle, "TextColor3", "Text")

        local headerSubtitle = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, -8, 0, 16),
            Font = Enum.Font.Gotham,
            Text = section.Subtitle,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
        self.App:_bindTheme(headerSubtitle, "TextColor3", "Muted")

        local holder = create("Frame", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 0, 0, definition.Subtitle and definition.Subtitle ~= "" and 50 or 28),
            Size = UDim2.new(1, 0, 0, 0),
            Parent = card,
        })
        local holderLayout = list(holder, 10)
        self.App.Maid:Give(holderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size = UDim2.new(1, 0, 0, holderLayout.AbsoluteContentSize.Y)
        end))

        section.Root = card
        section.Holder = holder
        section.Items = {}

        local function registerItem(item)
            table.insert(section.Items, item)
            table.insert(self.Entries, item)
            return item
        end

        function section:AddLabel(text)
            local label = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.Gotham,
                Text = text,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            self.Page.App:_bindTheme(label, "TextColor3", "Muted")
            return registerItem({ Root = label, SearchTokens = { text, section.Title } })
        end

        function section:AddButton(def)
            local button = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = holder,
            })
            buttonify(button)
            round(button, 12)
            local btnStroke = stroke(button, 1)
            self.Page.App:_bindTheme(button, "BackgroundColor3", def.Style == "Danger" and "Danger" or def.Style == "Success" and "Success" or "AccentSoft")
            self.Page.App:_bindTheme(btnStroke, "Color", def.Style == "Danger" and "Danger" or def.Style == "Success" and "Success" or "Accent")

            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.GothamBold,
                Text = def.Title,
                TextSize = 13,
                Parent = button,
            })
            self.Page.App:_bindTheme(titleLabel, "TextColor3", "Text")

            self.Page.App.Maid:Give(button.MouseButton1Click:Connect(function()
                if type(def.Callback) == "function" then
                    def.Callback()
                end
            end))

            return registerItem({ Root = button, SearchTokens = { def.Title, def.Description or "", section.Title } })
        end

        function section:AddToggle(def)
            local state = def.Default == true
            local row = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 54),
                Text = "",
                Parent = holder,
            })
            buttonify(row)
            round(row, 14)
            local rowStroke = stroke(row, 1)
            self.Page.App:_bindTheme(row, "BackgroundColor3", "SurfaceAlt")
            self.Page.App:_bindTheme(rowStroke, "Color", "BorderSoft")

            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 9),
                Size = UDim2.new(1, -88, 0, 18),
                Font = Enum.Font.GothamBold,
                Text = def.Title,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            self.Page.App:_bindTheme(titleLabel, "TextColor3", "Text")

            local descLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 28),
                Size = UDim2.new(1, -88, 0, 16),
                Font = Enum.Font.Gotham,
                Text = def.Description or "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            self.Page.App:_bindTheme(descLabel, "TextColor3", "Muted")

            local indicator = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.new(0, 46, 0, 24),
                Parent = row,
            })
            round(indicator, 999)
            local indicatorStroke = stroke(indicator, 1)

            local thumb = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
                Parent = indicator,
            })
            round(thumb, 999)

            local item = {
                Page = section.Page,
                Root = row,
                SearchTokens = { def.Title, def.Description or "", section.Title },
                Get = function()
                    return state
                end,
            }

            function item:Set(value, silent)
                state = value == true
                indicator.BackgroundColor3 = state and self.Page.App.Theme.AccentSoft or self.Page.App.Theme.Background
                indicatorStroke.Color = state and self.Page.App.Theme.Accent or self.Page.App.Theme.Border
                thumb.BackgroundColor3 = state and self.Page.App.Theme.Accent or self.Page.App.Theme.Muted
                self.Page.App.TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                }):Play()

                if not silent and type(def.Callback) == "function" then
                    def.Callback(state)
                end
            end

            function item:RefreshTheme()
                item:Set(state, true)
            end

            self.Page.App.Maid:Give(row.MouseButton1Click:Connect(function()
                item:Set(not state)
            end))

            item:Set(state, true)
            return registerItem(item)
        end

        function section:AddMultiSelect(def)
            local selected = cloneArray(def.Default or {})

            local container = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = holder,
            })
            local containerLayout = list(container, 8)
            self.Page.App.Maid:Give(containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                container.Size = UDim2.new(1, 0, 0, containerLayout.AbsoluteContentSize.Y)
            end))

            local button = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 54),
                Text = "",
                Parent = container,
            })
            buttonify(button)
            round(button, 14)
            local buttonStroke = stroke(button, 1)
            self.Page.App:_bindTheme(button, "BackgroundColor3", "SurfaceAlt")
            self.Page.App:_bindTheme(buttonStroke, "Color", "BorderSoft")

            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 9),
                Size = UDim2.new(1, -28, 0, 18),
                Font = Enum.Font.GothamBold,
                Text = def.Title,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
            self.Page.App:_bindTheme(titleLabel, "TextColor3", "Text")

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 28),
                Size = UDim2.new(1, -28, 0, 16),
                Font = Enum.Font.Gotham,
                Text = "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
            self.Page.App:_bindTheme(valueLabel, "TextColor3", "Muted")

            local listFrame = create("Frame", {
                Visible = false,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = container,
            })
            round(listFrame, 14)
            local listStroke = stroke(listFrame, 1)
            self.Page.App:_bindTheme(listFrame, "BackgroundColor3", "Surface")
            self.Page.App:_bindTheme(listStroke, "Color", "BorderSoft")
            pad(listFrame, 10, 10, 10, 10)
            local listLayout = list(listFrame, 6)

            local item = {
                Page = section.Page,
                Root = container,
                SearchTokens = { def.Title, table.concat(def.Options or {}, " "), section.Title },
            }

            local optionRows = {}
            local expanded = false

            local function updateText()
                valueLabel.Text = #selected > 0 and table.concat(selected, ", ") or (def.NoneText or "Nothing selected")
            end

            local function emit()
                if type(def.Callback) == "function" then
                    def.Callback(cloneArray(selected))
                end
            end

            local function refreshRows()
                for option, rowData in pairs(optionRows) do
                    local active = arrayContains(selected, option)
                    rowData.Box.BackgroundColor3 = active and self.Page.App.Theme.AccentSoft or self.Page.App.Theme.Background
                    rowData.Stroke.Color = active and self.Page.App.Theme.Accent or self.Page.App.Theme.Border
                    rowData.Label.TextColor3 = active and self.Page.App.Theme.Text or self.Page.App.Theme.Muted
                end
                updateText()
            end

            function item:Get()
                return cloneArray(selected)
            end

            function item:Set(values, silent)
                selected = cloneArray(values or {})
                refreshRows()
                if not silent then
                    emit()
                end
            end

            function item:RefreshTheme()
                refreshRows()
            end

            local function setExpanded(value)
                expanded = value == true
                listFrame.Visible = expanded
            end

            self.Page.App.Maid:Give(button.MouseButton1Click:Connect(function()
                setExpanded(not expanded)
            end))

            for _, option in ipairs(def.Options or {}) do
                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = "",
                    Parent = listFrame,
                })
                buttonify(row)
                round(row, 10)
                local rowStroke = stroke(row, 1)
                self.Page.App:_bindTheme(row, "BackgroundColor3", "SurfaceAlt")
                self.Page.App:_bindTheme(rowStroke, "Color", "BorderSoft")

                local box = create("Frame", {
                    Position = UDim2.new(0, 8, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    Parent = row,
                })
                round(box, 6)
                local boxStroke = stroke(box, 1)

                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 32, 0, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = option,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })
                self.Page.App:_bindTheme(label, "TextColor3", "Muted")

                optionRows[option] = {
                    Box = box,
                    Stroke = boxStroke,
                    Label = label,
                }

                self.Page.App.Maid:Give(row.MouseButton1Click:Connect(function()
                    if arrayContains(selected, option) then
                        arrayRemove(selected, option)
                    else
                        table.insert(selected, option)
                    end
                    refreshRows()
                    emit()
                end))
            end

            item:Set(selected, true)
            return registerItem(item)
        end

        function section:AddDropdown(def)
            local selected = def.Default or ((def.Options and def.Options[1]) or nil)
            local container = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = holder,
            })
            local containerLayout = list(container, 8)
            self.Page.App.Maid:Give(containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                container.Size = UDim2.new(1, 0, 0, containerLayout.AbsoluteContentSize.Y)
            end))

            local button = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 46),
                Text = "",
                Parent = container,
            })
            buttonify(button)
            round(button, 12)
            local buttonStroke = stroke(button, 1)
            self.Page.App:_bindTheme(button, "BackgroundColor3", "SurfaceAlt")
            self.Page.App:_bindTheme(buttonStroke, "Color", "BorderSoft")

            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.4, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = def.Title,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
            self.Page.App:_bindTheme(titleLabel, "TextColor3", "Text")

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.4, 0, 0, 0),
                Size = UDim2.new(0.6, -12, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(selected or ""),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = button,
            })
            self.Page.App:_bindTheme(valueLabel, "TextColor3", "Muted")

            local listFrame = create("Frame", {
                Visible = false,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = container,
            })
            round(listFrame, 12)
            local listStroke = stroke(listFrame, 1)
            self.Page.App:_bindTheme(listFrame, "BackgroundColor3", "Surface")
            self.Page.App:_bindTheme(listStroke, "Color", "BorderSoft")
            pad(listFrame, 8, 8, 8, 8)
            local listLayout = list(listFrame, 6)

            local item = {
                Page = section.Page,
                Root = container,
                SearchTokens = { def.Title, table.concat(def.Options or {}, " "), section.Title },
            }

            function item:Get()
                return selected
            end

            function item:Set(value, silent)
                selected = value
                valueLabel.Text = tostring(value or "")
                if not silent and type(def.Callback) == "function" then
                    def.Callback(value)
                end
            end

            function item:RefreshTheme()
                valueLabel.TextColor3 = self.Page.App.Theme.Muted
            end

            self.Page.App.Maid:Give(button.MouseButton1Click:Connect(function()
                listFrame.Visible = not listFrame.Visible
            end))

            for _, option in ipairs(def.Options or {}) do
                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = option,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    Parent = listFrame,
                })
                buttonify(row)
                round(row, 10)
                local rowStroke = stroke(row, 1)
                self.Page.App:_bindTheme(row, "BackgroundColor3", "SurfaceAlt")
                self.Page.App:_bindTheme(row, "TextColor3", "Text")
                self.Page.App:_bindTheme(rowStroke, "Color", "BorderSoft")

                self.Page.App.Maid:Give(row.MouseButton1Click:Connect(function()
                    item:Set(option)
                    listFrame.Visible = false
                end))
            end

            item:Set(selected, true)
            return registerItem(item)
        end

        return section
    end

    self.Pages[id] = page
    table.insert(self.PageOrder, id)
    self.PageButtons[id] = self:_makeNavButton(id, page.Title, page.Subtitle)

    return page
end

function VantaApp:SelectPage(id)
    local page = self.Pages[id]
    if not page then
        return
    end

    if self.ActivePage then
        self.ActivePage.Frame.Visible = false
    end

    self.ActivePage = page
    page.Frame.Visible = true
    self.PageTitle.Text = page.Title
    self.PageSubtitle.Text = page.Subtitle or ""
    page:ApplySearch(self.State.Search)

    for _, pageId in ipairs(self.PageOrder) do
        self:_updatePageButton(pageId)
    end
end

function VantaApp:SetTheme(name)
    self.State.ThemeName = name
    self:_applyTheme()
end

function VantaApp:GetThemeNames()
    return self.ThemeModule.GetNames()
end

function VantaApp:Notify(title, text, duration)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        Parent = self.NotificationHolder,
    })
    self:_bindTheme(card, "BackgroundColor3", "Surface")
    round(card, 14)
    local cardStroke = stroke(card, 1)
    self:_bindTheme(cardStroke, "Color", "Accent")
    pad(card, 14, 14, 12, 12)

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    self:_bindTheme(titleLabel, "TextColor3", "Text")

    local bodyLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card,
    })
    self:_bindTheme(bodyLabel, "TextColor3", "Muted")

    task.delay(duration or 4, function()
        if card and card.Parent then
            destroySafe(card)
        end
    end)
end

function VantaApp:Destroy()
    self.Maid:Clean()
end

return VantaApp
