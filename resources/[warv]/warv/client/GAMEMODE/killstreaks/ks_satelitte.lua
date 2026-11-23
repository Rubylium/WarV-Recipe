AddEventHandler("warv:gm_loaded", function()
    function Gamemode.StartSatelitte(myTeam, players)
        Gamemode.AlreadyActiveKillstreak["SATELITTE"] = true
        Killstreaks.activeList["SATELITTE"] = true
        local blips = {}
    
        Citizen.CreateThread(function()
            while Killstreaks.activeList["SATELITTE"] do
    
                if Killstreaks.GamemodeAlone[Matchmaking.data.gamemode] == nil then
                    for k,v in pairs(players) do
                        if v.team ~= myTeam then
                            if IsEntityVisible(GetPlayerPed(GetPlayerFromServerId(v.id))) then
                                local player = GetPlayerFromServerId(v.id)
                                local pPed = GetPlayerPed(player)
                                local pCoord = GetEntityCoords(pPed)
                                
                                local blip = AddBlipForCoord(pCoord)
                                SetBlipSprite(blip, 6)
                                SetBlipScale(blip, 0.85)
                                SetBlipColour(blip, 1)
                                SetBlipRotation(blip, math.ceil(GetEntityHeading(pPed)))
                                
                                table.insert(blips, blip)
                            end
                        end
                    end
                else
                    for k,v in pairs(players) do
                        if v.id ~= Gamemode.utils.GetSID() then
                            if IsEntityVisible(GetPlayerPed(GetPlayerFromServerId(v.id))) then
                                local player = GetPlayerFromServerId(v.id)
                                local pPed = GetPlayerPed(player)
                                local pCoord = GetEntityCoords(pPed)
                                
                                local blip = AddBlipForCoord(pCoord)
                                SetBlipSprite(blip, 6)
                                SetBlipScale(blip, 0.85)
                                SetBlipColour(blip, 1)
                                SetBlipRotation(blip, math.ceil(GetEntityHeading(pPed)))
                                
                                table.insert(blips, blip)
                            end
                        end
                    end
        
                end
    
                Wait(10)
    
                for k,v in pairs(blips) do
                    RemoveBlip(v)
                end
                blips = {}
            end
        end)
    
        Citizen.CreateThread(function()
            local timer = GetGameTimer()
            while Killstreaks.activeList["SATELITTE"] do
                if timer + 60000 < GetGameTimer() or Killstreaks.forceStopKillstreak then
                    Killstreaks.activeList["SATELITTE"] = false
                    Gamemode.AlreadyActiveKillstreak["SATELITTE"] = false
                end
                Wait(500)
            end
    
            Killstreaks.activeList["SATELITTE"] = false
            Gamemode.AlreadyActiveKillstreak["SATELITTE"] = false
        end)
    end
    
end)