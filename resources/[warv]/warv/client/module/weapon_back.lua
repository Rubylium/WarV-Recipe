WeaponBack = {}
WeaponBack.Bone = 24817
WeaponBack.CurrentEntity = nil
WeaponBack.CurrentWeapon = nil
WeaponBack.Presets = {
    ["back"] = {
        ["position"] = {
            x = 0.35,
            y = -0.23,
            z = 0.08
        },
        ["rotation"] = {
            x = 180.0,
            y = 180.0,
            z = 0
        }
    },
    ["back_lower"] = {
        ["position"] = {
            x = 0.1,
            y = -0.23,
            z = 0.08
        },
        ["rotation"] = {
            x = 180.0,
            y = 180.0,
            z = 0
        }
    },
    ["front"] = {
        ["position"] = {
            x = 0.02,
            y = 0.27,
            z = 0.1
        },
        ["rotation"] = {
            x = 180.0,
            y = 220.0,
            z = 0.0
        }
    },
    ["side_pistol"] = {
        ["bone"] = 23553,
        ["position"] = {
            x = 0.0,
            y = 0.0,
            z = -0.23
        },
        ["rotation"] = {
            x = 270.0,
            y = 180.0,
            z = 0.0
        }
    },
}
WeaponBack.PresetsWeapon = {
    [GetHashKey("weapon_sniperrifle")] = "back",
    [GetHashKey("weapon_heavysniper")] = "back",
    [GetHashKey("weapon_heavysniper_mk2")] = "back",
    [GetHashKey("weapon_marksmanrifle")] = "back",
    [GetHashKey("weapon_marksmanrifle_mk2")] = "back",
    [GetHashKey("weapon_musket")] = "back",

    [GetHashKey("weapon_assaultrifle")] = "front",
    [GetHashKey("weapon_assaultrifle_mk2")] = "front",
    [GetHashKey("weapon_carbinerifle")] = "front",
    [GetHashKey("weapon_carbinerifle_mk2")] = "front",
    [GetHashKey("weapon_advancedrifle")] = "front",
    [GetHashKey("weapon_specialcarbine")] = "front",
    [GetHashKey("weapon_specialcarbine_mk2")] = "front",
    [GetHashKey("weapon_bullpuprifle")] = "front",
    [GetHashKey("weapon_bullpuprifle_mk2")] = "front",
    [GetHashKey("weapon_compactrifle")] = "front",
    [GetHashKey("weapon_militaryrifle")] = "front",
    [GetHashKey("weapon_heavyrifle")] = "front",

    [GetHashKey("weapon_mg")] = "back",
    [GetHashKey("weapon_combatmg")] = "back",
    [GetHashKey("weapon_combatmg_mk2")] = "back",
    [GetHashKey("weapon_gusenberg")] = "front",

    [GetHashKey("weapon_pumpshotgun")] = "front",
    [GetHashKey("weapon_pumpshotgun_mk2")] = "front",
    [GetHashKey("weapon_sawnoffshotgun")] = "front",
    [GetHashKey("weapon_assaultshotgun")] = "front",
    [GetHashKey("weapon_bullpupshotgun")] = "front",
    [GetHashKey("weapon_heavyshotgun")] = "front",
    [GetHashKey("weapon_dbshotgun")] = "front",
    [GetHashKey("weapon_autoshotgun")] = "front",
    [GetHashKey("weapon_combatshotgun")] = "front",


    
    [GetHashKey("weapon_microsmg")] = "side_pistol",
    [GetHashKey("weapon_smg_mk2")] = "side_pistol",
    [GetHashKey("weapon_machinepistol")] = "side_pistol",
    [GetHashKey("weapon_minismg")] = "side_pistol",
    [GetHashKey("weapon_smg")] = "front",
    [GetHashKey("weapon_assaultsmg")] = "front",
    [GetHashKey("weapon_combatpdw")] = "front",



    [GetHashKey("weapon_pistol")] = "side_pistol",
    [GetHashKey("weapon_pistol_mk2")] = "side_pistol",
    [GetHashKey("weapon_combatpistol")] = "side_pistol",
    [GetHashKey("weapon_appistol")] = "side_pistol",
    [GetHashKey("weapon_pistol50")] = "side_pistol",
    [GetHashKey("weapon_snspistol")] = "side_pistol",
    [GetHashKey("weapon_snspistol_mk2")] = "side_pistol",
    [GetHashKey("weapon_heavypistol")] = "side_pistol",
    [GetHashKey("weapon_vintagepistol")] = "side_pistol",
    [GetHashKey("weapon_flaregun")] = "side_pistol",
    [GetHashKey("weapon_marksmanpistol")] = "side_pistol",
    [GetHashKey("weapon_revolver")] = "side_pistol",
    [GetHashKey("weapon_revolver_mk2")] = "side_pistol",
    [GetHashKey("weapon_doubleaction")] = "side_pistol",
    [GetHashKey("weapon_raypistol")] = "side_pistol",
    [GetHashKey("weapon_ceramicpistol")] = "side_pistol",
    [GetHashKey("weapon_navyrevolver")] = "side_pistol",
    [GetHashKey("weapon_gadgetpistol")] = "side_pistol",
    [GetHashKey("weapon_stungun_mp")] = "side_pistol",
}



function WeaponBack.SetupWeaponBack(hash)
    local pPed = Player.GetPed()
    if IsPedArmed(pPed, 4) then
        if WeaponBack.CurrentWeapon ~= hash then
            WeaponBack.RemoveWeaponFromBack()
            local weapObj = GetWeaponObjectFromPed(pPed, 1)
            local presetToUse
            local BoneToUse = WeaponBack.Bone
            if WeaponBack.PresetsWeapon[hash] then
                presetToUse = WeaponBack.PresetsWeapon[hash]
                if WeaponBack.Presets[presetToUse]["bone"] ~= nil then
                    BoneToUse = WeaponBack.Presets[presetToUse]["bone"]
                end
            else
                presetToUse = "back"
            end
            AttachEntityToEntity(
                weapObj,
                pPed,
                GetPedBoneIndex(pPed, BoneToUse),
                WeaponBack.Presets[presetToUse]["position"].x,
                WeaponBack.Presets[presetToUse]["position"].y,
                WeaponBack.Presets[presetToUse]["position"].z,
                WeaponBack.Presets[presetToUse]["rotation"].x,
                WeaponBack.Presets[presetToUse]["rotation"].y,
                WeaponBack.Presets[presetToUse]["rotation"].z,
                false,
                true,
                false,
                false,
                0,
                true
            )
            WeaponBack.CurrentEntity = weapObj
            WeaponBack.CurrentWeapon = hash
        end

    end
end

function WeaponBack.GetWeaponFromBack()
    WeaponBack.RemoveWeaponFromBack()
end

function WeaponBack.RemoveWeaponFromBack()
    if WeaponBack.CurrentEntity ~= nil and DoesEntityExist(WeaponBack.CurrentEntity) then
        DeleteEntity(WeaponBack.CurrentEntity)
    end
end

