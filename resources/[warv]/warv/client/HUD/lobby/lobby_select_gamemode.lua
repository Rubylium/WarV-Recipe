
RegisterNetEvent("groups:PlayJoinSound")
AddEventHandler("groups:PlayJoinSound", function()
    PlayCustomSound("group/member_join.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.06, 0.05))
end)

RegisterNetEvent("groups:PlayLeaveSound")
AddEventHandler("groups:PlayLeaveSound", function()
    PlayCustomSound("group/member_leave.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.06, 0.05))
end)

RegisterNetEvent("groups:SendBackToWait")
AddEventHandler("groups:SendBackToWait", function()
    UiHandler.CloseAllPages()
    UiHandler.SetPageActive("gamemodes_selection")
end)

RegisterNetEvent("groups:JoinMatchmaking")
AddEventHandler("groups:JoinMatchmaking", function(gamemode)
    LobbyPlacement.LoadPlayerSkin()
    LobbyPlacement.StartCam()

    Lobby.selectedGamemode = gamemode
    Lobby.SetClassCreationFromMenu("matchmaking")
    UiHandler.CloseAllPages()
    UiHandler.SetPageActive("matchmaking")
    Matchmaking.ClearMatchmakingData()

    PlayCustomSound("matchmaking_join.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.04, 0.05))
    Discord.SetState("matchmaking")
end)
