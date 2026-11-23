function Match.Run(gameID)

    if Gamemode.NoTeams then
        NetworkSetFriendlyFireOption(true)
        SetCanAttackFriendly(Player.GetPed(), true, true)
    else
        NetworkSetFriendlyFireOption(false)
        SetCanAttackFriendly(Player.GetPed(), false, false)
    end

    GamemodeRuntime.CreateThread("matchMain", function()
        Match.GameData = {}
        Status.SetCurrentGameId(gameID)
        Gamemode.PlayersData = {}
        Gamemode.Team = 0
        Gamemode.isDead = false
        Match.respawnProtection = false
        Gamemode.team1score = 0
        Gamemode.team2score = 0
        Match.GameStarted = false
        Match.displayInGameHud = false
        Match.SpawnIndex = 1
        Match.host = false
        Status.IsPlayerInGame = true
        Gamemode.SpawnProtection = false

        Bot.SetHost(false)
        Bot.GameId = gameID
        Bot.GameStarted = false
        Bot.UpdateList({[1] = {}, [2] = {}})
        Status.gameStarted = false

        Player.inGame = true

        if Matchmaking.selectedMap.mapBounds ~= nil then
            Gamemode.SetupMapBounds(Matchmaking.selectedMap.mapBounds, Matchmaking.selectedMap.mapBoundsZ)
        end

        Drops.RemoveWeaponDrops()
        Gamemode.Playing = true
        LobbyPlacement.StopCam()
        DisplayRadar(false)
        Medals.ResetCache()
        Lobby.ResetSelectedClass()
        if Match.OnStart then Match.OnStart() end
        Gamemode.utils.ResetKillstreak()
        TriggerScreenblurFadeOut(0)

        MapEnv.Apply(Matchmaking.selectedMap)

        SetFireSpreadRate(0.0)

        SetEntityVisible(PlayerPedId(), true, true)
        SetPlayerInvincible(GetPlayerIndex(), false)
        RemoveAllPedWeapons(Player.GetPed(), 1)
        SendNuiMessage(json.encode({
            teampoint = "0",
            enemypoint = "0",
        }))

        UiHandler.SetPageInactive("ui_death")

        Match.InitFunctions()
        Match.InitEvents()

        GamemodeRuntime.CreateThread("deathCheck", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                local pPed = Player.GetPed()

                if IsPedFatallyInjured(pPed) and not Gamemode.isDead and not UiHandler.IsPageActive("map_loading") then
                    if not SafeExecuteFunction(Match.PlayerDeathHandler) then
                        GamemodeRuntime.Fail("death_handler_error")
                    end
                end

                if IsPedSwimmingUnderWater(pPed) then
                    SetEntityHealth(pPed, 0)
                end

                Gamemode.HandleMinimap(Gamemode.PlayersData, Gamemode.Team)
                Wait(100)
            end
        end)

        GamemodeRuntime.CreateThread("protection", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                local needProtection = false
                if Class.selected.weapons == nil or UiHandler.IsPageActive("ui_class_selection") or UiHandler.IsPageActive("map_loading") then
                    needProtection = true
                end

                if needProtection then
                    Protection.ApplyProtectionToPed(Player.GetPed())
                else
                    if not Gamemode.isDead and not Gamemode.SpawnProtection then
                        Protection.RemoveProtectionFromPed(Player.GetPed())
                    end
                end
                Wait(1)
            end
        end)

        GamemodeRuntime.CreateThread("controls", function()
            while Player.inGame and GamemodeRuntime.IsActive() do

                DisableControlAction(0, 37, true)
                if IsDisabledControlPressed(0, 37) then
                    Lobby.DrawTeamScoreboard(Gamemode.PlayersData, 0, 0, Bot.list)

                    DisableControlAction(0, 1, true)
                    DisableControlAction(0, 2, true)
                    DisableControlAction(0, 4, true)
                    DisableControlAction(0, 6, true)
                    DisableControlAction(0, 24, true)
                else
                    Lobby.HideScoreboard()
                end

                if not Gamemode.isDead then
                    Pause.HandleMenuToogle()
                end
               
            
                if IsDisabledControlPressed(0, 21) then
                    SetPlayerSprint(GetPlayerIndex(), true)
                else
                    SetPlayerSprint(GetPlayerIndex(), false)
                end

                local pPed = Player.GetPed()
                Sounds.HandleCustomEngineSound(pPed)
                ReloadSounds.HandleReloadSound()
                Health.HandleBloodScreen()
                DamageLog.Track()
            

                Wait(0)
            end
        end)

        GamemodeRuntime.CreateThread("classControls", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                if not Gamemode.isDead and not Gamemode.isInKillstreakCam then
                    if Match.loadout then
                        Class.HandleControl()
                    end
                    if Gamemode.GamemodeWithoutKillstreaks[Matchmaking.data.gamemode] == nil then
                        Gamemode.HandleKillstreakControls(Status.GetCurrentGameId(), Gamemode.Team, Gamemode.PlayersData)
                    end
                end
                Wait(0)
            end
        end)

        GamemodeRuntime.CreateThread("timer", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                Matchmaking.data.gameTimer = Matchmaking.data.gameTimer - 1
                if Matchmaking.data.gameTimer <= 5 then
                    PlayCustomSound("countdown_tick.ogg",
                        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
                end
                if Matchmaking.data.gameTimer <= 0 then
                    Matchmaking.data.gameTimer = 0
                end
                Utils.RealWait(1000)
            end
        end)


        GamemodeRuntime.CreateThread("healthRegen", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                Health.HandleRegen(Gamemode.isDead)
                Wait(350)
            end
        end)

        GamemodeRuntime.CreateThread("hud", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                if Match.GameStarted then
                    if not Gamemode.isDead and not UiHandler.IsPageActive("ui_class_selection") and not UiHandler.IsPageActive("ui_pause_menu") and not Gamemode.isInKillstreakCam and not StartScreen.InAnimation then
                        if not Match.displayInGameHud then
                            Gamemode.StartMinimap()
                            Match.displayInGameHud = true
                            DisplayRadar(true)
                        end
                        
                        HudV2.Draw(Gamemode.team1score, Gamemode.team2score, Match.scoreLimit, Gamemode.Team)
                        PlayersUI.DrawPlayersUI(Gamemode.PlayersData, Gamemode.Team)
                    else
                        if Match.displayInGameHud then
                            Match.displayInGameHud = false

                            DisplayRadar(false)
                            ScoreHud.Hide()
                            KillstreakHud.Hide()
                            WeaponHud.Hide()
                            PlayersUI.Clear()
                            Voice.ClearInGameVoiceChat()
                        end
                        
                    end
                end
                Wait(1)
            end
        end)

        GamemodeRuntime.CreateThread("fireCleanup", function()
            while Player.inGame and GamemodeRuntime.IsActive() do
                StopFireInRange(GetEntityCoords(Player.GetPed()), 300.0)
                Wait(1500)
            end
        end)
        

        GamemodeRuntime.CreateThread("stateMonitor", function()
            Wait(1000)
            while Player.inGame and GamemodeRuntime.IsActive() do
                if not Gamemode.Playing then
                    Player.inGame = false
                end
                Wait(1000)
            end
        end)

        
    end)
end

function Match.Start(context)
    local definition = GamemodeDefinitions.Get(context.modeId)
    local capabilities = definition.capabilities
    Gamemode.NoTeams = capabilities.teams == false
    Match.loadout = capabilities.loadout ~= false
    Match.fragLimit = definition.rules.fragLimit
    Match.scoreLimit = definition.rules.scoreLimit
    Match.objective = definition.objective
    Match.Run(context.gameId)
end

function Match.Stop()
    Spectate.Stop()
    Player.inGame = false
    Gamemode.Playing = false
    Gamemode.isDead = false
    Gamemode.SpawnProtection = false
    Match.GameStarted = false
    Match.displayInGameHud = false
    HudV2.Reset()
    Status.gameStarted = false
    Status.SetIsPlayerInGame(false)
    Status.SetIsPlayerInEndScreen(false)
    UiHandler.SetPageInactive("map_loading")
    DisplayRadar(false)
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityInvincible(PlayerPedId(), false)
    SetPlayerInvincible(GetPlayerIndex(), false)
    Bot.EndGame()
    Gamemode.RemoveMapBounds()
    Gamemode.NoTeams = false
    Match.loadout = true
    Match.OnStart = nil
    Match.GiveWeapons = nil
    Match.OnPlayersData = nil
end
