Game = {}
Game.games = {}
Game.gamesById = {}
Game.GamesPerGamemode = {
    ranked = {},
    unranked = {},
}
Game.DefaultLobbyValues = {
    gameWaitingToStartTimer = 60,
    gameStartDefaultPlayerNum = 2,
    gameTimer = 600,
    gameTimerRanked = 600
}
Game.pingKickCount = 0
Game.health = {
    lastCycleAt = 0,
    lastSuccessAt = 0,
    consecutiveFailures = 0,
    lastError = nil,
}

if SharedConfig.devmod then
    Game.DefaultLobbyValues.gameStartDefaultPlayerNum = 1
end

local function trace(err)
    return debug.traceback(tostring(err), 2)
end

function Game.Create(private, maxPlayer, gamemode, ranked, aimMode)
    local definition = GamemodeDefinitions.Get(gamemode)
    local maps1, maps2, mapR, mapError = Game.GenerateNewMapsForLobby(gamemode)
    if maps1 == nil then
        return nil, mapError
    end

    local game = {
        gameId = GenerateUuid(),
        state = GamemodeSessionState.Waiting,
        sessionGeneration = 0,
        gameWaitingToStart = true,
        gameCanStart = false,
        gameWaitingToStartTimer = Game.DefaultLobbyValues.gameWaitingToStartTimer,
        gameStarting = false,
        gameStarted = false,
        gameFinish = false,
        gameTimer = Game.DefaultLobbyValues.gameTimer,
        gameLocked = false,

        gameMapVoted = false,
        gameMapVote1 = 0,
        gameMapVote2 = 0,
        gameMapVoteRandom = 0,

        gameMap1 = maps1,
        gameMap2 = maps2,
        mapRandom = mapR,

        gameMap = mapR,
        gameBucket = Buckets.GetFreeBucket(),

        inMatchmaking = private,
        maxPlayer = maxPlayer,
        gamemode = gamemode,
        modeId = definition.id,
        ranked = ranked,
        aimMode = aimMode,


        players = {},
    }

    if game.ranked then
        game.gameTimer = Game.DefaultLobbyValues.gameTimerRanked
    end

    table.insert(Game.games, game)
    Game.gamesById[game.gameId] = game
    Game.AddGamePerGamemode(gamemode, ranked)

    return game.gameId
end

function Game.RefreshPlayerProfile(player)
    local stats = Players.GetStats(player.id)
    player.level = Players.GetLevel(player.id)
    player.prestige = Players.GetPrestige(player.id)
    player.ranking = Players.GetRanking(player.id)
    player.emblem = Players.GetEmblesId(player.id)
    player.logo = Players.GetLogoId(player.id)
    player.kills = tonumber(Players.GetKills(player.id)) or 0
    player.deaths = tonumber(Players.GetDeaths(player.id)) or 0
    player.winStreak = tonumber(stats.winStreak) or 0
    player.bestStreak = tonumber(stats.bestWinStreak) or 0
    player.wins = tonumber(stats.win) or 0
    player.losses = tonumber(stats.loose) or 0
end

function Game.ResetLobbyForId(id, fromSession)
    if not fromSession then
        GamemodeSessionManager.Destroy(id, "lobby_reset")
    end
    for k, v in pairs(Game.games) do
        if v.gameId == id then
            local maps1, maps2, mapR, mapError = Game.GenerateNewMapsForLobby(v.gamemode)
            if maps1 == nil then
                CriticalPrint("Lobby reset [" .. id .. "]: " .. tostring(mapError))
                return false
            end

            v.gameWaitingToStart = true
            v.state = GamemodeSessionState.Waiting
            v.gameCanStart = false
            v.gameWaitingToStartTimer = Game.DefaultLobbyValues.gameWaitingToStartTimer
            v.gameStarting = false
            v.gameStarted = false
            v.gameFinish = false
            v.gameLocked = false
            if not v.ranked then
                v.gameTimer = Game.DefaultLobbyValues.gameTimer
            else
                v.gameTimer = Game.DefaultLobbyValues.gameTimerRanked
            end

            v.gameMapVoted = false
            v.gameMapVote1 = 0
            v.gameMapVote2 = 0
            v.gameMapVoteRandom = 0

            v.gameMap1 = maps1
            v.gameMap2 = maps2
            v.mapRandom = mapR

            v.gameMap = mapR

            for _, player in pairs(v.players) do
                player.voted = false
                Game.RefreshPlayerProfile(player)
            end

            Game.RefreshCanStartStatus(v.gameId)
            Game.RefreshGameDataForLobby(v, v.players)


            break
        end
    end

    return true
