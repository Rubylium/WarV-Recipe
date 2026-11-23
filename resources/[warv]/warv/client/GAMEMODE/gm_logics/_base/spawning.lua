function Match.InitFunctions()


    function Match.PlayGameStartAnimation(fastLoad)
        while GamemodeRuntime.IsActive() and not Gamemode.IsPlayerSyncedWithTeam() do
            Citizen.Wait(0)
        end
        if not Gamemode.IsPlayerSyncedWithTeam() then
            return
        end

        Gamemode.LoadPlayerSkinAndChoosenClass()
        DoScreenFadeOut(200)
        Utils.RealWait(250)
        UiHandler.SetPageInactive("map_loading")
        StopAllSounds()
        while GamemodeRuntime.IsActive() and LoadAnimation.AnimationStarted do
            Wait(0)
        end
        if Match.loadout then
            UiHandler.SetPageActive("ui_class_selection")
        end

        if not fastLoad then
            if Gamemode.NoTeams then
                StartScreen.InAnimation = true
                Match.SpawnPlayer()
                GamemodeRuntime.CreateThread("ffaCountdown", function()
                    Match.PlayCountdown()
                    StopAudioScenes()
                end)
            else
                GamemodeRuntime.CreateThread("startAnimation", function()
                    local participants = Bot.GetTeamParticipants(Gamemode.PlayersData, Gamemode.Team)
                    local showcasePos = Gamemode.Team == 1 and Matchmaking.selectedMap.startFirstPos1
                        or Matchmaking.selectedMap.startFirstPos2
                    StartScreen.NewStartScreen(showcasePos, participants)
                    StopAudioScenes()
                end)
            end
        else
            if Match.loadout then
                UiHandler.SetPageActive("ui_class_selection")
            end
            Match.SpawnPlayer()
            StopAudioScenes()
        end


        Match.GameStarted = true
        Killfeed.ResetStreak()
        exports['warv-ui']:HudClear()
        Match.StartSpawnCountdown(fastLoad)
    end

    function Match.StartSpawnCountdown(fastLoad)
        GamemodeRuntime.CreateThread("spawnCountdown", function()
            if not fastLoad then

                while GamemodeRuntime.IsActive() and StartScreen.InAnimation do
                    Wait(1)
                end

                if UiHandler.IsPageActive("ui_class_selection") then
                    RemoveAllPedWeapons(Player.GetPed(), 1)
                    Class.selected = Class.customClass[1]
                    UiHandler.SetPageInactive("ui_class_selection")
                end

            end

            exports['warv-ui']:Notify("notice", { title = "OBJECTIVE", message = Match.objective })

            FreezeEntityPosition(Player.GetPed(), false)
            Bot.GameStarted = true
            Status.gameStarted = true

            RealWait(15*1000)
            if GamemodeRuntime.IsActive() and Status.IsPlayerInGame then
                Sounds.PlayRandomGameMusic()
            end
        end)
    end

    function Match.PlayCountdown()
        local count = 10
        local beepHi = "ui/countdown/high_tick.wav"
        local beepLo = "ui/countdown/low_tick.wav"

        local ostStyleId = math.random(1, 4)
        PlayCustomSound("ui/match_start/start_" .. ostStyleId .. ".mp3",
            Settings.GetScaledVolume(Settings.MusicsVolume, 0.045, 0.02), false)

        Utils.RealWait(600)
        if IsScreenFadedOut() then
            DoScreenFadeIn(400)
        end

        local function classOpen()
            return UiHandler.IsPageActive("ui_class_selection")
        end

        local remaining = count
        local shownSec, shownVis
        local lastTick = GetGameTimer()
        local counting = true

        GamemodeRuntime.CreateThread("countdownLock", function()
            while counting and GamemodeRuntime.IsActive() do
                Gamemode.LockCombat()
                Wait(0)
            end
        end)

        PlayCustomSound(beepHi,
            Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.04, 0.05))

        while remaining > 0 and GamemodeRuntime.IsActive() do
            local vis = not classOpen()
            if shownSec ~= remaining or shownVis ~= vis then
                shownSec, shownVis = remaining, vis
                exports['warv-ui']:SetCountdown({ visible = vis, seconds = remaining, label = "Match starts in" })
            end

            if GetGameTimer() - lastTick >= 1000 then
                lastTick = lastTick + 1000
                remaining = remaining - 1
                if remaining > 0 then
                    PlayCustomSound(remaining >= 6 and beepHi or beepLo,
                        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.04, 0.05))
                end
            end
            Wait(50)
        end

        counting = false
        exports['warv-ui']:SetCountdown({ visible = false, seconds = 0, label = "" })
        PlayCustomSound("ui/countdown/match_start.wav",
            Settings.interfaceSoundVolume, false)

        StartScreen.InAnimation = false
    end



    function Match.SpawnPlayer()

        GamemodeRuntime.CreateThread("spawnPlayer", function()
            if Gamemode.Team == 0 then
                while GamemodeRuntime.IsActive() and not Gamemode.IsPlayerSyncedWithTeam() do
                    Wait(0)
                end
                if not Gamemode.IsPlayerSyncedWithTeam() then
                    return
                end
                SetEntityVisible(Player.GetPed(), true, 1)
            end

            SetRagdollBlockingFlags(Player.GetPed(), 1)
            SetRagdollBlockingFlags(Player.GetPed(), 2)
            SetRagdollBlockingFlags(Player.GetPed(), 4)
            SetPedCanRagdoll(Player.GetPed(), false)


            Appearance.LoadPlayer(Gamemode.Team)


            local SpawnPos, spawnError = SpawnFinder.NewGetSpawnPos(Status.GetCurrentGameId())
            if SpawnPos == nil then
                GamemodeRuntime.Fail("initial_spawn_error: " .. tostring(spawnError))
                return
            end
            SpawnFinder.SpawnPlayer(SpawnPos)

            if not Status.gameStarted then
                FreezeEntityPosition(Player.GetPed(), true)
            else
                FreezeEntityPosition(Player.GetPed(), false)
            end
            Gamemode.SetTeam(Gamemode.Team)

            ClassWeapons.GiveWeaponFromSelectedClass()
            if IsScreenFadedOut() then
               DoScreenFadeIn(500)
            end

        end)

    end


    function Match.RespawnPlayer()
        if Status.GetIsPlayerInEndScreen() then return end
        while UiHandler.IsPageActive("ui_class_selection") and Player.inGame and not Status.GetIsPlayerInEndScreen() do
            Wait(1)
        end
        if Status.GetIsPlayerInEndScreen() then return end

        if Gamemode.Team == 0 then
            Utils.TriggerGamemodeServerEvent("GetTeam")
            while Gamemode.Team == 0 and Player.inGame do
                SetEntityVisible(Player.GetPed(), false, 1)
                Utils.RealWait(100)
            end
            SetEntityVisible(Player.GetPed(), true, 1)
        end
        SetEntityInvincible(Player.GetPed(), true)
        if Class.selected.weapons == nil then
            return
        end

        SetRagdollBlockingFlags(Player.GetPed(), 1)
        SetRagdollBlockingFlags(Player.GetPed(), 2)
        SetRagdollBlockingFlags(Player.GetPed(), 4)
        SetPedCanRagdoll(Player.GetPed(), false)



        if Status.GetIsPlayerInEndScreen() then return end

        local SpawnPos, spawnError = SpawnFinder.NewGetSpawnPos(Status.GetCurrentGameId())
        if SpawnPos == nil then
            GamemodeRuntime.Fail("respawn_error: " .. tostring(spawnError))
            return false
        end
        UiHandler.SetPageInactive("ui_death")

        DoScreenFadeOut(500)
        Utils.RealWait(500)

        Spectate.Stop()
        cam.render("DEATH", false, false, 1500)
        cam.delete("DEATH")

        SpawnFinder.SpawnPlayer(SpawnPos)
        Utils.RealWait(500)
        DoScreenFadeIn(500)

        ClassWeapons.GiveWeaponFromSelectedClass()
        FreezeEntityPosition(Player.GetPed(), false)
        Gamemode.isDead = false

        SetEntityInvincible(Player.GetPed(), false)
        if Matchmaking.data.ranked == false then
            GamemodeRuntime.CreateThread("spawnProtection", function()
                Gamemode.SpawnProtection = true
                SetEntityInvincible(Player.GetPed(), true)
                Utils.RealWait(2500, function(cb)
                    if IsPedShooting(Player.GetPed()) then
                        cb(true)
                    else
                        cb(false)
                    end
                end)
                if not GamemodeRuntime.IsActive() then
                    return
                end
                SetEntityInvincible(Player.GetPed(), false)
                Gamemode.SpawnProtection = false
            end)
        end

        Gamemode.SetTeam(Gamemode.Team)
    end

    function Match.IsKillerAPlayer(entity)
        for k,v in pairs(GetActivePlayers()) do
            if GetPlayerPed(v) == entity then
                return v
            end
        end
        return nil
    end

    function Match.PlayerDeathHandler(name)
        Gamemode.isDead = true
        Killfeed.ResetStreak()

        local pos = GetEntityCoords(Player.GetPed())
        SetPlayerInvincibleKeepRagdollEnabled(Player.GetPed(), true)
        SetPedRagdollForceFall(Player.GetPed())
        while Gamemode.isInKillstreakCam and Player.inGame do
            if GetEntityHealth(Player.GetPed()) < 100 then
                NetworkResurrectLocalPlayer(pos.xyz, GetEntityHeading(Player.GetPed()), 0, 0)
            end
            SetPlayerInvincible(Player.GetPed(), true)
            SetEntityVisible(Player.GetPed(), false, 1)
            Wait(30)
        end
        SetEntityInvincible(Player.GetPed(), false)
        SetEntityHealth(Player.GetPed(), 0)
        SetEntityVisible(Player.GetPed(), true, 1)


        local playerPed = Player.GetPed()
        local killer = GetPedSourceOfDeath(playerPed)
        if killer == nil or killer == 0 or not DoesEntityExist(killer) then
            killer = playerPed
        end

        local killerId = Match.IsKillerAPlayer(killer)
        local killerName
        if killer == playerPed then
            killerName = GetPlayerName(GetPlayerIndex())
        elseif killerId ~= nil then
            killerName = GetPlayerName(killerId)
        else
            local isBot, botId = Bot.IsEntityABot(killer)
            local botProfile = isBot and Bot.GetProfile(botId) or nil
            killerName = botProfile and botProfile.name or "Unknown"
        end

        DeathAnim.Play(killerName, killer)
        Spectate.Run()

        return Match.RespawnPlayer()
    end

end

