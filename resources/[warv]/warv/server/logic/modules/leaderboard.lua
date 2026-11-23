Leaderboard = {}

local limit = 100
local cacheMs = 60000

local categories = {
    { id = "kills", label = "Kills", value = "w.`kill`" },
    { id = "wins", label = "Wins", value = "COALESCE(CAST(JSON_EXTRACT(w.`stats`, '$.win') AS UNSIGNED), 0)" },
    { id = "score", label = "Score", value = "w.`score`" },
    {
        id = "kd",
        label = "K/D",
        value = "w.`kill` / GREATEST(w.`death`, 1)",
        decimals = 2,
        filter = "w.`kill` + w.`death` >= 50",
    },
    { id = "level", label = "Level", value = "w.`level`", order = "w.`prestige` * 100 + w.`level`" },
    { id = "ranked", label = "Ranked", value = "w.`ranking`", filter = "w.`ranking` > 0" },
    { id = "headshots", label = "Headshots", value = "COALESCE(CAST(JSON_EXTRACT(w.`stats`, '$.headshot') AS UNSIGNED), 0)" },
    { id = "nukes", label = "Nukes", value = "COALESCE(CAST(JSON_EXTRACT(w.`stats`, '$.nukes') AS UNSIGNED), 0)" },
}

local cache = {}

local function getCategory(id)
    for _, category in ipairs(categories) do
        if category.id == id then return category end
    end
    return categories[1]
end

local function orderOf(category)
    return category.order or category.value
end

local function whereOf(category, extra)
    local clauses = {}
    if category.filter then clauses[#clauses + 1] = category.filter end
    if extra then clauses[#clauses + 1] = extra end
    if #clauses == 0 then return "" end
    return " WHERE " .. table.concat(clauses, " AND ")
end

local function categoryList()
    local list = {}
    for _, category in ipairs(categories) do
        list[#list + 1] = { id = category.id, label = category.label, decimals = category.decimals or 0 }
    end
    return list
end

local function fetchTop(category)
    local cached = cache[category.id]
    if cached ~= nil and GetGameTimer() < cached.expiresAt then
        return cached.items
    end

    local query = ([[
        SELECT w.uid, COALESCE(NULLIF(u.username, ''), CONCAT('Operator #', w.uid)) AS name,
               w.level, w.prestige, w.logoId, w.emblemsId, %s AS value
        FROM warv w
        INNER JOIN users u ON u.id = w.uid%s
        ORDER BY %s DESC, w.uid ASC
        LIMIT %d
    ]]):format(category.value, whereOf(category), orderOf(category), limit)

    local ok, rows = Db.Query(query)
    if not ok or type(rows) ~= "table" then
        return cached and cached.items or {}
    end

    local items = {}
    for index, row in ipairs(rows) do
        items[#items + 1] = {
            rank = index,
            uid = tonumber(row.uid) or 0,
            name = tostring(row.name or ""),
            level = tonumber(row.level) or 1,
            prestige = tonumber(row.prestige) or 0,
            logoId = tonumber(row.logoId) or 1,
            cardId = tonumber(row.emblemsId) or 1,
            value = tonumber(row.value) or 0,
        }
    end

    cache[category.id] = { items = items, expiresAt = GetGameTimer() + cacheMs }
    return items
end

local function fetchSelf(category, uid, items)
    for _, item in ipairs(items) do
        if item.uid == uid then return item end
    end

    local query = ([[
        SELECT COALESCE(NULLIF(u.username, ''), CONCAT('Operator #', w.uid)) AS name,
               w.level, w.prestige, w.logoId, w.emblemsId, %s AS value, %s AS ord
        FROM warv w
        INNER JOIN users u ON u.id = w.uid%s
    ]]):format(category.value, orderOf(category), whereOf(category, "w.uid = " .. uid))

    local ok, rows = Db.Query(query)
    if not ok or type(rows) ~= "table" or rows[1] == nil then
        return nil
    end

    local row = rows[1]
    local okRank, rankRows = Db.Query(
        ("SELECT COUNT(*) + 1 AS position FROM warv w%s"):format(
            whereOf(category, orderOf(category) .. " > " .. (tonumber(row.ord) or 0))
        )
    )

    return {
        rank = okRank and rankRows and rankRows[1] and tonumber(rankRows[1].position) or 0,
        uid = uid,
        name = tostring(row.name or ""),
        level = tonumber(row.level) or 1,
        prestige = tonumber(row.prestige) or 0,
        logoId = tonumber(row.logoId) or 1,
        cardId = tonumber(row.emblemsId) or 1,
        value = tonumber(row.value) or 0,
    }
end

function Leaderboard.Send(source, categoryId)
    if not Players.DoesPlayerExist(source) then return end

    local category = getCategory(categoryId)
    local items = fetchTop(category)
    local uid = tonumber(Players.GetPlayerUid(source))

    TriggerClientEvent("warv:LeaderboardData", source, {
        category = category.id,
        categories = categoryList(),
        items = items,
        self = uid and fetchSelf(category, uid, items) or nil,
    })
end

RegisterNetEvent("warv:GetLeaderboard", function(categoryId)
    Leaderboard.Send(source, type(categoryId) == "string" and categoryId or nil)
end)
