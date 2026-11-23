SpawnLogic = {}
SpawnLogic.Queue = {}
SpawnLogic.Reservations = {}
SpawnLogic.Spawned = {}

local dangerRadius = 15.0
local enemyCap = 80.0
local mateRadius = 30.0
local mateWeight = 0.5

local function getDistance(first, second)
    return Utils.GetDistanceBetweenCoords(
        vector3(first.x, first.y, first.z),
        vector3(second.x, second.y, second.z)
    )
end

local function cleanReservations(gameId)
    local reservations = SpawnLogic.Reservations[gameId]
    if reservations == nil then
        return
    end

    local now = GetGameTimer()
    for key, reservation in pairs(reservations) do
        if reservation.expiresAt <= now then
            reservations[key] = nil
        end
    end
end

local function getReservedPositions(gameId, ignoredKey)
    cleanReservations(gameId)
    local positions = {}

    for key, reservation in pairs(SpawnLogic.Reservations[gameId] or {}) do
        if key ~= ignoredKey then
            table.insert(positions, reservation.pos)
        end
    end

    return positions
end

local function reserveSpawn(gameId, reservationKey, spawn)
    SpawnLogic.Reservations[gameId] = SpawnLogic.Reservations[gameId] or {}
    SpawnLogic.Reservations[gameId][reservationKey] = {
        pos = spawn.pos,
        expiresAt = GetGameTimer() + BotConfig.spawnReservationDuration,
    }
end

function SpawnLogic.AddPlayerIntoQueueForLobby(gameId, source, playerTeam, players, currentMap, bots, teams)
    SpawnLogic.Queue[gameId] = SpawnLogic.Queue[gameId] or {}

    table.insert(SpawnLogic.Queue[gameId], {
        gameId = gameId,
        source = source,
        playerTeam = playerTeam,
        players = players,
        currentMap = currentMap,
        bots = bots,
        noTeams = teams == false,
    })
end

function SpawnLogic.RemoveLobbyFromQueue(gameId)
    SpawnLogic.Queue[gameId] = nil
    SpawnLogic.Reservations[gameId] = nil
    SpawnLogic.Spawned[gameId] = nil
end

Citizen.CreateThread(function()
    while true do
        local handledSpawn = false

        for gameId, players in pairs(SpawnLogic.Queue) do
            local player = players[1]
            if player ~= nil then
                handledSpawn = true
                local reservationKey = "player:" .. tostring(player.source)
                local spawn = SpawnLogic.GetSpawnForTeam(
                    player.playerTeam,
                    player.players,
                    player.currentMap,
                    player.bots,
                    gameId,
                    reservationKey,
                    not player.noTeams
                )
                TriggerClientEvent("SpawnFinder:GetSpawnPos", player.source, spawn)
                table.remove(players, 1)
            end
        end

        Wait(handledSpawn and 1 or 150)
    end
end)

function SpawnLogic.GetSpawnsForMap(currentMap)
    local map = SharedConfig.Maps[currentMap]
    if map == nil then
        return {}
    end
    return map.spawns or {}
end

function SpawnLogic.GetLivePositions(playerTeam, players, bots, teams)
    local enemies, allies = {}, {}

    local function add(team, pos)
        if teams == false or team ~= playerTeam then
            table.insert(enemies, pos)
        else
            table.insert(allies, pos)
        end
    end

    for _, player in pairs(players) do
        local playerPed = GetPlayerPed(player.id)
        if playerPed ~= 0 and DoesEntityExist(playerPed) and GetEntityHealth(playerPed) > 0 then
            add(player.team, GetEntityCoords(playerPed))
        end
    end

    for team = 1, 2 do
        for _, bot in pairs(bots[team]) do
            if bot.netId ~= 0 then
                local botPed = NetworkGetEntityFromNetworkId(bot.netId)
                if botPed ~= 0 and DoesEntityExist(botPed) and GetEntityHealth(botPed) > 0 then
                    add(bot.team, GetEntityCoords(botPed))
                end
            end
        end
    end

    return enemies, allies
end

function SpawnLogic.IsSpawnPointClear(pos, occupiedPositions, minimumDistance)
    for _, occupiedPos in pairs(occupiedPositions) do
        if getDistance(pos, occupiedPos) <= minimumDistance then
            return false
        end
    end

    return true
end

local function nearestDist(pos, positions)
    local d = math.huge
    for _, p in pairs(positions) do
        d = math.min(d, getDistance(pos, p))
    end
    return d
end

function SpawnLogic.GetSpawnForTeam(playerTeam, players, currentMap, bots, gameId, reservationKey, teams)
    local spawns = SpawnLogic.GetSpawnsForMap(currentMap)
    if #spawns == 0 then
        return nil
    end

    local map = SharedConfig.Maps[currentMap]
    local enemies, allies = SpawnLogic.GetLivePositions(playerTeam, players, bots, teams)
    local reservedPositions = getReservedPositions(gameId, reservationKey)

    local spawned = SpawnLogic.Spawned[gameId] or {}
    local anchor
    if teams ~= false and not spawned[reservationKey] then
        anchor = (playerTeam == 2 and map.startFirstPos2) or map.startFirstPos1
    end

    local function scoreOf(pos)
        if anchor then
            return -getDistance(pos, anchor)
        end
        local enemyD = nearestDist(pos, enemies)
        if enemyD < dangerRadius then
            return -10000.0 + enemyD
        end
        local score = math.min(enemyD, enemyCap)
        local mateD = nearestDist(pos, allies)
        if mateD < mateRadius then
            score = score + (mateRadius - mateD) * mateWeight
        end
        return score
    end

    local bestClear, bestClearScore = nil, -math.huge
    local bestAny, bestAnyScore = nil, -math.huge
    for _, spawn in pairs(spawns) do
        local score = scoreOf(spawn.pos)
        if score > bestAnyScore then
            bestAnyScore = score
            bestAny = spawn
        end
        if SpawnLogic.IsSpawnPointClear(spawn.pos, reservedPositions, BotConfig.spawnReservationDistance) then
            if score > bestClearScore then
                bestClearScore = score
                bestClear = spawn
            end
        end
    end

    local bestSpawn = bestClear or bestAny or spawns[1]
    SpawnLogic.Spawned[gameId] = spawned
    spawned[reservationKey] = true
    reserveSpawn(gameId, reservationKey, bestSpawn)
    return bestSpawn
end
