WeaponComponentVisuals = {}

function WeaponComponentVisuals.IsFinish(slot, componentModel)
    if slot == "finish" or slot == "finishSlide" then return true end
    return tostring(componentModel or ""):upper():find("_VARMOD_", 1, true) ~= nil
end

function WeaponComponentVisuals.GetObjectCustomModelHash(comps)
    local componentModel = comps and comps.finish
    if type(componentModel) ~= "string" or componentModel == "" then return 0 end
    return GetWeaponComponentTypeModel(GetHashKey(componentModel)) or 0
end

local function componentBefore(a, b)
    local aPriority = a.slot == "finishSlide" and 2 or 1
    local bPriority = b.slot == "finishSlide" and 2 or 1
    if aPriority ~= bPriority then return aPriority < bPriority end
    return a.model < b.model
end

function WeaponComponentVisuals.Split(comps)
    local regular, finishes = {}, {}
    for slot, componentModel in pairs(comps or {}) do
        if slot ~= "camo" and slot ~= "tint" and not WeaponsData.VirtualComponents[componentModel]
            and type(componentModel) == "string" and componentModel ~= "" then
            local entry = { slot = slot, model = componentModel }
            if WeaponComponentVisuals.IsFinish(slot, componentModel) then
                finishes[#finishes + 1] = entry
            else
                regular[#regular + 1] = entry
            end
        end
    end
    table.sort(regular, componentBefore)
    table.sort(finishes, componentBefore)
    return regular, finishes
end

function WeaponComponentVisuals.ApplyToPed(ped, weaponHash, comps)
    if not (ped and weaponHash) then return end
    local regular, finishes = WeaponComponentVisuals.Split(comps)

    SetPedWeaponTintIndex(ped, weaponHash, tonumber(comps and comps.tint) or 0)
    for _, component in ipairs(regular) do
        GiveWeaponComponentToPed(ped, weaponHash, GetHashKey(component.model))
    end
    for _, component in ipairs(finishes) do
        GiveWeaponComponentToPed(ped, weaponHash, GetHashKey(component.model))
    end
end
