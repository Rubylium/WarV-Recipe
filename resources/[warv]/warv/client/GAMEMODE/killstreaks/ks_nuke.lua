AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartNuke(myTeam, players, noExplosion)
        Citizen.CreateThread(function()
            local doExplosions = not noExplosion
            local path = "killstreak/nuke/"

            if doExplosions and Status.GetIsPlayerInGame() and not Status.GetIsPlayerInEndScreen() then
                Medals.AddMedalsToShow("nuke", Status.GetCurrentGameId())
            end

            StopAllSounds()
            exports['warv-ui']:NukeIncoming(19300)
            PlayCustomSound(path.."distant_launch.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.25, 0.05))
            Utils.RealWait(1500)
            PlayCustomSound(path.."alarm.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.04, 0.05))
            Utils.RealWait(1000)
            PlayCustomSound(path.."flight_loop.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05))
            Utils.RealWait(14*1000)
            PlayCustomSound(path.."impact_low.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.25, 0.05))
            PlayCustomSound(path.."incoming_warning.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.08, 0.05))
            Utils.RealWait(2800)
            PlayCustomSound(path.."blast_main.flac",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.20, 0.05))

            SetWeatherTypeNowPersist("HALLOWEEN")
            SetWeatherTypePersist("HALLOWEEN")
            SetWeatherTypeNow("HALLOWEEN")

            if doExplosions then
                local attributionId = Gm.KillAttribution.Begin("NUKE")
                if not Status.GetIsPlayerInEndScreen() then
                    for v in EnumeratePeds() do
                        local pos = GetEntityCoords(v)
                        Gm.KillAttribution.RecordExplosion(attributionId, pos, {
                            radius = 6.0,
                            ttl = 1000,
                            target = v,
                            targetOnly = true,
                        })
                        AddOwnedExplosion(Gamemode.utils.GetPed(), pos.x, pos.y, pos.z, 29, 2000.0, true, false, 2.0)
                    end
                end

                Gm.KillAttribution.End(attributionId)
            end
        end)
    end
end)
