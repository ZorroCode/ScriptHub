local Router = {}

local function normalizePlaceIds(placeIds)
    local map = {}

    for _, placeId in ipairs(placeIds or {}) do
        if type(placeId) == "number" then
            map[placeId] = true
        end
    end

    return map
end

function Router.FindGame(registry, currentPlaceId)
    if type(registry) ~= "table" then
        return nil, "Invalid registry table."
    end

    for _, gameEntry in ipairs(registry.Games or {}) do
        if gameEntry.Enabled then
            local validPlaceIds = normalizePlaceIds(gameEntry.PlaceIds)

            if validPlaceIds[currentPlaceId] then
                return gameEntry
            end
        end
    end

    if registry.Universal and registry.Universal.Enabled then
        return registry.Universal
    end

    return nil, string.format("No supported game found for PlaceId: %s", tostring(currentPlaceId))
end

return Router