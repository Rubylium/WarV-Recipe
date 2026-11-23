PlayerStats = {}

local defaultStats = {
    win = 0,
    loose = 0,
    draw = 0,
    shots = 0,
    shotsHit = 0,
    headshot = 0,
    nukes = 0,
    gamePlayed = 0,
    winStreak = 0,
    bestWinStreak = 0,
}

function PlayerStats.Normalize(stats)
    if type(stats) ~= "table" then
        stats = {}
    end

    for key, value in pairs(defaultStats) do
        if stats[key] == nil then
            stats[key] = value
        end
    end

    local playtimeSeconds = tonumber(stats.playtimeSeconds)
    if playtimeSeconds == nil then
        playtimeSeconds = (tonumber(stats.hoursPlayed) or 0) * 3600
    end
    stats.playtimeSeconds = math.max(0, math.floor(playtimeSeconds))
    stats.hoursPlayed = stats.playtimeSeconds / 3600
    return stats
end

function PlayerStats.StartPlaytime(player)
    player.playtimeStartedAt = os.time()
end

function PlayerStats.SyncPlaytime(player)
    local now = os.time()
    local startedAt = player.playtimeStartedAt or now
    local elapsed = math.max(0, now - startedAt)
    if elapsed > 0 then
        player.stats.playtimeSeconds = player.stats.playtimeSeconds + elapsed
        player.stats.hoursPlayed = player.stats.playtimeSeconds / 3600
    end
    player.playtimeStartedAt = now
    return player.stats.playtimeSeconds
end
