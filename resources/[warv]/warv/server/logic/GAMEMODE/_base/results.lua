function MatchLogic.CreateResultsHandler(options)
    local winnerXpBonus = 1000
    local teams = options.teams
    return function(reason)
        options.onStop()

        local draw, winningTeam, ffa
        if teams then
            local team1Point, team2Point = options.getScores()
            draw = team1Point == team2Point
            winningTeam = team1Point >= team2Point and 1 or 2
        else
            ffa = options.getFfaResult()
            draw = ffa.draw
        end

        local function didWin(player)
            if teams then return player.team == winningTeam end
            return ffa.winnerId ~= nil and tonumber(player.id) == tonumber(ffa.winnerId)
        end

        options.refreshPlayers()
        Wait(50)
        for _, player in pairs(options.players) do
            Players.AddKills(player.id, player.kill)
            Players.AddAssists(player.id, player.assist)
            Players.AddDeaths(player.id, player.death)
            Players.AddScores(player.id, player.score)

            if didWin(player) then
                Players.AddPlayerStatWin(player.id)
                Players.AddXp(player.id, winnerXpBonus)
                Challenges.Progress(player.id, "wins", 1)
            elseif draw then
                Players.AddPlayerStatDraw(player.id)
            else
                Players.AddPlayerStatLoose(player.id)
            end
            Players.AddPlayerStatGamePlayed(player.id)
            Challenges.Progress(player.id, "games", 1)
            Players.AddCreditBasedOnScore(player.id, player.score)
            Players.RefreshData(player.id)
            Players.SaveData(player.id)

        end
        options.refreshPlayers()

        for _, player in pairs(options.players) do
            options.scope:EmitClient(player.id, "EndGame", didWin(player), draw)
            Players.RefreshData(player.id)
        end

        return reason == "empty" and 0 or 35 * 1000
    end
end
