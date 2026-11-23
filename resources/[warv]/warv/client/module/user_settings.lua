local defaultLobbyTheme = "lobby_music/warv_AdrenalineProtocol.mp3"

Settings = {}
Settings.reloadSoundVolume = 0.04
Settings.killSoundVolume = 0.05
Settings.customWeaponSoundVolume = 0.02
Settings.hitMarkerVolume = 0.05
Settings.rankupVolume = 0.06
Settings.deathSoundVolume = 0.04
Settings.interfaceSoundVolume = 0.05
Settings.effectsSoundVolume = 0.05
Settings.RankupSound = "black_ops_2"
Settings.selectedPlayerSkin = 0
Settings.LobbyTheme = defaultLobbyTheme
Settings.MusicsVolume = 0.02

local legacyRankupSounds = {
    bo2 = "black_ops_2",
    cod4 = "call_of_duty_4",
    codaw = "advanced_warfare",
    cod_infinite = "infinite_warfare",
    ["mw2-3"] = "modern_warfare_2_3",
    ["mw2-challege"] = "modern_warfare_2_challenge",
}

function Settings.SaveAllSettings()
    local db = rockdb:new()
    db:SaveFloat("SOUND_RELOAD_VOLUME_NEW", Settings.reloadSoundVolume)
    db:SaveFloat("SOUND_KILL_VOLUME_NEW", Settings.killSoundVolume)
    db:SaveFloat("SOUND_CUSTOM_WEAPON_VOLUME_NEW", Settings.customWeaponSoundVolume)
    db:SaveFloat("SOUND_HIT_MARKER_VOLUME_NEW", Settings.hitMarkerVolume)
    db:SaveFloat("SOUND_RANKUP_VOLUME_NEW", Settings.rankupVolume)
    db:SaveFloat("SOUND_DEATH_VOLUME", Settings.deathSoundVolume)
    db:SaveFloat("SOUND_INTERFACE_VOLUME", Settings.interfaceSoundVolume)
    db:SaveFloat("SOUND_EFFECTS_VOLUME", Settings.effectsSoundVolume)
    db:SaveInt("AUDIO_SETTINGS_ZERO_SAFE_V1", 1)
    db:SaveInt("AUDIO_CATEGORIES_V1", 1)
    db:SaveString("SOUND_RANKUP_SOUND_NEW", Settings.RankupSound)
    db:SaveInt("SELECTED_PLAYER_SKIN_NEW", Settings.selectedPlayerSkin)
    db:SaveString("LOBBY_THEME_REVISITED", Settings.LobbyTheme)
    db:SaveFloat("MUSIC_VOLUME_NEW", Settings.MusicsVolume)
end

function Settings.LoadAllSettings()
    local db = rockdb:new()

    local reloadSound = db:GetFloat("SOUND_RELOAD_VOLUME_NEW")
    local killSound = db:GetFloat("SOUND_KILL_VOLUME_NEW")
    local customWeaponSound = db:GetFloat("SOUND_CUSTOM_WEAPON_VOLUME_NEW")
    local hitMarker = db:GetFloat("SOUND_HIT_MARKER_VOLUME_NEW")
    local rankup = db:GetFloat("SOUND_RANKUP_VOLUME_NEW")
    local deathSound = db:GetFloat("SOUND_DEATH_VOLUME")
    local interfaceSound = db:GetFloat("SOUND_INTERFACE_VOLUME")
    local effectsSound = db:GetFloat("SOUND_EFFECTS_VOLUME")
    local zeroSafe = db:GetInt("AUDIO_SETTINGS_ZERO_SAFE_V1") == 1
    local categoriesInitialized = db:GetInt("AUDIO_CATEGORIES_V1") == 1
    local rankupSound = db:GetString("SOUND_RANKUP_SOUND_NEW")
    local selectedPlayerSkin = db:GetInt("SELECTED_PLAYER_SKIN_NEW")
    local musicsVolume = db:GetFloat("MUSIC_VOLUME_NEW")

    if reloadSound == 0.0 and not zeroSafe then
        Settings.reloadSoundVolume = 0.04
    else
        Settings.reloadSoundVolume = reloadSound
    end

    if killSound == 0.0 and not zeroSafe then
        Settings.killSoundVolume = 0.05
    else
        Settings.killSoundVolume = killSound
    end

    if customWeaponSound == 0.0 and not zeroSafe then
        Settings.customWeaponSoundVolume = 0.02
    else
        Settings.customWeaponSoundVolume = customWeaponSound
    end

    if hitMarker == 0.0 and not zeroSafe then
        Settings.hitMarkerVolume = 0.05
    else
        Settings.hitMarkerVolume = hitMarker
    end

    if rankup == 0.0 and not zeroSafe then
        Settings.rankupVolume = 0.06
    else
        Settings.rankupVolume = rankup
    end

    if categoriesInitialized then
        Settings.deathSoundVolume = deathSound
        Settings.interfaceSoundVolume = interfaceSound
        Settings.effectsSoundVolume = effectsSound
    else
        Settings.deathSoundVolume = 0.04
        Settings.interfaceSoundVolume = 0.05
        Settings.effectsSoundVolume = 0.05
    end

    if rankupSound == nil then
        Settings.RankupSound = "black_ops_2"
    else
        Settings.RankupSound = legacyRankupSounds[rankupSound] or rankupSound
    end

    if selectedPlayerSkin == 0 then
        Settings.selectedPlayerSkin = 0
    else
        Settings.selectedPlayerSkin = selectedPlayerSkin
    end

    Settings.LobbyTheme = defaultLobbyTheme

    if musicsVolume == 0.0 and not zeroSafe then
        Settings.MusicsVolume = 0.02
    else
        Settings.MusicsVolume = musicsVolume
    end
end
Settings.LoadAllSettings()

function Settings.GetScaledVolume(settingVolume, authoredVolume, referenceVolume)
    return math.max(0.0, math.min(1.0, authoredVolume * (settingVolume / referenceVolume)))
end

function Settings.SetReladSoundVolume(volume)
    Settings.reloadSoundVolume = volume
end

function Settings.SetKillSoundVolume(volume)
    Settings.killSoundVolume = volume
end

function Settings.SetCustomWeaponSoundVolume(volume)
    Settings.customWeaponSoundVolume = volume
end

function Settings.SetHitMarkerVolume(volume)
    Settings.hitMarkerVolume = volume
end

function Settings.SetRankupVolume(volume)
    Settings.rankupVolume = volume
end

function Settings.SetDeathSoundVolume(volume)
    Settings.deathSoundVolume = volume
end

function Settings.SetInterfaceSoundVolume(volume)
    Settings.interfaceSoundVolume = volume
end

function Settings.SetEffectsSoundVolume(volume)
    Settings.effectsSoundVolume = volume
end

function Settings.SetPlayerSkin(skin)
    Settings.selectedPlayerSkin = skin
end

function Settings.SetLobbyTheme()
    Settings.LobbyTheme = defaultLobbyTheme
end

function Settings.SetMusicVolume(volume)
    Settings.MusicsVolume = volume
end

