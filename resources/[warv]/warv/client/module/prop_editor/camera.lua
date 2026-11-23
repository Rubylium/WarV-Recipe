PropEditorCam = {}
PropEditorCam.handle = 0
PropEditorCam.pos = vector3(0.0, 0.0, 0.0)
PropEditorCam.pitch = -15.0
PropEditorCam.yaw = 0.0
PropEditorCam.speed = 14.0
PropEditorCam.boost = false
PropEditorCam.move = { forward = 0, right = 0, up = 0 }
PropEditorCam.cursor = { x = 0.5, y = 0.5 }
PropEditorCam.looking = false
PropEditorCam.over = false
PropEditorCam.target = nil

local fov = 55.0
local lookSpeed = 8.0
local minSpeed = 1.5
local maxSpeed = 160.0
local last = 0

function PropEditorCam.Forward()
    return MapEditorCam.Direction(PropEditorCam.pitch, PropEditorCam.yaw)
end

function PropEditorCam.Update()
    if PropEditorCam.handle == 0 then return end
    SetCamCoord(PropEditorCam.handle, PropEditorCam.pos.x, PropEditorCam.pos.y, PropEditorCam.pos.z)
    SetCamRot(PropEditorCam.handle, PropEditorCam.pitch, 0.0, PropEditorCam.yaw, 2)
end

function PropEditorCam.Start(pos, heading)
    LobbyCam.running = false

    PropEditorCam.pos = pos
    PropEditorCam.yaw = heading or 0.0
    PropEditorCam.pitch = -12.0
    PropEditorCam.target = nil
    last = GetGameTimer()

    if PropEditorCam.handle == 0 then
        PropEditorCam.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    SetCamFov(PropEditorCam.handle, fov)
    PropEditorCam.Update()
    RenderScriptCams(true, false, 0, true, true)
end

function PropEditorCam.Resume()
    if PropEditorCam.handle == 0 then return end
    SetCamActive(PropEditorCam.handle, true)
    RenderScriptCams(true, false, 0, true, true)
    PropEditorCam.Update()
end

function PropEditorCam.Stop()
    ClearFocus()
    PropEditorCam.move.forward, PropEditorCam.move.right, PropEditorCam.move.up = 0, 0, 0
    PropEditorCam.StopLook()
    PropEditorCam.over = false
    if PropEditorCam.handle ~= 0 then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(PropEditorCam.handle, false)
        PropEditorCam.handle = 0
    end
end

function PropEditorCam.StartLook()
    if PropEditorCam.looking then return end
    PropEditorCam.looking = true
    exports['warv-ui']:SetEditorCursor(false)
end

function PropEditorCam.StopLook()
    if not PropEditorCam.looking then return end
    PropEditorCam.looking = false
    exports['warv-ui']:SetEditorCursor(true)
end

local function held(control)
    return IsDisabledControlPressed(0, control) and 1 or 0
end

function PropEditorCam.ReadInput()
    local move = PropEditorCam.move
    if PropEditor.typing then
        move.forward, move.right, move.up = 0, 0, 0
        PropEditorCam.boost = false
        return
    end

    move.forward = held(32) - held(33)
    move.right = held(35) - held(34)
    move.up = held(22) - held(36)
    PropEditorCam.boost = IsDisabledControlPressed(0, 21)

    if not PropEditorCam.looking then return end
    if not IsDisabledControlPressed(0, 25) then
        PropEditorCam.StopLook()
        return
    end

    local dx = GetDisabledControlNormal(0, 1)
    local dy = GetDisabledControlNormal(0, 2)
    if dx == 0.0 and dy == 0.0 then return end

    PropEditorCam.yaw = (PropEditorCam.yaw - dx * lookSpeed) % 360.0
    PropEditorCam.pitch = math.max(-89.0, math.min(89.0, PropEditorCam.pitch - dy * lookSpeed))
    PropEditorCam.Update()
end

function PropEditorCam.SetSpeed(delta)
    PropEditorCam.speed = math.max(minSpeed, math.min(maxSpeed, PropEditorCam.speed * (1.0 + delta * 0.18)))
end

function PropEditorCam.SetCursor(x, y)
    PropEditorCam.cursor.x = x
    PropEditorCam.cursor.y = y
end

function PropEditorCam.Cursor()
    return PropEditorCam.looking and { x = 0.5, y = 0.5 } or PropEditorCam.cursor
end

function PropEditorCam.FocusOn(pos)
    local back = PropEditorCam.Forward() * -8.0
    PropEditorCam.target = pos + back + vector3(0.0, 0.0, 2.5)
end

function PropEditorCam.Step()
    local now = GetGameTimer()
    local dt = math.min(0.12, (now - last) / 1000.0)
    last = now

    if PropEditorCam.target then
        local delta = PropEditorCam.target - PropEditorCam.pos
        if #(delta) < 0.4 then
            PropEditorCam.pos = PropEditorCam.target
            PropEditorCam.target = nil
        else
            PropEditorCam.pos = PropEditorCam.pos + delta * 0.18
        end
        PropEditorCam.Update()
        return
    end

    local move = PropEditorCam.move
    if move.forward == 0 and move.right == 0 and move.up == 0 then return end

    local yaw = math.rad(PropEditorCam.yaw)
    local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)
    local step = PropEditorCam.speed * (PropEditorCam.boost and 4.0 or 1.0) * dt

    PropEditorCam.pos = PropEditorCam.pos
        + PropEditorCam.Forward() * (move.forward * step)
        + right * (move.right * step)
        + vector3(0.0, 0.0, move.up * step)
    PropEditorCam.Update()
end

function PropEditorCam.Ray()
    if PropEditorCam.handle == 0 then return nil, nil end

    local dir = MapEditorCam.CursorRay(PropEditorCam.Forward(), PropEditorCam.Cursor(), fov)
    if not dir then return nil, nil end
    return PropEditorCam.pos, dir
end
