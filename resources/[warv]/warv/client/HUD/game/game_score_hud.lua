ScoreHud = {}

local lastKey = ""
local lastVisible = nil

local function myScoreAndBestOther(playersData)
    local pSID = GetPlayerServerId(GetPlayerIndex())
    local myScore, bestOther = 0, 0
    for _, v in pairs(playersData or {}) do
        local s = tonumber(v.kill) or 0
        if v.id == pSID then
            myScore = s
        elseif s > bestOther then
            bestOther = s
        end
    end
    for t = 1, 2 do
        for _, b in pairs(Bot.list[t] or {}) do
            local s = tonumber(b.kill) or 0
            if s > bestOther then bestOther = s end
        end
    end
    return myScore, bestOther
end

local function gamemodeIcon(name)
    name = string.upper(tostring(name or ""):gsub("~%a~", ""))
    for _, gm in ipairs(SharedConfig.Gamemode) do
        if string.upper(tostring(gm.name or "")) == name then
            return gm.sprite or ""
        end
    end
    return ""
end

function ScoreHud.Update(team1score, team2score, maxScore, myTeam)
    local gm = Matchmaking.data.gamemode
    local gmName = tostring(gm or ""):gsub("~%a~", "")
    local teamMode = Lobby.MatchGamemodeHasTeams(gm)
    local timer = tonumber(Matchmaking.data.gameTimer) or 0
    local gmIcon = gamemodeIcon(gm)

    local left, right, barMax
    if teamMode then
        local isa = { score = tonumber(team1score) or 0, label = "", logo = "team_1", color = "blue" }
        local mercs = { score = tonumber(team2score) or 0, label = "", logo = "team_2", color = "red" }
        if myTeam == 1 then
            left, right = isa, mercs
        else
            left, right = mercs, isa
        end
        barMax = tonumber(maxScore) or 0
    else
        local myScore, bestOther = myScoreAndBestOther(Gamemode.PlayersData)
        left = { score = myScore, label = "YOU", logo = "", color = "blue" }
        right = { score = bestOther, label = "TOP", logo = "", color = "red" }
        barMax = Match.fragLimit or math.max(myScore, bestOther, 1)
    end

    local key = string.format("%s|%d|%d|%d|%d|%s|%s",
        tostring(teamMode), timer, left.score, right.score, barMax, left.logo, gmIcon)
    if key == lastKey and lastVisible == true then return end
    lastKey = key
    lastVisible = true

    exports['warv-ui']:SetScoreHud({
        visible = true,
        teamMode = teamMode,
        gamemode = gmName,
        gmIcon = gmIcon,
        timer = timer,
        maxScore = barMax,
        left = left,
        right = right,
    })
end

function ScoreHud.Hide()
    if lastVisible == false then return end
    lastVisible = false
    lastKey = ""
    exports['warv-ui']:SetScoreHud({
        visible = false,
        teamMode = true,
        gamemode = "",
        gmIcon = "",
        timer = 0,
        maxScore = 0,
        left = { score = 0, label = "", logo = "", color = "blue" },
        right = { score = 0, label = "", logo = "", color = "red" },
    })
end
