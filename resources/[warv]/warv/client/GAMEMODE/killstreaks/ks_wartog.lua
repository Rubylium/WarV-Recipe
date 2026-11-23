AddEventHandler("warv:gm_loaded", function()
    local runAlt = 260.0
    local runLow = 50.0
    local runClimb = 10.0
    local runSpeed = 105.0
    local runIn = 480.0
    local runOut = 650.0
    local fireRange = 260.0
    local firePast = 40.0
    local fireRate = 20
    local fireDamage = 120.0
    local aimSlew = 80.0
    local aimCheck = 150
    local tracerMs = 70
    local tracerSpeed = 2600.0
    local tracerLen = 60.0
    local tracerWidth = 0.5
    local impactOvershoot = 25.0
    local impactScale = 0.4
    local runs = 2

    local function probeBlocked(from, to)
        local probe = StartExpensiveSynchronousShapeTestLosProbe(
            from.x, from.y, from.z,
            to.x, to.y, to.z,
            19, 0, 0
        )
        local _, hit, endCoords = GetShapeTestResult(probe)

        return hit == true or hit == 1, endCoords
    end

    local function canHit(from, ped)
        local pos = GetEntityCoords(ped, true)

        return not probeBlocked(from, vector3(pos.x, pos.y, pos.z + 1.0))
    end

    local function diveAngle()
        return math.deg(math.atan(runAlt - runLow, runIn))
    end

    local function runBearing(aim)
        local myPos = GetEntityCoords(Gamemode.utils.GetPed(), true)
        local toAim = vector3(aim.x - myPos.x, aim.y - myPos.y, 0.0)
        local len = #(toAim)

        if len < 25.0 then
            local angle = math.random() * math.pi * 2.0
            return vector3(math.cos(angle), math.sin(angle), 0.0)
        end

        return toAim * (1.0 / len)
    end

    local function gunPitch(pos, z, aim, flown)
        if flown >= runIn then return runClimb end

        local horiz = math.max(#(vector3(aim.x - pos.x, aim.y - pos.y, 0.0)), 1.0)
        local pitch = -math.deg(math.atan(z - (aim.z + 1.0), horiz))

        return math.max(pitch, -35.0)
    end

    local tracers = {}

    local function cross(a, b)
        return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
    end

    local function tracer(from, to)
        local delta = to - from
        local len = #(delta)
        if len < 1.0 then return end

        local dir = delta * (1.0 / len)
        local far = to + dir * impactOvershoot
        local blocked, endCoords = probeBlocked(from, far)
        local impact = blocked and endCoords or far

        tracers[#tracers + 1] = {
            from = from,
            dir = dir,
            impact = impact,
            total = #(impact - from),
            flown = 0.0,
        }
    end

    local function drawTracers()
        local cam = GetGameplayCamCoord()

        for i = #tracers, 1, -1 do
            local t = tracers[i]
            t.flown = t.flown + tracerSpeed * GetFrameTime()

            if t.flown >= t.total then
                UseParticleFxAssetNextCall("core")
                StartParticleFxNonLoopedAtCoord("exp_grd_grenade", t.impact.x, t.impact.y, t.impact.z, 0.0, 0.0, 0.0, impactScale, false, false, false)
                table.remove(tracers, i)
            else
                local head = t.from + t.dir * t.flown
                local tail = t.from + t.dir * math.max(0.0, t.flown - tracerLen)
                local view = head - cam
                local viewLen = #(view)
                local side = viewLen > 0.01 and cross(t.dir, view * (1.0 / viewLen)) or vector3(1.0, 0.0, 0.0)
                local sideLen = #(side)
                side = sideLen > 0.01 and side * (tracerWidth / sideLen) or vector3(tracerWidth, 0.0, 0.0)

                DrawLine(tail.x, tail.y, tail.z, head.x, head.y, head.z, 255, 226, 130, 255)
                DrawLine(tail.x + side.x, tail.y + side.y, tail.z + side.z, head.x + side.x, head.y + side.y, head.z + side.z, 255, 168, 40, 220)
                DrawLine(tail.x - side.x, tail.y - side.y, tail.z - side.z, head.x - side.x, head.y - side.y, head.z - side.z, 255, 168, 40, 220)
            end
        end
    end

    local function findTarget(planePed, from)
        local myPed = Gamemode.utils.GetPed()
        local origin = GetEntityCoords(myPed, true)
        local exposed, exposedDst = 0, 0
        local nearest, nearestDst = 0, 0

        for _, v in pairs(GetGamePool("CPed")) do
            if v ~= planePed and v ~= myPed and not IsEntityDead(v) and IsEntityVisible(v) then
                if GetRelationshipBetweenPeds(myPed, v) == 5 then
                    local pos = GetEntityCoords(v, true)
                    local dst = #(pos - origin)

                    if nearest == 0 or dst < nearestDst then
                        nearest, nearestDst = v, dst
                    end

                    if canHit(from or vector3(pos.x, pos.y, pos.z + runLow), v) then
                        if exposed == 0 or dst < exposedDst then
                            exposed, exposedDst = v, dst
                        end
                    end
                end
            end
        end

        if exposed ~= 0 then return exposed end
        return nearest
    end

    function Gamemode.StartWartog(myTeam, players)
        Gamemode.AlreadyActiveKillstreak["WARTOG"] = true
        Killstreaks.activeList["WARTOG"] = true
        local attributionId = Gm.KillAttribution.Begin("WARTOG")
        LoadModel("strikeforce")
        LoadModel("mp_m_freemode_01")

        local mid = Matchmaking.selectedMap.middleMapPos
        local plane = CreateVehicle(GetHashKey("strikeforce"), mid.x, mid.y, mid.z + 300.0, 0.0, true, 1)

        local count = 0
        while not DoesEntityExist(plane) do
            count = count + 1
            if count > 30 then
                count = 0
                plane = CreateVehicle(GetHashKey("strikeforce"), mid.x, mid.y, mid.z + 300.0, 0.0, true, 1)
            end
            Wait(10)
        end

        local ped = CreatePedInsideVehicle(plane, 1, GetHashKey("mp_m_freemode_01"), -1, false, 1)
        Gamemode.SetTeamForPed(myTeam, ped)

        SetPlaneTurbulenceMultiplier(plane, 0.0)

        SetEntityHealth(ped, 2000.0)
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false)
        FreezeEntityPosition(ped, true)
        SetPedAlertness(ped, 0.0)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetVehicleHasBeenOwnedByPlayer(plane, true)
        SetVehicleEngineOn(plane, true, true, false)
        SetVehicleLandingGear(plane, 3)
        SetEntityCollision(plane, false, false)
        FreezeEntityPosition(plane, true)
        Killstreaks.ProtectWartog(plane)

        local firing = false
        tracers = {}

        Citizen.CreateThread(function()
            while Killstreaks.activeList["WARTOG"] do
                drawTracers()
                Wait(0)
            end
        end)

        local function strafe(target, aim)
            DecorSetBool(plane, "SHOOTING", true)
            DecorSetInt(plane, "SHOOTING_OWNER", NetworkGetNetworkIdFromEntity(Gamemode.utils.GetPed()))
            if target ~= 0 then
                DecorSetInt(plane, "SHOOTING_TARGET", NetworkGetNetworkIdFromEntity(target))
            end
            PlayCustomSound("killstreak/warthog/cannon_fire_0" .. math.random(1, 3) .. ".wav",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05))

            Citizen.CreateThread(function()
                local aimAt = vector3(aim.x, aim.y, aim.z)
                local slew = aimSlew * (fireRate / 1000.0)
                local nextCheck = 0
                local nextTracer = 0

                while firing and DoesEntityExist(plane) do
                    local shotPos = GetOffsetFromEntityInWorldCoords(plane, 0.0, 9.0, -0.5)

                    if GetGameTimer() > nextCheck then
                        nextCheck = GetGameTimer() + aimCheck
                        if target == 0 or IsEntityDead(target) or not canHit(shotPos, target) then
                            target = findTarget(ped, shotPos)
                            if target ~= 0 then
                                DecorSetInt(plane, "SHOOTING_TARGET", NetworkGetNetworkIdFromEntity(target))
                            end
                        end
                    end

                    if target ~= 0 then
                        local want = GetEntityCoords(target, true)
                        local delta = want - aimAt
                        local gap = #(delta)
                        aimAt = gap > slew and aimAt + delta * (slew / gap) or want
                    end

                    local rPos = vector3(
                        aimAt.x + (math.random() - 0.5) * 1.4,
                        aimAt.y + (math.random() - 0.5) * 1.4,
                        aimAt.z + 1.0
                    )

                    Gm.KillAttribution.RecordShot(
                        attributionId,
                        shotPos,
                        rPos,
                        GetHashKey("weapon_heavysniper_mk2"),
                        {
                            radius = 3.0,
                            ttl = 600,
                            target = target ~= 0 and target or nil,
                        }
                    )
                    if GetGameTimer() >= nextTracer then
                        nextTracer = GetGameTimer() + tracerMs
                        tracer(shotPos, rPos)
                    end
                    ShootSingleBulletBetweenCoords(shotPos.x, shotPos.y, shotPos.z, rPos.xyz, fireDamage, 0, GetHashKey("weapon_heavysniper_mk2"), Gamemode.utils.GetPed(), true, true, 5000.0)

                    Wait(fireRate)
                end

                DecorSetBool(plane, "SHOOTING", false)
                PlayCustomSound("killstreak/warthog/distant_crack.ogg",
                    Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.04, 0.05))
                PlayCustomSound("killstreak/airstrike/jet_flyby_" .. math.random(0, 6) .. ".wav",
                    Settings.effectsSoundVolume)
            end)
        end

        Citizen.CreateThread(function()
            RequestWeaponAsset(GetHashKey("weapon_heavysniper_mk2"), 31, 0)
            while not HasWeaponAssetLoaded(GetHashKey("weapon_heavysniper_mk2")) do
                Wait(0)
            end

            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Wait(0)
            end

            Wait(1500)
            local run = 0

            while Killstreaks.activeList["WARTOG"] and run < runs do
                local controlUntil = GetGameTimer() + 2000
                while not NetworkHasControlOfEntity(plane) and GetGameTimer() < controlUntil do
                    NetworkRequestControlOfEntity(plane)
                    Wait(0)
                end

                local target = findTarget(ped)
                local aim = target ~= 0 and GetEntityCoords(target, true) or mid
                local dir = runBearing(aim)
                local heading = math.deg(math.atan(-dir.x, dir.y))
                local start = vector3(aim.x, aim.y, aim.z) - dir * runIn
                local flown = 0.0
                local fired = false

                SetEntityCoordsNoOffset(plane, start.x, start.y, start.z + runAlt, false, false, false)
                SetEntityRotation(plane, -diveAngle(), 0.0, heading, 2, true)

                while Killstreaks.activeList["WARTOG"] and flown < runIn + runOut do
                    flown = flown + runSpeed * GetFrameTime()

                    local pos = start + dir * flown
                    local alt = flown < runIn
                        and runAlt - (runAlt - runLow) * (flown / runIn)
                        or runLow + (flown - runIn) * math.tan(math.rad(runClimb))
                    local z = pos.z + alt

                    SetEntityCoordsNoOffset(plane, pos.x, pos.y, z, false, false, false)
                    SetEntityRotation(plane, gunPitch(pos, z, aim, flown), 0.0, heading, 2, true)

                    if not fired and flown > runIn - fireRange then
                        fired = true
                        firing = true
                        strafe(target, aim)
                    elseif firing and flown > runIn + firePast then
                        firing = false
                    end

                    Wait(0)
                end

                firing = false
                run = run + 1
            end

            Killstreaks.activeList["WARTOG"] = false
        end)

        Citizen.CreateThread(function()
            local timer = GetGameTimer() + 60000
            while timer > GetGameTimer() do
                if not Killstreaks.activeList["WARTOG"] then
                    break
                end
                Wait(100)
            end

            Killstreaks.activeList["WARTOG"] = false
            Gamemode.AlreadyActiveKillstreak["WARTOG"] = false
            Gm.KillAttribution.End(attributionId)

            TriggerServerEvent("DeleteEntity", VehToNet(plane))
            DeleteEntity(ped)
        end)
    end
end)
