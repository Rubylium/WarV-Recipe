

Citizen.CreateThread(function()
    local pCount = 0
    while true do
        local players = #GetPlayers()
        if pCount ~= players then
            GlobalState.players = players
            pCount = players
        end


        local lobbys = {}
        for k,v in pairs(Game.games) do

            local ping = 0
            for _,player in pairs(v.players) do
                ping = ping + GetPlayerPing(player.id)
            end
            if ping ~= 0 then
                ping = ping / #v.players
            end

            table.insert(lobbys, {
                gameId = v.gameId,
                gamemode = v.gamemode,
                gameMap = v.gameMap,
                playerCount = #v.players,
                maxPlayers = v.maxPlayer,
                ping = ping,
                inMatchmaking = v.gameWaitingToStart,
            })
        end

        GlobalState.lobbys = lobbys

        Wait(5000)
    end
end)