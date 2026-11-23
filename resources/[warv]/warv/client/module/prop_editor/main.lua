local undoStack = {}
local returnPos = nil
local returnVisible = true
local returnLobbyCam = false
local pressed = nil
local dragThreshold = 0.006

local function canEdit()
    return (tonumber(Lobby.playerData.perm) or 0) >= 3
end

local function snapshot()
    undoStack[#undoStack + 1] = json.encode(PropMapStore.Clean(PropEditor.mapName, PropEditor.data))
    if #undoStack > 30 then table.remove(undoStack, 1) end
    PropEditor.dirty = true
end

local function selected()
    local selection = PropEditor.selection
    if not (selection and selection.index) then return nil end
    return PropEditor.data.props[selection.index], selection.index
end

local function upsert(list, id, key, value)
    for _, slot in ipairs(list) do
        if slot.id == id then
            slot[key] = value
            return
        end
    end
    list[#list + 1] = { id = id, [key] = value }
end

function PropEditor.Cards()
    local cards = {}
    for _, name in ipairs(PropMapStore.Names()) do
        local map = PropMaps[name]
        local peds, vehicles = 0, 0
        for _, entry in ipairs(map.props or {}) do
            if entry.kind == "ped" then peds = peds + 1 end
            if entry.kind == "vehicle" then vehicles = vehicles + 1 end
        end
        cards[#cards + 1] = {
            name = name,
            props = #(map.props or {}) - peds - vehicles,
            peds = peds,
            vehicles = vehicles,
            hidden = #(map.hidden or {}),
            live = PropMap.IsLoaded(name),
        }
    end
    return cards
end

local function selectionPayload()
    local selection = PropEditor.selection
    if not selection then return nil end
    if selection.handle then return nil end

    if not selection.index then
        local entity = selection.entity
        if not (entity and DoesEntityExist(entity)) then return nil end
        local pos = GetEntityCoords(entity)
        local rot = GetEntityRotation(entity, 2)
        return {
            index = 0,
            kind = "world",
            model = PropEditor.ModelName(GetEntityModel(entity)),
            mine = false,
            favorite = false,
            x = pos.x, y = pos.y, z = pos.z,
            rx = rot.x, ry = rot.y, rz = rot.z,
        }
    end

    local index = selection.index
    local entry = PropEditor.data.props[index]
    if not entry then return nil end

    local payload = {
        index = index,
        kind = entry.kind,
        model = PropEditor.ModelName(entry.model),
        mine = true,
        favorite = PropEditor.IsFavorite(entry.model),
        x = entry.x, y = entry.y, z = entry.z,
        rx = entry.rx, ry = entry.ry, rz = entry.rz,
    }

    if entry.kind == "ped" then
        payload.ped = entry.ped
        payload.scenarios = PropEditor.Scenarios
    elseif entry.kind == "vehicle" then
        local mods, toggles, extras = PropEntities.ModOptions(index)
        payload.vehicle = entry.vehicle
        payload.mods = mods
        payload.toggles = toggles
        payload.extras = extras
        payload.doors = PropEditor.FlagList(PropEditor.Doors, entry.vehicle.doors)
        payload.windows = PropEditor.FlagList(PropEditor.Windows, entry.vehicle.windows)
        payload.wheelTypes = PropEditor.WheelTypes
    end
    return payload
end

function PropEditor.PushLive()
    if not (PropEditor.active and PropEditor.mode == "edit") then return end
    exports['warv-ui']:SetPropEditorLive({
        selection = selectionPayload(),
        handle = PropLobby.Selection(),
        placing = PropEditor.placing ~= nil,
        preview = PropEditor.preview or "",
        gizmo = PropEditor.gizmo ~= nil,
        looking = PropEditorCam.looking,
        speed = math.floor(PropEditorCam.speed),
        dirty = PropEditor.dirty,
    })
end

local function row(index, kind, entry)
    return {
        index = index,
        kind = kind,
        model = PropEditor.ModelName(entry.model),
        x = math.floor(entry.x * 10) / 10,
        y = math.floor(entry.y * 10) / 10,
        z = math.floor(entry.z * 10) / 10,
    }
end

function PropEditor.Push()
    if not PropEditor.active then return end

    if PropEditor.mode == "pick" then
        exports['warv-ui']:SetPropEditor({
            mode = "pick",
            mapName = "",
            cards = PropEditor.Cards(),
            props = {},
            hidden = {},
            history = PropEditor.history,
            favorites = PropEditor.favorites,
            selection = nil,
            placing = false,
            dirty = false,
            speed = 0,
            status = PropEditor.status,
        })
        return
    end

    local props = {}
    for index, entry in ipairs(PropEditor.data.props) do
        props[#props + 1] = row(index, entry.kind, entry)
    end

    local hidden = {}
    for index, entry in ipairs(PropEditor.data.hidden) do
        hidden[#hidden + 1] = row(index, "prop", entry)
    end

    exports['warv-ui']:SetPropEditor({
        mode = "edit",
        mapName = PropEditor.mapName,
        cards = {},
        props = props,
        hidden = hidden,
        history = PropEditor.history,
        favorites = PropEditor.favorites,
        selection = selectionPayload(),
        lobby = PropLobby.Payload(),
        placing = PropEditor.placing ~= nil,
        dirty = PropEditor.dirty,
        speed = math.floor(PropEditorCam.speed),
        status = PropEditor.status,
    })
    PropEditor.PushLive()
end

local function notify(message)
    PropEditor.status = message or ""
    PropEditor.Push()
end

local function hidePlayer()
    local ped = PlayerPedId()
    if not returnPos then
        returnPos = GetEntityCoords(ped)
        returnVisible = IsEntityVisible(ped)
    end
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
end

local function restorePlayer()
    local ped = PlayerPedId()
    if returnPos then
        SetEntityCoordsNoOffset(ped, returnPos.x, returnPos.y, returnPos.z, false, false, false)
        returnPos = nil
    end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, returnVisible, false)
end

local function streamAround(pos)
    SetEntityCoordsNoOffset(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false)
    SetFocusArea(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
end

function PropEditor.Enter()
    if not canEdit() then return end
    PropEditor.active = true
    PropEditor.mode = "pick"
    PropEditor.mapName = ""
    PropEditor.data = nil
    PropEditor.status = ""
    UiHandler.SetPageActive("ui_prop_editor")
    PropEditor.Push()
end

function PropEditor.Open(name)
    if not canEdit() then return end
    local key = PropMapStore.Key(name)
    local map = PropMapStore.Get(key)
    if not map then return end

    if PropMap.IsLoaded(key) then PropMap.Unload(key) end

    PropEditor.mapName = key
    PropEditor.data = PropMapStore.Clean(key, map)
    PropEditor.selection = nil
    PropEditor.placing = nil
    PropEditor.hover = nil
    PropEditor.dirty = false
    PropEditor.typing = false
    PropEditor.status = ""
    undoStack = {}

    local first = PropEditor.data.props[1]
    local pos = first and vector3(first.x, first.y, first.z + 6.0) or GetEntityCoords(PlayerPedId())

    PropEditor.active = true
    PropEditor.mode = "edit"
    returnLobbyCam = LobbyCam.rendering == true
    UiHandler.SetPageActive("ui_prop_editor")

    Citizen.CreateThread(function()
        hidePlayer()
        streamAround(pos)

        local deadline = GetGameTimer() + 5000
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < deadline do
            RequestCollisionAtCoord(pos.x, pos.y, pos.z)
            Wait(0)
        end

        if not (PropEditor.active and PropEditor.data and PropEditor.mapName == key) then return end

        PropEditorCam.Start(pos, GetEntityHeading(PlayerPedId()))
        PropEntities.Rebuild()
        PropEntities.HideAll()
        PropLobby.SyncPeds()
        PropLobby.ApplyEnv()
        PropEditor.Push()
    end)
end

function PropEditor.Create(name)
    if not canEdit() then return end
    local key = PropMapStore.Key(name)
    if key == "" then return end
    if PropMapStore.Get(key) then
        notify("MAP ALREADY EXISTS")
        return
    end

    PropMapStore.Set(key, { props = {}, hidden = {} })
    PropEditor.Open(key)
end

function PropEditor.DeleteMap(name)
    if not canEdit() then return end
    local key = PropMapStore.Key(name)
    if not PropMapStore.Get(key) then return end
    if PropMap.IsLoaded(key) then PropMap.Unload(key) end

    TriggerServerEvent("warv:DeletePropMap", key)
    PropMapStore.Set(key, nil)
    notify("DELETED " .. key)
end

local function teardown()
    PropEditor.PreviewStop()
    PropEditor.CancelPlacing()
    PropLobby.ClearPeds()
    PropEntities.Clear()
    if PropEditor.data then PropEntities.RevealAll() end
    PropEditorCam.Stop()
    PropEditor.selection = nil
    PropEditor.hover = nil
    PropEditor.typing = false
    pressed = nil
end

function PropEditor.Back()
    if not (PropEditor.active and PropEditor.mode == "edit") then return end
    teardown()
    restorePlayer()
    PropEditor.mode = "pick"
    PropEditor.mapName = ""
    PropEditor.data = nil
    PropEditor.dirty = false
    PropEditor.Push()
end

function PropEditor.Close()
    if not PropEditor.active then return end
    if PropEditor.mode == "edit" then
        teardown()
        restorePlayer()
    end

    PropEditor.active = false
    PropEditor.mode = "pick"
    PropEditor.mapName = ""
    PropEditor.data = nil
    PropEditor.dirty = false
    UiHandler.SetPageInactive("ui_prop_editor")

    if returnLobbyCam then
        LobbyLayout.Refresh()
        LobbyPlacement.StartCam()
        LobbyPlacement.GoToMainLobby(true)
        PlayersDisplay.SyncMyWeapon()
    end
    returnLobbyCam = false
end

function PropEditor.Save()
    if not (PropEditor.active and PropEditor.mode == "edit" and canEdit()) then return end
    local clean = PropMapStore.Clean(PropEditor.mapName, PropEditor.data)
    TriggerServerEvent("warv:SavePropMap", PropEditor.mapName, clean)
    PropMapStore.Set(PropEditor.mapName, clean)
    PropEditor.dirty = false
    notify("SAVED " .. PropEditor.mapName)
end

function PropEditor.Undo()
    local previous = table.remove(undoStack)
    if not previous then return end

    PropEditor.CancelPlacing()
    PropEntities.RevealAll()

    PropEditor.data = PropMapStore.Clean(PropEditor.mapName, json.decode(previous))
    PropEditor.selection = nil
    PropEntities.Rebuild()
    PropEntities.HideAll()
    PropLobby.SyncPeds()
    PropEditor.dirty = true
    PropEditor.Push()
end

function PropEditor.StartPlacing(target, spawn)
    if type(target) == "string" then
        local pos = PropLobby.HandlePos(target)
        if not pos then return end
        PropEditor.placing = {
            handle = target,
            lift = 0.0,
            distance = math.max(1.0, #(pos - PropEditorCam.pos)),
            origin = { x = pos.x, y = pos.y, z = pos.z },
        }
        PropEditor.selection = { handle = target }
        return
    end

    local entry = PropEditor.data.props[target]
    if not entry then return end
    PropEditor.placing = {
        index = target,
        spawn = spawn == true,
        lift = 0.0,
        origin = { x = entry.x, y = entry.y, z = entry.z, rx = entry.rx, ry = entry.ry, rz = entry.rz },
    }
    PropEditor.selection = { index = target }
end

function PropEditor.CommitPlacing()
    local placing = PropEditor.placing
    if not placing then return end
    PropEditor.placing = nil

    if not placing.handle then
        local entry = PropEditor.data.props[placing.index]
        if entry and type(entry.model) == "string" then PropEditor.PushHistory(entry.model) end
    end
    PropEditor.dirty = true
    PropEditor.Push()
end

function PropEditor.CancelPlacing()
    local placing = PropEditor.placing
    if not placing then return end
    PropEditor.placing = nil

    if placing.handle then
        PropLobby.SetPos(placing.handle, vector3(placing.origin.x, placing.origin.y, placing.origin.z))
    elseif placing.spawn then
        PropEntities.Remove(placing.index)
        PropEditor.selection = nil
    else
        local entry = PropEditor.data.props[placing.index]
        if entry then
            entry.x, entry.y, entry.z = placing.origin.x, placing.origin.y, placing.origin.z
            entry.rx, entry.ry, entry.rz = placing.origin.rx, placing.origin.ry, placing.origin.rz
            PropEntities.Apply(placing.index)
        end
    end
    PropEditor.Push()
end

function PropEditor.Add(model)
    if not PropEditor.data then return end
    model = tostring(model or ""):lower():gsub("%s", "")
    if model == "" then return end

    local hash = GetHashKey(model)
    if not IsModelValid(hash) then
        notify("UNKNOWN MODEL " .. model:upper())
        return
    end

    local origin, dir = PropEditorCam.Ray()
    local spot = origin and (origin + dir * 6.0) or PropEditorCam.pos

    snapshot()
    local index = PropEntities.Add(PropMapStore.Entry({
        kind = PropMap.Kind(hash),
        model = model,
        x = spot.x, y = spot.y, z = spot.z,
    }))

    if PropEntities.list[index] == 0 then
        table.remove(PropEditor.data.props, index)
        table.remove(PropEntities.list, index)
        notify("MODEL FAILED TO LOAD")
        return
    end

    PropEditor.StartPlacing(index, true)
    notify("")
end

local function worldEntry(entity)
    local pos = GetEntityCoords(entity)
    local rot = GetEntityRotation(entity, 2)
    return PropMapStore.Entry({
        kind = "prop",
        model = GetEntityModel(entity),
        x = pos.x, y = pos.y, z = pos.z,
        rx = rot.x, ry = rot.y, rz = rot.z,
    })
end

local function hideWorld(entity)
    local pos = GetEntityCoords(entity)
    local entry = { model = GetEntityModel(entity), x = pos.x, y = pos.y, z = pos.z }
    PropEditor.data.hidden[#PropEditor.data.hidden + 1] = entry
    PropMap.Hide(entry)
end

function PropEditor.Adopt(entity)
    snapshot()
    local index = PropEntities.Add(worldEntry(entity))
    hideWorld(entity)
    return index
end

function PropEditor.Grab()
    local selection = PropEditor.selection
    if selection and selection.handle then
        snapshot()
        PropEditor.StartPlacing(selection.handle, false)
        PropEditor.Push()
        return
    end

    local entry, index = selected()
    if entry then
        snapshot()
        PropEditor.StartPlacing(index, false)
        PropEditor.Push()
        return
    end

    if not (selection and selection.entity and DoesEntityExist(selection.entity)) then return end
    PropEditor.StartPlacing(PropEditor.Adopt(selection.entity), false)
    PropEditor.Push()
end

local function runGizmo(entity, finish)
    PropEditor.gizmo = entity
    PropEditor.Push()

    Citizen.CreateThread(function()
        local result = exports['object_gizmo']:useGizmo(entity, {
            cameraPosition = PropEditorCam.pos,
            cameraRotation = { x = PropEditorCam.pitch, y = 0.0, z = PropEditorCam.yaw },
            cameraFov = 55.0,
        })

        PropEditor.gizmo = nil
        finish(result and result.confirmed and result or nil)

        if not PropEditor.active then return end
        PropEditorCam.Resume()
        exports['warv-ui']:SetEditorCursor(true)
        PropEditor.Push()
    end)
end

function PropEditor.GizmoHandle(id)
    local pose = PropLobby.Pose(id)
    local kind = PropLobby.Kind(id)
    local entity = kind == "weapon" and PropLobby.weapon or PropLobby.peds[id]
    if not (pose and entity and entity ~= 0 and DoesEntityExist(entity)) then return end

    snapshot()
    local lift = GetEntityCoords(entity).z - pose.z

    runGizmo(entity, function(result)
        if result and PropLobby.Pose(id) == pose then
            pose.x, pose.y = result.position.x, result.position.y
            pose.z = result.position.z - lift
            pose.h = result.rotation.z % 360.0
            PropEditor.dirty = true
        end
        PropLobby.SyncPeds()
        PropLobby.Restyle(id)
    end)
end

function PropEditor.Gizmo()
    local selection = PropEditor.selection
    if not selection or PropEditor.gizmo then return end

    if GetResourceState("object_gizmo") ~= "started" then
        notify("GIZMO RESOURCE NOT STARTED")
        return
    end
    PropEditor.CancelPlacing()

    if selection.handle then
        PropEditor.GizmoHandle(selection.handle)
        return
    end

    local index = selection.index
    if index then
        snapshot()
    elseif selection.entity and DoesEntityExist(selection.entity) then
        index = PropEditor.Adopt(selection.entity)
    else
        return
    end

    local entry = PropEditor.data.props[index]
    local entity = PropEntities.list[index]
    if not (entry and entity and DoesEntityExist(entity)) then return end

    PropEditor.selection = { index = index }
    local lift = GetEntityCoords(entity).z - entry.z

    runGizmo(entity, function(result)
        if not (PropEditor.data and PropEditor.data.props[index] == entry) then return end
        if result then
            entry.x, entry.y = result.position.x, result.position.y
            entry.z = result.position.z - lift
            entry.rx, entry.ry, entry.rz = result.rotation.x, result.rotation.y, result.rotation.z
            PropEditor.dirty = true
        end
        PropEntities.Apply(index)
    end)
end

function PropEditor.Duplicate()
    local selection = PropEditor.selection
    if not selection then return end

    local source
    if selection.index then
        source = PropMapStore.Entry(PropEditor.data.props[selection.index])
    elseif selection.entity and DoesEntityExist(selection.entity) then
        source = worldEntry(selection.entity)
    end
    if not source then return end

    snapshot()
    PropEditor.StartPlacing(PropEntities.Add(source), true)
    PropEditor.Push()
end

function PropEditor.Delete()
    local selection = PropEditor.selection
    if not selection then return end
    PropEditor.CancelPlacing()

    if selection.handle then
        local index = tonumber(selection.handle:match("^slot:(%d+)"))
        if index then
            PropEditor.LobbyRemoveSlot(index)
        else
            PropEditor.LobbyClear(selection.handle)
        end
        return
    end

    if selection.index then
        snapshot()
        PropEntities.Remove(selection.index)
        PropEditor.selection = nil
        PropEditor.Push()
        return
    end

    local entity = selection.entity
    if not (entity and DoesEntityExist(entity)) then return end

    snapshot()
    hideWorld(entity)
    PropEditor.selection = nil
    PropEditor.Push()
end

function PropEditor.DeleteAt(index)
    if not (PropEditor.data and PropEditor.data.props[index]) then return end
    PropEditor.selection = { index = index }
    PropEditor.Delete()
end

function PropEditor.Restore(index)
    local entry = PropEditor.data and PropEditor.data.hidden[index]
    if not entry then return end
    snapshot()
    PropMap.Reveal(entry)
    table.remove(PropEditor.data.hidden, index)
    PropEditor.Push()
end

function PropEditor.Rotate(axis, delta)
    local entry, index = selected()
    if not entry then return end
    if not PropEditor.placing then snapshot() end

    local field = axis == "x" and "rx" or axis == "y" and "ry" or "rz"
    entry[field] = (entry[field] + delta) % 360.0
    PropEntities.Apply(index)
    PropEditor.dirty = true
    PropEditor.PushLive()
end

function PropEditor.SetField(field, value)
    local entry, index = selected()
    if not (entry and entry[field] ~= nil) then return end
    local number = tonumber(value)
    if not number then return end

    snapshot()
    entry[field] = number
    PropEntities.Apply(index)
    PropEditor.Push()
end

function PropEditor.Ground()
    local entry, index = selected()
    if not entry then return end

    local found, ground = GetGroundZFor_3dCoord(entry.x, entry.y, entry.z + 3.0, false)
    if not found then return end

    snapshot()
    entry.z = ground + PropEntities.Lift(PropEntities.list[index])
    PropEntities.Apply(index)
    PropEditor.Push()
end

function PropEditor.Focus(index)
    local entry = PropEditor.data and PropEditor.data.props[index]
    if not entry then return end
    PropEditor.selection = { index = index }
    PropEditorCam.FocusOn(vector3(entry.x, entry.y, entry.z))
    PropEditor.Push()
end

function PropEditor.SetPed(field, value)
    local entry, index = selected()
    if not (entry and entry.kind == "ped") then return end
    if field ~= "scenario" and field ~= "dict" and field ~= "anim" then return end

    snapshot()
    entry.ped[field] = tostring(value or "")
    if field == "scenario" and entry.ped.scenario ~= "" then
        entry.ped.dict, entry.ped.anim = "", ""
    elseif field ~= "scenario" then
        entry.ped.scenario = ""
    end
    PropEntities.Restyle(index)
    PropEditor.Push()
end

function PropEditor.SetVehicle(field, value)
    local entry, index = selected()
    if not (entry and entry.kind == "vehicle") then return end
    local current = entry.vehicle[field]
    if current == nil or type(current) == "table" then return end

    snapshot()
    if type(current) == "boolean" then
        entry.vehicle[field] = value == true
    elseif type(current) == "string" then
        entry.vehicle[field] = tostring(value or ""):upper():sub(1, 8)
    else
        entry.vehicle[field] = math.floor(tonumber(value) or 0)
    end
    PropEntities.Restyle(index)
    PropEditor.Push()
end

function PropEditor.SetRgb(group, channel, value)
    local entry, index = selected()
    if not (entry and entry.kind == "vehicle") then return end
    local color = entry.vehicle[group]
    if not (type(color) == "table" and color[channel]) then return end

    snapshot()
    color[channel] = math.max(0, math.min(255, math.floor(tonumber(value) or 0)))
    PropEntities.Restyle(index)
    PropEditor.Push()
end

function PropEditor.SetMod(id, value)
    local entry, index = selected()
    if not (entry and entry.kind == "vehicle") then return end
    snapshot()
    upsert(entry.vehicle.mods, id, "value", value)
    PropEntities.Restyle(index)
    PropEditor.Push()
end

function PropEditor.ToggleSlot(list, id, on)
    local entry, index = selected()
    if not (entry and entry.kind == "vehicle") then return end
    if type(entry.vehicle[list]) ~= "table" then return end

    snapshot()
    upsert(entry.vehicle[list], id, "on", on)
    PropEntities.Restyle(index)
    PropEditor.Push()
end

local function aheadOfCamera(distance)
    local origin, dir = PropEditorCam.Ray()
    if not origin then return PropEditorCam.pos end
    return origin + dir * distance
end

local function surfaceSpot(ignore, fallback)
    local trace = PropEntities.Trace(ignore or 0)
    if trace then return trace.coords end
    return aheadOfCamera(fallback or 8.0)
end

function PropEditor.LobbyToggle()
    local lobby = PropLobby.Data()
    if not lobby then return end

    snapshot()
    lobby.enabled = not lobby.enabled
    if not lobby.enabled then PropEditor.selection = nil end
    PropLobby.SyncPeds()
    PropLobby.ApplyEnv()
    notify(lobby.enabled and "LOBBY MAP" or "")
end

local function placeHandle(id)
    local pose = PropLobby.Pose(id)
    if not pose then return end

    local kind = PropLobby.Kind(id)
    if kind == "cam" then
        local eye = PropEditorCam.pos
        local target = aheadOfCamera(6.0)
        pose.x, pose.y, pose.z = eye.x, eye.y, eye.z
        pose.tx, pose.ty, pose.tz = target.x, target.y, target.z
        pose.set = true
        PropEditor.selection = { handle = id }
        PropEditor.Push()
        return
    end

    local spot = PropLobby.Ground(id, surfaceSpot(PropLobby.peds[id]))
    pose.x, pose.y, pose.z = spot.x, spot.y, spot.z
    pose.h = (PropEditorCam.yaw + 180.0) % 360.0
    pose.set = true
    PropLobby.SyncPeds()
    PropEditor.selection = { handle = id }
    PropEditor.StartPlacing(id, false)
    PropEditor.Push()
end

function PropEditor.LobbyPlace(id)
    if not PropLobby.Pose(id) then return end
    snapshot()
    placeHandle(id)
end

function PropEditor.LobbyAddSlot()
    local lobby = PropLobby.Data()
    if not lobby then return end

    snapshot()
    lobby.slots[#lobby.slots + 1] = PropMapStore.Pose({})
    placeHandle("slot:" .. #lobby.slots)
end

function PropEditor.LobbyRemoveSlot(index)
    local lobby = PropLobby.Data()
    if not (lobby and lobby.slots[index]) then return end

    snapshot()
    table.remove(lobby.slots, index)
    PropEditor.selection = nil
    PropLobby.SyncPeds()
    PropEditor.Push()
end

function PropEditor.LobbySelect(id)
    if not PropLobby.Pose(id) then return end
    PropEditor.selection = { handle = id }
    PropEditorCam.FocusOn(PropLobby.HandlePos(id))
    PropEditor.Push()
end

function PropEditor.LobbyClear(id)
    local pose = PropLobby.Pose(id)
    if not pose then return end

    snapshot()
    pose.set = false
    PropEditor.selection = nil
    PropLobby.SyncPeds()
    PropEditor.Push()
end

function PropEditor.LobbyPose(field, value)
    local id = PropEditor.selection and PropEditor.selection.handle
    local pose = id and PropLobby.Pose(id)
    if not pose then return end

    snapshot()
    if field == "h" then
        pose.h = (tonumber(value) or 0) % 360.0
    elseif field == "z" then
        pose.z = tonumber(value) or pose.z
    elseif field == "scenario" then
        pose.scenario = tostring(value or "")
        if pose.scenario ~= "" then pose.dict, pose.anim = "", "" end
    elseif field == "dict" or field == "anim" then
        pose[field] = tostring(value or "")
        pose.scenario = ""
    else
        return
    end
    PropLobby.Restyle(id)
    PropLobby.SyncWeapon()
    PropEditor.Push()
end

local camLimits = {
    fov = { 5.0, 120.0 },
    idle = { 0.0, 3.0 },
    dofStrength = { 0.0, 1.0 },
    dofNear = { 0.0, 50.0 },
    dofFar = { 0.1, 200.0 },
}

function PropEditor.LobbyCam(field, value)
    local id = PropEditor.selection and PropEditor.selection.handle
    local cam = id and PropLobby.Pose(id)
    if not cam then return end

    snapshot()
    if field == "dof" then
        cam.dof = value == true
    else
        local limit = camLimits[field]
        if not limit then return end
        cam[field] = math.max(limit[1], math.min(limit[2], tonumber(value) or 0))
    end

    if PropEditor.preview == id:match(":(.+)") then
        LobbyCam.SetTarget(LobbyLayout.CamVectors(cam))
    end
    PropEditor.Push()
end

function PropEditor.PreviewStop()
    if not PropEditor.preview then return end
    PropEditor.preview = nil
    LobbyCam.Stop()
    PropEditorCam.Resume()
end

function PropEditor.LobbyEnv(field, value)
    local lobby = PropLobby.Data()
    if not lobby then return end

    snapshot()
    local env = lobby.env
    if field == "set" then
        env.set = value == true
    elseif field == "weather" then
        env.weather = tostring(value or "EXTRASUNNY")
    elseif field == "hour" then
        env.hour = (math.floor(tonumber(value) or 0)) % 24
    elseif field == "minute" then
        env.minute = (math.floor(tonumber(value) or 0)) % 60
    else
        return
    end

    PropLobby.ApplyEnv()
    PropEditor.Push()
end

function PropEditor.LobbyPreview(key)
    local wasPreviewing = PropEditor.preview
    PropEditor.PreviewStop()
    if wasPreviewing == key then
        PropEditor.Push()
        return
    end

    local lobby = PropLobby.Data()
    local cam = lobby and lobby.cams[key]
    if not (cam and cam.set) then return end

    local pos, look, fov, opts = LobbyLayout.CamVectors(cam)
    opts.snap = true
    PropEditor.preview = key
    PropEditor.selection = { handle = "cam:" .. key }
    LobbyCam.Ensure()
    LobbyCam.SetTarget(pos, look, fov, opts)
    PropEditor.Push()
end

function PropEditor.FavoriteSelection()
    local entry = selected()
    if not (entry and type(entry.model) == "string") then return end
    PropEditor.AddFavorite(entry.model, entry.model)
    PropEditor.Push()
end

local function stepPlacing()
    local placing = PropEditor.placing
    if not placing then return end

    if placing.handle then
        local kind = PropLobby.Kind(placing.handle)
        local spot
        if kind == "cam" or kind == "look" then
            spot = aheadOfCamera(placing.distance)
        else
            spot = PropLobby.Ground(placing.handle, surfaceSpot(PropLobby.peds[placing.handle], placing.distance))
        end
        PropLobby.SetPos(placing.handle, spot)
        return
    end

    local entry = PropEditor.data.props[placing.index]
    local entity = PropEntities.list[placing.index]
    if not (entry and entity and DoesEntityExist(entity)) then
        PropEditor.placing = nil
        return
    end

    local trace = PropEntities.Trace(entity)
    local spot
    if trace then
        spot = vector3(trace.coords.x, trace.coords.y, trace.coords.z + PropEntities.Lift(entity))
    else
        local origin, dir = PropEditorCam.Ray()
        if not origin then return end
        spot = origin + dir * 12.0
    end

    entry.x, entry.y, entry.z = spot.x, spot.y, spot.z + placing.lift
    PropMap.Place(entity, entry.x, entry.y, entry.z)
end

function PropEditor.Down()
    if not (PropEditor.data and PropEditor.mode == "edit") then return end
    if PropEditor.preview or PropEditor.gizmo then return end
    if PropEditor.placing then
        PropEditor.CommitPlacing()
        return
    end

    local handle = PropLobby.Pick()
    local picked = handle and { handle = handle } or PropEntities.Pick()
    PropEditor.selection = picked
    pressed = picked and { x = PropEditorCam.cursor.x, y = PropEditorCam.cursor.y, dragging = false } or nil
    PropEditor.Push()
end

function PropEditor.Up()
    if not pressed then return end
    local dragging = pressed.dragging
    pressed = nil
    if dragging then PropEditor.CommitPlacing() end
end

function PropEditor.Lift(delta)
    if not PropEditor.placing then return end
    PropEditor.placing.lift = PropEditor.placing.lift + delta
end

local function stepDrag()
    if not pressed or PropEditor.placing or PropEditorCam.looking then return end
    local dx = PropEditorCam.cursor.x - pressed.x
    local dy = PropEditorCam.cursor.y - pressed.y
    if math.sqrt(dx * dx + dy * dy) < dragThreshold then return end

    pressed.dragging = true
    PropEditor.Grab()
end

Citizen.CreateThread(function()
    local liveAt = 0

    while true do
        if not (PropEditor.active and PropEditor.mode == "edit" and PropEditor.data) then
            Wait(250)
        elseif PropEditor.gizmo then
            if DoesEntityExist(PropEditor.gizmo) then streamAround(GetEntityCoords(PropEditor.gizmo)) end
            Wait(0)
        elseif PropEditor.preview then
            streamAround(LobbyCam.pos)
            DisableAllControlActions(0)
            Wait(0)
        else
            PropEditorCam.ReadInput()
            PropEditorCam.Step()
            streamAround(PropEditorCam.pos)
            stepDrag()
            stepPlacing()

            if PropEditor.placing or not (PropEditorCam.over or PropEditorCam.looking) then
                PropEditor.hover = nil
            else
                PropEditor.hover = PropEntities.Pick()
            end

            PropLobby.Draw()

            local selection = PropEditor.selection
            if selection and not selection.handle then
                local entity = selection.index and PropEntities.list[selection.index] or selection.entity
                if entity then PropEntities.Box(entity, 233, 118, 12) end
            end

            local hover = PropEditor.hover
            if hover and not PropEditor.placing then
                local entity = hover.index and PropEntities.list[hover.index] or hover.entity
                if entity then PropEntities.Box(entity, 235, 235, 235) end
            end

            local now = GetGameTimer()
            if now >= liveAt then
                liveAt = now + 90
                PropEditor.PushLive()
            end

            DisableAllControlActions(0)
            Wait(0)
        end
    end
end)

RegisterCommand("propeditor", function(source, args)
    if not canEdit() then return end
    if PropEditor.active then
        PropEditor.Close()
        return
    end

    local key = PropMapStore.Key(args[1])
    if PropMapStore.Get(key) then
        PropEditor.Open(key)
    else
        PropEditor.Enter()
    end
end, false)

AddEventHandler("warv-ui:propEditorInput", function(data)
    if not (PropEditor.active and data) then return end
    local kind = data.kind

    if kind == "move" then
        PropEditorCam.SetCursor(tonumber(data.x) or 0.5, tonumber(data.y) or 0.5)
    elseif kind == "looking" then
        if data.on == true then
            PropEditorCam.StartLook()
        else
            PropEditorCam.StopLook()
        end
    elseif kind == "over" then
        PropEditorCam.over = data.on == true
    elseif kind == "wheel" then
        if PropEditor.placing then
            if PropEditor.placing.handle and PropEditor.placing.distance then
                PropEditor.placing.distance = math.max(1.0, PropEditor.placing.distance + (tonumber(data.dy) or 0) * 0.6)
            else
                PropEditor.Lift((tonumber(data.dy) or 0) * 0.25)
            end
        else
            PropEditorCam.SetSpeed(tonumber(data.dy) or 0)
        end
    elseif kind == "down" then
        PropEditor.Down()
    elseif kind == "up" then
        PropEditor.Up()
    elseif kind == "cancel" then
        PropEditor.CancelPlacing()
    end
end)
