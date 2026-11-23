AddEventHandler("warv:gm_loaded", function()

    local droneModel = "m24_2_prop_m42_drone_01a"
    local ascendMs = 2500
    local orbitMs = 5000
    local orbitRadius = 35.0
    local orbitAlt = 25.0
    local orbitSpeed = 0.5
    local strikeSpeed = 32.0
    local touchDist = 2.2
    local searchTimeoutMs = 20000
    local strikeTimeoutMs = 15000

    local drones = {}

    local function playDroneBoom(pos)
        local dst = Utils.GetDistanceBetweenCoords(pos, Player.GetPos())
        local vol = Sounds.GetSoundForDistance(0.16, 0.04, 150, dst)
        PlayCustomSound("killstreak/suicide_drone/explosion.wav",
            Settings.GetScaledVolume(Settings.effectsSoundVolume, vol, 0.05))
    end

    local function cleanup(st)
        if st.sound then
            StopSound(st.sound)
            ReleaseSoundId(st.sound)
            st.sound = nil
        end
        if st.blip then
            RemoveBlip(st.blip)
            st.blip = nil
        end
        if st.ent and DoesEntityExist(st.ent) then DeleteEntity(st.ent) end
        drones[st.id] = nil
        if st.mine then
            if st.attributionId then
                Gm.KillAttribution.End(st.attributionId)
            end
            Killstreaks.activeList["SUICIDE_DRONE"] = false
            Gamemode.AlreadyActiveKillstreak["SUICIDE_DRONE"] = false
        end
    end

    local function pathPos(st, t)
        if t < ascendMs then
            local k = t / ascendMs
            k = k * k * (3.0 - 2.0 * k)
            return st.spawn + (st.entry - st.spawn) * k
        end
        local a = st.a0 + orbitSpeed * ((t - ascendMs) / 1000.0)
        return vector3(st.center.x + math.cos(a) * orbitRadius, st.center.y + math.sin(a) * orbitRadius, st.orbitZ)
    end

    local function runDrone(st)
        Citizen.CreateThread(function()
            LoadModel(droneModel)
            st.ent = CreateObject(GetHashKey(droneModel), st.spawn.x, st.spawn.y, st.spawn.z, false, false, false)
            SetEntityHasGravity(st.ent, false)
            FreezeEntityPosition(st.ent, true)
            SetModelAsNoLongerNeeded(GetHashKey(droneModel))
            if Settings.effectsSoundVolume > 0.0 then
                st.sound = GetSoundId()
                PlaySoundFromEntity(st.sound, "Flight_Loop", st.ent, "DLC_BTL_Drone_Sounds", true, 0)
            end
            if st.ally then
                st.blip = AddBlipForEntity(st.ent)
                SetBlipSprite(st.blip, 627)
                SetBlipScale(st.blip, 0.4)
            end

            local lastPos = st.spawn
            while drones[st.id] and st.alive do
                if not Status.GetIsPlayerInGame() then
                    cleanup(st)
                    return
                end

                local pos
                if st.phase == "strike" then
                    local tgt = st.targetPos
                    local ent = st.targetNet and NetworkGetEntityFromNetworkId(st.targetNet)
                    if ent and ent ~= 0 and DoesEntityExist(ent) and not IsEntityDead(ent) then
                        tgt = GetEntityCoords(ent) + vector3(0.0, 0.0, 0.4)
                        st.targetPos = tgt
                    end
                    local d = tgt - st.pos
                    local dist = #d
                    if dist > 0.01 then
                        pos = st.pos + (d / dist) * math.min(strikeSpeed * GetFrameTime(), dist)
                    else
                        pos = st.pos
                    end
                else
                    pos = pathPos(st, GetGameTimer() - st.t0)
                end
                st.pos = pos
                SetEntityCoordsNoOffset(st.ent, pos.x, pos.y, pos.z, false, false, false)

                local dp = pos - lastPos
                if #dp > 0.001 then
                    local yaw = math.deg(math.atan(dp.y, dp.x)) - 90.0
                    local pitch = math.deg(math.atan(dp.z, #(vector3(dp.x, dp.y, 0.0))))
                    SetEntityRotation(st.ent, math.max(-35.0, math.min(35.0, pitch)), 0.0, yaw, 2, true)
                    lastPos = pos
                end

                if not st.reported and HasEntityBeenDamagedByAnyPed(st.ent) then
                    st.reported = true
                    TriggerServerEvent("warv:suicideDrone", { action = "shot", id = st.id, gameId = st.gameId })
                end
                Wait(0)
            end
        end)
    end

    local function runAuthority(st)
        Citizen.CreateThread(function()
            while drones[st.id] and st.alive and (GetGameTimer() - st.t0) < (ascendMs + orbitMs) do
                Wait(50)
            end

            local searchEnd = GetGameTimer() + searchTimeoutMs
            local targetNet, targetPos
            while drones[st.id] and st.alive and st.phase == "fly" and targetNet == nil do
                if st.ent and DoesEntityExist(st.ent) then
                    for ped in EnumeratePeds() do
                        if ped ~= 0 and ped ~= Gamemode.utils.GetPed() and DoesEntityExist(ped) and not IsEntityDead(ped)
                            and GetRelationshipBetweenPeds(Gamemode.utils.GetPed(), ped) == 5
                            and HasEntityClearLosToEntity(st.ent, ped, 17) then
                            targetNet = NetworkGetNetworkIdFromEntity(ped)
                            targetPos = GetEntityCoords(ped)
                            break
                        end
                    end
                end
                if targetNet or GetGameTimer() > searchEnd then break end
                Wait(400)
            end

            if not (drones[st.id] and st.alive and st.phase == "fly") then return end
            if targetNet then
                TriggerServerEvent("warv:suicideDrone", {
                    action = "strike", id = st.id, gameId = st.gameId,
                    net = targetNet, x = targetPos.x, y = targetPos.y, z = targetPos.z,
                })
            else
                TriggerServerEvent("warv:suicideDrone", { action = "explode", id = st.id, gameId = st.gameId })
                return
            end

            while drones[st.id] and st.alive and st.phase ~= "strike" do Wait(50) end
            local strikeEnd = GetGameTimer() + strikeTimeoutMs
            while drones[st.id] and st.alive and st.phase == "strike" do
                if st.targetPos and st.pos and #(st.pos - st.targetPos) < touchDist then break end
                if GetGameTimer() > strikeEnd then break end
                Wait(0)
            end
            if drones[st.id] and st.alive then
                TriggerServerEvent("warv:suicideDrone", { action = "explode", id = st.id, gameId = st.gameId })
            end
        end)
    end

    RegisterNetEvent("warv:suicideDroneSync")
    AddEventHandler("warv:suicideDroneSync", function(p)
        if type(p) ~= "table" or not Status.GetIsPlayerInGame() or p.gameId ~= Status.GetCurrentGameId() then return end

        if p.action == "launch" then
            if drones[p.id] then return end
            local st = {
                id = p.id,
                gameId = p.gameId,
                mine = p.owner == GetPlayerServerId(PlayerId()),
                spawn = vector3(p.x, p.y, p.z),
                t0 = GetGameTimer(),
                phase = "fly",
                alive = true,
            }
            if st.mine then
                st.attributionId = Gm.KillAttribution.Begin("SUICIDE_DRONE", st.id)
            end
            st.ally = st.mine or (not Gamemode.NoTeams and p.team ~= nil and p.team == Gamemode.Team)
            local mid = Matchmaking.selectedMap.middleMapPos
            local cx, cy = mid.x, mid.y
            st.orbitZ = st.spawn.z + orbitAlt
            st.center = vector3(cx, cy, st.orbitZ)
            st.a0 = math.atan(st.spawn.y - cy, st.spawn.x - cx)
            st.entry = vector3(cx + math.cos(st.a0) * orbitRadius, cy + math.sin(st.a0) * orbitRadius, st.orbitZ)
            st.pos = st.spawn
            drones[p.id] = st
            runDrone(st)
            if st.mine then runAuthority(st) end

        elseif p.action == "strike" then
            local st = drones[p.id]
            if not st or not st.alive then return end
            st.targetNet = p.net
            st.targetPos = vector3(p.x, p.y, p.z)
            st.phase = "strike"

        elseif p.action == "shot" then
            local st = drones[p.id]
            if not st or not st.alive then return end
            st.alive = false
            if st.pos then
                AddExplosion(st.pos.x, st.pos.y, st.pos.z, 4, 0.0, true, false, 0.4)
                playDroneBoom(st.pos)
            end
            cleanup(st)

        elseif p.action == "explode" then
            local st = drones[p.id]
            if not st or not st.alive then return end
            st.alive = false
            local pos = st.pos or st.spawn
            if st.mine and not Status.GetIsPlayerInEndScreen() then
                Gm.KillAttribution.RecordExplosion(st.attributionId, pos, {
                    radius = 15.0,
                    ttl = 1000,
                    target = st.targetNet and NetworkGetEntityFromNetworkId(st.targetNet) or nil,
                })
                AddOwnedExplosion(Gamemode.utils.GetPed(), pos.x, pos.y, pos.z, 4, 2000.0, true, false, 0.3)
            elseif not st.mine then
                AddExplosion(pos.x, pos.y, pos.z, 4, 0.0, true, false, 0.3)
            end
            playDroneBoom(pos)
            cleanup(st)
        end
    end)

    function Gamemode.StartSuicideDrone(sync)
        if sync then return end
        Killstreaks.activeList["SUICIDE_DRONE"] = true
        Gamemode.AlreadyActiveKillstreak["SUICIDE_DRONE"] = true
        PlayCustomSound("killstreak/suicide_drone/drone_start.wav",
            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.18, 0.05))
        Gamemode.PlayTabletAnim()
        Citizen.CreateThread(function()
            Wait(2000)
            Gamemode.StopTabletAnim()
        end)
        local pPos = GetEntityCoords(Gamemode.utils.GetPed(), true)
        TriggerServerEvent("warv:suicideDrone", {
            action = "launch",
            id = tostring(GetPlayerServerId(PlayerId())) .. ":" .. tostring(GetGameTimer()),
            gameId = Status.GetCurrentGameId(),
            team = Gamemode.Team,
            x = pPos.x, y = pPos.y, z = pPos.z + 3.0,
        })
    end

    function Killstreaks.GetAllyDronePositions()
        local out = {}
        for _, st in pairs(drones) do
            if st.ally and st.alive and st.pos then
                out[#out + 1] = st.pos
            end
        end
        return out
    end
end)
