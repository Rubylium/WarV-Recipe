GamemodeRuntime.RegisterRouteInstaller(function()
    GamemodeRuntime.On("AwardMedals", function(medalIds)
        if type(medalIds) ~= "table" then return end

        local isKillstreakKill = false
        for _, medalId in ipairs(medalIds) do
            if medalId == "scorestreak_kill" then
                isKillstreakKill = true
                break
            end
        end

        for _, medalId in ipairs(medalIds) do
            Medals.AddMedalsToShow(medalId, Status.GetCurrentGameId(), isKillstreakKill)
        end
    end)
end)
