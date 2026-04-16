return {
    Init = function(ctx)
        local GameFactory = ctx.Core.GameFactory

        return GameFactory.Boot(ctx, {
            Config = ctx.Loader:LoadGameModule("Config"),
            Scanners = ctx.Loader:LoadGameModule("Scanners"),
            Features = ctx.Loader:LoadGameModule("Features"),
            UI = ctx.Loader:LoadGameModule("UI"),
        })
    end,
}