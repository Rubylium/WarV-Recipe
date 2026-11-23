Pause = {}

function Pause.HandleMenuToogle()
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)

    if IsDisabledControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 200) and not Lobby.displayMapLoadingScreen then
        Lobby.displayPauseMenu = not Lobby.displayPauseMenu
        if Lobby.displayPauseMenu then
            UiHandler.SetPageActive("ui_pause_menu")
        else
            UiHandler.SetPageInactive("ui_pause_menu")
        end
    end
end
