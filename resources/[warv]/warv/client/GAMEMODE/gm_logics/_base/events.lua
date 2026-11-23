function Match.InitEvents()

    Utils.RegisterGamemodeNetEvent("GetKillStreakFromTeam", function(killstreak, team, sync)
        if not Gamemode.NoTeams and team == Gamemode.Team then
            if sync then
                Gamemode.TriggerKillstreak(Status.GetCurrentGameId(), killstreak, Gamemode.Team, Gamemode.PlayersData, true)
            end

        elseif team ~= Gamemode.Team then
            if SharedConfig.Killstreaks[killstreak] ~= nil then
                if SharedConfig.Killstreaks[killstreak].syncForOtherTeam ~= nil and SharedConfig.Killstreaks[killstreak].syncForOtherTeam then
                    Gamemode.TriggerKillstreak(Status.GetCurrentGameId(), killstreak, Gamemode.Team, Gamemode.PlayersData, true)
                end
            end
        end
    end)

    Utils.RegisterGamemodeNetEvent("AddKillToKillfeed", function(
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
        local weaponImage
        if type(weapon) == "number" then
            weaponImage = GetWeaponImageFromHash(weapon)
        else
            weaponImage = weapon
        end

        Killfeed.Send(killerName, killerId, killerTeam, killedName, killedTeam, headshot, weaponImage)
        if killerId == Gamemode.utils.GetSID() then
            local isKillstreakKill = SharedConfig.IsKillstreakKillSource(weapon)
            local progressPoints = Score.GetKillstreakProgressPoints(150, isKillstreakKill)
            Score.AddScore(150, "ELIMINATION", progressPoints)

            if Killstreaks.ownedUavActive then
                Medals.AddMedalsToShow("UAV_KILL_BONUS", Status.GetCurrentGameId(), isKillstreakKill)
            end

            if GetEntityHealth(Player.GetPed()) < 150 then
                Medals.AddMedalsToShow("close_call", Status.GetCurrentGameId(), isKillstreakKill)
                
            end

            
            if headshot then
                PlayCustomSound("gameplay/headshot_notification.wav",
                    Settings.GetScaledVolume(Settings.hitMarkerVolume, 0.10, 0.05))
                Medals.AddMedalsToShow("headshot", Status.GetCurrentGameId(), isKillstreakKill)
            else
                PlayCustomSound("ui/hit_feedback/kill_confirmation.wav",
                    Settings.GetScaledVolume(Settings.hitMarkerVolume, 0.075, 0.05))
            end
        else
            Gamemode.HandleKillAssist(
                Status.GetCurrentGameId(),
                killedName,
                killedId,
                killedIsBot
            )
        end
    end)

    Utils.RegisterGamemodeNetEvent("LoadPlayerInGamemode", function(playersData, fastLoad)
        Gamemode.PlayersData = playersData
        Match.PlayGameStartAnimation(fastLoad)
    end)

    Utils.RegisterGamemodeNetEvent("GetGameData", function(data)
        Match.GameData = data
    end)

    Utils.RegisterGamemodeNetEvent("GetPlayersData", function(data, timer, team1Point, team2Point, botData)
        Matchmaking.data.gameTimer = timer
        Gamemode.PlayersData = data

        Gamemode.team1score = team1Point
        Gamemode.team2score = team2Point
        Bot.UpdateList(botData)

        for k,v in pairs(Gamemode.PlayersData) do

            if tonumber(v.id) == tonumber(Gamemode.utils.GetSID()) then
                Match.host = v.host
                break
            end
        end
        Bot.SetHost(Match.host)
        if Match.OnPlayersData then Match.OnPlayersData() end
    end)

    Utils.RegisterGamemodeNetEvent("GetTeam", function(data)
        Gamemode.Team = data
        Bot.team = Gamemode.Team
        Match.SpawnIndex = Gamemode.Team
        Gamemode.SetTeam(Gamemode.Team)
        Voice.AddPlayerToVoiceLobby(Matchmaking.data.gameBucket + Gamemode.Team) 
    end)

    Utils.RegisterGamemodeNetEvent("GetSpawnIndex", function(spawnIndex)
        Match.SpawnIndex = spawnIndex
        Gamemode.SetTeam(Gamemode.Team)
    end)

    Utils.RegisterGamemodeNetEvent("GetBotData", function(gameBotsDatalist)
        Bot.SetHost(Match.host)
        if Bot.isHost then
            Bot.UpdateList(gameBotsDatalist)
        end
    end)

    Utils.RegisterGamemodeNetEvent("BotSpawnGranted", function(requestId, botId, spawn)
        Bot.ResolveSpawnRequest(requestId, botId, spawn)
    end)

    Utils.RegisterGamemodeNetEvent("EndGame", function(win, draw)
        Player.inGame = false
        UiHandler.SetPageInactive("map_loading")
        PlayersUI.Clear()
        Voice.ClearInGameVoiceChat()
        Lobby.HideScoreboard()
        Gamemode.DisplayEndScreen(win, draw)
    end)

    Utils.RegisterGamemodeNetEvent("StopGame", function(reason)
        GamemodeRuntime.Stop(reason or "server_stop")
    end)
end
