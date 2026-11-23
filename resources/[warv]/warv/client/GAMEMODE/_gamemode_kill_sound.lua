KillSound = {}
KillSound.cooldown = false
KillSound.sniperWeapons = {
    [GetHashKey("weapon_sniperrifle")] = true,
    [GetHashKey("weapon_heavysniper")] = true,
    [GetHashKey("weapon_heavysniper_mk2")] = true,
    [GetHashKey("weapon_marksmanrifle")] = true,
    [GetHashKey("weapon_marksmanrifle_mk2")] = true,
}
function KillSound.HandleKillSound(weapon)
    if not KillSound.cooldown and not Killstreaks.active then

        if KillSound.sniperWeapons[weapon] == nil then
            if GetEntityModel(Gamemode.utils.GetPed()) == GetHashKey("mp_m_freemode_01") then
                PlayCustomSound("gameplay/player_kill/male/standard_kill_".. math.random(1,11) ..".ogg", Settings.killSoundVolume)
            else
                PlayCustomSound("gameplay/player_kill/female/standard_kill_".. math.random(1,16) ..".ogg", Settings.killSoundVolume)
            end
        else
            if GetEntityModel(Gamemode.utils.GetPed()) == GetHashKey("mp_m_freemode_01") then
                PlayCustomSound("gameplay/player_kill/male/sniper_kill_".. math.random(1,2) ..".ogg", Settings.killSoundVolume)
            else
                PlayCustomSound("gameplay/player_kill/female/sniper_kill_".. math.random(1,2) ..".ogg", Settings.killSoundVolume)
            end
        end


        KillSound.cooldown = true
        Citizen.CreateThread(function()
            Wait(2500)
            KillSound.cooldown = false
        end)
    end
end
