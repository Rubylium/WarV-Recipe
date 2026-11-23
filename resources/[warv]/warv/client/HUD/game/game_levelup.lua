RankUp = {}

function RankUp.NewRankUp(newRank, prestige)
    exports['warv-ui']:Notify("rank_up", {
        level = tonumber(newRank) or 1,
        prestige = tonumber(prestige) or 0,
    })
end

RegisterNetEvent("warv:LevelUpNotification")
AddEventHandler("warv:LevelUpNotification", function(level, prestige)
    RankUp.NewRankUp(level, prestige)
end)
