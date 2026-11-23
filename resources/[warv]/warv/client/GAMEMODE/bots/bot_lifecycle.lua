local function createBotBlip(entity, team)
    if Gamemode.NoTeams then return nil end
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, Bot.team == team and 3 or 47)
    SetBlipScale(blip, 0.40)
    return blip
end

local function registerManagedEntity(profile, entity, netId, awaitingSync, configured)
    Bot.entities[profile.id] = {
        entity = entity,
        netId = netId,
        blip = createBotBlip(entity, profile.team),
        lastCombatTaskAt = 0,
        deathObservedAt = nil,
        deathReported = false,
        frozen = false,
        awaitingSync = awaitingSync,
        createdAt = GetGameTimer(),
        configured = configured,
        lastControlRequestAt = 0,
    }
end

local function waitForSpawn(requestId)
    local expiresAt = GetGameTimer() + 5000
    while Bot.pendingSpawns[requestId] ~= nil and Bot.pendingSpawns[requestId].spawn == nil and GetGameTimer() < expiresAt do
        Wait(0)
    end

    local request = Bot.pendingSpawns[requestId]
    Bot.pendingSpawns[requestId] = nil
    return request and request.spawn or nil
end

function Bot.ResolveSpawnRequest(requestId, botId, spawn)
    local request = Bot.pendingSpawns[requestId]
    if request ~= nil and request.botId == botId then
        request.spawn = spawn or false
    end
end

function Bot.CreateNew(profile)
    Bot.requestSequence = Bot.requestSequence + 1
    local requestId = ("%s:%s:%s"):format(Bot.GameId, GetPlayerServerId(PlayerId()), Bot.requestSequence)
    Bot.pendingSpawns[requestId] = {
        botId = profile.id,
    }
    Utils.TriggerGamemodeServerEvent("RequestBotSpawn", requestId, profile.id, profile.team)

    local spawn = waitForSpawn(requestId)
    if not spawn or spawn.pos == nil or not Bot.isHost or Bot.GameId == 0 then
        return false
    end

    local outfit = Appearance.Find(profile.outfit)
    local model = Appearance.LoadModel(outfit and outfit.appearance.model or "mp_m_freemode_01")
    if model == nil then
        return false
    end

    local entity = CreatePed(4, model, spawn.pos.x, spawn.pos.y, spawn.pos.z + 0.25, spawn.pos.w or 0.0, true, true)
    if entity == nil or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    SetEntityAsMissionEntity(entity, true, true)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then
        DeleteEntity(entity)
        return false
    end

    SetNetworkIdCanMigrate(netId, true)
    SetNetworkIdExistsOnAllMachines(netId, true)
    Bot.SetBotAttribute(entity, profile)
    if outfit ~= nil then
        Appearance.Apply(entity, outfit.appearance)
    end
    registerManagedEntity(profile, entity, netId, true, true)
    Utils.TriggerGamemodeServerEvent("SyncBotEntity", profile.id, netId)
    return true
end

local function adoptEntity(profile)
    if profile.netId == 0 or not NetworkDoesNetworkIdExist(profile.netId) then
        return false
    end

    local entity = NetworkGetEntityFromNetworkId(profile.netId)
    if entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    local hasControl = Bot.RequestControl(entity, 100)
    if hasControl then
        Bot.SetBotAttribute(entity, profile)
    end
    registerManagedEntity(profile, entity, profile.netId, false, hasControl)
    Bot.missingEntities[profile.id] = nil
    return true
end

local function reportMissingEntity(profile)
    local missing = Bot.missingEntities[profile.id]
    if missing == nil or missing.netId ~= profile.netId then
        Bot.missingEntities[profile.id] = {
            netId = profile.netId,
            detectedAt = GetGameTimer(),
            reported = false,
        }
        return
    end

    if not missing.reported and GetGameTimer() - missing.detectedAt >= 3000 then
        missing.reported = true
        Utils.TriggerGamemodeServerEvent("BotEntityMissing", profile.id, profile.netId)
    end
end

local function reportUnattributedDeath(profile, state)
    if state.deathObservedAt == nil then
        state.deathObservedAt = GetGameTimer()
        SetPedCanRagdoll(state.entity, true)
        SetPedToRagdoll(state.entity, BotConfig.respawnDelay, BotConfig.respawnDelay, 0, false, false, false)
        return
    end

    if not state.deathReported and GetGameTimer() - state.deathObservedAt >= 750 then
        state.deathReported = true
        Utils.TriggerGamemodeServerEvent("BotEntityDied", profile.id, profile.team)
    end
end

local function reconcileProfile(profile)
    local state = Bot.entities[profile.id]

    if profile.netId == 0 then
        Bot.missingEntities[profile.id] = nil
        if state ~= nil then
            if state.awaitingSync and not profile.respawning and GetGameTimer() - state.createdAt < 3000 then
                return
            end
            Bot.DeleteManagedEntity(profile.id)
        end

        if not profile.respawning and not Bot.spawnInProgress then
            Bot.spawnInProgress = true
            Citizen.CreateThread(function()
                Bot.CreateNew(profile)
                Bot.spawnInProgress = false
            end)
        end
        return
    end

    if state == nil or state.netId ~= profile.netId or not DoesEntityExist(state.entity) then
        if state ~= nil then
            Bot.DeleteManagedEntity(profile.id)
        end
        adoptEntity(profile)
        state = Bot.entities[profile.id]
    end

    if state == nil then
        reportMissingEntity(profile)
        return
    end
    Bot.missingEntities[profile.id] = nil
    state.awaitingSync = false

    if not state.configured and GetGameTimer() - state.lastControlRequestAt >= 1000 then
        state.lastControlRequestAt = GetGameTimer()
        NetworkRequestControlOfEntity(state.entity)
        if NetworkHasControlOfEntity(state.entity) then
            Bot.SetBotAttribute(state.entity, profile)
            state.configured = true
        end
    end

    if Bot.GameStarted then
        if state.frozen then
            FreezeEntityPosition(state.entity, false)
            state.frozen = false
        end
        if IsEntityDead(state.entity) then
            reportUnattributedDeath(profile, state)
        else
            state.deathObservedAt = nil
            state.deathReported = false
            if Bot.SyncWeapon then
                Bot.SyncWeapon(profile, state)
            end
            Bot.RefreshCombatTask(state)
        end
    else
        if not state.frozen then
            FreezeEntityPosition(state.entity, true)
            state.frozen = true
        end
    end
end

local function cleanRemovedProfiles()
    for botId in pairs(Bot.entities) do
        if Bot.GetProfile(botId) == nil then
            Bot.DeleteManagedEntity(botId)
        end
    end
    for botId in pairs(Bot.missingEntities) do
        if Bot.GetProfile(botId) == nil then
            Bot.missingEntities[botId] = nil
        end
    end
end

Citizen.CreateThread(function()
    while true do
        if Bot.GameId ~= 0 and Bot.isHost and SharedConfig.devmod and not Status.GetIsPlayerInEndScreen() and not StartScreen.InAnimation and not EndScreen.InAnimation then
            for team = 1, 2 do
                for _, profile in pairs(Bot.list[team]) do
                    reconcileProfile(profile)
                end
            end
            cleanRemovedProfiles()
            Wait(150)
        else
            Wait(500)
        end
    end
end)
