AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartCruiseMissil(myTeam, players)
        local bombModel = "prop_ld_bomb_01"
        local bombOpenModel = "prop_ld_bomb_01_open"
        local bombEntity
        local shouldExplose = false
        Killstreaks.activeList["CRUISE"] = true
        Gamemode.AlreadyActiveKillstreak["CRUISE"] = true
        Gamemode.PlayTabletAnim()
        Gamemode.isInKillstreakCam = true

        Citizen.CreateThread(function()
            LoadModel(bombModel)
            LoadModel(bombOpenModel)
            local spawnPos = GetEntityCoords(Gamemode.utils.GetPed(), true)
            bombEntity = CreateObject(GetHashKey(bombModel), spawnPos.x + 150, spawnPos.y + 150, spawnPos.z + 100, true, true, true)
            while not DoesEntityExist(bombEntity) do
                Wait(1)
            end
            DoScreenFadeOut(200)
            RealWait(500)

            cam.create("CRUISE_PRE")
            cam.setPos("CRUISE_PRE", GetOffsetFromEntityInWorldCoords(bombEntity, 6.0, -15.0, 5.0))
            cam.setFov("CRUISE_PRE", 30.0)
            cam.lookAtEntity("CRUISE_PRE", bombEntity)
            cam.render("CRUISE_PRE", true, false, true)


            DoScreenFadeIn(300)
            cam.create("CRUISE")
            cam.setPos("CRUISE", GetOffsetFromEntityInWorldCoords(bombEntity, 3.0, -2.0, 1.0))
            cam.lookAtEntity("CRUISE", bombEntity)
            cam.setFov("CRUISE", 40.0)
            cam.attachToEntity("CRUISE", bombEntity, 3.0, 3.0, 2.0, true)

            cam.switchToCam("CRUISE", "CRUISE_PRE", 1500)
            ShakeCam(cam.cams["CRUISE"], "ROAD_VIBRATION_SHAKE", 1.5)

            FreezeEntityPosition(Gamemode.utils.GetPed(), true)

            PlayCustomSound("killstreak/cruise_missile/launch.ogg",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05))
            exports['warv-ui']:SetCruise({ phase = "cinematic" })
            Citizen.CreateThread(function()
                local timer = GetGameTimer() + 3500
                while timer > GetGameTimer() and Killstreaks.activeList["CRUISE"] do
                    if DoesEntityExist(bombEntity) then
                        local multi = Utils.TimeFrame
                        local newCuisePos = GetOffsetFromEntityInWorldCoords(bombEntity, 0.0, -0.03 * multi, 0.0)
                        SetEntityCoordsNoOffset(bombEntity, newCuisePos.xyz, true, false, true)
                    end
                    Wait(0)
                end
            end)
            RealWait(2500)

            local spawnPos = GetEntityCoords(bombEntity, true)
            local rotation = GetEntityRotation(bombEntity, 2)
            TriggerServerEvent("DeleteEntity", ObjToNet(bombEntity))

            LoadModel(bombOpenModel)
            bombEntity = CreateObject(GetHashKey(bombOpenModel), spawnPos.x, spawnPos.y, spawnPos.z, true, true, true)
            SetEntityRotation(bombEntity, rotation[1], rotation[2], rotation[3], 2, false)
            cam.attachToEntity("CRUISE", bombEntity, 3.0, 3.0, 2.0, true)
            cam.lookAtEntity("CRUISE", bombEntity)

            RealWait(500)
            DoScreenFadeOut(300)
            RealWait(500)

            cam.create("CRUISE_2")
            cam.setPos("CRUISE_2", GetOffsetFromEntityInWorldCoords(bombEntity, 0.0, 1.5, 0.0))
            cam.setFov("CRUISE_2", 40.0)

            cam.render("CRUISE_2", true, false, 0)
            PlayCustomSound("killstreak/cruise_missile/flight_loop.ogg",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05))

            SetEntityCoords(bombEntity, Matchmaking.selectedMap.middleMapPos.x, Matchmaking.selectedMap.middleMapPos.y, Matchmaking.selectedMap.middleMapPos.z + 200, false, false, false, false)
            local pos = GetEntityCoords(bombEntity, true)
            local get, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)


            DoScreenFadeIn(100)


            SetEntityRotation(bombEntity, -90.0, 0.0, 0.0, 2, false)
            cam.attachToEntity("CRUISE_2", bombEntity, 0.0, 1.0, 0.0, false)
            SetCamRot(cam.cams["CRUISE_2"], -90.0, 0.0, 0.0, 2)

            Citizen.CreateThread(function()
                while not shouldExplose and Killstreaks.activeList["CRUISE"] do
                    DisableAllControlActions(0)
                    CheckInputRotation(cam.cams["CRUISE_2"])
                    Wait(0)
                end
            end)

            Citizen.CreateThread(function()
                Utils.RealWait(10000, function(cb)
                    if shouldExplose or not Killstreaks.activeList["CRUISE"] then
                        cb(true)
                    else
                        cb(false)
                    end
                end)
                shouldExplose = true
            end)

            exports['warv-ui']:SetCruise({ phase = "control", fuelMs = 10000 })
            local lastBombPos = GetEntityCoords(bombEntity, true)
            while not shouldExplose and Killstreaks.activeList["CRUISE"] do
                local markers = {}
                local function pushCruiseMarker(mPos, kind, size)
                    local ok, sx, sy = World3dToScreen2d(mPos.x, mPos.y, mPos.z + 0.4)
                    if ok then
                        markers[#markers + 1] = { x = sx, y = sy, kind = kind, size = size }
                    end
                end

                for v in EnumeratePeds() do
                    if v == Gamemode.utils.GetPed() then
                        pushCruiseMarker(GetEntityCoords(v, true), "self", 4.5)
                    elseif GetRelationshipBetweenPeds(Gamemode.utils.GetPed(), v) == 5 then
                        if not IsEntityDead(v) and IsEntityVisible(v) then
                            pushCruiseMarker(GetEntityCoords(v, true), "target", 4.5)

                            if Utils.GetDistanceBetweenCoords(GetEntityCoords(v, true), GetEntityCoords(bombEntity, true)) < 2.5 then
                                shouldExplose = true
                            end
                        end
                    end
                end

                local multi = Utils.TimeFrame
                local nextBombPos = GetOffsetFromEntityInWorldCoords(bombEntity, 0.0, 0.06 * multi, 0.0)


                SetEntityCoordsNoOffset(bombEntity, nextBombPos.xyz, true, false, true)


                pos = GetEntityCoords(bombEntity, true)
                get, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
                if not get and z < 1.5 then
                    shouldExplose = true
                end


                local rotation = GetCamRot(cam.cams["CRUISE_2"], 2)
                SetEntityRotation(bombEntity, rotation[1], rotation[2], rotation[3], 2, false)

                local ft = GetFrameTime()
                local spd = ft > 0 and (#(pos - lastBombPos) / ft) or 0.0
                lastBombPos = pos
                exports['warv-ui']:SetCruise({
                    phase = "control",
                    markers = markers,
                    alt = get and (pos.z - z) or 0,
                    spd = spd,
                    hdg = rotation.z,
                    pitch = rotation.x,
                    roll = rotation.y,
                })


                Wait(0)
            end

            TriggerServerEvent("DeleteEntity", ObjToNet(bombEntity))

            StopAllSounds()
            PlayCustomSound("killstreak/cruise_missile/impact_0"..math.random(1,4)..".ogg",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.09, 0.05))
            local attributionId = Gm.KillAttribution.Begin("CRUISE")
            if not Status.GetIsPlayerInEndScreen() then
                local explosionPos = vector3(pos.x, pos.y, pos.z + 0.5)
                Gm.KillAttribution.RecordExplosion(attributionId, explosionPos, {
                    radius = 18.0,
                    ttl = 1000,
                })
                AddOwnedExplosion(Gamemode.utils.GetPed(), explosionPos.x, explosionPos.y, explosionPos.z, 2, 2000.0, true, false, 0.3)
            end
            Gm.KillAttribution.End(attributionId)

            exports['warv-ui']:SetCruise({ phase = "off" })
            FreezeEntityPosition(Gamemode.utils.GetPed(), false)
            cam.delete("CRUISE")
            cam.delete("CRUISE_2")
            cam.delete("CRUISE_PRE")
            Killstreaks.activeList["CRUISE"] = false
            Gamemode.AlreadyActiveKillstreak["CRUISE"] = false
            Gamemode.isInKillstreakCam = false
            Gamemode.StopTabletAnim()
        end)
    end
end)