end

function Game.GetGameFromGameId(id)
    return Game.gamesById[id]
end

function Game.GenerateNewMapsForLobby(gamemode)
    local maps = ShuffleTable(MatchmakingConfig.GetEligibleMapNames(gamemode))
    if #maps < 3 then
        return nil, nil, nil, "not enough maps [" .. tostring(gamemode) .. "]"
    end

    return maps[1], maps[2], maps[3]
end

function Game.VoteForMap(gameId, index, source)
    for k, v in pairs(Game.games) do
        if v.gameId == gameId then

            for j, i in pairs(v.players) do
                if i.id == source then

                    if i.voted == false then
                        if index == 1 then
                            v.gameMapVote1 = v.gameMapVote1 + 1
                        elseif index == 2 then
                            v.gameMapVote2 = v.gameMapVote2 + 1
                        elseif index == 3 then
                            v.gameMapVoteRandom = v.gameMapVoteRandom + 1
                        end
                        i.voted = true
                    end
                    break
                end
            end

            Game.RefreshGameDataForLobby(v, v.players)
            break
        end
    end
end

function Game.RefreshCanStartStatus(index)
    for k, v in pairs(Game.games) do
        if v.gameId == index then
            local session = GamemodeSessionManager.Get(v.gameId)
            if session ~= nil then
                if #v.players < Game.DefaultLobbyValues.gameStartDefaultPlayerNum and session:IsRunning() then
                    GamemodeSessionManager.End(v.gameId, "not_enough_players")
                end
                break
            end
            if #v.players >= Game.DefaultLobbyValues.gameStartDefaultPlayerNum then
                v.gameCanStart = true
                v.state = GamemodeSessionState.Countdown
            else
                v.gameWaitingToStartTimer = Game.DefaultLobbyValues.gameWaitingToStartTimer
                v.gameCanStart = false
                v.gameWaitingToStart = true
                v.state = GamemodeSessionState.Waiting
            end

            break
        end
    end
end

function Game.RefreshGameDataForLobby(data, lobby)

    local snapshot = GameSnapshot.Build(data)
    for k, v in pairs(lobby) do
        TriggerClientEvent("warv:RefreshLobbyData", v.id, snapshot)
    end
end

function Game.StartGame(gameID)
    local game = Game.GetGameFromGameId(gameID)
    if game == nil then
        return false, "lobby not found"
    end

    local started, sessionOrError = GamemodeSessionManager.Start(game)
    if not started then
        return false, sessionOrError
    end

    Game.RefreshGameDataForLobby(game, game.players)
    for _, player in ipairs(game.players) do
        TriggerClientEvent("warv:StartGame", player.id, false, {
            gameId = game.gameId,
            generation = sessionOrError.generation,
            modeId = sessionOrError.definition.id,
        })
    end

    return true
end

