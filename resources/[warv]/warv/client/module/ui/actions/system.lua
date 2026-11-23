function MenuUI.actions.pause_resume()
    Lobby.displayPauseMenu = false
    UiHandler.SetPageInactive("ui_pause_menu")
    MenuUI.Hide()
end

function MenuUI.actions.pause_settings()
    Lobby.displayPauseMenu = false
    UiHandler.SetPageInactive("ui_pause_menu")
    MenuUI.Hide()
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, 6)
end

function MenuUI.actions.pause_leave()
    if MenuUI.BlockNonLeader("leave the match") then return end
    Lobby.displayPauseMenu = false
    UiHandler.SetPageInactive("ui_pause_menu")
    MenuUI.Hide()
    Status.SetIsPlayerInEndScreen(false)
    Gamemode.Playing = false
    Bot.EndGame()
    MapEnv.Lobby()
    LobbyPlacement.StopCam()
    Voice.AddPlayerToVoiceLobby(Gamemode.utils.GetSID())
    TriggerServerEvent("warv:LeaveSquadGame")
end

function MenuUI.actions.tab_map_editor()
    MapEditor.Enter()
end

function MenuUI.actions.tab_lobby()
    MenuUI.GoToTab("LOBBY")
end

function MenuUI.actions.tab_barracks()
    MenuUI.GoToTab("BARRACKS")
end

function MenuUI.actions.tab_settings()
    MenuUI.GoToTab("SETTINGS")
end

function MenuUI.actions.tab_leaderboard()
    MenuUI.SaveSettings()
    for _, p in ipairs(MenuUI.LobbyPages) do
        if p ~= "ui_leaderboard" then UiHandler.SetPageInactive(p) end
    end
    UiHandler.SetPageActive("ui_leaderboard")
end

function MenuUI.actions.leaderboard_category(payload)
    if payload.id then
        Menu.leaderboard = payload.id
        Lobby.PushLeaderboard()
    end
end

function MenuUI.actions.set_volume(payload)
    local cfg = MenuUI.Vol[payload.key]
    if cfg then
        local value = (tonumber(payload.percent) or 0) / 100 * cfg.max
        Settings[cfg.set](value)
        if payload.key == "musics" then
            Sounds.SetMusicVolume(value)
        end
    end
end

function MenuUI.actions.set_rankup(payload)
    if payload.id then
        Settings.RankupSound = payload.id
        RankUp.NewRankUp(Lobby.playerData.level or 1, Lobby.playerData.prestige or 0)
        Lobby.PushSettingsData()
    end
end

function MenuUI.actions.set_music(payload)
    if payload.id then
        Settings.SetLobbyTheme()
        Lobby.musicTheme = Settings.LobbyTheme
        StopAllSounds()
        PlayCustomSound(Lobby.musicTheme, Settings.MusicsVolume, true, true)
        Lobby.PushSettingsData()
    end
end

function MenuUI.actions.open_callingcards()
    UiHandler.SetPageInactive("ui_barracks")
    UiHandler.SetPageActive("ui_emblem_choose")
end

function MenuUI.actions.open_emblems()
    UiHandler.SetPageInactive("ui_barracks")
    UiHandler.SetPageActive("ui_logo_choose")
end

function MenuUI.actions.prestige()
    TriggerServerEvent("warv:TriggerPrestige")
end

function MenuUI.actions.select_card(payload)
    if payload.id then
        TriggerServerEvent("warv:UpdateEmblem", payload.id)
    end
    UiHandler.SetPageInactive("ui_emblem_choose")
    UiHandler.SetPageActive("ui_barracks")
end

function MenuUI.actions.select_emblem(payload)
    if payload.id then
        Lobby.playerData.logoId = payload.id
        Data.playerIcon = payload.id
        TriggerServerEvent("warv:UpdateLogo", payload.id)
    end
    UiHandler.SetPageInactive("ui_logo_choose")
    UiHandler.SetPageActive("ui_barracks")
end

function MenuUI.actions.select_back()
    UiHandler.SetPageInactive("ui_emblem_choose")
    UiHandler.SetPageInactive("ui_logo_choose")
    UiHandler.SetPageActive("ui_barracks")
end
