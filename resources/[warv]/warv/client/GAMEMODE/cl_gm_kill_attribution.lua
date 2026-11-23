Gm.KillAttribution = {
    emissions = {},
    instances = {},
    lastDamageByVictim = {},
    nextInstanceId = 0,
}

local attribution = Gm.KillAttribution
local maxEmissions = 512
local lastDamageTtl = 2000

local function copyCoords(coords)
    return vector3(coords.x, coords.y, coords.z)
end

local function distanceToSegment(point, lineStart, lineEnd)
    local dx = lineEnd.x - lineStart.x
    local dy = lineEnd.y - lineStart.y
    local dz = lineEnd.z - lineStart.z
    local lengthSquared = dx * dx + dy * dy + dz * dz

    if lengthSquared <= 0.0001 then
        return #(point - lineStart)
    end

    local px = point.x - lineStart.x
    local py = point.y - lineStart.y
    local pz = point.z - lineStart.z
    local progress = (px * dx + py * dy + pz * dz) / lengthSquared
    progress = math.max(0.0, math.min(1.0, progress))

    local closest = vector3(
        lineStart.x + dx * progress,
        lineStart.y + dy * progress,
        lineStart.z + dz * progress
    )

    return #(point - closest)
end

local function cleanup(now)
    for index = #attribution.emissions, 1, -1 do
        if attribution.emissions[index].expiresAt < now then
            table.remove(attribution.emissions, index)
        end
    end

    for victim, damage in pairs(attribution.lastDamageByVictim) do
        if damage.expiresAt < now or not DoesEntityExist(victim) then
            attribution.lastDamageByVictim[victim] = nil
        end
    end

    for instanceId, instance in pairs(attribution.instances) do
        if instance.expiresAt < now then
            attribution.instances[instanceId] = nil
        end
    end
end

function attribution.Begin(killstreak, externalId)
    attribution.nextInstanceId = attribution.nextInstanceId + 1
    local instanceId = (externalId or killstreak) .. ":" .. GetGameTimer() .. ":" .. attribution.nextInstanceId

    attribution.instances[instanceId] = {
        killstreak = killstreak,
        kills = 0,
        expiresAt = GetGameTimer() + 120000,
    }

    return instanceId
end

function attribution.End(instanceId)
    local instance = attribution.instances[instanceId]
    if instance then
        instance.expiresAt = GetGameTimer() + lastDamageTtl
    end
end

local function record(instanceId, emission, options)
    local instance = attribution.instances[instanceId]
    if not instance then return end

    local now = GetGameTimer()
    cleanup(now)

    emission.instanceId = instanceId
    emission.killstreak = instance.killstreak
    emission.radius = options.radius
    emission.target = options.target
    emission.targetOnly = options.targetOnly
    emission.createdAt = now
    emission.expiresAt = now + options.ttl
    attribution.emissions[#attribution.emissions + 1] = emission

    if #attribution.emissions > maxEmissions then
        table.remove(attribution.emissions, 1)
    end
end

function attribution.RecordExplosion(instanceId, coords, options)
    if not coords then return end
    record(instanceId, { kind = "explosion", center = copyCoords(coords) }, options)
end

function attribution.RecordShot(instanceId, lineStart, lineEnd, weaponHash, options)
    if not lineStart or not lineEnd then return end
    record(instanceId, {
        kind = "shot",
        lineStart = copyCoords(lineStart),
        lineEnd = copyCoords(lineEnd),
        weaponHash = weaponHash,
    }, options)
end

local function emissionScore(emission, victim, victimPos, weaponHash, now)
    if emission.expiresAt < now then return nil end
    if emission.targetOnly and emission.target ~= victim then return nil end

    local age = now - emission.createdAt
    local targetBonus = emission.target == victim and -1000 or 0

    if emission.kind == "explosion" then
        local distance = #(victimPos - emission.center)
        if distance > emission.radius then return nil end
        return age + (distance / math.max(emission.radius, 0.1)) * 100 + targetBonus
    end

    if emission.weaponHash and weaponHash and emission.weaponHash ~= weaponHash then
        return nil
    end

    local distance = distanceToSegment(victimPos, emission.lineStart, emission.lineEnd)
    if distance > emission.radius then return nil end
    return age + (distance / math.max(emission.radius, 0.1)) * 100 + targetBonus
end

function attribution.TrackDamage(victim, weaponHash)
    local now = GetGameTimer()
    cleanup(now)

    local victimPos = GetEntityCoords(victim, true)
    local bestEmission
    local bestScore

    for index = #attribution.emissions, 1, -1 do
        local emission = attribution.emissions[index]
        local score = emissionScore(emission, victim, victimPos, weaponHash, now)
        if score and (bestScore == nil or score < bestScore) then
            bestEmission = emission
            bestScore = score
        end
    end

    attribution.lastDamageByVictim[victim] = {
        type = bestEmission and "killstreak" or "weapon",
        killstreak = bestEmission and bestEmission.killstreak or nil,
        instanceId = bestEmission and bestEmission.instanceId or nil,
        weapon = weaponHash,
        expiresAt = now + lastDamageTtl,
    }
end

function attribution.Consume(victim, fallbackWeapon)
    local now = GetGameTimer()
    local damage = attribution.lastDamageByVictim[victim]
    attribution.lastDamageByVictim[victim] = nil

    if not damage or damage.expiresAt < now then
        return fallbackWeapon
    end

    if damage.type == "killstreak" and damage.killstreak then
        local instance = attribution.instances[damage.instanceId]
        if instance then
            instance.kills = instance.kills + 1
        end
        return damage.killstreak
    end

    return damage.weapon or fallbackWeapon
end

function attribution.GetKillCount(instanceId)
    local instance = attribution.instances[instanceId]
    return instance and instance.kills or 0
end

function attribution.HasRecentShot()
    local now = GetGameTimer()
    cleanup(now)

    for index = #attribution.emissions, 1, -1 do
        if attribution.emissions[index].kind == "shot" then
            return true
        end
    end

    return false
end

function attribution.Clear()
    attribution.emissions = {}
    attribution.instances = {}
    attribution.lastDamageByVictim = {}
end

AddEventHandler("warv:gm_loaded", function()
    attribution.Clear()
end)
