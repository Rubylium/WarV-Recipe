Lobby.scoreboardVisible = false
local lastSend = 0

local function kdString(kill, death)
    kill = tonumber(kill) or 0
    death = tonumber(death) or 0
    if death <= 0 then return string.format("%.2f", kill) end
    return string.format("%.2f", kill / death)
end

local function voiceState(id)
    if not id or id == 0 or not MumbleIsConnected() then return "none" end
    local ch = MumbleGetVoiceChannelFromServerId(tonumber(id))
    if not ch or ch == -1 or ch == 0 then return "none" end
    if Voice.muted[id] ~= nil then return "muted" end
    if NetworkIsPlayerTalking(GetPlayerFromServerId(id)) then return "talking" end
    return "idle"
end

local function buildRow(self)
    if self == nil or self.id == nil or self.id == 0 then
        return { empty = true }
    end
    return {
        id = self.id,
        name = self.name or "",
        uid = tostring(self.uid or "0"),
        level = self.level or 1,
        prestige = self.prestige or 0,
        rankIcon = GetRankIcon(self.level, self.prestige),
        ping = self.ping or 0,
        score = self.score or 0,
        kill = self.kill or 0,
        assist = self.assist or 0,
        death = self.death or 0,
        kd = kdString(self.kill, self.death),
        isMe = self.id == GetPlayerServerId(GetPlayerIndex()),
        voice = voiceState(self.id),
        bot = self.bot and true or false,
    }
end

local function insertByScore(list, v)
    for i, j in pairs(list) do
        if j.score < v.score then
            table.insert(list, i, v)
            return
        end
    end
    table.insert(list, v)
end

function Lobby.HideScoreboard()
    if Lobby.scoreboardVisible then
        Lobby.scoreboardVisible = false
        exports["warv-ui"]:SetScoreboard({ visible = false })
    end
end

function Lobby.DrawTeamScoreboard(playersList, score1, score2, bots)
    local team1Score = 0
    local team2Score = 0
    local players1 = {}
    local players2 = {}

    if Gamemode.NoTeams then
        local all = {}
        for _, v in pairs(playersList or {}) do
            table.insert(all, v)
        end
        if bots ~= nil then
            for t = 1, 2 do
                for _, v in pairs(bots[t] or {}) do
                    v.ping = 15
                    v.bot = true
                    table.insert(all, v)
                end
            end
        end
        table.sort(all, function(a, b) return (a.score or 0) > (b.score or 0) end)
        team1Score = (all[1] and all[1].kill) or 0
        team2Score = ""
        for idx, v in ipairs(all) do
            if idx <= 10 then
                table.insert(players1, v)
            end
        end
    else
        local lists, kills = { players1, players2 }, { 0, 0 }
        for t = 1, 2 do
            for _, v in pairs(bots and bots[t] or {}) do
                kills[t] = kills[t] + v.kill
                v.ping = 15
                v.bot = true
                insertByScore(lists[t], v)
            end
        end

        for _, v in pairs(playersList) do
            local t = v.team == 1 and 1 or 2
            kills[t] = kills[t] + v.kill
            insertByScore(lists[t], v)
        end
        team1Score, team2Score = kills[1], kills[2]
    end

    if not Gamemode.NoTeams then
        for _ = #players1 + 1, 5 do table.insert(players1, { id = 0 }) end
        for _ = #players2 + 1, 5 do table.insert(players2, { id = 0 }) end
    end

    if score1 ~= nil and score1 ~= 0 then team1Score = score1 end
    if score2 ~= nil and score2 ~= 0 then team2Score = score2 end

    local now = GetGameTimer()
    if Lobby.scoreboardVisible and (now - lastSend) < 150 then
        return
    end
    lastSend = now
    Lobby.scoreboardVisible = true

    local team1 = {}
    for i, v in ipairs(players1) do
        local row = buildRow(v)
        row.rank = i
        team1[#team1 + 1] = row
    end
    local team2 = {}
    for i, v in ipairs(players2) do
        local row = buildRow(v)
        row.rank = i + 5
        team2[#team2 + 1] = row
    end

    exports["warv-ui"]:SetScoreboard({
        visible = true,
        mode = Gamemode.NoTeams and "ffa" or "teams",
        myTeam = Gamemode.Team or 0,
        gamemode = Lobby.selectedGamemode or "",
        map = Matchmaking.selectedMap.name or "",
        team1Score = team1Score,
        team2Score = team2Score,
        team1 = team1,
        team2 = team2,
    })
end
