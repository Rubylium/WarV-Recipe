Friends = {}
Friends.relations = {}
Friends.profiles = {}
Friends.hidden = {}

local maxFriends = 100
local pushMs = 5000

local signatures = {}

local function emptyRelations()
    return { friends = {}, incoming = {}, outgoing = {}, blocked = {}, blockedBy = {} }
end

local function readSettings(uid)
    local ok, rows = Db.Query("SELECT settings FROM users WHERE id = ?", { uid })
    if not ok or rows == nil or rows[1] == nil or rows[1].settings == nil then
        return {}
    end

    local decoded, result = pcall(json.decode, rows[1].settings)
    return decoded and type(result) == "table" and result or {}
end

local function relationsOf(uid)
    if Friends.relations[uid] == nil then
        Friends.relations[uid] = emptyRelations()
    end
    return Friends.relations[uid]
end

local function count(set)
    local total = 0
    for _ in pairs(set) do total = total + 1 end
    return total
end

local function cacheProfiles(uids)
    if #uids == 0 then return end

    local ok, rows = Db.Query(([[
        SELECT w.uid, COALESCE(NULLIF(u.username, ''), CONCAT('Operator #', w.uid)) AS name,
               w.level, w.prestige
        FROM warv w
        INNER JOIN users u ON u.id = w.uid
        WHERE w.uid IN (%s)
    ]]):format(table.concat(uids, ",")))

    if not ok or type(rows) ~= "table" then return end

    for _, row in ipairs(rows) do
        Friends.profiles[tonumber(row.uid)] = {
            name = tostring(row.name or ""),
            level = tonumber(row.level) or 1,
            prestige = tonumber(row.prestige) or 0,
        }
    end
end

