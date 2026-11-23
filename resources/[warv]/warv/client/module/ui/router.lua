local blurred = false
local blurFade = 250

function MenuUI.SetBlur(on)
    if on == blurred then return end
    blurred = on
    if on then
        TriggerScreenblurFadeIn(blurFade)
    else
        TriggerScreenblurFadeOut(blurFade)
    end
end

local function apply(screen)
    if Menu.current == screen then return end
    local def = MenuUI.Screens[screen]
    if not def then return end

    Menu.current = screen
    MenuUI.SetBlur(def.blur == true)
    if def.enter then def.enter() end
    if def.push then def.push() end
    def.open()
end

local function topScreen()
    local best, bestPriority = nil, -1

    local current = Menu.current and MenuUI.Screens[Menu.current]
    if current and UiHandler.IsPageActive(current.page) then
        best, bestPriority = Menu.current, current.priority
    end

    for screen, def in pairs(MenuUI.Screens) do
        if def.priority > bestPriority and UiHandler.IsPageActive(def.page) then
            best, bestPriority = screen, def.priority
        end
    end
    return best
end

function MenuUI.PushCurrent()
    local def = Menu.current and MenuUI.Screens[Menu.current]
    if def and def.push then def.push() end
end

function MenuUI.SaveSettings()
    if Menu.current == "settings" then
        Settings.SaveAllSettings()
    end
end

function MenuUI.Hide()
    MenuUI.SaveSettings()
    MenuUI.SetBlur(false)
    if Menu.current then
        Menu.current = nil
        exports['warv-ui']:HideUI()
    end
end

function Lobby.ResetWebState()
    Menu.current = nil
end

function Lobby.RefreshWebScreen()
    local screen = Menu.current
    Menu.current = nil
    if screen then
        apply(screen)
    else
        exports['warv-ui']:HideUI()
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        for _, def in pairs(MenuUI.Screens) do
            if def.tick and UiHandler.IsPageActive(def.page) then def.tick() end
        end

        local screen = topScreen()
        if screen then
            apply(screen)
        elseif Menu.current then
            MenuUI.Hide()
        end
    end
end)

MenuUI.LobbyPages = { "lobby", "gamemodes_selection", "ui_server_browser", "ui_barracks", "settings", "ui_emblem_choose", "ui_logo_choose", "ui_leaderboard", "ui_clothing_creator" }
local loadoutTabs = {
    ["LOBBY"] = {
        open = function()
            LobbyPlacement.LoadPlayerSkin()
            LobbyPlacement.SwitchToFirstCamAfterSkinCam()
            UiHandler.SetPageInactive("ui_class_creator_select")
            if Lobby.GetClassCreationFromMenu() == "lobby" then
                UiHandler.SetPageActive("lobby")
            else
                UiHandler.SetPageActive("matchmaking")
            end
        end,
        close = function()
            UiHandler.SetPageInactive("matchmaking")
        end,
    },
    ["CHANGE CLASS"] = {
        open = function()
            Data.GetClassData()
            Data.GetUnlockedContentData()
            Data.GetWeaponStatsData()
            UiHandler.SetPageActive("ui_class_creator_select")
        end,
        close = function()
            Citizen.CreateThread(function() LobbyWeapons.Clear() end)
            LobbyPlacement.SwitchToFirstCam()
            UiHandler.SetPageInactive("ui_class_creator_select")
        end,
    },
    ["SCORESTREAKS"] = {
        open = function()
            KillStreakUI.RefreshActiveKS()
            LobbyPlacement.SwitchToSecondCam()
            KillStreakUI.Clicked = false
            UiHandler.SetPageActive("ui_edit_killstreaks")
        end,
        close = function()
            LobbyPlacement.SwitchToFirstCam()
            UiHandler.SetPageInactive("ui_edit_killstreaks")
        end,
    },
}

local loadoutTab = "LOBBY"

function MenuUI.SetLoadoutTab(label)
    loadoutTab = label
end

function MenuUI.HeaderAction(label)
    local tab = loadoutTabs[label]
    if not tab then return end

    local previous = loadoutTabs[loadoutTab]
    if previous then previous.close() end
    tab.open()
    loadoutTab = label
end

local lobbyTabs = {
    ["LOBBY"] = function()
        UiHandler.SetPageActive("lobby")
    end,
    ["BARRACKS"] = function()
        Data.GetStatsData()
        Data.GetUnlockedContentData()
        UiHandler.SetPageActive("ui_barracks")
    end,
    ["SETTINGS"] = function()
        UiHandler.SetPageInactive("lobby")
        UiHandler.SetPageActive("settings")
    end,
}

function MenuUI.GoToTab(label)
    MenuUI.SaveSettings()
    for _, p in ipairs(MenuUI.LobbyPages) do
        UiHandler.SetPageInactive(p)
    end
    local open = lobbyTabs[label]
    if open then open() end
end
