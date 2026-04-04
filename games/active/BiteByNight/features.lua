local Features = {}

local function featureListToMap(list)
    local map = {}

    for _, name in ipairs(list or {}) do
        if name == "Progress Tracker" then
            map.ProgressTracker = true
        else
            map[name] = true
        end
    end

    return map
end

function Features.Create(ctx, config, scanners, settings)
    local ESPManager = ctx.Loader:LoadModule(ctx.BaseUrl .. "/features/esp/manager.lua")
    local esp = ESPManager.new(ctx.Shared.Services.Workspace)

    local definitions = {
        Player = {
            Color = config.Colors.Player,
            GetTargets = function()
                return scanners.GetPlayerTargets()
            end,
            Features = function()
                return featureListToMap(settings.Player.Features)
            end,
            Enabled = function()
                return settings.Player.Enabled
            end,
        },

        Killer = {
            Color = config.Colors.Killer,
            GetTargets = function()
                return scanners.GetKillerTargets()
            end,
            Features = function()
                return featureListToMap(settings.Killer.Features)
            end,
            Enabled = function()
                return settings.Killer.Enabled
            end,
        },

        Generator = {
            Color = config.Colors.Generator,
            GetTargets = function()
                return scanners.GetGeneratorTargets()
            end,
            Features = function()
                return featureListToMap(settings.Generator.Features)
            end,
            Enabled = function()
                return settings.Generator.Enabled
            end,
        },

        Battery = {
            Color = config.Colors.Battery,
            GetTargets = function()
                return scanners.GetBatteryTargets()
            end,
            Features = function()
                return featureListToMap(settings.Battery.Features)
            end,
            Enabled = function()
                return settings.Battery.Enabled
            end,
        },

        Fuse = {
            Color = config.Colors.Fuse,
            GetTargets = function()
                return scanners.GetFuseTargets()
            end,
            Features = function()
                return featureListToMap(settings.Fuse.Features)
            end,
            Enabled = function()
                return settings.Fuse.Enabled
            end,
        },

        Trap = {
            Color = config.Colors.Trap,
            GetTargets = function()
                return scanners.GetTrapTargets()
            end,
            Features = function()
                return featureListToMap(settings.Trap.Features)
            end,
            Enabled = function()
                return settings.Trap.Enabled
            end,
        },
    }

    local controller = {}

    function controller.RefreshCategory(category)
        local def = definitions[category]
        if not def then
            return
        end

        if not def.Enabled() then
            esp:DestroyCategory(category)
            return
        end

        local targets = def.GetTargets()
        local validSet = {}
        local featureFlags = def.Features()

        for _, target in ipairs(targets) do
            if category == "Generator" and scanners.ShouldHideGeneratorFromProgressTracker(target, featureFlags) then
                esp:DestroyEntry(category, target)
            else
                validSet[target] = true

                esp:UpdateEntry(category, target, def.Color, featureFlags, {
                    GetRootPart = scanners.GetRootPart,
                    GetDisplayName = scanners.GetDisplayName,
                    GetHealthText = scanners.GetHealthText,
                    GetProgressText = scanners.GetProgressText,
                    GetDistanceText = scanners.GetDistanceText,
                })
            end
        end

        esp:PruneCategory(category, validSet)
    end

    function controller.RefreshAll()
        for category in pairs(definitions) do
            controller.RefreshCategory(category)
        end
    end

    function controller.DestroyCategory(category)
        esp:DestroyCategory(category)
    end

    function controller.DestroyAll()
        esp:DestroyAll()
    end

    function controller.GetDefinitions()
        return definitions
    end

    return controller
end

return Features