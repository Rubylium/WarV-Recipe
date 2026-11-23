Gunsmith = {}
Gunsmith.active = false
Gunsmith.entity = 0
Gunsmith.yaw = 0.0
Gunsmith.pitch = 0.0
Gunsmith.targetYaw = 0.0
Gunsmith.targetPitch = 0.0
Gunsmith.anchors = {}
Gunsmith.slotMeta = {}
Gunsmith.localCenter = nil
Gunsmith.baseCenter = nil
Gunsmith.targetCenter = nil
Gunsmith.rebuildCenter = nil
Gunsmith.weapon = ""
Gunsmith.editing = false
Gunsmith.overrides = {}

local defaultAnchors = {
    scope      = { b = 0.50, h = 0.0 },
    flashlight = { b = 0.26, h = 0.0 },
    muzzle     = { b = 0.02, h = 0.45 },
    barrel     = { b = 0.20, h = 0.18 },
    grip       = { b = 0.44, h = 1.0 },
    clip       = { b = 0.66, h = 1.0 },
    rail       = { b = 0.36, h = 0.0 },
    finish     = { b = 0.78, h = 0.35 },
    tint       = { b = 0.92, h = 0.62 },
    bore       = { b = 0.12, h = 0.28 },
    trigger    = { b = 0.58, h = 0.80 },
    buffer     = { b = 0.70, h = 0.52 },
    weight     = { b = 0.90, h = 0.14 },
}

local anchorFile = "data/attachment_anchors.json"
local baseYaw = 180.0
local smoothing = 0.22
local yawSens = 240.0
local pitchSens = 170.0
local pitchLimit = 82.0

local frame

local function anchorDef(slot)
    local perWeapon = Gunsmith.overrides[Gunsmith.weapon]
    return (perWeapon and perWeapon[slot]) or defaultAnchors[slot]
end

local function anchorPoint(a)
    local b = frame.muzzle + (frame.stock - frame.muzzle) * a.b
    local h = frame.topZ + (frame.botZ - frame.topZ) * a.h
    if frame.barrelIsX then return vector3(b, frame.midY, h) end
    return vector3(frame.midX, b, h)
end

local function weaponOffset()
    local perWeapon = Gunsmith.overrides[Gunsmith.weapon]
    return perWeapon and perWeapon.offset
end

local function applyOffset()
    if not Gunsmith.baseCenter then return end
    local offset = weaponOffset()
    if offset then
        Gunsmith.targetCenter = Gunsmith.baseCenter + vector3(offset.x, offset.y, offset.z)
    else
        Gunsmith.targetCenter = Gunsmith.baseCenter
    end
end

function Gunsmith.LoadOverrides()
    local raw = LoadResourceFile(GetCurrentResourceName(), anchorFile)
    if not raw then return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then Gunsmith.overrides = data end
end

Gunsmith.LoadOverrides()

local function projLocal(entity, x, y, z)
    local w = GetOffsetFromEntityInWorldCoords(entity, x, y, z)
    return World3dToScreen2d(w.x, w.y, w.z)
end

local function camAxes()
    local fwd = LobbyCam.tLook - LobbyCam.tPos
    if #(fwd) < 0.0001 then return nil end
    fwd = fwd / #(fwd)
    local right = vector3(fwd.y, -fwd.x, 0.0)
    if #(right) < 0.0001 then return nil end
    right = right / #(right)
    local up = vector3(right.y * fwd.z - right.z * fwd.y,
        right.z * fwd.x - right.x * fwd.z,
        right.x * fwd.y - right.y * fwd.x)
    return right, up
end

