AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartMinigun(myTeam, players)
        Gamemode.AlreadyActiveKillstreak["MINIGUN"] = true
        Killstreaks.activeList["MINIGUN"] = true


        Citizen.CreateThread(function()
            local timer = GetGameTimer()

            GiveWeaponToPed(Player.GetPed(), GetHashKey("weapon_minigun"), 500, false, true)
            SetCurrentPedWeapon(Player.GetPed(), GetHashKey("weapon_minigun"), true)
            while Killstreaks.activeList["MINIGUN"] do
                if timer + 60000 < GetGameTimer() or Killstreaks.forceStopKillstreak then
                    Killstreaks.activeList["MINIGUN"] = false
                    Gamemode.AlreadyActiveKillstreak["MINIGUN"] = false
                end

                local _, weapon = GetCurrentPedWeapon(Player.GetPed(), 1)
                if weapon ~= GetHashKey("weapon_minigun") then
                    Killstreaks.activeList["MINIGUN"] = false
                    Gamemode.AlreadyActiveKillstreak["MINIGUN"] = false
                    break
                end

                if Status.GetIsPlayerInEndScreen() then
                    Killstreaks.activeList["MINIGUN"] = false
                    Gamemode.AlreadyActiveKillstreak["MINIGUN"] = false
                    break
                end
                Wait(500)
            end
            RemoveWeaponFromPed(Player.GetPed(), GetHashKey("weapon_minigun"))

        end)
    end
end)