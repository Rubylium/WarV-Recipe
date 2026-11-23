DeathSound = {}
function DeathSound.HandleDeathSound()
    if GetEntityModel(Gamemode.utils.GetPed()) == GetHashKey("mp_m_freemode_01") then
        PlayCustomSound("gameplay/player_death/male/death_".. math.random(1,11) ..".ogg", Settings.deathSoundVolume)
    else
        PlayCustomSound("gameplay/player_death/female/death_".. math.random(1,13) ..".ogg", Settings.deathSoundVolume)
    end
end