function Game.CreateFakeGameTeamsCount(gameID)
    local team1Count = 0
    local team2Count = 0
    local processedPlayers = {}

    local function JoinBestTeam(count)
        if team1Count > team2Count then
            team2Count = team2Count + count
        else
            team1Count = team1Count + count
        end
    end

    local game = Game.GetGameFromGameId(gameID)
    if game == nil then
        return team1Count, team2Count
    end

    local lobbyPlayers = {}
    for _, player in ipairs(game.players) do
        lobbyPlayers[player.id] = true
    end

    for _, player in ipairs(game.players) do
        if not processedPlayers[player.id] then
            if not Groups.IsPlayerInAnyGroup(player.id) then
                processedPlayers[player.id] = true
                JoinBestTeam(1)
            else
                local groupId = Groups.GetPlayerGroup(player.id)
                if groupId ~= nil then
                    local groupSize = 0

                    for _, memberSource in pairs(Groups.GetPlayersInGroup(groupId)) do
                        if lobbyPlayers[memberSource] and not processedPlayers[memberSource] then
                            processedPlayers[memberSource] = true
                            groupSize = groupSize + 1
                        end
                    end

                    if groupSize > 0 then
                        JoinBestTeam(groupSize)
                    else
                        processedPlayers[player.id] = true
                        JoinBestTeam(1)
                    end
                else
                    processedPlayers[player.id] = true
                    JoinBestTeam(1)
                end
            end
        end
    end

    Console.DebugPrint("Team 1: " .. team1Count .. " Team 2: " .. team2Count)
    return team1Count, team2Count
end

function Game.CanPlayerJoinGame(gameID, group)
    local game = Game.GetGameFromGameId(gameID)
    if game == nil or #group == 0 then
        return false, false
    end

    if game.gameLocked or game.gameStarting or #game.players + #group > game.maxPlayer then
        return false, false
    end

    local existingPlayers = {}
    for _, player in ipairs(game.players) do
        existingPlayers[player.id] = true
    end

    for _, playerSource in ipairs(group) do
        if existingPlayers[playerSource]
            or not Players.DoesPlayerExist(playerSource)
            or Players.GetPlayerCurrentLobby(playerSource) ~= 0 then
            return false, false
        end
    end

    if game.gameWaitingToStart then
        local definition = GamemodeDefinitions.Get(game.gamemode)
        if definition == nil or definition.capabilities.teams ~= true then
            return true, false
        end

        local team1Count, team2Count = Game.CreateFakeGameTeamsCount(gameID)
        local maxPlayersPerTeam = math.ceil(game.maxPlayer / 2)
        return team1Count + #group <= maxPlayersPerTeam or team2Count + #group <= maxPlayersPerTeam, false
    end

    if game.gameStarted and game.gameTimer >= 10 then
        local session = GamemodeSessionManager.Get(gameID)
        if session == nil or session.instance == nil or session.instance.canPlayerJoin == nil then
            return false, false
        end
        local success, canJoin = session.scope:Run("canPlayerJoin", session.instance.canPlayerJoin, session.instance, group)
        return success and canJoin == true, success and canJoin == true
    end

    return false, false
end

