Player = {}
Player.Clone = nil
Player.inGame = false

function Player.GetName()
    return GetPlayerName(GetPlayerIndex())
end

function Player.GetPed()
    return PlayerPedId()
end

function Player.GetIndex()
    return GetPlayerIndex()
end

function Player.GetHealth()
    return GetEntityHealth(PlayerPedId())
end

function Player.GetPos()
    return GetEntityCoords(PlayerPedId())
end

function Player.GetServerId()
    return GetPlayerServerId(Player.GetIndex())
end

function Player.GetHeading()
    return GetEntityHeading(PlayerPedId())
end

function Player.SetClone(clone)
    Player.Clone = clone 
end

function Player.GetClone()
    return Player.Clone
end

function Player.Revive(ped)
    ped = ped or Player.GetPed()
    if ped == 0 or not DoesEntityExist(ped) then
        return
    end

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        if ped == Player.GetPed() then
            local pos = GetEntityCoords(ped)
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), 0, 0)
            ped = Player.GetPed()
        else
            ResurrectPed(ped)
        end
        SetEntityHealth(ped, math.max(GetEntityMaxHealth(ped), 200))
        ClearPedBloodDamage(ped)
        ResetPedRagdollTimer(ped)
    end

    ClearPedTasksImmediately(ped)
    SetEntityVisible(ped, true, false)
end

function Player.SetGodModStatus(status)
    SetEntityInvincible(Player.GetPed(), status)
end
