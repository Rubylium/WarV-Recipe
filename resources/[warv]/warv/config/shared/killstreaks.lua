SharedConfig.Killstreaks = {
    ["UAV"] = {
        label = "UAV",
        kill = 1000,
        cooldown = 60,
        desc = "Shows enemies on the mini-map",
        sprite = "uav",
        sync = true,
        action = function(players, myTeam, sync)
            Gamemode.StartUav(players, myTeam, sync)
        end
    },
    ["SATELITTE"] = {
        label = "Satelitte",
        kill = 3775,
        cooldown = 60,
        desc = "Shows both enemy position and direction on the mini-map. \nCannot be shot down",
        sprite = "satellite",
        sync = true,
        action = function(myTeam, players)
            Gamemode.StartSatelitte(myTeam, players)
        end
    },
    ["AIRSTRIKE"] = {
        label = "Lightning Strike",
        kill = 2875,
        cooldown = 30,
        desc = "Launch a coordinated and rapid airstrike \non three locations",
        sprite = "airstrike",
        sync = false,
        action = function(myTeam, players)
            Gamemode.StartAirStrike(myTeam, players)
        end
    },
    ["MINIGUN"] = {
        label = "Death Machine",
        kill = 2475,
        cooldown = 20,
        desc = "A handheld Minigun. Does not go away until all \nof its 255 ammo has been exhausted",
        sprite = "minigun",
        sync = false,
        action = function(players, myTeam)
            Gamemode.StartMinigun(myTeam, players)
        end
    },
    ["RCXD"] = {
        label = "RC-XD",
        kill = 2125,
        cooldown = 20,
        desc = "Remote control car filled with explosives!",
        sprite = "rcxd",
        sync = false,
        action = function(players, myTeam)
            Gamemode.StartRcXd(myTeam, players)
        end
    },
    ["NUKE"] = {
        label = "NUKE",
        kill = 7950,
        cooldown = 60,
        desc = "Launch a tactical nuke, kill all enemies.",
        sprite = "nuke",
        sync = true,
        syncForOtherTeam = true,
        action = function(players, myTeam, sync)
            Gamemode.StartNuke(players, myTeam, sync)
        end,
    },
    ["COMBAT_HELI"] = {
        label = "COMBAT HELI",
        kill = 6700,
        cooldown = 120,
        desc = "Deploys a piloted combat helicopter mounted \nwith a high-powered cannon for 45s.",
        sprite = "combat_helicopter",
        sync = false,
        action = function(players, myTeam)
            Gamemode.StartCombatHeli(myTeam, players)
        end
    },
    ["WARTOG"] = {
        label = "WARTOG",
        kill = 5600,
        cooldown = 60,
        desc = "Calls for a fighter plane that can destroy \nthe opposing team. The plane will stay for 30s",
        sprite = "warthog",
        sync = false,
        action = function(players, myTeam)
            Gamemode.StartWartog(myTeam, players)
        end
    },
    ["CRUISE"] = {
        label = "CRUISE MISSILE",
        kill = 3025,
        cooldown = 20,
        desc = "Call a controllable missile to make a \nprecise strike on the enemy",
        sprite = "cruise_missile",
        sync = false,
        action = function(players, myTeam)
            Gamemode.StartCruiseMissil(myTeam, players)
        end
    },
    ["SUICIDE_DRONE"] = {
        label = "Suicide Drone",
        kill = 1800,
        cooldown = 30,
        desc = "Launch a drone that circles the map, \nthen dives on the first enemy it spots",
        sprite = "suicide_drone",
        sync = false,
        action = function(myTeam, players, sync)
            Gamemode.StartSuicideDrone(sync == true)
        end
    },
}

SharedConfig.KillstreakProgress = {
    killMultiplier = 0.1,
    damageWeapons = {
        WEAPON_MINIGUN = true,
    },
}

function SharedConfig.IsKillstreakKillSource(weapon)
    if weapon == nil or type(weapon) == "table" then return false end

    if type(weapon) == "string" and SharedConfig.Killstreaks[weapon:upper()] ~= nil then
        return true
    end

    local weaponName = WeaponRegistry.NormalizeName(weapon)
    return weaponName ~= nil and SharedConfig.KillstreakProgress.damageWeapons[weaponName] == true
end
