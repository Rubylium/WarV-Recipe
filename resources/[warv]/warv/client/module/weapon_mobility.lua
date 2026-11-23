WeaponMobility = {}

local rateByWeapon = {}

function WeaponMobility.SetRate(weaponModel, rate)
    rate = math.max(0.85, math.min(1.15, rate))
    rateByWeapon[weaponModel] = rate ~= 1.0 and rate or nil
end

function WeaponMobility.Clear()
    rateByWeapon = {}
end

Citizen.CreateThread(function()
    while true do
        local ped = Gamemode.utils.GetPed()
        local rate = rateByWeapon[WeaponRegistry.GetNameFromHash(GetSelectedPedWeapon(ped))]
        if rate then
            SetPedMoveRateOverride(ped, rate)
            Wait(0)
        else
            Wait(200)
        end
    end
end)
