DeathAnim = {}
function DeathAnim.Play(killerName, killer)
    Spectate.Begin()
    if killer == nil or killer == 0 or not DoesEntityExist(killer) then
        killer = Player.GetPed()
    end

    local myPed = Player.GetPed()
    local dst = GetDistanceBetweenCoords(GetEntityCoords(myPed), GetEntityCoords(killer), true)

    local killerLevel, killerPrestige
    local killerPid = Match.IsKillerAPlayer(killer)
    if killerPid ~= nil then
        local sid = GetPlayerServerId(killerPid)
        for _, v in pairs(Gamemode.PlayersData) do
            if tonumber(v.id) == tonumber(sid) then
                killerLevel, killerPrestige = v.level, v.prestige or 0
                break
            end
        end
    else
        local isBot, botId = Bot.IsEntityABot(killer)
        local prof = isBot and Bot.GetProfile(botId) or nil
        if prof then killerLevel, killerPrestige = prof.level, prof.prestige or 0 end
    end

    local _, dmgBone = GetPedLastDamageBone(myPed)
    DamageLog.MarkFinal(killer ~= myPed and killer or nil)

    Gamemode.deathInfo = {
        killer = killerName or "",
        respawnMs = Spectate.DeathMs(),
        weaponHash = GetPedCauseOfDeath(myPed),
        distance = math.floor(dst + 0.5),
        headshot = (dmgBone == 31086),
        killerLevel = killerLevel,
        killerPrestige = killerPrestige or 0,
    }
    UiHandler.SetPageActive("ui_death")

    Medals.Death(killerName or "0")
    cam.create("DEATH")
    Class.ResetIndex()
    WeaponBack.RemoveWeaponFromBack()

    local fovToUse = 15.0
    local lookAtPos = GetOffsetFromEntityInWorldCoords(killer, 0.0, 0.0, 1.0)
    local camPos = GetGameplayCamCoord()

    fovToUse = fovToUse - dst * 0.4
    if fovToUse < 5.0 then
        fovToUse = 5.0
    end

    if GetInteriorAtCoords(lookAtPos) ~= GetInteriorAtCoords(camPos) then
        camPos = GetEntityCoords(Gamemode.utils.GetPed(), 0)
    end

    cam.setPos("DEATH", vector3(camPos.x, camPos.y, camPos.z))
    cam.lookAtEntity("DEATH", killer, {0.0, 0.0, 0.5})
    cam.setFov("DEATH", fovToUse)

    cam.setActive("DEATH", true)
    cam.render("DEATH", true, true, 500)

    DeathSound.HandleDeathSound()

    Spectate.Hold(Spectate.killcamMs)
end
