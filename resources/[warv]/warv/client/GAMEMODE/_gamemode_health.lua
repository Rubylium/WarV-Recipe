Health = {}
Health.Alpha = 0
Health.AlphaToUse = 0
Health.damaged = false
Health.Check = 0
Health.LastHealthChecked = 0


function Health.HandleRegen(isDead)
    if not Health.damaged and not isDead then
        local pPed = Player.GetPed()
        local pHealth = GetEntityHealth(pPed) + 5
        if pHealth > SharedConfig.healthGate then
            pHealth = SharedConfig.healthGate
        end

        SetEntityHealth(pPed, pHealth)
        SetEntityMaxHealth(pPed, SharedConfig.healthGate)
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    end
end


Citizen.CreateThread(function()
    while true do
        local pPed = Player.GetPed()
        local pHealth = GetEntityHealth(pPed)
        if Health.LastHealthChecked ~= pHealth and pHealth < Health.LastHealthChecked and not Gamemode.isDead and Player.inGame and Match.displayInGameHud then
            Sounds.PlaySound("ui/hit_feedback/armor_hit_0"..math.random(1,5)..".ogg",
                Settings.hitMarkerVolume, false)
            Health.damaged = true
            Health.Check = 0
        else
            if Health.Check > 4 then
                Health.damaged = false
            else
                Health.Check = Health.Check + 1
            end
        end
        Health.LastHealthChecked = pHealth
        Utils.RealWait(500)
    end
end)

Health.lastBloodPct = -1

function Health.HandleBloodScreen()
    local alpha = 0
    if not Gamemode.isDead then
        local h = GetEntityHealth(Player.GetPed())
        local top = SharedConfig.healthGate
        local bottom = 101
        if top > bottom then
            alpha = (top - h) / (top - bottom)
            if alpha < 0 then alpha = 0 elseif alpha > 1 then alpha = 1 end
        end
    end

    local pct = math.floor(alpha * 100)
    if pct ~= Health.lastBloodPct then
        Health.lastBloodPct = pct
        exports['warv-ui']:SetBlood(pct / 100)
    end
end


