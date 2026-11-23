WeaponEditor.Header = {}
WeaponEditor.Header.Buttons = {}

function WeaponEditor.Header.SetupData()
    WeaponEditor.Header.Buttons = {
        {
            label = "BACK",
            draw = function()
                WeaponEditor.ForceUpdate()
                UiHandler.SetPageInactive("ui_class_creator_edit_accessories")
                UiHandler.SetPageActive("ui_class_creator_select")
                LobbyPlacement.SwitchToSecondCamAfterWeapon()
                LobbyWeapons.Clear()
                WeaponEditor.CurrentWeapon = Utils.Copy(WeaponEditor.Components.SelectedOldValue)
                TriggerServerEvent("warv:UpdateClass", Class.customClass)
            end,
            close = function()

            end,
        },
    }

    WeaponEditor.Header.current = nil
    WeaponEditor.Header.currentDraw = nil
    WeaponEditor.Header.currentLabel = ""
end

