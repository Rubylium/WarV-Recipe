GroupsData = { Players = {}, IsLeader = false }

function Lobby.ShowPopupMessage(title, message, cb)
    exports['warv-ui']:Notify("notice", {
        title = tostring(title or "NOTICE"),
        message = tostring(message or ""),
    })
    if cb then cb() end
end

RegisterNetEvent("Groups:DisplayPopupMessage", function(message, title)
    Lobby.ShowPopupMessage(title, message)
end)

RegisterNetEvent("groups:RefreshGroupData", function(isLeader, data)
    GroupsData.Players = data
    GroupsData.IsLeader = isLeader
end)
