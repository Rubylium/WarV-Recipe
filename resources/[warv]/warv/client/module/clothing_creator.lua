ClothingCreator = {
    open = false,
    previewPed = nil,
    draft = nil,
    selectedId = nil,
    notice = "",
    saving = false,
}

local componentLabels = {
    [0] = "Head",
    [1] = "Mask",
    [2] = "Hair",
    [3] = "Torso / Arms",
    [4] = "Legs",
    [5] = "Bags",
    [6] = "Shoes",
    [7] = "Accessories",
    [8] = "Undershirt",
    [9] = "Body Armor",
    [10] = "Decals",
    [11] = "Tops",
}

local propLabels = {
    [0] = "Hats",
    [1] = "Glasses",
    [2] = "Ears",
    [3] = "Prop 3",
    [4] = "Prop 4",
    [5] = "Prop 5",
    [6] = "Watches",
    [7] = "Bracelets",
}

local previewAnimations = {
    top = {"clothingshirt", "try_shirt_positive_d"},
    legs = {"clothingtrousers", "try_trousers_positive_a"},
    shoes = {"clothingshoes", "try_shoes_positive_a"},
    arms = {"anim@heists@heist_corona@single_team", "single_team_loop_boss"},
}

local function copy(value)
    return json.decode(json.encode(value))
end

local function tableEntry(collection, index)
    if type(collection) ~= "table" then
        return nil
    end
    return collection[tostring(index)] or collection[index]
end

local function modelName(hash)
    if hash == GetHashKey("mp_m_freemode_01") then
        return "mp_m_freemode_01"
    elseif hash == GetHashKey("mp_f_freemode_01") then
        return "mp_f_freemode_01"
    end
    return hash
end

local function getSourcePed()
    local clone = Player.GetClone()
    if clone and DoesEntityExist(clone) then
        return clone
    end
    return PlayerPedId()
end

local function hideLobbyPeds(hidden)
    for _, entity in pairs(PlayersDisplay.Entitys) do
        if DoesEntityExist(entity) then
            SetEntityAlpha(entity, hidden and 0 or 255, false)
        end
    end
end

local function setupPreviewEntity(entity, coords, heading)
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, heading)
    SetEntityCollision(entity, false, false)
    SetEntityInvincible(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    FreezeEntityPosition(entity, true)
    RemoveAllPedWeapons(entity, true)
    SetEntityVisible(entity, true, false)
    SetEntityAlpha(entity, 255, false)
end

local function updateCameraHeightBounds()
    local ped = ClothingCreator.previewPed
    if not ped or not DoesEntityExist(ped) then
        return
    end

    local coords = GetEntityCoords(ped)
    local head = GetPedBoneCoords(ped, 0x796E, 0.0, 0.0, 0.05)
    local leftFoot = GetPedBoneCoords(ped, 0x3779, 0.0, 0.0, 0.0)
    local rightFoot = GetPedBoneCoords(ped, 0xCC4D, 0.0, 0.0, 0.0)
    local minHeight = math.min(leftFoot.z, rightFoot.z) - coords.z + 0.03
    local maxHeight = head.z - coords.z

    if maxHeight <= minHeight then
        minHeight = 0.05
        maxHeight = 1.7
    end

    ClothingCreator.camera.minHeight = minHeight
    ClothingCreator.camera.maxHeight = maxHeight
    ClothingCreator.camera.height = math.max(
        minHeight,
        math.min(maxHeight, ClothingCreator.camera.height)
    )
end

local function createPreview(model)
    local hash = Appearance.ModelHash(model)
    local oldPed = ClothingCreator.previewPed
    local coords
    local heading

    if oldPed and DoesEntityExist(oldPed) then
        if GetEntityModel(oldPed) == hash then
            return oldPed
        end
    end

    if not Appearance.LoadModel(hash) then
        return nil
    end

    if oldPed and DoesEntityExist(oldPed) then
        coords = GetEntityCoords(oldPed)
        heading = GetEntityHeading(oldPed)
        DeleteEntity(oldPed)
    else
        local sourcePed = getSourcePed()
        coords = GetEntityCoords(sourcePed)
        heading = GetEntityHeading(sourcePed)
    end

    local previewPed = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, false, false)
    setupPreviewEntity(previewPed, coords, heading)
    SetModelAsNoLongerNeeded(hash)
    ClothingCreator.previewPed = previewPed
    Wait(0)
    updateCameraHeightBounds()
    return previewPed
end

local function requestAnimation(animationDictionary)
    RequestAnimDict(animationDictionary)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(animationDictionary) and GetGameTimer() < timeout do
        Wait(0)
        RequestAnimDict(animationDictionary)
    end
    return HasAnimDictLoaded(animationDictionary)
