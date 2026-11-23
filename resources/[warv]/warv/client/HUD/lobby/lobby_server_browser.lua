local ServerBrowserPage = {}
ServerBrowserPage.displayingErrorMessage = false
ServerBrowserPage.errorMessage = "The server you are trying to join is full.\nPlease try an other server."
ServerBrowserPage.Buttons = {
    {
        label = "LOBBY",
        draw = function()
            UiHandler.SetPageInactive("ui_server_browser")
            UiHandler.SetPageActive("lobby")
        end,
    },
    {
        label = "SERVER BROWSER",
        draw = function()

        end,
    },
}
ServerBrowserPage.currentDraw = ServerBrowserPage.Buttons[2].draw
ServerBrowserPage.currentLabel = ServerBrowserPage.Buttons[2].label
ServerBrowserPage.minDisplay = 1
ServerBrowserPage.maxDisplay = 8
ServerBrowserPage.clickedCooldown = false

GlobalState.lobbys = {
}

function Lobby.SetPageToServerBrower()
    ServerBrowserPage.clickedCooldown = false
    ServerBrowserPage.currentDraw = ServerBrowserPage.Buttons[2].draw
    ServerBrowserPage.currentLabel = ServerBrowserPage.Buttons[2].label
end



RegisterNetEvent("browser:ShowErrorMessage")
AddEventHandler("browser:ShowErrorMessage", function(message)
    ServerBrowserPage.displayingErrorMessage = true
    ServerBrowserPage.errorMessage = message
    ServerBrowserPage.clickedCooldown = false
end)

RegisterNetEvent("browser:CloseBrowserUi")
AddEventHandler("browser:CloseBrowserUi", function()
    ServerBrowserPage.clickedCooldown = false
    UiHandler.SetPageInactive("ui_server_browser")
end)

RegisterNetEvent("browser:CloseBrowserAfterJoining")
AddEventHandler("browser:CloseBrowserAfterJoining", function(gamemode)
    ServerBrowserPage.clickedCooldown = false
    UiHandler.SetPageInactive("ui_server_browser")
    LobbyPlacement.LoadPlayerSkin()
    LobbyPlacement.StartCam()
    Lobby.SetClassCreationFromMenu("matchmaking")

    Lobby.selectedGamemode = gamemode
    UiHandler.SetPageInactive("gamemodes_selection")
    UiHandler.SetPageActive("matchmaking")
    Matchmaking.ClearMatchmakingData()
    Matchmaking.found = true

    PlayCustomSound("matchmaking_join.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.04, 0.05))
    Discord.SetState("matchmaking")
end)

