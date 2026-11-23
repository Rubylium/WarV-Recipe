ReloadSounds = {}
ReloadSounds.cooldown = false
function ReloadSounds.HandleReloadSound()

    if not ReloadSounds.cooldown then
        if IsPedReloading(Gamemode.utils.GetPed()) then
            if GetEntityModel(Gamemode.utils.GetPed()) == GetHashKey("mp_m_freemode_01") then
                PlayCustomSound("gameplay/player_reloading/male/reload_".. math.random(1,7) ..".ogg", Settings.reloadSoundVolume)
            else
                PlayCustomSound("gameplay/player_reloading/female/reload_".. math.random(1,2) ..".ogg", Settings.reloadSoundVolume)
            end
            ReloadSounds.cooldown = true
            Citizen.CreateThread(function()
                while IsPedReloading(Gamemode.utils.GetPed()) do
                    Wait(1000)
                end
                ReloadSounds.cooldown = false
            end)
        end
    end

    
end
