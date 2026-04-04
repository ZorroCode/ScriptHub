local Scanners = {}

function Scanners.Create(ctx)
    local services = ctx.Shared.Services
    local playersService = services.Players
    local workspace = services.Workspace
    local localPlayer = ctx.Shared.LocalPlayer

    local Instances = ctx.Shared.Instances
    local Formatting = ctx.Shared.Formatting
    local PlayersUtil = ctx.Shared.Players

    local API = {}

    local function safeFind(parent, childName)
        return Instances.SafeFind(parent, childName)
    end

    local function listChildren(folder)
        return Instances.ListChildren(folder)
    end

    function API.GetCharacter()
        return PlayersUtil.GetCharacter(localPlayer)
    end

    function API.GetHumanoid(model)
        if typeof(model) ~= "Instance" or not model:IsA("Model") then
            return nil
        end

        return model:FindFirstChildOfClass("Humanoid")
    end

    function API.IsHumanoidAlive(model)
        return Instances.IsAliveHumanoid(model)
    end

    function API.GetRootPart(instance)
        return Instances.GetRootPart(instance)
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

        return (localRoot.Position - targetRoot.Position).Magnitude
    end

    function API.GetDistanceText(instance)
        local distance = API.GetDistanceTo(instance)
        return Formatting.DistanceStuds(distance)
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

        return Formatting.Health(hum.Health, hum.MaxHealth)
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

        return Formatting.Progress(numberProgress)
    end

    function API.GetPlayerFromCharacterModel(model)
        return PlayersUtil.GetPlayerFromCharacter(playersService, model)
    end

    function API.IsLocalPlayerTarget(target)
        return PlayersUtil.IsLocalCharacter(playersService, localPlayer, target)
    end

    function API.GetActiveMap()
        local mapsFolder = safeFind(workspace, "MAPS")
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
        local playersFolder = safeFind(workspace, "PLAYERS")
        return playersFolder and playersFolder:FindFirstChild("ALIVE") or nil
    end

    function API.GetKillerFolder()
        local playersFolder = safeFind(workspace, "PLAYERS")
        return playersFolder and playersFolder:FindFirstChild("KILLER") or nil
    end

    function API.GetIgnoreFolder()
        return safeFind(workspace, "IGNORE")
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
        return Instances.CollectNamedTargetsRecursive(API.GetIgnoreFolder(), "Battery")
    end

    function API.GetTrapTargets()
        return Instances.CollectNamedTargetsRecursive(API.GetIgnoreFolder(), "Trap")
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