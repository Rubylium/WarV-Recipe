Challenges = {}
Challenges.progress = {}
Challenges.periods = {}
Challenges.loading = {}

local weaponClasses = nil
local challengesById = {}

for _, challenge in ipairs(SharedConfig.challenges) do
    challengesById[challenge.id] = challenge
end

local function classOfWeapon(weapon)
    if weaponClasses == nil then
        weaponClasses = {}
        for _, section in pairs(SharedConfig.weapons) do
            for _, group in ipairs(section) do
                for _, entry in ipairs(group.weapons or {}) do
                    local name = WeaponRegistry.NormalizeName(entry.weapon)
                    if name then weaponClasses[name] = group.label end
                end
            end
        end
    end

    return weaponClasses[weapon]
end

local week = 604800
local mondayShift = 259200

function Challenges.Period()
    local now = os.time()
    return tostring(os.date("!%Y%m%d", now - ((now + mondayShift) % week)))
end

function Challenges.ResetsInSeconds()
    return week - ((os.time() + mondayShift) % week)
end

function Challenges.Weekly(period)
    local pool = SharedConfig.challenges
    local order = {}
    for index = 1, #pool do order[index] = index end

    local digits = (period or Challenges.Period()):gsub("%D", "")
    local seed = tonumber(digits) or 0
    for index = #order, 2, -1 do
        seed = (seed * 1103515245 + 12345) % 2147483648
        local pick = (seed % index) + 1
        order[index], order[pick] = order[pick], order[index]
    end

    local weekly = {}
    for index = 1, math.min(SharedConfig.weeklyChallengeCount, #order) do
        weekly[#weekly + 1] = pool[order[index]]
    end

    return weekly
end

local function isCompleted(value)
    return value == true or value == 1 or value == "1" or value == "true"
end

function Challenges.Load(uid, period)
    uid = tonumber(uid)
    if uid == nil then return nil, "invalid uid" end
    period = period or Challenges.Period()

    if Challenges.progress[uid] ~= nil and Challenges.periods[uid] == period then
        return Challenges.progress[uid]
    end

    local activeLoad = Challenges.loading[uid]
    if activeLoad ~= nil then
        local result = Citizen.Await(activeLoad.promise)
        if result.period ~= period then
            return Challenges.Load(uid, period)
        end
        return result.entries, result.error
    end

    local loadPromise = promise.new()
    Challenges.loading[uid] = {
        period = period,
        promise = loadPromise,
    }

    local entries = {}
    local ok, rows, errorMessage = Db.Query(
        "SELECT challenge, progress, completed FROM warv_challenges WHERE uid = ? AND period = ?",
        { uid, period }
    )

    if not ok or type(rows) ~= "table" then
        local loadError = errorMessage or "bad result"
        Challenges.loading[uid] = nil
        loadPromise:resolve({ entries = nil, error = loadError, period = period })
        CriticalPrint("Challenges load UID [" .. uid .. "]: " .. tostring(loadError))
        return nil, loadError
    end

    for _, row in ipairs(rows) do
        local challengeId = tostring(row.challenge)
        local challenge = challengesById[challengeId]
        local progress = tonumber(row.progress) or 0

        if challenge ~= nil and progress > challenge.target then
            progress = challenge.target
            local corrected, _, correctionError = Db.Update(
                "UPDATE warv_challenges SET progress = ? WHERE uid = ? AND period = ? AND challenge = ?",
                { progress, uid, period, challengeId }
            )
            if not corrected then
                WarningPrint("Challenge clamp UID [" .. uid .. "] [" .. challengeId .. "]: " .. tostring(correctionError))
            end
        end

        entries[challengeId] = {
            progress = progress,
            completed = isCompleted(row.completed),
        }
    end

    Challenges.progress[uid] = entries
    Challenges.periods[uid] = period
    Challenges.loading[uid] = nil
    loadPromise:resolve({ entries = entries, error = nil, period = period })
    return entries
end

function Challenges.Unload(uid)
    Challenges.progress[uid] = nil
    Challenges.periods[uid] = nil
end

local function entryOf(uid, id, period)
    period = period or Challenges.Period()
    local entries = Challenges.progress[uid]
    if entries == nil or Challenges.periods[uid] ~= period then
        local errorMessage
        entries, errorMessage = Challenges.Load(uid, period)
        if entries == nil then
            return nil, errorMessage
        end
    end

    if entries[id] == nil then
        entries[id] = { progress = 0, completed = false }
    end

    return entries[id]
end

function Challenges.BuildPayload(source)
    local uid = tonumber(Players.GetPlayerUid(source))
    if uid == nil then return nil end

    local period = Challenges.Period()
    local items = {}
    for _, challenge in ipairs(Challenges.Weekly(period)) do
        local entry = entryOf(uid, challenge.id, period)
        if entry == nil then return nil end
        items[#items + 1] = {
            id = challenge.id,
            label = challenge.label,
            desc = challenge.desc,
            target = challenge.target,
            credit = challenge.credit,
            icon = challenge.icon,
            progress = math.min(entry.progress, challenge.target),
            completed = entry.completed,
        }
    end

    return { items = items, resetsIn = Challenges.ResetsInSeconds() }
end

function Challenges.Send(source)
    if not Players.DoesPlayerExist(source) then return end

    local payload = Challenges.BuildPayload(source)
    if payload ~= nil then
        TriggerClientEvent("warv:ChallengesData", source, payload)
    end
end

local function notifyComplete(source, challenge)
    Players.RefreshData(source)

    TriggerClientEvent("warv:UnlockNotification", source,
        "CHALLENGE COMPLETE · " .. challenge.label:upper() .. " · +" .. challenge.credit .. " CR")
end

local function matches(challenge, kind, context)
    if challenge.type ~= kind then return false end
    if kind == "weaponClass" then return challenge.class == context end
    if kind == "weapon" then return challenge.weapon == context end
    return true
end

function Challenges.Progress(source, kind, amount, context)
    if not Players.DoesPlayerExist(source) then return end

    local uid = tonumber(Players.GetPlayerUid(source))
    if uid == nil then return end

    local period = Challenges.Period()
    local changed = false

    for _, challenge in ipairs(Challenges.Weekly(period)) do
        if matches(challenge, kind, context) then
            local entry, loadError = entryOf(uid, challenge.id, period)
            if entry == nil then
                CriticalPrint("Challenge skip UID [" .. uid .. "]: " .. tostring(loadError))
                return
            end

            if not entry.completed then
                local previousProgress = entry.progress
                local nextProgress = math.min(previousProgress + (amount or 1), challenge.target)
                local persisted, _, persistError = Db.Update([[
                    INSERT INTO warv_challenges (uid, period, challenge, progress, completed)
                    VALUES (?, ?, ?, ?, 0)
                    ON DUPLICATE KEY UPDATE
                        progress = IF(completed = 1, progress, GREATEST(progress, VALUES(progress)))
                ]], { uid, period, challenge.id, nextProgress })

                if not persisted then
                    CriticalPrint("Challenge save UID [" .. uid .. "] [" .. challenge.id .. "]: " .. tostring(persistError))
                    return
                end

                entry.progress = nextProgress
                changed = changed or nextProgress ~= previousProgress

                if nextProgress >= challenge.target then
                    local claimed, affectedRows, claimError = Db.Update([[
                        UPDATE warv_challenges AS challengeProgress
                        INNER JOIN warv AS playerData ON playerData.uid = challengeProgress.uid
                        SET challengeProgress.progress = LEAST(challengeProgress.progress, ?),
                            challengeProgress.completed = 1,
                            playerData.credit = playerData.credit + ?
                        WHERE challengeProgress.uid = ?
                          AND challengeProgress.period = ?
                          AND challengeProgress.challenge = ?
                          AND challengeProgress.completed = 0
                    ]], { challenge.target, challenge.credit, uid, period, challenge.id })

                    if not claimed then
                        entry.progress = previousProgress
                        CriticalPrint("Challenge claim UID [" .. uid .. "] [" .. challenge.id .. "]: " .. tostring(claimError))
                        return
                    end

                    entry.completed = true
                    if (tonumber(affectedRows) or 0) > 0 then
                        local data = Players.list[source]
                        if data ~= nil and tonumber(data.uid) == uid then
                            data.credit = data.credit + challenge.credit
                            if not Players.SaveDataNow(source) then
                                CriticalPrint("Challenge claimed, save failed UID [" .. uid .. "]")
                            end
                            notifyComplete(source, challenge)
                        end
                    end
                end
            end
        end
    end

    if changed then
        Challenges.Send(source)
    end
end

function Challenges.AddKill(source, weapon, headshot)
    Challenges.Progress(source, "kills", 1)
    if headshot then
        Challenges.Progress(source, "headshots", 1)
    end

    local class = weapon and classOfWeapon(weapon)
    if class then
        Challenges.Progress(source, "weaponClass", 1, class)
        Challenges.Progress(source, "weapon", 1, weapon)
    end
end

RegisterNetEvent("warv:GetChallenges", function()
    local source = source
    local uid = tonumber(Players.GetPlayerUid(source))
    if uid ~= nil and Challenges.progress[uid] == nil then
        Challenges.Load(uid)
    end
    Challenges.Send(source)
end)
