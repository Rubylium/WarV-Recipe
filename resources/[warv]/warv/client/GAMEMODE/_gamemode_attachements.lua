Attach = {}

local function applyComps(ped, weapon, comps)
    if not (weapon and weapon ~= "" and type(comps) == "table") then return end
    local weaponHash = GetHashKey(weapon)
    WeaponComponentVisuals.ApplyToPed(ped, weaponHash, comps)
    WeaponAttachmentStats.ApplyForWeapon(weapon, comps)
end

function Attach.LoadAttachForClass()
    if Class.selected and Class.selected.weapons ~= nil then
        local ped = Player.GetPed()
        applyComps(ped, Class.selected.weapons.primary.weapon, Class.selected.weapons.primary.comps)
        applyComps(ped, Class.selected.weapons.secondary.weapon, Class.selected.weapons.secondary.comps)
        WeaponAttachmentStats.ApplyForWeapon(Class.selected.weapons.primary.weapon, Class.selected.weapons.primary.comps)
    end
end

function Attach.LoadAttachForClassFromLobby()
    local self = ClasseCreation.ClassSelected
    if self == 0 or type(self) ~= "table" or not self.weapons then return end
    local ped = Player.GetPed()
    applyComps(ped, self.weapons.primary.weapon, self.weapons.primary.comps)
    applyComps(ped, self.weapons.secondary.weapon, self.weapons.secondary.comps)
end
