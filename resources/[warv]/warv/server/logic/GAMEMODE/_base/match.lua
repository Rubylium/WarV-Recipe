MatchLogic = {}
MatchServer = {}

function MatchServer.Create(context)
    local instance = {}

    function instance:start()
            local scope = context.scope
            local gameID = context.game.gameId

            local match = {}
            match.gameID = gameID
            match.gameDATA = context.game
            match.maxPlayersPerTeam = BotConfig.maxPlayersPerTeam
            local gameRunning = true
            local gameData = match.gameDATA
            local TotalWaitingForLoad = #gameData.players
            local PlayerLoaded = 0
            local PlayersIdLoaded = {}
            local WaitingLoad = true
            match.gamePlayersData = {}
            local rules = context.definition.rules
            local teams = context.definition.capabilities.teams ~= false
            local fragLimit = rules.fragLimit or 30

            local team1Point = 0
            local team2Point = 0
            local pointsToWin = rules.scoreLimit or 75
            local gameBotsData = BotRoster.New(gameID, teams)
            local gameStarted = false
            local suicidePending = {}
            local medalTracker
            local CreateParticipant

            local function topFragger()
                local best, bestKills, bestIsBot = nil, -1, false
                for _, v in pairs(match.gamePlayersData) do
                    if (v.kill or 0) > bestKills then bestKills = v.kill or 0; best = v; bestIsBot = false end
                end
                for t = 1, 2 do
                    for _, b in pairs(gameBotsData.list[t] or {}) do
                        if (b.kill or 0) > bestKills then bestKills = b.kill or 0; best = b; bestIsBot = true end
                    end
                end
                return best, bestKills, bestIsBot
            end

            local function ffaResult()
                local best, bestKills, bestIsBot = topFragger()
                if not best or bestKills <= 0 then return { winnerId = nil, draw = true } end
                local tied = 0
                for _, v in pairs(match.gamePlayersData) do
                    if (v.kill or 0) == bestKills then tied = tied + 1 end
                end
                for t = 1, 2 do
                    for _, b in pairs(gameBotsData.list[t] or {}) do
                        if (b.kill or 0) == bestKills then tied = tied + 1 end
                    end
                end
                local draw = tied > 1
                return { winnerId = (not draw and not bestIsBot) and best.id or nil, draw = draw }
            end

            local function CheckWinCondition()
                if not context.session:IsRunning() then return end
                if teams then
                    if team1Point >= pointsToWin or team2Point >= pointsToWin then
                        context.session:End("score_limit")
                    end
                else
                    local _, top = topFragger()
                    if top >= fragLimit then
                        context.session:End("frag_limit")
                    end
                end
            end

            local function ScheduleTimeout(delay, callback)
                scope:SetTimeout("botRespawn", delay, callback)
            end

            local function SendBotData()
                if gameBotsData.hostId ~= 0 and GetPlayerPing(gameBotsData.hostId) > 0 then
                    scope:EmitClient(gameBotsData.hostId, "GetBotData", BotRoster.Serialize(gameBotsData))
                end
            end

            local function DeleteBotNetId(netId)
                if netId == nil or netId == 0 then
                    return
                end

                local entity = NetworkGetEntityFromNetworkId(netId)
                if entity ~= 0 and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end

            local function DeleteBotEntity(bot)
                DeleteBotNetId(bot.netId)
            end

            local function HandleBotRespawnReady(bot, previousNetId)
                DeleteBotNetId(previousNetId)
                medalTracker:RecordRespawn(CreateParticipant(bot, false))
                SendBotData()
            end

            local function CleanupBotEntities()
                for team = 1, 2 do
                    for _, bot in pairs(gameBotsData.list[team]) do
                        DeleteBotEntity(bot)
                    end
                end
                SpawnLogic.RemoveLobbyFromQueue(gameID)
            end

            local function HandleGameBot()
                local playersTeam1 = 0
                local playersTeam2 = 0

                for k,v in pairs(match.gamePlayersData) do
                    if v.team == 1 then
                        playersTeam1 = playersTeam1 + 1
                    elseif v.team == 2 then
                        playersTeam2 = playersTeam2 + 1
                    end
                end

                BotRoster.ResizeTeam(gameBotsData, 1, math.max(0, match.maxPlayersPerTeam - playersTeam1), DeleteBotEntity)
                BotRoster.ResizeTeam(gameBotsData, 2, math.max(0, match.maxPlayersPerTeam - playersTeam2), DeleteBotEntity)
                SendBotData()
            end

            function match.AddPlayerToGame(source, forceTeam)
                local team1 = 0
                local team2 = 0
                local teamToJoin = 0
                if forceTeam == nil then
                    forceTeam = false
                    for k,v in pairs(match.gamePlayersData) do
                        if v.team == 1 then
                            team1 = team1 + 1
                        else
                            team2 = team2 + 1
                        end
                    end

                    if team1 > team2 then
                        teamToJoin = 2
                    else
                        teamToJoin = 1
                    end
                else
                    teamToJoin = forceTeam
                end

                Console.DebugPrint("AddPlayerToGame - TeamToJoin: "..teamToJoin .. " | forcedTeam: ".. tostring(forceTeam))

                table.insert(match.gamePlayersData, {
                    id = source,
                    uid = Players.GetPlayerUid(source),
                    name = Players.GetName(source),
                    emblemsId = Players.GetEmblesId(source),
                    logoId = Players.GetLogoId(source),

                    level = Players.GetLevel(source),
                    prestige = Players.GetPrestige(source),
                    ranking = Players.GetRanking(source),
                    winStreak = Players.GetWinStreak(source),
                    score = 0,
                    kill = 0,
                    death = 0,
                    assist = 0,
                    ping = GetPlayerPing(source) or 0,
                    team = teamToJoin,

                    host = false,
                })

                scope:SetTimeout("sendTeam", 2000, function()
                    scope:EmitClient(source, "GetTeam", teamToJoin)
                end)
                InfoPrint("Added player "..source.." to game ("..gameID..")")
            end

            CreateParticipant = function(data, isPlayer)
                if data == nil then return nil end
                local prefix = isPlayer and "player:" or "bot:"
                return {
                    key = prefix .. tostring(data.id),
                    id = data.id,
                    isPlayer = isPlayer,
                    team = data.team,
                    data = data,
                }
            end

            local function FindPlayer(playerId)
                for _, player in pairs(match.gamePlayersData) do
                    if tonumber(player.id) == tonumber(playerId) then
                        return player
                    end
                end
                return nil
            end

            local function GetParticipants()
                local result = {}
                for _, player in pairs(match.gamePlayersData) do
                    result[#result + 1] = CreateParticipant(player, true)
                end
                for team = 1, 2 do
                    for _, bot in pairs(gameBotsData.list[team] or {}) do
                        result[#result + 1] = CreateParticipant(bot, false)
                    end
                end
                return result
            end

            local function areMedalAllies(first, second)
                return teams and first.team == second.team
            end

            local function isMedalLeaderboardPeer(candidate, victim, killer)
                if teams then
                    return candidate.team == victim.team
                end
                return candidate.key ~= killer.key
            end

            local function isMedalSoleLeader(participant)
                if teams then
                    if participant.team == 1 then
                        return team1Point > team2Point
                    end
                    return team2Point > team1Point
                end

                local participantKills = tonumber(participant.data.kill) or 0
                for _, other in ipairs(GetParticipants()) do
                    if other.key ~= participant.key
                        and (tonumber(other.data.kill) or 0) >= participantKills then
                        return false
                    end
                end
                return true
            end

            local function isMedalGameWinner(participant)
                if teams then
                    local teamScore = participant.team == 1 and team1Point or team2Point
                    return teamScore >= pointsToWin
                end
                return (tonumber(participant.data.kill) or 0) >= fragLimit
            end

            medalTracker = GamemodeMedalTracker.New({
                areAllies = areMedalAllies,
                award = function(participant, medalIds)
                    if participant.isPlayer then
                        scope:EmitClient(participant.id, "AwardMedals", medalIds)
                    end
                end,
                getParticipants = GetParticipants,
                getScore = function(participant)
                    return participant.data.score
                end,
                isGameWinner = isMedalGameWinner,
                isLeaderboardPeer = isMedalLeaderboardPeer,
                isSoleLeader = isMedalSoleLeader,
            })

            MatchLogic.AttachJoinHandler(instance, match)

            local RefreshHost
            local RefreshTdmPlayersData

            local function InitTdmPlayerData()
                match.InitPlayers()
                if SharedConfig.devmod then
                    RefreshHost()
                    HandleGameBot()
                    RefreshTdmPlayersData()
                end

                scope:CreateThread("enableGameplay", function()
                    Wait(15*1000)
                    if scope:IsActive() then
                        gameStarted = true
                    end
                end)
            end

            local function RefreshPlayersPing()
                for k,v in pairs(match.gamePlayersData) do
                    v.ping = GetPlayerPing(v.id)
                end
            end

            RefreshTdmPlayersData = function()
                local botList = BotRoster.Serialize(gameBotsData)
                for k,v in pairs(gameData.players) do
                    scope:EmitClient(v.id, "GetPlayersData", match.gamePlayersData, gameData.gameTimer, team1Point, team2Point, botList)
                end
            end

            local function RefreshLoadingState(players)
                for k,v in pairs(gameData.players) do
                    TriggerClientEvent("warv:GetLoadingState", v.id, players, PlayerLoaded, TotalWaitingForLoad)
                end
            end

            RefreshHost = function()
                local bestHost = nil
                local currentHost = nil
                for _, player in pairs(match.gamePlayersData) do
                    local ping = GetPlayerPing(player.id)
                    player.ping = ping
                    if tonumber(player.id) == tonumber(gameBotsData.hostId) and ping > 0 then
                        currentHost = {
                            id = player.id,
                            ping = ping,
                        }
                    end
                    if ping > 0 and (bestHost == nil or ping < bestHost.ping) then
                        bestHost = {
                            id = player.id,
                            ping = ping,
                        }
                    end
                end

                local selectedHost = currentHost ~= nil and currentHost.ping <= 120 and currentHost or bestHost
                local newHostId = selectedHost and selectedHost.id or 0
                local hostChanged = tonumber(gameBotsData.hostId) ~= tonumber(newHostId)
                for _, player in pairs(match.gamePlayersData) do
                    player.host = tonumber(player.id) == tonumber(newHostId)
                end

                gameBotsData.hostId = newHostId
                if hostChanged then
                    RefreshTdmPlayersData()
                    SendBotData()
                end
            end

            local CompleteGame = MatchLogic.CreateResultsHandler({
                teams = teams,
                getScores = function()
                    return team1Point, team2Point
                end,
                getFfaResult = ffaResult,
                onStop = function()
                    gameRunning = false
                end,
                players = match.gamePlayersData,
                refreshPlayers = RefreshTdmPlayersData,
                scope = scope,
            })

            local function SendKillToKillfeed(
                killerName,
                killerTeam,
                killerId,
                killedName,
                killedTeam,
                headshot,
                weapon,
                killedId,
                killedIsBot
            )
                for k,v in pairs(match.gamePlayersData) do
                    scope:EmitClient(
                        v.id,
                        "AddKillToKillfeed",
                        killerName,
                        killerId,
                        killerTeam,
                        killedName,
                        killedTeam,
                        headshot,
                        weapon,
                        killedId,
                        killedIsBot
                    )
                end
            end

            local function SendSuicideToKillfeed(player)
                SendKillToKillfeed(
                    player.name,
                    player.team,
                    -1,
                    player.name,
                    player.team,
                    false,
                    "suicide",
                    player.id,
                    false
                )
            end

            scope:CreateThread("removeDisconnectedPlayers", function()
                while gameRunning do
                    if gameStarted then


                        for k,v in pairs(match.gamePlayersData) do
                            if GetPlayerPing(v.id) == 0 then
                                table.remove(match.gamePlayersData, k)
                            end
                        end

                        if #match.gamePlayersData == 0 then
                            context.session:End("empty")
                        end
                    end
                    Wait(1000)
                end
            end)

            scope:CreateThread("waitForPlayers", function()
                local i = 0
                while WaitingLoad do
                    InfoPrint("Waiting ("..PlayerLoaded.."/"..TotalWaitingForLoad..")")

                    if TotalWaitingForLoad == PlayerLoaded then
                        WaitingLoad = false
                    end


                    i = i + 1
                    if i >= 60 then
                        for k,v in pairs(gameData.players) do
                            if PlayersIdLoaded[v.id] == nil then
                                Game.RemovePlayerFromGame(gameID, v.id)
                                TriggerClientEvent("warv:SendPlayerBackToLobbyAfterTakingTooLongToLoad", v.id)
                                scope:EmitClient(v.id, "StopGame", "load_timeout")
                            end
                        end

                        Wait(1000)

                        InfoPrint("Force starting game after 2min")
                        WaitingLoad = false
                    end
                    Wait(1000)
                end

                if gameData ~= nil and #gameData.players >= 1 then
                    InitTdmPlayerData()

                    for k,v in pairs(gameData.players) do
                        scope:EmitClient(v.id, "LoadPlayerInGamemode", match.gamePlayersData, false)
                    end
                    Wait(10*1000)
                    if gameData ~= nil and #gameData.players >= 1 then
                        gameData.gameWaitingToStartTimer = 10
                        context.session:MarkRunning()
                    else
                        context.session:End("empty")
                    end
                else
                    context.session:End("empty")
                end
            end)


            scope:CreateThread("scoreLimit", function()
                while gameRunning do
                    CheckWinCondition()
                    Wait(500)
                end
            end)

            scope:CreateThread("refreshGame", function()
                while gameRunning do
                    gameData = Game.GetGameFromGameId(gameID)
                    if gameData ~= nil then
                        TotalWaitingForLoad = #gameData.players

                        if SharedConfig.devmod then
                            HandleGameBot()
                        end
                    end

                    Wait(3000)
                end
            end)


            scope:CreateThread("refreshHost", function()
                while gameRunning do
                    gameData = Game.GetGameFromGameId(gameID)
                    if gameData ~= nil then
                        if SharedConfig.devmod then
                            RefreshHost()
                        end
                    end
                    Wait(15*1000)
                end
            end)


            scope:OnNet("PlayerLeave", function(eventSource)
                for k,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then
                        table.remove(match.gamePlayersData, k)
                    end
                end

                Game.RemovePlayerFromGame(gameID, eventSource)
                RefreshTdmPlayersData()
                TriggerClientEvent("warv:GoBackToLobby", eventSource, gameID)
            end)


            scope:OnNet("PlayerLoadedIntoGame", function(eventSource)
                if PlayersIdLoaded[eventSource] then
                    return
                end
                PlayerLoaded = PlayerLoaded + 1
                PlayersIdLoaded[eventSource] = true
                local playersNotLoaded = ""

                for k,v in pairs(gameData.players) do
                    if PlayersIdLoaded[v.id] == nil then
                        playersNotLoaded = playersNotLoaded .. " - "..v.name
                    end
                end

                RefreshLoadingState(playersNotLoaded)

                if context.session:IsRunning() then
                    scope:EmitClient(eventSource, "LoadPlayerInGamemode", match.gamePlayersData, true)
                end
            end)

            scope:OnNet("AddPlayerKill", function(eventSource, killedSource, playerWhoKilled, headshot, weapon, killContext)
                if tonumber(playerWhoKilled) ~= tonumber(eventSource) then
                    return
                end
                if not context.session:IsRunning() then return end

                local killer = FindPlayer(playerWhoKilled)
                local victim = FindPlayer(killedSource)
                if killer == nil or victim == nil or killer == victim
                    or (teams and killer.team == victim.team) then
                    return
                end

                local killerParticipant = CreateParticipant(killer, true)
                local victimParticipant = CreateParticipant(victim, true)
                local preparedMedals = medalTracker:PrepareKill(killerParticipant, victimParticipant)

                victim.death = victim.death + 1
                killer.kill = killer.kill + 1
                killer.score = killer.score + 150
                Players.AddKillToWeapon(playerWhoKilled, GetWeaponNameFromHash(weapon), headshot)
                Players.AddXp(killer.id, 150)
                killer.level = Players.GetLevel(killer.id)
                if teams then
                    if killer.team == 1 then
                        team1Point = team1Point + 1
                    else
                        team2Point = team2Point + 1
                    end
                end

                killContext = type(killContext) == "table" and killContext or {}
                killContext.weapon = weapon
                medalTracker:RecordKill(killerParticipant, victimParticipant, killContext, preparedMedals)

                SendKillToKillfeed(
                    killer.name,
                    killer.team,
                    killer.id,
                    victim.name,
                    victim.team,
                    headshot,
                    weapon,
                    victim.id,
                    false
                )
                RefreshPlayersPing()
                RefreshTdmPlayersData()
                CheckWinCondition()
            end)

            if SharedConfig.devmod then
                scope:OnNet("AddPlayerKillBot", function(eventSource, botId, botTeam, _, headshot, weapon, killContext)
                    if not context.session:IsRunning() then
                        return
                    end
                    local bot = BotRoster.Find(gameBotsData, botId, botTeam)
                    local killer = FindPlayer(eventSource)

                    if bot == nil or killer == nil or (teams and killer.team == bot.team) then
                        return
                    end

                    local killerParticipant = CreateParticipant(killer, true)
                    local victimParticipant = CreateParticipant(bot, false)
                    local preparedMedals = medalTracker:PrepareKill(killerParticipant, victimParticipant)
                    local deadBot = BotRoster.MarkDead(gameBotsData, bot.id, bot.team, HandleBotRespawnReady, ScheduleTimeout)
                    if deadBot == nil then
                        return
                    end

                    killer.kill = killer.kill + 1
                    killer.score = killer.score + 150
                    Players.AddKillToWeapon(eventSource, GetWeaponNameFromHash(weapon), headshot)
                    Players.AddXp(eventSource, 150)
                    killer.level = Players.GetLevel(eventSource)
                    if teams then
                        if killer.team == 1 then
                            team1Point = team1Point + 1
                        else
                            team2Point = team2Point + 1
                        end
                    end

                    killContext = type(killContext) == "table" and killContext or {}
                    killContext.weapon = weapon
                    medalTracker:RecordKill(killerParticipant, victimParticipant, killContext, preparedMedals)

                    SendKillToKillfeed(
                        killer.name,
                        killer.team,
                        eventSource,
                        bot.name,
                        bot.team,
                        headshot,
                        weapon,
                        bot.id,
                        true
                    )
                    RefreshTdmPlayersData()
                    SendBotData()
                    CheckWinCondition()
                end)

                scope:OnNet("AddBotKillPlayer", function(eventSource, botId, botTeam, _, headshot, weapon)
                    if not context.session:IsRunning() then
                        return
                    end
                    local bot = BotRoster.Find(gameBotsData, botId, botTeam)
                    local victim = FindPlayer(eventSource)

                    if bot == nil or victim == nil or (teams and victim.team == bot.team) then
                        return
                    end

                    local killerParticipant = CreateParticipant(bot, false)
                    local victimParticipant = CreateParticipant(victim, true)
                    local preparedMedals = medalTracker:PrepareKill(killerParticipant, victimParticipant)
                    bot.kill = bot.kill + 1
                    bot.score = bot.score + 150
                    victim.death = victim.death + 1
                    if teams then
                        if bot.team == 1 then
                            team1Point = team1Point + 1
                        else
                            team2Point = team2Point + 1
                        end
                    end

                    medalTracker:RecordKill(killerParticipant, victimParticipant, {
                        weapon = weapon,
                    }, preparedMedals)

                    SendKillToKillfeed(
                        bot.name,
                        bot.team,
                        bot.id,
                        victim.name,
                        victim.team,
                        headshot,
                        weapon,
                        victim.id,
                        false
                    )
                    RefreshTdmPlayersData()
                    CheckWinCondition()
                end)

                scope:OnNet("AddBotKillBot", function(eventSource, killedBotId, killedBotTeam, killerBotId, killerBotTeam, headshot, weapon)
                    if not context.session:IsRunning() then
                        return
                    end
                    if not BotRoster.IsHost(gameBotsData, eventSource) then
                        return
                    end

                    local killedBot = BotRoster.Find(gameBotsData, killedBotId, killedBotTeam)
                    local killerBot = BotRoster.Find(gameBotsData, killerBotId, killerBotTeam)
                    local invalid = teams and (killedBot ~= nil and killerBot ~= nil and killedBot.team == killerBot.team)
                        or (not teams and killedBot == killerBot)
                    if killedBot == nil or killerBot == nil or invalid then
                        return
                    end

                    local killerParticipant = CreateParticipant(killerBot, false)
                    local victimParticipant = CreateParticipant(killedBot, false)
                    local preparedMedals = medalTracker:PrepareKill(killerParticipant, victimParticipant)
                    if BotRoster.MarkDead(gameBotsData, killedBot.id, killedBot.team, HandleBotRespawnReady, ScheduleTimeout) == nil then
                        return
                    end

                    killerBot.kill = killerBot.kill + 1
                    killerBot.score = killerBot.score + 150
                    if teams then
                        if killerBot.team == 1 then
                            team1Point = team1Point + 1
                        else
                            team2Point = team2Point + 1
                        end
                    end

                    medalTracker:RecordKill(killerParticipant, victimParticipant, {
                        weapon = weapon,
                    }, preparedMedals)

                    SendKillToKillfeed(
                        killerBot.name,
                        killerBot.team,
                        killerBot.id,
                        killedBot.name,
                        killedBot.team,
                        headshot,
                        weapon,
                        killedBot.id,
                        true
                    )
                    RefreshTdmPlayersData()
                    SendBotData()
                    CheckWinCondition()
                end)

                scope:OnNet("SyncBotEntity", function(eventSource, botId, netId)
                    if not BotRoster.IsHost(gameBotsData, eventSource) then
                        return
                    end

                    local bot = BotRoster.FindAny(gameBotsData, botId)
                    netId = tonumber(netId)
                    if bot == nil or netId == nil or netId <= 0 or bot.respawning then
                        return
                    end

                    bot.netId = netId
                    RefreshTdmPlayersData()
                    SendBotData()
                end)

                scope:OnNet("BotEntityDied", function(eventSource, botId, botTeam)
                    if not context.session:IsRunning() then
                        return
                    end
                    if not BotRoster.IsHost(gameBotsData, eventSource) then
                        return
                    end

                    local bot = BotRoster.MarkDead(gameBotsData, botId, botTeam, HandleBotRespawnReady, ScheduleTimeout)
                    if bot == nil then
                        return
                    end

                    medalTracker:RecordSuicide(CreateParticipant(bot, false))
                    if teams then
                        if bot.team == 1 then
                            team2Point = team2Point + 1
                        else
                            team1Point = team1Point + 1
                        end
                    end
                    RefreshTdmPlayersData()
                    SendBotData()
                end)

                scope:OnNet("BotEntityMissing", function(eventSource, botId, netId)
                    if not BotRoster.IsHost(gameBotsData, eventSource) then
                        return
                    end

                    local bot = BotRoster.FindAny(gameBotsData, botId)
                    netId = tonumber(netId)
                    if bot == nil or netId == nil or bot.netId ~= netId or bot.respawning then
                        return
                    end

                    DeleteBotEntity(bot)
                    bot.netId = 0
                    RefreshTdmPlayersData()
                    SendBotData()
                end)
            end


            scope:OnNet("AddPlayerDeath", function(eventSource)
                if not context.session:IsRunning() or suicidePending[eventSource] then
                    return
                end

                local deadPlayer
                for _,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then
                        deadPlayer = v
                        suicidePending[eventSource] = true
                        v.death = v.death + 1
                        if teams then
                            if v.team == 1 then
                                team2Point = team2Point + 1
                            elseif v.team == 2 then
                                team1Point = team1Point + 1
                            end
                        end

                        break
                    end
                end

                if deadPlayer then
                    medalTracker:RecordSuicide(CreateParticipant(deadPlayer, true))
                    SendSuicideToKillfeed(deadPlayer)
                    RefreshPlayersPing()
                    RefreshTdmPlayersData()
                    CheckWinCondition()
                end
            end)

            scope:OnNet("AssistKill", function(eventSource, assist)
                assist = tonumber(assist) or 0
                for k,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then
                        Players.AddXp(v.id, assist)
                        v.score = v.score + assist
                        v.assist = v.assist + 1

                        v.ranking = Players.GetRanking(tonumber(v.id))
                        medalTracker:AwardMajorAssist(CreateParticipant(v, true), assist)
                        break
                    end
                end
                RefreshPlayersPing()
                RefreshTdmPlayersData()
            end)

            scope:OnNet("ReportCombatDamage", function(eventSource, attackerType, attackerId, attackerTeam, health)
                if not context.session:IsRunning() then return end

                local victim = FindPlayer(eventSource)
                local attacker
                local attackerIsPlayer = attackerType == "player"
                if attackerIsPlayer then
                    attacker = FindPlayer(attackerId)
                elseif attackerType == "bot" then
                    attacker = BotRoster.Find(gameBotsData, attackerId, attackerTeam)
                end

                if victim == nil or attacker == nil
                    or tonumber(victim.id) == tonumber(attacker.id)
                    or (teams and victim.team == attacker.team) then
                    return
                end

                medalTracker:RecordDamage(
                    CreateParticipant(victim, true),
                    CreateParticipant(attacker, attackerIsPlayer),
                    health
                )
            end)

            scope:OnNet("RegisterUav", function(eventSource, uavId, initialAngle)
                if not context.session:IsRunning() then return end
                local owner = FindPlayer(eventSource)
                initialAngle = tonumber(initialAngle) or 0.0
                if initialAngle ~= initialAngle or math.abs(initialAngle) > math.pi * 2 then
                    initialAngle = 0.0
                end

                if owner ~= nil
                    and medalTracker:RegisterUav(CreateParticipant(owner, true), uavId) then
                    TriggerClientEvent("warv:uavPlaneSync", -1, {
                        action = "launch",
                        a0 = initialAngle,
                        gameId = gameID,
                        id = uavId,
                        owner = eventSource,
                        team = owner.team,
                    })
                end
            end)

            scope:OnNet("DestroyUav", function(eventSource, uavId)
                if not context.session:IsRunning() then return end
                local shooter = FindPlayer(eventSource)
                if shooter ~= nil
                    and medalTracker:DestroyUav(CreateParticipant(shooter, true), uavId) then
                    TriggerClientEvent("warv:uavPlaneSync", -1, {
                        action = "shot",
                        gameId = gameID,
                        id = uavId,
                        owner = eventSource,
                    })
                end
            end)

            scope:OnNet("MedalsPoint", function(eventSource, points)
                for k,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then
                        Players.AddXp(v.id, points)
                        v.score = v.score + points
                        break
                    end
                end
                RefreshPlayersPing()
                RefreshTdmPlayersData()
            end)

            scope:OnNet("GetTeam", function(eventSource)
                for k,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then

                        scope:EmitClient(v.id, "GetTeam", v.team, k)

                        break
                    end
                end

            end)

            scope:OnNet("GetKillStreakFromTeam", function(eventSource, killstreak, team, sync)
                local name = GetPlayerName(eventSource)
                local emmblem
                if tostring(killstreak):upper() == "NUKE" then
                    Unlocks.AddStat(Players.list[eventSource], "nukes", 1)
                    Challenges.Progress(eventSource, "nukes", 1)
                end
                for k,v in pairs(match.gamePlayersData) do
                    if v.id == eventSource then
                        emmblem = v.emblemsId
                        break
                    end
                end

                for k,v in pairs(match.gamePlayersData) do
                    
                    if v.id ~= eventSource then
                        scope:EmitClient(v.id, "GetKillStreakFromTeam", killstreak, team, sync, name, eventSource)
                    end
                    TriggerClientEvent("warv_revisted:GetEmblemMessage", v.id, name, name .. " Called an "..killstreak, emmblem, v.team == team)
                end
            end)

            scope:OnNet("GetSpawnPos", function(eventSource)
                suicidePending[eventSource] = nil
                local respawningPlayer = FindPlayer(eventSource)
                if respawningPlayer ~= nil then
                    medalTracker:RecordRespawn(CreateParticipant(respawningPlayer, true))
                end
                scope:CreateThread("queueSpawn", function()
                    for k,v in pairs(match.gamePlayersData) do
                        if v.id == eventSource then
                            SpawnLogic.AddPlayerIntoQueueForLobby(gameID, eventSource, v.team, match.gamePlayersData, gameData.gameMap, BotRoster.Serialize(gameBotsData), teams)
                            break
                        end
                    end
                end)
            end)

            scope:OnNet("RequestBotSpawn", function(eventSource, requestId, botId, team)
                if not BotRoster.IsHost(gameBotsData, eventSource) then
                    return
                end

                team = tonumber(team)
                local bot = BotRoster.Find(gameBotsData, botId, team)
                if bot == nil or bot.netId ~= 0 or bot.respawning then
                    scope:EmitClient(eventSource, "BotSpawnGranted", requestId, botId, nil)
                    return
                end

                local spawnPos = SpawnLogic.GetSpawnForTeam(
                    team,
                    match.gamePlayersData,
                    gameData.gameMap,
                    BotRoster.Serialize(gameBotsData),
                    gameID,
                    bot.id,
                    teams
                )
                scope:EmitClient(eventSource, "BotSpawnGranted", requestId, bot.id, spawnPos)
            end)

            MatchLogic.AttachExplosionHandler(instance, match.gamePlayersData)

            instance.stop = CompleteGame
            instance.destroy = function()
                gameRunning = false
                CleanupBotEntities()
            end
            instance.onPlayerLeave = function(_, playerSource)
                for index = #match.gamePlayersData, 1, -1 do
                    if match.gamePlayersData[index].id == playerSource then
                        table.remove(match.gamePlayersData, index)
                    end
                end
                RefreshTdmPlayersData()
            end
        end

    return instance
end
