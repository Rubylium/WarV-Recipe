function Lobby.PushWeaponPicker()
    local editType = Class.editType or 1
    local bucket = MenuUI.EditBucket[editType] or "main"
    local list = WeaponsData.PickerCategories(bucket)
    if #list == 0 then
        list = SharedConfig.weapons[bucket] or {}
    end
    local playerLevel = tonumber(Lobby.playerData.level) or 1

    local slot = MenuUI.EditSlot[editType] or "primary"
    local currentWeapon = ""
    if Class.editingIndex and Class.customClass[Class.editingIndex] then
        local cw = Class.customClass[Class.editingIndex].weapons
        if cw and cw[slot] then currentWeapon = cw[slot].weapon or "" end
    end

    local categories = {}
    for _, cat in ipairs(list) do
        local weapons = {}
        for _, wv in ipairs(cat.weapons or {}) do
            local model = wv.weapon
            local hash, label, image = MenuUI.WeaponMeta(model)
            local level = tonumber(wv.level) or 0
            local dmg, spd, acc, rng = 0, 0, 0, 0
            local ok, hudDamage, hudSpeed, _, hudAccuracy, hudRange = GetWeaponHudStats(hash)
            if ok then dmg, spd, acc, rng = hudDamage, hudSpeed, hudAccuracy, hudRange end
            weapons[#weapons + 1] = {
                weapon = model,
                label = label,
                image = image,
                level = level,
                locked = level > playerLevel,
                weaponLevel = (MenuUI.WeaponProgress(model)),
                equipped = (model == currentWeapon),
                damage = dmg,
                accuracy = acc,
                range = rng,
                fireRate = spd,
                clip = GetWeaponClipSize(hash) or 0,
            }
        end
        table.sort(weapons, function(a, b) return a.level < b.level end)
        categories[#categories + 1] = { label = tostring(cat.label or ""), weapons = weapons }
    end

    exports['warv-ui']:SetWeaponPicker({
        slot = slot,
        playerLevel = playerLevel,
        maxWeaponLevel = WeaponProgression.MaxLevel,
        categories = categories,
    })
end

local function classPickWeapon(w)
    local model = (w and w.weapon) or ""
    if model == "" then return { label = "None", image = "", level = 0, empty = true } end
    local _, label, image = MenuUI.WeaponMeta(model)
    return { label = label, image = image, level = (MenuUI.WeaponProgress(model)), empty = false }
end

local function classPickEntry(key, c, premade)
    local w = c.weapons or {}
    return {
        key = key,
        name = tostring(c.name or key),
        premade = premade,
        primary = classPickWeapon(w.primary),
        secondary = classPickWeapon(w.secondary),
        extra = classPickWeapon(w.extra),
    }
end

function Lobby.PushClassPick()
    local classes = {}
    for i, c in ipairs(Class.customClass) do
        classes[#classes + 1] = classPickEntry("c" .. i, c, false)
    end
    for i, c in ipairs(SharedConfig.PreMadeClass) do
        classes[#classes + 1] = classPickEntry("p" .. i, c, true)
    end

    local selName = (Class.selected and Class.selected.name) or ""
    local selected = ""
    for _, c in ipairs(classes) do
        if c.name == selName then selected = c.key break end
    end

    exports['warv-ui']:SetClassPick({
        classes = classes,
        maxWeaponLevel = WeaponProgression.MaxLevel,
        selected = selected,
    })
end

local attachTypeLabel = {
    scope = "Optic",
    muzzle = "Muzzle",
    barrel = "Barrel",
    grip = "Underbarrel",
    clip = "Magazine",
    flashlight = "Tactical",
    rail = "Rail",
    finish = "Finish",
}
for slot, label in pairs(WeaponsData.InternalSlots) do
    attachTypeLabel[slot] = label
end

local function attachmentBefore(a, b)
    if a.level ~= b.level then
        return a.level < b.level
    end

    local aName = tostring(a.name or a.model or ""):lower()
    local bName = tostring(b.name or b.model or ""):lower()
    if aName ~= bName then
        return aName < bName
    end
    return tostring(a.model or "") < tostring(b.model or "")
end

local function tintBefore(a, b)
    if a.unlock ~= b.unlock then
        return a.unlock < b.unlock
    end

    local aLabel = tostring(a.label or ""):lower()
    local bLabel = tostring(b.label or ""):lower()
    if aLabel ~= bLabel then
        return aLabel < bLabel
    end
    return (tonumber(a.index) or 0) < (tonumber(b.index) or 0)
end

function Lobby.PushAttachEditor()
    local ed = WeaponEditor
    if ClasseCreation.ClassSelected == 0 then return end
    local editPrimary = ed.Components.EditPrimary
    local sel = ClasseCreation.ClassSelected
    local wslot = editPrimary and sel.weapons.primary or sel.weapons.secondary
    local weaponModel = wslot.weapon
    local _, weaponLabel, weaponImage = MenuUI.WeaponMeta(weaponModel)
    local comps = WeaponsData.NormalizeComponentSlots(wslot.comps or {})
    local committed = ed.Components.SelectedOldValue or comps
    WeaponsData.NormalizeComponentSlots(committed)
    local weaponLevel, xpInto, xpSpan = MenuUI.WeaponProgress(weaponModel)
    local maxLevel = WeaponProgression.MaxLevel

    local types = {}
    local wd = WeaponsData.byName[tostring(weaponModel):upper()]
    if wd then
        for slotKey, list in pairs(wd.slots) do
            local items = {}
            for _, c in ipairs(list) do
                local unlock = tonumber(c.unlock) or 0
                local isInstalled = (committed[slotKey] == c.model) or (c.isDefault and committed[slotKey] == nil)
                items[#items + 1] = {
                    name = c.label or c.model,
                    model = c.model,
                    effects = WeaponComponentEffects.Build(c).effects,
                    level = unlock,
                    locked = weaponLevel < unlock,
                    installed = isInstalled,
                    previewing = Menu.attachPreview and Menu.attachPreview.type == slotKey and Menu.attachPreview.model == c.model or false,
                }
            end
            table.sort(items, attachmentBefore)
            types[#types + 1] = {
                type = slotKey,
                label = attachTypeLabel[slotKey] or slotKey,
                items = items,
                installed = committed[slotKey] or "",
                dirty = (comps[slotKey] or false) ~= (committed[slotKey] or false),
                capped = MenuUI.SlotIsCapped(weaponModel, committed, slotKey),
            }
        end
    end
    table.sort(types, function(a, b) return a.label < b.label end)

    local tints = {}
    if wd and wd.tints then
        for _, t in ipairs(wd.tints) do
            local unlock = tonumber(t.unlock) or 0
            local isInstalled = (committed.tint == t.index) or (t.index == 0 and committed.tint == nil)
            tints[#tints + 1] = {
                index = t.index,
                label = t.label,
                unlock = unlock,
                locked = weaponLevel < unlock,
                installed = isInstalled,
                previewing = (comps.tint == t.index) and not isInstalled,
            }
        end
        table.sort(tints, tintBefore)
    end
    local tintDirty = (comps.tint or false) ~= (committed.tint or false)

    local slotMeta = {}
    local function addMeta(slot, label, instName)
        slotMeta[#slotMeta + 1] = {
            slot = slot,
            label = label,
            installed = instName or "",
            internal = WeaponsData.InternalSlots[slot] ~= nil,
        }
    end
    for _, t in ipairs(types) do
        local instName = ""
        for _, it in ipairs(t.items) do if it.installed then instName = it.name break end end
        addMeta(t.type, t.label, instName)
    end
    if #tints > 0 then addMeta("tint", "Camo", "") end
    Gunsmith.slotMeta = slotMeta
    Gunsmith.weapon = tostring(weaponModel or ""):upper()

    exports['warv-ui']:SetAttachEditor({
        weapon = { label = weaponLabel, image = weaponImage },
        level = weaponLevel,
        maxLevel = maxLevel,
        xpInto = xpInto,
        xpSpan = xpSpan,
        types = types,
        tints = tints,
        tintDirty = tintDirty,
        attachments = { used = MenuUI.AttachmentCount(weaponModel, committed), limit = WeaponInternalsConfig.limit },
        canEdit = (tonumber(Lobby.playerData.perm) or 0) >= 3,
        editing = Gunsmith.editing == true,
        stats = WeaponAttachmentStats.BuildComparison(weaponModel, comps, Menu.attachPreview),
    })
end

function Lobby.PushClassSelect()
    local classes = {}
    for i, c in ipairs(Class.customClass) do
        local w = c.weapons or {}
        classes[#classes + 1] = {
            index = i,
            name = tostring(c.name or ("Class " .. i)),
            primary = MenuUI.ClassWeaponSlot(w.primary),
            secondary = MenuUI.ClassWeaponSlot(w.secondary),
            extra = MenuUI.ClassWeaponSlot(w.extra),
        }
    end
    local selected = (Class.editingIndex and Class.editingIndex >= 1) and Class.editingIndex or 1
    exports['warv-ui']:SetClassSelect({
        classes = classes,
        lockedSlots = 5,
        warvPlus = false,
        selected = selected,
        scorestreaks = MenuUI.KillstreakSlots(),
    })
end

function Lobby.PushKillstreakEditor()
    local slots = MenuUI.KillstreakSlots()
    local equipped = {}
    for _, v in ipairs(Gamemode.activeKillstreak or {}) do equipped[v.type] = true end
    local streaks = {}
    for k, cfg in pairs(SharedConfig.Killstreaks) do
        streaks[#streaks + 1] = {
            type = k,
            label = cfg.label or k,
            icon = MenuUI.Slug(cfg.sprite or ""),
            kill = tonumber(cfg.kill) or 0,
            desc = (tostring(cfg.desc or ""):gsub("\n", " ")),
            equipped = equipped[k] == true,
        }
    end
    table.sort(streaks, function(a, b) return a.kill < b.kill end)
    exports['warv-ui']:SetKillstreakEditor({ slots = slots, streaks = streaks })
end
