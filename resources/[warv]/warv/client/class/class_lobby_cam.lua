LobbyCam = {}
LobbyCam.handle = nil
LobbyCam.rendering = false
LobbyCam.running = false

LobbyCam.pos = vector3(0.0, 0.0, 0.0)
LobbyCam.look = vector3(0.0, 0.0, 0.0)
LobbyCam.fov = 10.0
LobbyCam.tPos = LobbyCam.pos
LobbyCam.tLook = LobbyCam.look
LobbyCam.tFov = LobbyCam.fov
LobbyCam.idle = 0.0
LobbyCam.posK = 0.05
LobbyCam.lookK = 0.06
LobbyCam.fovK = 0.07
LobbyCam.lookFn = nil
LobbyCam.dof = false
LobbyCam.dofStrength = 1.0
LobbyCam.dofNear = 0.5
LobbyCam.dofFar = 8.0

local function ease(cur, tgt, k, f)
    return cur + (tgt - cur) * (1.0 - (1.0 - k) ^ f)
end
local function easeV(cur, tgt, k, f)
    return vector3(ease(cur.x, tgt.x, k, f), ease(cur.y, tgt.y, k, f), ease(cur.z, tgt.z, k, f))
end

function LobbyCam.Get()
    return LobbyCam.handle
end

function LobbyCam.Ensure()
    if LobbyCam.handle and DoesCamExist(LobbyCam.handle) then
        LobbyCam.StartLoop()
        return
    end
    LobbyCam.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(LobbyCam.handle, LobbyCam.pos.x, LobbyCam.pos.y, LobbyCam.pos.z)
    PointCamAtCoord(LobbyCam.handle, LobbyCam.look.x, LobbyCam.look.y, LobbyCam.look.z)
    SetCamFov(LobbyCam.handle, LobbyCam.fov)
    SetCamActive(LobbyCam.handle, true)
    RenderScriptCams(true, false, 0, true, true)
    LobbyCam.rendering = true
    LobbyCam.StartLoop()
end

function LobbyCam.SetTarget(pos, look, fov, opts)
    opts = opts or {}
    if pos then LobbyCam.tPos = pos end
    if look then LobbyCam.tLook = look end
    if fov then LobbyCam.tFov = fov end
    LobbyCam.idle = opts.idle or 0.0
    LobbyCam.posK = opts.posK or 0.05
    LobbyCam.lookK = opts.lookK or 0.06
    LobbyCam.fovK = opts.fovK or 0.07
    LobbyCam.lookFn = opts.lookFn
    LobbyCam.dof = opts.dof == true
    LobbyCam.dofStrength = opts.dofStrength or 1.0
    LobbyCam.dofNear = opts.dofNear or 0.5
    LobbyCam.dofFar = opts.dofFar or 8.0
    if LobbyCam.lookFn then
        local lf = LobbyCam.lookFn()
        if lf then LobbyCam.tLook = lf end
    end
    if opts.snap then
        LobbyCam.pos, LobbyCam.look, LobbyCam.fov = LobbyCam.tPos, LobbyCam.tLook, LobbyCam.tFov
        if LobbyCam.handle and DoesCamExist(LobbyCam.handle) then
            SetCamCoord(LobbyCam.handle, LobbyCam.pos.x, LobbyCam.pos.y, LobbyCam.pos.z)
            PointCamAtCoord(LobbyCam.handle, LobbyCam.look.x, LobbyCam.look.y, LobbyCam.look.z)
            SetCamFov(LobbyCam.handle, LobbyCam.fov)
        end
    end
end

function LobbyCam.SetFov(fov)
    if fov then LobbyCam.tFov = fov end
end

function LobbyCam.StartLoop()
    if LobbyCam.running then return end
    LobbyCam.running = true
    Citizen.CreateThread(function()
        local lastT = GetGameTimer()
        while LobbyCam.running and LobbyCam.handle and DoesCamExist(LobbyCam.handle) do
            local now = GetGameTimer()
            local f = (now - lastT) / 1000.0 * 60.0
            lastT = now
            if f < 0.05 then f = 0.05 elseif f > 4.0 then f = 4.0 end

            if LobbyCam.lookFn then
                local lf = LobbyCam.lookFn()
                if lf then LobbyCam.tLook = lf end
            end

            LobbyCam.pos = easeV(LobbyCam.pos, LobbyCam.tPos, LobbyCam.posK, f)
            LobbyCam.look = easeV(LobbyCam.look, LobbyCam.tLook, LobbyCam.lookK, f)
            LobbyCam.fov = ease(LobbyCam.fov, LobbyCam.tFov, LobbyCam.fovK, f)

            local ax, ay, az, lx, ly = 0.0, 0.0, 0.0, 0.0, 0.0
            if LobbyCam.idle > 0.0 then
                local tt = now / 1000.0
                local a = LobbyCam.idle
                ax = (math.sin(tt * 0.55) + math.sin(tt * 0.27) * 0.5) * 0.018 * a
                ay = math.sin(tt * 0.31 + 0.7) * 0.012 * a
                az = math.sin(tt * 0.43 + 1.3) * 0.014 * a
                lx = math.sin(tt * 0.37 + 2.1) * 0.012 * a
                ly = math.sin(tt * 0.29 + 0.4) * 0.010 * a
            end

            SetCamCoord(LobbyCam.handle, LobbyCam.pos.x + ax, LobbyCam.pos.y + ay, LobbyCam.pos.z + az)
            PointCamAtCoord(LobbyCam.handle, LobbyCam.look.x + lx, LobbyCam.look.y + ly, LobbyCam.look.z)
            SetCamFov(LobbyCam.handle, LobbyCam.fov)
            SetFocusPosAndVel(LobbyCam.look.x, LobbyCam.look.y, LobbyCam.look.z, 0.0, 0.0, 0.0)

            if LobbyCam.dof then
                SetUseHiDof()
                SetCamUseShallowDofMode(LobbyCam.handle, true)
                SetCamDofStrength(LobbyCam.handle, LobbyCam.dofStrength)
                SetCamNearDof(LobbyCam.handle, LobbyCam.dofNear)
                SetCamFarDof(LobbyCam.handle, LobbyCam.dofFar)
                SetCamDofFnumberOfLens(LobbyCam.handle, 1.2)
            end

            Wait(0)
        end
        LobbyCam.running = false
    end)
end

function LobbyCam.Stop()
    LobbyCam.running = false
    if LobbyCam.handle and DoesCamExist(LobbyCam.handle) then
        SetCamActive(LobbyCam.handle, false)
        DestroyCam(LobbyCam.handle, false)
    end
    LobbyCam.handle = nil
    if LobbyCam.rendering then
        RenderScriptCams(false, false, 0, true, true)
        LobbyCam.rendering = false
    end
    ClearFocus()
end
