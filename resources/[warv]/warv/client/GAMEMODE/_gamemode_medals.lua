Medals = {}
Medals.queue = {}
Medals.scoreFeedQueue = {}
Medals.medals = {
    ["close_call"] =        {sprite = "close_call",   label = "Close call",    points = 50},
    ["revenge"] =           {sprite = "revenge",     label = "Revenge kill!", points = 50},
    ["headshot"] =          {sprite = "headshot",    label = "Headshot",      points = 25},
    ["UAV_KILL_BONUS"] =    {sprite = "uav_hunter",    label = "Uav kill bonus",points = 50},

    ["double_kill"] =       {sprite = "double_kill",  label = "Double kill",   points = 75},
    ["triple_kill"] =       {sprite = "triple_kill",  label = "Triple kill",   points = 100},
    ["quad_kill"] =         {sprite = "quad_kill",    label = "Quad kill",     points = 125},
    ["five_kill"] =         {sprite = "frenzy_kill",  label = "Frenzy kill",   points = 150},
    ["six_kill"] =          {sprite = "super_kill",   label = "Super kill",    points = 175},
    ["seven_kill"] =        {sprite = "mega_kill",    label = "Mega kill",     points = 200},
    ["eight_kill"] =        {sprite = "ultra_kill",   label = "Ultra kill",    points = 250},
    ["bloodthirsty"] =       {sprite = "frenzy_kill",  label = "Bloodthirsty",   points = 150},
    ["ten_kill"] =          {sprite = "merciless",   label = "Merciless",     points = 300},
    ["ruthless"] =           {sprite = "super_kill",   label = "Ruthless",       points = 300},
    ["twenty_kill"] =       {sprite = "relentless",  label = "Relentless",    points = 325},
    ["twenty_five_kill"] =  {sprite = "brutal",      label = "Brutal",        points = 350},
    ["unstoppable"] =       {sprite = "unstoppable", label = "Unstoppable",   points = 500},
    ["unstoppable_chain"] = {sprite = "unstoppable", label = "Unstoppable",   points = 100},
    ["nuke"] =              {sprite = "nuclear",     label = "Nuclear!",      points = 300},

    ["first_blood"] =       {sprite = "revenge",     label = "First blood",   points = 50},
    ["game_winner"] =       {sprite = "nuclear",     label = "Game winner",   points = 100},
    ["kingslayer"] =        {sprite = "brutal",      label = "Kingslayer",    points = 50},
    ["shutdown"] =          {sprite = "close_call",   label = "Shutdown",      points = 75},
    ["comeback"] =          {sprite = "revenge",     label = "Comeback",      points = 50},
    ["avenger"] =           {sprite = "revenge",     label = "Avenger",       points = 50},
    ["savior"] =            {sprite = "close_call",   label = "Savior",        points = 50},
    ["dominator"] =         {sprite = "merciless",   label = "Dominator",     points = 50},
    ["nemesis"] =           {sprite = "revenge",     label = "Nemesis",       points = 50},
    ["longshot"] =          {sprite = "one_shot_one_kill", label = "Longshot",  points = 25},
    ["point_blank"] =       {sprite = "close_call",   label = "Point blank",   points = 25},
    ["airborne"] =          {sprite = "super_kill",   label = "Airborne",      points = 25},
    ["melee"] =             {sprite = "close_call",   label = "Melee kill",    points = 50},
    ["demolition"] =        {sprite = "quad_kill",    label = "Demolition",    points = 50},
    ["from_grave"] =        {sprite = "revenge",     label = "From the grave",points = 75},
    ["major_assist"] =      {sprite = "uav_hunter",   label = "Major assist",  points = 50},
    ["uav_assist"] =        {sprite = "uav_hunter",   label = "UAV assist",    points = 25},
    ["aerial_denial"] =     {sprite = "uav_hunter",   label = "Aerial denial", points = 100},
    ["scorestreak_kill"] =  {sprite = "nuclear",     label = "Scorestreak kill", points = 25},
    ["took_lead"] =         {sprite = "relentless",  label = "Took the lead", points = 50},
}
Medals.multiKills = {
    [2] = "double_kill",
    [3] = "triple_kill",
    [4] = "quad_kill",
    [5] = "five_kill",
    [6] = "six_kill",
    [7] = "seven_kill",
    [8] = "eight_kill",
}
Medals.lifeStreaks = {
    [5] = "bloodthirsty",
    [10] = "ten_kill",
    [15] = "ruthless",
    [20] = "twenty_kill",
    [25] = "twenty_five_kill",
    [30] = "unstoppable",
}
Medals.multiKillWindowMs = 4000
Medals.cachedKills = 0
Medals.multiKillCount = 0
Medals.lastKillAt = nil
Medals.cachedKillerName = ""
Medals.breakLoop = false


