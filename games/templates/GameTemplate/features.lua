local Features = {}

function Features.Create(ctx, _config, scanners, settings)
    local manager = ctx.Core.FeatureManager.new(ctx.App.Logger)

    manager:Register("Diagnostics", {
        Enabled = function()
            return settings.Diagnostics.Enabled
        end,
        Refresh = function()
            local targets = {}

            if scanners and type(scanners.GetTargets) == "function" then
                targets = scanners.GetTargets() or {}
            end

            ctx.App.State:Set("Diagnostics/LastTargetCount", #targets)
            return nil
        end,
        Destroy = function()
            ctx.App.State:Remove("Diagnostics/LastTargetCount")
        end,
    })

    manager:Register("Actions", {
        Enabled = function()
            return settings.Actions.Enabled
        end,
        Refresh = function()
            ctx.App.State:Set("Actions/LastRefreshAt", os.clock())
            return nil
        end,
        Destroy = function()
            ctx.App.State:Remove("Actions/LastRefreshAt")
        end,
    })

    return {
        RefreshCategory = function(category)
            manager:Refresh(category)
        end,

        RefreshAll = function()
            manager:RefreshAll()
        end,

        DestroyCategory = function(category)
            manager:Destroy(category)
        end,

        DestroyAll = function()
            manager:DestroyAll()
        end,

        GetDefinitions = function()
            return manager:GetDefinitions()
        end,
    }
end

return Features