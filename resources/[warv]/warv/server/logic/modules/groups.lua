Groups = {}
Groups.list = {}
Groups.byPlayer = {}
Groups.invites = {}

local maxPlayers = 5
local inviteTtl = 60000

local function notify(source, message, title)
    TriggerClientEvent("Groups:DisplayPopupMessage", source, message, title or "SQUAD")
end

local function removeInvite(inviteId)
    local invite = Groups.invites[inviteId]
    if invite == nil then return nil end

    Groups.invites[inviteId] = nil
    if Players.DoesPlayerExist(invite.target) then
        TriggerClientEvent("groups:RemoveInvite", invite.target, inviteId)
    end
    return invite
end

local function clearInvitesForTarget(target)
    local removed = false
    for inviteId, invite in pairs(Groups.invites) do
        if invite.target == target then
            Groups.invites[inviteId] = nil
            removed = true
        end
    end

    if removed and Players.DoesPlayerExist(target) then
        TriggerClientEvent("groups:ClearInvites", target)
    end
end

local function formatPlayers(group)
    local players = {}
    for _, member in ipairs(group.players) do
        players[#players + 1] = {
            id = member,
            name = Players.GetName(member),
            level = Players.GetLevel(member),
            prestige = Players.GetPrestige(member),
            perms = Players.GetPerms(member),
        }
    end
    return players
end

local function refresh(group)
    local players = formatPlayers(group)
    for _, member in ipairs(group.players) do
        TriggerClientEvent("groups:RefreshGroupData", member, group.host == member, players)
    end
end

local function playSound(group, event)
    for _, member in ipairs(group.players) do
        TriggerClientEvent(event, member)
    end
end

local function detach(source)
    Groups.byPlayer[source] = nil
    TriggerClientEvent("groups:RefreshGroupData", source, false, {})
    TriggerClientEvent("groups:PlayLeaveSound", source)
end

local function disband(group)
    Groups.list[group.id] = nil
    for _, member in ipairs(group.players) do
        detach(member)
    end
end

function Groups.Get(source)
    local groupId = Groups.byPlayer[source]
    return groupId and Groups.list[groupId] or nil
end

function Groups.GetPlayerGroup(source)
    return Groups.byPlayer[source]
end

function Groups.IsPlayerInAnyGroup(source)
    return Groups.Get(source) ~= nil
end

function Groups.IsPlayerHostOfAnyGroup(source)
    local group = Groups.Get(source)
    return group ~= nil and group.host == source
end

function Groups.GetPlayersInGroup(groupId)
    local group = Groups.list[groupId]
    return group and copy(group.players) or {}
end

function Groups.Notify(source, message, title)
    notify(source, message, title)
end

function Groups.GetLeaderActionPlayers(source, action)
    local group = Groups.Get(source)
    if group == nil then
        return {source}
    end

    if group.host ~= source then
        notify(source, "Only the squad leader can " .. (action or "do that") .. ".", "SQUAD LEADER REQUIRED")
        return nil
    end

    return copy(group.players)
end

function Groups.Create(host)
    local groupId = GenerateUuid()
    Groups.list[groupId] = { id = groupId, host = host, players = { host } }
    Groups.byPlayer[host] = groupId
    clearInvitesForTarget(host)
    return groupId
end

