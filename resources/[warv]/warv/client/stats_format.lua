StatsFormat = {}

function StatsFormat.Playtime(totalSeconds)
    totalSeconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))
    local totalMinutes = math.floor(totalSeconds / 60)
    local totalHours = math.floor(totalMinutes / 60)
    local days = math.floor(totalHours / 24)
    local hours = totalHours % 24
    local minutes = totalMinutes % 60

    if days > 0 then
        return days .. "d " .. hours .. "h"
    end
    if totalHours > 0 then
        return totalHours .. "h " .. minutes .. "m"
    end
    if totalMinutes > 0 then
        return totalMinutes .. "m"
    end
    return "<1m"
end

function StatsFormat.LevelProgress(totalXp, level, getThreshold)
    totalXp = math.max(0, tonumber(totalXp) or 0)
    level = math.max(1, math.floor(tonumber(level) or 1))

    local currentThreshold = level == 1 and 0 or tonumber(getThreshold(level - 1)) or 0
    local nextThreshold = tonumber(getThreshold(level)) or currentThreshold + 1
    local span = math.max(1, nextThreshold - currentThreshold)
    local progress = math.max(0, math.min(span, totalXp - currentThreshold))
    return progress, span
end