end

local function setPreviewPose(pose)
    local ped = ClothingCreator.previewPed
    if not ped or not DoesEntityExist(ped) then
        return
    end

    if pose == "turnLeft" then
        SetEntityHeading(ped, GetEntityHeading(ped) - 45.0)
        return
    elseif pose == "turnRight" then
        SetEntityHeading(ped, GetEntityHeading(ped) + 45.0)
        return
    end

    ClearPedTasksImmediately(ped)
    if pose == "idle" then
        return
    end

    local animation = previewAnimations[pose]
    if animation and requestAnimation(animation[1]) then
        TaskPlayAnim(ped, animation[1], animation[2], 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end
end

local function captureAppearance(ped)
    local appearance = {
        model = modelName(GetEntityModel(ped)),
        components = {},
        props = {},
        faceFeatures = {},
        headOverlays = {},
        hair = {
            color = GetPedHairColor(ped),
            highlight = GetPedHairHighlightColor(ped),
        },
        eyeColor = GetPedEyeColor(ped),
        headBlend = {
            shapeFirst = 0,
            shapeSecond = 0,
            shapeThird = 0,
            skinFirst = 0,
            skinSecond = 0,
            skinThird = 0,
            shapeMix = 0.5,
            skinMix = 0.5,
            thirdMix = 0.0,
        },
    }

    for componentId = 0, 11 do
        appearance.components[tostring(componentId)] = {
            drawable = GetPedDrawableVariation(ped, componentId),
            texture = GetPedTextureVariation(ped, componentId),
            palette = GetPedPaletteVariation(ped, componentId),
        }
    end

    for propId = 0, 7 do
        appearance.props[tostring(propId)] = {
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId),
        }
    end

    for featureId = 0, 19 do
        appearance.faceFeatures[tostring(featureId)] = GetPedFaceFeature(ped, featureId)
    end

    for overlayId = 0, 12 do
        appearance.headOverlays[tostring(overlayId)] = {
            value = GetPedHeadOverlayValue(ped, overlayId),
            opacity = 1.0,
            colorType = 0,
            color = 0,
            secondColor = 0,
        }
    end

    return appearance
end

local function applyAppearance(appearance)
    local ped = createPreview(appearance.model)
    if ped == nil then
        ClothingCreator.notice = "Ped model unavailable"
        return false
    end

    return Appearance.Apply(ped, appearance)
end

local function resetDrawableDefaults(appearance, currentAppearance)
    local changed = {
        any = false,
        components = {},
        props = {},
    }

    for componentId = 0, 11 do
        local component = tableEntry(appearance.components, componentId)
        local current = tableEntry(currentAppearance.components, componentId) or {}
        if component
            and (tonumber(component.drawable) or 0) ~= (tonumber(current.drawable) or 0)
        then
            component.texture = 0
            component.palette = 0
            changed.any = true
            changed.components[componentId] = true
        end
    end

    for propId = 0, 7 do
        local prop = tableEntry(appearance.props, propId)
        local current = tableEntry(currentAppearance.props, propId) or {}
        local drawable = prop and (tonumber(prop.drawable) or -1) or -1
        local drawableChanged = drawable ~= (tonumber(current.drawable) or -1)
        local clearedTextureInvalid = drawable < 0 and tonumber(prop and prop.texture) ~= -1
        if prop and (drawableChanged or clearedTextureInvalid) then
            prop.texture = drawable < 0 and -1 or 0
            changed.any = true
            changed.props[propId] = true
        end
    end

    return changed
end

local function readAppliedDefaults(appearance, changed)
    local ped = ClothingCreator.previewPed
    if not ped or not DoesEntityExist(ped) then
        return
    end

    for componentId in pairs(changed.components) do
        local component = tableEntry(appearance.components, componentId)
        component.texture = GetPedTextureVariation(ped, componentId)
        component.palette = GetPedPaletteVariation(ped, componentId)
    end

    for propId in pairs(changed.props) do
        local prop = tableEntry(appearance.props, propId)
        prop.texture = GetPedPropTextureIndex(ped, propId)
    end
end

