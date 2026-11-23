Unlocks = {}

local function number(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function totalWeaponHeadshots(player)
    local total = 0
    for _, weaponStats in pairs(player.weaponsStats) do
        total = total + number(weaponStats.headshot)
    end
    return total
end

local statGetters = {
    level = function(player)
        if number(player.prestige) > 0 then return 55 end
        return number(player.level)
    end,
    prestige = function(player)
        return number(player.prestige)
    end,
    kills = function(player)
        return number(player.kill)
    end,
    assists = function(player)
        return number(player.assist)
    end,
    deaths = function(player)
        return number(player.death)
    end,
    wins = function(player)
        return number(player.stats.win)
    end,
    losses = function(player)
        return number(player.stats.loose)
    end,
    draws = function(player)
        return number(player.stats.draw)
    end,
    games = function(player)
        return number(player.stats.gamePlayed)
    end,
    headshots = function(player)
        return math.max(
            number(player.stats.headshot),
            totalWeaponHeadshots(player)
        )
    end,
    nukes = function(player)
        return number(player.stats.nukes)
    end,
}

function Unlocks.GetRequirementProgress(player, requirement)
    local getter = statGetters[requirement.stat]
    local current = getter and getter(player) or 0
    local target = math.max(1, number(requirement.target))

    return {
        stat = tostring(requirement.stat or ""),
        label = tostring(requirement.label or ""),
        current = current,
        target = target,
        percent = math.min(100, math.floor((current / target) * 100)),
        complete = current >= target,
    }
end

function Unlocks.AddStat(player, stat, amount)
    if player == nil then return end
    player.stats[stat] = number(player.stats[stat]) + number(amount)
end

function Unlocks.New(opts)
    local bucket, entries = opts.bucket, opts.entries
    local set = {}

    function set.Get(index)
        index = tonumber(index)
        if index == nil then return nil end
        return entries[math.floor(index)]
    end

    function set.IsUnlocked(player, index)
        local entry = set.Get(index)
        if not entry then return false end

        if player.unlockedContent[bucket][entry.id] == true then return true end
        if entry.grantOnly then return false end

        for _, requirement in ipairs(entry.requirements or {}) do
            if not Unlocks.GetRequirementProgress(player, requirement).complete then
                return false
            end
        end

        player.unlockedContent[bucket][entry.id] = true
        return true
    end

    function set.NormalizePlayer(player)
        player.stats.headshot = math.max(
            number(player.stats.headshot),
            totalWeaponHeadshots(player)
        )
        player.stats.nukes = number(player.stats.nukes)

        for index in ipairs(entries) do
            set.IsUnlocked(player, index)
        end

        local selected = tonumber(player[opts.selected])
        if not selected or not set.IsUnlocked(player, selected) then
            player[opts.selected] = 1
        else
            player[opts.selected] = math.floor(selected)
        end
    end

    function set.BuildPayload(player)
        set.NormalizePlayer(player)

        local items = {}
        for index, entry in ipairs(entries) do
            local requirements = {}
            local unlocked = set.IsUnlocked(player, index)

            for _, requirement in ipairs(entry.requirements or {}) do
                local progress = Unlocks.GetRequirementProgress(player, requirement)
                if unlocked and not progress.complete then
                    progress.current = progress.target
                    progress.percent = 100
                    progress.complete = true
                end
                requirements[#requirements + 1] = progress
            end

            items[#items + 1] = {
                id = index,
                key = entry.id,
                sprite = entry.image or entry.sprite,
                label = entry.label,
                description = entry.description,
                locked = not unlocked,
                requirements = requirements,
            }
        end

        return {
            items = items,
            selected = player[opts.selected],
        }
    end

    function set.SendProgress(source)
        if not Players.DoesPlayerExist(source) then return end
        TriggerClientEvent(opts.event, source, set.BuildPayload(Players.list[source]))
    end

    return set
end
