PropLobby = {}
PropLobby.peds = {}
PropLobby.weapon = 0
PropLobby.session = 0

local previewModel = "a_m_y_hipster_01"
local previewWeapon = "WEAPON_CARBINERIFLE"
local pickRadius = 0.035

PropLobby.CamLabels = {
    main = "Main lobby",
    streaks = "Scorestreaks",
    skin = "Player skin",
}

local colors = {
    me = { 90, 210, 130 },
    slot = { 90, 160, 255 },
    cam = { 233, 118, 12 },
    look = { 255, 220, 80 },
    weapon = { 190, 120, 255 },
}

function PropLobby.Data()
    return PropEditor.data and PropEditor.data.lobby or nil
end

function PropLobby.Kind(id)
    return tostring(id or ""):match("^[^:]+") or ""
end

function PropLobby.Pose(id)
    local lobby = PropLobby.Data()
    if not lobby then return nil end

    local kind = PropLobby.Kind(id)
    if kind == "me" then return lobby.me end
    if kind == "weapon" then return lobby.weapon end
    if kind == "slot" then return lobby.slots[tonumber(id:match(":(%d+)")) or 0] end
    if kind == "cam" or kind == "look" then return lobby.cams[id:match(":(.+)")] end
    return nil
end

function PropLobby.Ground(id, spot)
    local kind = PropLobby.Kind(id)
    if kind == "weapon" then return spot + vector3(0.0, 0.0, 0.35) end
    if kind ~= "me" and kind ~= "slot" then return spot end

    local found, ground = GetGroundZFor_3dCoord(spot.x, spot.y, spot.z + 1.0, false)
    if found and math.abs(ground - spot.z) < 0.6 then
        return vector3(spot.x, spot.y, ground)
    end
    return spot
end

function PropLobby.HandlePos(id)
    local pose = PropLobby.Pose(id)
    if not pose then return nil end
    if PropLobby.Kind(id) == "look" then return vector3(pose.tx, pose.ty, pose.tz) end
    return vector3(pose.x, pose.y, pose.z)
end

function PropLobby.SetPos(id, pos)
    local pose = PropLobby.Pose(id)
    if not pose then return end

    if PropLobby.Kind(id) == "look" then
        pose.tx, pose.ty, pose.tz = pos.x, pos.y, pos.z
    else
        pose.x, pose.y, pose.z = pos.x, pos.y, pos.z
    end
    pose.set = true
    PropLobby.SyncPeds()
end

function PropLobby.Handles()
    local lobby = PropLobby.Data()
    if not (lobby and lobby.enabled) then return {} end

    local handles = {}
    local function add(id, color)
        handles[#handles + 1] = { id = id, label = PropLobby.Label(id), color = color }
    end

    if lobby.me.set then add("me", colors.me) end
    for index, slot in ipairs(lobby.slots) do
        if slot.set then add("slot:" .. index, colors.slot) end
    end
    for _, key in ipairs(PropMapStore.CamKeys) do
        if lobby.cams[key].set then
            add("cam:" .. key, colors.cam)
            add("look:" .. key, colors.look)
        end
    end
    if lobby.weapon.set then add("weapon", colors.weapon) end
    return handles
end

function PropLobby.Pick()
    local best, bestDistance = nil, pickRadius
    local cursor = PropEditorCam.Cursor()

    for _, handle in ipairs(PropLobby.Handles()) do
        local pos = PropLobby.HandlePos(handle.id)
        local ok, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z)
        if ok then
            local dx, dy = sx - cursor.x, sy - cursor.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < bestDistance then
                best, bestDistance = handle.id, distance
            end
        end
    end
    return best
end