local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function Gunsmith.ComputeAnchors(entity, preservedCenter)
    Gunsmith.anchors = {}
    if not (entity and DoesEntityExist(entity)) then return end
    local minV, maxV = GetModelDimensions(GetEntityModel(entity))
    local sizeX, sizeY = maxV.x - minV.x, maxV.y - minV.y
    local barrelIsX = sizeX >= sizeY
    local midX = (minV.x + maxV.x) * 0.5
    local midY = (minV.y + maxV.y) * 0.5
    local midZ = (minV.z + maxV.z) * 0.5

    local right, camUp = camAxes()

    local aMin, aMax = (barrelIsX and minV.x or minV.y), (barrelIsX and maxV.x or maxV.y)
    local muzzle, stock = aMin, aMax
    if right then
        local pA = GetOffsetFromEntityInWorldCoords(entity, barrelIsX and minV.x or midX, barrelIsX and midY or minV.y, midZ)
        local pB = GetOffsetFromEntityInWorldCoords(entity, barrelIsX and maxV.x or midX, barrelIsX and midY or maxV.y, midZ)
        if dot(pA, right) > dot(pB, right) then muzzle, stock = aMax, aMin end
    else
        local okA, axA = projLocal(entity, barrelIsX and minV.x or midX, barrelIsX and midY or minV.y, midZ)
        local okB, axB = projLocal(entity, barrelIsX and maxV.x or midX, barrelIsX and midY or maxV.y, midZ)
        if okA and okB and axA > axB then muzzle, stock = aMax, aMin end
    end

    local topZ, botZ = maxV.z, minV.z
    if camUp then
        local pT = GetOffsetFromEntityInWorldCoords(entity, midX, midY, maxV.z)
        local pBo = GetOffsetFromEntityInWorldCoords(entity, midX, midY, minV.z)
        if dot(pT, camUp) < dot(pBo, camUp) then topZ, botZ = minV.z, maxV.z end
    else
        local okT, _, syT = projLocal(entity, midX, midY, maxV.z)
        local okBo, _, syBo = projLocal(entity, midX, midY, minV.z)
        if okT and okBo and syT > syBo then topZ, botZ = minV.z, maxV.z end
    end

    frame = {
        barrelIsX = barrelIsX,
        muzzle = muzzle,
        stock = stock,
        topZ = topZ,
        botZ = botZ,
        midX = midX,
        midY = midY,
    }
    for slot in pairs(defaultAnchors) do
        Gunsmith.anchors[slot] = anchorPoint(anchorDef(slot))
    end

    Gunsmith.localCenter = vector3(midX, midY, midZ)
    Gunsmith.baseCenter = GetOffsetFromEntityInWorldCoords(entity, midX, midY, midZ)
    if preservedCenter then
        local offset = weaponOffset()
        Gunsmith.targetCenter = preservedCenter
        if offset then
            Gunsmith.baseCenter = preservedCenter - vector3(offset.x, offset.y, offset.z)
        else
            Gunsmith.baseCenter = preservedCenter
        end
    else
        applyOffset()
    end
end

function Gunsmith.MoveAnchor(slot, dx, dy)
    local a = anchorDef(slot)
    if not (a and frame and DoesEntityExist(Gunsmith.entity)) then return end

    local step = 0.02
    local at = anchorPoint(a)
    local alongB = anchorPoint({ b = a.b + step, h = a.h })
    local alongH = anchorPoint({ b = a.b, h = a.h + step })
    local ok, x0, y0 = projLocal(Gunsmith.entity, at.x, at.y, at.z)
    local okB, xb, yb = projLocal(Gunsmith.entity, alongB.x, alongB.y, alongB.z)
    local okH, xh, yh = projLocal(Gunsmith.entity, alongH.x, alongH.y, alongH.z)
    if not (ok and okB and okH) then return end

    local bx, by = (xb - x0) / step, (yb - y0) / step
    local hx, hy = (xh - x0) / step, (yh - y0) / step
    local det = bx * hy - hx * by
    if math.abs(det) < 0.0001 then return end

    local moved = {
        b = math.max(-0.2, math.min(1.2, a.b + (dx * hy - dy * hx) / det)),
        h = math.max(-0.2, math.min(1.2, a.h + (bx * dy - by * dx) / det)),
    }

    local perWeapon = Gunsmith.overrides[Gunsmith.weapon] or {}
    perWeapon[slot] = moved
    Gunsmith.overrides[Gunsmith.weapon] = perWeapon
    Gunsmith.anchors[slot] = anchorPoint(moved)
end