function Game.AddPlayerToGame(gameID, sources, fastLoad)
    local game = Game.GetGameFromGameId(gameID)
    if game == nil or #sources == 0 then
        return false, "no lobby"
    end

    if #game.players + #sources > game.maxPlayer then
        return false, "lobby is full"
    end

    local existingPlayers = {}
    for _, player in ipairs(game.players) do
        existingPlayers[player.id] = true
    end

    local sourceSet = {}
    local playerRecords = {}

    for _, playerSource in ipairs(sources) do
        if sourceSet[playerSource]
            or existingPlayers[playerSource]
            or not Players.DoesPlayerExist(playerSource)
            or GetPlayerPing(playerSource) == 0
            or Players.GetPlayerCurrentLobby(playerSource) ~= 0 then
            return false, "player cannot join"
        end

        sourceSet[playerSource] = true
        local playerName = Players.GetName(playerSource) or GetPlayerName(playerSource) or tostring(playerSource)

        local playerRecord = {
            id = playerSource,
            uid = Players.GetPlayerUid(playerSource),
            name = playerName,
            perms = Players.GetPerms(playerSource),
            inGroup = Groups.IsPlayerInAnyGroup(playerSource),
            gameLoaded = false,
            voted = false,
        }
        Game.RefreshPlayerProfile(playerRecord)
        table.insert(playerRecords, playerRecord)
    end

    for _, playerRecord in ipairs(playerRecords) do
        table.insert(game.players, playerRecord)
        Players.SetPlayerGameId(playerRecord.id, game.gameId)
        Players.SetPlayerCurrentLobby(playerRecord.id, game.gameId)
        Buckets.SetPlayer(playerRecord.id, game.gameBucket)
    end

    if fastLoad then
        local session = GamemodeSessionManager.Get(game.gameId)
        local joinedStartedGame = false
        if session and session.instance and session.instance.addPlayers then
            local success, joined = session.scope:Run("addPlayers", session.instance.addPlayers, session.instance, sources)
            joinedStartedGame = success and joined == true
        end

        if not joinedStartedGame then
            for _, playerSource in ipairs(sources) do
                Game.RemovePlayerFromGame(gameID, playerSource, "late_join_rejected")
            end
            return false, "late join rejected"
        end
    end

    if game.gameWaitingToStart then
        Game.RefreshCanStartStatus(gameID)
    end

    Game.RefreshGameDataForLobby(game, game.players)
    for _, playerRecord in ipairs(playerRecords) do
        Chat.SendMessageToLobby(game.gameId, "[" .. playerRecord.name .. "] Joined the lobby")
        if fastLoad then
            local session = GamemodeSessionManager.Get(game.gameId)
            TriggerClientEvent("warv:StartGame", playerRecord.id, true, {
                gameId = game.gameId,
                generation = session.generation,
                modeId = session.definition.id,
            })
        end
    end

    return true
end

function Game.RemovePlayerFromGame(gameID, source, reason)
    local game = Game.GetGameFromGameId(gameID)
    if game == nil then
        return false
    end

    for index = #game.players, 1, -1 do
        if game.players[index].id == source then
            table.remove(game.players, index)

            Players.SetPlayerGameId(source, 0)
            Players.SetPlayerCurrentLobby(source, 0)
            local session = GamemodeSessionManager.Get(gameID)
            if session and session.instance and session.instance.onPlayerLeave then
                session.scope:Run("onPlayerLeave", session.instance.onPlayerLeave, session.instance, source, reason or "left")
            end
            Game.RefreshCanStartStatus(game.gameId)
            Game.RefreshGameDataForLobby(game, game.players)

            if GetPlayerPing(source) > 0 then
                Buckets.SetPlayer(source, source)
                TriggerClientEvent("warv:LobbyLeft", source)
            end

            return true
        end
    end

    return false
end

function Game.RemovePlayerFromAnyGame(source)
    local removed = false

    for _, game in pairs(Game.games) do
        while Game.RemovePlayerFromGame(game.gameId, source) do
            removed = true
        end
    end

    return removed
end

function Game.AddGamePerGamemode(gamemode, ranked)
    if ranked then
        if Game.GamesPerGamemode.ranked[gamemode] == nil then
            Game.GamesPerGamemode.ranked[gamemode] = 0
        end
        Game.GamesPerGamemode.ranked[gamemode] = Game.GamesPerGamemode.ranked[gamemode] + 1
    else
        if Game.GamesPerGamemode.unranked[gamemode] == nil then
            Game.GamesPerGamemode.unranked[gamemode] = 0
        end
        Game.GamesPerGamemode.unranked[gamemode] = Game.GamesPerGamemode.unranked[gamemode] + 1
    end



end

function Game.RemoveGamePerGamemode(gamemode, ranked)
    local gameType = ranked and Game.GamesPerGamemode.ranked or Game.GamesPerGamemode.unranked
    gameType[gamemode] = math.max((gameType[gamemode] or 0) - 1, 0)
end

