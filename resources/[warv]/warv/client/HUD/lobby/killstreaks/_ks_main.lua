KillStreakUI = {}
KillStreakUI.Clicked = false
KillStreakUI.ActiveKS = {}

function KillStreakUI.RefreshActiveKS()
    KillStreakUI.ActiveKS = {}
    for k,v in pairs(SharedConfig.Killstreaks) do
        for i,j in pairs(Gamemode.activeKillstreak) do
            if j.type == k then
                KillStreakUI.ActiveKS[k] = true
            end
        end
    end
end

