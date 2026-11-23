Lobby = {}
Lobby.loaded = false
Lobby.defaultPosition = vector3(354.90518188477, 4839.4897460938, -58.999450683594)
Lobby.playerData = {}
Lobby.playerLevel = "1"
Lobby.playerPrestige = 0


Lobby.displayPlayPrivate = false
Lobby.displayMapLoadingScreenFastLoad = false

UiHandler.SetPageInactive("ui_pause_menu")

Lobby.selectedGamemode = "TEAM DEATHMATCH"
Lobby.gamemodeLobby = {}
Lobby.playersPerGamemode = {}
Lobby.possibleMusic = 2
Lobby.matchmaking = {}
Lobby.matchmaking.gameFound = false

function Lobby.SetLobbyData()
    HudV2.Reset()
    AnimpostfxStopAll()
    SetTimeScale(1.0)
    Player.Revive()
    Gamemode.isDead = false
    StartAudioScene("MP_MENU_SCENE")
    while rockdb == nil do
        Wait(1)
    end
    PlayCustomSound(Settings.LobbyTheme, Settings.MusicsVolume, true, true)

    LobbyPlacement.StopCam()
    ClearTimecycleModifier()
    RemoveAllPedWeapons(Gamemode.utils.GetPed(), 0)
    LobbyLayout.Apply()
    LobbyLayout.PlaceSelf()
    SetPlayerInvincible(GetPlayerIndex(), true)
    SendNuiMessage(json.encode({hideInGameHud = true}))
    DisplayRadar(false)

    Protection.RemoveProtectionFromPed(Gamemode.utils.GetPed())

end

function Lobby.InitGamemode()
    LobbyLayout.Apply()
    PlayersDisplay.InitPoses()
    LobbyLayout.PlaceSelf()
    Sheets.LoadSpriteSheets()
    Gamemode.StartMinimap()
    Gm.Ipls.Load()

    Lobby.loaded = true
    while Gamemode == nil do
        Wait(0)
    end
    TriggerEvent("warv:gm_loaded")

    LobbyPlacement.LoadPlayerSkin()
    MapEnv.Lobby()
    StopAllSounds()
    Lobby.SetLobbyData()
    LobbyPlacement.StartCam()

    DoScreenFadeIn(0)
    RealWait(900)

    PlayCustomSound("ui/boot.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
    UiHandler.SetPageActive("lobby")

    if not Data.FirstLoaded then
        TriggerServerEvent("warv:Init")
        Data.FirstLoaded = true
    end
end



Citizen.CreateThread(function()
    while true do
        for k,v in pairs(SharedConfig.Tips) do
            Matchmaking.currentTip = v
            Wait(5000)
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        if Matchmaking.found then
            if Matchmaking.data.gameWaitingToStart and Matchmaking.data.gameCanStart then
                if Matchmaking.data.gameWaitingToStartTimer - 1 >= 0 then
                    Matchmaking.data.gameWaitingToStartTimer = Matchmaking.data.gameWaitingToStartTimer - 1

                    if Matchmaking.data.gameWaitingToStartTimer <= 5 then
                        PlayCustomSound("countdown_tick.ogg",
                            Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.01, 0.05))
                    end
                end
            end
            Utils.RealWait(1000)
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent("warv:SendPlayerBackToLobbyAfterTakingTooLongToLoad")
AddEventHandler("warv:SendPlayerBackToLobbyAfterTakingTooLongToLoad", function(gameId)

    GamemodeRuntime.Stop("load_timeout")

    TriggerServerEvent("warv:LeaveAnyLobby")

    DoScreenFadeOut(300)
    Wait(300)
    StopAllSounds()
    UiHandler.CloseAllPages()
    UiHandler.SetPageActive("lobby")
    WeaponBack.RemoveWeaponFromBack()

    Lobby.ShowPopupMessage("KICKED FROM LOBBY", "You could not sync with other player.")
    Lobby.SetLobbyData()
    Discord.SetState("lobby")
    DoScreenFadeIn(1000)
end)


RegisterNetEvent("warv:GoBackToLobby")
AddEventHandler("warv:GoBackToLobby", function(gameId)

    GamemodeRuntime.Stop("return_to_lobby")

    DoScreenFadeOut(300)
    Wait(300)
    StopAllSounds()
    UiHandler.CloseAllPages()
    UiHandler.SetPageActive("lobby")
    Discord.SetState("lobby")
    WeaponBack.RemoveWeaponFromBack()

    LobbyPlacement.StopCam()
    DestroyAllCams(false)
    Lobby.SetLobbyData()
    DoScreenFadeIn(1000)
    LobbyPlacement.StartCam()
end)


RegisterNetEvent("warv:GetLobbyData")
AddEventHandler("warv:GetLobbyData", function(data, data2)
    Lobby.gamemodeLobby = data
    Lobby.playersPerGamemode = data2
end)