function Game.DeleteGame(gameID)
    for index = #Game.games, 1, -1 do
        local game = Game.games[index]
        if game.gameId == gameID then
            GamemodeSessionManager.Destroy(gameID, "lobby_deleted")
            SpawnLogic.RemoveLobbyFromQueue(game.gameId)
            Game.RemoveGamePerGamemode(game.gamemode, game.ranked)
            Buckets.LeaveBucket(game.gameBucket)
            Game.gamesById[game.gameId] = nil
            table.remove(Game.games, index)
            return true
        end
    end

    return false
end

function Game.SendGameDataToPlayer(source, data)
    TriggerClientEvent("warv:RefreshLobbyData", source, GameSnapshot.Build(data))
end

function Game.RemoveDisconnectedPlayers(game)
    local disconnectedPlayers = {}

    for _, player in ipairs(game.players) do
        if not Players.DoesPlayerExist(player.id) or GetPlayerPing(player.id) == 0 then
            table.insert(disconnectedPlayers, player.id)
        end
    end

    for _, playerSource in ipairs(disconnectedPlayers) do
        Game.RemovePlayerFromGame(game.gameId, playerSource, "disconnected")
    end
end

function Game.RemoveDuplicatePlayers(game)
    local seen = {}

    for index = #game.players, 1, -1 do
        local playerSource = game.players[index].id
        if seen[playerSource] then
            table.remove(game.players, index)
        else
            seen[playerSource] = true
        end
    end
end

function Game.ProcessGameTick(game)
    local activeSession = GamemodeSessionManager.Get(game.gameId)
    if activeSession ~= nil and activeSession:HasLoadingTimedOut() then
        activeSession:Fail("loadingTimeout", "loading timeout")
        return
    end

    if game.gameStarted then
        if #game.players <= 1 and not SharedConfig.devmod then
            GamemodeSessionManager.End(game.gameId, "not_enough_players")
            return
        end

        game.gameTimer = game.gameTimer - 1
        if game.gameTimer <= 0 then
            GamemodeSessionManager.End(game.gameId, "time_limit")
        end
        return
    end

    if not game.gameCanStart or not game.gameWaitingToStart then
        return
    end

    game.gameWaitingToStartTimer = game.gameWaitingToStartTimer - 1

    if game.gameWaitingToStartTimer <= 0 then
        game.gameWaitingToStart = false
        game.gameStarting = true

        local started, startError = Game.StartGame(game.gameId)
        if not started then
            if GamemodeSessionManager.Get(game.gameId) == nil then
                game.state = GamemodeSessionState.Waiting
                game.gameWaitingToStart = true
                game.gameStarting = false
                game.gameWaitingToStartTimer = Game.DefaultLobbyValues.gameWaitingToStartTimer
            end
            WarningPrint("Lobby start [" .. game.gameId .. "]: " .. tostring(startError))
        end

        return
    end

    if not game.gameMapVoted and game.gameWaitingToStartTimer <= 30 then
        if game.gameMapVote1 > game.gameMapVote2 and game.gameMapVote1 > game.gameMapVoteRandom then
            game.gameMap = game.gameMap1
        elseif game.gameMapVote2 > game.gameMapVote1 and game.gameMapVote2 > game.gameMapVoteRandom then
            game.gameMap = game.gameMap2
        else
            game.gameMap = game.mapRandom
        end

        game.players = ShuffleTable(game.players)
        Game.RemoveDuplicatePlayers(game)
        game.gameMapVoted = true
        Game.RefreshGameDataForLobby(game, game.players)
    end
end

