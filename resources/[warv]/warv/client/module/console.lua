Console = {}
function Console.InfoPrint(text)
    print("^2WARV: ^7"..text)
end

function Console.WarningPrint(text)
    print("^3WARNING: ^7"..text)
end

function Console.CriticalPrint(text)
    print("^1CRITCAL ISSUE: ^7"..text)
end

function Console.DbPrint(text)
    print("^2DB: ^7"..text)
end

function Console.MatchmakingPrint(text)
    print("^2Matchmaking: ^7"..text)
end