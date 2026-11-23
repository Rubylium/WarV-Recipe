local function enterQueue(name)
    UiHandler.SetPageActive("matchmaking")
    Matchmaking.ClearMatchmakingData()
    TriggerServerEvent("warv:JoinMatchmaking", name, Matchmaking.ranked, Matchmaking.aimMode)
    PlayCustomSound("matchmaking_join.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.04, 0.05))
    Discord.SetState("matchmaking")
end

function MenuUI.actions.play()
    UiHandler.SetPageInactive("lobby")
    Matchmaking.aimMode = "TPP"
    TriggerServerEvent("warv:SetAimMode", "TPP")
    TriggerServerEvent("warv:LeaveAnyLobby")
    TriggerServerEvent("warv:GetLobbyData", false)
    Matchmaking.ranked = false
    UiHandler.SetPageActive("gamemodes_selection")
end

function MenuUI.actions.quickplay(payload)
    local name = payload.name
    if not name then return end
    if MenuUI.BlockNonLeader("start matchmaking") then return end
    MenuUI.Hide()
    UiHandler.SetPageInactive("lobby")
    Citizen.CreateThread(function()
        Matchmaking.aimMode = "TPP"
        TriggerServerEvent("warv:SetAimMode", "TPP")
        TriggerServerEvent("warv:LeaveAnyLobby")
        Matchmaking.ranked = MenuUI.GamemodeRanked(name)
        Wait(250)

        LobbyPlacement.LoadPlayerSkin()
        LobbyPlacement.StartCam()
        Lobby.SetClassCreationFromMenu("matchmaking")
        MenuUI.SetLoadoutTab("LOBBY")

        Lobby.selectedGamemode = name
        enterQueue(name)
    end)
end

function MenuUI.actions.join_gamemode(payload)
    local name = payload.name
    if not name then return end
    if MenuUI.BlockNonLeader("start matchmaking") then return end
    LobbyPlacement.LoadPlayerSkin()
    LobbyPlacement.StartCam()
    Lobby.SetClassCreationFromMenu("matchmaking")
    MenuUI.SetLoadoutTab("LOBBY")
    Lobby.selectedGamemode = name
    Matchmaking.ranked = MenuUI.GamemodeRanked(name)
    MenuUI.Hide()
    UiHandler.SetPageInactive("gamemodes_selection")
    enterQueue(name)
end

function MenuUI.actions.back_to_lobby()
    for _, p in ipairs(MenuUI.LobbyPages) do
        if p ~= "lobby" then UiHandler.SetPageInactive(p) end
    end
    UiHandler.SetPageActive("lobby")
end

function MenuUI.actions.browser()
    Menu.browserError = ""
    Menu.browserCooldown = false
    UiHandler.SetPageInactive("lobby")
    Lobby.SetPageToServerBrower()
    UiHandler.SetPageActive("ui_server_browser")
end

function MenuUI.actions.browser_join(payload)
    local id = payload.id
    if not id then return end
    local groupSize = (GroupsData.Players and #GroupsData.Players) or 0
    if groupSize > 1 then
        Menu.browserError = "Unavailable in a squad"
        Lobby.PushServerBrowser()
        return
    end
    if Menu.browserCooldown then return end
    Menu.browserCooldown = true
    MenuUI.SetLoadoutTab("LOBBY")
    TriggerServerEvent("warv:CanPlayerJoinMatchWithId", id)
end

function MenuUI.actions.browser_refresh()
    if Menu.current == "server_browser" then Lobby.PushServerBrowser() end
end

function MenuUI.actions.browser_dismiss_error()
    Menu.browserError = ""
    if Menu.current == "server_browser" then Lobby.PushServerBrowser() end
end

function MenuUI.actions.pick_spawn_class(payload)
    local key = tostring(payload.key or "")
    local kind, idx = key:match("^(%a)(%d+)$")
    idx = tonumber(idx)
    local cls
    if kind == "c" then
        cls = Class.customClass[idx]
    elseif kind == "p" then
        cls = SharedConfig.PreMadeClass[idx]
    end
    if cls then
        UiHandler.SetPageInactive("ui_class_selection")
        RemoveAllPedWeapons(Gamemode.utils.GetPed(), 1)
        Class.selected = cls
        MenuUI.Hide()
    end
end

function MenuUI.actions.vote_map(payload)
    local choice = tonumber(payload.choice)
    if choice and not Matchmaking.voted then
        Matchmaking.voted = true
        TriggerServerEvent("warv:VoteForMap", Status.GetCurrentGameId(), choice)
        Lobby.PushLobbyWait()
    end
end

function MenuUI.actions.mute_player(payload)
    if payload.id then
        Voice.MuteOrUnmute(payload.id)
        Lobby.PushLobbyWait()
    end
end

function MenuUI.actions.mm_change_class()
    MenuUI.HeaderAction("CHANGE CLASS")
    MenuUI.Hide()
end

function MenuUI.actions.mm_scorestreaks()
    Menu.killstreakOrigin = "matchmaking"
    MenuUI.HeaderAction("SCORESTREAKS")
    MenuUI.Hide()
end

function MenuUI.actions.leave_matchmaking()
    if MenuUI.BlockNonLeader("leave matchmaking") then return end
    if tonumber((Matchmaking.data or {}).gameWaitingToStartTimer or 0) > 5 and not Matchmaking.fadeIn then
        UiHandler.SetPageActive("gamemodes_selection")
        UiHandler.SetPageInactive("matchmaking")
        TriggerServerEvent("warv:GetLobbyData", Matchmaking.ranked)
        Voice.AddPlayerToVoiceLobby(Gamemode.utils.GetSID())
        PlayCustomSound("ui/leave.ogg",
            Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
        Discord.SetState("lobby")
        if Matchmaking.found then
            TriggerServerEvent("warv:LeaveLobby")
        else
            TriggerServerEvent("warv:LeaveMatchmaking")
        end
        Matchmaking.found = false
    end
end

function MenuUI.actions.classes()
    UiHandler.SetPageInactive("lobby")
    LobbyPlacement.StartCam()
    Data.GetClassData()
    Data.GetUnlockedContentData()
    Data.GetWeaponStatsData()
    Lobby.SetClassCreationFromMenu("lobby")
    UiHandler.SetPageActive("ui_class_creator_select")
end
