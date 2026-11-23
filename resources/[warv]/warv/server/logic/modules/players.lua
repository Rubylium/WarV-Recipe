Players = {}
Players.list = {}
Players.pendingSaves = {}

local function identifier(identifiers, identifierType)
    local prefix = identifierType .. ":"

    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, #prefix) == prefix then
            return id
        end
    end

    return nil
end

function Players.GetIdentity(source)
    local identifiers = GetPlayerIdentifiers(source)
    local license = identifier(identifiers, "license")

    if license == nil or license == "" then
        return nil, "missing_license"
    end

    local tokens = {}
    local tokenCount = GetNumPlayerTokens(source)
    for tokenIndex = 0, tokenCount - 1 do
        local token = GetPlayerToken(source, tokenIndex)
        if token ~= nil and token ~= "" then
            tokens[#tokens + 1] = token
        end
    end

    return {
        license = license,
        license2 = identifier(identifiers, "license2"),
        discord = identifier(identifiers, "discord"),
        fivem = identifier(identifiers, "fivem"),
        steam = identifier(identifiers, "steam"),
        identifiers = identifiers,
        tokens = tokens,
    }
end

local function decodeJson(value, fallback)
    if value == nil or value == "" then
        return fallback
    end

    local success, decoded = pcall(json.decode, value)
    if not success or decoded == nil then
        return fallback
    end

    return decoded
end

local function defaultClasses()
    local classes = {}

    for classIndex = 1, 5 do
        classes[classIndex] = {
            name = "Custom class " .. classIndex,
            weapons = {
                primary = {
                    weapon = "weapon_assaultrifle",
                    comps = {},
                },
                secondary = {
                    weapon = "weapon_pistol",
                    comps = {},
                },
                extra = {
                    weapon = "weapon_grenade",
                    ammo = 1,
                },
            },
        }
    end

    return classes
end

local function newPlayer(source, identity, userData, gameData)
    local unlockedContent = decodeJson(gameData.unlockedContent, {
        guns = {},
        emblems = {},
        callingCards = {},
    })

    unlockedContent.guns = unlockedContent.guns or {}
    unlockedContent.emblems = unlockedContent.emblems or {}
    unlockedContent.callingCards = unlockedContent.callingCards or {}

    local weaponsStats = WeaponRegistry.NormalizeStats(decodeJson(gameData.weaponStats, {}))

    local rawName = GetPlayerName(source) or userData.username or "Unknown"
    local name = RemoveUnallowedSymboleFromString(rawName)
    if string.len(name) > 20 then
        name = string.sub(name, 1, 20) .. "..."
    end

    return {
        needSave = false,
        banned = false,
        id = source,
        uid = tonumber(userData.id),
        gameId = 0,
        permissionLevel = tonumber(userData.permissionLevel or userData.staff) or PermissionConfig.defaultLevel,
        perm = tonumber(userData.permissionLevel or userData.staff) or PermissionConfig.defaultLevel,
        source = source,

        steam = identity.steam or "none",
        fivem = identity.fivem or userData.fivem or "none",
        name = name,
        license = identity.license,
        discord = identity.discord or userData.discord or "none",

        credit = tonumber(gameData.credit) or 0,
        emblemsId = tonumber(gameData.emblemsId) or 1,
        logoId = tonumber(gameData.logoId) or 1,
        xp = tonumber(gameData.xp) or 0,
        weaponsStats = weaponsStats,
        unlockedContent = unlockedContent,
        stats = PlayerStats.Normalize(decodeJson(gameData.stats, nil)),

        aimMode = "TPP",
        lobby = 0,

        kill = tonumber(gameData.kill) or 0,
        assist = tonumber(gameData.assist) or 0,
        death = tonumber(gameData.death) or 0,
        score = tonumber(gameData.score) or 0,
        level = tonumber(gameData.level) or 1,
        prestige = tonumber(gameData.prestige) or 0,
        ranking = tonumber(gameData.ranking) or 1000,
        class = decodeJson(gameData.class, defaultClasses()),
        _saveRevision = 0,
        _savedRevision = 0,
        _saveInProgress = false,
        _closing = false,
        _sessionGeneration = nil,
    }
end

function Players.RefreshPlayerPerms(source)
    local player = Players.list[source]
    if player == nil then
        return
    end

    player.permissionLevel = tonumber(player.permissionLevel or player.perm)
        or PermissionConfig.defaultLevel
    player.perm = player.permissionLevel
end

function Players.SaveData(source)
    local player = Players.list[source]
    if player == nil then
        return false
    end

    player._saveRevision = player._saveRevision + 1
    player.needSave = true
    return true
end

local function SavePlayerRecord(player, sourceLabel, waitForLock)
    if player == nil or tonumber(player.uid) == nil then
        return false
    end

    if player._saveInProgress then
        player.needSave = true

        if not waitForLock then
            return false
        end

        local waited = 0
        while player._saveInProgress and waited < 16000 do
            Wait(50)
            waited = waited + 50
        end

        if player._saveInProgress then
            return false
        end

        if not player.needSave and player._savedRevision >= player._saveRevision then
            return true
        end
    end

    player._saveInProgress = true
    local saved = true

    repeat
        local revision = player._saveRevision
        player.needSave = false
        PlayerStats.SyncPlaytime(player)

        local success, errorMessage = Db.Save(player)
        if not success then
            saved = false
            player.needSave = true
            CriticalPrint("Save failed UID [" .. tostring(player.uid) .. "]: " .. tostring(errorMessage))
            break
        end

        player._savedRevision = revision
    until player._saveRevision <= player._savedRevision

    player._saveInProgress = false

    if saved then
        InfoPrint("Player (" .. tostring(sourceLabel or player.source) .. ") saved ^1now^7.")
    end

    return saved
end

function Players.SaveDataNow(source)
    local player = Players.list[source]
    if player ~= nil then
        player._saveRevision = player._saveRevision + 1
        return SavePlayerRecord(player, source, true)
    end

    return false
end

function Players.SaveDetachedPlayer(player, sourceLabel)
    if player == nil then
        return false
    end

    player._closing = true
    player._saveRevision = player._saveRevision + 1
    local saved = SavePlayerRecord(player, sourceLabel, true)
    if saved and player._sessionGeneration ~= nil then
        PlayerSessions.ReleaseUid(player.uid, player._sessionGeneration)
        if Players.pendingSaves[player.uid] == player then
            Players.pendingSaves[player.uid] = nil
        end
    elseif not saved then
        player._saveRetryAt = os.time() + 5
        Players.pendingSaves[player.uid] = player
    end

    return saved
end

function Players.DetachPlayer(source)
    local session = PlayerSessions.Detach(source)
    local player = session and session.player or Players.list[source]

    if Players.list[source] == player then
        Players.list[source] = nil
    end

    return player, session
end

function Players.RemoveFromCache(source)
    local player = Players.DetachPlayer(source)
    if player ~= nil then
        return Players.SaveDetachedPlayer(player, source)
    end

    return false
end

function Players.BeginConnection(source, identity)
    local session, previous = PlayerSessions.BeginConnection(source, identity)
    local previousPlayer = previous and previous.player or Players.list[source]

    if Players.list[source] == previousPlayer then
        Players.list[source] = nil
    end

    if previousPlayer ~= nil then
        Citizen.CreateThread(function()
            Players.SaveDetachedPlayer(previousPlayer, source)
        end)
    end

    return session
end


local function SendBootstrap(source)
    Players.RefreshData(source)
    Buckets.SetPlayer(source, source)
end

local function LogPlayerLoaded(source, player, created, identity)
    local action = created and "Created" or "Loaded"
    WarningPrint(action .. " player data for (" .. source .. ") with UID: " .. player.uid)
    Discord.SendLogType("connexion", "```User connected: " .. json.encode(player.name) .. "\nStats: " .. json.encode(player.stats) .. "\nLevel: " .. json.encode(player.level) .. "\nKills: " .. json.encode(player.kill) .. "\nId: " .. tostring(source) .. "```")

    local identifiers = ""
    for _, identifier in ipairs(identity.identifiers) do
        if string.sub(identifier, 1, 3) ~= "ip:" then
            identifiers = identifiers .. identifier .. ";\n"
        end
    end

    Discord.SendLogType("connexion-public", "**Player connected**\n**Name**: " .. tostring(player.name) .. "\n**ID**: " .. source .. "\n**Ids**: ```" .. identifiers .. "```")

    if created then
        Discord.SendLogType("new-user", "```New user created: " .. json.encode(player.name) .. "\nStats: " .. json.encode(player.stats) .. "\nUnlocked content: " .. json.encode(player.unlockedContent) .. "```")
    end
end

function Players.AddPlayerIfNotExist(source)
    local existingSession = PlayerSessions.Get(source)
    if existingSession ~= nil and existingSession.state == "ready" and Players.list[source] ~= nil then
        SendBootstrap(source)
        return true
    end

    if not SchemaMigrations.WaitUntilReady(10000) then
        CriticalPrint("Migrations not ready, load blocked [" .. source .. "]")
        DropPlayer(source, "Database not ready. Reconnect.")
        return false
    end

    local identity, identityError = Players.GetIdentity(source)
    if identity == nil then
        CriticalPrint("No license [" .. source .. "]: " .. tostring(identityError))
        DropPlayer(source, "Rockstar license not found. Restart FiveM and reconnect.")
        return false
    end

    local session, shouldLoad, previous = PlayerSessions.StartLoading(source, identity)
    if not shouldLoad then
        return session.state == "ready"
    end

    if previous ~= nil and previous.player ~= nil then
        Citizen.CreateThread(function()
            Players.SaveDetachedPlayer(previous.player, source)
        end)
    end

    local rawName = GetPlayerName(source) or "Unknown"
    local username = RemoveUnallowedSymboleFromString(rawName)
    local userData, created, loadError = Db.LoadOrCreate(identity, username)

    if not PlayerSessions.IsCurrent(source, session.generation, identity.license) then
        WarningPrint("Stale load [" .. source .. "]")
        return false
    end

    if userData == nil then
        PlayerSessions.Fail(source, session.generation)
        CriticalPrint("Player load [" .. source .. "]: " .. tostring(loadError))
        DropPlayer(source, "Profile failed to load. Reconnect.")
        return false
    end

    local reservationWait = 0
    local uidReservation = PlayerSessions.GetUidReservation(userData.id)
    while uidReservation ~= nil
        and uidReservation.generation ~= session.generation
        and uidReservation.state == "closing"
        and reservationWait < 16000 do
        Wait(50)
        reservationWait = reservationWait + 50

        if not PlayerSessions.IsCurrent(source, session.generation, identity.license) then
            return false
        end

        uidReservation = PlayerSessions.GetUidReservation(userData.id)
    end

    if uidReservation ~= nil and uidReservation.generation ~= session.generation then
        PlayerSessions.Fail(source, session.generation)

        if uidReservation.state == "closing" then
            DropPlayer(source, "Previous session still saving. Reconnect in a few seconds.")
        else
            DropPlayer(source, "This account is already connected to the server.")
        end

        return false
    end

    local gameData, profileError = Db.LoadProfile(userData.id)
    if gameData == nil then
        PlayerSessions.Fail(source, session.generation)
        CriticalPrint("Profile load [" .. source .. "]: " .. tostring(profileError))
        DropPlayer(source, "Profile failed to load. Reconnect.")
        return false
    end

    local player = newPlayer(source, identity, userData, gameData)
    player._sessionGeneration = session.generation

    local published, publishError, activeSource = PlayerSessions.Publish(source, session.generation, player)
    if not published then
        PlayerSessions.Fail(source, session.generation)

        if publishError == "uid_already_online" then
            CriticalPrint("Duplicate UID [" .. player.uid .. "] source [" .. source .. "] active [" .. activeSource .. "]")
            DropPlayer(source, "This account is already connected to the server.")
        end

        return false
    end

    Players.list[source] = player
    PlayerStats.StartPlaytime(player)
    Players.RefreshLevel(source)
    CallingCards.NormalizePlayer(player)
    Emblems.NormalizePlayer(player)
    Citizen.CreateThread(function()
        Friends.Load(player.uid)
        Challenges.Load(player.uid)
    end)
    Players.RefreshPlayerPerms(source)
    SendBootstrap(source)
    LogPlayerLoaded(source, player, created, identity)
    return true
end

function Players.AddNewPlayer(source)
    return Players.AddPlayerIfNotExist(source)
end

function Players.RefreshData(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]

        TriggerLatentClientEvent("warv:GetGlobalData", source, 30000, data.banned, data.uid, data.id, data.steam, data.gameId, data.perm, data.fivem, data.name, data.credit, data.emblemsId, data.xp, data.level, data.prestige, data.ranking, data.logoId)

    end
end

function Players.RefreshUnlockedContent(source)
    if Players.DoesPlayerExist(source) then
        TriggerClientEvent("warv:RefreshUnlockedContent", source, Players.list[source].unlockedContent)
    end
end

function Players.DoesPlayerExist(source)
    return Players.list[source] ~= nil
end

function Players.IsBanned(source)
    if Players.DoesPlayerExist(source) then
        return Players.list[source].banned, Players.list[source].banType
    end
end

function Players.GetPlayerGameId(source)
    if Players.DoesPlayerExist(source) then
        return Players.list[source].gameId
    end
end

function Players.SetPlayerGameId(source, gameId)
    if Players.DoesPlayerExist(source) then
        Players.list[source].gameId = gameId
    end
end

function Players.RefreshLevel(source)
    if Players.DoesPlayerExist(source) then
        Players.list[source].level = tostring(GetPlayerLevelFromXp(Players.list[source].xp, Players.list[source].prestige))
    end
end

function Players.Get(source)
    if Players.DoesPlayerExist(source) then
        return Players.list[source]
    end
end

function Players.GetSourceFromUID(uid)
    return PlayerSessions.GetSourceByUid(uid)
end

AddEventHandler("warv:GetSourceFromUID", function(uid, cb)
    cb(Players.GetSourceFromUID(uid))
end)

function Players.GetRanking(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.ranking
    end
end

function Players.GetSteamId(source)
    if Players.DoesPlayerExist(source) then
        return Players.list[source].steam
    end
end

function Players.GetEmblesId(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.emblemsId
    end
end

function Players.GetLogoId(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.logoId
    end
end

function Players.SetLogoId(source, id)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        data.logoId = id
    end
end

function Players.SetNewRanking(source, new)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        local new = tonumber(new)
        if new <= 1000 then
            new = 1000
        end
        data.ranking = tonumber(new)
    end
end

function Players.GetLevel(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return tostring(GetPlayerLevelFromXp(data.xp, data.prestige))
    end
end

function Players.GetPrestige(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return tostring(data.prestige)
    end
end

function Players.GetWinStreak(source)
    if Players.DoesPlayerExist(source) then
        return tonumber(Players.list[source].stats.winStreak) or 0
    end
    return 0
end

function Players.GetStats(source)
    if Players.DoesPlayerExist(source) then
        return Players.list[source].stats
    end
    return {}
end

function Players.GetName(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]

        if string.len(data.name) > 20 then
            data.name = string.sub(data.name, 1,20).."..."
        end

        return data.name
    end
    return "Unknow"
end

function Players.GetKills(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.kill
    end
end

function Players.GetDeaths(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.death
    end
end

function Players.GetScores(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.score
    end
end

function Players.GetPerms(source)
    return Permissions.GetLevel(source)
end

function Players.HasPermission(source, requiredLevel)
    return Permissions.Has(source, requiredLevel)
end

function Players.GetAimMode(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.aimMode
    end
end

function Players.SetAimMode(source, mode)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        data.aimMode = mode
    end
end

function Players.AddXp(source, xp)
    if Players.DoesPlayerExist(source) then
        local oldLevel = GetPlayerLevelFromXp(Players.list[source].xp, Players.list[source].prestige)
        Players.list[source].xp = Players.list[source].xp + xp
        local newLevel = GetPlayerLevelFromXp(Players.list[source].xp, Players.list[source].prestige)
        if oldLevel ~= newLevel then
            TriggerClientEvent("warv:LevelUpNotification", source, newLevel, Players.list[source].prestige)


            local newGuns = {}
            for _,categories in pairs(SharedConfig.weapons) do
                for _,type in pairs(categories) do
                    for _,v in pairs(type.weapons) do
                        if v.level == newLevel then
                            table.insert(newGuns, v.weapon)
                        end
                    end
                end
            end

            for k,v in pairs(newGuns) do
                TriggerClientEvent("warv:UnlockNotificationNewGun", source, v)
            end
        end

        Players.RefreshLevel(source)
    end
end

function Players.AddOneKill(source)
    if Players.DoesPlayerExist(source) then
        Players.list[source].kill = Players.list[source].kill + 1
    end
end

function Players.AddKills(source, kills)
    if Players.DoesPlayerExist(source) then
        Players.list[source].kill = Players.list[source].kill + kills
    end
end

function Players.AddAssists(source, assists)
    if Players.DoesPlayerExist(source) then
        Players.list[source].assist = Players.list[source].assist + assists
        Challenges.Progress(source, "assists", assists)
    end
end

function Players.AddOneDeath(source)
    if Players.DoesPlayerExist(source) then
        Players.list[source].death = Players.list[source].death + 1
    end
end

function Players.AddDeaths(source, deaths)
    if Players.DoesPlayerExist(source) then
        Players.list[source].death = Players.list[source].death + deaths
    end
end

function Players.AddScores(source, score)
    if Players.DoesPlayerExist(source) then
        Players.list[source].score = Players.list[source].score + score
    end
end

function Players.AddPrestige(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        if tonumber(data.level) >= 55 and data.prestige < 5 then
            data.level = 1
            data.xp = 0
            data.prestige = data.prestige + 1

            TriggerClientEvent("warv:LevelUpNotification", source, 1, Players.list[source].prestige)
            Players.RefreshLevel(source)

        end
    end
end

function Players.SetClass(source, class)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        data.class = class


        for k,v in pairs(data.class) do
            v.name = RemoveUnallowedSymboleFromString(v.name)
        end
    end
end

function Players.SetEmblesId(source, id)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        data.emblemsId = id
    end
end


function Players.IsPlayerOnlineWithUID(uid)
    local source = PlayerSessions.GetSourceByUid(uid)
    if source ~= nil then
        return true, source
    end

    return false, 0
end

function Players.AddKillToWeapon(source, weapon, headshot)
    if Players.DoesPlayerExist(source) then
        weapon = WeaponRegistry.NormalizeName(weapon)
        if not weapon then return end

        local data = Players.list[source]
        if data.weaponsStats[weapon] == nil then
            data.weaponsStats[weapon] = {
                kill = 0,
                assist = 0,
                headshot = 0,
                xp = 0,
                level = 1,
            }
        end
        local ws = data.weaponsStats[weapon]
        ws.kill = (tonumber(ws.kill) or 0) + 1
        if headshot then
            ws.headshot = (tonumber(ws.headshot) or 0) + 1
            Unlocks.AddStat(data, "headshot", 1)
        end
        Challenges.AddKill(source, weapon, headshot)

        local oldLevel = tonumber(ws.level) or WeaponProgression.LevelFromXp(ws.xp)
        ws.xp = (tonumber(ws.xp) or 0) + WeaponProgression.XpPerKill + (headshot and WeaponProgression.XpHeadshotBonus or 0)
        local newLevel = WeaponProgression.LevelFromXp(ws.xp)
        ws.level = newLevel
        if newLevel > oldLevel then
            TriggerClientEvent("warv:WeaponLevelUpNotification", source, weapon, newLevel)
        end
    end
end

function Players.DoesPlayerHaveEmblem(source, index)
    if Players.DoesPlayerExist(source) then
        local emblem = Emblems.Get(index)
        return emblem ~= nil and Players.list[source].unlockedContent.emblems[emblem.id] == true
    end
    return false
end

function Players.AddUnlockedEmblem(source, index)
    if Players.DoesPlayerExist(source) then
        local emblem = Emblems.Get(index)
        if emblem and not Players.list[source].unlockedContent.emblems[emblem.id] then
            Players.list[source].unlockedContent.emblems[emblem.id] = true

            Players.RefreshUnlockedContent(source)
        end
    end
end

function Players.AddCreditBasedOnScore(source, score)
    if Players.DoesPlayerExist(source) then
        local credit = math.floor(score / 3000)
        local data = Players.list[source]
        data.credit = data.credit + credit
    end
end

function Players.RefreshCreditsData(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]

        TriggerClientEvent("warv:GetCreditData", source, data.credit)
    end
end

function Players.SetPlayerCurrentLobby(source, lobbyId)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        data.lobby = lobbyId
    end
end

function Players.GetPlayerCurrentLobby(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.lobby
    end
    return 0
end

function Players.AddPlayerStatWin(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        if data.stats.win == nil then
            data.stats.win = 0
        end
        data.stats.win = data.stats.win + 1
        data.stats.winStreak = (tonumber(data.stats.winStreak) or 0) + 1
        data.stats.bestWinStreak = math.max(tonumber(data.stats.bestWinStreak) or 0, data.stats.winStreak)
    end
end

function Players.AddPlayerStatLoose(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        if data.stats.loose == nil then
            data.stats.loose = 0
        end
        data.stats.loose = data.stats.loose + 1
        data.stats.winStreak = 0
    end
end

function Players.AddPlayerStatDraw(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        if data.stats.draw == nil then
            data.stats.draw = 0
        end
        data.stats.draw = data.stats.draw + 1
    end
end

function Players.AddPlayerStatGamePlayed(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        if data.stats.gamePlayed == nil then
            data.stats.gamePlayed = 0
        end
        data.stats.gamePlayed = data.stats.gamePlayed + 1
    end
end

function Players.GetPlayerFromSteam(steam)
    for k, v in pairs(Players.list) do
        if v.steam == steam then
            return k
        end
    end
    return nil
end

function Players.GetPlayerObject(source)
    return Players.list[source] or false
end

function Players.GetPlayerUid(source)
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        return data.uid
    end
end

function Players.GetPlayerFromUID(uid)
    return PlayerSessions.GetSourceByUid(uid)
end

RegisterNetEvent("warv:GetClassData")
AddEventHandler("warv:GetClassData", function()
    local source = source
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        TriggerLatentClientEvent("warv:GetClassData", source, 30000, data.class)
    end
end)

RegisterNetEvent("warv:GetStatsData")
AddEventHandler("warv:GetStatsData", function()
    local source = source
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        PlayerStats.SyncPlaytime(data)
        TriggerLatentClientEvent("warv:GetStatsData", source, 30000, data.kill, data.assist, data.death, data.score, data.xp, data.level, data.stats)
    end
end)

RegisterNetEvent("warv:GetWeaponStatsData")
AddEventHandler("warv:GetWeaponStatsData", function()
    local source = source
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        TriggerLatentClientEvent("warv:GetWeaponStatsData", source, 30000, data.weaponsStats)
    end
end)

RegisterNetEvent("warv:GetUnlockedContentData")
AddEventHandler("warv:GetUnlockedContentData", function()
    local source = source
    if Players.DoesPlayerExist(source) then
        local data = Players.list[source]
        TriggerLatentClientEvent("warv:GetUnlockedContentData", source, 30000, data.unlockedContent)
    end
end)


RegisterNetEvent("warv:Init")
AddEventHandler("warv:Init", function()
    local source = source
    Players.AddPlayerIfNotExist(source)
end)


RegisterNetEvent("warv:SetAimMode")
AddEventHandler("warv:SetAimMode", function(mode)
    Players.SetAimMode(source, mode)
end)

RegisterNetEvent("warv:TriggerPrestige")
AddEventHandler("warv:TriggerPrestige", function()
    local source = source
    if not Players.DoesPlayerExist(source) then
        return
    end

    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    Players.AddPrestige(source)
    TriggerClientEvent("warv:RefreshPlayerData", source, Players.list[source])
end)

RegisterNetEvent("warv:UpdateClass")
AddEventHandler("warv:UpdateClass", function(class)
    local source = source
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    Players.SetClass(source, class)
end)

RegisterNetEvent("warv:UpdateEmblem")
AddEventHandler("warv:UpdateEmblem", function(emblemId)
    local source = source
    if not Players.DoesPlayerExist(source) then
        return
    end
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    local index = tonumber(emblemId)
    if index and CallingCards.IsUnlocked(Players.list[source], math.floor(index)) then
        Players.SetEmblesId(source, math.floor(index))
        Players.RefreshData(source)
    end
    CallingCards.SendProgress(source)
end)

RegisterNetEvent("warv:UpdateLogo")
AddEventHandler("warv:UpdateLogo", function(LogoId)
    local source = source
    local banned, type = Players.IsBanned(source)
    if banned then
        DropPlayer(source, Ban.type[type].desc)
        return
    end
    local index = tonumber(LogoId)
    if index and Emblems.IsUnlocked(Players.list[source], math.floor(index)) then
        Players.SetLogoId(source, math.floor(index))
        Players.RefreshData(source)
    end
    Emblems.SendProgress(source)
end)

Citizen.CreateThread(function()
    while true do
        for k,v in pairs(Players.list) do
            if v.needSave and not v._saveInProgress then
                local sourceToSave = k
                local playerToSave = v
                Citizen.CreateThread(function()
                    SavePlayerRecord(playerToSave, sourceToSave, false)
                end)
            end
        end

        for uid, player in pairs(Players.pendingSaves) do
            if not player._saveInProgress and os.time() >= (player._saveRetryAt or 0) then
                local pendingUid = uid
                local pendingPlayer = player
                Citizen.CreateThread(function()
                    local saved = Players.SaveDetachedPlayer(pendingPlayer, pendingPlayer.source)
                    if saved and Players.pendingSaves[pendingUid] == pendingPlayer then
                        Players.pendingSaves[pendingUid] = nil
                    end
                end)
            end
        end

        Wait(1000)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if GetResourceState("oxmysql") ~= "started" then
        WarningPrint("oxmysql stopped, final save skipped")
        return
    end

    Db.shuttingDown = true

    local sources = {}
    for source in pairs(Players.list) do
        sources[#sources + 1] = source
    end

    for _, source in ipairs(sources) do
        local player = Players.DetachPlayer(source)
        if player ~= nil then
            Players.SaveDetachedPlayer(player, source)
        end
    end


    for _, player in pairs(Players.pendingSaves) do
        Players.SaveDetachedPlayer(player, player.source)
    end
end)

exports("getPlayers", function()
    return Players
end)
