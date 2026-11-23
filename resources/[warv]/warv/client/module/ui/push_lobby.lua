local function playable()
    local out = {}
    for _, gm in ipairs(SharedConfig.Gamemode) do
        if gm.type == "normal" and gm.name and GamemodeDefinitions.IsImplemented(gm.name) then
            out[#out + 1] = gm
        end
    end
    return out
end

local function buildMenuData()
    local pd = Lobby.playerData

    local news = {}
    for _, v in ipairs(SharedConfig.News) do
        news[#news + 1] = { title = "", text = v[1] or "" }
    end

    local selfId = GetPlayerServerId(GetPlayerIndex())
    local members = {}
    for _, m in ipairs(Menu.squad.members) do
        local level = tonumber(m.level) or 1
        local prestige = tonumber(m.prestige) or 0
        members[#members + 1] = {
            id = m.id,
            name = m.name,
            level = level,
            prestige = prestige,
            rankIcon = GetRankIcon(level, prestige) or ("rank_" .. level),
            leader = (Menu.squad.isLeader and m.id == selfId) or false,
            self = (m.id == selfId),
        }
    end

    local gamemodes = {}
    for _, gm in ipairs(playable()) do
        local label = tostring(gm.label or gm.name):gsub("~%a~", "")
        gamemodes[#gamemodes + 1] = {
            name = gm.name,
            label = label,
            sprite = gm.sprite or "",
            players = (Lobby.playersPerGamemode and Lobby.playersPerGamemode[gm.name]) or 0,
        }
    end

    return {
        player = MenuUI.Player(),
        squad = {
            isLeader = Menu.squad.isLeader == true,
            isOpen = false,
            members = members,
            invites = Menu.squad.invites,
        },
        news = news,
        gamemodes = gamemodes,
        banned = { active = (pd.banned == true), text = tostring(pd.banTimeRemainText or "") },
        permissions = {
            clothingCreator = (tonumber(pd.perm) or 0) >= 2,
            mapEditor = (tonumber(pd.perm) or 0) >= 3,
        },
    }
end

function Lobby.PushMenuData()
    exports['warv-ui']:SetMenuData(buildMenuData())
end

function Lobby.PushBarracksData()
    local pd = Lobby.playerData
    local stats = pd.stats or {}
    local kills = tonumber(pd.kill) or 0
    local deaths = tonumber(pd.death) or 0
    local wins = tonumber(stats.win) or 0
    local losses = tonumber(stats.loose) or 0
    local headshots = tonumber(stats.headshot) or 0
    exports['warv-ui']:SetBarracksData({
        player = MenuUI.Player(),
        stats = {
            kills = kills,
            deaths = deaths,
            assists = tonumber(pd.assist) or 0,
            kda = MenuUI.Ratio(kills, deaths),
            wins = wins,
            draws = tonumber(stats.draw) or 0,
            losses = losses,
            wlr = MenuUI.Ratio(wins, losses),
            score = tonumber(pd.score) or 0,
            winStreak = tonumber(stats.winStreak) or 0,
            bestWinStreak = tonumber(stats.bestWinStreak) or 0,
            headshots = headshots,
            headshotRatio = kills > 0 and string.format("%.1f%%", headshots / kills * 100) or "0.0%",
            playtimeText = StatsFormat.Playtime(stats.playtimeSeconds),
            canPrestige = (tonumber(pd.level) or 1) >= 55,
        },
    })
end

function Lobby.PushServerBrowser()
    local servers = {}
    for _, v in ipairs(GlobalState.lobbys or {}) do
        local mapName = ""
        if v.gameMap and SharedConfig.Maps[v.gameMap] then
            mapName = tostring(SharedConfig.Maps[v.gameMap].name or v.gameMap)
        elseif v.gameMap then
            mapName = tostring(v.gameMap)
        end
        servers[#servers + 1] = {
            id = tostring(v.gameId or ""),
            official = v.inMatchmaking == true,
            voting = v.inMatchmaking == true,
            gamemode = tostring(v.gamemode or ""),
            map = mapName,
            players = tonumber(v.playerCount) or 0,
            maxPlayers = tonumber(v.maxPlayers) or 0,
            ping = tonumber(v.ping) or 0,
            sprite = MenuUI.GamemodeSprite(v.gamemode),
        }
    end
    exports['warv-ui']:SetServerBrowser({ servers = servers, error = Menu.browserError or "" })
end

local function selfProfile()
    local pd = Lobby.playerData
    local stats = pd.stats or {}
    return {
        uid = pd.uid,
        name = pd.name,
        level = pd.level,
        prestige = pd.prestige,
        ranking = pd.ranking,
        emblem = pd.emblemsId,
        logo = Data.playerIcon,
        kills = pd.kill,
        deaths = pd.death,
        wins = stats.win,
        losses = stats.loose,
        winStreak = stats.winStreak,
        bestStreak = stats.bestWinStreak,
    }
end

function Lobby.PushLobbyWait()
    local mm = Matchmaking
    local data = mm.data or {}
    local ranked = mm.ranked == true
    local selfId = Player.GetServerId()

    local state
    if not mm.found then
        state = "searching"
    elseif data.gameCanStart ~= nil and not data.gameCanStart then
        state = "waiting"
    elseif not data.gameMapVoted then
        state = "voting"
    else
        state = "starting"
    end

    local players = {}
    for i, v in ipairs(data.players or {}) do
        if (v.id or 0) == 0 then
            players[#players + 1] = { slot = i, empty = true }
        else
            local isSelf = (v.id == selfId)
            local p = isSelf and selfProfile() or v
            local lvl = tonumber(p.level) or 0
            local prestige = tonumber(p.prestige) or 0
            local talking = false
            local plyIdx = GetPlayerFromServerId(v.id)
            if plyIdx ~= -1 and NetworkIsPlayerTalking(plyIdx) then talking = true end
            local kills = tonumber(p.kills) or 0
            local deaths = tonumber(p.deaths) or 0
            local wins = tonumber(p.wins) or 0
            players[#players + 1] = {
                slot = i,
                empty = false,
                id = v.id,
                uid = tonumber(p.uid) or 0,
                name = MenuUI.StripCodes(p.name),
                level = lvl,
                rankIcon = GetRankIcon(lvl, prestige) or "rank_1",
                prestige = prestige,
                self = isSelf,
                talking = talking,
                muted = Voice.muted[v.id] ~= nil,
                rankingIcon = (ranked and GetCorrectRankingImage(p.ranking)) or "",
                ranking = (ranked and tonumber(p.ranking)) or 0,
                winStreak = tonumber(p.winStreak) or 0,
                bestStreak = tonumber(p.bestStreak) or 0,
                callingCard = MenuUI.CallingCardSprite(p.emblem),
                emblem = MenuUI.EmblemSprite(p.logo),
                kills = kills,
                deaths = deaths,
                kd = MenuUI.Ratio(kills, deaths),
                wins = wins,
                wl = MenuUI.Ratio(wins, tonumber(p.losses) or 0),
                squad = v.inGroup == true,
                voted = v.voted == true,
            }
        end
    end

    local vote, selectedMap, timer = nil, nil, 0
    if state == "voting" then
        local function mapInfo(key, votes)
            local m = SharedConfig.Maps[key] or {}
            return { key = tostring(key or ""), name = tostring(m.name or key or ""),
                image = tostring(m.uiImage or m.spritePreview or ""), votes = tonumber(votes) or 0 }
        end
        vote = {
            map1 = mapInfo(data.gameMap1, data.gameMapVote1),
            map2 = mapInfo(data.gameMap2, data.gameMapVote2),
            randomVotes = tonumber(data.gameMapVoteRandom) or 0,
        }
        timer = (tonumber(data.gameWaitingToStartTimer) or 30) - 30
        if timer < 0 then timer = 0 end
    elseif state == "starting" then
        local m = mm.selectedMap or {}
        selectedMap = { name = tostring(m.name or ""), image = tostring(m.uiImage or m.spritePreview or "") }
        timer = tonumber(data.gameWaitingToStartTimer) or 0
    end

    exports['warv-ui']:SetLobbyWait({
        ranked = ranked,
        gamemode = tostring(Lobby.selectedGamemode or ""),
        maxPlayers = tonumber(data.maxPlayer) or 0,
        playersInLobby = tonumber(mm.playersInLobby) or 0,
        players = players,
        myRankingIcon = (ranked and GetCorrectRankingImage(Lobby.playerData.ranking)) or "",
        state = state,
        queuePlace = tonumber(mm.myPlace) or 0,
        queueTotal = tonumber(mm.placeTotal) or 0,
        timer = timer,
        voted = mm.voted == true,
        vote = vote,
        selectedMap = selectedMap,
    })
end

function Lobby.PushMatchLoading()
    exports['warv-ui']:SetMatchLoading(Lobby.GetMatchLoadingWebState())
end

function Lobby.PushGamemodeData()
    local playlists = {}
    for _, gm in ipairs(playable()) do
        local label = tostring(gm.label or gm.name):gsub("~%a~", "")
        local desc = tostring(gm.description or ""):gsub("~%a~", ""):gsub("%-%-", "")
        playlists[#playlists + 1] = {
            name = gm.name,
            label = label,
            description = desc,
            sprite = gm.sprite or "",
            players = (Lobby.playersPerGamemode and Lobby.playersPerGamemode[gm.name]) or 0,
            maxPlayers = tonumber(gm.maxPlayers) or 0,
            ranked = gm.ranked == true,
        }
    end
    exports['warv-ui']:SetGamemodeData({ playlists = playlists })
end

function Lobby.PushCardSelect()
    TriggerServerEvent("warv:GetCallingCardProgress")
end

RegisterNetEvent("warv:CallingCardProgress")
AddEventHandler("warv:CallingCardProgress", function(data)
    data = type(data) == "table" and data or { items = {}, selected = 1 }
    Lobby.playerData.emblemsId = tonumber(data.selected) or 1
    exports['warv-ui']:SetCardSelect(data)
end)

function Lobby.PushEmblemSelect()
    TriggerServerEvent("warv:GetEmblemProgress")
end

RegisterNetEvent("warv:EmblemProgress")
AddEventHandler("warv:EmblemProgress", function(data)
    data = type(data) == "table" and data or { items = {}, selected = 1 }
    local selected = tonumber(data.selected) or 1
    Lobby.playerData.logoId = selected
    Data.playerIcon = selected
    exports['warv-ui']:SetEmblemSelect(data)
end)

function Lobby.PushLeaderboard()
    TriggerServerEvent("warv:GetLeaderboard", Menu.leaderboard)
end

local function decorateEntry(entry)
    entry.rankIcon = GetRankIcon(entry.level, entry.prestige)
    entry.callingCard = MenuUI.CallingCardSprite(entry.cardId)
    entry.emblem = MenuUI.EmblemSprite(entry.logoId)
end

RegisterNetEvent("warv:LeaderboardData")
AddEventHandler("warv:LeaderboardData", function(data)
    data = type(data) == "table" and data or { category = Menu.leaderboard, categories = {}, items = {} }
    Menu.leaderboard = data.category or Menu.leaderboard

    for _, entry in ipairs(data.items or {}) do
        decorateEntry(entry)
    end
    if data.self then decorateEntry(data.self) end

    exports['warv-ui']:SetLeaderboard(data)
end)

function Lobby.PushFriends()
    TriggerServerEvent("warv:GetFriends")
end

function Lobby.PushChallenges()
    TriggerServerEvent("warv:GetChallenges")
end

RegisterNetEvent("warv:ChallengesData")
AddEventHandler("warv:ChallengesData", function(data)
    if type(data) ~= "table" then return end
    exports['warv-ui']:SetChallenges(data)
end)

RegisterNetEvent("warv:FriendsData")
AddEventHandler("warv:FriendsData", function(data)
    if type(data) ~= "table" then return end
    exports['warv-ui']:SetFriends(data)
end)

function Lobby.PushSettingsData()
    local volumes = {}
    for _, key in ipairs(MenuUI.VolOrder) do
        local cfg = MenuUI.Vol[key]
        local cur = tonumber(Settings[cfg.get]) or 0
        local percent = math.floor((cur / cfg.max) * 100 + 0.5)
        if percent > 100 then percent = 100 elseif percent < 0 then percent = 0 end
        volumes[#volumes + 1] = { key = key, label = cfg.label, percent = percent }
    end

    local rankup = {}
    for _, r in ipairs(RankupSounds) do
        rankup[#rankup + 1] = { id = r.sound, label = r.label, selected = (r.sound == Settings.RankupSound) }
    end

    local music = {}
    local currentTheme = tostring(Settings.LobbyTheme or ""):gsub("lobby_music/", "")
    for _, m in ipairs(LobbyMusic) do
        music[#music + 1] = { id = m.link, label = m.label, desc = m.desc, selected = (m.link == currentTheme) }
    end

    exports['warv-ui']:SetSettingsData({ volumes = volumes, rankup = rankup, music = music })
end
