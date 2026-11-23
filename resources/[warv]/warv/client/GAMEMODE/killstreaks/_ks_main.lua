Killstreaks = {}
Killstreaks.active = false
Killstreaks.activeList = {}
Killstreaks.onCooldown = {}
Killstreaks.forceStopKillstreak = false
Killstreaks.playingTabletAnim = false
Killstreaks.GamemodeAlone = {
    ["FFA"] = true,
    ["GUN GAME"] = true,
}

function Killstreaks.ProtectWartog(plane)
    SetEntityInvincible(plane, true)
    SetEntityCanBeDamaged(plane, false)
    SetEntityProofs(plane, true, true, true, true, true, true, true, true)
    SetVehicleCanBeVisiblyDamaged(plane, false)
    SetVehicleTyresCanBurst(plane, false)
    SetVehicleWheelsCanBreak(plane, false)
    SetVehicleStrong(plane, true)
    SetDisableVehiclePetrolTankDamage(plane, true)
    SetDisableVehiclePetrolTankFires(plane, true)
end

AddEventHandler("warv:gm_loaded", function()
    function Gamemode.SetKillstreakOnCooldown(name)
        Citizen.CreateThread(function()
            local time = SharedConfig.Killstreaks[name].cooldown
            Killstreaks.onCooldown[name] = time

            while Killstreaks.onCooldown[name] ~= nil and Killstreaks.onCooldown[name] > 0 do
                Killstreaks.onCooldown[name] = Killstreaks.onCooldown[name] - 1
                RealWait(1000)
            end
            Killstreaks.onCooldown[name] = nil
        end)
    end

    function Gamemode.IsAnyKillStreakActive()
        local active = false
        for k,v in pairs(Killstreaks.activeList) do
            if v then
                active = true
                break
            end
        end
        Killstreaks.active = active
    end

    function Gamemode.StopAllKillsteaks()
        for k,v in pairs(Killstreaks.activeList) do
            Killstreaks.activeList[k] = false
        end
    end

    DecorRegister("SHOOTING", 2)
    DecorRegister("SHOOTING_OWNER", 3)
    DecorRegister("SHOOTING_TARGET", 3)

    function Gamemode.ForceStopKillstreaks()
        Killstreaks.forceStopKillstreak = true
        Killstreaks.active = false
        Gm.KillAttribution.Clear()
        Gamemode.StopAllKillsteaks()

        Citizen.CreateThread(function()
            Wait(5000)
            Killstreaks.forceStopKillstreak = false
            Killstreaks.onCooldown = {}
        end)
    end

    function Gamemode.HandleKillstreak(kills)
        for tier,v in ipairs(Gamemode.activeKillstreak) do
            if v.kills <= kills and not v.used and not v.unlocked then
                v.unlocked = true
                v.used = true

                local config = SharedConfig.Killstreaks[v.type]
                if config then
                    exports['warv-ui']:Notify("killstreak", {
                        type = v.type,
                        label = config.label or v.type,
                        icon = config.sprite or "",
                        key = "F" .. tier,
                        tier = tier,
                    })
                end
            end
        end
    end

    function Gamemode.PlayTabletAnim()
        if Killstreaks.playingTabletAnim then
            return
        end

        Killstreaks.playingTabletAnim = true
        LoadModel("prop_cs_tablet")

        local TabletEntity = CreateObject(GetHashKey("prop_cs_tablet"), GetEntityCoords(Gamemode.utils.GetPed()), true)

        AttachEntityToEntity(TabletEntity, Gamemode.utils.GetPed(), GetPedBoneIndex(Gamemode.utils.GetPed(), 28422), -0.03, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

        RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a")

        TaskPlayAnim(Gamemode.utils.GetPed(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )

        Citizen.CreateThread(function()
            while Killstreaks.playingTabletAnim and not Gamemode.isDead do
                Citizen.Wait(1)
                if IsEntityDead(Gamemode.utils.GetPed()) then
                    Killstreaks.playingTabletAnim = false
                else
                    if not IsEntityPlayingAnim(Gamemode.utils.GetPed(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3) then
                        TaskPlayAnim(Gamemode.utils.GetPed(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )
                    end
                end
            end

            DetachEntity(TabletEntity, 1, 1)
            DeleteEntity(TabletEntity)
            ClearPedTasksImmediately(Gamemode.utils.GetPed())
        end)
    end

    function Gamemode.StopTabletAnim()
        Killstreaks.playingTabletAnim = false
    end

    function Gamemode.TriggerKillstreak(gameID, name, myTeam, players, alreadySync)
        local v = SharedConfig.Killstreaks[name]
        if v == nil then return end

        if alreadySync then
            v.action(myTeam, players, true)
        else
            v.action(myTeam, players, false)
            Utils.TriggerGamemodeServerEvent("GetKillStreakFromTeam", name, myTeam, v.sync)
        end
    end

    local killstreakKeys = { 288, 289, 170 }

    function Gamemode.HandleKillstreakControls(gameID, myTeam, players)
        for slot, key in ipairs(killstreakKeys) do
            if IsControlJustReleased(0, key) then
                local ks = Gamemode.activeKillstreak[slot]
                if Killstreaks.onCooldown[ks.type] == nil then
                    if Gamemode.AlreadyActiveKillstreak[ks.type] then
                        return
                    end

                    if ks.unlocked then
                        Gamemode.SetKillstreakOnCooldown(ks.type)
                        ks.unlocked = false
                        Gamemode.TriggerKillstreak(gameID, ks.type, myTeam, players)
                    end
                end
            end
        end
    end


    local KillstreaksEntity = {}

    Citizen.CreateThread(function()
        while true do
            for v in EnumerateVehicles() do
                if KillstreaksEntity[v] == nil then
                    local model = GetEntityModel(v)
                    if model == GetHashKey("strikeforce") then
                        Killstreaks.ProtectWartog(v)
                        KillstreaksEntity[v] = v
                    elseif model == GetHashKey("akula") then
                        KillstreaksEntity[v] = v
                    end
                end
            end
            Wait(1000)
        end
    end)

    local cooldown = {
        ["strikeforce"] = {}
    }
    local combatHeliFiring = {}
    local combatHeliSoundPath = "killstreak/combat_helicopter/"

    local function getCombatHeliVolume(heli)
        local distance = #(GetEntityCoords(Gamemode.utils.GetPed(), true) - GetEntityCoords(heli, true))
        return math.max(0.0, math.min(0.05, 0.05 * (250.0 - distance) / 250.0))
    end

    local function getCombatHeliSoundId(heli)
        return "combatHeliDistantMinigun:"..tostring(heli)
    end

    local function startCombatHeliSound(heli)
        PlayCustomSoundSequence(
            getCombatHeliSoundId(heli),
            combatHeliSoundPath.."distant_minigun_start.wav",
            combatHeliSoundPath.."distant_minigun_loop.wav",
            Settings.GetScaledVolume(Settings.effectsSoundVolume, getCombatHeliVolume(heli), 0.05)
        )
        combatHeliFiring[heli] = true
    end

    local function stopCombatHeliSound(heli, playStopSound)
        if not combatHeliFiring[heli] then
            return
        end

        StopCustomSound(getCombatHeliSoundId(heli))
        if playStopSound and DoesEntityExist(heli) then
            PlayCustomSoundWithId(
                getCombatHeliSoundId(heli),
                combatHeliSoundPath.."distant_minigun_stop.wav",
                Settings.GetScaledVolume(Settings.effectsSoundVolume, getCombatHeliVolume(heli), 0.05),
                false
            )
        end
        combatHeliFiring[heli] = nil
    end

    Citizen.CreateThread(function()
        while true do
            local count = 0

            if not Killstreaks.active then
                for k,v in pairs(KillstreaksEntity) do
                    if DoesEntityExist(v) then
                        if GetEntityModel(v) == GetHashKey("akula") then
                            local shooting = DecorExistOn(v, "SHOOTING")
                                and (DecorGetBool(v, "SHOOTING") == 1 or DecorGetBool(v, "SHOOTING") == true)

                            if shooting and not combatHeliFiring[v] then
                                startCombatHeliSound(v)
                            elseif not shooting and combatHeliFiring[v] then
                                stopCombatHeliSound(v, true)
                            end
                        end

                        if GetEntityModel(v) == GetHashKey("strikeforce") and cooldown["strikeforce"][v] == nil then
                            if DecorExistOn(v, "SHOOTING") then
                                if DecorGetBool(v, "SHOOTING") == 1 or DecorGetBool(v, "SHOOTING") == true then
                                    if not IsEntityDead(v) then
                                        PlayCustomSound("killstreak/warthog/cannon_fire_0"..math.random(1, 3)..".wav",
                                            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.07, 0.05))
                                        Citizen.CreateThread(function()
                                            for i = 1, 20 do
                                                local HeliShootPos = GetEntityCoords(v, true)
                                                local rPos = GetEntityCoords(NetworkGetEntityFromNetworkId(DecorGetInt(v, "SHOOTING_TARGET")))
                                                local ownerId = NetworkGetEntityFromNetworkId(DecorGetInt(v, "SHOOTING_OWNER"))
                                                ShootSingleBulletBetweenCoords(HeliShootPos.x, HeliShootPos.y, HeliShootPos.z - 15.0, rPos.xyz, 0.0, 0, GetHashKey("weapon_heavysniper_mk2"), ownerId, true, false, 5000.0)
                                                Wait(80)
                                            end
                                        end)
                                        Wait(1500)
                                        PlayCustomSound("killstreak/warthog/distant_crack.ogg", Settings.effectsSoundVolume)

                                        cooldown["strikeforce"][v] = true
                                        Citizen.CreateThread(function()
                                            Wait(3500)
                                            cooldown["strikeforce"][v] = nil
                                        end)
                                    else
                                        KillstreaksEntity[k] = nil
                                    end
                                end
                            end
                        end

                        count = count + 1
                    else
                        stopCombatHeliSound(v, false)
                        KillstreaksEntity[k] = nil
                    end
                end
            else
                for heli in pairs(combatHeliFiring) do
                    stopCombatHeliSound(heli, false)
                end
            end

            if count > 0 then
                Wait(10)
            else
                Wait(500)
            end
        end
    end)


    Citizen.CreateThread(function()
        while true do
            Gamemode.IsAnyKillStreakActive()
            Wait(50)
        end
    end)
end)
