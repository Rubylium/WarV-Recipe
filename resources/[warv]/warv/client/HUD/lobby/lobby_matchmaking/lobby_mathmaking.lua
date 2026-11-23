Matchmaking = {}
Matchmaking.selectedMap = {}
Matchmaking.found = false
Matchmaking.data = {}
Matchmaking.data.players = {}
Matchmaking.currentTip = ""
Matchmaking.voted = false
Matchmaking.ranked = false
Matchmaking.aimMode = "FPP"
Matchmaking.lockedControls = {
    14, 16, 15, 17, 30, 31, 32, 33, 34, 35, 59, 60, 61, 62, 63, 64, 266, 267, 268, 269, 278, 279, 280, 281, 69, 70, 92, 114, 121, 140, 141, 142, 257, 263, 264, 331, 24, 25, 50, 68, 91
}
Matchmaking.fadeIn = false

function Matchmaking.SetupPlayerDisplay()
    local i = #Matchmaking.data.players
    local max = Matchmaking.data.maxPlayer
    if max == nil then
        max = 9
    end


    for i = 1, max - i do
        table.insert(Matchmaking.data.players, {id = 0, uid = 0, level = "", name = "Looking for players"})
    end
end

function Matchmaking.ClearMatchmakingData()
    Matchmaking.data.players = {}
    Matchmaking.found = false
    table.insert(Matchmaking.data.players, {id = GetPlayerServerId(GetPlayerIndex()), uid = 0, level = Lobby.playerData.level or 0, prestige = Lobby.playerPrestige, ranking = Lobby.playerData.ranking or 0, name = "~y~"..GetPlayerName(GetPlayerIndex())})

    local max = Matchmaking.data.maxPlayer
    if max == nil then
        max = 9
    end
    for i = 1,max do
        table.insert(Matchmaking.data.players, {id = 0, uid = 0, level = "", name = "Looking for players"})
    end
end

function Lobby.LockControls()
    for k,v in pairs(Matchmaking.lockedControls) do
        DisableControlAction(0, v, true)
    end
end





RegisterNetEvent("warv:RefreshLobbyData")
AddEventHandler("warv:RefreshLobbyData", function(data)

    Matchmaking.data = data
    Status.SetCurrentGameId(data.gameId)
    Matchmaking.selectedMap = SharedConfig.Maps[data.gameMap]

    if Matchmaking.found == false then
        ClearPedBloodDamage(Gamemode.utils.GetPed())
        Voice.AddPlayerToVoiceLobby(Matchmaking.data.gameBucket)
        if not EndScreen.InAnimation then
            PlayCustomSound("ui/match_found.ogg",
                Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
        end
    end

    Voice.HandleLobbyVolume(Matchmaking.data.players)

    Matchmaking.SetupPlayerDisplay()
    if Matchmaking.found == false then
        Matchmaking.voted = false
    end
    Matchmaking.found = true

    if not EndScreen.InAnimation and not data.gameStarted or Lobby.displayMapLoadingScreen then
        LobbyPlacement.StartCam()
        PlayersDisplay.SetupPlayersClones()
        Discord.SetState("matchmaking")
        PlayCustomSound("matchmaking_found.ogg",
            Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
    else
        Discord.SetState("playing")
    end
end)

RegisterNetEvent("warv:LobbyLeft", function()
    Status.SetCurrentGameId(0)
    Matchmaking.data = {players = {}}
    Matchmaking.selectedMap = {}
    Matchmaking.found = false
end)

RegisterNetEvent("warv:StartGame")
AddEventHandler("warv:StartGame", function(fastLoad, sessionData)
    local ok, err = GamemodeRuntime.Prepare(sessionData)
    if not ok then
        Console.CriticalPrint("gamemode prepare: " .. tostring(err))
        TriggerServerEvent("warv:LeaveAnyLobby")
        return
    end
    Matchmaking.fadeIn = true
    Utils.RealWait(500)

    if not Data.AlreadyLoadClassOne then
        Data.GetClassData()
        Data.GetUnlockedContentData()
        Data.GetWeaponStatsData()
    end

    StopAllSounds()
    DoScreenFadeOut(1000)
    Utils.RealWait(1000)
    PlayCustomSound("loading_music/warv_StaticHorizon.mp3", Settings.MusicsVolume)

    PlayersDisplay.RemoveAllClones()
    Lobby.ResetLoadingScreenData()
    MapLoader.LoadMapAssets(Matchmaking.data.gameMap)
    TriggerScreenblurFadeOut(0)
    LobbyPlacement.StopCam()

    Gamemode.IsPlayerBeingSyncChecked = false
    UiHandler.CloseAllPages()
    WeaponBack.RemoveWeaponFromBack()
    UiHandler.SetPageActive("map_loading")

    for v in EnumeratePeds() do
        SetEntityAlpha(v, 255, 0)
    end

    if UiHandler.IsPageActive("ui_server_browser") then
        UiHandler.SetPageInactive("ui_server_browser")
    end

    if fastLoad then
        Lobby.displayMapLoadingScreenFastLoad = true
    else
        Lobby.displayMapLoadingScreenFastLoad = false
    end

    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoordsNoOffset(PlayerPedId(), Matchmaking.selectedMap.middleMapPos, false, false, false)
    SetEntityVisible(PlayerPedId(), false, false)
    SetPlayerInvincible(GetPlayerIndex(), true)

    if not GamemodeRuntime.Start(fastLoad) then
        TriggerServerEvent("warv:LeaveAnyLobby")
        return
    end

    Discord.SetState("playing")
    Utils.RealWait(1000)
    DoScreenFadeIn(3500)
    Matchmaking.fadeIn = false
end)
