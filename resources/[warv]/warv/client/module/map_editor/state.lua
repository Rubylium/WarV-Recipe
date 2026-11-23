MapEditor = {}
MapEditor.active = false
MapEditor.mode = "pick"
MapEditor.mapName = ""
MapEditor.data = nil
MapEditor.layer = "spawns"
MapEditor.selection = nil
MapEditor.hover = nil
MapEditor.dirty = false
MapEditor.PedLift = 1.0

MapEditor.CoreLayers = {
    { key = "spawns", label = "Spawns", kind = "list", vec = 4, color = { 90, 210, 130 } },
    { key = "startFirstPos1", label = "Team 1 Start", kind = "single", vec = 4, color = { 90, 160, 255 } },
    { key = "startFirstPos2", label = "Team 2 Start", kind = "single", vec = 4, color = { 255, 120, 80 } },
    { key = "endScreenPos", label = "End Screen", kind = "single", vec = 4, color = { 233, 118, 12 } },
    { key = "middleMapPos", label = "Map Center", kind = "single", vec = 3, color = { 255, 220, 80 } },
    { key = "mapBounds", label = "Bounds", kind = "polygon", vec = 2, color = { 235, 70, 60 } },
}

MapEditor.RequirementLayers = {
    dominationSpawns = {
        { key = "dominationSpawns", label = "Domination Flags", kind = "list", vec = 3, max = 3, color = { 190, 120, 255 } },
    },
    snd = {
        { key = "snd", field = "bombSite1", label = "Bomb Site A", kind = "nested", vec = 3, color = { 255, 90, 90 } },
        { key = "snd", field = "bombSite2", label = "Bomb Site B", kind = "nested", vec = 3, color = { 255, 90, 90 } },
        { key = "snd", field = "bombSpawnSite", label = "Bomb Spawn", kind = "nested", vec = 3, color = { 255, 190, 90 } },
    },
}

local function layerId(layer)
    if layer.field then return layer.key .. "." .. layer.field end
    return layer.key
end

MapEditor.LayerId = layerId

