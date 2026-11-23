Gm.KillHandler = {}
Gm.KillHandler.fatalCooldown = {}


function Gm.KillHandler.IsHeadshot(victim)
    local headshot = false
    local _, outbone = GetPedLastDamageBone(victim)
    if outbone == 31086 then
        headshot = true
    end
    return headshot
end

function Gm.KillHandler.HandleCooldown(victim)
    Gm.KillHandler.fatalCooldown[victim] = true
    Citizen.CreateThread(function()
        Wait(1000)
        Gm.KillHandler.fatalCooldown[victim] = false
    end)
    Gm.KillHandler.CleanCooldownList()
end

function Gm.KillHandler.IsVictimOutOfCooldown(victim)
    return Gm.KillHandler.fatalCooldown[victim] == nil or Gm.KillHandler.fatalCooldown[victim] == false
end

function Gm.KillHandler.CleanCooldownList()
    local EntityToRemove = {}
    for index, entity in pairs(Gm.KillHandler.fatalCooldown) do
        if not DoesEntityExist(entity) then
            table.insert(EntityToRemove, index)
        end
    end

    for _, index in pairs(EntityToRemove) do
        Gm.KillHandler.fatalCooldown[index] = nil
    end
end

function Gm.KillHandler.BuildKillContext(attacker, victim)
    local fromGrave = Gamemode.isDead or IsEntityDead(attacker)
    return {
        distance = #(GetEntityCoords(attacker, true) - GetEntityCoords(victim, true)),
        airborne = not fromGrave and IsEntityInAir(attacker),
        fromGrave = fromGrave,
    }
end


AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local fatal = args[4]

        if GetEntityType(attacker) == 1 and GetEntityType(victim) == 1 then
            local pPed = Gamemode.utils.GetPed()
            if pPed == attacker then
                if pPed ~= victim then
                    Gm.KillAttribution.TrackDamage(victim, args[7])
                    if IsEntityDead(victim, 1) then
                        if Gm.KillHandler.IsVictimOutOfCooldown(victim) then
                            Gm.KillHandler.HandleCooldown(victim)
                            local weapon
                            local headshot = Gm.KillHandler.IsHeadshot(victim)
                            local bot, botId, botTeam = Bot.IsEntityABot(victim)
                            local victimPlayer = GetPlayerByEntityID(victim)
                            local victimName = victimPlayer ~= nil and GetPlayerName(victimPlayer) or nil
                            local killedId = victimPlayer ~= nil and GetPlayerServerId(victimPlayer) or nil
                            local killContext = Gm.KillHandler.BuildKillContext(pPed, victim)

                            if bot then
                                local botProfile = Bot.GetProfile(botId)
                                victimName = botProfile and botProfile.name or nil
                            end

                            weapon = Gm.KillAttribution.Consume(victim, args[7])
                            Medals.AddKill(
                                Status.GetCurrentGameId(),
                                victimName,
                                SharedConfig.IsKillstreakKillSource(weapon)
                            )

                            if bot then
                                Utils.TriggerGamemodeServerEvent("AddPlayerKillBot", botId, botTeam, Gamemode.utils.GetSID(), headshot, weapon, killContext)
                            else
                                Utils.TriggerGamemodeServerEvent("AddPlayerKill", killedId, Gamemode.utils.GetSID(), headshot, weapon, killContext)
                            end

                            local _, weaponKill = GetCurrentPedWeapon(victim, 1)
                            KillSound.HandleKillSound(weaponKill)
                        end
                    end
                elseif pPed == attacker and pPed == victim then
                    if IsEntityDead(victim, 1) and Gm.KillHandler.IsVictimOutOfCooldown(victim) then
                        Gm.KillHandler.HandleCooldown(victim)
                        Utils.TriggerGamemodeServerEvent("AddPlayerDeath")
                    end
                end
            else
                if SharedConfig.devmod then
                    if Player.GetPed() == victim then
                        if fatal then
                            if Gm.KillHandler.IsVictimOutOfCooldown(victim) then
                                if IsEntityDead(victim) then
                                    local bot, botId, botTeam = Bot.IsEntityABot(attacker)
                                    if bot then
                                        Gm.KillHandler.HandleCooldown(victim)
                                        local psID = Gamemode.utils.GetSID()
                                        local weapon = args[7]
                                        local headshot = Gm.KillHandler.IsHeadshot(victim)

                                        Utils.TriggerGamemodeServerEvent("AddBotKillPlayer", botId, botTeam, psID, headshot, weapon)
                                    end
                                end
                            end
                        end
                    else
                        if Bot.isHost then
                            if fatal then
                                if Gm.KillHandler.IsVictimOutOfCooldown(victim) then
                                    if IsEntityDead(victim) then
                                        local bot, botId, botTeam = Bot.IsEntityABot(victim)
                                        if bot then
                                            local botAttacker, botIdAttacker, botTeamAttacker = Bot.IsEntityABot(attacker)
                                            if botAttacker then
                                                Gm.KillHandler.HandleCooldown(victim)
                                                local weapon = args[7]
                                                local headshot = Gm.KillHandler.IsHeadshot(victim)

                                                Utils.TriggerGamemodeServerEvent("AddBotKillBot", botId, botTeam, botIdAttacker, botTeamAttacker, headshot, weapon)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