function Game.RunMaintenanceCycle()
    local gameIds = {}
    for _, game in ipairs(Game.games) do
        table.insert(gameIds, game.gameId)
    end

    local errors = {}
    for _, gameId in ipairs(gameIds) do
        local game = Game.GetGameFromGameId(gameId)
        if game ~= nil then
            local ok, err = xpcall(function()
                Game.RemoveDisconnectedPlayers(game)
                if #game.players > 0 then
                    Game.ProcessGameTick(game)
                end
            end, trace)

            if not ok then
                table.insert(errors, "lobby " .. gameId .. ": " .. err)
                CriticalPrint("Lobby [" .. gameId .. "]: " .. err)
            end
        end
    end

    for index = #Game.games, 1, -1 do
        if #Game.games[index].players == 0 then
            Game.DeleteGame(Game.games[index].gameId)
        end
    end

    if #errors > 0 then
        return false, table.concat(errors, "\n")
    end

    return true
end

Citizen.CreateThread(function()
    while true do
        local success, cycleResult, cycleError = xpcall(Game.RunMaintenanceCycle, trace)

        Game.health.lastCycleAt = os.time()

        if success and cycleResult then
            Game.health.lastSuccessAt = Game.health.lastCycleAt
            Game.health.consecutiveFailures = 0
            Game.health.lastError = nil
        else
            Game.health.consecutiveFailures = Game.health.consecutiveFailures + 1
            Game.health.lastError = success and cycleError or cycleResult
            CriticalPrint("Lobby cycle: " .. tostring(Game.health.lastError))
        end

        Wait(1000)
    end
end)


RegisterNetEvent("warv:VoteForMap")
AddEventHandler("warv:VoteForMap", function(gameID, index)
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    Game.VoteForMap(gameID, index, source)
end)

RegisterNetEvent("warv:LeaveLobby")
AddEventHandler("warv:LeaveLobby", function()
    local playerSource = source
    local banned, type = Players.IsBanned(playerSource)
    if banned then
        DropPlayer(playerSource, Ban.type[type].desc)
        return
    end

    local leavePlayers = Groups.GetLeaderActionPlayers(playerSource, "leave the lobby")
    if leavePlayers == nil then
        return
    end

    for _, memberSource in ipairs(leavePlayers) do
        local gameID = Players.GetPlayerCurrentLobby(memberSource)
        local removed = false

        if gameID ~= nil and gameID ~= 0 and gameID ~= "0" then
            removed = Game.RemovePlayerFromGame(gameID, memberSource, "squad_left_lobby")
            if removed then
                Chat.SendMessageToLobby(gameID, "[" .. Players.GetName(memberSource) .. "] Left the lobby")
            end
        end

        if not removed then
            removed = Game.RemovePlayerFromAnyGame(memberSource)
        end

        if not removed then
            Players.SetPlayerGameId(memberSource, 0)
            Players.SetPlayerCurrentLobby(memberSource, 0)
            if GetPlayerPing(memberSource) > 0 then
                Buckets.SetPlayer(memberSource, memberSource)
                TriggerClientEvent("warv:LobbyLeft", memberSource)
            end
        end

        if GetPlayerPing(memberSource) > 0 then
            TriggerClientEvent("groups:SendBackToWait", memberSource)
        end
    end
end)

RegisterNetEvent("warv:LeaveSquadGame")
AddEventHandler("warv:LeaveSquadGame", function()
    local playerSource = source
    local banned, type = Players.IsBanned(playerSource)
    if banned then
        DropPlayer(playerSource, Ban.type[type].desc)
        return
    end

    local leavePlayers = Groups.GetLeaderActionPlayers(playerSource, "leave the match")
    if leavePlayers == nil then
        return
    end

    for _, memberSource in ipairs(leavePlayers) do
        local gameID = Players.GetPlayerCurrentLobby(memberSource)
        local removed = false

        if gameID ~= nil and gameID ~= 0 and gameID ~= "0" then
            removed = Game.RemovePlayerFromGame(gameID, memberSource, "squad_left_match")
        end

        if not removed then
            removed = Game.RemovePlayerFromAnyGame(memberSource)
        end

        if not removed then
            Players.SetPlayerGameId(memberSource, 0)
            Players.SetPlayerCurrentLobby(memberSource, 0)
            if GetPlayerPing(memberSource) > 0 then
                Buckets.SetPlayer(memberSource, memberSource)
                TriggerClientEvent("warv:LobbyLeft", memberSource)
            end
        end

        if GetPlayerPing(memberSource) > 0 then
            TriggerClientEvent("warv:GoBackToLobby", memberSource, gameID)
        end
    end
end)

