SpawnFinder = {}
SpawnFinder.WaitingForSpawn = false
SpawnFinder.SpawnPos = {}

function SpawnFinder.SpawnPlayer(pos)
    local player = Player.GetPed()
    if pos == nil then
        pos = Player.GetPos()
    else
        pos = pos.pos
    end
    local posToUse = {pos.x, pos.y, pos.z}
    local get, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, 0)
    if get then
        posToUse[3] = z
    end
    ClearAreaOfEverything(posToUse[1], posToUse[2], posToUse[3], 500.0, 0, 0, 0, 0)
    NetworkResurrectLocalPlayer(posToUse[1], posToUse[2], posToUse[3], GetEntityHeading(player), 0, 0)
    SetEntityCoords(player, posToUse[1], posToUse[2], posToUse[3], false, false, false, false)
    FreezeEntityPosition(player, true)
    ClearPedBloodDamage(player)
    DamageLog.Reset()
end

function SpawnFinder.NewGetSpawnPos(gameId)
    SpawnFinder.WaitingForSpawn = true
    SpawnFinder.SpawnPos = nil
    local requested = Utils.TriggerGamemodeServerEvent("GetSpawnPos")
    if not requested then
        SpawnFinder.WaitingForSpawn = false
        return nil, "inactive"
    end

    local timeoutAt = GetGameTimer() + 10000
    while SpawnFinder.WaitingForSpawn
        and Status.GetIsPlayerInGame()
        and GamemodeRuntime.IsActive()
        and GetGameTimer() < timeoutAt do
        Wait(1)
    end

    if SpawnFinder.WaitingForSpawn then
        SpawnFinder.WaitingForSpawn = false
        return nil, "timeout"
    end
    return SpawnFinder.SpawnPos
end

RegisterNetEvent("SpawnFinder:GetSpawnPos")
AddEventHandler("SpawnFinder:GetSpawnPos", function(spawn)
    SpawnFinder.WaitingForSpawn = false
    SpawnFinder.SpawnPos = spawn
end)
