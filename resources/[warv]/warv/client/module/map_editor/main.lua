local undoStack = {}
local dragging = false

local function clone(value)
    return MapStore.Decode(MapStore.Encode(value))
end

local function snapshot()
    undoStack[#undoStack + 1] = MapStore.Encode(MapEditor.data)
    if #undoStack > 40 then table.remove(undoStack, 1) end
end

local function canEdit()
    return (tonumber(Lobby.playerData.perm) or 0) >= 3
end

function MapEditor.Cards()
    local cards = {}
    for name, map in pairs(SharedConfig.Maps) do
        local modes = {}
        for id, on in pairs(map.gamemodes or {}) do
            if on then modes[#modes + 1] = (GamemodeDefinitions.byId[id] or {}).name or id end
        end
        table.sort(modes)
        cards[#cards + 1] = {
            name = name,
            label = map.name or name,
            description = map.description or "",
            image = map.uiImage or "",
            spawns = #(map.spawns or {}),
            bounds = #(map.mapBounds or {}),
            gamemodes = modes,
        }
    end
    table.sort(cards, function(a, b) return a.name < b.name end)
    return cards
end

function MapEditor.Push()
    if not MapEditor.active then return end
    if MapEditor.mode == "pick" then
        exports['warv-ui']:SetMapEditor({
            mode = "pick",
            mapName = "",
            hidden = false,
            cards = MapEditor.Cards(),
            layers = {},
            gamemodes = {},
            selection = nil,
            dirty = false,
            missing = {},
            height = 0,
        })
        return
    end

    local layers = {}
    for _, layer in ipairs(MapEditor.Layers()) do
        local id = MapEditor.LayerId(layer)
        layers[#layers + 1] = {
            id = id,
            label = layer.label,
            kind = layer.kind,
            count = #MapEditor.Points(layer),
            max = layer.max or 0,
            active = id == MapEditor.layer,
            color = string.format("rgb(%d,%d,%d)", layer.color[1], layer.color[2], layer.color[3]),
        }
    end

    local gamemodes = {}
    for _, gamemode in ipairs(MapEditor.Gamemodes()) do
        local requirements = {}
        for requirement in pairs(gamemode.requirements) do requirements[#requirements + 1] = requirement end
        gamemodes[#gamemodes + 1] = {
            id = gamemode.id,
            name = gamemode.name,
            implemented = gamemode.implemented,
            enabled = (MapEditor.data.gamemodes or {})[gamemode.id] == true,
            requirements = requirements,
        }
    end

    local points = {}
    local activeLayer = MapEditor.FindLayer(MapEditor.layer)
    if activeLayer then
        for index, point in ipairs(MapEditor.Points(activeLayer)) do
            points[#points + 1] = {
                index = index,
                x = math.floor(point.x * 10) / 10,
                y = math.floor(point.y * 10) / 10,
                z = activeLayer.vec ~= 2 and math.floor(point.z * 10) / 10 or 0,
                heading = activeLayer.vec == 4 and math.floor(point.w) or -1,
                flat = activeLayer.vec == 2,
            }
        end
    end

    local envHour, envMinute, envWeather = MapEnv.Get(MapEditor.data)
    envHour, envMinute, envWeather = envHour or 12, envMinute or 0, envWeather or "EXTRASUNNY"

    local selection = nil
    if MapEditor.selection then
        local layer = MapEditor.FindLayer(MapEditor.selection.layer)
        local point = layer and MapEditor.PointAt(layer, MapEditor.selection.index)
        if point then
            selection = {
                label = layer.label,
                index = MapEditor.selection.index,
                x = math.floor(point.x * 100) / 100,
                y = math.floor(point.y * 100) / 100,
                z = layer.vec ~= 2 and math.floor(point.z * 100) / 100 or 0,
                heading = layer.vec == 4 and math.floor(point.w * 10) / 10 or -1,
            }
        end
    end

    exports['warv-ui']:SetMapEditor({
        mode = "edit",
        mapName = MapEditor.mapName,
        cards = {},
        layers = layers,
        points = points,
        activeLabel = activeLayer and activeLayer.label or "",
        hidden = MapEditor.hiddenUntil ~= nil,
        env = {
            hour = envHour,
            minute = envMinute,
            weather = envWeather,
            set = MapEditor.data.env ~= nil,
        },
        weathers = MapEnv.Weathers,
        boundsMaxZ = MapEditor.data.mapBoundsZ and tostring(MapEditor.data.mapBoundsZ) or "",
        boundsMinZ = MapEditor.data.minZ and tostring(MapEditor.data.minZ) or "",
        gamemodes = gamemodes,
        selection = selection,
        dirty = MapEditor.dirty,
        missing = MapEditor.Missing(),
        height = math.floor(MapEditorCam.height),
    })
end

local returnPos = nil
local returnVisible = true

local function rememberPlayer()
    if returnPos then return end
    returnPos = GetEntityCoords(PlayerPedId())
    returnVisible = IsEntityVisible(PlayerPedId())
end

local function teleport(pos)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    local deadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        Wait(0)
    end
end

function MapEditor.Enter()
    if not canEdit() then return end
    rememberPlayer()
    MapEditor.active = true
    MapEditor.mode = "pick"
    MapEditor.mapName = ""
    MapEditor.data = nil
    UiHandler.SetPageActive("ui_map_editor")
    MapEditor.Push()
end

function MapEditor.Open(name)
    if not canEdit() then return end
    local source = SharedConfig.Maps[name]
    if not source then return end

    MapEditor.mapName = name
    MapEditor.data = clone(source)
    MapEditor.data.name = MapEditor.data.name or name
    MapEditor.selection = nil
    MapEditor.hover = nil
    MapEditor.dirty = false
    MapEditor.layer = "spawns"
    undoStack = {}
    MapEditorDraw.ClearCache()

    local focus = MapEditor.data.middleMapPos
        or (MapEditor.data.spawns and MapEditor.data.spawns[1] and MapEditor.data.spawns[1].pos)
        or GetEntityCoords(PlayerPedId())
    focus = vector3(focus.x, focus.y, focus.z)

    rememberPlayer()
    MapEditor.active = true
    MapEditor.mode = "edit"
    UiHandler.SetPageActive("ui_map_editor")

    Citizen.CreateThread(function()
        teleport(focus)
        MapEditorCam.Start(focus)
        MapEnv.Apply(MapEditor.data)
        MapEditor.Push()
    end)
end

function MapEditor.Back()
    if not MapEditor.active then return end
    MapEditorCam.Stop()
    MapEditor.mode = "pick"
    MapEditor.mapName = ""
    MapEditor.data = nil
    MapEditor.selection = nil
    MapEditor.hover = nil
    MapEditor.hiddenUntil = nil
    dragging = false
    MapEditor.Push()
end

function MapEditor.Create(name)
    if not canEdit() then return end
    name = tostring(name or ""):upper()
    if name == "" or SharedConfig.Maps[name] then return end

    local pos = GetEntityCoords(PlayerPedId())
    SharedConfig.Maps[name] = {
        name = name,
        description = "",
        spritePreview = "",
        uiImage = "",
        modelsToLoad = {},
        middleMapPos = vector3(pos.x, pos.y, pos.z),
        spawns = {},
        gamemodes = {},
    }
    MapEditor.Open(name)
end

function MapEditor.Close()
    MapEditor.active = false
    MapEditor.mode = "pick"
    MapEditor.mapName = ""
    MapEditor.data = nil
    MapEditor.selection = nil
    MapEditor.hover = nil
    MapEditor.hiddenUntil = nil
    dragging = false
    MapEditorCam.Stop()
    UiHandler.SetPageInactive("ui_map_editor")

    local ped = PlayerPedId()
    if returnPos then
        SetEntityCoordsNoOffset(ped, returnPos.x, returnPos.y, returnPos.z, false, false, false)
        returnPos = nil
    end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, returnVisible, false)

    MapEnv.Lobby()
    if LobbyCam.handle and DoesCamExist(LobbyCam.handle) then
        SetCamActive(LobbyCam.handle, true)
        RenderScriptCams(true, false, 0, true, true)
        LobbyCam.rendering = true
    end
    LobbyPlacement.GoToMainLobby(true)
    PlayersDisplay.SyncMyWeapon()
end

function MapEditor.Save()
    if not (MapEditor.active and canEdit()) then return end
    TriggerServerEvent("warv:SaveMap", MapEditor.mapName, MapStore.Encode(MapEditor.data))
    SharedConfig.Maps[MapEditor.mapName] = clone(MapEditor.data)
    MapEditor.dirty = false
    MapEditor.Push()
end

function MapEditor.Undo()
    local previous = table.remove(undoStack)
    if not previous then return end
    MapEditor.data = MapStore.Decode(previous)
    MapEditor.selection = nil
    MapEditor.dirty = true
    MapEditor.Push()
end

function MapEditor.Click(shift)
    if not MapEditor.data then return end
    local picked = MapEditorDraw.Pick()
    if picked then
        MapEditor.selection = picked
        MapEditor.layer = picked.layer
        snapshot()
        dragging = true
        MapEditor.Push()
        return
    end

    if shift then return end
    local cursor = MapEditorCam.world
    local layer = MapEditor.FindLayer(MapEditor.layer)
    if not (cursor and layer) then return end

    snapshot()
    MapEditor.Add(layer, cursor.x, cursor.y, cursor.z)
    MapEditor.Push()
end

function MapEditor.Release()
    if dragging then
        dragging = false
        MapEditor.Push()
    end
end

function MapEditor.DragPoint()
    if not (dragging and MapEditor.selection and MapEditorCam.world) then return end
    local layer = MapEditor.FindLayer(MapEditor.selection.layer)
    if not layer then return end
    local cursor = MapEditorCam.world
    MapEditor.Move(layer, MapEditor.selection.index, cursor.x, cursor.y, cursor.z)
end

function MapEditor.FocusPoint(index)
    local layer = MapEditor.FindLayer(MapEditor.layer)
    local point = layer and MapEditor.PointAt(layer, index)
    if not point then return end

    local z = layer.vec == 2 and MapEditorCam.focus.z or point.z
    MapEditorCam.FocusOn(vector3(point.x, point.y, z))
    MapEditor.selection = { layer = MapEditor.layer, index = index }
    MapEditor.Push()
end

function MapEditor.DeleteAt(index)
    local layer = MapEditor.FindLayer(MapEditor.layer)
    if not layer then return end
    snapshot()
    MapEditor.Delete(layer, index)
    MapEditor.Push()
end

function MapEditor.SnapGroundAt(index)
    local layer = MapEditor.FindLayer(MapEditor.layer)
    if not layer then return end
    snapshot()
    MapEditor.SnapGround(layer, index)
    MapEditor.Push()
end

function MapEditor.HideUi(seconds)
    if not MapEditor.active then return end
    MapEditor.selection = nil
    MapEditor.hover = nil
    MapEditor.hiddenUntil = GetGameTimer() + math.floor((tonumber(seconds) or 5) * 1000)
    MapEditor.Push()
end

function MapEditor.SetEnv(field, value)
    if not MapEditor.data then return end
    snapshot()

    local env = MapEditor.data.env or {}
    if field == "weather" then
        env.weather = tostring(value or "EXTRASUNNY")
    else
        local number = math.floor(tonumber(value) or 0)
        env[field] = field == "hour" and (number % 24) or (number % 60)
    end
    env.hour = env.hour or 12
    env.minute = env.minute or 0
    env.weather = env.weather or "EXTRASUNNY"

    MapEditor.data.env = env
    MapEditor.dirty = true
    MapEnv.Apply(MapEditor.data)
    MapEditor.Push()
end

function MapEditor.SetBoundsZ(field, value)
    if not MapEditor.data then return end
    if field ~= "mapBoundsZ" and field ~= "minZ" then return end
    snapshot()
    MapEditor.data[field] = tonumber(value)
    MapEditor.dirty = true
    MapEditor.Push()
end

function MapEditor.RotateSelection(delta)
    if not MapEditor.selection then return end
    local layer = MapEditor.FindLayer(MapEditor.selection.layer)
    if not layer then return end
    snapshot()
    MapEditor.Rotate(layer, MapEditor.selection.index, delta)
    MapEditor.Push()
end

function MapEditor.DeleteSelection()
    if not MapEditor.selection then return end
    local layer = MapEditor.FindLayer(MapEditor.selection.layer)
    if not layer then return end
    snapshot()
    MapEditor.Delete(layer, MapEditor.selection.index)
    MapEditor.Push()
end

function MapEditor.ToggleGamemode(id)
    if not MapEditor.data then return end
    snapshot()
    MapEditor.data.gamemodes = MapEditor.data.gamemodes or {}
    if MapEditor.data.gamemodes[id] then
        MapEditor.data.gamemodes[id] = nil
    else
        MapEditor.data.gamemodes[id] = true
    end
    MapEditor.dirty = true
    MapEditor.Push()
end

function MapEditor.SnapToPlayer()
    if not MapEditor.selection then return end
    local layer = MapEditor.FindLayer(MapEditor.selection.layer)
    if not layer then return end
    local pos = GetEntityCoords(PlayerPedId())
    snapshot()
    MapEditor.Move(layer, MapEditor.selection.index, pos.x, pos.y)
    if layer.vec == 4 then
        local point = MapEditor.PointAt(layer, MapEditor.selection.index)
        MapEditor.Rotate(layer, MapEditor.selection.index, GetEntityHeading(PlayerPedId()) - point.w)
    end
    MapEditor.Push()
end

Citizen.CreateThread(function()
    while true do
        if MapEditor.active and MapEditor.mode == "edit" then
            MapEditorCam.Step()
            local focus = MapEditorCam.focus
            SetFocusArea(focus.x, focus.y, focus.z, 0.0, 0.0, 0.0)

            if MapEditor.hiddenUntil then
                if GetGameTimer() >= MapEditor.hiddenUntil then
                    MapEditor.hiddenUntil = nil
                    MapEditor.Push()
                end
            else
                MapEditorCam.world = MapEditorCam.CursorWorld()
                if dragging then
                    MapEditor.DragPoint()
                else
                    MapEditor.hover = MapEditorDraw.Pick()
                end
                MapEditorDraw.Frame()
            end

            DisableAllControlActions(0)
            Wait(0)
        else
            Wait(300)
        end
    end
end)

RegisterCommand("mapeditor", function(source, args)
    if not canEdit() then return end
    if MapEditor.active then
        MapEditor.Close()
        return
    end
    local name = string.upper(tostring(args[1] or ""))
    if SharedConfig.Maps[name] then
        MapEditor.Open(name)
    else
        MapEditor.Enter()
    end
end, false)

RegisterNetEvent("warv:MapUpdated", function(name, data)
    MapStore.ApplyOne(name, data)
end)

AddEventHandler("warv-ui:mapEditorInput", function(data)
    if not (MapEditor.active and data) then return end
    local kind = data.kind

    if kind == "move" then
        MapEditorCam.SetCursor(tonumber(data.x) or 0.5, tonumber(data.y) or 0.5)
    elseif kind == "pan" then
        MapEditorCam.Pan(tonumber(data.dx) or 0, tonumber(data.dy) or 0)
    elseif kind == "orbit" then
        MapEditorCam.Orbit((tonumber(data.dx) or 0) * 120.0)
        MapEditorCam.Tilt((tonumber(data.dy) or 0) * 80.0)
    elseif kind == "zoom" then
        MapEditorCam.Zoom(tonumber(data.dy) or 0)
        MapEditor.Push()
    elseif kind == "down" then
        MapEditor.Click(data.shift == true)
    elseif kind == "up" then
        MapEditor.Release()
    end
end)
