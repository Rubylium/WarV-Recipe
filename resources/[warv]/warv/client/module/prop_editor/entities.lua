PropEntities = {}
PropEntities.list = {}

local rayFlags = 1 + 2 + 4 + 8 + 16
local rayRange = 400.0

function PropEntities.Lift(entity)
    if IsEntityAPed(entity) then return 0.0 end
    local min = GetModelDimensions(GetEntityModel(entity))
    return -min.z
end

function PropEntities.Spawn(entry)
    local entity = PropMap.Spawn(entry)
    if entity ~= 0 then SetEntityCollision(entity, true, true) end
    return entity
end

function PropEntities.Apply(index)
    local entry = PropEditor.data.props[index]
    local entity = PropEntities.list[index]
    if not (entry and entity and DoesEntityExist(entity)) then return end
    PropMap.Place(entity, entry.x, entry.y, entry.z)
    SetEntityRotation(entity, entry.rx, entry.ry, entry.rz, 2, true)
end

function PropEntities.Restyle(index)
    local entry = PropEditor.data.props[index]
    local entity = PropEntities.list[index]
    if not (entry and entity and DoesEntityExist(entity)) then return end

    if entry.kind == "ped" then
        PropMap.ApplyPed(entity, entry.ped)
    elseif entry.kind == "vehicle" then
        PropMap.ApplyVehicle(entity, entry.vehicle)
    end
    PropEntities.Apply(index)
end

function PropEntities.Add(entry)
    local index = #PropEditor.data.props + 1
    PropEditor.data.props[index] = entry
    PropEntities.list[index] = PropEntities.Spawn(entry)
    return index
end

function PropEntities.Remove(index)
    PropMap.Delete(PropEntities.list[index])
    table.remove(PropEditor.data.props, index)
    table.remove(PropEntities.list, index)
end

function PropEntities.Clear()
    for _, entity in ipairs(PropEntities.list) do PropMap.Delete(entity) end
    PropEntities.list = {}
end

function PropEntities.Rebuild()
    PropEntities.Clear()
    for index, entry in ipairs(PropEditor.data.props) do
        PropEntities.list[index] = PropEntities.Spawn(entry)
    end
end

function PropEntities.HideAll()
    for _, entry in ipairs(PropEditor.data.hidden) do PropMap.Hide(entry) end
end

function PropEntities.RevealAll()
    for _, entry in ipairs(PropEditor.data.hidden) do PropMap.Reveal(entry) end
end

function PropEntities.IndexOf(entity)
    for index, spawned in ipairs(PropEntities.list) do
        if spawned == entity then return index end
    end
    return nil
end

function PropEntities.Trace(ignore)
    local origin, dir = PropEditorCam.Ray()
    if not origin then return nil end

    local far = origin + dir * rayRange
    local probe = StartExpensiveSynchronousShapeTestLosProbe(
        origin.x, origin.y, origin.z, far.x, far.y, far.z, rayFlags, ignore or 0, 4)
    local _, hit, coords, _, entity = GetShapeTestResult(probe)
    if not hit or hit == 0 then return nil end
    return { coords = coords, entity = entity }
end

function PropEntities.Pick()
    local trace = PropEntities.Trace(0)
    if not (trace and trace.entity and trace.entity ~= 0) then return nil end

    local index = PropEntities.IndexOf(trace.entity)
    if index then return { index = index } end
    if IsEntityAnObject(trace.entity) then return { entity = trace.entity } end
    return nil
end

local edges = {
    { 1, 2 }, { 1, 3 }, { 1, 5 }, { 2, 4 }, { 2, 6 }, { 3, 4 },
    { 3, 7 }, { 4, 8 }, { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
}

function PropEntities.Box(entity, r, g, b)
    if not DoesEntityExist(entity) then return end
    local min, max = GetModelDimensions(GetEntityModel(entity))

    local offsets = {
        vector3(min.x, min.y, min.z), vector3(min.x, min.y, max.z),
        vector3(min.x, max.y, min.z), vector3(min.x, max.y, max.z),
        vector3(max.x, min.y, min.z), vector3(max.x, min.y, max.z),
        vector3(max.x, max.y, min.z), vector3(max.x, max.y, max.z),
    }

    local points = {}
    for index, offset in ipairs(offsets) do
        points[index] = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    end
    for _, edge in ipairs(edges) do
        local from, to = points[edge[1]], points[edge[2]]
        DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, r, g, b, 220)
    end
end

function PropEntities.ModOptions(index)
    local entity = PropEntities.list[index]
    local entry = PropEditor.data.props[index]
    if not (entry and entry.kind == "vehicle" and entity and DoesEntityExist(entity)) then return {}, {}, {} end

    local mods = {}
    for _, slot in ipairs(PropEditor.ModSlots) do
        local count = GetNumVehicleMods(entity, slot.id)
        if count > 0 then
            mods[#mods + 1] = { id = slot.id, label = slot.label, count = count, value = GetVehicleMod(entity, slot.id) }
        end
    end

    local toggles = {}
    for _, slot in ipairs(PropEditor.ToggleSlots) do
        toggles[#toggles + 1] = { id = slot.id, label = slot.label, on = IsToggleModOn(entity, slot.id) }
    end

    local extras = {}
    for id = 1, 14 do
        if DoesExtraExist(entity, id) then
            extras[#extras + 1] = { id = id, on = IsVehicleExtraTurnedOn(entity, id) == true }
        end
    end

    return mods, toggles, extras
end
