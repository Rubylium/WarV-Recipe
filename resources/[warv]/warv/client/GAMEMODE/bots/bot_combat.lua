local combatConfigFlags = {
    [17] = true,
    [39] = true,
    [49] = true,
    [118] = false,
    [119] = true,
    [128] = false,
    [169] = true,
    [208] = true,
    [213] = false,
    [226] = true,
    [245] = true,
    [285] = true,
    [290] = true,
    [294] = true,
    [329] = true,
    [372] = true,
    [373] = true,
}

function Bot.SetBotAttribute(entity, profile)
    Bot.DisableAudio(entity)

    SetPedAccuracy(entity, BotConfig.accuracy)
    SetPedCombatAbility(entity, 2)
    SetPedCombatMovement(entity, BotConfig.combatMovement)
    SetPedCombatRange(entity, BotConfig.combatRange)
    SetPedSeeingRange(entity, BotConfig.seeingRange)
    SetPedHearingRange(entity, 0.0)
    SetPedAlertness(entity, 3)

    SetPedCombatAttributes(entity, 0, true)
    SetPedCombatAttributes(entity, 1, false)
    SetPedCombatAttributes(entity, 2, false)
    SetPedCombatAttributes(entity, 3, false)
    SetPedCombatAttributes(entity, 5, true)
    SetPedCombatAttributes(entity, 20, false)
    SetPedCombatAttributes(entity, 46, true)
    SetPedCombatAttributes(entity, 58, true)
    SetPedFleeAttributes(entity, 0, false)

    for flag, enabled in pairs(combatConfigFlags) do
        SetPedConfigFlag(entity, flag, enabled)
    end

    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanEvasiveDive(entity, false)
    SetPedCanPlayInjuredAnims(entity, false)
    SetPedCanRagdollFromPlayerImpact(entity, false)
    SetPedCanRagdoll(entity, false)
    SetPedDropsWeaponsWhenDead(entity, false)
    SetPedKeepTask(entity, true)
    SetCanAttackFriendly(entity, false, false)

    SetEntityMaxHealth(entity, SharedConfig.healthGate)
    SetEntityHealth(entity, SharedConfig.healthGate)

    local weapon = Bot.possibleWeapon[math.random(1, #Bot.possibleWeapon)]
    if Matchmaking.data.gamemode == "TRON DEATHMATCH" then
        weapon = GetHashKey(TdmFutur.weapon)
    elseif Bot.WeaponFor then
        weapon = Bot.WeaponFor(profile)
    end

    RequestWeaponAsset(weapon, 31, 0)
    GiveWeaponToPed(entity, weapon, 255, false, true)
    SetPedAmmo(entity, weapon, 255)
    SetCurrentPedWeapon(entity, weapon, true)
    Gamemode.SetTeamForPed(profile.team, entity)
end

function Bot.RefreshCombatTask(state)
    local entity = state.entity
    if not Bot.GameStarted or IsEntityDead(entity) then
        return
    end

    local now = GetGameTimer()
    if not IsPedInCombat(entity, 0) and now - state.lastCombatTaskAt >= 1000 then
        TaskCombatHatedTargetsAroundPed(entity, BotConfig.seeingRange, 0)
        state.lastCombatTaskAt = now
    end
end
