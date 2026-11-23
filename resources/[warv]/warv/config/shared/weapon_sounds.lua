SharedConfig.WeaponsSoundType = {
    ["lmg"] = {
        path = "weapons/distant/light_machine_gun/",
        variation = "3",
        sound = "lmg_"
    },
    ["rif"] = {
        path = "weapons/distant/sniper_rifle/",
        variation = "2",
        sound = "sniper_"
    },
    ["shotgun"] = {
        path = "weapons/distant/shotgun/",
        variation = "2",
        sound = "shotgun_"
    },
    ["pistol"] = {
        path = "weapons/distant/pistol/",
        variation = "3",
        sound = "pistol_"
    }
}

SharedConfig.WeaponsSound = {
    [GetHashKey("weapon_sniperrifle")] = {type = "rif", closeSound = ""},
    [GetHashKey("weapon_heavysniper")] = {type = "rif", closeSound = "dsr_fire_close"},
    [GetHashKey("weapon_heavysniper_mk2")] = {type = "rif", closeSound = "dsr_fire_close"},
    [GetHashKey("weapon_marksmanrifle")] = {type = "rif", closeSound = ""},

    [GetHashKey("weapon_pumpshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_pumpshotgun_mk2")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_sawnoffshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_assaultshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_bullpupshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_musket")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_heavyshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_dbshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("weapon_autoshotgun")] = {type = "shotgun", closeSound = ""},
    [GetHashKey("WEAPON_COMBATSHOTGUN")] = {type = "shotgun", closeSound = ""},

    [GetHashKey("weapon_pistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_pistol_mk2")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_combatpistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_appistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_pistol50")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_snspistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_snspistol_mk2")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_heavypistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_vintagepistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_marksmanpistol")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_revolver")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_revolver_mk2")] = {type = "pistol", closeSound = ""},
    [GetHashKey("weapon_doubleaction")] = {type = "pistol", closeSound = ""}
}
