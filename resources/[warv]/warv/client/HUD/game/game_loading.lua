local LoadingDone = false
local loadTry = 0
local showcaseStarted = false
local showcaseAt = 0

local phase = "loading"
local assetPct = 0
local waitingText = ""
local shownAt = 0
local lastKey = ""
local minLoadingMs = 2500
local showcaseMs = 4000

Lobby._matchLoadingDirty = false

local soloGamemodes = { FFA = true, ["GUN GAME"] = true, ["ONE IN THE CHAMBER"] = true }
function Lobby.MatchGamemodeHasTeams(name)
    name = string.upper(tostring(name or ""))
    local def = GamemodeDefinitions.Get(name)
    if def then return def.capabilities.teams == true end
    return not soloGamemodes[name]
end

function Lobby.ResetLoadingScreenData()
    HudV2.Reset()
    LoadingDone = false
    loadTry = 0
    showcaseStarted = false
    showcaseAt = 0
    phase = "loading"
    assetPct = 0
    waitingText = ""
    shownAt = 0
    lastKey = ""
    Lobby._matchLoadingDirty = true
    UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
end

local function fastLoadTimeoutKick()
    Gamemode.RemoveMapBounds()
    Utils.TriggerGamemodeServerEvent("PlayerLeave")
    GamemodeRuntime.Stop("load_cancelled")
    TriggerServerEvent("warv:LeaveAnyLobby")

    Lobby.ShowPopupMessage("Error", "Sorry. The server you are trying to reach has refused your client.\nPlease do not modify your FiveM / GTA files in any way.\nThis will prevent the connection to the WarV game servers.\n(" .. GetNumResources() .. ")", function()
        GamemodeRuntime.Stop("load_cancelled")
        TriggerServerEvent("warv:LeaveAnyLobby")
        Lobby.SetLobbyData()

        UiHandler.SetPageInactive("ui_class_selection")
        UiHandler.SetPageInactive("ui_class_creator_select")
        UiHandler.SetPageInactive("ui_class_creator_edit_accessories")
        UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
        UiHandler.SetPageInactive("ui_edit_killstreaks")
    end)
end

function Lobby.MapLoadingTick()
    if shownAt == 0 then shownAt = GetGameTimer() end

    local m = Matchmaking.selectedMap
    if m == nil or m.name == nil or m.name == "DEBUG" then
        Matchmaking.selectedMap = m or {}
        m = Matchmaking.selectedMap
        m.name = "DEBUG"
        m.description = "This is a debug description for a map loading!"
        m.spritePreview = "map_construct"
        m.uiImage = "construct"

        MapLoader.maxAsset = 100
        MapLoader.currentAsset = MapLoader.currentAsset + 0.1
        if MapLoader.currentAsset > MapLoader.maxAsset then
            MapLoader.currentAsset = 0
        end
    end

    local pct = 0
    if MapLoader.maxAsset > 0 then
        pct = math.floor((MapLoader.currentAsset / MapLoader.maxAsset) * 100)
    end
    if pct > 100 then pct = 100 end
    assetPct = pct

    local assetsReady = MapLoader.currentAsset >= MapLoader.maxAsset
    local minElapsed = (GetGameTimer() - shownAt) >= minLoadingMs

    if assetsReady and minElapsed then
        if Lobby.displayMapLoadingScreenFastLoad then
            if not LoadingDone then
                LoadingDone = true
                phase = "waiting"
                Utils.TriggerGamemodeServerEvent("PlayerLoadedIntoGame")
            else
                loadTry = loadTry + 1
                if loadTry > 1000 then
                    loadTry = 0
                    fastLoadTimeoutKick()
                end
            end
        else
            if not showcaseStarted then
                showcaseStarted = true
                phase = "waiting"
                showcaseAt = GetGameTimer()
                Citizen.CreateThread(function()
                    LoadAnimation.StartLoadAnimation()
                end)
            end
            if not LoadingDone and (GetGameTimer() - showcaseAt) >= showcaseMs then
                LoadingDone = true
                Utils.TriggerGamemodeServerEvent("PlayerLoadedIntoGame")
            end
        end
    end

    if not LoadingDone then
        waitingText = ""
    elseif Lobby.displayMapLoadingScreenFastLoad then
        waitingText = "Syncing players"
    else
        waitingText = "Waiting for players"
    end

    local key = phase .. "|" .. assetPct .. "|" .. waitingText .. "|" .. tostring(Matchmaking.currentTip)
    if key ~= lastKey then
        lastKey = key
        Lobby._matchLoadingDirty = true
    end

    if not UiHandler.IsPageActive("ui_class_selection") then
        DisableAllControlActions(0)
    end
end

function Lobby.GetMatchLoadingWebState()
    local m = Matchmaking.selectedMap or {}
    local gm = Matchmaking.data.gamemode or Lobby.selectedGamemode
    return {
        map = {
            name = string.upper(tostring(m.name or "")),
            image = tostring(m.uiImage or m.spritePreview or ""),
        },
        gamemode = (string.upper(tostring(gm or "")):gsub("~%a~", "")),
        ranked = Matchmaking.ranked == true,
        teamMode = Lobby.MatchGamemodeHasTeams(gm),
        phase = phase,
        progress = assetPct,
        waitingText = waitingText,
        tip = tostring(Matchmaking.currentTip or ""),
    }
end
