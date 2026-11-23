BotRoster = {}

local function copyProfile(profile)
    return {
        id = profile.id,
        profileId = profile.profileId,
        emblemsId = profile.emblemsId,
        name = profile.name,
        level = profile.level,
        prestige = profile.prestige,
        score = profile.score,
        kill = profile.kill,
        death = profile.death,
        assist = profile.assist,
        ping = profile.ping,
        team = profile.team,
        outfit = profile.outfit,
        netId = profile.netId,
        respawning = profile.respawning,
    }
end

function BotRoster.New(gameId, teams)
    return {
        gameId = gameId,
        hostId = 0,
        nextProfileId = 1,
        noTeams = teams == false,
        list = {
            [1] = {},
            [2] = {},
        },
    }
end

function BotRoster.Find(roster, botId, team)
    team = tonumber(team)
    if roster.list[team] == nil then
        return nil
    end

    for _, bot in pairs(roster.list[team]) do
        if bot.id == botId then
            return bot
        end
    end

    return nil
end

function BotRoster.FindAny(roster, botId)
    return BotRoster.Find(roster, botId, 1) or BotRoster.Find(roster, botId, 2)
end

function BotRoster.IsHost(roster, source)
    return roster.hostId ~= 0 and tonumber(source) == tonumber(roster.hostId)
end

function BotRoster.CreateBot(roster, team)
    local profileId = roster.nextProfileId
    local nameIndex = ((profileId - 1) % #BotConfig.names) + 1
    local outfitPool = Outfits.TeamOutfits(roster.noTeams and math.random(1, 2) or team)
    local outfit
    if #outfitPool > 0 then
        local outfitIndex = roster.noTeams
            and math.random(1, #outfitPool)
            or (((profileId - 1) % #outfitPool) + 1)
        outfit = outfitPool[outfitIndex]
    end
    roster.nextProfileId = profileId + 1

    return {
        id = ("bot:%s:%s"):format(roster.gameId, profileId),
        profileId = profileId,
        emblemsId = ((profileId - 1) % #SharedConfig.callingCards) + 1,
        name = BotConfig.names[nameIndex],
        level = ((profileId * 7) % 55) + 1,
        prestige = 0,
        score = 0,
        kill = 0,
        death = 0,
        assist = 0,
        ping = 0,
        team = team,
        outfit = outfit and outfit.id,
        netId = 0,
        respawning = false,
        lastDeathAt = 0,
    }
end

function BotRoster.ResizeTeam(roster, team, targetCount, onRemove)
    local teamList = roster.list[team]

    while #teamList < targetCount do
        table.insert(teamList, BotRoster.CreateBot(roster, team))
    end

    while #teamList > targetCount do
        onRemove(table.remove(teamList))
    end
end

function BotRoster.Serialize(roster)
    local result = {
        [1] = {},
        [2] = {},
    }

    for team = 1, 2 do
        for _, bot in pairs(roster.list[team]) do
            table.insert(result[team], copyProfile(bot))
        end
    end

    return result
end

function BotRoster.MarkDead(roster, botId, team, onRespawnReady, scheduleTimeout)
    local bot = BotRoster.Find(roster, botId, team)
    if bot == nil or bot.respawning then
        return nil
    end

    bot.death = bot.death + 1
    bot.respawning = true
    bot.lastDeathAt = GetGameTimer()

    scheduleTimeout(BotConfig.respawnDelay, function()
        local currentBot = BotRoster.Find(roster, botId, team)
        if currentBot == bot then
            local previousNetId = currentBot.netId
            currentBot.netId = 0
            currentBot.respawning = false
            onRespawnReady(currentBot, previousNetId)
        end
    end)

    return bot
end
