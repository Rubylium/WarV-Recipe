WeapSelectionHeader = {}
WeapSelectionHeader.Buttons = {
    {
        label = "BACK",
        draw = function()
            
            UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
            UiHandler.SetPageActive("ui_class_creator_select")
        end,
        close = function()
            
        end,
    },
}
WeapSelectionHeader.currentDraw = WeapSelectionHeader.Buttons[1].draw
WeapSelectionHeader.currentLabel = "NONE"
WeapSelectionHeader.current = WeapSelectionHeader.Buttons[1]

function WeapSelectionHeader.ResetCurrent()
    WeapSelectionHeader.currentDraw = WeapSelectionHeader.Buttons[1].draw
    WeapSelectionHeader.currentLabel = "NONE"
    WeapSelectionHeader.current = WeapSelectionHeader.Buttons[1]
end

function WeapSelectionHeader.SetupHeaderButtons()
    WeapSelectionHeader.ResetCurrent()
    WeapSelectionHeader.Buttons = {
        {
            label = "BACK",
            draw = function()
                Lobby.ResetWeaponSelectionMaxAndMin()
                UiHandler.SetPageInactive("ui_class_creator_edit_weapon")
                UiHandler.SetPageActive("ui_class_creator_select")
            end,
            close = function()
                
            end,
        },
    }

    local weaponsList = {}
    if Class.editType == 1 then
        weaponsList = SharedConfig.weapons.main
    elseif Class.editType == 2 then
        weaponsList = SharedConfig.weapons.secondary
    elseif Class.editType == 3 then
        weaponsList = SharedConfig.weapons.extra
    end

    for k,v in pairs(weaponsList) do
        table.insert(WeapSelectionHeader.Buttons, { 
            label = v.label,
            draw = function()
                Lobby.ResetWeaponSelectionMaxAndMin()
                Class.editSelectedWeaponType = k
            end,
            close = function()
                
            end,
        })
    end
end

