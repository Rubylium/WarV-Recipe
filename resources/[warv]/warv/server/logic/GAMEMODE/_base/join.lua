function MatchLogic.AttachJoinHandler(instance, match)
    function match.GetPlayerCountPerTeam()
        local playersTeam1 = 0
        local playersTeam2 = 0

        for _, player in pairs(match.gamePlayersData) do
            if player.team == 1 then
                playersTeam1 = playersTeam1 + 1
            elseif player.team == 2 then
                playersTeam2 = playersTeam2 + 1
            end
        end

        return playersTeam1, playersTeam2
    end

    function match.MakePlayersJoinGame(players)
        local playersTeam1, playersTeam2 = match.GetPlayerCountPerTeam()
        local playersCountToJoin = #players
        local preferredTeam = playersTeam1 < playersTeam2 and 1 or 2
        local alternateTeam = preferredTeam == 1 and 2 or 1
        local counts = {[1] = playersTeam1, [2] = playersTeam2}

        local teamToJoin = nil
        if counts[preferredTeam] + playersCountToJoin <= match.maxPlayersPerTeam then
            teamToJoin = preferredTeam
        elseif counts[alternateTeam] + playersCountToJoin <= match.maxPlayersPerTeam then
            teamToJoin = alternateTeam
        end
        if teamToJoin == nil then
            return false
        end

        for _, playerSource in pairs(players) do
            match.AddPlayerToGame(playerSource, teamToJoin)
        end
        return true
    end

    function match.InitPlayers()
        local groups = {}
        for _, player in pairs(match.gameDATA.players) do
            if Groups.IsPlayerInAnyGroup(player.id) then
                local group = Groups.GetPlayerGroup(player.id)
                if group ~= nil then
                    groups[group] = groups[group] or {}
                    table.insert(groups[group], player.id)
                else
                    match.AddPlayerToGame(player.id)
                end
            else
                match.AddPlayerToGame(player.id)
            end
        end

        for _, groupPlayers in pairs(groups) do
            match.MakePlayersJoinGame(groupPlayers)
        end
    end

    function instance:canPlayerJoin(players)
        local playersTeam1, playersTeam2 = match.GetPlayerCountPerTeam()
        return playersTeam1 + #players <= match.maxPlayersPerTeam
            or playersTeam2 + #players <= match.maxPlayersPerTeam
    end

    function instance:addPlayers(players)
        return match.MakePlayersJoinGame(players)
    end
end
