local uiSounds = {
    hover        = { "ui/navigation/hover.wav", 0.09 },
    hover_subtle = { "ui/navigation/subtle_hover.wav", 0.09 },
    loadout_hover= { "ui/navigation/loadout_hover.wav", 0.11 },
    select       = { "ui/navigation/select.wav", 0.12 },
    back         = { "ui/navigation/back.wav", 0.13 },
    ["return"]   = { "ui/navigation/return.wav", 0.13 },
    tab          = { "ui/navigation/tab.wav", 0.12 },
    error        = { "ui/navigation/error.wav", 0.15 },
    deny         = { "ui/navigation/denied.wav", 0.15 },
    adjust       = { "ui/navigation/adjust.wav", 0.08 },
    adjust_alt   = { "ui/navigation/alternate_adjust.wav", 0.10 },
    screen_adjust= { "ui/navigation/screen_adjust.wav", 0.11 },
    expand       = { "ui/navigation/expand.wav", 0.12 },
    collapse     = { "ui/navigation/collapse.wav", 0.12 },
    popup        = { "ui/navigation/popup.wav", 0.13 },
    type_blip    = { "ui/text_blip.ogg", 0.02 },
    popup_general= { "ui/navigation/notification_open.wav", 0.13 },
    progression  = { "ui/navigation/progression_popup.wav", 0.15 },
    gunsmith_menu       = { "gunsmith/menu_opened.wav", 0.05 },
    gunsmith_scope      = { "gunsmith/optic_selected.wav", 0.05 },
    gunsmith_muzzle     = { "gunsmith/muzzle_selected.wav", 0.05 },
    gunsmith_barrel     = { "gunsmith/stock_selected.wav", 0.05 },
    gunsmith_grip       = { "gunsmith/underbarrel_selected.wav", 0.05 },
    gunsmith_clip       = { "gunsmith/magazine_selected.wav", 0.05 },
    gunsmith_flashlight = { "gunsmith/laser_selected.wav", 0.05 },
    gunsmith_rail       = { "gunsmith/laser_selected.wav", 0.05 },
    gunsmith_bore       = { "gunsmith/muzzle_selected.wav", 0.05 },
    gunsmith_trigger    = { "gunsmith/receiver_selected.wav", 0.05 },
    gunsmith_buffer     = { "gunsmith/receiver_selected.wav", 0.05 },
    gunsmith_weight     = { "gunsmith/stock_selected.wav", 0.05 },
    gunsmith_finish     = { "gunsmith/receiver_selected.wav", 0.05 },
    gunsmith_tint       = { "gunsmith/receiver_selected.wav", 0.05 },
    gunsmith_camo       = { "gunsmith/stock_selected.wav", 0.05 },
}
AddEventHandler("warv-ui:playSound", function(name)
    if name == "notify_weapon_level" then
        PlayCustomSound("ui/unlock/weapon_level_up.wav", Settings.rankupVolume)
        return
    elseif name == "notify_medal" then
        PlayCustomSound("ui/lower_place.ogg", Settings.effectsSoundVolume)
        return
    elseif name == "notify_rank_up" then
        PlayCustomSound("ui/rank_up/" .. (Settings.RankupSound or "black_ops_2") .. ".ogg",
            Settings.rankupVolume)
        return
    elseif name == "notify_killstreak_1" or name == "notify_killstreak_2" or name == "notify_killstreak_3" then
        local tier = name:match("(%d)$") or "1"
        PlayCustomSound("ui/killstreak_ready/tier_" .. tier .. ".wav",
            Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.12, 0.05))
        return
    end
    local s = uiSounds[name]
    if s then
        PlayCustomSound(s[1],
            Settings.GetScaledVolume(Settings.interfaceSoundVolume, s[2] or 0.1, 0.05))
    end
end)
