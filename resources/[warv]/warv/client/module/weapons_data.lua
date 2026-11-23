WeaponsData = {}
WeaponsData.byName = {}
WeaponsData.byHash = {}
WeaponsData.slotByComponent = {}
WeaponsData.loaded = false
WeaponsData.SlotOrder = {
    "clip",
    "scope",
    "muzzle",
    "barrel",
    "grip",
    "flashlight",
    "rail",
    "bore",
    "trigger",
    "buffer",
    "weight",
    "finish",
}

WeaponsData.InternalSlots = {}
WeaponsData.VirtualComponents = {}
for _, def in ipairs(WeaponInternalsConfig.slots) do
    if def.label then WeaponsData.InternalSlots[def.key] = def.label end
    for _, item in ipairs(def.items) do WeaponsData.VirtualComponents[item.model] = true end
end

local function slotForComponent(c)
    local t = c.Type
    local name = tostring(c.Name or ""):upper()
    if t == "CWeaponComponentClipInfo" then
        if name:find("EXPLOSIVE") then return nil end
        return "clip"
    end
    if t == "CWeaponComponentScopeInfo" then return "scope" end
    if t == "CWeaponComponentSuppressorInfo" then return "muzzle" end
    if t == "CWeaponComponentFlashLightInfo" then return "flashlight" end
    if t == "CWeaponComponentInfo" then
        if name:find("GRIP") then return "grip" end
        if name:find("BARREL") then return "barrel" end
        if name:find("RAILCOVER") then return "rail" end
    end
    if t == "CWeaponComponentVariantModelInfo" then return "finish" end
    if name:find("_VARMOD_", 1, true) then
        if name:find("_SLIDE", 1, true) then return nil end
        return "finish"
    end
    return nil
end

function WeaponsData.SlotForComponent(componentModel, declaredSlot)
    WeaponsData.Load()
    local model = tostring(componentModel or ""):upper()
    local slot = WeaponsData.slotByComponent[model]
    if slot then return slot end
    if model:find("_BARREL_", 1, true) or model:find("_QDC", 1, true) then return "barrel" end
    if model:find("_VARMOD_", 1, true) then
        if model:find("_SLIDE", 1, true) then return nil end
        return "finish"
    end
    if model:find("RAILCOVER", 1, true) then return "rail" end
    if declaredSlot == "barrel" then return "muzzle" end
    return declaredSlot
end

function WeaponsData.NormalizeComponentSlots(comps)
    if type(comps) ~= "table" then return comps end
    local legacyBarrel = comps.barrel
    if type(legacyBarrel) == "string" and legacyBarrel ~= "" then
        local resolvedSlot = WeaponsData.SlotForComponent(legacyBarrel, "barrel")
        if resolvedSlot == "muzzle" then
            if not comps.muzzle then comps.muzzle = legacyBarrel end
            comps.barrel = nil
        end
    end
    return comps
end

local function labelOf(o, fallback)
    return (o.TranslatedLabel and o.TranslatedLabel.English) or fallback
end

local function descriptionOf(o)
    return (o.TranslatedDescription and o.TranslatedDescription.English) or ""
end

local function hasAnyComponent(list, patterns)
    if not patterns then return false end
    for _, c in ipairs(list or {}) do
        local model = tostring(c.model):upper()
        for _, pattern in ipairs(patterns) do
            if model:find(pattern, 1, true) then return true end
        end
    end
    return false
end

local function tintRarity(label, index)
    local l = tostring(label or ""):lower()
    if l:find("platinum") then return 1000 end
    if l:find("diamond") then return 950 end
    if l:find("gold") then return 900 end
    return tonumber(index) or 0
end

