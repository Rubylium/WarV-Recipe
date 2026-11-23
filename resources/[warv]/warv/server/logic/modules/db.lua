Db = {}

Db.shuttingDown = false

local queryTimeout = 15000

local function await(method, query, parameters)
    local p = promise.new()
    local done = false

    local function finish(ok, result, err)
        if not done then
            done = true
            p:resolve({ok, result, err})
        end
    end

    SetTimeout(queryTimeout, function()
        finish(false, nil, method .. " timeout")
    end)

    local ok, err = pcall(function()
        exports.oxmysql[method](exports.oxmysql, query, parameters or {}, function(result)
            finish(true, result)
        end)
    end)
    if not ok then
        finish(false, nil, tostring(err))
    end

    local r = Citizen.Await(p)
    return r[1], r[2], r[3]
end

function Db.Query(query, parameters)
    return await("query", query, parameters)
end

function Db.Single(query, parameters)
    return await("single", query, parameters)
end

function Db.Insert(query, parameters)
    local success, result, errorMessage = await("insert", query, parameters)
    if success and result == nil then
        return false, nil, "insert: no result"
    end

    return success, result, errorMessage
end

function Db.Update(query, parameters)
    if Db.shuttingDown then
        local ok, err = pcall(function()
            exports.oxmysql:update(query, parameters or {})
        end)
        if not ok then
            return false, nil, tostring(err)
        end
        return true, 1, nil
    end

    local success, result, errorMessage = await("update", query, parameters)
    if success and result == nil then
        return false, nil, "update: no result"
    end

    return success, result, errorMessage
end

local function SyncTokens(uid, tokens)
    local values = {}
    local parameters = {}

    for _, token in ipairs(tokens) do
        if string.sub(token, 1, 1) ~= "1" then
            values[#values + 1] = "(?, ?)"
            parameters[#parameters + 1] = uid
            parameters[#parameters + 1] = token
        end
    end

    if #values == 0 then
        return true
    end

    local success, _, errorMessage = Db.Update(
        "INSERT IGNORE INTO `identifiers` (`UID`, `Identifier`) VALUES " .. table.concat(values, ", "),
        parameters
    )

    return success, errorMessage
end

function Db.LoadOrCreate(identity, username)
    local selectUserQuery = "SELECT * FROM `users` WHERE `identifier` = ? LIMIT 1"
    local success, existingUser, errorMessage = Db.Single(selectUserQuery, {identity.license})
    if not success then
        return nil, false, errorMessage
    end

    local created = existingUser == nil
    local insertSuccess, _, insertError = Db.Insert([[
        INSERT INTO `users` (`username`, `identifier`, `discord`, `fivem`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `id` = LAST_INSERT_ID(`id`),
            `username` = VALUES(`username`),
            `discord` = COALESCE(VALUES(`discord`), `discord`),
            `fivem` = COALESCE(VALUES(`fivem`), `fivem`)
    ]], {
        username or "Unknown",
        identity.license,
        identity.discord or "none",
        identity.fivem or "none",
    })

    if not insertSuccess then
        return nil, false, insertError
    end

    local userSuccess, userData, userError = Db.Single(selectUserQuery, {identity.license})
    if not userSuccess or userData == nil then
        return nil, false, userError or "user not found"
    end

    local profileSuccess, _, profileError = Db.Update([[
        INSERT INTO `warv` (`uid`, `weaponStats`, `unlockedContent`)
        VALUES (?, '{}', '{}')
        ON DUPLICATE KEY UPDATE `uid` = VALUES(`uid`)
    ]], {userData.id})

    if not profileSuccess then
        return nil, false, profileError
    end

    local tokensSuccess, tokensError = SyncTokens(userData.id, identity.tokens)
    if not tokensSuccess then
        WarningPrint("Token sync UID [" .. userData.id .. "]: " .. tostring(tokensError))
    end

    return userData, created
end

function Db.LoadProfile(uid)
    local success, gameData, errorMessage = Db.Single(
        "SELECT * FROM `warv` WHERE `uid` = ? LIMIT 1",
        {uid}
    )

    if not success or gameData == nil then
        return nil, errorMessage or "profile not found"
    end

    return gameData
end

function Db.Save(player)
    local parameters = {
        player.uid,
        player.credit,
        player.emblemsId,
        player.logoId,
        player.kill,
        player.assist,
        player.death,
        player.score,
        player.xp,
        player.level,
        player.prestige,
        player.ranking,
        json.encode(player.class),
        json.encode(player.weaponsStats),
        json.encode(player.unlockedContent),
        json.encode(player.stats),
    }

    local success, _, errorMessage = Db.Update([[
        INSERT INTO `warv` (
            `uid`, `credit`, `emblemsId`, `logoId`, `kill`, `assist`, `death`, `score`,
            `xp`, `level`, `prestige`, `ranking`, `class`, `weaponStats`,
            `unlockedContent`, `stats`
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `credit` = VALUES(`credit`),
            `emblemsId` = VALUES(`emblemsId`),
            `logoId` = VALUES(`logoId`),
            `kill` = VALUES(`kill`),
            `assist` = VALUES(`assist`),
            `death` = VALUES(`death`),
            `score` = VALUES(`score`),
            `xp` = VALUES(`xp`),
            `level` = VALUES(`level`),
            `prestige` = VALUES(`prestige`),
            `ranking` = VALUES(`ranking`),
            `class` = VALUES(`class`),
            `weaponStats` = VALUES(`weaponStats`),
            `unlockedContent` = VALUES(`unlockedContent`),
            `stats` = VALUES(`stats`)
    ]], parameters)

    return success, errorMessage
end
