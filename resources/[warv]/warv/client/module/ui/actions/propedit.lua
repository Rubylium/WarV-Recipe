function MenuUI.actions.propedit_select_map(payload)
    PropEditor.Open(payload.name)
end

function MenuUI.actions.propedit_create(payload)
    PropEditor.Create(payload.name)
end

function MenuUI.actions.propedit_delete_map(payload)
    PropEditor.DeleteMap(payload.name)
end

function MenuUI.actions.propedit_back()
    PropEditor.Back()
end

function MenuUI.actions.propedit_close()
    PropEditor.Close()
end

function MenuUI.actions.propedit_save()
    PropEditor.Save()
end

function MenuUI.actions.propedit_undo()
    PropEditor.Undo()
end

function MenuUI.actions.propedit_add(payload)
    PropEditor.Add(payload.model)
end

function MenuUI.actions.propedit_focus(payload)
    PropEditor.Focus(tonumber(payload.index) or 0)
end

function MenuUI.actions.propedit_grab()
    PropEditor.Grab()
end

function MenuUI.actions.propedit_gizmo()
    PropEditor.Gizmo()
end

function MenuUI.actions.propedit_duplicate()
    PropEditor.Duplicate()
end

function MenuUI.actions.propedit_delete()
    PropEditor.Delete()
end

function MenuUI.actions.propedit_ground()
    PropEditor.Ground()
end

function MenuUI.actions.propedit_rotate(payload)
    PropEditor.Rotate(tostring(payload.axis or "z"), tonumber(payload.delta) or 0)
end

function MenuUI.actions.propedit_set(payload)
    PropEditor.SetField(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_delete_at(payload)
    PropEditor.DeleteAt(tonumber(payload.index) or 0)
end

function MenuUI.actions.propedit_ped(payload)
    PropEditor.SetPed(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_vehicle(payload)
    PropEditor.SetVehicle(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_rgb(payload)
    PropEditor.SetRgb(tostring(payload.group or ""), tostring(payload.channel or ""), payload.value)
end

function MenuUI.actions.propedit_mod(payload)
    PropEditor.SetMod(tonumber(payload.id) or 0, tonumber(payload.value) or -1)
end

function MenuUI.actions.propedit_toggle(payload)
    PropEditor.ToggleSlot(tostring(payload.list or "toggles"), tonumber(payload.id) or 0, payload.on == true)
end

function MenuUI.actions.propedit_restore(payload)
    PropEditor.Restore(tonumber(payload.index) or 0)
end

function MenuUI.actions.propedit_fav_selection()
    PropEditor.FavoriteSelection()
end

function MenuUI.actions.propedit_fav_add(payload)
    PropEditor.AddFavorite(tostring(payload.model or ""), payload.label)
    PropEditor.Push()
end

function MenuUI.actions.propedit_fav_rename(payload)
    PropEditor.RenameFavorite(tonumber(payload.index) or 0, payload.label)
    PropEditor.Push()
end

function MenuUI.actions.propedit_fav_delete(payload)
    PropEditor.RemoveFavorite(tonumber(payload.index) or 0)
    PropEditor.Push()
end

function MenuUI.actions.propedit_history_clear()
    PropEditor.ClearHistory()
    PropEditor.Push()
end

function MenuUI.actions.propedit_lobby_toggle()
    PropEditor.LobbyToggle()
end

function MenuUI.actions.propedit_lobby_place(payload)
    PropEditor.LobbyPlace(tostring(payload.id or ""))
end

function MenuUI.actions.propedit_lobby_select(payload)
    PropEditor.LobbySelect(tostring(payload.id or ""))
end

function MenuUI.actions.propedit_lobby_add_slot()
    PropEditor.LobbyAddSlot()
end

function MenuUI.actions.propedit_lobby_remove_slot(payload)
    PropEditor.LobbyRemoveSlot(tonumber(payload.index) or 0)
end

function MenuUI.actions.propedit_lobby_pose(payload)
    PropEditor.LobbyPose(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_lobby_cam(payload)
    PropEditor.LobbyCam(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_lobby_env(payload)
    PropEditor.LobbyEnv(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.propedit_lobby_preview(payload)
    PropEditor.LobbyPreview(tostring(payload.key or ""))
end

function MenuUI.actions.propedit_typing(payload)
    PropEditor.typing = payload.on == true
end
