function Lobby.PushDeath()
    local gm = string.upper(tostring(Matchmaking.data.gamemode or ""):gsub("~%a~", ""))
    local noChange = (gm == "GUN GAME" or gm == "ONE IN THE CHAMBER")
    local di = Gamemode.deathInfo or {}

    local function weaponSprite(hash)
        local cfg = hash and SharedConfig.weaponsSpriteByHash[hash]
        if not (cfg and cfg.weapon) then return "", "" end
        local _, lbl, img = MenuUI.WeaponMeta(cfg.weapon)
        return img, lbl
    end

    local wImage, wLabel = weaponSprite(di.weaponHash)

    local damage = {}
    for _, row in ipairs(DamageLog.Build()) do
        local img = weaponSprite(row.weaponHash)
        damage[#damage + 1] = {
            name = row.name,
            damage = row.damage,
            hits = row.hits,
            headshot = row.headshot,
            final = row.final,
            weaponImage = img,
        }
    end

    local rank = ""
    if di.killerLevel then rank = MenuUI.RankIcon(di.killerLevel, di.killerPrestige) end

    exports['warv-ui']:SetDeath({
        killer = di.killer or "",
        respawnMs = di.respawnMs or 3000,
        canChangeClass = not noChange,
        weaponImage = wImage,
        weaponName = wLabel,
        distance = tonumber(di.distance) or 0,
        headshot = di.headshot == true,
        rankIcon = rank,
        level = tonumber(di.killerLevel) or 0,
        prestige = tonumber(di.killerPrestige) or 0,
        spectating = tostring(Spectate.target or ""),
        specSeq = Spectate.seq,
        damage = damage,
    })
end
