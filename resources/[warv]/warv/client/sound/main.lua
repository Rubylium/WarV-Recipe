Sounds = {}
Sounds.Cache = {}
Sounds.CacheId = {}
Sounds.weaponsSounds = {
    [GetHashKey("weapon_carbinerifle")] = "m4_fire.ogg",
    [GetHashKey("weapon_carbinerifle_mk2")] = "m4_mk2_fire.ogg",
    [GetHashKey("weapon_heavysniper_mk2")] = "dsr_fire.ogg",
    [GetHashKey("weapon_heavysniper")] = "dsr_fire.ogg",
    [GetHashKey("weapon_sniperrifle")] = "ballista_fire.ogg",
    [GetHashKey("weapon_pumpshotgun")] = "shotgun_fire.ogg",
    [GetHashKey("weapon_smg")] = "smg_fire.ogg",
    [GetHashKey("weapon_assaultrifle_mk2")] = "ak47_fire.ogg",
}

Sounds.silenceAttach = {
    "COMPONENT_AT_PI_SUPP",
    "COMPONENT_AT_PI_SUPP_02",
    "COMPONENT_AT_SR_SUPP_03",
    "COMPONENT_AT_AR_SUPP",
    "COMPONENT_AT_AR_SUPP_02",
}


Sounds.snipers = {
    [GetHashKey("weapon_sniperrifle")] = true,
    [GetHashKey("weapon_heavysniper")] = true,
    [GetHashKey("weapon_heavysniper_mk2")] = true,
    [GetHashKey("weapon_marksmanrifle")] = true,
    [GetHashKey("weapon_marksmanrifle_mk2")] = true,
}

function PlayCustomSound(soundFile, soundVolume, loop, isMusic)
    return Sounds.PlaySound(soundFile, soundVolume, loop, isMusic)
end

function PlayCustomSoundWithId(soundId, soundFile, soundVolume, loop)
    return Sounds.PlaySound(soundFile, soundVolume, loop, false, soundId)
end

function PlayCustomSoundSequence(soundId, startFile, loopFile, soundVolume)
    SendNUIMessage({
        transactionType = 'playSoundSequence',
        soundId = soundId,
        startFile = startFile,
        loopFile = loopFile,
        transactionVolume = soundVolume,
    })
end

function StopCustomSound(soundId)
    SendNUIMessage({
        transactionType = 'stopSound',
        soundId = soundId,
    })
end


function StopAllSounds()
    Sounds.StopAllSounds()
end

function Sounds.SetMusicVolume(volume)
    SendNUIMessage({
        transactionType = 'setMusicVolume',
        transactionVolume = volume,
    })
end

function Sounds.StopAllSounds()
    SendNUIMessage({
        transactionType = 'yes',
    })
end

function Sounds.RemoveSoundFromCache(id)
    if Sounds.CacheId[id] ~= nil then
        local info = Sounds.CacheId[id]
        Sounds.Cache[info.name] = nil
        Sounds.CacheId[id] = nil
    end
end

function Sounds.PlaySound(soundFile, soundVolume, loop, isMusic, soundId)
    if loop == nil then
        loop = false
    end
    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = soundFile,
        transactionVolume = soundVolume,
        loop = loop,
        isMusic = isMusic == true,
        soundId = soundId,
    })

    return soundId
end

function Sounds.NewPlaySound(soundNameId, soundName, isLooped, volume)
    local soundID = soundNameId..math.random(1,999999)
    local configuredVolume = Settings.GetScaledVolume(Settings.interfaceSoundVolume, volume, 0.05)
    Sounds.Cache[soundNameId] = {
        id = soundID,
        name = soundName,
        isLooped = isLooped,
        volume = configuredVolume,
    }
    Sounds.CacheId[soundID] = {
        id = soundNameId,
        name = soundName,
        isLooped = isLooped,
        volume = configuredVolume,
    }

    SendNUIMessage({
        type = 'playNormalSound',

        soundId      = soundID,
        soundName    = soundName,
        isLooped     = isLooped,
        volume       = configuredVolume,
    })
end


AddEventHandler('PlaySound', function(soundFile, soundVolume)
    PlayCustomSound(soundFile,
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, soundVolume, 0.05))
end)

RegisterNetEvent('sounds:PlaySoundForDomination')
AddEventHandler('sounds:PlaySoundForDomination', function(soundFile, soundVolume, loop)
    PlayCustomSound("gamemode/domination/"..soundFile..".ogg",
        Settings.GetScaledVolume(Settings.effectsSoundVolume, soundVolume, 0.05), loop)
end)

RegisterNetEvent('StopSound')
AddEventHandler('StopSound', function(soundFile, soundVolume)
    Sounds.StopAllSounds()
end)

RegisterNUICallback('soundEnded', function(data, cb)
    Sounds.RemoveSoundFromCache(data.soundId)
end)



