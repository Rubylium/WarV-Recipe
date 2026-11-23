local usingGizmo = false
local gizmoCam = nil
local distanceLimit = nil
local initialCoords = nil
local gizmoCancelled = false

local isDraggingGizmo = false
local camTheta = 0.0
local camPhi = 1.5
local camRadius = 6.0
local camTarget = vector3(0, 0, 0)
local lastEntityCoords = vector3(0, 0, 0)
local gizmoZOffset = 0.5
local keepSeedRotation = false
local finalCameraState = nil
local activeCameraFov = 45.0

local function CartesianToSpherical(x, y, z)
    local r = math.sqrt(x*x + y*y + z*z)
    local theta = math.atan(y, x)
    local phi = math.acos(z / r)
    return r, theta, phi
end

local function SphericalToCartesian(radius, theta, phi)
    local x = radius * math.sin(phi) * math.cos(theta)
    local y = radius * math.sin(phi) * math.sin(theta)
    local z = radius * math.cos(phi)
    return vector3(x, y, z)
end

local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

local function normalizeFov(value)
    local fov = tonumber(value)
    if not fov or fov ~= fov or fov < 10.0 or fov > 120.0 then return nil end
    return fov + 0.0
end

local function toPlainVector3(value)
    if not value then return nil end

    return {
        x = value.x + 0.0,
        y = value.y + 0.0,
        z = value.z + 0.0,
    }
end

local function captureGizmoCameraState()
    if not gizmoCam then return nil end

    local okPosition, position = pcall(GetCamCoord, gizmoCam)
    local okRotation, rotation = pcall(GetCamRot, gizmoCam, 2)
    if not okPosition or not okRotation then return nil end

    return {
        position = toPlainVector3(position),
        rotation = toPlainVector3(rotation),
        fov = activeCameraFov,
    }
end

local function toGizmoPosition(position)
    return {
        x = position.x,
        y = position.y,
        z = position.z - gizmoZOffset
    }
end

local function fromGizmoPosition(position)
    return vector3(position.x, position.y, position.z + gizmoZOffset)
end

local function setEntityCoords(entity, position)
    SetEntityCoordsNoOffset(entity, position.x, position.y, position.z, false, false, false)
end

local function placeEntityOnGround(entity)
    if IsEntityAVehicle(entity) then
        SetVehicleOnGroundProperly(entity)
        return GetEntityCoords(entity)
    end

    if IsEntityAPed(entity) then
        local coords = GetEntityCoords(entity)
        local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 10.0, false)
        if foundGround then
            setEntityCoords(entity, vector3(coords.x, coords.y, groundZ))
        end
        return GetEntityCoords(entity)
    end

    PlaceObjectOnGroundProperly(entity)
    return GetEntityCoords(entity)
end

local function toggleNuiFrame(bool)
    usingGizmo = bool
    SetNuiFocus(bool, bool)

    if not bool and gizmoCam then
        DestroyCam(gizmoCam, false)
        RenderScriptCams(false, true, 500, true, true)
        gizmoCam = nil
    end
end