function Medals.ResetQueue()
    Medals.queue = {}
    Medals.scoreFeedQueue = {}
end

function Medals.ResetCache()
    Medals.cachedKills = 0
    Medals.multiKillCount = 0
    Medals.lastKillAt = nil
    Medals.cachedKillerName = ""
    Score.ResetCache()
    Citizen.CreateThread(function()
        Medals.breakLoop = true
        Utils.RealWait(3000)
        Medals.queue = {}
        Medals.breakLoop = false
    end)
end

function Medals.Death(name)
    Medals.cachedKills = 0
    Medals.multiKillCount = 0
    Medals.lastKillAt = nil
    Medals.cachedKillerName = name
    Score.ResetCache()
    Medals.ResetQueue()
    exports['warv-ui']:ClearMedals()

    for k,v in pairs(Gamemode.activeKillstreak) do
        v.used = false
    end
end

function Medals.AddKill(gameID, name, isKillstreakKill)
    if Medals.breakLoop then return end

    local now = GetGameTimer()
    Medals.cachedKills = Medals.cachedKills + 1

    if Medals.lastKillAt ~= nil and now - Medals.lastKillAt <= Medals.multiKillWindowMs then
        Medals.multiKillCount = Medals.multiKillCount + 1
    else
        Medals.multiKillCount = 1
    end
    Medals.lastKillAt = now

    local multiKillMedal = Medals.multiKills[Medals.multiKillCount]
    if multiKillMedal ~= nil then
        Medals.AddMedalsToShow(multiKillMedal, gameID, isKillstreakKill)
    end

    local lifeStreakMedal = Medals.lifeStreaks[Medals.cachedKills]
    if lifeStreakMedal ~= nil then
        Medals.AddMedalsToShow(lifeStreakMedal, gameID, isKillstreakKill)
    elseif Medals.cachedKills > 30 then
        Medals.AddMedalsToShow("unstoppable_chain", gameID, isKillstreakKill)
    end

    if name ~= nil and name ~= "" and name == Medals.cachedKillerName then
        Citizen.CreateThread(function()
            Wait(500)
            if Medals.breakLoop then return end
            Medals.AddMedalsToShow("revenge", gameID, isKillstreakKill)
            Medals.cachedKillerName = ""
        end)
        
    end

end

function Medals.AddMedalsToShow(medal, gameID, isKillstreakKill)
    if Medals.breakLoop then return end
    if gameID == nil or tostring(gameID) == "0" or Status.GetIsPlayerInEndScreen() then return end

    local medalData = Medals.medals[medal]
    if medalData == nil then return end

    Utils.TriggerGamemodeServerEvent("MedalsPoint", medalData.points)
    Score.AddKillstreakProgress(Score.GetKillstreakProgressPoints(medalData.points, isKillstreakKill))
    table.insert(Medals.scoreFeedQueue, {
        points = medalData.points,
        label = medalData.label,
    })
    table.insert(Medals.queue, {medal = medal, gameID = gameID})
end



Citizen.CreateThread(function()
    while true do
        if Medals.breakLoop or Status.GetIsPlayerInEndScreen() then
            Medals.queue = {}
            Wait(100)
        else
            local queuedMedal = table.remove(Medals.queue, 1)
            if queuedMedal then
                Medals.ShowMedal(Medals.medals[queuedMedal.medal], queuedMedal.gameID)
                Wait(0)
            else
                Wait(50)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if Medals.breakLoop or Status.GetIsPlayerInEndScreen() then
            Medals.scoreFeedQueue = {}
            Wait(100)
        elseif #Medals.scoreFeedQueue > 0 then
            Wait(math.random(50, 100))

            local scoreFeedback = table.remove(Medals.scoreFeedQueue, 1)
            if scoreFeedback and not Medals.breakLoop and not Status.GetIsPlayerInEndScreen() then
                Score.ShowFeedback(scoreFeedback.points, scoreFeedback.label)
            end
        else
            Wait(25)
        end
    end
end)