function Sounds.HandleCustomEngineSound(pPed)
    if IsPedArmed(pPed, 4) and IsPedShooting(pPed) and not Gm.KillAttribution.HasRecentShot() then

        local _, weapon = GetCurrentPedWeapon(pPed, 1)
        Class.handleCooldown(weapon)

        local silenced = false
        for k,v in pairs(Sounds.silenceAttach) do
            if HasPedGotWeaponComponent(pPed, weapon, GetHashKey(v)) then
                silenced = true
            end
        end
        if Sounds.weaponsSounds[weapon] ~= nil then
            if not silenced then
                PlayCustomSound("weapons/"..Sounds.weaponsSounds[weapon], Settings.customWeaponSoundVolume)
            else
                if Sounds.snipers[weapon] == nil then
                    PlayCustomSound("weapons/suppressed_smg_fire.ogg", Settings.customWeaponSoundVolume)
                else
                    PlayCustomSound("weapons/suppressed_sniper_fire.ogg", Settings.customWeaponSoundVolume)
                end
            end
        else
            if silenced then
                if Sounds.snipers[weapon] == nil then
                    PlayCustomSound("weapons/suppressed_smg_fire.ogg", Settings.customWeaponSoundVolume)
                else
                    PlayCustomSound("weapons/suppressed_sniper_fire.ogg", Settings.customWeaponSoundVolume)
                end
            end
        end
    end
end

function Sounds.PlayRandomGameMusic()
    PlayCustomSound("match_music/track_"..math.random(1,3)..".ogg",
        Settings.GetScaledVolume(Settings.MusicsVolume, 0.01, 0.02))
end


function Sounds.GetSoundForDistance(maxVolume, minVolume, maxDistance, distance)
    if distance > maxDistance then
        return 0.0
    else
        local volume = maxVolume - (distance / maxDistance) * maxVolume
        if volume < minVolume then
            volume = minVolume
        end

        if volume > maxVolume then
            volume = maxVolume
        end
        return volume
    end
end


RegisterNetEvent("warv:explosionSound")
AddEventHandler("warv:explosionSound", function(data)
    local myPedPos = Player.GetPos()
    local dst = Utils.GetDistanceBetweenCoords(data.pos, myPedPos)
    local variation = math.random(1, SharedConfig.ExplosionSounds[data.type].variation)
    local sound = SharedConfig.ExplosionSounds[data.type].sound
    local path = SharedConfig.ExplosionSounds[data.type].path
    local volume = Sounds.GetSoundForDistance(
        0.08,
        0.02,
        150,
        dst
    )
    PlayCustomSound(path .. sound .. variation..".ogg",
        Settings.GetScaledVolume(Settings.customWeaponSoundVolume, volume, 0.02), false)
end)

Citizen.CreateThread(function()
    while true do
        if Gamemode.Playing and not UiHandler.IsPageActive("map_loading") then
            local myPed = Player.GetPed()
            local myPedPos = Player.GetPos()
            for v in EnumeratePeds() do
                if v ~= myPed then
                    if IsPedArmed(v, 4) and IsPedShooting(v) then
                        local pPed = v
                        local _, weapon = GetCurrentPedWeapon(pPed, 1)
                        if SharedConfig.WeaponsSound[weapon] ~= nil then
                            if SharedConfig.WeaponsSoundType[SharedConfig.WeaponsSound[weapon].type] ~= nil then
                                local dst = Utils.GetDistanceBetweenCoords(GetEntityCoords(pPed), myPedPos)
                                local dstCheckToAdd = 0.0
                                local volume = Sounds.GetSoundForDistance(
                                    0.03,
                                    0.015,
                                    300,
                                    dst
                                )
                                local closeSound = SharedConfig.WeaponsSound[weapon].closeSound
                                if closeSound ~= "" then
                                    dstCheckToAdd = dstCheckToAdd + 15
                                end
                                if dst > 20 + dstCheckToAdd then
                                    local variation = math.random(1, SharedConfig.WeaponsSoundType[SharedConfig.WeaponsSound[weapon].type].variation)
                                    local sound = SharedConfig.WeaponsSoundType[SharedConfig.WeaponsSound[weapon].type].sound
                                    local path = SharedConfig.WeaponsSoundType[SharedConfig.WeaponsSound[weapon].type].path
                                    PlayCustomSound(path .. sound .. variation..".ogg",
                                        Settings.GetScaledVolume(Settings.customWeaponSoundVolume, volume, 0.02), false)
                                elseif closeSound ~= "" then
                                    PlayCustomSound("weapons/close/" .. closeSound ..".ogg",
                                        Settings.GetScaledVolume(Settings.customWeaponSoundVolume, volume, 0.02), false)
                                end
                            end

                        end
                    end
                end
            end

            Wait(1)
        else
            Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    local sentCoord = vector3(0.0, 0.0, 0.0)
    local sentRot = vector3(0.0, 0.0, 0.0)

    while true do
        local pCoord = GetEntityCoords(Gamemode.utils.GetPed())
        local pRot = GetGameplayCamRot(0)

        if #(pCoord - sentCoord) > 0.05 or #(pRot - sentRot) > 0.05 then
            sentCoord = pCoord
            sentRot = pRot
            SendNUIMessage({
                transactionType = 'update',
                pedCoord = pCoord,
                pedRot = pRot,
            })
        end

        Wait(1)
    end
end)

