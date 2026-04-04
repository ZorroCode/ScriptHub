local Scanners = {}

function Scanners.Create(ctx)
    local Players = ctx.Shared.Services.Players
    local Workspace = ctx.Shared.Services.Workspace
    local LocalPlayer = ctx.Shared.LocalPlayer

    local API = {}

    local function safeFind(parent, childName)
        return parent and parent:FindFirstChild(childName) or nil
    end

    local function listChildren(folder)
        if not folder then
            return {}
        end

        return folder:GetChildren()
    end

    local function appendUnique(targets, seen, object)
        if not object or seen[object] then
            return
        end

        if object:IsA("Model") or object:IsA("BasePart") then
            seen[object] = true
            table.insert(targets, object)
        end
    end

    local function collectNamedTargetsRecursive(root, targetName)
        local targets = {}
        local seen = {}

        if not root then
            return targets
        end

        if root.Name == targetName then
            appendUnique(targets, seen, root)
        end

        for _, obj in ipairs(root:GetDescendants()) do
            if obj.Name == targetName then
                appendUnique(targets, seen, obj)
            end
        end

        return targets
    end

    function API.GetCharacter()
        return LocalPlayer and LocalPlayer.Character or nil
    end

    function API.GetHumanoid(model)
        if typeof(model) ~= "Instance" or not model:IsA("Model") then
            return nil
        end

        return model:FindFirstChildOfClass("Humanoid")
    end

    function API.IsHumanoidAlive(model)
        local hum = API.GetHumanoid(model)
        return hum and hum.Health > 0
    end

    function API.GetRootPart(instance)
        if not instance or not instance.Parent then
            return nil
        end

        if instance:IsA("BasePart") then
            return instance
        end

        if instance:IsA("Model") then
            return instance:FindFirstChild("HumanoidRootPart")
                or instance.PrimaryPart
                or instance:FindFirstChild("Head")
                or instance:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
    end

    function API.GetLocalRoot()
        local char = API.GetCharacter()
        return char and API.GetRootPart(char) or nil
    end

    function API.GetDistanceTo(instance)
        local localRoot = API.GetLocalRoot()
        local targetRoot = API.GetRootPart(instance)

        if not localRoot or not targetRoot then
            return nil
        end

        return math.floor((localRoot.Position - targetRoot.Position).Magnitude + 0.5)
    end

    function API.GetDistanceText(instance)
        local dist = API.GetDistanceTo(instance)
        if not dist then
            return nil
        end

        return string.format("%d studs", dist)
    end

    function API.GetDisplayName(model)
        if not model then
            return "Unknown"
        end

        local hum = API.GetHumanoid(model)
        if hum and hum.DisplayName and hum.DisplayName ~= "" then
            return hum.DisplayName
        end

        return model.Name
    end

    function API.GetHealthText(instance)
        local hum = API.GetHumanoid(instance)
        if not hum then
            return nil
        end

        local hp = math.floor(hum.Health + 0.5)
        local maxHp = math.floor(hum.MaxHealth + 0.5)

        return string.format("HP: %d/%d", hp, maxHp)
    end

    function API.GetProgressText(generator)
        if not generator then
            return nil
        end

        local progress = generator:GetAttribute("Progress")
        if progress == nil then
            return nil
        end

        local numberProgress = tonumber(progress)
        if not numberProgress then
            return nil
        end

        numberProgress = math.clamp(math.floor(numberProgress + 0.5), 0, 100)
        return string.format("Progress: %d%%", numberProgress)
    end

    function API.GetPlayerFromCharacterModel(model)
        if not model or not model:IsA("Model") then
            return nil
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == model then
                return player
            end
        end

        return nil
    end

    function API.IsLocalPlayerTarget(target)
        if not target or not target:IsA("Model") then
            return false
        end

        if LocalPlayer and target == LocalPlayer.Character then
            return true
        end

        local owner = API.GetPlayerFromCharacterModel(target)
        return owner == LocalPlayer
    end

    function API.GetActiveMap()
        local mapsFolder = safeFind(Workspace, "MAPS")
        if not mapsFolder then
            return nil
        end

        local direct = mapsFolder:FindFirstChild("GAME MAP")
        if direct then
            return direct
        end

        for _, child in ipairs(mapsFolder:GetChildren()) do
            if child:IsA("Model") or child:IsA("Folder") then
                if child:FindFirstChild("Generators")
                    or child:FindFirstChild("Batteries")
                    or child:FindFirstChild("FuseBoxes") then
                    return child
                end
            end
        end

        return nil
    end

    function API.GetAlivePlayersFolder()
        local playersFolder = safeFind(Workspace, "PLAYERS")
        return playersFolder and playersFolder:FindFirstChild("ALIVE") or nil
    end

    function API.GetKillerFolder()
        local playersFolder = safeFind(Workspace, "PLAYERS")
        return playersFolder and playersFolder:FindFirstChild("KILLER") or nil
    end

    function API.GetIgnoreFolder()
        return safeFind(Workspace, "IGNORE")
    end

    function API.ShouldHideGeneratorFromProgressTracker(generator, featureFlags)
        if not featureFlags.ProgressTracker then
            return false
        end

        if not generator or not generator:IsA("Model") then
            return false
        end

        local progress = generator:GetAttribute("Progress")
        if progress == nil then
            return false
        end

        return tonumber(progress) == 100
    end

    function API.ShouldHideFuseBox(fuseBox)
        if not fuseBox then
            return false
        end

        local inserted = fuseBox:GetAttribute("Inserted")
        if inserted == nil then
            return false
        end

        return inserted == true
    end

    function API.GetBatteryTargets()
        return collectNamedTargetsRecursive(API.GetIgnoreFolder(), "Battery")
    end

    function API.GetTrapTargets()
        return collectNamedTargetsRecursive(API.GetIgnoreFolder(), "Trap")
    end

    function API.GetPlayerTargets()
        local aliveFolder = API.GetAlivePlayersFolder()
        local targets = {}

        for _, obj in ipairs(listChildren(aliveFolder)) do
            if obj:IsA("Model") and not API.IsLocalPlayerTarget(obj) and API.IsHumanoidAlive(obj) then
                table.insert(targets, obj)
            end
        end

        return targets
    end

    function API.GetKillerTargets()
        local killerFolder = API.GetKillerFolder()
        local targets = {}

        for _, obj in ipairs(listChildren(killerFolder)) do
            if obj:IsA("Model") and not API.IsLocalPlayerTarget(obj) and API.IsHumanoidAlive(obj) then
                table.insert(targets, obj)
            end
        end

        if #targets == 0 and killerFolder and killerFolder:IsA("Model") then
            if not API.IsLocalPlayerTarget(killerFolder) and API.IsHumanoidAlive(killerFolder) then
                table.insert(targets, killerFolder)
            end
        end

        return targets
    end

    function API.GetGeneratorTargets()
        local map = API.GetActiveMap()
        local folder = map and map:FindFirstChild("Generators")
        local targets = {}

        for _, obj in ipairs(listChildren(folder)) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                table.insert(targets, obj)
            end
        end

        return targets
    end

    function API.GetFuseTargets()
        local map = API.GetActiveMap()
        local folder = map and map:FindFirstChild("FuseBoxes")
        local targets = {}

        for _, obj in ipairs(listChildren(folder)) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and not API.ShouldHideFuseBox(obj) then
                table.insert(targets, obj)
            end
        end

        return targets
    end

    return API
end

return Scanners