GamemodeMedalTracker = {}

local avengerWindowMs = 5000
local saviorWindowMs = 2000
local uavDurationMs = 30000
local longshotDistance = 60.0
local pointBlankDistance = 3.0
local shutdownStreak = 5
local comebackDeaths = 3
local dominatorKills = 3
local majorAssistPoints = 75
local saviorHealth = 130

local function addMedal(medals, added, medalId)
    if added[medalId] then return end
    added[medalId] = true
    medals[#medals + 1] = medalId
end

local function number(value, fallback)
    local result = tonumber(value)
    if result == nil then return fallback end
    return result
end

local function weaponDefinition(weapon)
    if weapon == nil or type(weapon) == "table" then return nil end
    local weaponName = WeaponRegistry.NormalizeName(weapon)
    return weaponName and WeaponRegistry.byName[weaponName] or nil
end

local function weaponHasDamageType(weapon, damageType)
    local definition = weaponDefinition(weapon)
    return definition ~= nil and tostring(definition.DamageType or ""):upper() == damageType
end

function GamemodeMedalTracker.New(options)
    local tracker = {
        firstBloodAvailable = true,
        gameWinnerAwarded = false,
        states = {},
        uavs = {},
    }

    local function participantState(participant)
        if participant == nil or participant.key == nil then return nil end
        local state = tracker.states[participant.key]
        if state == nil then
            state = {
                alive = true,
                avengerTargets = {},
                deathStreak = 0,
                domination = {},
                lastAttacker = nil,
                lastDamagedAt = 0,
                lastHealth = 0,
                lifeStreak = 0,
            }
            tracker.states[participant.key] = state
        end
        return state
    end

    local function award(participant, medalIds)
        if participant == nil or #medalIds == 0 then return end
        options.award(participant, medalIds)
    end

    local function scoreOf(participant)
        return number(participant and options.getScore(participant), 0)
    end

    local function isKingslayerTarget(killer, victim)
        local victimScore = scoreOf(victim)
        if victimScore <= 0 then return false end

        local highestScore = -1
        for _, participant in ipairs(options.getParticipants()) do
            if options.isLeaderboardPeer(participant, victim, killer) then
                highestScore = math.max(highestScore, scoreOf(participant))
            end
        end

        return victimScore >= highestScore
    end

    local function cleanUavs(now)
        for uavId, uav in pairs(tracker.uavs) do
            if uav.expiresAt <= now then
                tracker.uavs[uavId] = nil
            end
        end
    end

    local function awardUavAssists(killer, now)
        cleanUavs(now)

        for _, uav in pairs(tracker.uavs) do
            if uav.owner.key ~= killer.key and options.areAllies(uav.owner, killer) then
                award(uav.owner, {"uav_assist"})
            end
        end
    end

    function tracker:PrepareKill(killer, victim)
        local killerState = participantState(killer)
        local victimState = participantState(victim)
        local now = GetGameTimer()
        for targetKey, expiresAt in pairs(killerState.avengerTargets) do
            if expiresAt < now then
                killerState.avengerTargets[targetKey] = nil
            end
        end

        local isAvenger = number(killerState.avengerTargets[victim.key], 0) >= now
        local isNemesis = number(victimState.domination[killer.key], 0) >= dominatorKills

        return {
            isAvenger = isAvenger,
            isComeback = killerState.deathStreak >= comebackDeaths,
            isKingslayer = isKingslayerTarget(killer, victim),
            isNemesis = isNemesis,
            isShutdown = victimState.lifeStreak >= shutdownStreak,
            wasSoleLeader = options.isSoleLeader(killer),
        }
    end

    function tracker:RecordKill(killer, victim, context, prepared)
        if killer.key == victim.key then return end

        local now = GetGameTimer()
        local killerState = participantState(killer)
        local victimState = participantState(victim)
        local medals = {}
        local added = {}

        if self.firstBloodAvailable then
            self.firstBloodAvailable = false
            addMedal(medals, added, "first_blood")
        end
        if prepared.isKingslayer then addMedal(medals, added, "kingslayer") end
        if prepared.isShutdown then addMedal(medals, added, "shutdown") end
        if prepared.isComeback then addMedal(medals, added, "comeback") end
        if prepared.isAvenger then addMedal(medals, added, "avenger") end
        if prepared.isNemesis then addMedal(medals, added, "nemesis") end

        local distance = number(context.distance, -1)
        if distance >= longshotDistance and distance <= 10000.0 then
            addMedal(medals, added, "longshot")
        elseif distance >= 0.0 and distance <= pointBlankDistance then
            addMedal(medals, added, "point_blank")
        end
        if context.airborne == true then addMedal(medals, added, "airborne") end
        if context.fromGrave == true then addMedal(medals, added, "from_grave") end

        if SharedConfig.IsKillstreakKillSource(context.weapon) then
            addMedal(medals, added, "scorestreak_kill")
        elseif weaponHasDamageType(context.weapon, "MELEE") then
            addMedal(medals, added, "melee")
        elseif weaponHasDamageType(context.weapon, "EXPLOSIVE") then
            addMedal(medals, added, "demolition")
        end

        if not prepared.wasSoleLeader and options.isSoleLeader(killer) then
            addMedal(medals, added, "took_lead")
        end
        if not self.gameWinnerAwarded and options.isGameWinner(killer) then
            self.gameWinnerAwarded = true
            addMedal(medals, added, "game_winner")
        end

        for _, teammate in ipairs(options.getParticipants()) do
            if teammate.key ~= killer.key and options.areAllies(teammate, killer) then
                local teammateState = participantState(teammate)
                if teammateState.alive
                    and teammateState.lastAttacker == victim.key
                    and teammateState.lastDamagedAt + saviorWindowMs >= now
                    and teammateState.lastHealth <= saviorHealth then
                    addMedal(medals, added, "savior")
                    break
                end
            end
        end

        local dominationCount = number(killerState.domination[victim.key], 0) + 1
        killerState.domination[victim.key] = dominationCount
        victimState.domination[killer.key] = 0
        if dominationCount == dominatorKills then
            addMedal(medals, added, "dominator")
        end

        killerState.alive = true
        killerState.deathStreak = 0
        killerState.lifeStreak = killerState.lifeStreak + 1
        if prepared.isAvenger then
            killerState.avengerTargets[victim.key] = nil
        end

        victimState.alive = false
        victimState.deathStreak = victimState.deathStreak + 1
        victimState.lifeStreak = 0
        victimState.lastAttacker = nil
        victimState.lastDamagedAt = 0

        for _, teammate in ipairs(options.getParticipants()) do
            if teammate.key ~= victim.key and options.areAllies(teammate, victim) then
                local teammateState = participantState(teammate)
                teammateState.avengerTargets[killer.key] = now + avengerWindowMs
            end
        end

        award(killer, medals)
        awardUavAssists(killer, now)
    end

    function tracker:RecordSuicide(participant)
        local state = participantState(participant)
        if state == nil then return end
        state.alive = false
        state.deathStreak = state.deathStreak + 1
        state.lifeStreak = 0
        state.lastAttacker = nil
        state.lastDamagedAt = 0
    end

    function tracker:RecordRespawn(participant)
        local state = participantState(participant)
        if state == nil then return end
        state.alive = true
        state.lastAttacker = nil
        state.lastDamagedAt = 0
        state.lastHealth = 0
    end

    function tracker:RecordDamage(victim, attacker, health)
        local state = participantState(victim)
        if state == nil or attacker == nil then return end
        state.alive = true
        state.lastAttacker = attacker.key
        state.lastDamagedAt = GetGameTimer()
        state.lastHealth = math.max(0, number(health, 0))
    end

    function tracker:AwardMajorAssist(participant, assistPoints)
        if number(assistPoints, 0) >= majorAssistPoints then
            award(participant, {"major_assist"})
        end
    end

    function tracker:RegisterUav(owner, uavId)
        if owner == nil or type(uavId) ~= "string" or uavId == "" or #uavId > 64 then
            return false
        end

        for existingId, uav in pairs(self.uavs) do
            if uav.owner.key == owner.key then
                self.uavs[existingId] = nil
            end
        end

        self.uavs[uavId] = {
            expiresAt = GetGameTimer() + uavDurationMs,
            owner = owner,
        }
        return true
    end

    function tracker:DestroyUav(shooter, uavId)
        cleanUavs(GetGameTimer())
        local uav = self.uavs[uavId]
        if shooter == nil or uav == nil then return false end

        local isEnemy = shooter.key ~= uav.owner.key
            and not options.areAllies(shooter, uav.owner)
        if not isEnemy then return false end

        self.uavs[uavId] = nil
        award(shooter, {"aerial_denial"})
        return true
    end

    return tracker
end
