AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartCombatHeli(myTeam, players)
        Gamemode.PlayTabletAnim()
        Gamemode.isInKillstreakCam = true
        Killstreaks.activeList["COMBAT_HELI"] = true
        local attributionId = Gm.KillAttribution.Begin("COMBAT_HELI")
        local heliPos = vector3(GetEntityCoords(Gamemode.utils.GetPed(), 1))
        local ped
        local heli
        local pModel = GetEntityModel(Gamemode.utils.GetPed())
        local soundKillCooldown = false
        local soundPath = "killstreak/combat_helicopter/"
        local minigunSoundId = "combatHeliMinigun"
        local cockpitSoundId = "combatHeliCockpit"
        local isFiring = false
        local firingSession = 0
        local killsBeforeFiring = 0
        local shotsWhileFiring = 0
        local impactEffectOvershoot = 25.0
        local impactEffectScale = 0.4
        local impactEffectRate = 70
        local nextImpactEffect = 0
        local firingShake = "HAND_SHAKE"
        local firingShakeAmplitude = 0.05
        local initialCameraPitch = -75.0

        FreezeEntityPosition(Gamemode.utils.GetPed(), true)
        local function playBulletSound(kind, count)
            if soundKillCooldown then
                return
            end

            PlayCustomSound("killstreak/combat_helicopter/bullet_"..kind.."_"..math.random(1, count)..".ogg",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.03, 0.05))
            soundKillCooldown = true
            Citizen.CreateThread(function()
                Wait(4000)
                soundKillCooldown = false
            end)
        end

        local function playImpactEffect(from, to)
            local delta = to - from
            local distance = #(delta)
            if distance < 1.0 then
                return
            end

            local direction = delta * (1.0 / distance)
            local probeEnd = to + direction * impactEffectOvershoot
            local probe = StartExpensiveSynchronousShapeTestLosProbe(
                from.x,
                from.y,
                from.z,
                probeEnd.x,
                probeEnd.y,
                probeEnd.z,
                19,
                0,
                0
            )
            local _, hit, endCoords = GetShapeTestResult(probe)
            local impact = (hit == true or hit == 1) and endCoords or probeEnd

            UseParticleFxAssetNextCall("core")
            StartParticleFxNonLoopedAtCoord(
                "exp_grd_grenade",
                impact.x,
                impact.y,
                impact.z,
                0.0,
                0.0,
                0.0,
                impactEffectScale,
                false,
                false,
                false
            )
        end

        local function startFiring()
            if isFiring or heli == nil or not DoesEntityExist(heli) then
                return
            end

            isFiring = true
            firingSession = firingSession + 1
            killsBeforeFiring = Gm.KillAttribution.GetKillCount(attributionId)
            shotsWhileFiring = 0
            DecorSetBool(heli, "SHOOTING", true)
            if cam.cams["KS_HELI"] ~= nil then
                ShakeCam(cam.cams["KS_HELI"], firingShake, firingShakeAmplitude)
            end
            PlayCustomSoundSequence(
                minigunSoundId,
                soundPath.."minigun_start.wav",
                soundPath.."minigun_loop.wav",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05)
            )

            local currentSession = firingSession
            Citizen.CreateThread(function()
                RequestWeaponAsset(GetHashKey("weapon_heavysniper_mk2"), 31, 0)
                local cachedEndCoords = vector3(0.0, 0.0, 0.0)

                while isFiring
                    and firingSession == currentSession
                    and Killstreaks.activeList["COMBAT_HELI"]
                    and DoesEntityExist(heli)
                do
                    local _, _, endCoords, _, _ = ScreenToWorldOnlyEntity({x = 0.5, y = 0.5}, 5000.0)

                    if endCoords ~= vector3(0.0, 0.0, 0.0) then
                        cachedEndCoords = endCoords
                    else
                        endCoords = cachedEndCoords
                    end

                    if endCoords ~= vector3(0.0, 0.0, 0.0) then
                        local heliShootPos = GetOffsetFromEntityInWorldCoords(heli, 0.0, 2.0, -3.0)
                        local rPos = vector3(
                            endCoords.x + math.random(-1, 1),
                            endCoords.y + math.random(-1, 1),
                            endCoords.z
                        )
                        local shotPos = vector3(heliShootPos.x, heliShootPos.y, heliShootPos.z - 3.0)

                        Gm.KillAttribution.RecordShot(
                            attributionId,
                            shotPos,
                            rPos,
                            GetHashKey("weapon_heavysniper_mk2"),
                            {
                                radius = 3.0,
                                ttl = 500,
                            }
                        )
                        ShootSingleBulletBetweenCoords(
                            shotPos.x,
                            shotPos.y,
                            shotPos.z,
                            rPos.xyz,
                            50.0,
                            0,
                            GetHashKey("weapon_heavysniper_mk2"),
                            Gamemode.utils.GetPed(),
                            true,
                            false,
                            5000.0
                        )
                        if GetGameTimer() >= nextImpactEffect then
                            nextImpactEffect = GetGameTimer() + impactEffectRate
                            playImpactEffect(shotPos, rPos)
                        end
                        shotsWhileFiring = shotsWhileFiring + 1
                    end

                    Wait(25)
                end
            end)
        end

        local function stopFiring()
            if not isFiring then
                return
            end

            isFiring = false
            if heli ~= nil and DoesEntityExist(heli) then
                DecorSetBool(heli, "SHOOTING", false)
            end
            if cam.cams["KS_HELI"] ~= nil then
                StopCamShaking(cam.cams["KS_HELI"], true)
            end

            StopCustomSound(minigunSoundId)
            PlayCustomSoundWithId(
                minigunSoundId,
                soundPath.."minigun_stop.wav",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05),
                false
            )

            if shotsWhileFiring > 0 then
                local killsAtStart = killsBeforeFiring
                Citizen.CreateThread(function()
                    Wait(100)
                    if Gm.KillAttribution.GetKillCount(attributionId) > killsAtStart then
                        playBulletSound("hit", 9)
                    else
                        playBulletSound("miss", 3)
                    end
                end)
            end
        end

        Citizen.CreateThread(function()
            while Killstreaks.activeList["COMBAT_HELI"] do
                local entityToFollow = 0
                local myPed = Player.GetPed()
                for k,v in pairs(GetGamePool("CPed")) do
                    if v ~= myPed then
                        if not IsEntityDead(v) then
                            if v ~= ped then
                                if IsEntityVisible(v) then
                                    if GetRelationshipBetweenPeds(myPed, v) == 5 then
                                        entityToFollow = v
                                    end
                                end
                            end
                        end
                    end
                end


                if entityToFollow == 0 then
                    entityToFollow = Gamemode.utils.GetPed()
                end

                local heliCoords = GetEntityCoords(heli)
                if heliCoords.z - heliPos.z > 150 then
                    SetEntityCoordsNoOffset(heli, heliCoords.x, heliCoords.y, heliPos.z + 50, false, false, false)
                end

                if heli ~= nil and DoesEntityExist(heli) then

                    NetworkRequestControlOfEntity(heli)
                    while not NetworkHasControlOfEntity(heli) do
                        Wait(1)
                    end

                    ClearPedTasks(ped)
                    TaskHeliChase(ped, entityToFollow, 80.0, 80.0, 50.0)
                end
                if heli ~= nil and DoesEntityExist(heli) then
                    RealWait(1500)
                else
                    RealWait(100)
                end
            end
        end)

        local timeLeft = 45
        Citizen.CreateThread(function()
            while Killstreaks.activeList["COMBAT_HELI"] do
                timeLeft = timeLeft - 1

                if timeLeft == 0 then
                    Killstreaks.activeList["COMBAT_HELI"] = false
                end
                RealWait(1000)
            end
        end)

        Citizen.CreateThread(function()
            LoadModel("akula")
            LoadModel("mp_m_freemode_01")

            heli = CreateVehicle(GetHashKey("akula"), heliPos.x + 150, heliPos.y + 150, heliPos.z + 100, 100.0, true, 1)

            local count = 0
            while not DoesEntityExist(heli) do
                count = count + 1

                if count > 30 then
                    count = 0

                    LoadModel("akula")
                    LoadModel("mp_m_freemode_01")
                    heli = CreateVehicle(GetHashKey("akula"), heliPos.x + 150, heliPos.y + 150, heliPos.z + 100, 100.0, true, 1)
                end
                Wait(10)
            end

            ped = CreatePedInsideVehicle(heli, 1, GetHashKey("mp_m_freemode_01"), -1, false, 1)
            SetHeliBladesFullSpeed(heli)
            SetHeliTurbulenceScalar(heli, 0.0)

            SetEntityHealth(ped, 2000.0)
            SetEntityInvincible(ped, true)
            SetEntityVisible(ped, false)
            FreezeEntityPosition(ped, true)
            SetPedAlertness(ped, 0.0)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetVehicleHasBeenOwnedByPlayer(heli, true)

            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Wait(0)
            end

            DoScreenFadeOut(200)
            Wait(500)
            cam.create("KS_HELI")
            cam.attachToEntity("KS_HELI", heli, 0.0, 1.0, -3.5, false)
            SetCamRot(cam.cams["KS_HELI"], initialCameraPitch, 0.0, GetEntityHeading(heli), 2)
            cam.setFov("KS_HELI", 25.0)
            cam.render("KS_HELI", true, false, 0)
            SetTimecycleModifier("heliGunCam")
            DoScreenFadeIn(250)
            PlayCustomSoundWithId(
                cockpitSoundId,
                soundPath.."cockpit_ambience.wav",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.08, 0.05),
                true
            )

            Citizen.CreateThread(function()
                local nextBeep = GetGameTimer() + math.random(3000, 8000)
                local nextRadio = GetGameTimer() + math.random(6000, 12000)
                local nextRattle = GetGameTimer() + math.random(5000, 10000)
                local nextDamage = 0
                while Killstreaks.activeList["COMBAT_HELI"] do
                    local now = GetGameTimer()
                    if now > nextBeep then
                        nextBeep = now + math.random(4000, 9000)
                        PlayCustomSound("killstreak/combat_helicopter/gunship/cockpit_beep_0"..math.random(1, 8)..".wav",
                            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.09, 0.05))
                    end
                    if now > nextRadio then
                        nextRadio = now + math.random(8000, 15000)
                        local n = math.random(1, 16)
                        PlayCustomSound("killstreak/combat_helicopter/gunship/radio_message_"..(n < 10 and ("0"..n) or n)..".wav",
                            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.12, 0.05))
                    end
                    if now > nextRattle then
                        nextRattle = now + math.random(6000, 12000)
                        PlayCustomSound("killstreak/combat_helicopter/gunship/interior_rattle_0"..math.random(1, 7)..".wav",
                            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.1, 0.05))
                    end
                    if heli ~= nil and DoesEntityExist(heli) and GetEntityHealth(heli) < 600 and now > nextDamage then
                        nextDamage = now + math.random(3000, 6000)
                        if math.random(1, 2) == 1 then
                            PlayCustomSound("killstreak/combat_helicopter/gunship/damage_groan_0"..math.random(1, 5)..".wav",
                                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.14, 0.05))
                        else
                            PlayCustomSound("killstreak/combat_helicopter/gunship/damage_burst_0"..math.random(1, 6)..".wav",
                                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.14, 0.05))
                        end
                    end
                    Wait(250)
                end
            end)


            while Killstreaks.activeList["COMBAT_HELI"] do
                DisableAllControlActions(0)

                local markers = {}
                local function pushHeliMarker(mPos, kind)
                    local ok, sx, sy = World3dToScreen2d(mPos.x, mPos.y, mPos.z + 0.4)
                    if ok then
                        markers[#markers + 1] = { x = sx, y = sy, kind = kind }
                    end
                end

                for v in EnumeratePeds() do
                    if v == Gamemode.utils.GetPed() then
                        pushHeliMarker(GetEntityCoords(v, true), "self")
                    elseif GetRelationshipBetweenPeds(Gamemode.utils.GetPed(), v) == 5 then
                        if not IsEntityDead(v) and IsEntityVisible(v) then
                            pushHeliMarker(GetEntityCoords(v, true), "target")
                        end
                    end
                end

                local vel = GetEntityVelocity(heli)
                local cameraRotation = GetCamRot(cam.cams["KS_HELI"], 2)
                exports['warv-ui']:SetHeli({
                    visible = true,
                    markers = markers,
                    time = timeLeft,
                    gun = isFiring and "firing" or "ready",
                    alt = GetEntityHeightAboveGround(heli),
                    spd = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z),
                    hdg = cameraRotation.z,
                    pitch = cameraRotation.x,
                    roll = cameraRotation.y,
                    hp = math.max(0, math.min(100, math.floor(GetEntityHealth(heli) / 10.0 + 0.5))),
                })


                CheckInputRotation(cam.cams["KS_HELI"])

                DisableControlAction(0, 24, true)
                local fireHeld = IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)
                if fireHeld then
                    startFiring()
                else
                    stopFiring()
                end


                if heli ~= nil and DoesEntityExist(heli) and IsEntityDead(heli) then
                    Killstreaks.activeList["COMBAT_HELI"] = false
                end

                Wait(1)
            end
            local wasFiring = isFiring
            stopFiring()
            if not wasFiring then
                StopCustomSound(minigunSoundId)
            end
            if cam.cams["KS_HELI"] ~= nil then
                StopCamShaking(cam.cams["KS_HELI"], true)
            end
            StopCustomSound(cockpitSoundId)
            exports['warv-ui']:SetHeli({ visible = false })
            ClearTimecycleModifier()
            DoScreenFadeOut(200)
            Wait(500)

            FreezeEntityPosition(Gamemode.utils.GetPed(), false)
            DeleteEntity(ped)
            TriggerServerEvent("DeleteEntity", VehToNet(heli))
            Gamemode.StopTabletAnim()
            Gamemode.isInKillstreakCam = false
            cam.render("KS_HELI", false, false, 0)
            Gm.KillAttribution.End(attributionId)
            DoScreenFadeIn(250)
        end)
    end
end)
