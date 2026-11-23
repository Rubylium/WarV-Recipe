function MenuUI.actions.attach_edit_toggle()
    if (tonumber(Lobby.playerData.perm) or 0) < 3 then return end
    Menu.attachPreview = nil
    Gunsmith.SetEditing(not Gunsmith.editing)
    Lobby.PushAttachEditor()
end

function MenuUI.actions.attach_edit_reset(payload)
    if (tonumber(Lobby.playerData.perm) or 0) < 3 or not Gunsmith.editing then return end
    local slot = tostring(payload.slot or "")
    if slot == "" then Gunsmith.ResetOffset() else Gunsmith.ResetAnchor(slot) end
end

function MenuUI.actions.attach_preview(payload)
    if payload.type and payload.type ~= "tint" then
        Menu.attachPreview = {
            type = tostring(payload.type),
            model = tostring(payload.model or ""),
        }
        Lobby.PushAttachEditor()
    end
end

function MenuUI.actions.attach_preview_clear()
    Menu.attachPreview = nil
    Lobby.PushAttachEditor()
end

function MenuUI.actions.attach_set(payload)
    local ed = WeaponEditor
    if not (payload.type and ClasseCreation.ClassSelected ~= 0) then return end
    Menu.attachPreview = nil
    local sel = ClasseCreation.ClassSelected
    local wslot = ed.Components.EditPrimary and sel.weapons.primary or sel.weapons.secondary
    local comps = wslot.comps
    if payload.type == "tint" then
        comps.tint = tonumber(payload.index)
    else
        local model = payload.model
        if model == nil or model == "" then
            comps[payload.type] = nil
        else
            if MenuUI.SlotIsCapped(wslot.weapon, comps, payload.type) then return end
            comps[payload.type] = model
        end
    end
    ed.Components.RefreshFunction()
    ed.Components.SelectedOldValue[payload.type] = comps[payload.type]
    TriggerServerEvent("warv:UpdateClass", Class.customClass)
    PlayersDisplay.SyncMyWeapon()
    Lobby.PushAttachEditor()
end

function MenuUI.actions.gunsmith_reset()
    Gunsmith.Reset()
end

function MenuUI.actions.gunsmith_spin(payload)
    Gunsmith.Spin(tonumber(payload.dir) or 1)
end

function MenuUI.actions.attach_back()
    Menu.attachPreview = nil
    Gunsmith.Stop()
    WeaponEditor.ForceUpdate()
    UiHandler.SetPageInactive("ui_class_creator_edit_accessories")
    UiHandler.SetPageActive("ui_class_creator_select")
    LobbyPlacement.SwitchToSecondCamAfterWeapon()
    LobbyWeapons.Clear()
    WeaponEditor.CurrentWeapon = Utils.Copy(WeaponEditor.Components.SelectedOldValue)
    TriggerServerEvent("warv:UpdateClass", Class.customClass)
end
