LobbyPlacement = {}

LobbyPlacement.BaseFov = 3.8
LobbyPlacement.objPos = vector4(351.7802734375, 4838.6459960938, -58.999450683594, 199.54891967773)
LobbyPlacement.obj = "vw_prop_vw_table_01a"
LobbyPlacement.objEntity = nil
LobbyPlacement.customCamPos = vector3(0, 0, 0)
function LobbyPlacement.GetCorrectFovForPlayersNumber(players)
    local numberToUse = #players
    if numberToUse > 4 then
        numberToUse = 4
    end
    return LobbyPlacement.BaseFov + (2.00 * numberToUse)
end

function LobbyPlacement.LoadPlayerSkin()
    Citizen.CreateThread(function()
        Appearance.LoadPlayer(0)
    end)
end

function LobbyPlacement.SetupObject()
    if LobbyLayout.Weapon() then return end
    if LobbyPlacement.objEntity == nil then
        LoadModel(LobbyPlacement.obj)
        LobbyPlacement.objEntity = CreateObject(GetHashKey(LobbyPlacement.obj), LobbyPlacement.objPos.xyz, false, true, false)
        SetEntityHeading(LobbyPlacement.objEntity, LobbyPlacement.objPos.w + 180)
        PlaceObjectOnGroundProperly(LobbyPlacement.objEntity)
        LobbyPlacement.customCamPos = GetOffsetFromEntityInWorldCoords(LobbyPlacement.objEntity, 1.5, -2.0, 1.5)
    end
end

function LobbyPlacement.StandPos()
    local weapon = LobbyLayout.Weapon()
    if weapon then return vector3(weapon.x, weapon.y, weapon.z) end
    LobbyPlacement.SetupObject()
    return GetEntityCoords(LobbyPlacement.objEntity, true)
end

local lobbyLookDrop = 0.30

function LobbyPlacement.MainLobbyLook()
    local sum = vector3(0.0, 0.0, 0.0)
    local n = 0
    for _, ent in pairs(PlayersDisplay.Entitys) do
        if DoesEntityExist(ent) then
            sum = sum + GetPedBoneCoords(ent, 0x796E, 0.0, 0.0, 0.0)
            n = n + 1
        end
    end
    if n > 0 then
        return vector3(sum.x / n, sum.y / n, sum.z / n - lobbyLookDrop)
    end
    return vector3(PlayersDisplay.Poses[1].pos.x, PlayersDisplay.Poses[1].pos.y, PlayersDisplay.Poses[1].pos.z + 1.3)
end

function LobbyPlacement.MainLobbyPose()
    return vector3(PlayersDisplay.LobbyPosition.x, PlayersDisplay.LobbyPosition.y, PlayersDisplay.LobbyPosition.z + 0.8),
        LobbyPlacement.MainLobbyLook(),
        PlayersDisplay.LobbyCachedFov or PlayersDisplay.LobbyDefaultFov
end

function LobbyPlacement.GoToMainLobby(snap)
    if Status.GetIsPlayerInEndScreen() or Gamemode.Playing then return end
    LobbyPlacement.SetupObject()
    LobbyCam.Ensure()

    local cam = LobbyLayout.Cam("main")
    if cam then
        local pos, look, fov, opts = LobbyLayout.CamVectors(cam)
        opts.snap = snap
        LobbyCam.SetTarget(pos, look, fov, opts)
        return
    end

    local pos, look, fov = LobbyPlacement.MainLobbyPose()
    LobbyCam.SetTarget(pos, look, fov, { idle = 1.0, snap = snap, lookFn = LobbyPlacement.MainLobbyLook })
end

function LobbyPlacement.StartCam()
    if Status.GetIsPlayerInEndScreen() or Gamemode.Playing then return end
    LobbyPlacement.SetupObject()
    if not (LobbyCam.handle and DoesCamExist(LobbyCam.handle)) then
        LobbyPlacement.GoToMainLobby(true)
    else
        LobbyCam.Ensure()
    end
end

function LobbyPlacement.SwitchToSecondCam()
    LobbyCam.Ensure()

    local cam = LobbyLayout.Cam("streaks")
    if cam then
        LobbyCam.SetTarget(LobbyLayout.CamVectors(cam))
        return
    end

    LobbyPlacement.SetupObject()
    if not (LobbyPlacement.objEntity and DoesEntityExist(LobbyPlacement.objEntity)) then
        LobbyPlacement.GoToMainLobby()
        return
    end

    local entityPos = GetEntityCoords(LobbyPlacement.objEntity, true)
    LobbyCam.SetTarget(LobbyPlacement.customCamPos,
        vector3(entityPos.x, entityPos.y, entityPos.z + 1.0), 30.0, { idle = 0.7 })
end

