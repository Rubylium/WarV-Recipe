PlayersDisplay = {}
PlayersDisplay.LobbyPosition = vector4(352.75708007813, 4832.8671875, -58.999450683594, 64.113815307617)
PlayersDisplay.LobbyDefaultFov = 10.0
PlayersDisplay.LobbyCachedFov = 10.0
PlayersDisplay.DoingFovChange = false
PlayersDisplay.Poses = {}
PlayersDisplay.Entitys = {}
PlayersDisplay.Anims = {
    {"WORLD_HUMAN_GUARD_PATROL"},
    {"WORLD_HUMAN_GUARD_STAND"},
    {"WORLD_HUMAN_GUARD_STAND_CASINO"},
    {"WORLD_HUMAN_GUARD_STAND_CLUBHOUSE"},
    {"WORLD_HUMAN_GUARD_STAND_ARMY"},
    {"WORLD_HUMAN_STAND_IMPATIENT"},
    {"WORLD_HUMAN_HANG_OUT_STREET"},
}

PlayersDisplay.WeaponData = {}
PlayersDisplay.editedRef = nil
local myWeaponKey = nil

function PlayersDisplay.MyDisplayWeapon()
    local ref = PlayersDisplay.editedRef
    local cls = ref and Class.customClass[ref.classIdx]
    local w = cls and cls.weapons and cls.weapons[ref.slot]
    if not (w and w.weapon and w.weapon ~= "") then
        cls = Class.customClass[1]
        w = cls and cls.weapons and cls.weapons.primary
    end
    if not (w and w.weapon and w.weapon ~= "") then return nil end
    return { weapon = w.weapon, comps = w.comps or {} }
end

function PlayersDisplay.SyncMyWeapon()
    local data = PlayersDisplay.MyDisplayWeapon()
    if data == nil then return end
    local key = json.encode(data)
    if key == myWeaponKey then return end
    myWeaponKey = key
    TriggerServerEvent("warv:SetLobbyWeapon", data)
end

local function poseOf(serverId)
    for _, pos in pairs(PlayersDisplay.Poses) do
        if pos.taken and pos.id == serverId then return pos end
    end
end

function PlayersDisplay.ApplyWeaponToClone(serverId)
    local entity = PlayersDisplay.Entitys[serverId]
    local data = PlayersDisplay.WeaponData[serverId]
    if not (entity and DoesEntityExist(entity) and data and data.weapon) then return end
    Citizen.CreateThread(function()
        local hash = GetHashKey(data.weapon)
        RequestWeaponAsset(hash, 31, 0)
        local deadline = GetGameTimer() + 3000
        while not HasWeaponAssetLoaded(hash) and GetGameTimer() < deadline do Wait(0) end
        if not DoesEntityExist(entity) then return end
        RemoveAllPedWeapons(entity, true)
        GiveWeaponToPed(entity, hash, 10, false, true)
        WeaponComponentVisuals.ApplyToPed(entity, hash, data.comps or {})
        SetCurrentPedWeapon(entity, hash, true)
        local pose = poseOf(serverId)
        if pose then LobbyLayout.PlayPose(entity, pose, true) end
    end)
end

RegisterNetEvent("warv:LobbyWeapons")
AddEventHandler("warv:LobbyWeapons", function(map)
    PlayersDisplay.WeaponData = type(map) == "table" and map or {}
    for id in pairs(PlayersDisplay.Entitys) do
        PlayersDisplay.ApplyWeaponToClone(id)
    end
end)

function PlayersDisplay.HideOthersClones()
    for _, pos in pairs(PlayersDisplay.Poses) do
        if pos.taken then SetEntityAlpha(pos.entity, 0, false) end
    end
end

function PlayersDisplay.ShowOthersClones()
    for _, pos in pairs(PlayersDisplay.Poses) do
        if pos.taken then SetEntityAlpha(pos.entity, 255, false) end
    end
end

function PlayersDisplay.RemoveAllClones()
    for index, pos in pairs(PlayersDisplay.Poses) do
        if pos.taken then
            if DoesEntityExist(pos.entity) then
                DeleteEntity(pos.entity)
            end
            pos.taken = false
            pos.entity = nil
        end
    end
    PlayersDisplay.Entitys = {}
    Player.SetClone(nil)
end

function PlayersDisplay.CleanupRemainingClones()
    local toRemove = {}
    for playerId, entity in pairs(PlayersDisplay.Entitys) do
        local found = false
        for k,v in pairs(Matchmaking.data.players) do
            if v.id == playerId then
                found = true
                break
            end
        end
        if not found then
            table.insert(toRemove, playerId)
        end
    end

    for k,v in pairs(toRemove) do
        DeleteEntity(PlayersDisplay.Entitys[v])
    end

    for index, pos in pairs(PlayersDisplay.Poses) do
        if pos.taken then
            if not DoesEntityExist(pos.entity) then
                pos.taken = false
                pos.entity = nil
            end
        end
    end
end

function PlayersDisplay.UpdateClonesPositions()
    local gap = false
    for index = 2, #PlayersDisplay.Poses do
        local pos = PlayersDisplay.Poses[index]
        if not pos.taken then
            gap = true
        elseif gap then
            DeleteEntity(pos.entity)
            PlayersDisplay.Entitys[pos.id] = nil
            pos.taken = false
            pos.entity = nil
        end
    end
end

