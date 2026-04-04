local Scanners = {}

function Scanners.Create(ctx)
    local API = {}

    function API.GetTargets()
        return {}
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
                or instance:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
    end

    function API.GetDisplayName(target)
        return target and target.Name or "Unknown"
    end

    function API.GetHealthText(_target)
        return nil
    end

    function API.GetProgressText(_target)
        return nil
    end

    function API.GetDistanceText(_target)
        return nil
    end

    return API
end

return Scanners