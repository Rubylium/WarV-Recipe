Score = {}
Score.cache = 0

function Score.ResetScoreFeed()
    exports['warv-ui']:ScorePopupReset()
end

function Score.ResetCache()
    Score.cache = 0
end

function Score.ShowFeedback(points, label)
    if Status.GetIsPlayerInEndScreen() then
        Score.ResetScoreFeed()
        return
    end

    exports['warv-ui']:ScorePopup(points, tostring(label or ""))
end

function Score.AddKillstreakProgress(points)
    if Matchmaking.data.gamemode ~= nil and Gamemode.GamemodeWithoutKillstreaks[Matchmaking.data.gamemode] == nil then
        Score.cache = Score.cache + points
        Gamemode.HandleKillstreak(Score.cache)
    end
end

function Score.GetKillstreakProgressPoints(points, isKillstreakKill)
    local progressPoints = math.max(0, tonumber(points) or 0)
    if not isKillstreakKill then return progressPoints end

    return math.floor(progressPoints * SharedConfig.KillstreakProgress.killMultiplier + 0.5)
end

function Score.AddScore(points, label, progressPoints)
    if Status.GetIsPlayerInEndScreen() then
        Score.ResetScoreFeed()
        return
    end

    exports['warv-ui']:ScorePopup(points, tostring(label or ""))
    Score.AddKillstreakProgress(progressPoints or points)
end