function Groups.Join(groupId, source)
    local group = Groups.list[groupId]
    if group == nil or Groups.byPlayer[source] ~= nil or #group.players >= maxPlayers then
        return false
    end

    group.players[#group.players + 1] = source
    Groups.byPlayer[source] = groupId
    clearInvitesForTarget(source)
    playSound(group, "groups:PlayJoinSound")
    refresh(group)
    return true
end

function Groups.Leave(groupId, source)
    local group = Groups.list[groupId]
    if group == nil or Groups.byPlayer[source] ~= groupId then
        return false
    end

    Matchmaking.LeaveMatchmaking(source, true)

    if group.host == source then
        disband(group)
        return true
    end

    for index = #group.players, 1, -1 do
        if group.players[index] == source then
            table.remove(group.players, index)
            break
        end
    end
    detach(source)

    if #group.players <= 1 then
        disband(group)
    else
        refresh(group)
        playSound(group, "groups:PlayLeaveSound")
    end

    return true
end

local function sendInvite(target, inviteId, source, sourceUid)
    TriggerClientEvent("groups:SendInvite", target, {
        inviteId = inviteId,
        uid = sourceUid or 0,
        name = Players.GetName(source),
        level = Players.GetLevel(source),
        prestige = Players.GetPrestige(source),
    })
end

RegisterNetEvent("groups:SendInviteToPlayer", function(uid)
    local source = source
    local target = Players.GetPlayerFromUID(uid)

    if target == nil or not Players.DoesPlayerExist(target) then
        notify(source, "Player not found.")
        return
    end

    if target == source then
        notify(source, "You can't invite yourself")
        return
    end

    local targetUid = tonumber(Players.GetPlayerUid(target))
    local sourceUid = tonumber(Players.GetPlayerUid(source))
    if targetUid ~= nil and sourceUid ~= nil and Friends.IsBlocked(targetUid, sourceUid) then
        notify(source, "Player not found.")
        return
    end

    if Groups.IsPlayerInAnyGroup(target) then
        notify(source, "Player is already in a group.")
        return
    end

    local group = Groups.Get(source)
    if group ~= nil then
        if group.host ~= source then
            notify(source, "You are not the host of this group.")
            return
        end

        if #group.players >= maxPlayers then
            notify(source, "Your group is full.")
            return
        end
    end

    for pendingId, pendingInvite in pairs(Groups.invites) do
        if pendingInvite.host == source and pendingInvite.target == target then
            pendingInvite.expiresAt = GetGameTimer() + inviteTtl
            sendInvite(target, pendingId, source, sourceUid)
            notify(source, "Invite already pending.")
            return
        end
    end

    local inviteId = GenerateUuid()
    Groups.invites[inviteId] = {
        host = source,
        target = target,
        expiresAt = GetGameTimer() + inviteTtl,
    }

    sendInvite(target, inviteId, source, sourceUid)
    notify(source, "Player invited")
end)

RegisterNetEvent("groups:AcceptInvite", function(inviteId)
    local source = source
    local invite = Groups.invites[inviteId]
    if invite == nil or invite.target ~= source then return end

    removeInvite(inviteId)

    if not Players.DoesPlayerExist(invite.host) then
        notify(source, "Player not found.")
        return
    end

    if Groups.IsPlayerInAnyGroup(source) then
        notify(source, "You are already in a group.")
        return
    end

    local group = Groups.Get(invite.host)
    if group ~= nil and group.host ~= invite.host then
        notify(source, "This group is no longer available.")
        return
    end

    if not Groups.Join(group and group.id or Groups.Create(invite.host), source) then
        notify(source, "This group is full.")
    end
end)

RegisterNetEvent("groups:RefuseInvite", function(inviteId)
    local source = source
    local invite = Groups.invites[inviteId]
    if invite == nil or invite.target ~= source then return end

    removeInvite(inviteId)
    notify(invite.host, "Invite declined.")
end)

RegisterNetEvent("groups:KickPlayer", function(playerId)
    local source = source
    local group = Groups.Get(source)
    if group == nil then return end

    if group.host ~= source then
        notify(source, "You are not the host of this group.")
        return
    end

    local target = tonumber(playerId)
    if target == nil or target == source or Groups.byPlayer[target] ~= group.id then
        notify(source, "Player is not in your group.")
        return
    end

    Groups.Leave(group.id, target)
    notify(source, "Player kicked")
    notify(target, "You got kicked out of the group.")
end)

RegisterNetEvent("groups:Leave", function()
    local source = source
    local group = Groups.Get(source)
    if group == nil then
        notify(source, "You are not in any group.")
        return
    end

    Groups.Leave(group.id, source)
    notify(source, "You left the group.")
end)

Citizen.CreateThread(function()
    while true do
        Wait(1000)

        local now = GetGameTimer()
        for inviteId, invite in pairs(Groups.invites) do
            if now > invite.expiresAt
                or not Players.DoesPlayerExist(invite.host)
                or not Players.DoesPlayerExist(invite.target) then
                removeInvite(inviteId)
            end
        end

        for groupId, group in pairs(Groups.list) do
            for index = #group.players, 1, -1 do
                if not Players.DoesPlayerExist(group.players[index]) then
                    Groups.Leave(groupId, group.players[index])
                end
            end
        end
    end
end)
