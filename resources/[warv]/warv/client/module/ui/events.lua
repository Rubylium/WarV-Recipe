function MenuUI.Refresh()
    if Menu.current then MenuUI.PushCurrent() end
end
RegisterNetEvent("warv:RefreshPlayerData", MenuUI.Refresh)
RegisterNetEvent("warv:RefreshUnlockedContent", MenuUI.Refresh)
RegisterNetEvent("warv:GetStatsData", function()
    if Menu.current == "barracks" then Lobby.PushBarracksData() end
end)
RegisterNetEvent("warv:GetLobbyData", function()
    if Menu.current == "menu" then Lobby.PushMenuData()
    elseif Menu.current == "gamemode_select" then Lobby.PushGamemodeData() end
end)

RegisterNetEvent("browser:ShowErrorMessage", function(message)
    Menu.browserCooldown = false
    Menu.browserError = tostring(message or "")
    if Menu.current == "server_browser" then Lobby.PushServerBrowser() end
end)
RegisterNetEvent("browser:CloseBrowserUi", function()
    Menu.browserCooldown = false
end)
RegisterNetEvent("browser:CloseBrowserAfterJoining", function()
    Menu.browserCooldown = false
    Menu.browserError = ""
    MenuUI.Hide()
end)
AddStateBagChangeHandler("lobbys", "global", function()
    if Menu.current == "server_browser" then Lobby.PushServerBrowser() end
end)

RegisterNetEvent("warv:RefreshLobbyData", function()
    if Menu.current == "lobby_wait" then Lobby.PushLobbyWait() end
end)
RegisterNetEvent("warv:MatchmakingGetData", function()
    if Menu.current == "lobby_wait" then Lobby.PushLobbyWait() end
end)
RegisterNetEvent("warv:GetClassData", function()
    Citizen.SetTimeout(50, function()
        if Menu.current == "class_editor" then
            MenuUI.EnsureClassSelected()
            Lobby.PushClassSelect()
        end
    end)
end)
Citizen.CreateThread(function()
    while true do
        Wait(150)
        if Menu.current == "lobby_wait" then Lobby.PushLobbyWait() end
    end
end)
Citizen.CreateThread(function()
    while true do
        Wait(400)
        if Menu.current == "attach_editor" then Lobby.PushAttachEditor() end
    end
end)
RegisterNetEvent("groups:RefreshGroupData", function(isLeader, data)
    Menu.squad.isLeader = isLeader
    Menu.squad.members = data or {}
    MenuUI.Refresh()
end)

function MenuUI.RemoveSquadInvite(inviteId)
    local targetId = tostring(inviteId or "")
    if targetId == "" then return false end

    for index = #Menu.squad.invites, 1, -1 do
        if tostring(Menu.squad.invites[index].inviteId) == targetId then
            table.remove(Menu.squad.invites, index)
            return true
        end
    end
    return false
end

RegisterNetEvent("groups:SendInvite", function(data)
    if type(data) ~= "table" then
        data = { inviteId = data }
    end

    local inviteId = tostring(data.inviteId or "")
    if inviteId == "" then return end

    local level = tonumber(data.level) or 1
    local prestige = tonumber(data.prestige) or 0
    MenuUI.RemoveSquadInvite(inviteId)
    Menu.squad.invites[#Menu.squad.invites + 1] = {
        inviteId = inviteId,
        uid = tonumber(data.uid) or 0,
        name = tostring(data.name or "Player"),
        level = level,
        prestige = prestige,
        rankIcon = GetRankIcon(level, prestige) or ("rank_" .. level),
    }
    MenuUI.Refresh()
end)

RegisterNetEvent("groups:RemoveInvite", function(inviteId)
    if MenuUI.RemoveSquadInvite(inviteId) then
        MenuUI.Refresh()
    end
end)

RegisterNetEvent("groups:ClearInvites", function()
    Menu.squad.invites = {}
    MenuUI.Refresh()
end)