function PropLobby.Draw()
    local lobby = PropLobby.Data()
    if not (lobby and lobby.enabled) then return end

    local selected = PropEditor.selection and PropEditor.selection.handle
    for _, handle in ipairs(PropLobby.Handles()) do
        local pos = PropLobby.HandlePos(handle.id)
        local color = handle.color
        local alpha = handle.id == selected and 255 or 150
        local size = handle.id == selected and 0.28 or 0.2

        DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            size, size, size, color[1], color[2], color[3], alpha, false, false, 2, false, nil, nil, false)
    end

    for _, key in ipairs(PropMapStore.CamKeys) do
        local cam = lobby.cams[key]
        if cam.set then
            DrawLine(cam.x, cam.y, cam.z, cam.tx, cam.ty, cam.tz, colors.cam[1], colors.cam[2], colors.cam[3], 200)
        end
    end

    if lobby.me.set then PropLobby.DrawHeading(lobby.me, colors.me) end
    for _, slot in ipairs(lobby.slots) do
        if slot.set then PropLobby.DrawHeading(slot, colors.slot) end
    end
    if lobby.weapon.set then PropLobby.DrawHeading(lobby.weapon, colors.weapon) end
end

function PropLobby.DrawHeading(pose, color)
    local radians = math.rad(pose.h)
    local tip = vector3(pose.x - math.sin(radians) * 1.2, pose.y + math.cos(radians) * 1.2, pose.z + 0.1)
    DrawLine(pose.x, pose.y, pose.z + 0.1, tip.x, tip.y, tip.z, color[1], color[2], color[3], 220)
end

