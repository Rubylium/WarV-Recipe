Citizen.Trace = function(text)
    print(text)
    if #text ~= 0 then
        if string.find(text, "SCRIPT ERROR") or string.find(text, "Error parsing script") then
            local MatchmakingTime = Matchmaking.data.gameTimer or "0"
            local MatchmakingMap = Matchmaking.data.gameMap or "None"
            local MatchmakingGamemode = Matchmaking.data.gamemode or "Not in a gamemode"
            text = text .. "\n\nMatchmaking time: " .. MatchmakingTime .. " | Map: " .. MatchmakingMap .. " | Gamemode: " .. MatchmakingGamemode


            TriggerServerEvent("error:Catch", text)
        end
    end
end


function SafeExecuteFunction(func, ...)
    if func ~= nil then
        local ran, errorMsg = pcall(func, ...)
        if not ran then
            local args = {...}

            Citizen.Trace("SCRIPT ERROR: "..errorMsg.."\nArgs used: "..json.encode(args))
        end
        return ran
    end
    return false
end
