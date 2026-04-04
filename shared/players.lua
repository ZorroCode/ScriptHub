local PlayersUtil = {}

function PlayersUtil.GetLocalPlayer(playersService)
    local players = playersService or game:GetService("Players")
    return players.LocalPlayer
end

function PlayersUtil.GetCharacter(player)
    return player and player.Character or nil
end

function PlayersUtil.GetPlayerFromCharacter(playersService, model)
    local players = playersService or game:GetService("Players")

    if not model or not model:IsA("Model") then
        return nil
    end

    for _, player in ipairs(players:GetPlayers()) do
        if player.Character == model then
            return player
        end
    end

    return nil
end

function PlayersUtil.IsLocalCharacter(playersService, localPlayer, model)
    if not model or not model:IsA("Model") then
        return false
    end

    if localPlayer and localPlayer.Character == model then
        return true
    end

    local owner = PlayersUtil.GetPlayerFromCharacter(playersService, model)
    return owner == localPlayer
end

return PlayersUtil