function useGizmo(handle, optionsOrLimit)
    if not DoesEntityExist(handle) then return end

    gizmoCancelled = false
    finalCameraState = nil

    if type(optionsOrLimit) == 'number' then
        distanceLimit = optionsOrLimit
    elseif type(optionsOrLimit) == 'table' then
        distanceLimit = tonumber(optionsOrLimit.distanceLimit or optionsOrLimit.limit or optionsOrLimit.gizmoDistanceLimit)
    else
        distanceLimit = nil
    end

    lastEntityCoords = GetEntityCoords(handle)
    initialCoords = lastEntityCoords
    camTarget = lastEntityCoords

    local cameraPosition = type(optionsOrLimit) == 'table' and optionsOrLimit.cameraPosition or nil
    local cameraRotation = type(optionsOrLimit) == 'table' and optionsOrLimit.cameraRotation or nil
    local camPos = cameraPosition and vector3(cameraPosition.x, cameraPosition.y, cameraPosition.z) or GetGameplayCamCoord()
    local requestedFov = type(optionsOrLimit) == 'table' and (optionsOrLimit.cameraFov or optionsOrLimit.fov) or nil
    local fov = normalizeFov(requestedFov) or normalizeFov(GetGameplayCamFov()) or 45.0
    activeCameraFov = fov
    local offset = camPos - lastEntityCoords
    local r, theta, phi = CartesianToSpherical(offset.x, offset.y, offset.z)
    camRadius = clamp(r, 2.0, 20.0)
    camTheta = theta
    camPhi = clamp(phi, 0.1, 3.0)

    gizmoCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(gizmoCam, camPos.x, camPos.y, camPos.z)
    SetCamFov(gizmoCam, fov)
    keepSeedRotation = type(cameraRotation) == 'table'
    if keepSeedRotation then
        SetCamRot(gizmoCam, cameraRotation.x + 0.0, cameraRotation.y + 0.0, cameraRotation.z + 0.0, 2)
    else
        PointCamAtCoord(gizmoCam, lastEntityCoords.x, lastEntityCoords.y, lastEntityCoords.z)
    end
    SetCamActive(gizmoCam, true)
    RenderScriptCams(true, false, 0, true, true)

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = handle,
            position = toGizmoPosition(lastEntityCoords),
            rotation = GetEntityRotation(handle, 2)
        }
    })

    toggleNuiFrame(true)

    while usingGizmo do
        if DoesEntityExist(handle) then
            local currentEntityCoords = GetEntityCoords(handle)

            if isDraggingGizmo then
                camTarget = camTarget
            else
                local dist = #(camTarget - currentEntityCoords)
                if dist > 0.01 then
                    camTarget = camTarget + (currentEntityCoords - camTarget) * 0.1
                end
            end

            local offset = SphericalToCartesian(camRadius, camTheta, camPhi)
            local newCamPos = camTarget + offset

            SetCamCoord(gizmoCam, newCamPos.x, newCamPos.y, newCamPos.z)

            if not isDraggingGizmo and not keepSeedRotation then
                PointCamAtCoord(gizmoCam, camTarget.x, camTarget.y, camTarget.z)
            end
        end

        SendNUIMessage({
            action = 'setCameraPosition',
            data = {
                position = GetCamCoord(gizmoCam),
                rotation = GetCamRot(gizmoCam, 2)
            }
        })

        Wait(0)
    end

    local cameraState = finalCameraState
    if not cameraState then cameraState = captureGizmoCameraState() end

    return {
        handle = handle,
        position = GetEntityCoords(handle),
        rotation = GetEntityRotation(handle, 2),
        cameraPosition = cameraState and cameraState.position or nil,
        cameraRotation = cameraState and cameraState.rotation or nil,
        cameraFov = cameraState and cameraState.fov or nil,
        cancelled = gizmoCancelled,
        canceled = gizmoCancelled,
        confirmed = not gizmoCancelled,
    }
end

local function isGizmoActive()
    return usingGizmo
end

RegisterNUICallback('rotateCamera', function(data, cb)
    if not usingGizmo then return end
    keepSeedRotation = false

    local sensitivity = 0.005
    camTheta = camTheta - (data.x * sensitivity)
    camPhi = camPhi - (data.y * sensitivity)

    camPhi = clamp(camPhi, 0.1, 3.1)

    cb('ok')
end)

RegisterNUICallback('zoomCamera', function(data, cb)
    if not usingGizmo then return end

    local zoomSpeed = 1.0
    if data.delta > 0 then
        camRadius = camRadius + zoomSpeed
    else
        camRadius = camRadius - zoomSpeed
    end

    camRadius = clamp(camRadius, 2.0, 20.0)
    cb('ok')
end)

RegisterNUICallback('setGizmoDragging', function(data, cb)
    isDraggingGizmo = data.dragging
    cb('ok')
end)

RegisterNUICallback('moveEntity', function(data, cb)
    local entity = data.handle
    local position = fromGizmoPosition(data.position)
    local rotation = data.rotation
    local limitReached = false

    if distanceLimit and initialCoords then
        local dist = #(position - initialCoords)
        if dist > distanceLimit then
            limitReached = true
            local dir = position - initialCoords
            dir = dir / dist * distanceLimit
            position = initialCoords + dir
        end
    end

    setEntityCoords(entity, position)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = entity,
            position = toGizmoPosition(position),
            rotation = rotation,
            limitReached = limitReached
        }
    })

    cb('ok')
end)

RegisterNUICallback('placeOnGround', function(data, cb)
    local entity = data.handle
    local position = placeEntityOnGround(entity)

    local rotation = GetEntityRotation(entity, 2)
    local limitReached = false

    if distanceLimit and initialCoords then
        local dist = #(position - initialCoords)
        if dist > distanceLimit then
            limitReached = true
            local dir = position - initialCoords
            dir = dir / dist * distanceLimit
            position = initialCoords + dir
            setEntityCoords(entity, position)
            position = placeEntityOnGround(entity)
        end
    end

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = entity,
            position = toGizmoPosition(position),
            rotation = rotation,
            limitReached = limitReached
        }
    })
    cb('ok')
end)

RegisterNUICallback('finishEdit', function(data, cb)
    gizmoCancelled = (type(data) == 'table' and (data.cancelled == true or data.canceled == true)) or false
    usingGizmo = false
    finalCameraState = captureGizmoCameraState()

    toggleNuiFrame(false)
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    cb('ok')
end)

exports("useGizmo", useGizmo)
exports("isGizmoActive", isGizmoActive)
