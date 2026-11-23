Clothing = {}

local function clamp(value, minimum, maximum, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback
    end

    return math.max(minimum, math.min(maximum, value))
end

local function integer(value, minimum, maximum, fallback)
    return math.floor(clamp(value, minimum, maximum, fallback))
end

local function sanitizeText(value, maximumLength)
    value = tostring(value or "")
    value = value:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return value:sub(1, maximumLength)
end

local function copy(value)
    return json.decode(json.encode(value))
end

local function sanitizeModel(model)
    if type(model) == "number" then
        return math.floor(model)
    end

    local modelName = sanitizeText(model, 64)
    if modelName == "" then
        return "mp_m_freemode_01"
    end

    return modelName
end

local function sanitizeAppearance(appearance)
    appearance = type(appearance) == "table" and appearance or {}
    local sanitized = {
        model = sanitizeModel(appearance.model),
        components = {},
        props = {},
        faceFeatures = {},
        headOverlays = {},
        hair = {
            color = integer(appearance.hair and appearance.hair.color, 0, 63, 0),
            highlight = integer(appearance.hair and appearance.hair.highlight, 0, 63, 0),
        },
        eyeColor = integer(appearance.eyeColor, 0, 31, 0),
    }

    for componentId = 0, 11 do
        local source = appearance.components
            and (appearance.components[tostring(componentId)] or appearance.components[componentId])
            or {}
        sanitized.components[tostring(componentId)] = {
            drawable = integer(source.drawable, 0, 4095, 0),
            texture = integer(source.texture, 0, 1023, 0),
            palette = integer(source.palette, 0, 3, 0),
        }
    end

    for propId = 0, 7 do
        local source = appearance.props
            and (appearance.props[tostring(propId)] or appearance.props[propId])
            or {}
        local drawable = integer(source.drawable, -1, 4095, -1)
        sanitized.props[tostring(propId)] = {
            drawable = drawable,
            texture = drawable < 0 and -1 or integer(source.texture, 0, 1023, 0),
        }
    end

    local blend = type(appearance.headBlend) == "table" and appearance.headBlend or {}
    sanitized.headBlend = {
        shapeFirst = integer(blend.shapeFirst, 0, 45, 0),
        shapeSecond = integer(blend.shapeSecond, 0, 45, 0),
        shapeThird = integer(blend.shapeThird, 0, 45, 0),
        skinFirst = integer(blend.skinFirst, 0, 45, 0),
        skinSecond = integer(blend.skinSecond, 0, 45, 0),
        skinThird = integer(blend.skinThird, 0, 45, 0),
        shapeMix = clamp(blend.shapeMix, 0.0, 1.0, 0.5),
        skinMix = clamp(blend.skinMix, 0.0, 1.0, 0.5),
        thirdMix = clamp(blend.thirdMix, 0.0, 1.0, 0.0),
    }

    for featureId = 0, 19 do
        local value = appearance.faceFeatures
            and (appearance.faceFeatures[tostring(featureId)] or appearance.faceFeatures[featureId])
        sanitized.faceFeatures[tostring(featureId)] = clamp(value, -1.0, 1.0, 0.0)
    end

    for overlayId = 0, 12 do
        local source = appearance.headOverlays
            and (appearance.headOverlays[tostring(overlayId)] or appearance.headOverlays[overlayId])
            or {}
        sanitized.headOverlays[tostring(overlayId)] = {
            value = integer(source.value, 0, 255, 255),
            opacity = clamp(source.opacity, 0.0, 1.0, 1.0),
            colorType = integer(source.colorType, 0, 2, 0),
            color = integer(source.color, 0, 63, 0),
            secondColor = integer(source.secondColor, 0, 63, 0),
        }
    end

    return sanitized
end

local function sanitizeTeams(teams)
    local sanitized = {}
    if type(teams) ~= "table" then
        return sanitized
    end

    for team = 1, 2 do
        for _, value in ipairs(teams) do
            if tonumber(value) == team then
                sanitized[#sanitized + 1] = team
                break
            end
        end
    end

    return sanitized
end

local function slugify(value)
    local slug = sanitizeText(value, 48):lower():gsub("[^%w]+", "-")
    slug = slug:gsub("^%-+", ""):gsub("%-+$", "")
    return slug ~= "" and slug or "outfit"
end

local function findOutfitIndex(outfits, outfitId)
    for index, outfit in ipairs(outfits) do
        if outfit.id == outfitId then
            return index
        end
    end
end

local function uniqueId(outfits, requestedId, name)
    local baseId = sanitizeText(requestedId, 64):lower():gsub("[^%w_-]", "")
    if baseId ~= "" and findOutfitIndex(outfits, baseId) ~= nil then
        return baseId
    end

    baseId = slugify(name)
    local candidate = baseId
    local suffix = 2
    while findOutfitIndex(outfits, candidate) ~= nil do
        candidate = baseId .. "-" .. suffix
        suffix = suffix + 1
    end
    return candidate
end

RegisterNetEvent("warv:clothing:requestData")
AddEventHandler("warv:clothing:requestData", function()
    TriggerClientEvent("warv:clothing:sync", source, Outfits.data)
end)

RegisterNetEvent("warv:clothing:requestOpen")
AddEventHandler("warv:clothing:requestOpen", function()
    local source = source
    if not Permissions.Has(source, "Admin") then
        return
    end

    TriggerClientEvent("warv:clothing:open", source, Outfits.data)
end)

RegisterNetEvent("warv:clothing:save")
AddEventHandler("warv:clothing:save", function(payload)
    local source = source
    if not Permissions.Has(source, "Admin") or type(payload) ~= "table" then
        return
    end

    local name = sanitizeText(payload.name, 48)
    if name == "" then
        TriggerClientEvent("warv:clothing:saveResult", source, false, "Name required")
        return
    end

    local data = copy(Outfits.data)
    local outfits = data.outfits
    local outfitId = uniqueId(outfits, payload.id, name)
    local outfit = {
        id = outfitId,
        name = name,
        teams = sanitizeTeams(payload.teams),
        appearance = sanitizeAppearance(payload.appearance),
        updatedAt = os.time(),
        updatedBy = Players.GetPlayerUid(source),
    }

    local outfitIndex = findOutfitIndex(outfits, outfitId)
    if outfitIndex == nil then
        outfits[#outfits + 1] = outfit
    else
        outfits[outfitIndex] = outfit
    end

    table.sort(outfits, function(left, right)
        return left.name:lower() < right.name:lower()
    end)

    local saved, saveError = Outfits.Save(data)
    if not saved then
        TriggerClientEvent("warv:clothing:saveResult", source, false, saveError)
        return
    end

    TriggerClientEvent("warv:clothing:sync", -1, data)
    TriggerClientEvent("warv:clothing:saveResult", source, true, "Outfit saved", data, outfitId)
end)

RegisterNetEvent("warv:clothing:setTeams")
AddEventHandler("warv:clothing:setTeams", function(outfitId, teams)
    local source = source
    if not Permissions.Has(source, "Admin") then
        return
    end

    local data = copy(Outfits.data)
    local outfitIndex = findOutfitIndex(data.outfits, sanitizeText(outfitId, 64))
    if outfitIndex == nil then
        return
    end

    data.outfits[outfitIndex].teams = sanitizeTeams(teams)
    local saved, saveError = Outfits.Save(data)
    if not saved then
        TriggerClientEvent("warv:clothing:saveResult", source, false, saveError)
        return
    end

    TriggerClientEvent("warv:clothing:sync", -1, data)
end)

RegisterNetEvent("warv:clothing:delete")
AddEventHandler("warv:clothing:delete", function(outfitId)
    local source = source
    if not Permissions.Has(source, "Admin") then
        return
    end

    outfitId = sanitizeText(outfitId, 64)
    local data = copy(Outfits.data)
    local outfitIndex = findOutfitIndex(data.outfits, outfitId)
    if outfitIndex == nil then
        TriggerClientEvent("warv:clothing:saveResult", source, false, "Outfit not found")
        return
    end

    table.remove(data.outfits, outfitIndex)
    local saved, saveError = Outfits.Save(data)
    if not saved then
        TriggerClientEvent("warv:clothing:saveResult", source, false, saveError)
        return
    end

    TriggerClientEvent("warv:clothing:sync", -1, data)
    TriggerClientEvent("warv:clothing:saveResult", source, true, "Outfit deleted", data)
end)