RegisterNetEvent("warv:GetLobbyData")
AddEventHandler("warv:GetLobbyData", function(ranked)
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    if not ranked then
        local playersInGamemodes = {}

        for k, v in pairs(SharedConfig.Gamemode) do
            if GamemodeDefinitions.IsImplemented(v.name) then
                playersInGamemodes[v.name] = 0
            end
        end

        for k, v in pairs(Game.games) do
            if v.ranked == false then
                if playersInGamemodes[v.gamemode] == nil then
                    playersInGamemodes[v.gamemode] = 0
                end
                playersInGamemodes[v.gamemode] = playersInGamemodes[v.gamemode] + #v.players
            end
        end

        TriggerClientEvent("warv:GetLobbyData", source, Game.GamesPerGamemode.unranked, playersInGamemodes)
    else

        local playersInGamemodes = {}

        for k, v in pairs(SharedConfig.Gamemode) do
            if GamemodeDefinitions.IsImplemented(v.name) then
                playersInGamemodes[v.name] = 0
            end
        end

        for k, v in pairs(Game.games) do
            if v.ranked == true then
                if playersInGamemodes[v.gamemode] == nil then
                    playersInGamemodes[v.gamemode] = 0
                end
                playersInGamemodes[v.gamemode] = playersInGamemodes[v.gamemode] + #v.players
            end
        end

        TriggerClientEvent("warv:GetLobbyData", source, Game.GamesPerGamemode.ranked, playersInGamemodes)
    end
end)


RegisterNetEvent("warv:GetAllLobbyData")
AddEventHandler("warv:GetAllLobbyData", function(ranked)
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    local rankedCount = 0
    local unrankedCount = 0

    for k, v in pairs(Game.GamesPerGamemode.ranked) do
        rankedCount = rankedCount + v
    end

    for k, v in pairs(Game.GamesPerGamemode.unranked) do
        unrankedCount = unrankedCount + v
    end

    TriggerClientEvent("warv:GetAllLobbyData", source, rankedCount, unrankedCount)
end)


RegisterNetEvent("warv:LeaveAnyLobby")
AddEventHandler("warv:LeaveAnyLobby", function()
    local source = source
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end

    for k, v in pairs(Game.games) do
        local gameId = v.gameId

        for i, j in pairs(v.players) do
            if j.id == source then
                local session = GamemodeSessionManager.Get(gameId)
                if session ~= nil then
                    session.scope:EmitClient(source, "StopGame", "left_lobby")
                end
                Game.RemovePlayerFromGame(gameId, source)
                break
            end
        end
    end


    Buckets.SetPlayer(source, source)
    Players.SetPlayerCurrentLobby(source, 0)
    Players.SetPlayerGameId(source, 0)
    TriggerClientEvent("warv:LobbyLeft", source)
end)

RegisterNetEvent("warv:suicideDrone")
AddEventHandler("warv:suicideDrone", function(payload)
    local src = source
    if type(payload) ~= "table" or type(payload.action) ~= "string" or type(payload.id) ~= "string" or #payload.id > 32 then
        return
    end
    payload.owner = src
    TriggerClientEvent("warv:suicideDroneSync", -1, payload)
end)

RegisterNetEvent("warv:uavPlane")
AddEventHandler("warv:uavPlane", function(payload)
    local src = source
    if type(payload) ~= "table" or type(payload.action) ~= "string" or type(payload.id) ~= "string" or #payload.id > 32 then
        return
    end
    payload.owner = src
    TriggerClientEvent("warv:uavPlaneSync", -1, payload)
end)
