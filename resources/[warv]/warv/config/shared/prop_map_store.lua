PropMapStore = {}
PropMapStore.File = "data/prop_maps.json"
PropMaps = {}

local function number(value, fallback)
    return math.floor((tonumber(value) or fallback or 0) * 1000) / 1000
end

local function whole(value, fallback)
    return math.floor(tonumber(value) or fallback or 0)
end

local function cleanPed(ped)
    ped = type(ped) == "table" and ped or {}
    return {
        scenario = tostring(ped.scenario or ""),
        dict = tostring(ped.dict or ""),
        anim = tostring(ped.anim or ""),
    }
end

local function cleanMods(slots)
    local out = {}
    for _, slot in ipairs(type(slots) == "table" and slots or {}) do
        if type(slot) == "table" and slot.id ~= nil then
            out[#out + 1] = { id = whole(slot.id), value = whole(slot.value, -1) }
        end
    end
    return out
end

local function cleanFlags(slots)
    local out = {}
    for _, slot in ipairs(type(slots) == "table" and slots or {}) do
        if type(slot) == "table" and slot.id ~= nil then
            out[#out + 1] = { id = whole(slot.id), on = slot.on == true }
        end
    end
    return out
end

local function cleanColor(color, fallback)
    color = type(color) == "table" and color or {}
    return {
        r = whole(color.r, fallback),
        g = whole(color.g, fallback),
        b = whole(color.b, fallback),
    }
end

local function cleanVehicle(vehicle)
    vehicle = type(vehicle) == "table" and vehicle or {}
    return {
        primary = whole(vehicle.primary, 0),
        secondary = whole(vehicle.secondary, 0),
        pearl = whole(vehicle.pearl, 0),
        wheelColor = whole(vehicle.wheelColor, 0),
        interior = whole(vehicle.interior, 0),
        dashboard = whole(vehicle.dashboard, 0),
        wheelType = whole(vehicle.wheelType, 0),
        windowTint = whole(vehicle.windowTint, 0),
        plateStyle = whole(vehicle.plateStyle, 0),
        livery = whole(vehicle.livery, -1),
        dirt = whole(vehicle.dirt, 0),
        plate = tostring(vehicle.plate or ""),
        bulletproof = vehicle.bulletproof == true,
        engineOn = vehicle.engineOn == true,
        lights = vehicle.lights == true,
        highBeams = vehicle.highBeams == true,
        siren = vehicle.siren == true,
        mods = cleanMods(vehicle.mods),
        toggles = cleanFlags(vehicle.toggles),
        extras = cleanFlags(vehicle.extras),
        doors = cleanFlags(vehicle.doors),
        windows = cleanFlags(vehicle.windows),
        neonOn = vehicle.neonOn == true,
        neon = cleanColor(vehicle.neon, 255),
        tyreSmoke = cleanColor(vehicle.tyreSmoke, 255),
    }
end

local function cleanEntry(entry)
    if type(entry) ~= "table" or entry.model == nil then return nil end
    local kind = entry.kind
    if kind ~= "ped" and kind ~= "vehicle" then kind = "prop" end

    local out = {
        kind = kind,
        model = entry.model,
        x = number(entry.x),
        y = number(entry.y),
        z = number(entry.z),
        rx = number(entry.rx),
        ry = number(entry.ry),
        rz = number(entry.rz),
    }
    if kind == "ped" then out.ped = cleanPed(entry.ped) end
    if kind == "vehicle" then out.vehicle = cleanVehicle(entry.vehicle) end
    return out
end

PropMapStore.Entry = cleanEntry

PropMapStore.CamKeys = { "main", "streaks", "skin" }

local function cleanHidden(entry)
    if type(entry) ~= "table" or entry.model == nil then return nil end
    return { model = entry.model, x = number(entry.x), y = number(entry.y), z = number(entry.z) }
end

local function cleanPose(pose)
    pose = type(pose) == "table" and pose or {}
    return {
        set = pose.set == true,
        x = number(pose.x),
        y = number(pose.y),
        z = number(pose.z),
        h = number(pose.h),
        scenario = tostring(pose.scenario or ""),
        dict = tostring(pose.dict or ""),
        anim = tostring(pose.anim or ""),
    }
end

local function cleanCam(cam)
    cam = type(cam) == "table" and cam or {}
    return {
        set = cam.set == true,
        x = number(cam.x),
        y = number(cam.y),
        z = number(cam.z),
        tx = number(cam.tx),
        ty = number(cam.ty),
        tz = number(cam.tz),
        fov = number(cam.fov, 45),
        idle = number(cam.idle),
        dof = cam.dof == true,
        dofStrength = number(cam.dofStrength, 1),
        dofNear = number(cam.dofNear, 0.5),
        dofFar = number(cam.dofFar, 8),
    }
end

local function cleanEnv(env)
    env = type(env) == "table" and env or {}
    return {
        set = env.set == true,
        hour = whole(env.hour, 12) % 24,
        minute = whole(env.minute) % 60,
        weather = tostring(env.weather or "EXTRASUNNY"),
    }
end

local function cleanLobby(lobby)
    lobby = type(lobby) == "table" and lobby or {}
    local slots = {}
    for _, slot in ipairs(lobby.slots or {}) do
        slots[#slots + 1] = cleanPose(slot)
    end

    local cams = {}
    for _, key in ipairs(PropMapStore.CamKeys) do
        cams[key] = cleanCam((lobby.cams or {})[key])
    end

    return {
        enabled = lobby.enabled == true,
        me = cleanPose(lobby.me),
        slots = slots,
        cams = cams,
        weapon = cleanPose(lobby.weapon),
        env = cleanEnv(lobby.env),
    }
end

function PropMapStore.Clean(name, map)
    map = type(map) == "table" and map or {}
    local props, hidden = {}, {}
    for _, entry in ipairs(map.props or {}) do
        props[#props + 1] = cleanEntry(entry)
    end
    for _, entry in ipairs(map.hidden or {}) do
        hidden[#hidden + 1] = cleanHidden(entry)
    end
    return { name = name, props = props, hidden = hidden, lobby = cleanLobby(map.lobby) }
end

PropMapStore.Pose = cleanPose

function PropMapStore.Key(name)
    return tostring(name or ""):upper()
end

function PropMapStore.Get(name)
    return PropMaps[PropMapStore.Key(name)]
end

function PropMapStore.Names()
    local names = {}
    for name in pairs(PropMaps) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function PropMapStore.Set(name, map)
    local key = PropMapStore.Key(name)
    if key == "" then return false end
    if map == nil then
        PropMaps[key] = nil
        return true
    end

    PropMaps[key] = PropMapStore.Clean(key, map)
    if PropMaps[key].lobby.enabled then
        for other, entry in pairs(PropMaps) do
            if other ~= key then entry.lobby.enabled = false end
        end
    end
    return true
end

function PropMapStore.LobbyName()
    for name, map in pairs(PropMaps) do
        if map.lobby.enabled then return name end
    end
    return nil
end

function PropMapStore.Serialize()
    local out = {}
    for name, map in pairs(PropMaps) do
        out[name] = PropMapStore.Clean(name, map)
    end
    return out
end

function PropMapStore.Load()
    local raw = LoadResourceFile(GetCurrentResourceName(), PropMapStore.File)
    if not raw then return false end
    local ok, maps = pcall(json.decode, raw)
    if not ok or type(maps) ~= "table" then return false end

    PropMaps = {}
    for name, map in pairs(maps) do
        PropMapStore.Set(name, map)
    end
    return true
end

PropMapStore.Load()
