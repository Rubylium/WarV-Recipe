function Gamemode.HandleEndScreenProtection()
    GamemodeRuntime.CreateThread("endScreenProtection", function()
        while GamemodeRuntime.IsActive() and Status.GetIsPlayerInEndScreen() do
            Player.SetGodModStatus(true)
            DisableAllControlActions(0)
            Wait(1)
        end
    end)
end

local endgameSound = {
    victory = "match_result/victory.wav",
    defeat = "match_result/defeat.wav",
    draw = "match_result/draw.wav",
}

local function playEndJingle(isWin)
    if isWin then
        PlayCustomSound("match_end_music/victory_" .. math.random(1, 6) .. ".ogg", Settings.MusicsVolume)
    else
        PlayCustomSound("match_end_music/defeat_1.ogg", Settings.MusicsVolume)
    end
end

function Gamemode.DisplayEndScreen(win, draw)
    Player.Revive()
    Gamemode.isDead = false
    Status.SetIsPlayerInGame(false)
    ScoreHud.Hide()
    KillstreakHud.Hide()
    WeaponHud.Hide()

    GamemodeRuntime.CreateThread("endScreen", function()
        StopAllSounds()
        playEndJingle(win)
        Protection.RemoveProtectionFromPed(Player.GetPed())
        Status.SetIsPlayerInEndScreen(true)
        Gamemode.HandleEndScreenProtection()
        Bot.Pause()

        SetTimeScale(0.2)
        RealWait(300)
        SetTimeScale(1.0)

        Gamemode.RemoveMapBounds()
        Medals.ResetQueue()
        Score.ResetScoreFeed()
        DisplayRadar(false)
        Bot.GameId = 0
        UiHandler.SetPageInactive("ui_death")
        UiHandler.SetPageInactive("ui_class_selection")
        Lobby.ResetWebState()
        Matchmaking.voted = false
        SendNuiMessage(json.encode({ hideInGameHud = true }))
        Gamemode.ForceStopKillstreaks()
        StartAudioScene("MP_MENU_SCENE")

        FreezeEntityPosition(Player.GetPed(), true)
        ClearPedBloodDamage(Player.GetPed())
        Voice.AddPlayerToVoiceLobby(Matchmaking.data.gameBucket)
        AnimpostfxStopAll()

        local result = draw and "draw" or (win and "victory" or "defeat")

        if Gamemode.NoTeams then
            local mySID = Gamemode.utils.GetSID()
            local all = {}
            for _, v in pairs(Gamemode.PlayersData) do
                all[#all + 1] = { id = v.id, name = v.name or "Player", kills = tonumber(v.kill) or 0,
                    level = tonumber(v.level) or 0, prestige = tonumber(v.prestige) or 0, isMe = tonumber(v.id) == tonumber(mySID) }
            end
            for team = 1, 2 do
                for _, b in pairs(Bot.list[team]) do
                    all[#all + 1] = { id = b.id, name = b.name or "Bot", kills = tonumber(b.kill) or 0,
                        level = tonumber(b.level) or 0, prestige = tonumber(b.prestige) or 0, isMe = false }
                end
            end
            table.sort(all, function(a, b) return a.kills > b.kills end)

            local meEntry
            for i, e in ipairs(all) do
                e.pos = i
                if e.isMe then meEntry = e end
            end

            local picked = {}
            if meEntry then picked[#picked + 1] = meEntry end
            for _, e in ipairs(all) do
                if e ~= meEntry and #picked < 5 then picked[#picked + 1] = e end
            end
            table.sort(picked, function(a, b) return a.pos < b.pos end)

            local board = {}
            for _, e in ipairs(picked) do
                board[#board + 1] = {
                    pos = e.pos,
                    name = e.name,
                    score = e.kills,
                    level = e.level,
                    prestige = e.prestige,
                    rankIcon = GetRankIcon(e.level, e.prestige),
                    me = e.isMe,
                }
            end

            exports['warv-ui']:ShowEndScreen({
                result = result,
                subtitle = "Free For All",
                teamMode = false,
                left = { name = "", logo = "", score = 0, color = "blue" },
                right = { name = "", logo = "", score = 0, color = "red" },
                board = board,
            })
        else
            local t1 = tonumber(Gamemode.team1score) or 0
            local t2 = tonumber(Gamemode.team2score) or 0
            local isa = { name = "ISA", logo = "team_1", score = t1, color = "blue" }
            local mercs = { name = "MERCS", logo = "team_2", score = t2, color = "red" }
            local left, right
            if Gamemode.Team == 1 then left, right = isa, mercs else left, right = mercs, isa end

            exports['warv-ui']:ShowEndScreen({
                result = result,
                subtitle = "Score limit reached",
                teamMode = true,
                left = left,
                right = right,
                board = {},
            })
        end
        PlayCustomSound(endgameSound[result],
            Settings.GetScaledVolume(Settings.MusicsVolume, 0.06, 0.02))

        RealWait(6000)

        DoScreenFadeOut(400)
        RealWait(450)
        exports['warv-ui']:HideEndScreen()
        RealWait(650)

        local players = {}
        if Gamemode.NoTeams then
            local ranked = {}
            for _, v in pairs(Gamemode.PlayersData) do table.insert(ranked, v) end
            for _, bot in pairs(Bot.GetEndScreenPlayers(1)) do table.insert(ranked, bot) end
            for _, bot in pairs(Bot.GetEndScreenPlayers(2)) do table.insert(ranked, bot) end
            table.sort(ranked, function(a, b) return (tonumber(a.kill) or 0) > (tonumber(b.kill) or 0) end)
            for i = 1, math.min(5, #ranked) do table.insert(players, ranked[i]) end
        else
            for k, v in pairs(Gamemode.PlayersData) do
                if win then
                    if v.team == Gamemode.Team then
                        table.insert(players, v)
                    end
                elseif draw then
                    table.insert(players, v)
                else
                    if v.team ~= Gamemode.Team then
                        table.insert(players, v)
                    end
                end
            end
            for team = 1, 2 do
                local includeTeam = draw or (win and team == Gamemode.Team) or (not win and not draw and team ~= Gamemode.Team)
                if includeTeam then
                    for _, bot in pairs(Bot.GetEndScreenPlayers(team)) do
                        table.insert(players, bot)
                    end
                end
            end
        end
        EndScreen.EndScreen(Matchmaking.selectedMap.endScreenPos, players, win, draw)
        Bot.EndGame()

        UiHandler.CloseAllPages()
        UiHandler.SetPageActive("matchmaking")
        Status.SetIsPlayerInEndScreen(false)
        Gamemode.Playing = false
        Data.CanRefreshClass()
        SendNuiMessage(json.encode({ hideInGameHud = true }))
        Lobby.SetLobbyData()
        Discord.SetState("matchmaking")
        MapEnv.Lobby()

        LobbyPlacement.StopCam()
        LobbyPlacement.StartCam()
        SetEntityCoordsNoOffset(Player.GetPed(), LobbyLayout.SpawnPos(), false, false, false)
        PlayersDisplay.SetupPlayersClones()

        RealWait(1000)
        DoScreenFadeIn(1000)
        GamemodeRuntime.Stop("completed")
    end)
end