function LobbyPlacement.SwitchToPlayerSkinCam()
    LobbyCam.Ensure()

    local cam = LobbyLayout.Cam("skin")
    if cam then
        LobbyCam.SetTarget(LobbyLayout.CamVectors(cam))
        return
    end

    local pedToUse = Player.GetClone() or Player.GetPed()
    local pPos = GetOffsetFromEntityInWorldCoords(pedToUse, 0.0, 4.0, 0.2)
    local playerPos = GetEntityCoords(pedToUse, true)
    LobbyCam.SetTarget(pPos, vector3(playerPos.x, playerPos.y, playerPos.z + 0.2), 30.0, { idle = 0.6 })
end

function LobbyPlacement.SwitchToFirstCam()
    LobbyPlacement.GoToMainLobby()
end

function LobbyPlacement.SwitchToFirstCamAfterSkinCam()
    LobbyPlacement.GoToMainLobby()
end

function LobbyPlacement.GetWeaponPositionData()
    local entityPos = LobbyPlacement.StandPos()
    local entity
    local coordsToLookAt
    if LobbyWeapons.obj ~= 0 and DoesEntityExist(LobbyWeapons.obj) then
        entity = LobbyWeapons.obj
        coordsToLookAt = GetOffsetFromEntityInWorldCoords(entity, 0.2, -1.5, 0.0)
    else
        coordsToLookAt = entityPos
    end
    return entityPos, entity, coordsToLookAt
end

function LobbyPlacement.WeaponFraming(entity)
    local minD, maxD = GetModelDimensions(GetEntityModel(entity))
    local sizeX, sizeY, sizeZ = maxD.x - minD.x, maxD.y - minD.y, maxD.z - minD.z

    local barrelLen, thinSpan, viewLocal
    if sizeX >= sizeY then
        barrelLen, thinSpan, viewLocal = sizeX, sizeY, vector3(0.0, 1.0, 0.0)
    else
        barrelLen, thinSpan, viewLocal = sizeY, sizeX, vector3(1.0, 0.0, 0.0)
    end
    local heightLen = sizeZ

    local center = GetOffsetFromEntityInWorldCoords(entity,
        (minD.x + maxD.x) * 0.5, (minD.y + maxD.y) * 0.5, (minD.z + maxD.z) * 0.5)
    local entPos = GetEntityCoords(entity, true)
    local viewDir = GetOffsetFromEntityInWorldCoords(entity, viewLocal.x, viewLocal.y, viewLocal.z) - entPos
    local vlen = #(viewDir)
    viewDir = vlen > 0.0001 and (viewDir / vlen) or vector3(0.0, -1.0, 0.0)

    local fovV = 18.0
    local aspect = GetAspectRatio(false)
    if not aspect or aspect <= 0.1 then aspect = 16.0 / 9.0 end
    local vHalf = math.rad(fovV * 0.5)
    local hHalf = math.atan(math.tan(vHalf) * aspect)
    local fillH, fillV = 0.82, 0.72
    local refLen = 0.9
    local effLen = math.max(barrelLen, refLen)
    local dW = ((effLen * 0.5) / fillH) / math.tan(hHalf)
    local dH = ((heightLen * 0.5) / fillV) / math.tan(vHalf)
    local distance = math.max(0.5, math.min(math.max(dW, dH), 8.0))

    return center + viewDir * distance, center, fovV, distance, thinSpan
end

function LobbyPlacement.FrameWeaponCam(entity)
    if not (entity and DoesEntityExist(entity)) then return end
    Gunsmith.Prepare(entity)

    local eye, center, fov, distance, thinSpan = LobbyPlacement.WeaponFraming(entity)
    LobbyCam.SetTarget(eye, center, fov, { idle = 0.0, snap = true })

    LobbyPlacement.weaponFocusDist = distance
    LobbyPlacement.weaponFocusDepth = thinSpan
end

function LobbyPlacement.SwitchToWeaponCamAfterSecond()
    LobbyPlacement.SetupObject()
    LobbyCam.Ensure()

    local stand, entity = LobbyPlacement.GetWeaponPositionData()
    if entity and DoesEntityExist(entity) then
        LobbyPlacement.FrameWeaponCam(entity)
    else
        local wPos = LobbyWeapons.Display()
        LobbyCam.SetTarget(stand + vector3(0.0, 1.2, 0.15), vector3(wPos.x, wPos.y, wPos.z), 18.0, { idle = 0.0, snap = true })
    end

    Citizen.CreateThread(function()
        while not LobbyWeapons.RefreshDone do
            Wait(0)
        end
        local _, e2 = LobbyPlacement.GetWeaponPositionData()
        LobbyPlacement.FrameWeaponCam(e2)
        Gunsmith.Begin()
    end)
end

function LobbyPlacement.SwitchToSecondCamAfterWeapon()
    LobbyPlacement.GoToMainLobby()
end

function LobbyPlacement.StopCam()
    LobbyCam.Stop()
end