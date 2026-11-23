WeaponHud = {}

local lastKey = ""
local lastVisible = nil


function WeaponHud.Update(name, sprite, clip, reserve, clipMax, grenade)
    local slug = ""
    if sprite then slug = MenuUI.Slug(sprite.image or sprite.sprite) end
    clip = tonumber(clip) or 0
    reserve = tonumber(reserve) or 0
    clipMax = tonumber(clipMax) or 0
    grenade = tonumber(grenade) or -1

    local key = tostring(name) .. "|" .. slug .. "|" .. clip .. "|" .. reserve .. "|" .. clipMax .. "|" .. grenade
    if key == lastKey and lastVisible == true then return end
    lastKey = key
    lastVisible = true

    exports['warv-ui']:SetWeaponHud({
        visible = true,
        name = tostring(name or ""),
        image = slug,
        clip = clip,
        reserve = reserve,
        clipMax = clipMax,
        grenade = grenade,
    })
end

function WeaponHud.Hide()
    if lastVisible == false then return end
    lastVisible = false
    lastKey = ""
    exports['warv-ui']:SetWeaponHud({ visible = false, name = "", image = "", clip = 0, reserve = 0, clipMax = 0, grenade = -1 })
end
