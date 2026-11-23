AddEventHandler("warv:gm_loaded", function()

    local uavModel = "velum"
    local orbitRadius = 180.0
    local orbitAlt = 120.0
    local orbitRate = 0.08
    local uavMs = 30000

    local uavs = {}
    Killstreaks.ownedUavActive = false

    local function uavCleanup(st)
        if st.ent and DoesEntityExist(st.ent) then DeleteEntity(st.ent) end
        uavs[st.id] = nil
    end

    local function playUavBoom(pos)
        local dst = Utils.GetDistanceBetweenCoords(pos, Player.GetPos())
        local vol = Sounds.GetSoundForDistance(0.08, 0.02, 300, dst)
        PlayCustomSound("killstreak/uav/impact_explosion_0" .. math.random(1, 4) .. ".wav",
            Settings.GetScaledVolume(Settings.effectsSoundVolume, vol, 0.05))
    end

    local function runUav(st)
        Citizen.CreateThread(function()
            LoadModel(uavModel)
            local mid = Matchmaking.selectedMap.middleMapPos
            local groundRef = Matchmaking.selectedMap.startFirstPos1.z
            st.center = vector3(mid.x, mid.y, groundRef + orbitAlt)
            st.ent = CreateVehicle(GetHashKey(uavModel),
                st.center.x + math.cos(st.a0) * orbitRadius,
                st.center.y + math.sin(st.a0) * orbitRadius,
                st.center.z, 0.0, false, false)
            SetModelAsNoLongerNeeded(GetHashKey(uavModel))
            FreezeEntityPosition(st.ent, true)
            SetEntityInvincible(st.ent, false)

            local t0 = GetGameTimer()
            while uavs[st.id] and st.alive do
                local t = GetGameTimer() - t0
                if t > uavMs then break end
                local a = st.a0 + orbitRate * (t / 1000.0)
                local x = st.center.x + math.cos(a) * orbitRadius
                local y = st.center.y + math.sin(a) * orbitRadius
                st.pos = vector3(x, y, st.center.z)
                SetEntityCoordsNoOffset(st.ent, x, y, st.center.z, false, false, false)
                SetEntityRotation(st.ent, 0.0, -14.0, math.deg(a) % 360.0, 2, true)

                if not st.reported
                    and HasEntityBeenDamagedByEntity(st.ent, Gamemode.utils.GetPed(), true) then
                    st.reported = true
                    Utils.TriggerGamemodeServerEvent("DestroyUav", st.id)
                end
                Wait(0)
            end
            if uavs[st.id] then uavCleanup(st) end
        end)
    end

    RegisterNetEvent("warv:uavPlaneSync")
    AddEventHandler("warv:uavPlaneSync", function(p)
        if type(p) ~= "table" or not Status.GetIsPlayerInGame() or p.gameId ~= Status.GetCurrentGameId() then return end

        if p.action == "launch" then
            if uavs[p.id] then return end
            local st = {
                id = p.id,
                gameId = p.gameId,
                alive = true,
                owner = p.owner,
                team = p.team,
                friendly = (not Gamemode.NoTeams and p.team ~= nil and p.team == Gamemode.Team)
                    or p.owner == GetPlayerServerId(PlayerId()),
                a0 = tonumber(p.a0) or 0.0,
            }
            uavs[p.id] = st
            runUav(st)

        elseif p.action == "shot" then
            local st = uavs[p.id]
            if not st or not st.alive then return end
            st.alive = false
            local pos = st.pos or st.center
            if pos then
                AddExplosion(pos.x, pos.y, pos.z, 4, 0.0, true, false, 0.6)
                playUavBoom(pos)
            end
            uavCleanup(st)
            Killstreaks.activeList["UAV"] = false
        end
    end)

    function Killstreaks.GetFriendlyUavPositions()
        local out = {}
        for _, st in pairs(uavs) do
            if st.friendly and st.alive and st.pos then
                out[#out + 1] = st.pos
            end
        end
        return out
    end

    function Gamemode.StartUav(myTeam, players, sync)
        Gamemode.AlreadyActiveKillstreak["UAV"] = true
        Killstreaks.activeList["UAV"] = true
        local blips = {}
        local isOwner = sync ~= nil and not sync
        if isOwner then
            Killstreaks.ownedUavActive = true
            local pPos = GetEntityCoords(Gamemode.utils.GetPed(), true)
            local mid = Matchmaking.selectedMap.middleMapPos
            local uavId = tostring(GetPlayerServerId(PlayerId())) .. ":uav:" .. tostring(GetGameTimer())
            Utils.TriggerGamemodeServerEvent(
                "RegisterUav",
                uavId,
                math.atan(pPos.y - mid.y, pPos.x - mid.x)
            )
        end


        Citizen.CreateThread(function()
            while Killstreaks.activeList["UAV"] do

                if Killstreaks.GamemodeAlone[Matchmaking.data.gamemode] == nil then
                    for k,v in pairs(players) do
                        if v.team ~= myTeam then
                            if IsEntityVisible(GetPlayerPed(GetPlayerFromServerId(v.id))) then
                                local player = GetPlayerFromServerId(v.id)
                                local pPed = GetPlayerPed(player)
                                local pCoord = GetEntityCoords(pPed)

                                local blip = AddBlipForCoord(pCoord)
                                SetBlipSprite(blip, 1)
                                SetBlipScale(blip, 0.85)
                                SetBlipColour(blip, 1)

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
                                SetBlipSprite(blip, 1)
                                SetBlipScale(blip, 0.85)
                                SetBlipColour(blip, 1)

                                table.insert(blips, blip)
                            end

                        end
                    end
                end


                RealWait(3000)
                for k,v in pairs(blips) do
                    RemoveBlip(v)
                end
                blips = {}


            end
        end)

        Citizen.CreateThread(function()
            local timer = GetGameTimer() + 30000
            while timer > GetGameTimer() and Killstreaks.activeList["UAV"] do
                if not Killstreaks.activeList["UAV"] then
                    break
                end
                Wait(0)
            end
            Killstreaks.activeList["UAV"] = false
            Gamemode.AlreadyActiveKillstreak["UAV"] = false

            if isOwner then
                Killstreaks.ownedUavActive = false
            end

        end)
    end

end)
