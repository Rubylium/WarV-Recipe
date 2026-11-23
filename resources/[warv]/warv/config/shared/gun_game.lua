GunGame = {
    ladder = {
        "weapon_pistol",
        "weapon_snspistol",
        "weapon_ceramicpistol",
        "weapon_combatpistol",
        "weapon_appistol",
        "weapon_pistol50",
        "weapon_revolver",
        "weapon_revolver_mk2",
        "weapon_microsmg",
        "weapon_minismg",
        "weapon_machinepistol",
        "weapon_smg",
        "weapon_assaultsmg",
        "weapon_combatpdw",
        "weapon_gusenberg",
        "weapon_sawnoffshotgun",
        "weapon_dbshotgun",
        "weapon_pumpshotgun",
        "weapon_bullpupshotgun",
        "weapon_heavyshotgun",
        "weapon_compactrifle",
        "weapon_assaultrifle",
        "weapon_carbinerifle",
        "weapon_specialcarbine",
        "weapon_bullpuprifle",
        "weapon_mg",
        "weapon_combatmg",
        "weapon_marksmanrifle",
        "weapon_musket",
        "weapon_knife",
    },
}

function GunGame.TierFromKills(kills)
    local tier = (tonumber(kills) or 0) + 1
    if tier < 1 then return 1 end
    if tier > #GunGame.ladder then return #GunGame.ladder end
    return tier
end

function GunGame.WeaponForKills(kills)
    return GunGame.ladder[GunGame.TierFromKills(kills)]
end