local function buildLimits()
    local ped = ClothingCreator.previewPed
    local limits = {
        components = {},
        props = {},
        overlayMax = {},
        hairColorMax = math.max(0, GetNumHairColors() - 1),
    }
    if not ped or not DoesEntityExist(ped) then
        return limits
    end

    for componentId = 0, 11 do
        local component = tableEntry(ClothingCreator.draft.appearance.components, componentId) or {}
        local drawable = tonumber(component.drawable) or 0
        limits.components[#limits.components + 1] = {
            id = componentId,
            label = componentLabels[componentId],
            drawableMax = math.max(0, GetNumberOfPedDrawableVariations(ped, componentId) - 1),
            textureMax = math.max(0, GetNumberOfPedTextureVariations(ped, componentId, drawable) - 1),
        }
    end

    for propId = 0, 7 do
        local prop = tableEntry(ClothingCreator.draft.appearance.props, propId) or {}
        local drawable = tonumber(prop.drawable) or -1
        limits.props[#limits.props + 1] = {
            id = propId,
            label = propLabels[propId],
            drawableMax = math.max(-1, GetNumberOfPedPropDrawableVariations(ped, propId) - 1),
            textureMax = drawable < 0
                and 0
                or math.max(0, GetNumberOfPedPropTextureVariations(ped, propId, drawable) - 1),
        }
    end

    for overlayId = 0, 12 do
        limits.overlayMax[tostring(overlayId)] = math.max(0, GetNumHeadOverlayValues(overlayId) - 1)
    end
    return limits
end

local function updateCamera()
    local ped = ClothingCreator.previewPed
    if not ped or not DoesEntityExist(ped) then
        return
    end

    local coords = GetEntityCoords(ped)
    local camera = ClothingCreator.camera
    local angle = math.rad(camera.angle)
    local target = vector3(coords.x, coords.y, coords.z + camera.height)
    local position = vector3(
        target.x + math.sin(angle) * camera.distance,
        target.y + math.cos(angle) * camera.distance,
        target.z + 0.12
    )

    LobbyCam.Ensure()
    LobbyCam.SetTarget(position, target, 32.0, {
        idle = 0.0,
        snap = true,
        posK = 0.2,
        lookK = 0.2,
    })
end

function ClothingCreator.Push()
    if not ClothingCreator.open or ClothingCreator.draft == nil then
        return
    end

    exports["warv-ui"]:SetClothingCreator({
        outfits = Appearance.catalog.outfits,
        selectedId = ClothingCreator.selectedId,
        draft = ClothingCreator.draft,
        limits = buildLimits(),
        saving = ClothingCreator.saving,
        notice = ClothingCreator.notice,
    })
end

function ClothingCreator.Select(outfitId)
    local outfit = Appearance.Find(outfitId)
    if outfit == nil then
        return
    end

    ClothingCreator.selectedId = outfit.id
    ClothingCreator.draft = copy(outfit)
    ClothingCreator.notice = ""
    applyAppearance(ClothingCreator.draft.appearance)
    updateCameraHeightBounds()
    updateCamera()
    ClothingCreator.Push()
end

function ClothingCreator.New()
    local ped = ClothingCreator.previewPed or getSourcePed()
    ClearPedTasksImmediately(ped)
    SetPedDefaultComponentVariation(ped)
    for propId = 0, 7 do
        ClearPedProp(ped, propId)
    end

    local appearance = captureAppearance(ped)
    ClothingCreator.selectedId = nil
    ClothingCreator.draft = {
        name = "New Outfit",
        teams = {},
        appearance = appearance,
    }
    ClothingCreator.notice = ""
    applyAppearance(appearance)
    updateCameraHeightBounds()
    updateCamera()
    ClothingCreator.Push()
end

function ClothingCreator.Open(data)
    if ClothingCreator.open then
        return
    end

    Appearance.SetCatalog(data)

    ClothingCreator.open = true
    ClothingCreator.camera = {
        angle = 180.0,
        height = 1.0,
        distance = 2.8,
        minHeight = 0.05,
        maxHeight = 1.7,
    }
    hideLobbyPeds(true)

    local sourcePed = getSourcePed()
    local previewPed = ClonePed(sourcePed, false, true, false)
    setupPreviewEntity(previewPed, GetEntityCoords(sourcePed), GetEntityHeading(sourcePed))
    SetEntityVisible(sourcePed, false, false)
    ClothingCreator.previewPed = previewPed
    Wait(0)
    updateCameraHeightBounds()

    local firstOutfit = Appearance.catalog.outfits[1]
    if firstOutfit then
        ClothingCreator.Select(firstOutfit.id)
    else
        ClothingCreator.New()
    end

    UiHandler.CloseAllPages()
    UiHandler.SetPageActive("ui_clothing_creator")
end

