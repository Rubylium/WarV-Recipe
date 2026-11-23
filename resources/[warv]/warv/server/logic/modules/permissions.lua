Permissions = {}

local roleLevelsByName = {}

local function normalizeLevel(level)
    local numericLevel = tonumber(level)
    if numericLevel == nil or numericLevel < 0 or numericLevel % 1 ~= 0 then
        return nil
    end

    numericLevel = math.floor(numericLevel)
    if PermissionConfig.roles[numericLevel] == nil then
        return nil
    end

    return numericLevel
end

for level, role in pairs(PermissionConfig.roles) do
    roleLevelsByName[string.lower(role.name)] = level
end

function Permissions.ResolveLevel(requiredLevel)
    if type(requiredLevel) == "string" then
        local configuredLevel = roleLevelsByName[string.lower(requiredLevel)]
        if configuredLevel ~= nil then
            return configuredLevel
        end
    end

    return normalizeLevel(requiredLevel)
end

function Permissions.GetLevel(source)
    local player = Players.Get(source)
    if player == nil then
        return PermissionConfig.defaultLevel
    end

    return tonumber(player.permissionLevel or player.perm) or PermissionConfig.defaultLevel
end

function Permissions.Has(source, requiredLevel)
    if source == 0 then
        return true
    end

    local resolvedLevel = Permissions.ResolveLevel(requiredLevel)
    if resolvedLevel == nil then
        return false
    end

    return Permissions.GetLevel(source) >= resolvedLevel
end

function Permissions.SetByUid(uid, level)
    local numericUid = tonumber(uid)
    local normalizedLevel = normalizeLevel(level)

    if numericUid == nil or numericUid < 1 or numericUid % 1 ~= 0 then
        return false, "Invalid UID"
    end

    if normalizedLevel == nil then
        return false, "Unknown level"
    end

    local userSuccess, user, userError = Db.Single(
        "SELECT `id`, `username` FROM `users` WHERE `id` = ? LIMIT 1",
        {numericUid}
    )
    if not userSuccess then
        return false, userError or "User lookup failed"
    end
    if user == nil then
        return false, "Unknown UID"
    end

    local updateSuccess, _, updateError = Db.Update(
        "UPDATE `users` SET `permissionLevel` = ? WHERE `id` = ?",
        {normalizedLevel, numericUid}
    )
    if not updateSuccess then
        return false, updateError or "Update failed"
    end

    local targetSource = Players.GetSourceFromUID(numericUid)
    local targetPlayer = targetSource ~= nil and Players.Get(targetSource) or nil
    if targetPlayer ~= nil then
        targetPlayer.permissionLevel = normalizedLevel
        targetPlayer.perm = normalizedLevel
        Players.RefreshData(targetSource)
    end

    return true, {
        uid = numericUid,
        username = user.username,
        level = normalizedLevel,
        role = PermissionConfig.roles[normalizedLevel],
    }
end

RegisterCommand("setpermission", function(source, args)
    if source ~= 0 then
        return
    end

    if args[1] == nil or args[2] == nil then
        print("setpermission <uid> <level>")
        return
    end

    local success, result = Permissions.SetByUid(args[1], args[2])
    if not success then
        print("^1WARV: " .. tostring(result) .. "^7")
        return
    end

    print(string.format(
        "^2WARV: UID %d (%s) - level %d (%s)^7",
        result.uid,
        result.username or "Unknown",
        result.level,
        result.role.name
    ))
end, false)

exports("HasPermission", function(source, requiredLevel)
    return Permissions.Has(tonumber(source), requiredLevel)
end)

exports("GetPermissionLevel", function(source)
    return Permissions.GetLevel(tonumber(source))
end)
