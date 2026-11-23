WeaponAttachmentStats = {}

local initialized = false
local baselines = {}
local touchedWeapons = {}
local categoryScales = {}
local globalScales = {}

local statDefinitions = {
    damage = { lowerIsBetter = false, headroomMin = 0.80, headroomMax = 1.20 },
    recoil = { lowerIsBetter = true, cap = "recoil" },
    spread = { lowerIsBetter = true, cap = "spread", headroomMin = 0.80, headroomMax = 1.20 },
    range = { lowerIsBetter = false, globalScale = true, headroomMin = 0.80, headroomMax = 1.20 },
    fireRate = { lowerIsBetter = false, headroomMin = 0.95, headroomMax = 1.05 },
    mobility = { lowerIsBetter = false, globalScale = true, cap = "mobility", headroomMin = 0.95, headroomMax = 1.05 },
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function round(value, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function copyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local internalProfiles
local function internalProfile(model)
    if not internalProfiles then
        internalProfiles = {}
        for _, def in ipairs(WeaponInternalsConfig.slots) do
            for _, item in ipairs(def.items) do internalProfiles[item.model] = item end
        end
    end
    return internalProfiles[model]
end

local function profileForComponent(componentModel)
    local config = AttachmentEffectsConfig
    local model = tostring(componentModel or ""):upper()
    if model == "" then return nil end

    local internal = internalProfile(model)
    if internal then return internal end

    local profileName = config.componentProfiles[model]
    if not profileName then
        for _, rule in ipairs(config.rules) do
            if model:find(rule.contains, 1, true) then
                profileName = rule.profile
                break
            end
        end
    end

    return profileName and config.profiles[profileName]
end

local function captureBaseline(weaponModel, category)
    local model = tostring(weaponModel or ""):upper()
    if model == "" then return nil end
    local weaponHash = GetHashKey(model)
    if baselines[weaponHash] then return baselines[weaponHash] end

    local ok, hudDamage, hudSpeed, _, _, hudRange = GetWeaponHudStats(weaponHash)
    local baseline = {
        model = model,
        hash = weaponHash,
        category = category or "",
        damage = ok and hudDamage or 0,
        recoil = GetWeaponRecoilShakeAmplitude(weaponHash),
        spread = GetWeaponAccuracySpread(weaponHash),
        range = ok and hudRange or 0,
        fireRate = ok and hudSpeed or 0,
        clip = GetWeaponClipSize(weaponHash),
        damageModifier = GetWeaponDamageModifier(weaponHash),
        mobility = AttachmentEffectsConfig.mobilityByCategory[category or ""] or 85,
    }
    if baseline.damageModifier <= 0 then baseline.damageModifier = 1.0 end
    baselines[weaponHash] = baseline
    return baseline
end

local function addScaleValue(scales, key, value)
    value = tonumber(value)
    if not value or value <= 0 then return end
    local scale = scales[key]
    if not scale then
        scales[key] = { min = value, max = value }
        return
    end
    scale.min = math.min(scale.min, value)
    scale.max = math.max(scale.max, value)
end

local function finalizeScale(scale, definition)
    if not scale then return { min = 0, max = 1 } end

    local cap = definition.cap and AttachmentEffectsConfig.caps[definition.cap]
    if cap then
        scale.min = scale.min * (1.0 + cap.min)
        scale.max = scale.max * (1.0 + cap.max)
    end
    if definition.headroomMin then scale.min = scale.min * definition.headroomMin end
    if definition.headroomMax then scale.max = scale.max * definition.headroomMax end

    if scale.max <= scale.min then
        local padding = math.max(math.abs(scale.max) * 0.15, 0.01)
        scale.min = math.max(0, scale.min - padding)
        scale.max = scale.max + padding
    end
    return scale
end

local function buildScales()
    local rawGlobal = {}
    local rawCategories = {}

    for _, baseline in pairs(baselines) do
        local category = baseline.category ~= "" and baseline.category or "GLOBAL"
        rawCategories[category] = rawCategories[category] or {}
        for statKey in pairs(statDefinitions) do
            addScaleValue(rawGlobal, statKey, baseline[statKey])
            addScaleValue(rawCategories[category], statKey, baseline[statKey])
        end
    end

    for statKey, definition in pairs(statDefinitions) do
        globalScales[statKey] = finalizeScale(rawGlobal[statKey], definition)
    end
    for category, rawScales in pairs(rawCategories) do
        categoryScales[category] = {}
        for statKey, definition in pairs(statDefinitions) do
            categoryScales[category][statKey] = finalizeScale(rawScales[statKey], definition)
        end
    end
end

function WeaponAttachmentStats.Initialize()
    if initialized then return end
    WeaponsData.Load()

    local selectableCategories = {}
    for _, bucket in pairs(WeaponsData.Picker) do
        for _, category in ipairs(bucket) do selectableCategories[category.cat] = true end
    end

    for weaponModel, weaponData in pairs(WeaponsData.byName) do
        if selectableCategories[weaponData.category] then
            captureBaseline(weaponModel, weaponData.category)
        end
    end

    buildScales()
    initialized = true
end

local function aggregateEffects(comps)
    local totals = { damage = 0, recoil = 0, spread = 0, mobility = 0 }
    for key, componentModel in pairs(comps or {}) do
        if key ~= "camo" and key ~= "tint" and type(componentModel) == "string" and componentModel ~= "" then
            local profile = profileForComponent(componentModel)
            for statKey in pairs(totals) do
                totals[statKey] = totals[statKey] + (profile and profile[statKey] or 0)
            end
        end
    end

    for statKey, value in pairs(totals) do
        local cap = AttachmentEffectsConfig.caps[statKey]
        totals[statKey] = clamp(value, cap.min, cap.max)
    end
    return totals
end

local function componentModifiers(comps)
    local result = { damage = 1.0, accuracy = 1.0, range = 1.0, clip = nil }
    for key, componentModel in pairs(comps or {}) do
        if key ~= "camo" and key ~= "tint" and not WeaponsData.VirtualComponents[componentModel]
            and type(componentModel) == "string" and componentModel ~= "" then
            local componentHash = GetHashKey(componentModel)
            local modifier = GetWeaponComponentDamageModifier(componentHash)
            if modifier > 0 then result.damage = result.damage * modifier end
            modifier = GetWeaponComponentAccuracyModifier(componentHash)
            if modifier > 0 then result.accuracy = result.accuracy * modifier end
            modifier = GetWeaponComponentRangeModifier(componentHash)
            if modifier > 0 then result.range = result.range * modifier end
            local clip = GetWeaponComponentClipSize(componentHash)
            if clip > 0 then result.clip = clip end
        end
    end
    return result
end

local function calculateRaw(weaponModel, comps)
    WeaponAttachmentStats.Initialize()
    local model = tostring(weaponModel or ""):upper()
    local weaponData = WeaponsData.byName[model]
    local baseline = captureBaseline(model, weaponData and weaponData.category or "")
    if not baseline then return nil end

    local effects = aggregateEffects(comps)
    local components = componentModifiers(comps)
    return {
        damage = baseline.damage * components.damage * (1.0 + effects.damage),
        recoil = baseline.recoil * (1.0 + effects.recoil),
        spread = baseline.spread * (1.0 + effects.spread) / components.accuracy,
        range = baseline.range * components.range,
        fireRate = baseline.fireRate,
        mobility = baseline.mobility * (1.0 + effects.mobility),
        clip = components.clip or baseline.clip,
        category = baseline.category,
    }
end

local function statBar(statKey, value, category)
    local definition = statDefinitions[statKey]
    local categoryScale = categoryScales[category] and categoryScales[category][statKey]
    local scale = definition.globalScale and globalScales[statKey]
        or categoryScale
        or globalScales[statKey]
        or { min = 0, max = 1 }
    local normalized = clamp((value - scale.min) / math.max(0.000001, scale.max - scale.min), 0, 1)
    if definition.lowerIsBetter then normalized = 1.0 - normalized end
    return round(normalized * 100, 1)
end

local function comparisonEntry(statKey, referenceValue, value, category)
    local definition = statDefinitions[statKey]
    local delta = 0
    if math.abs(referenceValue) > 0.000001 then delta = ((value / referenceValue) - 1.0) * 100 end

    local tone = "neutral"
    if math.abs(delta) >= 0.05 then
        local improved = definition.lowerIsBetter and delta < 0 or not definition.lowerIsBetter and delta > 0
        tone = improved and "positive" or "negative"
    end

    local decimals = (statKey == "recoil" or statKey == "spread") and 3 or 1
    return {
        value = round(value, decimals),
        referenceValue = round(referenceValue, decimals),
        bar = statBar(statKey, value, category),
        referenceBar = statBar(statKey, referenceValue, category),
        delta = round(delta, 1),
        tone = tone,
        lowerIsBetter = definition.lowerIsBetter,
    }
end

function WeaponAttachmentStats.BuildComparison(weaponModel, comps, preview)
    local baseline = calculateRaw(weaponModel, {})
    local current = calculateRaw(weaponModel, comps or {})
    if not baseline or not current then return {} end

    local displayed = current
    local reference = baseline
    local isPreview = type(preview) == "table" and preview.type and preview.type ~= "tint"
    if isPreview then
        local previewComps = copyTable(comps)
        local model = tostring(preview.model or "")
        previewComps[preview.type] = model ~= "" and model or nil
        displayed = calculateRaw(weaponModel, previewComps) or current
        reference = current
    end

    local result = { isPreview = isPreview == true }
    for statKey in pairs(statDefinitions) do
        result[statKey] = comparisonEntry(statKey, reference[statKey], displayed[statKey], displayed.category)
    end

    local clipDelta = displayed.clip - reference.clip
    result.clip = {
        value = round(displayed.clip, 0),
        referenceValue = round(reference.clip, 0),
        delta = round(clipDelta, 0),
        tone = clipDelta > 0 and "positive" or (clipDelta < 0 and "negative" or "neutral"),
    }
    return result
end

function WeaponAttachmentStats.GetComponentDisplayEffects(componentModel)
    local internal = internalProfile(tostring(componentModel or ""):upper())
    if internal then
        return {
            damage = internal.damage or 0,
            recoil = internal.recoil or 0,
            spread = internal.spread or 0,
            mobility = internal.mobility or 0,
            range = 0,
            clip = 0,
        }
    end

    local profile = profileForComponent(componentModel) or {}
    local componentHash = GetHashKey(tostring(componentModel or ""))
    local nativeDamage = GetWeaponComponentDamageModifier(componentHash)
    local nativeAccuracy = GetWeaponComponentAccuracyModifier(componentHash)
    local nativeRange = GetWeaponComponentRangeModifier(componentHash)
    local clip = GetWeaponComponentClipSize(componentHash)
    if nativeDamage <= 0 then nativeDamage = 1.0 end
    if nativeAccuracy <= 0 then nativeAccuracy = 1.0 end
    if nativeRange <= 0 then nativeRange = 1.0 end

    return {
        damage = (1.0 + (profile.damage or 0)) * nativeDamage - 1.0,
        recoil = profile.recoil or 0,
        spread = (1.0 + (profile.spread or 0)) / nativeAccuracy - 1.0,
        range = nativeRange - 1.0,
        mobility = 0,
        clip = clip,
        utility = profile.utility,
    }
end

function WeaponAttachmentStats.ApplyForWeapon(weaponModel, comps)
    WeaponAttachmentStats.Initialize()
    local model = tostring(weaponModel or ""):upper()
    if model == "" then return end
    local weaponData = WeaponsData.byName[model]
    local baseline = captureBaseline(model, weaponData and weaponData.category or "")

    local effects = aggregateEffects(comps or {})
    SetWeaponRecoilShakeAmplitude(baseline.hash, baseline.recoil * (1.0 + effects.recoil))
    SetWeaponAccuracySpread(baseline.hash, baseline.spread * (1.0 + effects.spread))
    SetWeaponDamageModifier(baseline.hash, baseline.damageModifier * (1.0 + effects.damage))
    WeaponMobility.SetRate(baseline.model, 1.0 + effects.mobility)
    touchedWeapons[baseline.hash] = true
end

function WeaponAttachmentStats.RestoreAll()
    for weaponHash in pairs(touchedWeapons) do
        local baseline = baselines[weaponHash]
        if baseline then
            SetWeaponRecoilShakeAmplitude(weaponHash, baseline.recoil)
            SetWeaponAccuracySpread(weaponHash, baseline.spread)
            SetWeaponDamageModifier(weaponHash, baseline.damageModifier)
        end
    end
    touchedWeapons = {}
    WeaponMobility.Clear()
end

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then WeaponAttachmentStats.RestoreAll() end
end)

Citizen.CreateThread(function()
    Wait(0)
    WeaponAttachmentStats.Initialize()
end)
