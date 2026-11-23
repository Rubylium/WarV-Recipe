Data = {}
Data.ClassNeedRefresh = true
Data.AlreadyLoadClassOne = false
Data.FirstLoaded = false
Data.playerIcon = 1
function Data.CanRefreshClass()
    Data.ClassNeedRefresh = true
end

RegisterNetEvent("warv:GetGlobalData")
AddEventHandler("warv:GetGlobalData", function(banned, uid, id, steam, gameId, perm, fivem, name, credit, emblemsId, xp, level, prestige, ranking, logoId)
    Lobby.playerData.uid = uid
    Lobby.playerData.banned = banned
    Lobby.playerData.id = id
    Lobby.playerData.steam = steam
    Lobby.playerData.gameId = gameId
    Lobby.playerData.perm = perm
    Lobby.playerData.fivem = fivem
    Lobby.playerData.name = name
    Lobby.playerData.credit = credit
    Lobby.playerData.emblemsId = emblemsId
    Lobby.playerData.xp = xp
    Lobby.playerData.level = level
    Lobby.playerData.prestige = prestige
    Lobby.playerData.ranking = ranking
    Data.playerIcon = logoId
end)

function Data.GetClassData()
    if Data.ClassNeedRefresh then
        Data.AlreadyLoadClassOne = true
        TriggerServerEvent("warv:GetClassData")
    end
end

RegisterNetEvent("warv:GetCreditData")
AddEventHandler("warv:GetCreditData", function(data)
    Lobby.playerData.credit = data
end)

local removedWeapons = {
    WEAPON_M4A1 = "weapon_assaultrifle",
    WEAPON_ACR = "weapon_assaultrifle",
    WEAPON_TX15 = "weapon_carbinerifle",
    WEAPON_HK416A5 = "weapon_carbinerifle",
    WEAPON_SCARH = "weapon_assaultrifle",
    WEAPON_MP7 = "weapon_smg",
    WEAPON_P90 = "weapon_smg",
    WEAPON_awp = "weapon_sniperrifle",
}

RegisterNetEvent("warv:GetClassData")
AddEventHandler("warv:GetClassData", function(data)
    Lobby.playerData.class = data
    Class.customClass = data

    for _, v in pairs(data) do
        if v.weapons then
            for _, slot in ipairs({ "primary", "secondary" }) do
                local w = v.weapons[slot]
                local replacement = w and w.weapon and removedWeapons[w.weapon]
                if replacement then
                    w.weapon = replacement
                    w.comps = {}
                end
            end
        end
    end

    ClasseCreation.Rebind()
    PlayersDisplay.SyncMyWeapon()
end)


function Data.GetStatsData()
    TriggerServerEvent("warv:GetStatsData")
end

RegisterNetEvent("warv:GetStatsData")
AddEventHandler("warv:GetStatsData", function(kill, assist, death, score, xp, level, stats)
    Lobby.playerData.kill = kill
    Lobby.playerData.assist = assist
    Lobby.playerData.death = death
    Lobby.playerData.score = score
    Lobby.playerData.xp = xp
    Lobby.playerData.level = level
    Lobby.playerData.stats = stats
    RefreshCareerData(Lobby.playerData)
end)

function Data.GetWeaponStatsData()
    if Data.ClassNeedRefresh then
        TriggerServerEvent("warv:GetWeaponStatsData")
        Data.ClassNeedRefresh = false
    end
end

RegisterNetEvent("warv:GetWeaponStatsData")
AddEventHandler("warv:GetWeaponStatsData", function(data)
    Lobby.playerData.weaponsStats = data
end)

function Data.GetUnlockedContentData()
    if Data.ClassNeedRefresh then
        TriggerServerEvent("warv:GetUnlockedContentData")
    end
end

RegisterNetEvent("warv:GetUnlockedContentData")
AddEventHandler("warv:GetUnlockedContentData", function(data)
    Lobby.playerData.unlockedContent = data
end)

RegisterNetEvent("warv:GetPermData")
AddEventHandler("warv:GetPermData", function(data)
    Lobby.playerData.perm = data
end)

RegisterNetEvent("warv:GetBanData")
AddEventHandler("warv:GetBanData", function(banned, type, time)
    Lobby.playerData.banned = banned
    Lobby.playerData.banType = type
    Lobby.playerData.banTimeRemainText = time
end)

AddEventHandler("warv:GetPlayerPerm", function(cb)
    cb(Lobby.playerData.perm or 0)
end)
