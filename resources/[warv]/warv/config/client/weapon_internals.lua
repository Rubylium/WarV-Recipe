local allCategories = {
    GROUP_RIFLE = true,
    GROUP_SMG = true,
    GROUP_SHOTGUN = true,
    GROUP_MG = true,
    GROUP_SNIPER = true,
    GROUP_PISTOL = true,
}

WeaponInternalsConfig = {
    limit = 6,

    slots = {
        {
            key = "clip",
            skipWhen = { "_CLIP_FMJ", "_CLIP_ARMORPIERCING", "_CLIP_HOLLOWPOINT", "_CLIP_INCENDIARY", "_CLIP_TRACER" },
            categories = allCategories,
            items = {
                { model = "WARV_AMMO_FMJ", label = "Full Metal Jacket", damage = 0.02, recoil = 0.02 },
                { model = "WARV_AMMO_HOLLOW", label = "Hollow Point", damage = 0.03, spread = 0.03 },
                { model = "WARV_AMMO_SUBSONIC", label = "Subsonic", damage = -0.02, recoil = -0.05 },
                { model = "WARV_AMMO_OVER", label = "Overpressured", damage = 0.03, recoil = 0.07, mobility = -0.02 },
                { model = "WARV_AMMO_MATCH", label = "Match Grade", spread = -0.07, recoil = -0.02, mobility = -0.01 },
                { model = "WARV_AMMO_LIGHT", label = "Light Rounds", damage = -0.02, spread = 0.02, mobility = 0.05 },
            },
        },
        {
            key = "bore",
            label = "Bore",
            categories = {
                GROUP_RIFLE = true,
                GROUP_SHOTGUN = true,
                GROUP_MG = true,
                GROUP_SNIPER = true,
            },
            items = {
                { model = "WARV_BORE_CHROME", label = "Chrome Lining", damage = 0.02, mobility = -0.02 },
                { model = "WARV_BORE_HEAVY", label = "Heavy Profile", recoil = -0.07, spread = -0.02, mobility = -0.06 },
                { model = "WARV_BORE_FLUTED", label = "Fluted Bore", recoil = 0.03, mobility = 0.06 },
                { model = "WARV_BORE_MATCH", label = "Match Bore", damage = 0.01, spread = -0.05, mobility = -0.02 },
            },
        },
        {
            key = "trigger",
            label = "Trigger",
            categories = {
                GROUP_RIFLE = true,
                GROUP_MG = true,
                GROUP_SNIPER = true,
                GROUP_PISTOL = true,
            },
            items = {
                { model = "WARV_TRIGGER_MATCH", label = "Match Trigger", spread = -0.06, recoil = -0.02 },
                { model = "WARV_TRIGGER_HAIR", label = "Hair Trigger", spread = 0.03, mobility = 0.04 },
                { model = "WARV_TRIGGER_TWO_STAGE", label = "Two-Stage Trigger", spread = -0.08, mobility = -0.03 },
                { model = "WARV_TRIGGER_SEAR", label = "Polished Sear", recoil = -0.04, spread = 0.02 },
            },
        },
        {
            key = "buffer",
            label = "Buffer",
            categories = {
                GROUP_RIFLE = true,
                GROUP_SMG = true,
                GROUP_SHOTGUN = true,
                GROUP_MG = true,
                GROUP_PISTOL = true,
            },
            items = {
                { model = "WARV_BUFFER_HYDRAULIC", label = "Hydraulic Buffer", recoil = -0.08, spread = 0.02 },
                { model = "WARV_BUFFER_SPRING", label = "Competition Spring", damage = -0.01, recoil = -0.05, spread = -0.03 },
                { model = "WARV_BUFFER_HEAVY", label = "Heavy Carrier", recoil = -0.10, mobility = -0.05 },
                { model = "WARV_BUFFER_LIGHT", label = "Light Carrier", recoil = 0.04, mobility = 0.06 },
            },
        },
        {
            key = "weight",
            label = "Weight",
            categories = allCategories,
            items = {
                { model = "WARV_WEIGHT_POLYMER", label = "Polymer Furniture", recoil = 0.05, mobility = 0.07 },
                { model = "WARV_WEIGHT_SKELETON", label = "Skeletonised Frame", recoil = 0.08, spread = 0.03, mobility = 0.10 },
                { model = "WARV_WEIGHT_TUNGSTEN", label = "Tungsten Insert", recoil = -0.06, mobility = -0.04 },
                { model = "WARV_WEIGHT_BALLAST", label = "Weighted Chassis", recoil = -0.09, spread = -0.03, mobility = -0.07 },
            },
        },
    },
}
