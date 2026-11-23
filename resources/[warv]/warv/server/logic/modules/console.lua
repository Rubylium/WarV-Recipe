Console = {}
Console.debug = true

function InfoPrint(text)
    print("^2WARV: ^7"..text)
end

function WarningPrint(text)
    print("^3WARNING: ^7"..text)
end

function CriticalPrint(text)
    print("^1CRITCAL ISSUE: ^7"..text)
end

function DbPrint(text)
    print("^2DB: ^7"..text)
end

function MatchmakingPrint(text)
    print("^2Matchmaking: ^7"..text)
end

function Console.InfoPrint(text)
    InfoPrint(text)
end

function Console.WarningPrint(text)
    WarningPrint(text)
end

function Console.CriticalPrint(text)
    CriticalPrint(text)
end

function Console.DbPrint(text)
    DbPrint(text)
end

function Console.MatchmakingPrint(text)
    MatchmakingPrint(text)
end

function Console.DebugPrint(text)
    if Console.debug then
        print("^2DEBUG: ^7"..text)
    end
end