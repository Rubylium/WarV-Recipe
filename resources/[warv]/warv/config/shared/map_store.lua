MapStore = {}
MapStore.File = "data/maps.json"
SharedConfig.Maps = {}

local function encode(value)
    local kind = type(value)
    if kind == "vector2" then return { x = value.x, y = value.y } end
    if kind == "vector3" then return { x = value.x, y = value.y, z = value.z } end
    if kind == "vector4" then return { x = value.x, y = value.y, z = value.z, w = value.w } end
    if kind ~= "table" then return value end

    local out = {}
    for key, nested in pairs(value) do out[key] = encode(nested) end
    return out
end

local function decode(value)
    if type(value) ~= "table" then return value end
    if value.x ~= nil and value.y ~= nil then
        if value.w ~= nil then return vector4(value.x, value.y, value.z, value.w) end
        if value.z ~= nil then return vector3(value.x, value.y, value.z) end
        return vector2(value.x, value.y)
    end

    local out = {}
    for key, nested in pairs(value) do out[key] = decode(nested) end
    return out
end

MapStore.Encode = encode
MapStore.Decode = decode

function MapStore.Serialize()
    return encode(SharedConfig.Maps)
end

function MapStore.Normalize()
    for _, map in pairs(SharedConfig.Maps) do
        if type(map) == "table" and type(map.gamemodes) ~= "table" then
            local modes = {}
            for id, definition in pairs(GamemodeDefinitions.byId) do
                if definition.implemented then modes[id] = true end
            end
            map.gamemodes = modes
        end
    end
end

function MapStore.Apply(maps)
    if type(maps) ~= "table" or next(maps) == nil then return false end
    SharedConfig.Maps = decode(maps)
    MapStore.Normalize()
    return true
end

function MapStore.ApplyOne(name, data)
    if type(name) ~= "string" or name == "" then return false end
    if data == nil then
        SharedConfig.Maps[name] = nil
    else
        SharedConfig.Maps[name] = decode(data)
    end
    MapStore.Normalize()
    return true
end

function MapStore.Load()
    local raw = LoadResourceFile(GetCurrentResourceName(), MapStore.File)
    if not raw then return false end
    local ok, maps = pcall(json.decode, raw)
    if not ok then return false end
    return MapStore.Apply(maps)
end

MapStore.Load()
MapStore.Normalize()