function PlayersDisplay.CreateClone(playerId, index)
    local pose = PlayersDisplay.Poses[index]
    PlayersDisplay.Entitys[playerId] = ClonePed(GetPlayerPed(GetPlayerFromServerId(playerId)), false, true, false)
    Player.Revive(PlayersDisplay.Entitys[playerId])
    SetBlockingOfNonTemporaryEvents(PlayersDisplay.Entitys[playerId], true)
    PropMap.Place(PlayersDisplay.Entitys[playerId], pose.pos.x, pose.pos.y, pose.pos.z)
    SetEntityHeading(PlayersDisplay.Entitys[playerId], pose.heading)
    PlayersDisplay.PlayWaitingAnimationOnClone(PlayersDisplay.Entitys[playerId], index)
    PlayersDisplay.ApplyWeaponToClone(playerId)
    return PlayersDisplay.Entitys[playerId]
end

local function claim(index, playerId)
    local pose = PlayersDisplay.Poses[index]
    if not pose or pose.taken then return false end

    pose.taken = true
    pose.entity = PlayersDisplay.CreateClone(playerId, index)
    pose.id = playerId
    return true
end

function PlayersDisplay.SetupPlayersClones()
    PlayersDisplay.CleanupRemainingClones()
    PlayersDisplay.UpdateClonesPositions()

    local me = Player.GetServerId()
    for _, player in pairs(Matchmaking.data.players) do
        if player.id ~= 0 and player.id ~= me and PlayersDisplay.Entitys[player.id] == nil then
            for index = 2, #PlayersDisplay.Poses do
                if claim(index, player.id) then break end
            end
        end
    end

    PlayersDisplay.UpdateCameraFovBasedOnCloneCount()
    if Lobby.displayPlayerSkinEdit then
        PlayersDisplay.HideOthersClones()
    end
    PlayersDisplay.SyncMyWeapon()
end

function PlayersDisplay.PlayWaitingAnimationOnClone(clone, index)
    LobbyLayout.PlayPose(clone, PlayersDisplay.Poses[index], true)
end

function PlayersDisplay.UpdateCameraFovBasedOnCloneCount()
    if LobbyLayout.Cam("main") then return end
    while PlayersDisplay.DoingFovChange do
        Wait(0)
    end
    PlayersDisplay.DoingFovChange = true
    Citizen.CreateThread(function()
        local playersToSend = { Player.GetPed() }
        for _, entity in pairs(PlayersDisplay.Entitys) do
            if DoesEntityExist(entity) then
                table.insert(playersToSend, entity)
            end
        end
        local camFov = LobbyPlacement.GetCorrectFovForPlayersNumber(playersToSend)

        if Lobby.displayMatchmaking then
            LobbyCam.SetFov(camFov)
        end

        PlayersDisplay.LobbyCachedFov = camFov
        PlayersDisplay.DoingFovChange = false
    end)

end

local function pose(pos, heading, source)
    source = source or {}
    return {
        pos = pos,
        heading = heading,
        scenario = source.scenario or SharedConfig.MatchmakingScenarioList[math.random(1, #SharedConfig.MatchmakingScenarioList)][1],
        dict = source.dict or "",
        anim = source.anim or "",
        taken = false,
    }
end

function PlayersDisplay.InitPoses()
    PlayersDisplay.Poses = {}

    local me = LobbyLayout.Me()
    if me then
        PlayersDisplay.Poses[1] = pose(vector3(me.x, me.y, me.z), me.h, me)
        for _, slot in ipairs(LobbyLayout.Slots()) do
            PlayersDisplay.Poses[#PlayersDisplay.Poses + 1] = pose(vector3(slot.x, slot.y, slot.z), slot.h, slot)
        end
        return
    end

    PlayersDisplay.LegacyPoses()
end

function PlayersDisplay.LegacyPoses()
    local paddingStartingLeftRight = 0.0
    local paddingStartingFrontBack = 9.0
    local paddingLeftRight = 0.8
    local paddingFrontBack = 0.3
    local ped = ClonePed(Player.GetPed(), false, true, false)


    PlaceObjectOnGroundProperly(ped)
    SetVehicleOnGroundProperly(ped)
    SetEntityVisible(ped, false, 1)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, PlayersDisplay.LobbyPosition.xyz, false, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityHeading(ped, PlayersDisplay.LobbyPosition.w)



    table.insert(PlayersDisplay.Poses, pose(
        GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight, paddingStartingFrontBack, 0.0),
        PlayersDisplay.LobbyPosition.w - 180))
    for i = 1,2 do
        table.insert(PlayersDisplay.Poses, pose(
            GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight + (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), 0.0),
            PlayersDisplay.LobbyPosition.w - 180))


        table.insert(PlayersDisplay.Poses, pose(
            GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight - (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), 0.0),
            PlayersDisplay.LobbyPosition.w - 180))
    end

    local paddingStartingLeftRight = 0.0
    local paddingStartingFrontBack = 10.0
    local paddingLeftRight = 1.2
    local paddingFrontBack = 0.3

    table.insert(PlayersDisplay.Poses, pose(
        GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight - 0.3, paddingStartingFrontBack, 0.0),
        PlayersDisplay.LobbyPosition.w - 180))
    for i = 1,2 do
        table.insert(PlayersDisplay.Poses, pose(
            GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight + (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), 0.0),
            PlayersDisplay.LobbyPosition.w - 180))


        table.insert(PlayersDisplay.Poses, pose(
            GetOffsetFromEntityInWorldCoords(ped, paddingStartingLeftRight - (paddingLeftRight * i), paddingStartingFrontBack + (paddingFrontBack * i), 0.0),
            PlayersDisplay.LobbyPosition.w - 180))
    end
    DeleteEntity(ped)
end
