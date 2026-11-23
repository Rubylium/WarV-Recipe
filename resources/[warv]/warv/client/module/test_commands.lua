Citizen.CreateThread(function()
    if SharedConfig.devmod then

        local triggerbotEnabled = false

        local function getParticipantTeam(serverId)
            for _, participant in pairs(Gamemode.PlayersData) do
                if tonumber(participant.id) == tonumber(serverId) then
                    return tonumber(participant.team)
                end
            end

            return nil
        end

        local function isEnemyPed(playerPed, targetPed)
            if targetPed == nil
                or targetPed == 0
                or targetPed == playerPed
                or not DoesEntityExist(targetPed)
                or not IsEntityAPed(targetPed)
                or IsPedDeadOrDying(targetPed, true) then
                return false
            end

            local ffa = Gamemode.NoTeams

            local isBot, _, botTeam = Bot.IsEntityABot(targetPed)
            if isBot then
                if ffa then
                    return true
                end
                local playerTeam = tonumber(Gamemode.Team) or 0
                return playerTeam == 0 or tonumber(botTeam) ~= playerTeam
            end

            if IsPedAPlayer(targetPed) then
                local targetPlayer = GetPlayerByEntityID(targetPed)
                if targetPlayer == nil or targetPlayer == PlayerId() then
                    return false
                end

                if ffa then
                    return true
                end

                local playerTeam = tonumber(Gamemode.Team) or 0
                if playerTeam == 0 then
                    return true
                end

                local targetTeam = getParticipantTeam(GetPlayerServerId(targetPlayer))
                return targetTeam ~= nil and targetTeam ~= playerTeam
            end

            local relationship = GetRelationshipBetweenPeds(playerPed, targetPed)
            return relationship == 4 or relationship == 5
        end

        RegisterCommand("triggerbot", function()
            triggerbotEnabled = not triggerbotEnabled
            print("Triggerbot " .. (triggerbotEnabled and "enabled" or "disabled"))
        end, false)

        Citizen.CreateThread(function()
            while true do
                if not triggerbotEnabled then
                    Wait(250)
                else
                    local playerPed = PlayerPedId()
                    local isAiming, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

                    if isAiming
                        and IsPedArmed(playerPed, 4)
                        and not IsPedReloading(playerPed)
                        and not IsEntityDead(playerPed)
                        and isEnemyPed(playerPed, targetEntity) then
                        SetControlNormal(0, 24, 1.0)
                    end

                    Wait(0)
                end
            end
        end)

        local recording = false
        RegisterCommand("record", function(source, args, rawCommand)
            if not recording then
                StartRecording(1)
                recording = true
            else
                StopRecordingAndSaveClip()
                recording = false
            end
        end, false)

        local preview = false
        RegisterCommand("preview_first_spawn", function(source, args, rawCommand)
            preview = not preview
            Citizen.CreateThread(function()
                while preview do
                    local ped = Player.GetPed()
                    local zones = {
                        [1] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, 2.4, 3.0, -1.0),
                        },
                        [2] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, 1.2, 2.5, -1.0),
                        },
                        [3] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, -1.0),
                        },
                        [4] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, -1.2, 2.5, -1.0),
                        },
                        [5] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, -2.4, 3.0, -1.0),
                        },
                        [6] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.5, -0.7),
                        },
                        [7] = {
                            pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, -3.0, -0.7),
                        },
                    }
    
                    for k,v in pairs(zones) do
                        DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 10.0, 255, 255, 255, 200, false, false, 2, false, nil, nil, false)
                    end
                    Wait(1)
                end
            end)


        end, false)

        RegisterCommand("lobbyNumber", function(source, args, rawCommand)
            local tables = {}
            for i = 1, tonumber(args[1]) do
                table.insert(tables, {id = 5})
            end
            local camFov = LobbyPlacement.GetCorrectFovForPlayersNumber(tables)
            cam.setFov("Matchmaking", camFov)
        end, false)


        RegisterCommand("feed", function(source, args, rawCommand)
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName("Hello " .. GetPlayerName(PlayerId()) .. ".")
            EndTextCommandThefeedPostTicker(true, true)
        end, false)


        RegisterCommand("unlock", function(source, args, rawCommand)
            TriggerEvent("warv:UnlockNotificationNewGun", "weapon_carbinerifle")
        end, false)

        RegisterCommand("test_cruise", function(source, args, rawCommand)
            local bombModel = "prop_ld_bomb_01"
            LoadModel(bombModel)
            local spawnPos = GetEntityCoords(Gamemode.utils.GetPed(), false)
            print(spawnPos)
            local bombEntity = CreateObject(GetHashKey(bombModel), spawnPos.x + 150, spawnPos.y + 150, spawnPos.z + 100, false, true, true)
            while not DoesEntityExist(bombEntity) do
                Wait(1)
            end
            SetEntityAsMissionEntity(bombEntity, 1, 1)
            FreezeEntityPosition(bombEntity, true)
            
            print(GetEntityCoords(bombEntity, true))
            Wait(500)
            print(DoesEntityExist(bombEntity), GetOffsetFromEntityInWorldCoords(bombEntity, 6.0, -15.0, 5.0))

            DeleteEntity(bombEntity)

        end, false)
        

        local bots = {}
        RegisterCommand("test_nuke", function(source, args, rawCommand)
            Gamemode.StartNuke({}, {}, true)
        end, false)

        RegisterCommand("weapon", function(source, args, rawCommand)
            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(args[1]), 255, 0, 1)
        end, false)

        RegisterCommand("global", function(source, args, rawCommand)
            CreateRuntimeTxd('adb831a7fdd83d_Guest_d1e2a309ce7591dff86')
        end, false)

        RegisterCommand("cruise", function(source, args, rawCommand)
            Gamemode.StartCruiseMissil(1, {})
        end, false)

        RegisterCommand("points", function(source, args, rawCommand)
            Score.AddScore(5000, "Cheat")
        end, false)

        RegisterCommand("closelobby", function(source, args, rawCommand)
            StopAudioScenes()
            UiHandler.SetPageInactive("lobby")
        end, false)

        RegisterCommand("menuoff", function(source, args, rawCommand)
            StopAudioScenes()
            StopAllSounds()
            UiHandler.CloseAllPages()
            exports['warv-ui']:HideUI()
            LobbyPlacement.StopCam()
            local ped = PlayerPedId()
            FreezeEntityPosition(ped, false)
            SetEntityVisible(ped, true, false)
            SetEntityCollision(ped, true, true)
            SetEntityInvincible(ped, false)
            SetPlayerControl(PlayerId(), true, 0)
            RenderScriptCams(false, false, 0, true, true)
            ClearFocus()
            SetNuiFocus(false, false)
            DisplayRadar(true)
            print("^2[warv] menu off^7")
        end, false)

        RegisterCommand("loadipl", function(source, args, rawCommand)
            RequestIpl(args[1])
        end, false)

        RegisterCommand("unloadipl", function(source, args, rawCommand)
            RemoveIpl(args[1])
        end, false)

        RegisterCommand("setHealth", function(source, args, rawCommand)
            SetEntityHealth(Player.GetPed(), tonumber(args[1]))
        end, false)

        RegisterCommand("delbots", function(source, args, rawCommand)
            for k,v in pairs(bots) do
                DeleteEntity(v)
            end
            bots = {}
        end, false)

        RegisterCommand("testaim", function(source, args, rawCommand)
        end, false)

        RegisterCommand("testMatchmakingCam", function(source, args, rawCommand)
            Appearance.LoadPlayer(math.random(1, 2))

            cam.create("Matchmaking")
            cam.setPos("Matchmaking", SharedConfig.MatchmakingCamPos)
            cam.lookAtCoords("Matchmaking", SharedConfig.MatchmakingPositions[1].pos.xyz)
            cam.setFov("Matchmaking", 20.0)
            cam.render("Matchmaking", true, false, 0)
            ShakeCam(cam.cams["Matchmaking"], 1.0)
            SetCamMotionBlurStrength(cam.cams["Matchmaking"], "HAND_SHAKE", 1.0)


            for k,v in pairs(SharedConfig.MatchmakingPositions) do
                LoadModel("mp_m_freemode_01")
                local bot = CreatePed(1, GetHashKey("mp_m_freemode_01"), v.pos.xyzw, false, false)
                while bot == nil do
                    print("Waiting entity creation ...")
                    Wait(1)
                end
                table.insert(bots, bot)
                local pool = Appearance.TeamPool(math.random(1, 2))
                if #pool > 0 then
                    Appearance.Apply(bot, pool[math.random(1, #pool)].appearance)
                end

                Bot.SetBotAttribute(bot)
                SetEntityHeading(bot, v.pos.w)
                ClearPedTasksImmediately(bot)
                print(SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1])

                local weapon = Bot.possibleWeapon[math.random(1, #Bot.possibleWeapon)][1]

                RequestWeaponAsset(weapon, 31, 0)
                while not HasWeaponAssetLoaded(weapon) do
                    print("Waiting weap asset")
                    Wait(1)
                end
                GiveWeaponToPed(bot, weapon, 255, false, true)
                TaskStartScenarioInPlace(bot, SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1], -1, true)
            end

        end, false)

        local preview = false
        RegisterCommand("preview_lobby", function(source, args, rawCommand)
            preview = not preview
            Citizen.CreateThread(function()
                local ped = Player.GetPed()
                local pHeading = Player.GetHeading()
                local paddingStartingLeftRight = 0.0
                local paddingStartingFrontBack = 9.0
                local paddingLeftRight = 0.8
                local paddingFrontBack = 0.3
                PlayersDisplay.Poses = {}

                table.insert(PlayersDisplay.Poses, {
                    scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                    taken = false,
                    pos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight, paddingStartingFrontBack, -1.0)
                })
                for i = 1,2 do
                    local prepPos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight + (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), -1.0)
                    table.insert(PlayersDisplay.Poses, {
                        pos = prepPos,
                        scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                        taken = false
                    })
            

                    local prepPos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight - (paddingLeftRight * i), paddingStartingFrontBack +     (paddingFrontBack * i), -1.0)
                    table.insert(PlayersDisplay.Poses, {
                        pos = prepPos,
                        scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                        taken = false
                    })
                end

                local paddingStartingLeftRight = 0.0
                local paddingStartingFrontBack = 10.0
                local paddingLeftRight = 1.2
                local paddingFrontBack = 0.3

                table.insert(PlayersDisplay.Poses, {
                    scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                    taken = false,
                    pos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight, paddingStartingFrontBack, -1.0)
                })
                for i = 1,2 do
                    local prepPos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight + (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), -1.0)
                    table.insert(PlayersDisplay.Poses, {
                        pos = prepPos,
                        scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                        taken = false
                    })
            

                    local prepPos = GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight - (paddingLeftRight * i), paddingStartingFrontBack +     (paddingFrontBack * i), -1.0)
                    table.insert(PlayersDisplay.Poses, {
                        pos = prepPos,
                        scenario = SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
                        taken = false
                    })
                end
                DeleteEntity(ped)

                for k,v in pairs(PlayersDisplay.Poses) do
                    v.entity = ClonePed(Player.GetPed(), false, true, false)
                    SetEntityCoordsNoOffset(v.entity, v.pos.xyz, false, false, false)
                    SetBlockingOfNonTemporaryEvents(v.entity, true)
                    SetEntityHeading(v.entity, pHeading - 180)

                    TaskStartScenarioInPlace(v.entity, SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1], -1, true)
                end
            end)


        end, false)

        RegisterCommand("add_fake_player_to_lobby", function(source, args, rawCommand)
            for k,v in pairs(Matchmaking.data.players) do
                if v.id == 0 then
                    table.remove(Matchmaking.data.players, k)
                end
            end
            table.insert(Matchmaking.data.players, {id = math.random(1,5555), fake = true, uid = math.random(1,5555), level = math.random(1,55), name = GetRandomNickName()})
            PlayersDisplay.SetupPlayersClones()
        end)

        RegisterCommand("remove_fake_player_from_lobby", function(source, args, rawCommand)
            for k,v in pairs(Matchmaking.data.players) do
                if v.id ~= 0 and v.fake then
                    table.remove(Matchmaking.data.players, k)
                    break
                end
            end
            PlayersDisplay.SetupPlayersClones()
        end)


        RegisterCommand("testWeaponStats", function(source, args, rawCommand)
            GiveWeaponToPed(Player.GetPed(), args[1], 255, false, true)
            local retval, hudDamage, hudSpeed, hudCapacity, hudAccuracy, hudRange = GetWeaponHudStats(GetHashKey(args[1]))
            print(retval, hudDamage, hudSpeed, hudCapacity, hudAccuracy, hudRange)
        end)

        RegisterCommand("setvie", function(source, args, rawCommand)
            SetEntityHealth(Player.GetPed(), tonumber(args[1]))
            print(IsEntityDead(Player.GetPed()))
        end)

        RegisterCommand("rankup", function(source, args, rawCommand)
            RankUp.NewRankUp(math.random(1,55), 0)
        end)

        RegisterCommand("testkillstreak", function(source, args, rawCommand)
            local tier = math.max(1, math.min(3, math.floor(tonumber(args[1]) or 1)))

            Gamemode.utils.SortKillstreaks()

            local streak = Gamemode.activeKillstreak[tier]
            local config = streak and SharedConfig.Killstreaks[streak.type]
            if not config then
                print("^1[testkillstreak] no streak on tier " .. tier .. "^7")
                return
            end

            exports['warv-ui']:Notify("killstreak", {
                type = streak.type,
                label = config.label or streak.type,
                icon = config.sprite or "",
                key = "F" .. tier,
                tier = tier,
            })
        end, false)
        
        
        RegisterCommand("testDeath", function(source, args, rawCommand)
            SetPlayerInvincibleKeepRagdollEnabled(Player.GetPed(), true)
            SetPedRagdollForceFall(Player.GetPed())
            while true do
                if GetEntityHealth(Player.GetPed()) < 100 then
                    SetPlayerInvincibleKeepRagdollEnabled(Player.GetPed(), true)
                    NetworkResurrectLocalPlayer(pos.xyz, GetEntityHeading(Player.GetPed()), 0, 0)
                    SetPedRagdollForceFall(Player.GetPed())
                end
                SetPedToRagdoll(Player.GetPed(), 5000, 0, 0, 0, 0, 0)
                Wait(30)
            end
        end)

        RegisterCommand("popup", function(source, args, rawCommand)
            Lobby.ShowPopupMessage("KICKED FROM LOBBY", "You could not sync with other player.")
        end, false)

        RegisterCommand("testnotice", function(_, args)
            local message = table.concat(args, " ")
            if message == "" then
                message = "Leader only: start matchmaking"
            end

            TriggerEvent("Groups:DisplayPopupMessage", message, "SQUAD LEADER REQUIRED")
        end, false)

        RegisterCommand("test_fov", function(source, args, rawCommand)
            local fovToUse = GetGameplayCamFov()
            local dst = tonumber(args[1])
            print(fovToUse - dst * 0.5)
        end, false)
    end
end)
