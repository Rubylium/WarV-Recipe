WeaponRegistry = {
    byHash = {},
    byName = {},
    definitions = {},
    loaded = false,
}

local additiveStatFields = {
    kill = true,
    assist = true,
    headshot = true,
    xp = true,
}

local function registerHash(hash, name)
    hash = tonumber(hash)
    if not hash then return end

    WeaponRegistry.byHash[hash] = name
    if hash < 0 then
        WeaponRegistry.byHash[hash + 4294967296] = name
    elseif hash > 2147483647 then
        WeaponRegistry.byHash[hash - 4294967296] = name
    end
end

function WeaponRegistry.Load()
    if WeaponRegistry.loaded then return true end

    local raw = LoadResourceFile(GetCurrentResourceName(), "data/weapons.json")
    if not raw then
        print("^3[warv] weapons.json missing^7")
        return false
    end

    local success, definitions = pcall(json.decode, raw)
    if not success or type(definitions) ~= "table" then
        print("^3[warv] weapons.json invalid^7")
        return false
    end

    WeaponRegistry.definitions = definitions
    for _, definition in ipairs(definitions) do
        local name = tostring(definition.Name or ""):upper()
        if name ~= "" then
            WeaponRegistry.byName[name] = definition
            registerHash(GetHashKey(name), name)
            registerHash(definition.Hash, name)
            registerHash(definition.IntHash, name)
        end
    end

    WeaponRegistry.loaded = true
    return true
end

function WeaponRegistry.GetNameFromHash(hash)
    if hash == nil or not WeaponRegistry.Load() then return nil end
    local numericHash = tonumber(hash)
    if not numericHash then return nil end
    return WeaponRegistry.byHash[numericHash]
end

function WeaponRegistry.NormalizeName(weapon)
    if weapon == nil then return nil end
    WeaponRegistry.Load()

    if type(weapon) == "number" then
        return WeaponRegistry.GetNameFromHash(weapon)
    end

    local name = tostring(weapon):upper()
    if name == "" then return nil end
    if WeaponRegistry.byName[name] then return name end
    return WeaponRegistry.GetNameFromHash(GetHashKey(name)) or name
end

function WeaponRegistry.GetStats(stats, weapon)
    if type(stats) ~= "table" then return nil end

    local canonicalName = WeaponRegistry.NormalizeName(weapon)
    if canonicalName and stats[canonicalName] ~= nil then
        return stats[canonicalName]
    end
    if weapon ~= nil and stats[weapon] ~= nil then return stats[weapon] end

    for name, weaponStats in pairs(stats) do
        if WeaponRegistry.NormalizeName(name) == canonicalName then
            return weaponStats
        end
    end

    return nil
end

local function mergeStats(target, source)
    for field, value in pairs(source) do
        if additiveStatFields[field] then
            target[field] = (tonumber(target[field]) or 0) + (tonumber(value) or 0)
        elseif field == "level" then
            target.level = math.max(tonumber(target.level) or 1, tonumber(value) or 1)
        elseif target[field] == nil then
            target[field] = value
        end
    end
end

function WeaponRegistry.NormalizeStats(stats)
    if type(stats) ~= "table" then return {} end

    local normalized = {}
    for weapon, weaponStats in pairs(stats) do
        if type(weaponStats) == "table" then
            local name = WeaponRegistry.NormalizeName(weapon)
            if name then
                normalized[name] = normalized[name] or {}
                mergeStats(normalized[name], weaponStats)
            end
        end
    end

    for _, weaponStats in pairs(normalized) do
        weaponStats.kill = tonumber(weaponStats.kill) or 0
        weaponStats.assist = tonumber(weaponStats.assist) or 0
        weaponStats.headshot = tonumber(weaponStats.headshot) or 0
        weaponStats.xp = tonumber(weaponStats.xp) or 0
        weaponStats.level = math.max(tonumber(weaponStats.level) or 1, WeaponProgression.LevelFromXp(weaponStats.xp))
    end

    return normalized
end

WeaponRegistry.Load()