function Gunsmith.MoveWeapon(dx, dy)
    local at = Gunsmith.targetCenter
    if not (at and DoesEntityExist(Gunsmith.entity)) then return end
    local right, up = camAxes()
    if not right then return end

    local step = 0.02
    local ok, x0, y0 = World3dToScreen2d(at.x, at.y, at.z)
    local okR, xr, yr = World3dToScreen2d(at.x + right.x * step, at.y + right.y * step, at.z + right.z * step)
    local okU, xu, yu = World3dToScreen2d(at.x + up.x * step, at.y + up.y * step, at.z + up.z * step)
    if not (ok and okR and okU) then return end

    local rx, ry = (xr - x0) / step, (yr - y0) / step
    local ux, uy = (xu - x0) / step, (yu - y0) / step
    local det = rx * uy - ux * ry
    if math.abs(det) < 0.0001 then return end

    local dr = (dx * uy - dy * ux) / det
    local du = (rx * dy - ry * dx) / det

    local offset = weaponOffset() or { x = 0.0, y = 0.0, z = 0.0 }
    local moved = {
        x = math.max(-0.5, math.min(0.5, offset.x + right.x * dr + up.x * du)),
        y = math.max(-0.5, math.min(0.5, offset.y + right.y * dr + up.y * du)),
        z = math.max(-0.5, math.min(0.5, offset.z + right.z * dr + up.z * du)),
    }

    local perWeapon = Gunsmith.overrides[Gunsmith.weapon] or {}
    perWeapon.offset = moved
    Gunsmith.overrides[Gunsmith.weapon] = perWeapon
    applyOffset()
end

function Gunsmith.ResetOffset()
    local perWeapon = Gunsmith.overrides[Gunsmith.weapon]
    if not perWeapon then return end
    perWeapon.offset = nil
    if not next(perWeapon) then Gunsmith.overrides[Gunsmith.weapon] = nil end
    applyOffset()
end

function Gunsmith.ResetAnchor(slot)
    local perWeapon = Gunsmith.overrides[Gunsmith.weapon]
    if not perWeapon then return end
    perWeapon[slot] = nil
    if not next(perWeapon) then Gunsmith.overrides[Gunsmith.weapon] = nil end
    Gunsmith.anchors[slot] = anchorPoint(anchorDef(slot))
end

function Gunsmith.SetEditing(editing)
    Gunsmith.editing = editing
    if not editing then TriggerServerEvent("warv:SaveAttachAnchors", Gunsmith.overrides) end
end

function Gunsmith.Prepare(entity)
    if not (entity and DoesEntityExist(entity)) then return end
    SetEntityRotation(entity, 0.0, 0.0, baseYaw, 2, false)
end

function Gunsmith.CaptureRebuildCenter()
    Gunsmith.rebuildCenter = nil
    if not Gunsmith.active then return end
    local center = Gunsmith.targetCenter
    if Gunsmith.localCenter and DoesEntityExist(Gunsmith.entity) then
        center = GetOffsetFromEntityInWorldCoords(Gunsmith.entity,
            Gunsmith.localCenter.x, Gunsmith.localCenter.y, Gunsmith.localCenter.z)
    end
    if not center then return end
    Gunsmith.rebuildCenter = vector3(center.x, center.y, center.z)
    Gunsmith.entity = 0
end

function Gunsmith.Begin()
    Gunsmith.active = true
    Gunsmith.entity = 0
    Gunsmith.localCenter = nil
    Gunsmith.baseCenter = nil
    Gunsmith.targetCenter = nil
    Gunsmith.rebuildCenter = nil
    Gunsmith.yaw, Gunsmith.pitch = 0.0, 0.0
    Gunsmith.targetYaw, Gunsmith.targetPitch = 0.0, 0.0
end

function Gunsmith.Stop()
    Gunsmith.active = false
    Gunsmith.rebuildCenter = nil
    if Gunsmith.editing then Gunsmith.SetEditing(false) end
    exports['warv-ui']:SetAttachMarkers({})
end

