Matchmaking = {}
Matchmaking.players = {}
Matchmaking.playerEntries = {}
Matchmaking.nextEntryId = 0
Matchmaking.health = {
    lastCycleAt = 0,
    lastSuccessAt = 0,
    consecutiveFailures = 0,
    lastError = nil,
}

local function trace(err)
    return debug.traceback(tostring(err), 2)
end

local function findEntryIndexById(entryId)
    for index, entry in ipairs(Matchmaking.players) do
        if entry.id == entryId then
            return index
        end
    end
end

local function copyGroup(group)
    local result = {}
    local seen = {}

    for _, playerSource in ipairs(group) do
        if type(playerSource) == "number" and not seen[playerSource] then
            seen[playerSource] = true
            table.insert(result, playerSource)
        end
    end

    return result
end

local function removeEntryAt(index, notifyPlayers)
    local entry = Matchmaking.players[index]
    if entry == nil then
        return nil
    end

    table.remove(Matchmaking.players, index)

    for _, playerSource in ipairs(entry.group) do
        if Matchmaking.playerEntries[playerSource] == entry.id then
            Matchmaking.playerEntries[playerSource] = nil
        end

        if notifyPlayers and GetPlayerPing(playerSource) > 0 then
            TriggerClientEvent("groups:SendBackToWait", playerSource)
        end
    end

    return entry
end

local function removeEntryById(entryId, notifyPlayers)
    local index = findEntryIndexById(entryId)
    if index ~= nil then
        return removeEntryAt(index, notifyPlayers)
    end
end

local function rejectRequest(playerSource, message)
    Groups.Notify(playerSource, message, "MATCHMAKING")
    TriggerClientEvent("groups:SendBackToWait", playerSource)
end

function Matchmaking.IsPlayerInMatchmaking(playerSource)
    return Matchmaking.playerEntries[playerSource] ~= nil
end

function Matchmaking.LeaveMatchmaking(playerSource, notifyParty)
    local entryId = Matchmaking.playerEntries[playerSource]
    if entryId == nil then
        return false
    end

    local entry = removeEntryById(entryId, notifyParty == true)
    if entry == nil then
        Matchmaking.playerEntries[playerSource] = nil
        return false
    end

    InfoPrint("Removed matchmaking party [" .. entry.id .. "]")
    return true, entry.group
end

function Matchmaking.JoinMatchmaking(group, gamemode, rankedStatus, aimMode, maxPlayers)
    local matchmakingGroup = copyGroup(group)

    for _, playerSource in ipairs(matchmakingGroup) do
        Matchmaking.LeaveMatchmaking(playerSource, false)
    end

    Matchmaking.nextEntryId = Matchmaking.nextEntryId + 1
    local entry = {
        id = Matchmaking.nextEntryId,
        gamemode = gamemode,
        ranked = rankedStatus,
        aimMode = aimMode,
        maxPlayers = maxPlayers,
        group = matchmakingGroup,
        createdAt = os.time(),
    }

    table.insert(Matchmaking.players, entry)

    for _, playerSource in ipairs(matchmakingGroup) do
        Matchmaking.playerEntries[playerSource] = entry.id
        InfoPrint("Added player [" .. playerSource .. "] to matchmaking party [" .. entry.id .. "]")
    end

    return entry
end

function Matchmaking.GetAllGameIdForGamemode(gamemode, rankedStatus, aimMode, private)
    local ids = {}

    for _, game in pairs(Game.games) do
        if game.gamemode == gamemode
            and game.ranked == rankedStatus
            and game.aimMode == aimMode
            and game.inMatchmaking == private then
            table.insert(ids, game.gameId)
        end
    end

    return ids
end

function Matchmaking.JoinRandomGameByGamemode(entry)
    local group = entry.group
    local gamemode = entry.gamemode
    local rankedStatus = entry.ranked
    local aimMode = entry.aimMode
    local gameIds = ShuffleTable(Matchmaking.GetAllGameIdForGamemode(gamemode, rankedStatus, aimMode, false))

    for _, gameId in ipairs(gameIds) do
        local canJoin, alreadyStarted = Game.CanPlayerJoinGame(gameId, group)

        if Matchmaking.playerEntries[group[1]] ~= entry.id then
            return false, true
        end

        if canJoin then
            local joined = Game.AddPlayerToGame(gameId, group, alreadyStarted)
            if joined then
                return true
            end
        end
    end

    return false
end

