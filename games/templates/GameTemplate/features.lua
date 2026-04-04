local Features = {}

function Features.Create(_ctx, _config, _scanners, settings)
    local controller = {}

    function controller.RefreshCategory(_category)
    end

    function controller.RefreshAll()
    end

    function controller.DestroyCategory(_category)
    end

    function controller.DestroyAll()
    end

    function controller.GetSettings()
        return settings
    end

    return controller
end

return Features