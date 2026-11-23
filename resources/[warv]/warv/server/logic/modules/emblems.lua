Emblems = Unlocks.New({
    bucket = "emblems",
    entries = SharedConfig.emblems,
    selected = "logoId",
    event = "warv:EmblemProgress",
})

RegisterNetEvent("warv:GetEmblemProgress")
AddEventHandler("warv:GetEmblemProgress", function()
    Emblems.SendProgress(source)
end)
