ClassWeapons = {}
function ClassWeapons.GiveWeaponFromSelectedClass()
    if Match.GiveWeapons then
        Match.GiveWeapons()
        return
    end

    Citizen.CreateThread(function()
        while Class.selected.weapons == nil or UiHandler.IsPageActive("ui_class_selection") do
            Wait(1)
        end

        RequestWeaponAsset(GetHashKey(Class.selected.weapons.primary.weapon), 31, 0)
        RequestWeaponAsset(GetHashKey(Class.selected.weapons.secondary.weapon), 31, 0)
        RequestWeaponAsset(GetHashKey(Class.selected.weapons.extra.weapon), 31, 0)

        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), 255)


        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), 255)

        while Class.selected.weapons ~= nil and not IsPedArmed(Gamemode.utils.GetPed(), 4) do
            RequestWeaponAsset(GetHashKey(Class.selected.weapons.primary.weapon), 31, 0)
            RequestWeaponAsset(GetHashKey(Class.selected.weapons.secondary.weapon), 31, 0)
            RequestWeaponAsset(GetHashKey(Class.selected.weapons.extra.weapon), 31, 0)

            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), 255, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), 255)

            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), 255, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.secondary.weapon), 255)

            SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), true)
            Wait(100)
        end

        Attach.LoadAttachForClass()

        if Class.selected.weapons.extra.weapon ~= "" then
            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.extra.weapon), Class.selected.weapons.extra.ammo, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.extra.weapon), Class.selected.weapons.extra.ammo)
        end


        SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(Class.selected.weapons.primary.weapon), true)
    end)
end

function ClassWeapons.GiveWeaponFromSelectedClassFromLobby()
    Citizen.CreateThread(function()
        local self = Class.customClass[Class.editingIndex]

        RequestWeaponAsset(GetHashKey(self.weapons.primary.weapon), 31, 0)
        RequestWeaponAsset(GetHashKey(self.weapons.secondary.weapon), 31, 0)
        RequestWeaponAsset(GetHashKey(self.weapons.extra.weapon), 31, 0)

        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255)


        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255)

        while self.weapons ~= nil and not IsPedArmed(Gamemode.utils.GetPed(), 4) do
            RequestWeaponAsset(GetHashKey(self.weapons.primary.weapon), 31, 0)
            RequestWeaponAsset(GetHashKey(self.weapons.secondary.weapon), 31, 0)
            RequestWeaponAsset(GetHashKey(self.weapons.extra.weapon), 31, 0)

            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255)

            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255)

            SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), true)
            Wait(0)
        end

        Attach.LoadAttachForClassFromLobby()

        if self.weapons.extra.weapon ~= "" then
            GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.extra.weapon), self.weapons.extra.ammo, 0, 1)
            SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.extra.weapon), self.weapons.extra.ammo)
        end


        SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), true)
    end)
end

function ClassWeapons.GivePrimaryWeaponFromSelectedClassFromLobby()
    RemoveAllPedWeapons(Gamemode.utils.GetPed(), 0)
    local self = Class.customClass[Class.editingIndex]

    RequestWeaponAsset(GetHashKey(self.weapons.primary.weapon), 31, 0)

    GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255, 0, 1)
    SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255)

    while self.weapons ~= nil and not IsPedArmed(Gamemode.utils.GetPed(), 4) do
        RequestWeaponAsset(GetHashKey(self.weapons.primary.weapon), 31, 0)

        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), 255)
        Wait(0)
    end

    Attach.LoadAttachForClassFromLobby()
    SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(self.weapons.primary.weapon), true)
end


function ClassWeapons.GiveSecondaryWeaponFromSelectedClassFromLobby()
    RemoveAllPedWeapons(Gamemode.utils.GetPed(), 0)
    local self = Class.customClass[Class.editingIndex]
    RequestWeaponAsset(GetHashKey(self.weapons.secondary.weapon), 31, 0)

    GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255, 0, 1)
    SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255)

    while self.weapons ~= nil and not IsPedArmed(Gamemode.utils.GetPed(), 4) do
        RequestWeaponAsset(GetHashKey(self.weapons.secondary.weapon), 31, 0)

        GiveWeaponToPed(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255, 0, 1)
        SetPedAmmo(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), 255)

        Wait(0)
    end
    Attach.LoadAttachForClassFromLobby()

    SetCurrentPedWeapon(Gamemode.utils.GetPed(), GetHashKey(self.weapons.secondary.weapon), true)
end