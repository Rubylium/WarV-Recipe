function MenuUI.actions.select_class(payload)
    local idx = tonumber(payload.index)
    if idx and Class.customClass[idx] then
        ClasseCreation.ClassSelected = Class.customClass[idx]
        Class.editingIndex = idx
        PlayersDisplay.SyncMyWeapon()
        Lobby.PushClassSelect()
    end
end

function MenuUI.actions.rename_class(payload)
    local idx = tonumber(payload.index)
    local name = payload.name
    if idx and name and Class.customClass[idx] then
        name = (tostring(name):gsub("~%a~", "")):sub(1, 24)
        if name:gsub("%s", "") ~= "" then
            Class.customClass[idx].name = name
            PlayCustomSound("menu_click.ogg",
                Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.02, 0.05))
            TriggerServerEvent("warv:UpdateClass", Class.customClass)
            Lobby.PushClassSelect()
        end
    end
end

function MenuUI.actions.class_change_weapon(payload)
    if not (Class.editingIndex and ClasseCreation.ClassSelected ~= 0) then return end
    local slot = payload.slot
    local editType = (slot == "primary" and 1) or (slot == "secondary" and 2) or (slot == "extra" and 3) or nil
    if not editType then return end
    Class.editType = editType
    WeapSelectionHeader.SetupHeaderButtons()
    UiHandler.SetPageInactive("ui_class_creator_select")
    UiHandler.SetPageActive("ui_class_creator_edit_weapon")
end

function MenuUI.actions.class_customize(payload)
    if not (Class.editingIndex and ClasseCreation.ClassSelected ~= 0) then return end
    local slot = payload.slot
    if slot ~= "primary" and slot ~= "secondary" then return end
    local sel = ClasseCreation.ClassSelected
    Menu.attachPreview = nil
    LobbyWeapons.Build(slot)
    PlayersDisplay.editedRef = { classIdx = Class.editingIndex, slot = slot }
    PlayersDisplay.SyncMyWeapon()
    WeaponEditor.Components.RefreshFunction = LobbyWeapons.SyncComps
    WeaponEditor.Components.PreviewCache = {}
    WeaponEditor.Components.EditPrimary = slot == "primary"
    WeaponEditor.CurrentWeapon = sel.weapons[slot].comps
    WeaponEditor.Components.SelectedOldValue = Utils.Copy(sel.weapons[slot].comps)
    WeaponEditor.Header.SetupData()
    UiHandler.SetPageInactive("ui_class_creator_select")
    UiHandler.SetPageActive("ui_class_creator_edit_accessories")
    LobbyPlacement.SwitchToWeaponCamAfterSecond()
end

function MenuUI.actions.weapon_pick(payload)
    if not (Class.editingIndex and Class.customClass[Class.editingIndex]) then return end
    local model = payload.weapon
    if not model or model == "" then return end
    local cls = Class.customClass[Class.editingIndex]
    local slot = MenuUI.EditSlot[Class.editType or 1]
    if not (slot and cls.weapons and cls.weapons[slot]) then return end
    cls.weapons[slot].weapon = model
    cls.weapons[slot].comps = {}
    UiHandler.SetPageActive("ui_class_creator_select")
    UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
    PlayCustomSound("ui/weapon_equip.ogg",
        Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
    TriggerServerEvent("warv:UpdateClass", Class.customClass)
    PlayersDisplay.SyncMyWeapon()
end

function MenuUI.actions.weapon_picker_back()
    UiHandler.SetPageActive("ui_class_creator_select")
    UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
end

function MenuUI.actions.class_scorestreaks()
    Menu.killstreakOrigin = "class_editor"
    MenuUI.HeaderAction("SCORESTREAKS")
end

function MenuUI.actions.equip_killstreak(payload)
    local slot = tonumber(payload.slot)
    local ktype = payload.type
    if slot and ktype and Gamemode.activeKillstreak[slot] and SharedConfig.Killstreaks[ktype] then
        local dup = false
        for i, v in ipairs(Gamemode.activeKillstreak) do
            if i ~= slot and v.type == ktype then dup = true break end
        end
        if not dup then
            Gamemode.activeKillstreak[slot].type = ktype
            Gamemode.activeKillstreak[slot].kills = SharedConfig.Killstreaks[ktype].kill
            Gamemode.utils.SortKillstreaks()
            KillStreakUI.RefreshActiveKS()
            local db = rockdb:new()
            db:SaveTable("KILLSTREAKS", Gamemode.activeKillstreak)
            PlayCustomSound("ui/weapon_equip.ogg",
                Settings.GetScaledVolume(Settings.interfaceSoundVolume, 0.03, 0.05))
            Lobby.PushKillstreakEditor()
        end
    end
end

function MenuUI.actions.ks_back()
    if Menu.killstreakOrigin == "class_editor" then
        MenuUI.HeaderAction("CHANGE CLASS")
    else
        LobbyPlacement.SwitchToFirstCam()
        UiHandler.SetPageInactive("ui_edit_killstreaks")
        UiHandler.SetPageActive("matchmaking")
        MenuUI.SetLoadoutTab("LOBBY")
    end
    Menu.killstreakOrigin = nil
end

function MenuUI.actions.death_change_class()
    if not Match.loadout then return end
    UiHandler.SetPageActive("ui_class_selection")
    UiHandler.SetPageInactive("ui_death")
end

function MenuUI.actions.death_respawn()
    Spectate.RequestRespawn()
end

function MenuUI.actions.class_back()
    LobbyWeapons.Clear()
    LobbyPlacement.LoadPlayerSkin()
    LobbyPlacement.SwitchToFirstCamAfterSkinCam()
    UiHandler.SetPageInactive("ui_class_creator_select")
    if Lobby.GetClassCreationFromMenu() == "lobby" then
        UiHandler.SetPageActive("lobby")
    else
        UiHandler.SetPageActive("matchmaking")
    end
end
