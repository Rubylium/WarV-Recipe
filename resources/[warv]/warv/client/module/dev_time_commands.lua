if SharedConfig.devmod then
    RegisterCommand("day", function()
        NetworkOverrideClockTime(12, 0, 0)
    end, false)

    RegisterCommand("night", function()
        NetworkOverrideClockTime(0, 0, 0)
    end, false)
end
