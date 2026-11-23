WeaponEditor.Components = {}
WeaponEditor.Components.EditPrimary = false
WeaponEditor.Components.RefreshFunction = function()

end
WeaponEditor.Components.PreviewCache = {}
WeaponEditor.Components.SelectedOldValue = {}

function WeaponEditor.ForceUpdate()
    if WeaponEditor.Components.EditPrimary then
        ClasseCreation.ClassSelected.weapons.primary.comps = Utils.Copy(WeaponEditor.Components.SelectedOldValue)
    else
        ClasseCreation.ClassSelected.weapons.secondary.comps = Utils.Copy(WeaponEditor.Components.SelectedOldValue)
    end
    WeaponEditor.Components.RefreshFunction(true)
end