function Gunsmith.AddDrag(dx, dy)
    Gunsmith.targetYaw = Gunsmith.targetYaw + (tonumber(dx) or 0) * yawSens
    Gunsmith.targetPitch = Gunsmith.targetPitch - (tonumber(dy) or 0) * pitchSens
    if Gunsmith.targetPitch > pitchLimit then Gunsmith.targetPitch = pitchLimit end
    if Gunsmith.targetPitch < -pitchLimit then Gunsmith.targetPitch = -pitchLimit end
end

function Gunsmith.Spin(dir)
    Gunsmith.targetYaw = Gunsmith.targetYaw - (tonumber(dir) or 0) * 90.0
end

function Gunsmith.Reset()
    Gunsmith.targetYaw, Gunsmith.targetPitch = 0.0, 0.0
end

function Gunsmith.ProjectMarkers(obj)
    local out = {}
    local okc, cx, cy = false, 0.5, 0.5
    if Gunsmith.targetCenter then
        okc, cx, cy = World3dToScreen2d(Gunsmith.targetCenter.x, Gunsmith.targetCenter.y, Gunsmith.targetCenter.z)
    end
    for _, m in ipairs(Gunsmith.slotMeta) do
        local a = Gunsmith.anchors[m.slot]
        if a then
            local w = GetOffsetFromEntityInWorldCoords(obj, a.x, a.y, a.z)
            local ok, sx, sy = World3dToScreen2d(w.x, w.y, w.z)
            if ok then
                local side
                local dx, dy = sx - (okc and cx or 0.5), sy - (okc and cy or 0.5)
                if math.abs(dx) > math.abs(dy) then
                    side = dx < 0 and "left" or "right"
                else
                    side = dy < 0 and "top" or "bottom"
                end
                out[#out + 1] = {
                    slot = m.slot,
                    label = m.label,
                    installed = m.installed or "",
                    internal = m.internal == true,
                    x = sx,
                    y = sy,
                    side = side,
                }
            end
        end
    end
    exports['warv-ui']:SetAttachMarkers(out)
end

function Gunsmith.Update()
    if not Gunsmith.active then return end
    if not LobbyWeapons.RefreshDone then return end
    local obj = LobbyWeapons.obj
    if obj == 0 or not DoesEntityExist(obj) then return end

    if obj ~= Gunsmith.entity then
        Gunsmith.entity = obj
        SetEntityRotation(obj, 0.0, 0.0, baseYaw, 2, false)
        local preservedCenter = Gunsmith.rebuildCenter
        Gunsmith.rebuildCenter = nil
        Gunsmith.ComputeAnchors(obj, preservedCenter)
    end

    Gunsmith.yaw = Gunsmith.yaw + (Gunsmith.targetYaw - Gunsmith.yaw) * smoothing
    Gunsmith.pitch = Gunsmith.pitch + (Gunsmith.targetPitch - Gunsmith.pitch) * smoothing

    SetEntityRotation(obj, Gunsmith.pitch, 0.0, baseYaw + Gunsmith.yaw, 2, false)

    if Gunsmith.localCenter and Gunsmith.targetCenter then
        local cur = GetOffsetFromEntityInWorldCoords(obj, Gunsmith.localCenter.x, Gunsmith.localCenter.y, Gunsmith.localCenter.z)
        local ep = GetEntityCoords(obj, true)
        SetEntityCoordsNoOffset(obj,
            ep.x + (Gunsmith.targetCenter.x - cur.x),
            ep.y + (Gunsmith.targetCenter.y - cur.y),
            ep.z + (Gunsmith.targetCenter.z - cur.z), false, false, false)
    end

    Gunsmith.ProjectMarkers(obj)
end

AddEventHandler("warv-ui:gunsmithDrag", function(data)
    if data then Gunsmith.AddDrag(data.dx, data.dy) end
end)

AddEventHandler("warv-ui:gunsmithAnchorDrag", function(data)
    if Gunsmith.editing and data and data.slot then
        Gunsmith.MoveAnchor(data.slot, tonumber(data.dx) or 0, tonumber(data.dy) or 0)
    end
end)

AddEventHandler("warv-ui:gunsmithMove", function(data)
    if Gunsmith.editing and data then
        Gunsmith.MoveWeapon(tonumber(data.dx) or 0, tonumber(data.dy) or 0)
    end
end)
