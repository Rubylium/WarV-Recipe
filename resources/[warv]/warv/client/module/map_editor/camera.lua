MapEditorCam = {}
MapEditorCam.handle = 0
MapEditorCam.focus = vector3(0.0, 0.0, 0.0)
MapEditorCam.height = 120.0
MapEditorCam.pitch = -80.0
MapEditorCam.yaw = 0.0
MapEditorCam.cursor = { x = 0.5, y = 0.5 }
MapEditorCam.world = nil

MapEditorCam.target = nil

local minHeight = 4.0
local maxHeight = 400.0
local fov = 50.0

function MapEditorCam.Direction(pitch, yaw)
    local p, y = math.rad(pitch), math.rad(yaw)
    local cosP = math.abs(math.cos(p))
    return vector3(-math.sin(y) * cosP, math.cos(y) * cosP, math.sin(p))
end

function MapEditorCam.CursorRay(forward, cursor, camFov)
    local right = vector3(forward.y, -forward.x, 0.0)
    if #(right) < 0.0001 then return nil end
    right = right / #(right)
    local up = vector3(right.y * forward.z, -right.x * forward.z, right.x * forward.y - right.y * forward.x)

    local tanHalf = math.tan(math.rad(camFov) * 0.5)
    local dir = forward
        + right * ((cursor.x - 0.5) * 2.0 * tanHalf * GetAspectRatio(false))
        + up * ((0.5 - cursor.y) * 2.0 * tanHalf)
    if #(dir) < 0.0001 then return nil end
    return dir / #(dir)
end

local function camPosition()
    local back = MapEditorCam.Direction(MapEditorCam.pitch, MapEditorCam.yaw) * -1.0
    local distance = MapEditorCam.height / math.max(0.2, math.abs(math.sin(math.rad(MapEditorCam.pitch))))
    return MapEditorCam.focus + back * distance
end

function MapEditorCam.Start(focus)
    LobbyCam.running = false

    MapEditorCam.focus = focus or MapEditorCam.focus
    if MapEditorCam.handle == 0 then
        MapEditorCam.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    SetCamFov(MapEditorCam.handle, fov)
    MapEditorCam.Update()
    RenderScriptCams(true, false, 0, true, true)
end

function MapEditorCam.Stop()
    ClearFocus()
    if MapEditorCam.handle ~= 0 then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(MapEditorCam.handle, false)
        MapEditorCam.handle = 0
    end
end

function MapEditorCam.Update()
    if MapEditorCam.handle == 0 then return end
    local pos = camPosition()
    SetCamCoord(MapEditorCam.handle, pos.x, pos.y, pos.z)
    SetCamRot(MapEditorCam.handle, MapEditorCam.pitch, 0.0, MapEditorCam.yaw, 2)
end

function MapEditorCam.Zoom(delta)
    MapEditorCam.height = math.max(minHeight, math.min(maxHeight, MapEditorCam.height * (1.0 - delta * 0.07)))
    MapEditorCam.Update()
end

function MapEditorCam.Pan(dx, dy)
    local speed = MapEditorCam.height * 0.7
    local y = math.rad(MapEditorCam.yaw)
    local right = vector3(math.cos(y), math.sin(y), 0.0)
    local forward = vector3(-math.sin(y), math.cos(y), 0.0)
    MapEditorCam.target = nil
    MapEditorCam.focus = MapEditorCam.focus - right * (dx * speed) + forward * (dy * speed)
    MapEditorCam.Update()
end

function MapEditorCam.FocusOn(pos)
    MapEditorCam.target = pos
end

function MapEditorCam.Step()
    local moved = false

    if MapEditorCam.target then
        local delta = MapEditorCam.target - MapEditorCam.focus
        if #(delta) < 0.2 then
            MapEditorCam.focus = MapEditorCam.target
            MapEditorCam.target = nil
        else
            MapEditorCam.focus = MapEditorCam.focus + delta * 0.16
        end
        moved = true
    end

    local ground = MapEditor.GroundZ(MapEditorCam.focus.x, MapEditorCam.focus.y)
    if ground and math.abs(ground - MapEditorCam.focus.z) > 0.05 then
        local z = MapEditorCam.focus.z + (ground - MapEditorCam.focus.z) * 0.2
        MapEditorCam.focus = vector3(MapEditorCam.focus.x, MapEditorCam.focus.y, z)
        moved = true
    end

    if moved then MapEditorCam.Update() end
end

function MapEditorCam.Orbit(delta)
    MapEditorCam.yaw = (MapEditorCam.yaw + delta) % 360.0
    MapEditorCam.Update()
end

function MapEditorCam.Tilt(delta)
    MapEditorCam.pitch = math.max(-89.0, math.min(-20.0, MapEditorCam.pitch + delta))
    MapEditorCam.Update()
end

function MapEditorCam.SetCursor(x, y)
    MapEditorCam.cursor.x = x
    MapEditorCam.cursor.y = y
end

function MapEditorCam.CursorWorld()
    if MapEditorCam.handle == 0 then return nil end
    local origin = camPosition()
    local dir = MapEditorCam.CursorRay(MapEditorCam.Direction(MapEditorCam.pitch, MapEditorCam.yaw), MapEditorCam.cursor, fov)
    if not dir then return nil end

    local far = origin + dir * 2000.0
    local probe = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, far.x, far.y, far.z, 1 + 16, 0, 4)
    local _, hit, endCoords = GetShapeTestResult(probe)
    if hit == 1 then return endCoords end

    if math.abs(dir.z) < 0.0001 then return nil end
    local t = (MapEditorCam.focus.z - origin.z) / dir.z
    if t <= 0 then return nil end
    return origin + dir * t
end
