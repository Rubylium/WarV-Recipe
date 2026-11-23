Chat = {}

AddEventHandler("warv:GetPlayerLobby", function(source, cb)
    cb(Players.GetPlayerCurrentLobby(source))
end)

AddEventHandler("warv:GetPlayersInLobby", function(id, cb)

    local game = Game.GetGameFromGameId(id)
    local ids = {}
    for k,v in pairs(game.players) do
        table.insert(ids, v.id)
    end

    cb(ids)
end)


function Chat.SendMessageToLobby(lobbyId, message)
    if lobbyId ~= 0 or lobbyId ~= nil then
        local game = Game.GetGameFromGameId(lobbyId)

        if game ~= nil then
            local outMessage = {
                color = { 161, 161, 161},
                multiline = true,
                args = { "System", message},
                mode = "all"
            }
        
            for k,v in pairs(game.players) do
                TriggerClientEvent('chat:addMessage', v.id, outMessage)
            end
        end
    end

end