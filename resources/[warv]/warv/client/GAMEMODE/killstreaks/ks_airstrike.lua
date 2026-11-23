AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartAirStrike(myTeam, players)
        Gamemode.PlayTabletAnim()
        Gamemode.isInKillstreakCam = true
        Gamemode.AlreadyActiveKillstreak["AIRSTRIKE"] = true
        Killstreaks.activeList["AIRSTRIKE"] = true
        local pPos = GetEntityCoords(Gamemode.utils.GetPed(), true)
        FreezeEntityPosition(Gamemode.utils.GetPed(), true)
        DoScreenFadeOut(200)
        Wait(500)
        local orbitRadius = 260.0
        local orbitAlt = 170.0
        local orbitRate = 0.05

        local mid = Matchmaking.selectedMap.middleMapPos
        local groundRef = Matchmaking.selectedMap.startFirstPos1.z
        local a0 = math.atan(pPos.y - mid.y, pPos.x - mid.x)
        local lookAt = vector3(mid.x, mid.y, groundRef)

        cam.create("AIRSTRIKE")
        cam.setPos("AIRSTRIKE", vector3(mid.x + math.cos(a0) * orbitRadius, mid.y + math.sin(a0) * orbitRadius, groundRef + orbitAlt))
        cam.lookAtCoords("AIRSTRIKE", lookAt)
        cam.setFov("AIRSTRIKE", 30.0)
        cam.render("AIRSTRIKE", true, false, 0)
        SetTimecycleModifier("NG_filmnoir_BW1")
        DoScreenFadeIn(200)

        Citizen.CreateThread(function()
            local t0 = GetGameTimer()
            while Killstreaks.activeList["AIRSTRIKE"] do
                local a = a0 + orbitRate * ((GetGameTimer() - t0) / 1000.0)
                cam.setPos("AIRSTRIKE", vector3(mid.x + math.cos(a) * orbitRadius, mid.y + math.sin(a) * orbitRadius, groundRef + orbitAlt))
                cam.lookAtCoords("AIRSTRIKE", lookAt)
                Wait(0)
            end
        end)


        Citizen.CreateThread(function()
            local _, _, endCoords, _, _
            local airstrikeCoords = {}
            local gridCache = { x = 0.0, y = 0.0 }
            local nextGridAt = 0

            while Killstreaks.activeList["AIRSTRIKE"] do
                local x2 = GetControlNormal(0, 239)
                local y2 = GetControlNormal(0, 240)

                local pings = {}
                for v in EnumeratePeds() do
                    if v ~= Gamemode.utils.GetPed() and GetRelationshipBetweenPeds(Gamemode.utils.GetPed(), v) == 5 then
                        if not IsEntityDead(v) and IsEntityVisible(v) then
                            local ePos = GetEntityCoords(v, true)
                            local ok, sx, sy = World3dToScreen2d(ePos.x, ePos.y, ePos.z)
                            if ok then pings[#pings + 1] = { x = sx, y = sy } end
                        end
                    end
                end

                local targets = {}
                for k, v in pairs(airstrikeCoords) do
                    local ok, sx, sy = World3dToScreen2d(v.pos.x, v.pos.y, v.pos.z)
                    if ok then
                        targets[#targets + 1] = { x = sx, y = sy, gx = v.pos.x, gy = v.pos.y }
                    end
                end

                local camC = GetFinalRenderedCamCoord()
                if GetGameTimer() > nextGridAt then
                    nextGridAt = GetGameTimer() + 200
                    local _, _, gc = ScreenToWorldOnlyEntity({ x = x2, y = y2 }, 5000.0)
                    if gc ~= nil and gc ~= vector3(0.0, 0.0, 0.0) then
                        gridCache.x, gridCache.y = gc.x, gc.y
                    end
                end

                exports['warv-ui']:SetAirstrike({
                    visible = true,
                    cursor = { x = x2, y = y2 },
                    pings = pings,
                    targets = targets,
                    alt = math.max(0.0, camC.z - groundRef),
                    grid = gridCache,
                })

                DisableControlAction(0, 24, true)
                if IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24) then

                    _, _, endCoords, _, _ = ScreenToWorldOnlyEntity({x = x2, y = y2}, 5000.0)

                    if endCoords ~= vector3(0.0, 0.0, 0.0) then
                        table.insert(airstrikeCoords, {
                            pos = endCoords
                        })
                    end

                    if #airstrikeCoords == 3 then
                        Killstreaks.activeList["AIRSTRIKE"] = false
                        DoScreenFadeOut(200)
                        Wait(500)
                    end
                end

                Wait(0)
            end

            exports['warv-ui']:SetAirstrike({ visible = false })
            ClearTimecycleModifier()
            FreezeEntityPosition(Gamemode.utils.GetPed(), false)
            Gamemode.AlreadyActiveKillstreak["AIRSTRIKE"] = false
            cam.delete("AIRSTRIKE")
            Gamemode.isInKillstreakCam = false
            Gamemode.StopTabletAnim()
            DoScreenFadeIn(200)
            PlayCustomSound("killstreak/airstrike/jet_flyby_"..math.random(0,6)..".wav", Settings.effectsSoundVolume)
            Wait(2500)

            local attributionId = Gm.KillAttribution.Begin("AIRSTRIKE")

            if not Status.GetIsPlayerInEndScreen() then
                for k,v in pairs(airstrikeCoords) do
                    PlayCustomSound("killstreak/airstrike/explosion_distant_"..math.random(1,3)..".ogg",
                        Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.09, 0.05))
                    PlayCustomSound("killstreak/airstrike/aircraft_impact_0"..math.random(1,3)..".wav",
                        Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.15, 0.05))
                    for i = 1,3 do
                        local explosionPos
                        if pPos.z + v.pos.z > 50 then
                            explosionPos = vector3(v.pos.x + math.random(-5,5), v.pos.y + math.random(-5,5), pPos.z)
                        else
                            explosionPos = vector3(v.pos.x + math.random(-5,5), v.pos.y + math.random(-5,5), v.pos.z)
                        end
                        Gm.KillAttribution.RecordExplosion(attributionId, explosionPos, {
                            radius = 18.0,
                            ttl = 1000,
                        })
                        AddOwnedExplosion(Gamemode.utils.GetPed(), explosionPos.x, explosionPos.y, explosionPos.z, 15, 200.0, true, false, 0.0)
                    end

                    Wait(250)
                end
            end

            Gm.KillAttribution.End(attributionId)
        end)
    end
end)
