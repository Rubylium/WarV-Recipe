Killfeed = {}
Killfeed.myStreak = 0


local function weaponSlug(model)
    if model == nil or model == "" or model == "suicide" then return "" end
    local data = SharedConfig.weaponsSpriteByHash[GetHashKey(model)]
    if data then return MenuUI.Slug(data.image or data.sprite) end
    return ""
end

local function killstreakSprite(value)
    local data = SharedConfig.Killstreaks[tostring(value or ""):upper()]
    if data then return data.sprite end
    return ""
end

function Killfeed.ResetStreak()
    Killfeed.myStreak = 0
end

function Killfeed.Send(killerName, killerId, killerTeam, killedName, killedTeam, headshot, weaponImage)
    local mine = killerId ~= nil and killerId == Gamemode.utils.GetSID()
    local suicide = (weaponImage == "suicide") or (killerName ~= nil and killerName == killedName)

    local slug = (not suicide) and weaponSlug(weaponImage) or ""
    local special = ""
    if not suicide and slug == "" then special = killstreakSprite(weaponImage) end

    if mine then
        if suicide then Killfeed.myStreak = 0 else Killfeed.myStreak = Killfeed.myStreak + 1 end
    end

    local killerFriendly, victimFriendly
    if Gamemode.NoTeams then
        killerFriendly = mine
        victimFriendly = false
    else
        killerFriendly = (killerTeam == Gamemode.Team)
        victimFriendly = (killedTeam == Gamemode.Team)
    end

    exports['warv-ui']:HudKill({
        killer = tostring(killerName or ""),
        victim = tostring(killedName or ""),
        weapon = slug,
        headshot = headshot == true,
        suicide = suicide,
        special = special,
        killerFriendly = killerFriendly,
        victimFriendly = victimFriendly,
        mine = mine,
        streak = (mine and Killfeed.myStreak) or 0,
    })
end