function Friends.Load(uid)
    local relations = emptyRelations()
    local ok, rows = Db.Query(
        "SELECT requester, target, status FROM warv_friends WHERE requester = ? OR target = ?",
        { uid, uid }
    )

    local related = {}
    if ok and type(rows) == "table" then
        for _, row in ipairs(rows) do
            local requester = tonumber(row.requester)
            local target = tonumber(row.target)
            local other = requester == uid and target or requester
            related[#related + 1] = other

            if row.status == "accepted" then
                relations.friends[other] = true
            elseif row.status == "blocked" then
                if requester == uid then
                    relations.blocked[other] = true
                else
                    relations.blockedBy[other] = true
                end
            elseif requester == uid then
                relations.outgoing[other] = true
            else
                relations.incoming[other] = true
            end
        end
    end

    Friends.relations[uid] = relations
    cacheProfiles(related)

    Friends.hidden[uid] = readSettings(uid).hideOnline == true
    return relations
end

function Friends.Unload(uid)
    Friends.relations[uid] = nil
    Friends.hidden[uid] = nil
end

function Friends.IsBlocked(uid, otherUid)
    local relations = Friends.relations[uid]
    return relations ~= nil and relations.blocked[otherUid] == true
end

local function presenceOf(uid, viewerSource)
    if Friends.hidden[uid] then return { state = "offline" } end

    local source = PlayerSessions.GetSourceByUid(uid)
    if source == nil or not Players.DoesPlayerExist(source) then
        return { state = "offline" }
    end

    if Matchmaking.IsPlayerInMatchmaking(source) then
        return { state = "queue" }
    end

    local gameId = Players.GetPlayerCurrentLobby(source)
    if gameId ~= 0 then
        local game = Game.GetGameFromGameId(gameId)
        if game ~= nil then
            local joinable = Game.CanPlayerJoinGame(gameId, { viewerSource })
            return {
                state = "match",
                detail = tostring(game.gamemode or ""),
                joinable = joinable == true and not Groups.IsPlayerInAnyGroup(viewerSource),
                gameId = gameId,
            }
        end
    end

    return { state = "lobby" }
end

local function entryOf(uid, presence)
    local profile = Friends.profiles[uid] or {}
    return {
        uid = uid,
        name = profile.name or ("Operator #" .. uid),
        level = profile.level or 1,
        prestige = profile.prestige or 0,
        state = presence and presence.state or "offline",
        detail = presence and presence.detail or nil,
        joinable = presence and presence.joinable == true,
        gameId = presence and presence.gameId or nil,
    }
end

local function nameBefore(a, b)
    local aName = tostring(a.name or ""):lower()
    local bName = tostring(b.name or ""):lower()
    if aName ~= bName then
        return aName < bName
    end
    return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
end

local function friendBefore(a, b)
    local aConnected = a.state ~= "offline"
    local bConnected = b.state ~= "offline"
    if aConnected ~= bConnected then
        return aConnected
    end
    return nameBefore(a, b)
end

function Friends.BuildPayload(source)
    local uid = tonumber(Players.GetPlayerUid(source))
    if uid == nil then return nil end

    local relations = relationsOf(uid)
    local friends = {}
    for other in pairs(relations.friends) do
        friends[#friends + 1] = entryOf(other, presenceOf(other, source))
    end

    table.sort(friends, friendBefore)

    local incoming = {}
    for other in pairs(relations.incoming) do
        incoming[#incoming + 1] = entryOf(other, nil)
    end
    table.sort(incoming, nameBefore)

    local outgoing = {}
    for other in pairs(relations.outgoing) do
        outgoing[#outgoing + 1] = entryOf(other, nil)
    end
    table.sort(outgoing, nameBefore)

    local blocked = {}
    for other in pairs(relations.blocked) do
        blocked[#blocked + 1] = entryOf(other, nil)
    end
    table.sort(blocked, nameBefore)

    return {
        friends = friends,
        incoming = incoming,
        outgoing = outgoing,
        blocked = blocked,
        hidden = Friends.hidden[uid] == true,
        cap = maxFriends,
    }
end

local function signature(payload)
    local parts = {}
    for _, entry in ipairs(payload.friends) do
        parts[#parts + 1] = entry.uid .. entry.state .. tostring(entry.joinable)
    end
    parts[#parts + 1] = #payload.incoming .. ":" .. #payload.outgoing .. ":" .. #payload.blocked
    parts[#parts + 1] = tostring(payload.hidden)
    return table.concat(parts, "|")
end

local function push(source, payload)
    signatures[source] = signature(payload)
    TriggerClientEvent("warv:FriendsData", source, payload)
end

function Friends.Send(source)
    if not Players.DoesPlayerExist(source) then return end

    local payload = Friends.BuildPayload(source)
    if payload ~= nil then
        push(source, payload)
    end
end

local function sendToUid(uid)
    local source = PlayerSessions.GetSourceByUid(uid)
    if source ~= nil then Friends.Send(source) end
end

local function pairExists(uid, otherUid)
    local relations = relationsOf(uid)
    return relations.friends[otherUid] or relations.incoming[otherUid]
        or relations.outgoing[otherUid] or relations.blocked[otherUid]
        or relations.blockedBy[otherUid]
end

local function clearPair(uid, otherUid)
    for _, side in ipairs({ uid, otherUid }) do
        local relations = Friends.relations[side]
        if relations ~= nil then
            local other = side == uid and otherUid or uid
            relations.friends[other] = nil
            relations.incoming[other] = nil
            relations.outgoing[other] = nil
            relations.blocked[other] = nil
            relations.blockedBy[other] = nil
        end
    end

    Db.Update(
        "DELETE FROM warv_friends WHERE (requester = ? AND target = ?) OR (requester = ? AND target = ?)",
        { uid, otherUid, otherUid, uid }
    )
end

local function notify(source, message)
    TriggerClientEvent("Groups:DisplayPopupMessage", source, message)
end

RegisterNetEvent("warv:GetFriends", function()
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    if uid ~= nil and Friends.relations[uid] == nil then
        Friends.Load(uid)
    end
    Friends.Send(source)
end)

RegisterNetEvent("warv:AddFriend", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil or other == uid then return end

    if pairExists(uid, other) then
        notify(source, "Already on your list.")
        return
    end

    if count(relationsOf(uid).friends) >= maxFriends then
        notify(source, "Your friend list is full.")
        return
    end

    local ok, rows = Db.Query("SELECT id FROM users WHERE id = ?", { other })
    if not ok or rows == nil or rows[1] == nil then
        notify(source, "Player not found.")
        return
    end

    Db.Insert(
        "INSERT INTO warv_friends (requester, target, status) VALUES (?, ?, 'pending')",
        { uid, other }
    )

    relationsOf(uid).outgoing[other] = true
    if Friends.relations[other] then Friends.relations[other].incoming[uid] = true end
    cacheProfiles({ uid, other })

    notify(source, "Friend request sent.")
    Friends.Send(source)
    sendToUid(other)
end)

RegisterNetEvent("warv:AcceptFriend", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil or not relationsOf(uid).incoming[other] then return end

    if count(relationsOf(uid).friends) >= maxFriends then
        notify(source, "Your friend list is full.")
        return
    end

    Db.Update(
        "UPDATE warv_friends SET status = 'accepted' WHERE requester = ? AND target = ? AND status = 'pending'",
        { other, uid }
    )

    Friends.relations[uid].incoming[other] = nil
    Friends.relations[uid].friends[other] = true
    if Friends.relations[other] then
        Friends.relations[other].outgoing[uid] = nil
        Friends.relations[other].friends[uid] = true
    end

    Friends.Send(source)
    sendToUid(other)
end)

RegisterNetEvent("warv:DeclineFriend", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil then return end

    clearPair(uid, other)
    Friends.Send(source)
    sendToUid(other)
end)

RegisterNetEvent("warv:BlockPlayer", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil or other == uid then return end

    clearPair(uid, other)
    Db.Insert(
        "INSERT INTO warv_friends (requester, target, status) VALUES (?, ?, 'blocked')",
        { uid, other }
    )

    relationsOf(uid).blocked[other] = true
    if Friends.relations[other] then Friends.relations[other].blockedBy[uid] = true end
    cacheProfiles({ other })

    notify(source, "Player blocked.")
    Friends.Send(source)
    sendToUid(other)
end)

RegisterNetEvent("warv:UnblockPlayer", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil then return end

    clearPair(uid, other)
    Friends.Send(source)
    sendToUid(other)
end)

RegisterNetEvent("warv:SetAppearOffline", function(hidden)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    if uid == nil then return end

    Friends.hidden[uid] = hidden == true

    local settings = readSettings(uid)
    settings.hideOnline = Friends.hidden[uid]
    Db.Update("UPDATE users SET settings = ? WHERE id = ?", { json.encode(settings), uid })

    Friends.Send(source)
end)

RegisterNetEvent("warv:JoinFriend", function(targetUid)
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    local other = tonumber(targetUid)
    if uid == nil or other == nil or not relationsOf(uid).friends[other] then return end

    if Groups.IsPlayerInAnyGroup(source) then
        notify(source, "Leave your group first, joining a friend is solo only.")
        return
    end

    local presence = presenceOf(other, source)
    if presence.state ~= "match" or not presence.joinable then
        notify(source, "You can't join this player right now.")
        return
    end

    local canJoin, alreadyStarted = Game.CanPlayerJoinGame(presence.gameId, { source })
    if not canJoin or not Game.AddPlayerToGame(presence.gameId, { source }, alreadyStarted) then
        notify(source, "You can't join this player right now.")
        return
    end

    local game = Game.GetGameFromGameId(presence.gameId)
    if game ~= nil then
        TriggerClientEvent("browser:CloseBrowserAfterJoining", source, game.gamemode)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(pushMs)

        for playerSource in pairs(Players.list) do
            local payload = Friends.BuildPayload(playerSource)
            if payload ~= nil and #payload.friends > 0 and signature(payload) ~= signatures[playerSource] then
                push(playerSource, payload)
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    signatures[source] = nil
end)
