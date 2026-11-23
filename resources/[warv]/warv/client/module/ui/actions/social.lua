function MenuUI.actions.friend_add(payload)
    if payload.id then TriggerServerEvent("warv:AddFriend", payload.id) end
end

function MenuUI.actions.friend_accept(payload)
    if payload.id then TriggerServerEvent("warv:AcceptFriend", payload.id) end
end

function MenuUI.actions.friend_remove(payload)
    if payload.id then TriggerServerEvent("warv:DeclineFriend", payload.id) end
end

function MenuUI.actions.friend_block(payload)
    if payload.id then TriggerServerEvent("warv:BlockPlayer", payload.id) end
end

function MenuUI.actions.friend_unblock(payload)
    if payload.id then TriggerServerEvent("warv:UnblockPlayer", payload.id) end
end

function MenuUI.actions.friend_invite(payload)
    if payload.id then TriggerServerEvent("groups:SendInviteToPlayer", payload.id) end
end

function MenuUI.actions.friend_join(payload)
    if payload.id then TriggerServerEvent("warv:JoinFriend", payload.id) end
end

function MenuUI.actions.friend_hide(payload)
    TriggerServerEvent("warv:SetAppearOffline", payload.hidden == true)
end

function MenuUI.actions.squad_invite(payload)
    if MenuUI.BlockNonLeader("invite players") then return end
    local inviteId = tonumber(payload.id)
    if inviteId ~= nil then TriggerServerEvent("groups:SendInviteToPlayer", inviteId) end
end

function MenuUI.actions.squad_accept(payload)
    local inviteId = tostring(payload.inviteId or "")
    if inviteId ~= "" then
        MenuUI.RemoveSquadInvite(inviteId)
        MenuUI.Refresh()
        TriggerServerEvent("groups:AcceptInvite", inviteId)
    end
end

function MenuUI.actions.squad_refuse(payload)
    local inviteId = tostring(payload.inviteId or "")
    if inviteId ~= "" then
        MenuUI.RemoveSquadInvite(inviteId)
        MenuUI.Refresh()
        TriggerServerEvent("groups:RefuseInvite", inviteId)
    end
end

function MenuUI.actions.squad_kick(payload)
    if MenuUI.BlockNonLeader("remove squad members") then return end
    if payload.id then TriggerServerEvent("groups:KickPlayer", payload.id) end
end

function MenuUI.actions.squad_leave()
    TriggerServerEvent("groups:Leave")
end
