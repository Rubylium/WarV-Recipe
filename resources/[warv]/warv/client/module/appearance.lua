Appearance = {
    catalog = {
        outfits = {},
    },
    playerOutfits = {},
}

local function tableEntry(collection, index)
    if type(collection) ~= "table" then
        return nil
    end
    return collection[tostring(index)] or collection[index]
end

local function hasTeam(outfit, team)
    if type(outfit.teams) ~= "table" then
        return false
    end
    for _, value in ipairs(outfit.teams) do
        if tonumber(value) == team then
            return true
        end
    end
    return false
end

function Appearance.ModelHash(model)
    if type(model) == "number" then
        return math.floor(model)
    end
    return GetHashKey(tostring(model or "mp_m_freemode_01"))
end

function Appearance.LoadModel(model)
    local hash = Appearance.ModelHash(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
        RequestModel(hash)
    end
    return HasModelLoaded(hash) and hash or nil
end

function Appearance.SetCatalog(data)
    if type(data) ~= "table" or type(data.outfits) ~= "table" then
        return
    end
    Appearance.catalog = data
end

function Appearance.Find(outfitId)
    for _, outfit in ipairs(Appearance.catalog.outfits) do
        if outfit.id == outfitId then
            return outfit
        end
    end
end

function Appearance.TeamPool(team)
    local pool = {}
    for _, outfit in ipairs(Appearance.catalog.outfits) do
        local rostered = type(outfit.teams) == "table" and #outfit.teams > 0
        if (team == 0 and rostered) or hasTeam(outfit, team) then
            pool[#pool + 1] = outfit
        end
    end

    if #pool == 0 then
        return Appearance.catalog.outfits
    end
    return pool
end

function Appearance.PlayerOutfit(team)
    team = tonumber(team) or 0

    local outfit = Appearance.Find(Appearance.playerOutfits[team])
    if outfit ~= nil then
        return outfit
    end

    local pool = Appearance.TeamPool(team)
    if #pool == 0 then
        return nil
    end

    outfit = pool[math.random(1, #pool)]
    Appearance.playerOutfits[team] = outfit.id
    return outfit
end

function Appearance.Apply(ped, appearance)
    if type(appearance) ~= "table" or ped == nil or not DoesEntityExist(ped) then
        return false
    end

    local blend = appearance.headBlend or {}
    SetPedHeadBlendData(
        ped,
        tonumber(blend.shapeFirst) or 0,
        tonumber(blend.shapeSecond) or 0,
        tonumber(blend.shapeThird) or 0,
        tonumber(blend.skinFirst) or 0,
        tonumber(blend.skinSecond) or 0,
        tonumber(blend.skinThird) or 0,
        tonumber(blend.shapeMix) or 0.5,
        tonumber(blend.skinMix) or 0.5,
        tonumber(blend.thirdMix) or 0.0,
        false
    )

    for featureId = 0, 19 do
        SetPedFaceFeature(ped, featureId, tonumber(tableEntry(appearance.faceFeatures, featureId)) or 0.0)
    end

    for componentId = 0, 11 do
        local component = tableEntry(appearance.components, componentId) or {}
        SetPedComponentVariation(
            ped,
            componentId,
            tonumber(component.drawable) or 0,
            tonumber(component.texture) or 0,
            tonumber(component.palette) or 0
        )
    end

    for propId = 0, 7 do
        local prop = tableEntry(appearance.props, propId) or {}
        local drawable = tonumber(prop.drawable) or -1
        if drawable < 0 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawable, tonumber(prop.texture) or 0, true)
        end
    end

    local hair = appearance.hair or {}
    SetPedHairColor(ped, tonumber(hair.color) or 0, tonumber(hair.highlight) or 0)
    SetPedEyeColor(ped, tonumber(appearance.eyeColor) or 0)

    for overlayId = 0, 12 do
        local overlay = tableEntry(appearance.headOverlays, overlayId) or {}
        local value = tonumber(overlay.value) or 255
        SetPedHeadOverlay(ped, overlayId, value, tonumber(overlay.opacity) or 1.0)
        if value ~= 255 then
            SetPedHeadOverlayColor(
                ped,
                overlayId,
                tonumber(overlay.colorType) or 0,
                tonumber(overlay.color) or 0,
                tonumber(overlay.secondColor) or 0
            )
        end
    end

    return true
end

function Appearance.ApplyOutfit(ped, outfitId)
    local outfit = Appearance.Find(outfitId)
    if outfit == nil then
        return false
    end
    return Appearance.Apply(ped, outfit.appearance)
end

function Appearance.ApplyToPlayer(appearance)
    if type(appearance) ~= "table" then
        return
    end

    local ped = Gamemode.utils.GetPed()
    local hash = Appearance.ModelHash(appearance.model)
    if GetEntityModel(ped) ~= hash and Appearance.LoadModel(hash) then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
        ped = Gamemode.utils.GetPed()
        SetPedDefaultComponentVariation(ped)
    end

    Appearance.Apply(ped, appearance)
end

function Appearance.LoadPlayer(team)
    local outfit = Appearance.PlayerOutfit(team)
    if outfit == nil then
        return
    end
    Appearance.ApplyToPlayer(outfit.appearance)
end

RegisterNetEvent("warv:clothing:sync")
AddEventHandler("warv:clothing:sync", function(data)
    Appearance.SetCatalog(data)
    Citizen.CreateThread(function()
        if not ClothingCreator.open then
            Appearance.LoadPlayer(Gamemode.Playing and Gamemode.Team or 0)
        end
        Bot.RefreshAppearances()
    end)
end)

Citizen.CreateThread(function()
    local raw = LoadResourceFile(GetCurrentResourceName(), "data/clothing.json")
    if raw then
        local ok, data = pcall(json.decode, raw)
        if ok then
            Appearance.SetCatalog(data)
        end
    end
    TriggerServerEvent("warv:clothing:requestData")
end)
