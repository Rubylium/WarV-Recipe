SharedConfig = {
    version = "0.1.5b",
    devmod = false,
    expForLevel = 400,
    healthGate = 200,
    allowConnexion = true,
    Tips = {
        "Once in game, you can use \"TAB\" to display the scoreboard.",
        "In the scoreboard, you can click on players and mute them if they talk too much",
        "The keys (1/2/3) are used to change weapons!",
        "The keys (F1 / F2 / F3) are used to launch your scorestreaks",
    },
    PreMadeClass = {
        {
            name = "Rifleman",
            weapons = {
                primary = {
                    weapon = "weapon_carbinerifle",
                    comps = {
                        clip = "COMPONENT_CARBINERIFLE_CLIP_02",
                        scope = "COMPONENT_AT_SCOPE_MEDIUM",
                        grip = "COMPONENT_AT_AR_AFGRIP",
                        bore = "WARV_BORE_MATCH",
                        trigger = "WARV_TRIGGER_MATCH",
                    }
                },
                secondary = {
                    weapon = "weapon_combatpistol",
                    comps = {
                        clip = "COMPONENT_COMBATPISTOL_CLIP_02",
                    }
                },
                extra = {
                    weapon = "weapon_grenade",
                    ammo = 1
                }
            }
        },
        {
            name = "Heavy gunner",
            weapons = {
                primary = {
                    weapon = "weapon_mg",
                    comps = {
                        clip = "COMPONENT_MG_CLIP_02",
                        scope = "COMPONENT_AT_SCOPE_SMALL_02",
                        bore = "WARV_BORE_HEAVY",
                        buffer = "WARV_BUFFER_HEAVY",
                        weight = "WARV_WEIGHT_BALLAST",
                    }
                },
                secondary = {
                    weapon = "weapon_combatpistol",
                    comps = {
                        muzzle = "COMPONENT_AT_PI_SUPP",
                    }
                },
                extra = {
                    weapon = "weapon_stickybomb",
                    ammo = 1
                }
            }
        },
        {
            name = "Shotgunner",
            weapons = {
                primary = {
                    weapon = "weapon_pumpshotgun",
                    comps = {
                        clip = "WARV_AMMO_OVER",
                        muzzle = "COMPONENT_AT_SR_SUPP",
                        bore = "WARV_BORE_CHROME",
                        weight = "WARV_WEIGHT_POLYMER",
                        finish = "COMPONENT_PUMPSHOTGUN_VARMOD_SECURITY",
                    }
                },
                secondary = {
                    weapon = "weapon_pistol50",
                    comps = {
                        clip = "COMPONENT_PISTOL50_CLIP_02",
                    }
                },
                extra = {
                    weapon = "weapon_pipebomb",
                    ammo = 1
                }
            }
        },
        {
            name = "Runner",
            weapons = {
                primary = {
                    weapon = "weapon_smg",
                    comps = {
                        clip = "COMPONENT_SMG_CLIP_02",
                        scope = "COMPONENT_AT_SCOPE_MACRO_02",
                        muzzle = "COMPONENT_AT_PI_SUPP",
                        buffer = "WARV_BUFFER_LIGHT",
                        weight = "WARV_WEIGHT_SKELETON",
                    }
                },
                secondary = {
                    weapon = "weapon_combatpistol",
                    comps = {
                        clip = "COMPONENT_COMBATPISTOL_CLIP_02",
                        muzzle = "COMPONENT_AT_PI_SUPP",
                    }
                },
                extra = {
                    weapon = "weapon_pipebomb",
                    ammo = 1
                }
            }
        },
        {
            name = "Sniper",
            weapons = {
                primary = {
                    weapon = "weapon_sniperrifle",
                    comps = {
                        scope = "COMPONENT_AT_SCOPE_MAX",
                        muzzle = "COMPONENT_AT_AR_SUPP_02",
                        bore = "WARV_BORE_MATCH",
                        trigger = "WARV_TRIGGER_TWO_STAGE",
                        weight = "WARV_WEIGHT_TUNGSTEN",
                        finish = "COMPONENT_SNIPERRIFLE_VARMOD_LUXE",
                    }
                },
                secondary = {
                    weapon = "weapon_combatpistol",
                    comps = {
                        muzzle = "COMPONENT_AT_PI_SUPP",
                    }
                },
                extra = {
                    weapon = "weapon_proxmine",
                    ammo = 1
                }
            }
        }
    },
    Gamemode = {
        {
            label = "SEARCH AND DESTROY",
            name = "SEARCH AND DESTROY",
            sprite = "team_deathmatch",
            description = "Attackers plant the bomb on one of two sites, defenders hold. One life per round.",
            maxPlayers = 10,
            ranked = true,
            type = "normal",
        },
        {
            label = "Team Deathmatch",
            name = "TEAM DEATHMATCH",
            sprite = "team_deathmatch",
            description = "First team to 75 kills wins.",
            maxPlayers = 10,
            ranked = false,
            type = "normal",
        },
        {
            label = "TEAM DEATHMATCH ~r~HARDCORE",
            name = "TEAM DEATHMATCH HARDCORE",
            sprite = "team_deathmatch",
            description = "Reduced health, one-shot headshots, minimal HUD.",
            maxPlayers = 10,
            ranked = false,
            type = "hardcore",
        },
        {
            label = "TRON DEATHMATCH ~y~EVENT",
            name = "TRON DEATHMATCH",
            sprite = "team_deathmatch",
            description = "Team deathmatch, with lasers. Limited-time event.",
            maxPlayers = 12,
            ranked = false,
            type = "normal",
        },
       {
          label = "FREE FOR ALL",
          name = "FFA",
            sprite = "free_for_all",
          description = "Every man for himself, no alliance possible.",
          maxPlayers = 10,
          ranked = false,
          type = "normal",
       },
       {
          label = "GUN GAME",
          name = "GUN GAME",
          sprite = "free_for_all",
          description = "Every kill swaps your weapon. First to finish the ladder with the knife wins.",
          maxPlayers = 10,
          ranked = false,
          type = "normal",
       },
       {
          label = "KILL CONFIRMED",
          name = "KILL CONFIRMED",
          sprite = "kill_confirmed_yellow_tag",
          description = "Kill and collect the enemy dogtag to score. Grab your team's tags to deny.",
          maxPlayers = 10,
          ranked = false,
          type = "normal",
       },
       {
          label = "VIP",
          name = "VIP",
          sprite = "team_deathmatch",
          description = "Kill the enemy VIP to score. Stay alive if you are the VIP.",
          maxPlayers = 10,
          ranked = false,
          type = "normal",
       },
        {
           label = "DOMINATION",
           name = "DOMINATION",
           sprite = "team_deathmatch",
           description = "Hold 3 zones to score. First team to 200 wins.",
           maxPlayers = 10,
           ranked = false,
           type = "normal",
        },
        {
           label = "ONE IN THE CHAMBER",
           name = "ONE IN THE CHAMBER",
           sprite = "free_for_all",
           description = "One pistol, one bullet, three lives. Every shot kills. Miss and it's knife only until your next kill.",
           maxPlayers = 12,
           ranked = false,
           type = "party",
        },
    },

    MatchmakingCamPos = vector3(356.43505859375, 4830.8344726562, -58.799500274658),
    MatchmakingScenarioList = {
        {"WORLD_HUMAN_GUARD_PATROL"},
        {"WORLD_HUMAN_GUARD_STAND"},
        {"WORLD_HUMAN_GUARD_STAND_CASINO"},
        {"WORLD_HUMAN_GUARD_STAND_CLUBHOUSE"},
        {"WORLD_HUMAN_GUARD_STAND_ARMY"},
        {"WORLD_HUMAN_STAND_IMPATIENT"},
        {"WORLD_HUMAN_HANG_OUT_STREET"},
    },
    MatchmakingPositions = {
        {pos = vector4(347.55279541016, 4834.6831054688, -58.999450683594, 244.62455749512)},
        {pos = vector4(345.90542602539, 4834.099609375, -58.999450683594, 241.74426269531)},
        {pos = vector4(346.84194946289, 4836.5146484375, -58.999450683594, 247.27293395996)},
        {pos = vector4(346.14788818359, 4838.2172851562, -58.999450683594, 245.79978942871)},
        {pos = vector4(343.70846557617, 4833.26953125, -58.999450683594, 244.0553894043)},
        {pos = vector4(340.90673828125, 4832.865234375, -58.999450683594, 244.93438720703)},
        {pos = vector4(345.17010498047, 4841.068359375, -58.999450683594, 240.33282470703)},
        {pos = vector4(344.83877563477, 4836.3842773438, -58.999450683594, 242.8444519043)},
        {pos = vector4(343.77423095703, 4834.8408203125, -58.999450683594, 243.57043457031)},
        {pos = vector4(343.53784179688, 4838.30859375, -58.999450683594, 244.2225189209)},
        {pos = vector4(342.56866455078, 4836.3627929688, -58.999450683594, 246.86431884766)},
        {pos = vector4(341.49658203125, 4834.4814453125, -58.999450683594, 248.21743774414)},
        {pos = vector4(340.63961791992, 4835.8305664062, -58.999450683594, 246.77478027344)},
        {pos = vector4(341.54528808594, 4837.98828125, -58.999450683594, 242.98196411133)},
        {pos = vector4(342.84042358398, 4840.5205078125, -58.999450683594, 244.05554199219)},
        {pos = vector4(337.74368286133, 4835.3403320312, -58.999450683594, 248.84173583984)},
        {pos = vector4(338.70483398438, 4837.8369140625, -58.999450683594, 242.94186401367)},
        {pos = vector4(339.80407714844, 4840.3754882812, -58.999450683594, 244.38737487793)},
        {pos = vector4(340.95358276367, 4842.7314453125, -58.999450683594, 243.15249633789)},
        {pos = vector4(342.79745483398, 4842.974609375, -58.999450683594, 244.97563171387)},
        {pos = vector4(340.0432434082, 4845.1362304688, -58.999458312988, 238.7474822998)},
        {pos = vector4(338.38757324219, 4842.5219726562, -58.999458312988, 242.24002075195)},
        {pos = vector4(336.85604858398, 4840.1064453125, -58.999458312988, 242.89025878906)},
        {pos = vector4(335.58145141602, 4837.5991210938, -58.999458312988, 243.61430358887)},
    }

}
