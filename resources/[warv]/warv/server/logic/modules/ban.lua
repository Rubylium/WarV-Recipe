Ban = {}

local function findActiveBan(uid)
    local success, ban, errorMessage = Db.Single([[
        SELECT `banid`, `uid`, `staffmember`, `reason`, `banstart`, `banend`
        FROM `bans`
        WHERE `uid` = ?
          AND `unbanned` = 0
          AND (`banend` IS NULL OR `banend` > ?)
        ORDER BY `banid` DESC
        LIMIT 1
    ]], {
        uid,
        os.time(),
    })

    return success, ban, errorMessage
end

local function findBanUser(uid)
    return Db.Single(
        "SELECT `id`, `username`, `permissionLevel` FROM `users` WHERE `id` = ? LIMIT 1",
        {uid}
    )
end

local function createBan(uid, staffMember, reason, banStart, banEnd)
    if banEnd == nil then
        return Db.Insert([[
            INSERT INTO `bans` (`uid`, `staffmember`, `reason`, `banstart`, `banend`)
            VALUES (?, ?, ?, ?, NULL)
        ]], {
            uid,
            staffMember,
            reason,
            banStart,
        })
    end

    return Db.Insert([[
        INSERT INTO `bans` (`uid`, `staffmember`, `reason`, `banstart`, `banend`)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        uid,
        staffMember,
        reason,
        banStart,
        banEnd,
    })
end

Ban.type = {
    [1] = {
        label = "Permanent ban",
        desc = "This account has been permanently banned from WarV servers.",
    },
    [2] = {
        label = "Analytic ban",
        desc = "This account has been suspended after automated gameplay analysis.",
    },
    [3] = {
        label = "Staff removal",
        desc = "You have been removed from WarV game servers for your behavior. Please respect the rules.",
    },
}

local durationUnits = {
    m = 60,
    h = 60 * 60,
    d = 24 * 60 * 60,
    w = 7 * 24 * 60 * 60,
}

local function pluralize(value, singular)
    if value == 1 then
        return value .. " " .. singular
    end

    return value .. " " .. singular .. "s"
end

function Ban.ParseDuration(value)
    if value == nil then
        return nil, nil, "Duration missing"
    end

    local normalizedValue = string.lower(tostring(value))
    if normalizedValue == "perm" or normalizedValue == "permanent" then
        return nil, "permanent"
    end

    local amount, unit = string.match(normalizedValue, "^(%d+)([mhdw])$")
    if amount == nil then
        amount = string.match(normalizedValue, "^(%d+)$")
        unit = "h"
    end

    amount = tonumber(amount)
    if amount == nil or amount < 1 then
        return nil, nil, "Duration: perm, 30m, 12h, 7d, 2w"
    end

    local seconds = amount * durationUnits[unit]
    local labels = {
        m = "minute",
        h = "hour",
        d = "day",
        w = "week",
    }

    return seconds, pluralize(amount, labels[unit])
end

function Ban.FormatMessage(ban)
    local header
    if ban.banend == nil then
        header = "You are permanently banned from this server."
    else
        local secondsLeft = math.max(0, tonumber(ban.banend) - os.time())
        local days = math.floor(secondsLeft / 86400)
        local hours = math.floor((secondsLeft % 86400) / 3600)
        local minutes = math.floor((secondsLeft % 3600) / 60)
        header = string.format(
            "You are banned from this server for %d day(s), %d hour(s), and %d minute(s).",
            days,
            hours,
            minutes
        )
    end

    return string.format(
        "\n%s\nBan ID: %s\nReason: %s\nBanned by: %s\nAppeal: https://discord.gg/warv",
        header,
        tostring(ban.banid),
        tostring(ban.reason),
        tostring(ban.staffmember)
    )
end

function Ban.FindActiveByUid(uid)
    return findActiveBan(tonumber(uid))
end

function Ban.Create(targetUid, duration, reason, actor)
    local numericUid = tonumber(targetUid)
    if numericUid == nil or numericUid < 1 or numericUid % 1 ~= 0 then
        return false, "Invalid UID"
    end

    reason = tostring(reason or "")
    reason = string.match(reason, "^%s*(.-)%s*$")
    if reason == "" then
        return false, "Reason missing"
    end
    if #reason > 500 then
        return false, "Reason too long (500 max)"
    end

    local durationSeconds, durationLabel, durationError = Ban.ParseDuration(duration)
    if durationError ~= nil then
        return false, durationError
    end

    local userSuccess, targetUser, userError = findBanUser(numericUid)
    if not userSuccess then
        return false, userError or "User lookup failed"
    end
    if targetUser == nil then
        return false, "Unknown UID"
    end

    local existingSuccess, existingBan, existingError = findActiveBan(numericUid)
    if not existingSuccess then
        return false, existingError or "Ban lookup failed"
    end
    if existingBan ~= nil then
        return false, "Already banned (ID " .. existingBan.banid .. ")"
    end

    if actor.source ~= 0 then
        local actorLevel = Permissions.GetLevel(actor.source)
        local targetLevel = tonumber(targetUser.permissionLevel) or PermissionConfig.defaultLevel
        if targetLevel >= actorLevel then
            return false, "Target rank too high"
        end
    end

    local banStart = os.time()
    local banEnd = durationSeconds ~= nil and banStart + durationSeconds or nil
    local insertSuccess, banId, insertError = createBan(
        numericUid,
        actor.label,
        reason,
        banStart,
        banEnd
    )
    if not insertSuccess then
        return false, insertError or "Ban insert failed"
    end

    local targetSource = Players.GetSourceFromUID(numericUid)
    local targetPlayer = targetSource ~= nil and Players.Get(targetSource) or nil

    Logger.Log(
        "staff_ban",
        actor.label,
        targetPlayer and targetPlayer.name or targetUser.username or "Offline user",
        targetSource or "offline",
        numericUid,
        targetSource and Utils.GetPlayersIdentifiersInString(targetSource) or "Unavailable (offline)",
        reason
    )

    local ban = {
        banid = banId,
        uid = numericUid,
        staffmember = actor.label,
        reason = reason,
        banstart = banStart,
        banend = banEnd,
    }

    if targetSource ~= nil then
        DropPlayer(targetSource, Ban.FormatMessage(ban))
    end

    return true, {
        ban = ban,
        durationLabel = durationLabel,
        username = targetUser.username,
    }
end

exports("Ban", function()
    return Ban
end)