function ClothingCreator.Close()
    if not ClothingCreator.open then
        return
    end

    ClothingCreator.open = false
    ClothingCreator.saving = false
    UiHandler.SetPageInactive("ui_clothing_creator")
    if ClothingCreator.previewPed and DoesEntityExist(ClothingCreator.previewPed) then
        DeleteEntity(ClothingCreator.previewPed)
    end
    ClothingCreator.previewPed = nil
    SetEntityVisible(getSourcePed(), true, false)
    hideLobbyPeds(false)
    LobbyPlacement.LoadPlayerSkin()
    LobbyPlacement.GoToMainLobby(true)
end

function ClothingCreator.HandleAction(payload)
    local action = payload and payload.action
    if action == "tab_clothing_creator" then
        if (tonumber(Lobby.playerData.perm) or 0) >= 2 then
            TriggerServerEvent("warv:clothing:requestOpen")
        end
        return
    end

    if not ClothingCreator.open then
        return
    end

    if action == "clothing_close" or (action and action:sub(1, 4) == "tab_") then
        ClothingCreator.Close()
        if action == "clothing_close" then
            UiHandler.SetPageActive("lobby")
        end
    elseif action == "clothing_select" then
        ClothingCreator.Select(payload.id)
    elseif action == "clothing_new" then
        ClothingCreator.New()
    elseif action == "clothing_revert" then
        if ClothingCreator.selectedId then
            ClothingCreator.Select(ClothingCreator.selectedId)
        end
    elseif action == "clothing_pose" then
        setPreviewPose(tostring(payload.pose or "idle"))
    elseif action == "clothing_teams" and type(payload.teams) == "table" then
        ClothingCreator.draft.teams = payload.teams
        if ClothingCreator.selectedId then
            TriggerServerEvent("warv:clothing:setTeams", ClothingCreator.selectedId, payload.teams)
        end
    elseif action == "clothing_apply" and type(payload.appearance) == "table" then
        local nextAppearance = copy(payload.appearance)
        local changed = resetDrawableDefaults(nextAppearance, ClothingCreator.draft.appearance)
        if applyAppearance(nextAppearance) then
            readAppliedDefaults(nextAppearance, changed)
            ClothingCreator.draft.name = tostring(payload.name or ClothingCreator.draft.name)
            ClothingCreator.draft.appearance = nextAppearance
            ClothingCreator.notice = ""
            if changed.any then
                ClothingCreator.Push()
            else
                exports["warv-ui"]:SetClothingLimits(buildLimits())
            end
        else
            ClothingCreator.Push()
        end
    elseif action == "clothing_save" and type(payload.outfit) == "table" then
        ClothingCreator.saving = true
        ClothingCreator.notice = ""
        ClothingCreator.Push()
        TriggerServerEvent("warv:clothing:save", payload.outfit)
    elseif action == "clothing_delete" then
        local outfitId = tostring(payload.id or ClothingCreator.selectedId or "")
        if outfitId == "" then
            return
        end
        ClothingCreator.saving = true
        ClothingCreator.Push()
        TriggerServerEvent("warv:clothing:delete", outfitId)
    end
end

AddEventHandler("warv-ui:menuAction", ClothingCreator.HandleAction)

AddEventHandler("warv-ui:clothingCamera", function(payload)
    if not ClothingCreator.open or type(payload) ~= "table" then
        return
    end

    ClothingCreator.camera.angle = ClothingCreator.camera.angle + (tonumber(payload.dx) or 0) * 0.08
    ClothingCreator.camera.height = math.max(
        ClothingCreator.camera.minHeight,
        math.min(
            ClothingCreator.camera.maxHeight,
            ClothingCreator.camera.height + (tonumber(payload.dy) or 0) * 0.00055
        )
    )
    ClothingCreator.camera.distance = math.max(
        1.1,
        math.min(5.0, ClothingCreator.camera.distance + (tonumber(payload.wheel) or 0) * 0.002)
    )
    updateCamera()
end)

RegisterNetEvent("warv:clothing:open")
AddEventHandler("warv:clothing:open", function(data)
    ClothingCreator.Open(data)
end)

RegisterNetEvent("warv:clothing:sync")
AddEventHandler("warv:clothing:sync", function()
    ClothingCreator.Push()
end)

RegisterNetEvent("warv:clothing:saveResult")
AddEventHandler("warv:clothing:saveResult", function(success, message, data, savedId)
    ClothingCreator.saving = false
    ClothingCreator.notice = tostring(message or "")
    Appearance.SetCatalog(data)
    if success and savedId then
        ClothingCreator.selectedId = savedId
        local savedOutfit = Appearance.Find(savedId)
        if savedOutfit then
            ClothingCreator.draft = copy(savedOutfit)
        end
    elseif success and not savedId then
        ClothingCreator.New()
    end
    ClothingCreator.Push()
end)
