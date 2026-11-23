local function gunsmithDof()
    local cam = LobbyCam.Get()
    if not (cam and DoesCamExist(cam)) then return end

    local dist = LobbyPlacement.weaponFocusDist or 1.2
    local half = (LobbyPlacement.weaponFocusDepth or 0.2) * 0.5
    SetUseHiDof()
    SetCamDofStrength(cam, 1.0)
    SetCamNearDof(cam, math.max(0.05, dist - half - 0.18))
    SetCamFarDof(cam, dist + half + 0.12)
    SetCamDofFnumberOfLens(cam, 1.2)
    SetCamDofMaxNearInFocusDistance(cam, 1.0)
    SetCamDofMaxNearInFocusDistanceBlendLevel(cam, 1.0)
    SetCamUseShallowDofMode(cam, true)
end

local function matchmakingDof()
    local cam = LobbyCam.Get()
    if not (cam and DoesCamExist(cam)) then return end

    local dist = #(LobbyCam.look - GetCamCoord(cam))
    SetUseHiDof()
    SetCamDofStrength(cam, 1.0)
    SetCamNearDof(cam, math.max(0.1, dist - 2.0))
    SetCamFarDof(cam, dist + 2.0)
    SetCamUseShallowDofMode(cam, true)
end

MenuUI.Screens = {
    menu = {
        blur = true,
        page = "lobby",
        priority = 10,
        push = Lobby.PushMenuData,
        enter = function()
            TriggerServerEvent("warv:GetLobbyData", false)
            Lobby.PushFriends()
            Lobby.PushChallenges()
        end,
        open = function() exports['warv-ui']:ShowMainMenu() end,
    },
    lobby_wait = {
        page = "matchmaking",
        priority = 10,
        push = Lobby.PushLobbyWait,
        enter = function() Data.GetStatsData() end,
        open = function() exports['warv-ui']:ShowLobbyWait() end,
        tick = function()
            Lobby.LockControls()
            matchmakingDof()
        end,
    },
    gamemode_select = {
        blur = true,
        page = "gamemodes_selection",
        priority = 40,
        push = Lobby.PushGamemodeData,
        enter = function() TriggerServerEvent("warv:GetLobbyData", false) end,
        open = function() exports['warv-ui']:ShowGamemodeSelect() end,
    },
    server_browser = {
        blur = true,
        page = "ui_server_browser",
        priority = 40,
        push = Lobby.PushServerBrowser,
        open = function() exports['warv-ui']:ShowServerBrowser() end,
    },
    barracks = {
        blur = true,
        page = "ui_barracks",
        priority = 40,
        push = Lobby.PushBarracksData,
        open = function() exports['warv-ui']:ShowBarracks() end,
    },
    leaderboard = {
        blur = true,
        page = "ui_leaderboard",
        priority = 40,
        push = Lobby.PushLeaderboard,
        open = function() exports['warv-ui']:ShowLeaderboard() end,
    },
    settings = {
        blur = true,
        page = "settings",
        priority = 45,
        push = Lobby.PushSettingsData,
        open = function() exports['warv-ui']:ShowSettings() end,
    },
    card = {
        blur = true,
        page = "ui_emblem_choose",
        priority = 50,
        push = Lobby.PushCardSelect,
        open = function() exports['warv-ui']:ShowCardSelect() end,
    },
    emblem = {
        blur = true,
        page = "ui_logo_choose",
        priority = 50,
        push = Lobby.PushEmblemSelect,
        open = function() exports['warv-ui']:ShowEmblemSelect() end,
    },
    class_editor = {
        blur = true,
        page = "ui_class_creator_select",
        priority = 60,
        push = Lobby.PushClassSelect,
        enter = function() MenuUI.EnsureClassSelected() end,
        open = function() exports['warv-ui']:ShowClassEditor() end,
    },
    weapon_picker = {
        blur = true,
        page = "ui_class_creator_edit_weapon",
        priority = 70,
        push = Lobby.PushWeaponPicker,
        open = function() exports['warv-ui']:ShowWeaponPicker() end,
    },
    killstreak_editor = {
        blur = true,
        page = "ui_edit_killstreaks",
        priority = 70,
        push = Lobby.PushKillstreakEditor,
        open = function() exports['warv-ui']:ShowKillstreakEditor() end,
    },
    attach_editor = {
        page = "ui_class_creator_edit_accessories",
        priority = 80,
        push = Lobby.PushAttachEditor,
        open = function() exports['warv-ui']:ShowAttachEditor() end,
        tick = function()
            gunsmithDof()
            Gunsmith.Update()
        end,
    },
    map_editor = {
        page = "ui_map_editor",
        priority = 86,
        push = MapEditor.Push,
        open = function() exports['warv-ui']:ShowMapEditor() end,
    },
    prop_editor = {
        page = "ui_prop_editor",
        priority = 87,
        push = PropEditor.Push,
        open = function() exports['warv-ui']:ShowPropEditor() end,
    },
    death = {
        page = "ui_death",
        priority = 88,
        push = Lobby.PushDeath,
        open = function() exports['warv-ui']:ShowDeath() end,
    },
    class_pick = {
        page = "ui_class_selection",
        priority = 90,
        push = Lobby.PushClassPick,
        open = function() exports['warv-ui']:ShowClassPick() end,
    },
    clothing_creator = {
        page = "ui_clothing_creator",
        priority = 91,
        push = ClothingCreator.Push,
        open = function() exports['warv-ui']:ShowClothingCreator() end,
    },
    pause = {
        page = "ui_pause_menu",
        priority = 95,
        open = function() exports['warv-ui']:ShowPause() end,
    },
    match_loading = {
        page = "map_loading",
        priority = 100,
        push = Lobby.PushMatchLoading,
        open = function() exports['warv-ui']:ShowMatchLoading() end,
        tick = function()
            Lobby.MapLoadingTick()
            if Lobby._matchLoadingDirty then
                Lobby._matchLoadingDirty = false
                Lobby.PushMatchLoading()
            end
        end,
    },
}

for _, def in pairs(MenuUI.Screens) do
    UiHandler.Register(def.page)
end
