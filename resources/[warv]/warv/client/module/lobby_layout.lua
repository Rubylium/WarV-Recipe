LobbyLayout = {}
LobbyLayout.loaded = nil

function LobbyLayout.Get()
    local name = PropMapStore.LobbyName()
    local map = name and PropMapStore.Get(name)
    return map and map.lobby or nil
end

function LobbyLayout.Me()
    local lobby = LobbyLayout.Get()
    if lobby and lobby.me.set then return lobby.me end
    return nil
end

function LobbyLayout.Slots()
    local lobby = LobbyLayout.Get()
    if not lobby then return {} end

    local slots = {}
    for _, slot in ipairs(lobby.slots) do
        if slot.set then slots[#slots + 1] = slot end
    end
    return slots
end

function LobbyLayout.Cam(key)
    local lobby = LobbyLayout.Get()
    local cam = lobby and lobby.cams[key]
    if cam and cam.set then return cam end
    return nil
end

function LobbyLayout.Env()
    local lobby = LobbyLayout.Get()
    if lobby and lobby.env.set then return lobby.env end
    return nil
end

function LobbyLayout.Weapon()
    local lobby = LobbyLayout.Get()
    if lobby and lobby.weapon.set then return lobby.weapon end
    return nil
end

function LobbyLayout.CamVectors(cam)
    return vector3(cam.x, cam.y, cam.z), vector3(cam.tx, cam.ty, cam.tz), cam.fov, {
        idle = cam.idle,
        dof = cam.dof,
        dofStrength = cam.dofStrength,
        dofNear = cam.dofNear,
        dofFar = cam.dofFar,
    }
end

function LobbyLayout.PlayPose(ped, pose, freeze)
    ClearPedTasksImmediately(ped)
    if pose.scenario ~= "" then
        TaskStartScenarioInPlace(ped, pose.scenario, 0, true)
        if freeze then FreezeEntityPosition(ped, false) end
    elseif pose.dict ~= "" and pose.anim ~= "" then
        PropMap.PlayAnim(ped, pose.dict, pose.anim)
        if freeze then FreezeEntityPosition(ped, true) end
    elseif freeze then
        FreezeEntityPosition(ped, true)
    end
end

function LobbyLayout.SpawnPos()
    local me = LobbyLayout.Me()
    if me then return vector3(me.x, me.y, me.z) end
    return Lobby.defaultPosition
end

function LobbyLayout.PlaceSelf()
    local ped = Gamemode.utils.GetPed()
    local me = LobbyLayout.Me()
    if not me then
        SetEntityCoordsNoOffset(ped, Lobby.defaultPosition.xyz, false, false, false)
        return
    end

    PropMap.Place(ped, me.x, me.y, me.z)
    SetEntityHeading(ped, me.h)
    LobbyLayout.PlayPose(ped, me, false)
end

function LobbyLayout.Apply()
    local name = PropMapStore.LobbyName()
    if LobbyLayout.loaded and LobbyLayout.loaded ~= name then
        PropMap.Unload(LobbyLayout.loaded)
        LobbyLayout.loaded = nil
    end

    if not name then return end
    if PropMap.IsLoaded(name) and not PropMap.IsAlive(name) then PropMap.Unload(name) end
    PropMap.Load(name)
    LobbyLayout.loaded = name
end

function LobbyLayout.Refresh()
    LobbyLayout.Apply()
    PlayersDisplay.RemoveAllClones()
    PlayersDisplay.InitPoses()
    LobbyLayout.PlaceSelf()
end
