function MenuUI.BlockNonLeader(action)
    if #Menu.squad.members == 0 or Menu.squad.isLeader then
        return false
    end

    exports['warv-ui']:Notify("notice", {
        title = "SQUAD LEADER REQUIRED",
        message = "Leader only: " .. action,
    })
    return true
end

function MenuUI.CallingCardSprite(id)
    local _, sprite = GetEmblemForId(tonumber(id) or 1)
    return sprite or ""
end

function MenuUI.EmblemSprite(id)
    local e = SharedConfig.emblems[tonumber(id) or 1]
    return e and (e.image or e.sprite) or ""
end

function MenuUI.Player()
    local pd = Lobby.playerData
    local level = tonumber(pd.level) or 1
    local prestige = tonumber(pd.prestige) or 0
    local totalXp = tonumber(pd.xp) or 0

    local into, span = StatsFormat.LevelProgress(totalXp, level, GetCorrectExpForLevel)

    local rankIcon = GetRankIcon(level, prestige) or "rank_1"

    return {
        name = tostring(pd.name or "OPERATOR"),
        uid = tonumber(pd.uid) or 0,
        level = level,
        prestige = prestige,
        xp = into,
        xpMax = span,
        credit = tonumber(pd.credit) or 0,
        rankIcon = rankIcon,
        callingCard = MenuUI.CallingCardSprite(pd.emblemsId),
        emblem = MenuUI.EmblemSprite(Data.playerIcon),
    }
end

function MenuUI.Ratio(a, b)
    a = tonumber(a) or 0
    b = tonumber(b) or 0
    if b <= 0 then b = 1 end
    return string.format("%.2f", a / b)
end

local function gamemodeOf(name)
    for _, gm in ipairs(SharedConfig.Gamemode) do
        if gm.name == name then return gm end
    end
end

function MenuUI.GamemodeSprite(name)
    local gm = gamemodeOf(name)
    return gm and gm.sprite or ""
end

function MenuUI.GamemodeRanked(name)
    local gm = gamemodeOf(name)
    return gm ~= nil and gm.ranked == true
end

function MenuUI.Slug(s)
    return (tostring(s or ""):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

function MenuUI.WeaponMeta(model)
    local hash = GetHashKey(model)
    local entry = SharedConfig.weaponsSpriteByHash[hash]
    local sprite = entry and (entry.image or entry.sprite) or ""
    local label = model
    local l = GetGxtForWeapon(model)
    if l and l ~= "" then label = l end
    if label == model or label == "Unknown" or label == "" then
        local wd = WeaponsData.byName[tostring(model):upper()]
        if wd and wd.label then label = wd.label end
    end
    return hash, label, MenuUI.Slug(sprite)
end

function MenuUI.WeaponProgress(model)
    local stats = Lobby.playerData.weaponsStats or {}
    local ws = WeaponRegistry.GetStats(stats, model) or {}
    return WeaponProgression.Progress(tonumber(ws.xp) or 0)
end

local cosmeticSlots = { tint = true, camo = true, finish = true }

local function defaultsOf(weaponModel)
    local wd = WeaponsData.byName[tostring(weaponModel or ""):upper()]
    return (wd and wd.defaults) or {}
end

local function isAttachment(defaults, slot, model)
    return not cosmeticSlots[slot]
        and type(model) == "string" and model ~= ""
        and not defaults[model]
end

function MenuUI.AttachmentCount(weaponModel, comps)
    local defaults = defaultsOf(weaponModel)
    local used = 0
    for slot, model in pairs(comps or {}) do
        if isAttachment(defaults, slot, model) then used = used + 1 end
    end
    return used
end

function MenuUI.SlotIsCapped(weaponModel, comps, slot)
    if cosmeticSlots[slot] then return false end
    if isAttachment(defaultsOf(weaponModel), slot, comps[slot]) then return false end
    return MenuUI.AttachmentCount(weaponModel, comps) >= WeaponInternalsConfig.limit
end

function MenuUI.ClassWeaponSlot(w)
    local model = (w and w.weapon) or ""
    if model == "" then
        return { weapon = "", label = "None", image = "", empty = true, attachOn = 0, attachTotal = 0, level = 0, maxLevel = WeaponProgression.MaxLevel }
    end
    local _, label, image = MenuUI.WeaponMeta(model)

    local comps = (w and w.comps) or {}
    local wd = WeaponsData.byName[tostring(model):upper()]
    local slots = wd and wd.slots
    return { weapon = model, label = label, image = image, empty = false,
        attachOn = MenuUI.AttachmentCount(model, comps),
        attachTotal = (slots and next(slots)) and WeaponInternalsConfig.limit or 0,
        level = (MenuUI.WeaponProgress(model)), maxLevel = WeaponProgression.MaxLevel }
end

MenuUI.EditBucket = { [1] = "main", [2] = "secondary", [3] = "extra" }
MenuUI.EditSlot = { [1] = "primary", [2] = "secondary", [3] = "extra" }

function MenuUI.RankIcon(level, prestige)
    level = tonumber(level) or 0
    prestige = tonumber(prestige) or 0
    if level > 55 then level = 55 end
    if prestige > 0 then return "rank_prestige_" .. prestige end
    return "rank_" .. level
end

function MenuUI.EnsureClassSelected()
    if Class.customClass[1] then
        local idx = Class.editingIndex or 1
        if not Class.customClass[idx] then idx = 1 end
        if ClasseCreation.ClassSelected == 0 then
            ClasseCreation.ClassSelected = Class.customClass[idx]
            Class.editingIndex = idx
        end
    end
end

function MenuUI.KillstreakSlots()
    local slots = {}
    for i, v in ipairs(Gamemode.activeKillstreak or {}) do
        local cfg = SharedConfig.Killstreaks[v.type]
        slots[#slots + 1] = {
            index = i,
            type = v.type,
            label = (cfg and cfg.label) or v.type,
            icon = MenuUI.Slug((cfg and cfg.sprite) or ""),
            kill = tonumber(cfg and cfg.kill) or 0,
        }
    end
    return slots
end

function MenuUI.StripCodes(s)
    return (tostring(s or ""):gsub("~%a~", ""):gsub("^%s+", ""))
end

MenuUI.Vol = {
    reload    = { max = 0.12, get = "reloadSoundVolume",       set = "SetReladSoundVolume",        label = "Reload Voices" },
    kill      = { max = 0.15, get = "killSoundVolume",         set = "SetKillSoundVolume",         label = "Kill Voices" },
    death     = { max = 0.12, get = "deathSoundVolume",        set = "SetDeathSoundVolume",        label = "Death Voices" },
    weapon    = { max = 0.06, get = "customWeaponSoundVolume", set = "SetCustomWeaponSoundVolume", label = "Weapon Sounds" },
    hitmarker = { max = 0.15, get = "hitMarkerVolume",         set = "SetHitMarkerVolume",         label = "Hitmarker" },
    rankupvol = { max = 0.15, get = "rankupVolume",            set = "SetRankupVolume",            label = "Rank-Up Sound" },
    interface = { max = 0.15, get = "interfaceSoundVolume",    set = "SetInterfaceSoundVolume",    label = "Interface Sounds" },
    effects   = { max = 0.15, get = "effectsSoundVolume",      set = "SetEffectsSoundVolume",      label = "Gameplay Effects" },
    musics    = { max = 0.06, get = "MusicsVolume",            set = "SetMusicVolume",             label = "Music" },
}
MenuUI.VolOrder = { "reload", "kill", "death", "weapon", "hitmarker", "rankupvol", "interface", "effects", "musics" }