function Matchmaking.BroadcastQueueData()
    local totalPlayers = 0

    for _, entry in ipairs(Matchmaking.players) do
        totalPlayers = totalPlayers + #entry.group
    end

    local place = 1
    for _, entry in ipairs(Matchmaking.players) do
        for _, playerSource in ipairs(entry.group) do
            TriggerClientEvent("warv:MatchmakingGetData", playerSource, place, totalPlayers)
            place = place + 1
        end
    end
end

function Matchmaking.RemoveDisconnectedParties()
    for index = #Matchmaking.players, 1, -1 do
        local entry = Matchmaking.players[index]
        local disconnected = false

        for _, playerSource in ipairs(entry.group) do
            if not Players.DoesPlayerExist(playerSource) or GetPlayerPing(playerSource) == 0 then
                disconnected = true
                break
            end
        end

        if disconnected then
            removeEntryAt(index, true)
        end
    end
end

function Matchmaking.ProcessEntry(entry)
    if Matchmaking.playerEntries[entry.group[1]] ~= entry.id then
        return
    end

    local joinedExistingGame, cancelled = Matchmaking.JoinRandomGameByGamemode(entry)
    if cancelled then
        return
    end

    if joinedExistingGame then
        removeEntryById(entry.id, false)
        return
    end

    if Matchmaking.playerEntries[entry.group[1]] ~= entry.id then
        return
    end

    local gameId, createError = Game.Create(false, entry.maxPlayers, entry.gamemode, entry.ranked, entry.aimMode)
    if gameId == nil then
        error(createError or "lobby create failed")
    end

    local joined, joinError = Game.AddPlayerToGame(gameId, entry.group, false)
    if joined then
        removeEntryById(entry.id, false)
    else
        Game.DeleteGame(gameId)
        error(joinError or "party join failed")
    end
end

function Matchmaking.RunCycle()
    Matchmaking.RemoveDisconnectedParties()
    Matchmaking.BroadcastQueueData()

    local entryIds = {}
    for _, entry in ipairs(Matchmaking.players) do
        table.insert(entryIds, entry.id)
    end

    local errors = {}
    for _, entryId in ipairs(entryIds) do
        local index = findEntryIndexById(entryId)
        local entry = index ~= nil and Matchmaking.players[index] or nil

        if entry ~= nil then
            local ok, err = xpcall(Matchmaking.ProcessEntry, trace, entry)
            if not ok then
                table.insert(errors, "party " .. entry.id .. ": " .. err)
                CriticalPrint("Matchmaking party [" .. entry.id .. "]: " .. err)
            end
        end
    end

    if #errors > 0 then
        return false, table.concat(errors, "\n")
    end

    return true
end

Citizen.CreateThread(function()
    while true do
        local success, cycleResult, cycleError = xpcall(Matchmaking.RunCycle, trace)

        Matchmaking.health.lastCycleAt = os.time()

        if success and cycleResult then
            Matchmaking.health.lastSuccessAt = Matchmaking.health.lastCycleAt
            Matchmaking.health.consecutiveFailures = 0
            Matchmaking.health.lastError = nil
        else
            Matchmaking.health.consecutiveFailures = Matchmaking.health.consecutiveFailures + 1
            Matchmaking.health.lastError = success and cycleError or cycleResult
            CriticalPrint("Matchmaking cycle: " .. tostring(Matchmaking.health.lastError))
        end

        Wait(3000)
    end
end)

local function getRequestGroup(playerSource, playlist)
    local group = {playerSource}

    if Groups.IsPlayerInAnyGroup(playerSource) then
        if not Groups.IsPlayerHostOfAnyGroup(playerSource) then
            return nil, "Only the squad leader can start matchmaking."
        end

        local groupId = Groups.GetPlayerGroup(playerSource)
        if groupId == nil then
            return nil, "Group not found."
        end

        group = copyGroup(Groups.GetPlayersInGroup(groupId))
    end

    if #group == 0 or #group > playlist.maxPlayers then
        return nil, "Invalid group size for this playlist."
    end

    for _, memberSource in ipairs(group) do
        if not Players.DoesPlayerExist(memberSource) or GetPlayerPing(memberSource) == 0 then
            return nil, "A player in the group is disconnected."
        end

        if Players.GetPlayerCurrentLobby(memberSource) ~= 0 then
            return nil, "A player in the group is already in a lobby."
        end
    end

    return group
end