function MapEditor.Layers()
    local layers = {}
    for _, layer in ipairs(MapEditor.CoreLayers) do layers[#layers + 1] = layer end

    for _, gamemode in ipairs(MapEditor.Gamemodes()) do
        if MapEditor.data and MapEditor.data.gamemodes and MapEditor.data.gamemodes[gamemode.id] then
            for requirement in pairs(gamemode.requirements) do
                for _, layer in ipairs(MapEditor.RequirementLayers[requirement] or {}) do
                    layers[#layers + 1] = layer
                end
            end
        end
    end
    return layers
end

function MapEditor.Gamemodes()
    local out = {}
    for id, definition in pairs(GamemodeDefinitions.byId) do
        out[#out + 1] = {
            id = id,
            name = definition.name,
            implemented = definition.implemented == true,
            requirements = definition.mapRequirements or {},
        }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function MapEditor.FindLayer(id)
    for _, layer in ipairs(MapEditor.Layers()) do
        if layerId(layer) == id then return layer end
    end
    return nil
end

function MapEditor.Value(layer)
    if not MapEditor.data then return nil end
    if layer.field then
        local parent = MapEditor.data[layer.key]
        return parent and parent[layer.field]
    end
    return MapEditor.data[layer.key]
end

local function setValue(layer, value)
    if layer.field then
        MapEditor.data[layer.key] = MapEditor.data[layer.key] or {}
        MapEditor.data[layer.key][layer.field] = value
        return
    end
    MapEditor.data[layer.key] = value
end

function MapEditor.Points(layer)
    local value = MapEditor.Value(layer)
    if value == nil then return {} end
    if layer.kind == "single" or layer.kind == "nested" then return { value } end
    if layer.kind == "polygon" then return value end

    local out = {}
    for index, entry in ipairs(value) do out[index] = entry.pos end
    return out
end

function MapEditor.PointAt(layer, index)
    return MapEditor.Points(layer)[index]
end

function MapEditor.GroundZ(x, y)
    for _, probe in ipairs({ 1200.0, 500.0, 200.0, 80.0, 20.0 }) do
        local found, z = GetGroundZFor_3dCoord(x, y, probe, false)
        if found then return z end
    end
    return nil
end

local function makePoint(layer, x, y, z, heading)
    if layer.vec == 2 then return vector2(x, y) end
    if layer.vec == 3 then return vector3(x, y, z) end
    return vector4(x, y, z, heading or 0.0)
end

local function surfaceToStored(layer, surfaceZ)
    if layer.vec == 2 then return 0.0 end
    return surfaceZ + MapEditor.PedLift
end

local function insertIndex(list, x, y)
    if #list < 2 then return #list + 1 end

    local bestIndex, bestDistance = #list + 1, math.huge
    for index = 1, #list do
        local a = list[index]
        local b = list[(index % #list) + 1]
        local abx, aby = b.x - a.x, b.y - a.y
        local length = abx * abx + aby * aby
        local t = 0.0
        if length > 0.0001 then
            t = math.max(0.0, math.min(1.0, ((x - a.x) * abx + (y - a.y) * aby) / length))
        end
        local px, py = a.x + abx * t, a.y + aby * t
        local distance = (x - px) * (x - px) + (y - py) * (y - py)
        if distance < bestDistance then
            bestDistance = distance
            bestIndex = index + 1
        end
    end
    return bestIndex
end

function MapEditor.Add(layer, x, y, surfaceZ)
    if not MapEditor.data then return end
    surfaceZ = surfaceZ or MapEditor.GroundZ(x, y) or 0.0
    local point = makePoint(layer, x, y, surfaceToStored(layer, surfaceZ), 0.0)

    if layer.kind == "single" or layer.kind == "nested" then
        setValue(layer, point)
        MapEditor.selection = { layer = layerId(layer), index = 1 }
    elseif layer.kind == "polygon" then
        local list = MapEditor.Value(layer) or {}
        local at = insertIndex(list, x, y)
        table.insert(list, at, point)
        setValue(layer, list)
        MapEditor.selection = { layer = layerId(layer), index = at }
    else
        local list = MapEditor.Value(layer) or {}
        if layer.max and #list >= layer.max then return end
        list[#list + 1] = { pos = point }
        setValue(layer, list)
        MapEditor.selection = { layer = layerId(layer), index = #list }
    end
    MapEditor.dirty = true
end

function MapEditor.Move(layer, index, x, y, surfaceZ)
    if not MapEditor.data then return end
    local current = MapEditor.PointAt(layer, index)
    if not current then return end

    surfaceZ = surfaceZ or MapEditor.GroundZ(x, y)
    local z = surfaceZ and surfaceToStored(layer, surfaceZ) or (layer.vec ~= 2 and current.z) or 0.0
    local heading = layer.vec == 4 and current.w or 0.0
    local point = makePoint(layer, x, y, z, heading)

    if layer.kind == "single" or layer.kind == "nested" then
        setValue(layer, point)
    elseif layer.kind == "polygon" then
        MapEditor.Value(layer)[index] = point
    else
        MapEditor.Value(layer)[index].pos = point
    end
    MapEditor.dirty = true
end

function MapEditor.Rotate(layer, index, delta)
    if layer.vec ~= 4 then return end
    local current = MapEditor.PointAt(layer, index)
    if not current then return end

    local heading = (current.w + delta) % 360.0
    local point = vector4(current.x, current.y, current.z, heading)
    if layer.kind == "single" or layer.kind == "nested" then
        setValue(layer, point)
    else
        MapEditor.Value(layer)[index].pos = point
    end
    MapEditor.dirty = true
end

function MapEditor.SnapGround(layer, index)
    local current = MapEditor.PointAt(layer, index)
    if not current then return end
    local ground = MapEditor.GroundZ(current.x, current.y)
    if not ground then return end
    MapEditor.Move(layer, index, current.x, current.y, ground)
end

function MapEditor.Delete(layer, index)
    if not MapEditor.data then return end
    if layer.kind == "single" or layer.kind == "nested" then
        setValue(layer, nil)
    else
        local list = MapEditor.Value(layer)
        if not list then return end
        table.remove(list, index)
    end
    MapEditor.selection = nil
    MapEditor.dirty = true
end

function MapEditor.Missing()
    local missing = {}
    for _, layer in ipairs(MapEditor.Layers()) do
        local points = MapEditor.Points(layer)
        local needed = layer.kind == "polygon" and 3 or 1
        if #points < needed then missing[#missing + 1] = layer.label end
    end
    return missing
end
