local Instances = {}

function Instances.SafeFind(parent, childName)
    return parent and parent:FindFirstChild(childName) or nil
end

function Instances.ListChildren(folder)
    if not folder then
        return {}
    end

    return folder:GetChildren()
end

function Instances.AppendUnique(targets, seen, object)
    if not object or seen[object] then
        return
    end

    if object:IsA("Model") or object:IsA("BasePart") then
        seen[object] = true
        table.insert(targets, object)
    end
end

function Instances.CollectNamedTargetsRecursive(root, targetName)
    local targets = {}
    local seen = {}

    if not root then
        return targets
    end

    if root.Name == targetName then
        Instances.AppendUnique(targets, seen, root)
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == targetName then
            Instances.AppendUnique(targets, seen, obj)
        end
    end

    return targets
end

function Instances.GetRootPart(instance)
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

function Instances.IsAliveHumanoid(model)
    if typeof(model) ~= "Instance" or not model:IsA("Model") then
        return false
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 or false
end

return Instances