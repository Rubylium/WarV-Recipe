Loader = {}

function Loader.EnsureUiReady()
    local tries = 0
    while GetResourceState("warv-ui") ~= "started" and tries < 400 do
        Wait(50)
        tries = tries + 1
    end
    tries = 0
    while tries < 400 do
        local ok, mounted = pcall(function() return exports["warv-ui"]:IsMounted() end)
        if ok and mounted then break end
        Wait(50)
        tries = tries + 1
    end
end

function Loader.DrawUI()
    Loader.EnsureUiReady()
    local tries = 0
    while not pcall(function() exports["warv-ui"]:ShowLoading() end) and tries < 200 do
        Wait(50)
        tries = tries + 1
    end
    Citizen.CreateThread(function()
        while not Lobby.loaded do
            exports['warv-ui']:SetLoadingProgress(0, "LOADING GAME ASSETS")
            Wait(50)
        end
        exports['warv-ui']:SetLoadingProgress(100, "LOADING GAME ASSETS")
    end)
end


function Loader.StartWARVLoading()
    DoScreenFadeOut(100)

    Gamemode.utils.InitPlayerKillstreaks()
    Voice.AddPlayerToVoiceLobby(Gamemode.utils.GetSID())

    Loader.DrawUI()

    PlayCustomSound("loading_music/warv_StaticHorizon.mp3",
        Settings.GetScaledVolume(Settings.MusicsVolume, 0.03, 0.02))
    RealWait(1000)
    DoScreenFadeIn(300)

    if not WeaponsData.loaded then
        exports['warv-ui']:SetLoadingProgress(100, "LOADING WEAPON DATA")
        WeaponsData.Load()
    end

    DoScreenFadeOut(200)
    Utils.RealWait(500)
    Lobby.InitGamemode()
end

RegisterNetEvent("warv:Start", function()
    Loader.StartWARVLoading()
end)
