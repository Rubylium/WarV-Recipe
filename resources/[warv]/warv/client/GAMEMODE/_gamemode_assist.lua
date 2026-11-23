Hitmarker = {}

local soundCooldown = false
local hits = 0

function Hitmarker.ShowHitmarker(kill)
    hits = hits + 1
    exports["warv-ui"]:HitMarker({ n = hits, kill = kill })

    if not soundCooldown then
        PlayCustomSound("assist_hitmarker.wav", Settings.hitMarkerVolume)
        soundCooldown = true
        GamemodeRuntime.CreateThread("hitmarkerSound", function()
            Utils.RealWait(50)
            soundCooldown = false
        end)
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        if GetEntityType(attacker) == 1 and GetEntityType(victim) == 1 then
            local playerPed = Gamemode.utils.GetPed()
            if playerPed == attacker then

                if playerPed ~= victim then
                    if GetEntityHealth(victim) <= 175 then
                        Gamemode.assist[victim] = 200 - GetEntityHealth(victim)
                    end
                end
            end

            if playerPed == victim and playerPed ~= attacker and Status.GetIsPlayerInGame() then
                local attackerPlayer = GetPlayerByEntityID(attacker)
                if attackerPlayer ~= nil then
                    Utils.TriggerGamemodeServerEvent(
                        "ReportCombatDamage",
                        "player",
                        GetPlayerServerId(attackerPlayer),
                        0,
                        GetEntityHealth(victim)
                    )
                else
                    local isBot, botId, botTeam = Bot.IsEntityABot(attacker)
                    if isBot then
                        Utils.TriggerGamemodeServerEvent(
                            "ReportCombatDamage",
                            "bot",
                            botId,
                            botTeam,
                            GetEntityHealth(victim)
                        )
                    end
                end
            end
        end
    end
end)


AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
            if Gamemode.utils.GetPed() == attacker then
                local kill = IsEntityDead(victim, 1) and true or false
                Hitmarker.ShowHitmarker(kill)
            end
    end
end)

function Gamemode.HandleKillAssist(gameID, killedName, killedId, killedIsBot)
    local victim
    if killedIsBot then
        victim = Bot.GetEntityById(killedId)
    elseif killedId ~= nil then
        local player = GetPlayerFromServerId(tonumber(killedId))
        if player ~= -1 then
            victim = GetPlayerPed(player)
        end
    end

    if victim == nil or victim == 0 then
        for _, player in pairs(GetActivePlayers()) do
            if GetPlayerName(player) == killedName then
                victim = GetPlayerPed(player)
                break
            end
        end
    end

    local assistPoints = victim ~= nil and Gamemode.assist[victim] or nil
    if assistPoints == nil then return end

    if assistPoints ~= 200 then
        Utils.TriggerGamemodeServerEvent("AssistKill", assistPoints)
        Score.AddScore(assistPoints, "Assist")
    end
    Gamemode.assist[victim] = nil
end

function GetPlayerByEntityID(id)
    for k,v in pairs(GetActivePlayers()) do
        if GetPlayerPed(v) == id then
            return v
        end
    end
    return nil
end
