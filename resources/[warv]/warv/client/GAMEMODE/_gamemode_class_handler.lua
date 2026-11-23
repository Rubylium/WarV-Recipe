Class = {}
Class.selected = {}
Class.lockedControl = {1,2,3,4,5,6,24}
Class.selectedIndex = 1
Class.OldselectedIndex = 1
Class.editingIndex = 1 
Class.editType = 1
Class.camoEditType = 1
Class.editSelectedWeaponType = 1
Class.customClass = {}
Class.cachedAmmoCount = {
    [1] = -1,
    [2] = -1,
    [3] = -1,
}
Class.inCooldown = false
Class.switchAllowed = 1

function Class.ResetIndex()
    Class.selectedIndex = 1
    Class.cachedAmmoCount = {
        [1] = -1,
        [2] = -1,
        [3] = -1,
    }
end

Citizen.CreateThread(function()
    while Lobby == nil do
        Wait(1)
    end
    function Lobby.ResetSelectedClass()
        Class.selected = {}
    end
end)

function Class.handleCooldown(weapon)
    if not Class.inCooldown then
        Class.inCooldown = true
        Class.switchAllowed = 1
        local time = GetWeaponTimeBetweenShots(weapon) * 1000
        Citizen.CreateThread(function()
            RealWait(time)
            Class.inCooldown = false
            Class.switchAllowed = 1
        end)
    end

end

function Class.HandleControl()

    if Class.inCooldown == false or Class.switchAllowed ~= 0 then
        if IsDisabledControlJustReleased(0, 157) or IsControlJustReleased(0, 157) then
            local _, weapon = GetCurrentPedWeapon(Gamemode.utils.GetPed(), 1)
            local _, ammoClip = GetAmmoInClip(Gamemode.utils.GetPed(), weapon)
            Class.cachedAmmoCount[Class.selectedIndex] = ammoClip
    
            Class.OldselectedIndex = Class.selectedIndex
            Class.selectedIndex = 1
            Class.SetWeaponBasedOnIndex()
            if Class.inCooldown then
                Class.switchAllowed = 0
            end
        elseif IsDisabledControlJustReleased(0, 158) or IsControlJustReleased(0, 158) then
            local _, weapon = GetCurrentPedWeapon(Gamemode.utils.GetPed(), 1)
            local _, ammoClip = GetAmmoInClip(Gamemode.utils.GetPed(), weapon)
            Class.cachedAmmoCount[Class.selectedIndex] = ammoClip
    
            Class.OldselectedIndex = Class.selectedIndex
            Class.selectedIndex = 2
            Class.SetWeaponBasedOnIndex()
            if Class.inCooldown then
                Class.switchAllowed = 0
            end
        elseif IsDisabledControlJustReleased(0, 160) or IsControlJustReleased(0, 160) then
            local _, weapon = GetCurrentPedWeapon(Gamemode.utils.GetPed(), 1)
            local _, ammoClip = GetAmmoInClip(Gamemode.utils.GetPed(), weapon)
            Class.cachedAmmoCount[Class.selectedIndex] = ammoClip
    
            Class.OldselectedIndex = Class.selectedIndex
            Class.selectedIndex = 3
            Class.SetWeaponBasedOnIndex()
            if Class.inCooldown then
                Class.switchAllowed = 0
            end
        end
    end

end

function Class.SetWeaponBasedOnIndex()
    if Class.selected.weapons ~= nil then
        local selectedWeapon
        if Class.selectedIndex == 1 then 
            if Class.selected.weapons.primary ~= nil then
                selectedWeapon = Class.selected.weapons.primary
                WeaponBack.SetupWeaponBack(GetHashKey(Class.selected.weapons.secondary.weapon))
                SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), true)
                if Class.cachedAmmoCount[Class.selectedIndex] ~= -1 then
                    SetAmmoInClip(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), Class.cachedAmmoCount[Class.selectedIndex])
                end
            end
        elseif Class.selectedIndex == 2 then
            if Class.selected.weapons.secondary ~= nil then
                selectedWeapon = Class.selected.weapons.secondary
                WeaponBack.SetupWeaponBack(GetHashKey(Class.selected.weapons.primary.weapon))
                SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), true)
                if Class.cachedAmmoCount[Class.selectedIndex] ~= -1 then
                    SetAmmoInClip(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), Class.cachedAmmoCount[Class.selectedIndex])
                end
            end
        elseif Class.selectedIndex == 3 then
            if Class.selected.weapons.extra ~= nil then
                selectedWeapon = Class.selected.weapons.extra
                if Class.selected.weapons.extra.weapon ~= "" then
                    SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.extra.weapon), true)
                    if Class.cachedAmmoCount[Class.selectedIndex] ~= -1 then
                        SetAmmoInClip(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.extra.weapon), Class.cachedAmmoCount[Class.selectedIndex])
                    end
                end
            end
        end
        if selectedWeapon then
            WeaponAttachmentStats.ApplyForWeapon(selectedWeapon.weapon, selectedWeapon.comps)
        end
    end
end
