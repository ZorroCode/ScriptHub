local Hub = {}

function Hub.Create(window, spec)
    spec = spec or {}

    local pages = {}
    for _, pageSpec in ipairs(spec.Pages or {}) do
        local tab = window:CreateTab(pageSpec.Name, pageSpec.Icon)
        tab:SetHeader(pageSpec.HeaderTitle or pageSpec.Name, pageSpec.HeaderSubtitle or pageSpec.Description or "")
        pages[pageSpec.Key or pageSpec.Name] = tab
    end

    return {
        Pages = pages,
        Notify = function(_, title, body, duration)
            if window.Notify then
                window:Notify(title, body, duration)
            end
        end,
        Window = window,
    }
end

return Hub
