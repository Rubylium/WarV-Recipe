CallingCards = Unlocks.New({
    bucket = "callingCards",
    entries = SharedConfig.callingCards,
    selected = "emblemsId",
    event = "warv:CallingCardProgress",
})

RegisterNetEvent("warv:GetCallingCardProgress")
AddEventHandler("warv:GetCallingCardProgress", function()
    CallingCards.SendProgress(source)
end)