local function lockPreview(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
end

local function spawnPreview(pose)
    local hash = GetHashKey(previewModel)
    if not PropMap.Request(hash) then return 0 end

    local ped = CreatePed(4, hash, pose.x, pose.y, pose.z, pose.h, false, false)
    PropMap.Place(ped, pose.x, pose.y, pose.z)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityAlpha(ped, 200, false)
    SetModelAsNoLongerNeeded(hash)
    LobbyLayout.PlayPose(ped, pose, true)
    lockPreview(ped)
    return ped
end

local function spawnWeaponPreview(pose)
    local hash = GetHashKey(previewWeapon)
    RequestWeaponAsset(hash, 31, 0)
    local deadline = GetGameTimer() + 4000
    while not HasWeaponAssetLoaded(hash) and GetGameTimer() < deadline do Wait(0) end
    if not HasWeaponAssetLoaded(hash) then return 0 end

    local obj = CreateWeaponObject(hash, 50, pose.x, pose.y, pose.z, true, 1.0, 0)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityRotation(obj, 0.0, 0.0, pose.h, 2, false)
    return obj
end

local weaponPending = false

function PropLobby.SyncWeapon()
    local lobby = PropLobby.Data()
    local pose = lobby and lobby.enabled and lobby.weapon.set and lobby.weapon

    if not pose then
        PropMap.Delete(PropLobby.weapon)
        PropLobby.weapon = 0
        return
    end

    if PropLobby.weapon ~= 0 and DoesEntityExist(PropLobby.weapon) then
        SetEntityCoordsNoOffset(PropLobby.weapon, pose.x, pose.y, pose.z, false, false, false)
        SetEntityRotation(PropLobby.weapon, 0.0, 0.0, pose.h, 2, false)
        return
    end

    if weaponPending then return end
    weaponPending = true
    local session = PropLobby.session
    Citizen.CreateThread(function()
        local obj = spawnWeaponPreview(pose)
        weaponPending = false
        if session == PropLobby.session then
            PropLobby.weapon = obj
        else
            PropMap.Delete(obj)
        end
    end)
end

function PropLobby.ApplyEnv()
    local lobby = PropLobby.Data()
    local env = lobby and lobby.enabled and lobby.env.set and lobby.env
    if env then
        MapEnv.Set(env.hour, env.minute, env.weather)
        return
    end
    MapEnv.Lobby()
end

function PropLobby.ClearPeds()
    PropLobby.session = PropLobby.session + 1
    for _, ped in pairs(PropLobby.peds) do PropMap.Delete(ped) end
    PropLobby.peds = {}
    PropMap.Delete(PropLobby.weapon)
    PropLobby.weapon = 0
end

function PropLobby.SyncPeds()
    local lobby = PropLobby.Data()
    if not (lobby and lobby.enabled) then
        PropLobby.ClearPeds()
        return
    end
    PropLobby.SyncWeapon()

    local wanted = {}
    if lobby.me.set then wanted.me = lobby.me end
    for index, slot in ipairs(lobby.slots) do
        if slot.set then wanted["slot:" .. index] = slot end
    end

    for id, ped in pairs(PropLobby.peds) do
        if not wanted[id] then
            PropMap.Delete(ped)
            PropLobby.peds[id] = nil
        end
    end

    for id, pose in pairs(wanted) do
        local ped = PropLobby.peds[id]
        if not (ped and DoesEntityExist(ped)) then
            local session = PropLobby.session
            local spawned = spawnPreview(pose)
            if session == PropLobby.session then
                PropLobby.peds[id] = spawned
            else
                PropMap.Delete(spawned)
                return
            end
        else
            PropMap.Place(ped, pose.x, pose.y, pose.z)
            SetEntityHeading(ped, pose.h)
        end
    end
end

function PropLobby.Restyle(id)
    local pose = PropLobby.Pose(id)
    local ped = PropLobby.peds[id]
    if not (pose and ped and DoesEntityExist(ped)) then return end
    LobbyLayout.PlayPose(ped, pose, true)
    lockPreview(ped)
    PropMap.Place(ped, pose.x, pose.y, pose.z)
    SetEntityHeading(ped, pose.h)
end

function PropLobby.Payload()
    local lobby = PropLobby.Data()
    if not lobby then return nil end

    local slots = {}
    for index, slot in ipairs(lobby.slots) do
        slots[#slots + 1] = { index = index, set = slot.set, scenario = slot.scenario }
    end

    local cams = {}
    for _, key in ipairs(PropMapStore.CamKeys) do
        local cam = lobby.cams[key]
        cams[#cams + 1] = { key = key, label = PropLobby.CamLabels[key], set = cam.set, fov = cam.fov, idle = cam.idle }
    end

    return {
        enabled = lobby.enabled,
        meSet = lobby.me.set,
        weaponSet = lobby.weapon.set,
        slots = slots,
        cams = cams,
        env = lobby.env,
        weathers = MapEnv.Weathers,
        scenarios = PropEditor.Scenarios,
    }
end

function PropLobby.Selection()
    local id = PropEditor.selection and PropEditor.selection.handle
    local pose = id and PropLobby.Pose(id)
    if not pose then return nil end

    local kind = PropLobby.Kind(id)
    local payload = { handle = id, kind = kind, label = PropLobby.Label(id) }

    if kind == "cam" or kind == "look" then
        payload.x, payload.y, payload.z = pose.x, pose.y, pose.z
        payload.tx, payload.ty, payload.tz = pose.tx, pose.ty, pose.tz
        payload.fov, payload.idle = pose.fov, pose.idle
        payload.dof, payload.dofStrength = pose.dof, pose.dofStrength
        payload.dofNear, payload.dofFar = pose.dofNear, pose.dofFar
        payload.camKey = id:match(":(.+)")
        return payload
    end

    payload.x, payload.y, payload.z, payload.h = pose.x, pose.y, pose.z, pose.h
    payload.scenario, payload.dict, payload.anim = pose.scenario, pose.dict, pose.anim
    payload.posed = kind == "me" or kind == "slot"
    payload.turnable = true
    payload.scenarios = PropEditor.Scenarios
    return payload
end

function PropLobby.Label(id)
    local kind = PropLobby.Kind(id)
    if kind == "me" then return "Me" end
    if kind == "weapon" then return "Weapon stand" end
    if kind == "slot" then return "Player " .. (id:match(":(%d+)") or "") end

    local label = PropLobby.CamLabels[id:match(":(.+)")] or id
    return kind == "look" and (label .. " target") or label
end