function WeaponsData.Load()
    if WeaponsData.loaded then return end
    if not WeaponRegistry.Load() then return end
    local data = WeaponRegistry.definitions

    for _, w in ipairs(data) do
        local name = tostring(w.Name or ""):upper()
        local category = tostring(w.Category or "")
        if name ~= "" then
            local tints = {}
            for _, t in ipairs(w.Tints or {}) do
                tints[#tints + 1] = { index = t.Index, label = labelOf(t, "Tint " .. tostring(t.Index)) }
            end
            local slots, defaults = {}, {}
            for _, c in ipairs(w.Components or {}) do
                local slot = slotForComponent(c)
                if slot then
                    WeaponsData.slotByComponent[tostring(c.Name or ""):upper()] = slot
                    if c.IsDefault == true then defaults[c.Name] = true end
                    slots[slot] = slots[slot] or {}
                    table.insert(slots[slot], {
                        model = c.Name,
                        label = labelOf(c, c.Name),
                        description = descriptionOf(c),
                        isDefault = c.IsDefault == true,
                    })
                end
            end

            for _, def in ipairs(WeaponInternalsConfig.slots) do
                if def.categories[category] and not hasAnyComponent(slots[def.key], def.skipWhen) then
                    slots[def.key] = slots[def.key] or {}
                    for _, item in ipairs(def.items) do
                        WeaponsData.slotByComponent[item.model] = def.key
                        table.insert(slots[def.key], { model = item.model, label = item.label })
                    end
                end
            end

            local maxLevel = WeaponProgression.MaxLevel
            local nonDefault, internalsBySlot = {}, {}
            for _, sk in ipairs(WeaponsData.SlotOrder) do
                for _, c in ipairs(slots[sk] or {}) do
                    if c.isDefault then
                        c.unlock = 1
                    elseif WeaponsData.VirtualComponents[c.model] then
                        internalsBySlot[sk] = internalsBySlot[sk] or {}
                        table.insert(internalsBySlot[sk], c)
                    else
                        nonDefault[#nonDefault + 1] = c
                    end
                end
            end

            local depth, dealt = 1, true
            while dealt do
                dealt = false
                for _, sk in ipairs(WeaponsData.SlotOrder) do
                    local c = internalsBySlot[sk] and internalsBySlot[sk][depth]
                    if c then
                        nonDefault[#nonDefault + 1] = c
                        dealt = true
                    end
                end
                depth = depth + 1
            end

            local total = #nonDefault
            for k, c in ipairs(nonDefault) do
                c.unlock = math.max(2, math.ceil(maxLevel * k / total))
            end
            local premium = {}
            for _, t in ipairs(tints) do
                if t.index == 0 then
                    t.unlock = 1
                else
                    t._rar = tintRarity(t.label, t.index)
                    premium[#premium + 1] = t
                end
            end
            table.sort(premium, function(a, b) return a._rar < b._rar end)
            local ptot = #premium
            for k, t in ipairs(premium) do
                if ptot <= 1 then
                    t.unlock = maxLevel
                else
                    t.unlock = math.floor(2 + (maxLevel - 2) * (k - 1) / (ptot - 1) + 0.5)
                end
                t._rar = nil
            end

            WeaponsData.byName[name] = {
                label = labelOf(w, name),
                category = category,
                tints = tints,
                slots = slots,
                defaults = defaults,
            }
            WeaponsData.byHash[GetHashKey(name)] = name
        end
    end
    WeaponsData.loaded = true
end

WeaponsData.Picker = {
    main = {
        { cat = "GROUP_RIFLE",   label = "Assault Rifles" },
        { cat = "GROUP_SMG",     label = "Submachine Guns" },
        { cat = "GROUP_SHOTGUN", label = "Shotguns" },
        { cat = "GROUP_MG",      label = "Light Machine Guns" },
        { cat = "GROUP_SNIPER",  label = "Sniper Rifles" },
    },
    secondary = {
        { cat = "GROUP_PISTOL", label = "Handguns" },
    },
    extra = {
        { cat = "GROUP_THROWN", label = "Explosive" },
    },
}

local pickerSkip = {
    WEAPON_BALL = true, WEAPON_SNOWBALL = true, WEAPON_FLARE = true,
    WEAPON_ACIDPACKAGE = true, WEAPON_STRICKLER = true,
}

local curated
local function curatedMeta()
    if curated then return curated end
    curated = {}
    for _, bucket in pairs(SharedConfig.weapons) do
        for _, cat in ipairs(bucket) do
            for _, wv in ipairs(cat.weapons or {}) do
                curated[tostring(wv.weapon):upper()] = {
                    level = tonumber(wv.level) or 1,
                    pointToUse = tonumber(wv.pointToUse) or 5,
                }
            end
        end
    end
    return curated
end

function WeaponsData.PickerCategories(bucketKey)
    WeaponsData.Load()
    local meta = curatedMeta()
    local cats = {}
    for _, def in ipairs(WeaponsData.Picker[bucketKey] or {}) do
        local weapons = {}
        for name, wd in pairs(WeaponsData.byName) do
            if wd.category == def.cat and not pickerSkip[name] then
                local cur = meta[name]
                weapons[#weapons + 1] = {
                    weapon = name,
                    level = (cur and cur.level) or (1 + (GetHashKey(name) % 55)),
                    pointToUse = (cur and cur.pointToUse) or 5,
                }
            end
        end
        table.sort(weapons, function(a, b)
            if a.level ~= b.level then return a.level < b.level end
            return a.weapon < b.weapon
        end)
        if #weapons > 0 then
            cats[#cats + 1] = { label = def.label, weapons = weapons }
        end
    end
    return cats
end
