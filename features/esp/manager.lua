local ESPManager = {}
ESPManager.__index = ESPManager

local function makeBillboard(parentPart)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 180, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = parentPart
    billboard.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = false
    label.TextSize = 14
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextWrapped = true
    label.RichText = false
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = billboard

    return billboard, label
end

local function makeHighlight(target, color)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = target
    hl.Parent = target
    return hl
end

function ESPManager.new(workspaceRef)
    local self = setmetatable({}, ESPManager)

    self.Workspace = workspaceRef or game:GetService("Workspace")
    self.Entries = {}

    return self
end

function ESPManager:GetBucket(category)
    self.Entries[category] = self.Entries[category] or {}
    return self.Entries[category]
end

function ESPManager:DestroyEntry(category, target)
    local bucket = self:GetBucket(category)
    local entry = bucket[target]

    if not entry then
        return
    end

    if entry.Billboard then
        entry.Billboard:Destroy()
    end

    if entry.Highlight then
        entry.Highlight:Destroy()
    end

    bucket[target] = nil
end

function ESPManager:DestroyCategory(category)
    local bucket = self:GetBucket(category)

    for target in pairs(bucket) do
        self:DestroyEntry(category, target)
    end
end

function ESPManager:DestroyAll()
    for category in pairs(self.Entries) do
        self:DestroyCategory(category)
    end
end

function ESPManager:EnsureEntry(category, target, color)
    local bucket = self:GetBucket(category)
    local entry = bucket[target]

    if entry and entry.Target ~= target then
        self:DestroyEntry(category, target)
        entry = nil
    end

    if not entry then
        entry = {
            Target = target,
            Color = color,
            Billboard = nil,
            Label = nil,
            Highlight = nil,
        }

        bucket[target] = entry
    end

    return entry
end

function ESPManager:EnsureBillboard(entry, targetRoot)
    if entry.Billboard and entry.Label and entry.Billboard.Parent then
        if entry.Billboard.Adornee ~= targetRoot then
            entry.Billboard.Adornee = targetRoot
        end
        return
    end

    local billboard, label = makeBillboard(targetRoot)
    entry.Billboard = billboard
    entry.Label = label
    entry.Billboard.Parent = self.Workspace
end

function ESPManager:EnsureHighlight(entry)
    if entry.Highlight and entry.Highlight.Parent then
        entry.Highlight.FillColor = entry.Color
        entry.Highlight.OutlineColor = entry.Color
        entry.Highlight.Adornee = entry.Target
        return
    end

    entry.Highlight = makeHighlight(entry.Target, entry.Color)
end

function ESPManager:UpdateEntry(category, target, color, featureFlags, resolver)
    if not target or not target.Parent then
        return
    end

    local entry = self:EnsureEntry(category, target, color)
    entry.Color = color

    local root = resolver.GetRootPart(target)
    if not root then
        self:DestroyEntry(category, target)
        return
    end

    local wantsText = featureFlags.NameTag
        or featureFlags.Health
        or featureFlags.Stamina
        or featureFlags.Distance
        or featureFlags.ProgressTracker

    local wantsHighlight = featureFlags.Highlight

    if wantsText then
        self:EnsureBillboard(entry, root)

        local lines = {}

        if featureFlags.NameTag then
            local text = resolver.GetDisplayName(target)
            if text then
                table.insert(lines, text)
            end
        end

        if featureFlags.Health then
            local text = resolver.GetHealthText(target)
            if text then
                table.insert(lines, text)
            end
        end

        if featureFlags.Stamina then
            local text = resolver.GetStaminaText and resolver.GetStaminaText(target)
            if text then
                table.insert(lines, text)
            end
        end

        if featureFlags.ProgressTracker then
            local text = resolver.GetProgressText(target)
            if text then
                table.insert(lines, text)
            end
        end

        if featureFlags.Distance then
            local text = resolver.GetDistanceText(target)
            if text then
                table.insert(lines, text)
            end
        end

        local finalText = table.concat(lines, "\n")

        if finalText == "" then
            entry.Billboard.Enabled = false
        else
            entry.Billboard.Enabled = true
            entry.Label.Text = finalText
            entry.Label.TextColor3 = color
        end
    else
        if entry.Billboard then
            entry.Billboard:Destroy()
            entry.Billboard = nil
            entry.Label = nil
        end
    end

    if wantsHighlight then
        self:EnsureHighlight(entry)
    else
        if entry.Highlight then
            entry.Highlight:Destroy()
            entry.Highlight = nil
        end
    end
end

function ESPManager:PruneCategory(category, validSet)
    local bucket = self:GetBucket(category)

    for target in pairs(bucket) do
        if not validSet[target] or not target.Parent then
            self:DestroyEntry(category, target)
        end
    end
end

return ESPManager