RegisterNetEvent("warv:JoinMatchmaking")
AddEventHandler("warv:JoinMatchmaking", function(gamemode, rankedStatus, aimMode)
    local playerSource = source
    local banned, banType = Players.IsBanned(playerSource)

    if banned then
        DropPlayer(playerSource, Ban.type[banType].desc)
        return
    end

    if not Players.DoesPlayerExist(playerSource) then
        rejectRequest(playerSource, "Player data is not loaded.")
        return
    end

    local valid, validationError, playlist = MatchmakingConfig.ValidateRequest(gamemode, rankedStatus, aimMode)
    if not valid then
        rejectRequest(playerSource, validationError)
        return
    end

    local group, groupError = getRequestGroup(playerSource, playlist)
    if group == nil then
        rejectRequest(playerSource, groupError)
        return
    end

    Matchmaking.JoinMatchmaking(group, playlist.name, playlist.ranked, aimMode, playlist.maxPlayers)
    Matchmaking.BroadcastQueueData()

    for _, memberSource in ipairs(group) do
        if memberSource ~= playerSource then
            TriggerClientEvent("groups:JoinMatchmaking", memberSource, playlist.name)
        end
    end
end)

RegisterNetEvent("warv:LeaveMatchmaking")
AddEventHandler("warv:LeaveMatchmaking", function()
    local playerSource = source
    local banned, banType = Players.IsBanned(playerSource)

    if banned then
        DropPlayer(playerSource, Ban.type[banType].desc)
        return
    end

    if Groups.GetLeaderActionPlayers(playerSource, "leave matchmaking") == nil then
        return
    end

    Matchmaking.LeaveMatchmaking(playerSource, true)
    Matchmaking.BroadcastQueueData()
end)

RegisterNetEvent("warv:CanPlayerJoinMatchWithId")
AddEventHandler("warv:CanPlayerJoinMatchWithId", function(gameId)
    local playerSource = source
    local banned, banType = Players.IsBanned(playerSource)

    if banned then
        DropPlayer(playerSource, Ban.type[banType].desc)
        return
    end

    if Groups.IsPlayerInAnyGroup(playerSource) then
        TriggerClientEvent("browser:ShowErrorMessage", playerSource, "Can't join this server.\nLeave your group first, the browser is solo only.")
        return
    end

    if type(gameId) ~= "string"
        or not Players.DoesPlayerExist(playerSource)
        or Players.GetPlayerCurrentLobby(playerSource) ~= 0 then
        TriggerClientEvent("browser:ShowErrorMessage", playerSource, "Can't join this server.")
        return
    end

    local canJoin, alreadyStarted = Game.CanPlayerJoinGame(gameId, {playerSource})
    if not canJoin then
        TriggerClientEvent("browser:ShowErrorMessage", playerSource, "Can't join this server.\nIt's full or unreachable.")
        return
    end

    local joined = Game.AddPlayerToGame(gameId, {playerSource}, alreadyStarted)
    if not joined then
        TriggerClientEvent("browser:ShowErrorMessage", playerSource, "Can't join this server.\nIt's full or unreachable.")
        return
    end

    local game = Game.GetGameFromGameId(gameId)
    if game ~= nil then
        TriggerClientEvent("browser:CloseBrowserAfterJoining", playerSource, game.gamemode)
    end
end)

RegisterCommand("matchmaking-health", function(playerSource)
    if playerSource ~= 0 then
        return
    end

    print(json.encode({
        queuedParties = #Matchmaking.players,
        activeLobbies = #Game.games,
        matchmaking = Matchmaking.health,
        lobbyMaintenance = Game.health,
    }))
end, true)

local lobbyWeapons = {}

RegisterNetEvent("warv:SetLobbyWeapon")
AddEventHandler("warv:SetLobbyWeapon", function(data)
    local src = source
    if type(data) ~= "table" or type(data.weapon) ~= "string" or #data.weapon == 0 or #data.weapon > 64 then return end
    local clean = { weapon = data.weapon, comps = {} }
    local n = 0
    for k, v in pairs(type(data.comps) == "table" and data.comps or {}) do
        n = n + 1
        if n > 16 then break end
        if k == "tint" and tonumber(v) then
            clean.comps.tint = tonumber(v)
        elseif type(k) == "string" and type(v) == "string" and #v <= 64 then
            clean.comps[k] = v
        end
    end
    lobbyWeapons[src] = clean
    TriggerClientEvent("warv:LobbyWeapons", -1, lobbyWeapons)
end)

AddEventHandler("playerDropped", function()
    local src = source
    if lobbyWeapons[src] ~= nil then
        lobbyWeapons[src] = nil
        TriggerClientEvent("warv:LobbyWeapons", -1, lobbyWeapons)
    end
end)
