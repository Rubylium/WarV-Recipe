Protection = {}
function Protection.ApplyProtectionToPed(ped)
    SetEntityVisible(ped, false, 1)
    SetEntityInvincible(ped, true)
end

function Protection.RemoveProtectionFromPed(ped)
    SetEntityVisible(ped, true, 1)
    SetEntityInvincible(ped, false)
end
