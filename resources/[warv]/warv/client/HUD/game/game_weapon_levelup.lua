local function weaponMeta(model)
    local data = SharedConfig.weaponsSpriteByHash[GetHashKey(model)]
    local label = GetGxtForWeapon(model)
    if label == "" then label = model end
    return label, MenuUI.Slug(data and (data.image or data.sprite) or "")
end

local function show(weapon, level)
    local label, image = weaponMeta(weapon)
    local isMax = tonumber(level) and tonumber(level) >= WeaponProgression.MaxLevel
    exports['warv-ui']:WeaponLevelUp({
        weapon = label,
        image = image,
        level = tonumber(level) or 1,
        max = isMax,
    })
end

RegisterNetEvent("warv:WeaponLevelUpNotification")
AddEventHandler("warv:WeaponLevelUpNotification", function(weapon, level)
    show(weapon, level)
end)
