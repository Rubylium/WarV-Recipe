
Citizen.CreateThread(function()
    exports.spawnmanager.spawnPlayer()
    StartAudioScene("MP_MENU_SCENE")
    TriggerEvent("loading:finish")
    DoScreenFadeOut(0)
    Loader.StartWARVLoading()
end)

