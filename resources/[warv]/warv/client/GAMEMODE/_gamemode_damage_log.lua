DamageLog = {}

local deadHealth = 100

local entries = {}
local tracked = deadHealth

local function attackerKey(attacker)
    local player = GetPlayerByEntityID(attacker)
    if player ~= nil then
        return "p:" .. GetPlayerServerId(player), GetPlayerName(player)
    end

    local isBot, botId = Bot.IsEntityABot(attacker)
    if isBot then
        local profile = Bot.GetProfile(botId)
        return "b:" .. botId, (profile and profile.name) or "Bot"
    end
    return nil
end

function DamageLog.Reset()
    entries = {}
    tracked = math.max(deadHealth, GetEntityHealth(Gamemode.utils.GetPed()))
end

function DamageLog.Track()
    local health = GetEntityHealth(Gamemode.utils.GetPed())
    if health > tracked then tracked = health end
end

function DamageLog.MarkFinal(killer)
    local key = killer and killer ~= 0 and attackerKey(killer)
    local entry = key and entries[key]
    if entry then entry.final = true end
end

function DamageLog.Build()
    local rows = {}
    for _, entry in pairs(entries) do
        local topWeapon, topDamage = 0, -1
        for weaponHash, damage in pairs(entry.weapons) do
            if damage > topDamage then topWeapon, topDamage = weaponHash, damage end
        end
        rows[#rows + 1] = {
            name = entry.name,
            damage = math.floor(entry.damage + 0.5),
            hits = entry.hits,
            headshot = entry.headshot == true,
            final = entry.final == true,
            weaponHash = topWeapon,
        }
    end

    table.sort(rows, function(a, b)
        if a.damage ~= b.damage then return a.damage > b.damage end
        return a.name < b.name
    end)
    return rows
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local attacker = args[2]
    local ped = Gamemode.utils.GetPed()
    if victim ~= ped or attacker == ped or not Status.GetIsPlayerInGame() then return end
    if GetEntityType(attacker) ~= 1 then return end

    local key, attackerName = attackerKey(attacker)
    if not key then return end

    local health = math.max(deadHealth, GetEntityHealth(ped))
    local damage = math.max(0, tracked - health)
    tracked = health

    local entry = entries[key]
    if not entry then
        entry = { name = attackerName, damage = 0, hits = 0, weapons = {} }
        entries[key] = entry
    end

    local weaponHash = tonumber(args[7]) or 0
    entry.damage = entry.damage + damage
    entry.hits = entry.hits + 1
    entry.weapons[weaponHash] = (entry.weapons[weaponHash] or 0) + damage

    local _, bone = GetPedLastDamageBone(ped)
    if bone == 31086 then entry.headshot = true end
end)
