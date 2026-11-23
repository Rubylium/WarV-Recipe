PropMap = {}
PropMap.loaded = {}
PropMap.hideRadius = 1.25

function PropMap.Hash(model)
    if type(model) == "number" then return math.floor(model) end
    return GetHashKey(tostring(model or ""))
end

function PropMap.Request(hash)
    if not IsModelValid(hash) then return false end
    if HasModelLoaded(hash) then return true end

    RequestModel(hash)
    local deadline = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(0) end
    return HasModelLoaded(hash)
end

function PropMap.Kind(hash)
    if IsModelAVehicle(hash) then return "vehicle" end
    if IsModelAPed(hash) then return "ped" end
    return "prop"
end

function PropMap.PlayAnim(entity, dict, anim)
    if dict == "" or anim == "" then return end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 4000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    if not HasAnimDictLoaded(dict) then return end
    TaskPlayAnim(entity, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

function PropMap.ApplyPed(entity, settings)
    settings = settings or {}
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanRagdoll(entity, false)
    SetPedDiesWhenInjured(entity, false)
    SetPedFleeAttributes(entity, 0, false)
    SetPedCombatAttributes(entity, 46, true)
    SetEntityInvincible(entity, true)
    LobbyLayout.PlayPose(entity, settings, true)
end

function PropMap.ApplyVehicle(entity, settings)
    settings = settings or {}
    SetVehicleModKit(entity, 0)
    SetVehicleColours(entity, settings.primary, settings.secondary)
    SetVehicleExtraColours(entity, settings.pearl, settings.wheelColor)
    SetVehicleInteriorColour(entity, settings.interior)
    SetVehicleDashboardColour(entity, settings.dashboard)
    SetVehicleWheelType(entity, settings.wheelType)
    SetVehicleWindowTint(entity, settings.windowTint)
    SetVehicleNumberPlateTextIndex(entity, settings.plateStyle)
    SetVehicleDirtLevel(entity, settings.dirt + 0.0)
    if settings.plate ~= "" then SetVehicleNumberPlateText(entity, settings.plate) end
    SetVehicleLivery(entity, settings.livery)

    for _, slot in ipairs(settings.mods or {}) do
        if slot.value < 0 then
            RemoveVehicleMod(entity, slot.id)
        else
            SetVehicleMod(entity, slot.id, slot.value, false)
        end
    end
    for _, slot in ipairs(settings.toggles or {}) do
        ToggleVehicleMod(entity, slot.id, slot.on)
    end
    for _, slot in ipairs(settings.extras or {}) do
        SetVehicleExtra(entity, slot.id, not slot.on)
    end

    local neon = settings.neon or {}
    SetVehicleNeonLightsColour(entity, neon.r or 255, neon.g or 255, neon.b or 255)
    for index = 0, 3 do
        SetVehicleNeonLightEnabled(entity, index, settings.neonOn == true)
    end

    local smoke = settings.tyreSmoke or {}
    SetVehicleTyreSmokeColor(entity, smoke.r or 255, smoke.g or 255, smoke.b or 255)
    SetVehicleTyresCanBurst(entity, not settings.bulletproof)
    SetVehicleEngineOn(entity, settings.engineOn == true, true, true)
    SetVehicleLights(entity, settings.lights and 2 or 1)
    SetVehicleFullbeam(entity, settings.highBeams == true)
    SetVehicleSiren(entity, settings.siren == true)

    for _, slot in ipairs(settings.doors or {}) do
        if slot.on then
            SetVehicleDoorOpen(entity, slot.id, false, true)
        else
            SetVehicleDoorShut(entity, slot.id, true)
        end
    end
    for _, slot in ipairs(settings.windows or {}) do
        if slot.on then
            RollDownWindow(entity, slot.id)
        else
            RollUpWindow(entity, slot.id)
        end
    end

    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
end

function PropMap.Spawn(entry)
    local hash = PropMap.Hash(entry.model)
    if not PropMap.Request(hash) then return 0 end

    local x, y, z = entry.x + 0.0, entry.y + 0.0, entry.z + 0.0
    local entity

    if entry.kind == "ped" then
        entity = CreatePed(4, hash, x, y, z, entry.rz + 0.0, false, false)
        PropMap.ApplyPed(entity, entry.ped)
    elseif entry.kind == "vehicle" then
        entity = CreateVehicle(hash, x, y, z, entry.rz + 0.0, false, false)
        PropMap.ApplyVehicle(entity, entry.vehicle)
    else
        entity = CreateObjectNoOffset(hash, x, y, z, false, false, false)
        FreezeEntityPosition(entity, true)
        SetEntityInvincible(entity, true)
    end

    PropMap.Place(entity, x, y, z)
    SetEntityRotation(entity, entry.rx + 0.0, entry.ry + 0.0, entry.rz + 0.0, 2, true)
    SetEntityLodDist(entity, 4000)
    SetModelAsNoLongerNeeded(hash)
    return entity
end

function PropMap.Place(entity, x, y, z)
    if IsEntityAPed(entity) then
        SetEntityCoords(entity, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
        return
    end
    SetEntityCoordsNoOffset(entity, x + 0.0, y + 0.0, z + 0.0, false, false, false)
end

function PropMap.Hide(entry)
    CreateModelHideExcludingScriptObjects(entry.x + 0.0, entry.y + 0.0, entry.z + 0.0, PropMap.hideRadius, PropMap.Hash(entry.model), false)
end

function PropMap.Reveal(entry)
    RemoveModelHide(entry.x + 0.0, entry.y + 0.0, entry.z + 0.0, PropMap.hideRadius, PropMap.Hash(entry.model), false)
end

function PropMap.Delete(entity)
    if not DoesEntityExist(entity) then return end
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

function PropMap.IsLoaded(name)
    return PropMap.loaded[PropMapStore.Key(name)] ~= nil
end

function PropMap.IsAlive(name)
    local session = PropMap.loaded[PropMapStore.Key(name)]
    if not session then return false end
    for _, entity in ipairs(session.entities) do
        if not DoesEntityExist(entity) then return false end
    end
    return true
end

function PropMap.Load(name)
    local key = PropMapStore.Key(name)
    local map = PropMapStore.Get(key)
    if not map or PropMap.loaded[key] then return false end

    local session = { entities = {}, hidden = map.hidden or {} }
    PropMap.loaded[key] = session

    Citizen.CreateThread(function()
        for _, entry in ipairs(map.props or {}) do
            if PropMap.loaded[key] ~= session then return end
            local entity = PropMap.Spawn(entry)
            if entity ~= 0 then session.entities[#session.entities + 1] = entity end
            Wait(0)
        end
        if PropMap.loaded[key] ~= session then return end
        for _, entry in ipairs(session.hidden) do PropMap.Hide(entry) end
    end)
    return true
end

function PropMap.Unload(name)
    local key = PropMapStore.Key(name)
    local session = PropMap.loaded[key]
    if not session then return false end
    PropMap.loaded[key] = nil

    for _, entity in ipairs(session.entities) do PropMap.Delete(entity) end
    for _, entry in ipairs(session.hidden) do PropMap.Reveal(entry) end
    return true
end

function PropMap.UnloadAll()
    for name in pairs(PropMap.loaded) do PropMap.Unload(name) end
end

RegisterNetEvent("warv:PropMapUpdated", function(name, map)
    local key = PropMapStore.Key(name)
    local wasLoaded = PropMap.IsLoaded(key)
    if wasLoaded then PropMap.Unload(key) end
    PropMapStore.Set(key, map)
    if wasLoaded and map then PropMap.Load(key) end
    if not PropEditor.active then LobbyLayout.Apply() end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then PropMap.UnloadAll() end
end)
