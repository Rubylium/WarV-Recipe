local function reply(source, message, isError)
    if source == 0 then
        print((isError and "^1WARV: " or "^2WARV: ") .. message .. "^7")
        return
    end

    TriggerClientEvent("chat:addMessage", source, {
        color = isError and {255, 80, 80} or {80, 200, 120},
        args = {"WARV", message},
    })
end

local function canUseCommand(source, commandName)
    local requiredLevel = PermissionConfig.commandLevels[commandName]
    if Permissions.Has(source, requiredLevel) then
        return true
    end

    reply(source, "Permission denied", true)
    return false
end

local function getActor(source)
    if source == 0 then
        return {
            source = 0,
            label = "Console",
        }
    end

    local player = Players.Get(source)
    return {
        source = source,
        label = string.format("%s (UID %d)", player.name, player.uid),
    }
end

RegisterCommand("ban", function(source, args)
    source = tonumber(source)
    if not canUseCommand(source, "ban") then
        return
    end

    if args[1] == nil or args[2] == nil or args[3] == nil then
        reply(source, "/ban <uid> <30m|12h|7d|2w|perm> <reason>", true)
        return
    end

    local reason = table.concat(args, " ", 3)
    local success, result = Ban.Create(args[1], args[2], reason, getActor(source))
    if not success then
        reply(source, tostring(result), true)
        return
    end

    reply(source, string.format(
        "Ban #%d - UID %d (%s) - %s",
        result.ban.banid,
        result.ban.uid,
        result.username or "Unknown",
        result.durationLabel
    ))
end, false)

RegisterCommand("kick", function(source, args)
    source = tonumber(source)
    if not canUseCommand(source, "kick") then
        return
    end

    local targetUid = tonumber(args[1])
    if targetUid == nil or args[2] == nil then
        reply(source, "/kick <uid> <reason>", true)
        return
    end

    local targetSource = Players.GetSourceFromUID(targetUid)
    local targetPlayer = targetSource ~= nil and Players.Get(targetSource) or nil
    if targetPlayer == nil then
        reply(source, "Player offline", true)
        return
    end

    if source ~= 0 and Permissions.GetLevel(targetSource) >= Permissions.GetLevel(source) then
        reply(source, "Target rank too high", true)
        return
    end

    local reason = table.concat(args, " ", 2)
    local actor = getActor(source)
    Logger.Log(
        "staff_kick",
        actor.label,
        targetPlayer.name,
        targetSource,
        targetUid,
        Utils.GetPlayersIdentifiersInString(targetSource),
        reason
    )
    DropPlayer(targetSource, "You have been kicked from the server.\nReason: " .. reason)
    reply(source, string.format("Kicked UID %d (%s)", targetUid, targetPlayer.name))
end, false)

RegisterCommand("setwinstreak", function(source, args)
    source = tonumber(source)
    if not Permissions.Has(source, "Owner") then
        return
    end

    local streak = tonumber(args[1])
    if streak == nil then
        reply(source, "/setwinstreak <value> [uid]", true)
        return
    end

    local targetUid = tonumber(args[2])
    local targetSource = targetUid ~= nil and Players.GetSourceFromUID(targetUid) or source
    local targetPlayer = targetSource ~= nil and Players.Get(targetSource) or nil
    if targetPlayer == nil then
        reply(source, "Player offline", true)
        return
    end

    streak = math.max(0, math.floor(streak))
    targetPlayer.stats.winStreak = streak
    targetPlayer.stats.bestWinStreak = math.max(tonumber(targetPlayer.stats.bestWinStreak) or 0, streak)
    Players.RefreshData(targetSource)
    reply(source, ("%s win streak: %d"):format(targetPlayer.name, streak))
end, false)

RegisterCommand("search", function(source, args)
    source = tonumber(source)
    if not canUseCommand(source, "search") then
        return
    end

    if args[1] == nil then
        reply(source, "/search <name>", true)
        return
    end

    local query = string.lower(table.concat(args, " "))
    local matches = {}

    for _, player in pairs(Players.list) do
        if string.find(string.lower(player.name), query, 1, true) ~= nil then
            matches[#matches + 1] = string.format("[%d] %s", player.uid, player.name)
        end
    end

    if #matches == 0 then
        reply(source, "No match")
        return
    end

    table.sort(matches)
    reply(source, "Found: " .. table.concat(matches, ", "))
end, false)

RegisterCommand("off", function(source)
    if tonumber(source) ~= 0 then
        return
    end

    SharedConfig.allowConnexion = false
    for _, playerSource in pairs(GetPlayers()) do
        Players.RemoveFromCache(tonumber(playerSource))
        DropPlayer(playerSource, "For technical reasons, the WarV game servers are currently waiting for restart. Please be patient.")
        Wait(300)
    end
end, false)
