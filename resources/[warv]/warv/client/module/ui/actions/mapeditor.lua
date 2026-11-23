function MenuUI.actions.mapedit_layer(payload)
    MapEditor.layer = tostring(payload.id or "")
    MapEditor.Push()
end

function MenuUI.actions.mapedit_select_map(payload)
    MapEditor.Open(tostring(payload.name or ""))
end

function MenuUI.actions.mapedit_create(payload)
    MapEditor.Create(payload.name)
end

function MenuUI.actions.mapedit_gamemode(payload)
    MapEditor.ToggleGamemode(tostring(payload.id or ""))
end

function MenuUI.actions.mapedit_delete()
    MapEditor.DeleteSelection()
end

function MenuUI.actions.mapedit_focus(payload)
    MapEditor.FocusPoint(tonumber(payload.index) or 0)
end

function MenuUI.actions.mapedit_delete_at(payload)
    MapEditor.DeleteAt(tonumber(payload.index) or 0)
end

function MenuUI.actions.mapedit_snap_ground(payload)
    MapEditor.SnapGroundAt(tonumber(payload.index) or 0)
end

function MenuUI.actions.mapedit_set_z(payload)
    MapEditor.SetBoundsZ(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.mapedit_rotate(payload)
    MapEditor.RotateSelection(tonumber(payload.delta) or 0)
end

function MenuUI.actions.mapedit_snap()
    MapEditor.SnapToPlayer()
end

function MenuUI.actions.mapedit_undo()
    MapEditor.Undo()
end

function MenuUI.actions.mapedit_save()
    MapEditor.Save()
end

function MenuUI.actions.mapedit_back()
    MapEditor.Back()
end

function MenuUI.actions.mapedit_set_env(payload)
    MapEditor.SetEnv(tostring(payload.field or ""), payload.value)
end

function MenuUI.actions.mapedit_hide(payload)
    MapEditor.HideUi(payload.seconds)
end

function MenuUI.actions.mapedit_close()
    MapEditor.Close()
end
