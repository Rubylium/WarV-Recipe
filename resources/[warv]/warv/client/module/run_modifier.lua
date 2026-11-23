Citizen.CreateThread(function()
    while true do
        ResetPlayerStamina(PlayerId(), true)
        SetPedConfigFlag(Gamemode.utils.GetPed(), 427, true)
        Wait(500)
    end
end)