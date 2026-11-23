AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartRcXd(myTeam, players)
        Gamemode.isInKillstreakCam = true
        Gamemode.PlayTabletAnim()
        FreezeEntityPosition(Gamemode.utils.GetPed(), true)
        DoScreenFadeOut(200)
        Wait(500)
        Gamemode.AlreadyActiveKillstreak["RCXD"] = true
        Killstreaks.activeList["RCXD"] = true
        local attributionId = Gm.KillAttribution.Begin("RCXD")
        Citizen.CreateThread(function()
            LoadModel("rcbandito")
            LoadModel("mp_m_freemode_01")
            local pPos = GetOffsetFromEntityInWorldCoords(Gamemode.utils.GetPed(), 0.0, 1.0, 0.0)
            local veh = CreateVehicle(GetHashKey("rcbandito"), pPos.xyz, GetEntityHeading(Gamemode.utils.GetPed()), 1, 1)
            local ped = CreatePedInsideVehicle(veh, 1, GetHashKey("mp_m_freemode_01"), -1, 0, 1)

            SetEntityInvincible(ped, true)
            SetEntityVisible(ped, false)
            FreezeEntityPosition(ped, true)
            SetPedAlertness(ped, 0.0)

            TaskWarpPedIntoVehicle(ped, veh, -1)

            while not IsPedInVehicle(ped, veh) do
                TaskWarpPedIntoVehicle(ped, veh, -1)

                if not DoesEntityExist(veh) then
                    veh = CreateVehicle(GetHashKey("rcbandito"), pPos.xyz, GetEntityHeading(Gamemode.utils.GetPed()), 1, 1)
                    Wait(100)
                end

                if not DoesEntityExist(ped) then
                    ped = CreatePedInsideVehicle(veh, 1, GetHashKey("mp_m_freemode_01"), -1, 0, 1)
                    Wait(100)
                end

                Wait(1)
            end

            local vehPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.0, 0.3)

            cam.create("RCXD")
            cam.setPos("RCXD", vector3(vehPos.x, vehPos.y, vehPos.z))
            cam.lookAtEntity("RCXD", veh)
            cam.setFov("RCXD", 60.0)
            cam.render("RCXD", true, false, 0)

            exports['warv-ui']:SetRcxd({ visible = true })
            DoScreenFadeIn(200)

            while Killstreaks.activeList["RCXD"] do
                DisableAllControlActions(0)
                vehPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.0, 0.3)
                cam.setPos("RCXD", vector3(vehPos.x, vehPos.y, vehPos.z))

                if GetPedInVehicleSeat(veh, -1) == 0 then
                    DeleteEntity(ped)
                    ped = CreatePed(5, GetHashKey("mp_m_freemode_01"), pPos.xyz, 100.0, false, true)

                    SetEntityInvincible(ped, true)
                    SetEntityVisible(ped, false)
                    FreezeEntityPosition(ped, true)
                    SetPedAlertness(ped, 0.0)

                    TaskWarpPedIntoVehicle(ped, veh, -1)
                end

                if not NetworkHasControlOfEntity(ped) then
                    NetworkRequestControlOfEntity(ped)
                elseif not NetworkHasControlOfEntity(veh) then
                    NetworkRequestControlOfEntity(veh)
                end

                if IsDisabledControlPressed(0, 71) and not IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 9, 1)
                end

                if IsDisabledControlJustReleased(0, 71) or IsDisabledControlJustReleased(0, 72) then
                    TaskVehicleTempAction(ped, veh, 6, 1000)
                end

                if IsDisabledControlPressed(0, 72) and not IsDisabledControlPressed(0, 71) then
                    TaskVehicleTempAction(ped, veh, 22, 1)
                end

                if IsDisabledControlPressed(0, 63) and IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 13, 1)
                end

                if IsDisabledControlPressed(0, 64) and IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 14, 1)
                end

                if IsDisabledControlPressed(0, 71) and IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 30, 100)
                end

                if IsDisabledControlPressed(0, 63) and IsDisabledControlPressed(0, 71) then
                    TaskVehicleTempAction(ped, veh, 7, 1)
                end

                if IsDisabledControlPressed(0, 64) and IsDisabledControlPressed(0, 71) then
                    TaskVehicleTempAction(ped, veh, 8, 1)
                end

                if IsDisabledControlPressed(0, 63) and not IsDisabledControlPressed(0, 71) and not IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 4, 1)
                end

                if IsDisabledControlPressed(0, 64) and not IsDisabledControlPressed(0, 71) and not IsDisabledControlPressed(0, 72) then
                    TaskVehicleTempAction(ped, veh, 5, 1)
                end

                ClearPedTasks(ped)

                if IsDisabledControlPressed(0, 38) then
                    FreezeEntityPosition(Gamemode.utils.GetPed(), false)
                    if not Status.GetIsPlayerInEndScreen() then
                        Gm.KillAttribution.RecordExplosion(attributionId, vehPos, {
                            radius = 15.0,
                            ttl = 1000,
                        })
                        AddOwnedExplosion(Gamemode.utils.GetPed(), vehPos.x, vehPos.y, vehPos.z, 2, 200.0, true, false, 0.0)
                    end
                    Killstreaks.activeList["RCXD"] = false
                end
                Wait(1)
            end

            exports['warv-ui']:SetRcxd({ visible = false })
            Gamemode.StopTabletAnim()
            DoScreenFadeOut(200)
            Wait(500)
            cam.delete("RCXD")
            SetEntityAsNoLongerNeeded(veh)
            SetEntityAsNoLongerNeeded(ped)
            Gamemode.AlreadyActiveKillstreak["RCXD"] = false


            DeleteEntity(ped)
            TriggerServerEvent("DeleteEntity", VehToNet(veh))
            Gamemode.isInKillstreakCam = false
            DoScreenFadeIn(200)

            Gm.KillAttribution.End(attributionId)
        end)
    end
end)
