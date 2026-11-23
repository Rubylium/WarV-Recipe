Bot = {
    GameId = 0,
    GameStarted = false,
    team = 0,
    list = {
        [1] = {},
        [2] = {},
    },
    isHost = false,
    entities = {},
    pendingSpawns = {},
    missingEntities = {},
    spawnInProgress = false,
    requestSequence = 0,
    possibleWeapon = {
        GetHashKey("weapon_carbinerifle"),
        GetHashKey("weapon_carbinerifle_mk2"),
        GetHashKey("weapon_advancedrifle"),
        GetHashKey("weapon_specialcarbine"),
        GetHashKey("weapon_specialcarbine_mk2"),
        GetHashKey("weapon_bullpuprifle"),
        GetHashKey("weapon_assaultsmg"),
        GetHashKey("weapon_smg"),
        GetHashKey("weapon_smg_mk2"),
        GetHashKey("weapon_machinepistol"),
        GetHashKey("weapon_combatpdw"),
        GetHashKey("weapon_pumpshotgun"),
        GetHashKey("weapon_pumpshotgun_mk2"),
        GetHashKey("weapon_bullpupshotgun"),
        GetHashKey("weapon_pistol"),
        GetHashKey("weapon_pistol_mk2"),
        GetHashKey("weapon_combatpistol"),
        GetHashKey("weapon_appistol"),
        GetHashKey("weapon_pistol50"),
        GetHashKey("weapon_snspistol_mk2"),
        GetHashKey("weapon_gusenberg"),
        GetHashKey("weapon_marksmanrifle"),
        GetHashKey("weapon_heavysniper"),
    },
}

local function removeBlip(state)
    if state.blip and DoesBlipExist(state.blip) then
        RemoveBlip(state.blip)
    end
end

function Bot.RequestControl(entity, timeout)
    if entity == nil or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    local expiresAt = GetGameTimer() + (timeout or 500)
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < expiresAt do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

function Bot.GetProfile(botId)
    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            if profile.id == botId then
                return profile
            end
        end
    end

    return nil
end

function Bot.GetEntityById(botId)
    local state = Bot.entities[botId]
    if state ~= nil and DoesEntityExist(state.entity) then
        return state.entity
    end

    local profile = Bot.GetProfile(botId)
    if profile ~= nil and profile.netId ~= 0 and NetworkDoesNetworkIdExist(profile.netId) then
        local entity = NetworkGetEntityFromNetworkId(profile.netId)
        if entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    return 0
end

function Bot.RefreshAppearances()
    if not Bot.isHost then
        return
    end

    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            local entity = Bot.GetEntityById(profile.id)
            if entity ~= 0 and Bot.RequestControl(entity, 100) then
                Appearance.ApplyOutfit(entity, profile.outfit)
            end
        end
    end
end

function Bot.IsEntityABot(entityToCheck)
    if entityToCheck == nil or entityToCheck == 0 then
        return false
    end

    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            if profile.netId ~= 0 and NetworkDoesNetworkIdExist(profile.netId) then
                if NetworkGetEntityFromNetworkId(profile.netId) == entityToCheck then
                    return true, profile.id, profile.team
                end
            end
        end
    end

    return false
end

function Bot.UpdateList(list)
    Bot.list = list or {}
    Bot.list[1] = Bot.list[1] or {}
    Bot.list[2] = Bot.list[2] or {}
end

function Bot.SetHost(isHost)
    isHost = isHost == true
    if Bot.isHost == isHost then
        return
    end

    Bot.isHost = isHost
    Bot.spawnInProgress = false
    Bot.pendingSpawns = {}
    Bot.missingEntities = {}

    if not isHost then
        for _, state in pairs(Bot.entities) do
            removeBlip(state)
        end
        Bot.entities = {}
    end
end

function Bot.DeleteManagedEntity(botId)
    local state = Bot.entities[botId]
    if state == nil then
        return
    end

    removeBlip(state)
    if DoesEntityExist(state.entity) and Bot.RequestControl(state.entity) then
        SetEntityAsMissionEntity(state.entity, true, true)
        DeleteEntity(state.entity)
    end
    Bot.entities[botId] = nil
end

function Bot.Pause()
    Bot.GameStarted = false
    if not Bot.isHost then
        return
    end

    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            local entity = Bot.GetEntityById(profile.id)
            if entity ~= 0 and DoesEntityExist(entity) and Bot.RequestControl(entity, 100) then
                SetPedKeepTask(entity, false)
                ClearPedTasksImmediately(entity)
                SetBlockingOfNonTemporaryEvents(entity, true)
                SetEntityInvincible(entity, true)
                FreezeEntityPosition(entity, true)
            end
        end
    end
end

function Bot.EndGame()
    local netIds = {}
    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            if profile.netId ~= nil and profile.netId ~= 0 then
                netIds[profile.netId] = true
            end
        end
    end

    for botId in pairs(Bot.entities) do
        Bot.DeleteManagedEntity(botId)
    end

    if Bot.isHost then
        for netId in pairs(netIds) do
            if NetworkDoesNetworkIdExist(netId) then
                local entity = NetworkGetEntityFromNetworkId(netId)
                if entity ~= 0 and DoesEntityExist(entity) and Bot.RequestControl(entity) then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                end
            end
        end
    end

    Bot.GameId = 0
    Bot.GameStarted = false
    Bot.team = 0
    Bot.list = {
        [1] = {},
        [2] = {},
    }
    Bot.isHost = false
    Bot.pendingSpawns = {}
    Bot.missingEntities = {}
    Bot.spawnInProgress = false
end

function Bot.GetEndScreenPlayers(team)
    local players = {}
    for _, profile in pairs(Bot.list[team]) do
        local copy = {}
        for key, value in pairs(profile) do
            copy[key] = value
        end
        copy.bot = true
        table.insert(players, copy)
    end
    return players
end

function Bot.GetTeamParticipants(players, team)
    local participants = {}
    for _, player in pairs(players or {}) do
        if player.team == team then
            table.insert(participants, player)
        end
    end
    for _, bot in pairs(Bot.GetEndScreenPlayers(team)) do
        table.insert(participants, bot)
    end
    return participants
end
