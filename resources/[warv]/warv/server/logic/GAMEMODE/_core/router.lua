RegisterNetEvent("warv:GamemodeEvent", function(gameId, generation, eventName, arguments)
    local playerSource = source
    local session = GamemodeSessionManager.Get(gameId)
    if session == nil
        or session.destroyed
        or session.generation ~= tonumber(generation)
        or Players.GetPlayerCurrentLobby(playerSource) ~= gameId
        or type(eventName) ~= "string"
        or type(arguments) ~= "table" then
        return
    end

    local route = session.netRoutes[eventName]
    if route == nil then
        return
    end
    session.scope:Run("event:" .. eventName, route, playerSource, table.unpack(arguments, 1, arguments.n or #arguments))
end)

RegisterNetEvent("warv:GamemodeClientFailed", function(gameId, generation, reason)
    local playerSource = source
    local session = GamemodeSessionManager.Get(gameId)
    if session == nil
        or session.generation ~= tonumber(generation)
        or Players.GetPlayerCurrentLobby(playerSource) ~= gameId then
        return
    end
    WarningPrint("Client fail [" .. playerSource .. "] gamemode [" .. gameId .. "]: " .. tostring(reason))
    Game.RemovePlayerFromGame(gameId, playerSource, "client_runtime_error")
    TriggerClientEvent("warv:GoBackToLobby", playerSource, gameId)
end)

AddEventHandler("explosionEvent", function(sender, explosion)
    sender = tonumber(sender)
    if sender == nil or not Players.DoesPlayerExist(sender) then
        return
    end
    local gameId = Players.GetPlayerCurrentLobby(sender)
    local session = gameId and GamemodeSessionManager.Get(gameId) or nil
    if session == nil or session.destroyed or session.instance == nil then
        return
    end
    if session.instance.onExplosion then
        session.scope:Run("event:explosion", session.instance.onExplosion, session.instance, sender, explosion)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    for gameId in pairs(GamemodeSessionManager.sessions) do
        GamemodeSessionManager.Destroy(gameId, "resource_stop")
    end
end)
