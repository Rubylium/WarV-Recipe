local possibleNames = {
    {"Charlizerex"},
    {"IHasFeet"},
    {"Charlize Red Feet"},
    {"Charlizeasaurus Rex"},
    {"Charlize Loving Insides"},
    {"Charlize English"},
    {"Uber Red Fox"},
    {"Disguised Fox"},
    {"RedFeetOMG"},
    {"LovingFeetLOL"},
    {"AdorableFeetOMG"},
    {"RedInsidesLOL"},
    {"LovingInsidesOMG"},
    {"AdorableInsidesLMAO"},
    {"Iamred"},
    {"Iamloving"},
    {"Iamadorable"},
    {"IamCharlize"},
    {"FoxMilk"},
    {"Charlize Adorable Fox"},
    {"MindOfCharlize"},
    {"Gamerfox"},
    {"The Red Gamer"},
    {"The Loving Gamer"},
    {"The Adorable Gamer"},
    {"DrRed"},
    {"CharlizeFeetpopper"},
    {"BigRedFox"},
    {"ItIsYeFox"},
    {"Ch4rl1z3"},
    {"Fox Boy"},
    {"Fox Girl"},
    {"Fox Person"},
    {"Captain Red"},
    {"IHasInsides"},
    {"Total Fox"},
    {"The Red English Dude"},
    {"The Gaming Fox"},
    {"Gaming With Charlize"},
    {"Marcrex"},
    {"IHasArm Pits"},
    {"Marc Hungry Arm Pits"},
    {"Marcasaurus Rex"},
    {"Marc Tall Hands"},
    {"Marc Spanish"},
    {"Uber Hungry Lizard"},
    {"Disguised Lizard"},
    {"HungryArm PitsOMG"},
    {"TallArm PitsLOL"},
    {"GivingArm PitsOMG"},
    {"HungryHandsLOL"},
    {"TallHandsOMG"},
    {"GivingHandsLMAO"},
    {"Iamhungry"},
    {"Iamtall"},
    {"Iamgiving"},
    {"IamMarc"},
    {"LizardMilk"},
    {"Marc Giving Lizard"},
    {"MindOfMarc"},
    {"Gamerlizard"},
    {"The Hungry Gamer"},
    {"The Tall Gamer"},
    {"The Giving Gamer"},
    {"DrHungry"},
    {"MarcArm Pitspopper"},
    {"BigHungryLizard"},
    {"ItIsYeLizard"},
    {"M4rc"},
    {"Lizard Boy"},
    {"Lizard Girl"},
    {"Lizard Person"},
    {"Captain Hungry"},
    {"IHasHands"},
    {"Total Lizard"},
    {"The Hungry Spanish Dude"},
    {"The Gaming Lizard"},
    {"Gaming With Marc"},
    {"Mikerex"},
    {"IHasChins"},
    {"Mike Cute Chins"},
    {"Mikeasaurus Rex"},
    {"Mike Sympathetic Teeth"},
    {"Mike English"},
    {"Uber Cute Cat"},
    {"Disguised Cat"},
    {"CuteChinsOMG"},
    {"SympatheticChinsLOL"},
    {"OptimisticChinsOMG"},
    {"CuteTeethLOL"},
    {"SympatheticTeethOMG"},
    {"OptimisticTeethLMAO"},
    {"Iamcute"},
    {"Iamsympathetic"},
    {"Iamoptimistic"},
    {"IamMike"},
    {"CatMilk"},
    {"Mike Optimistic Cat"},
    {"MindOfMike"},
    {"Gamercat"},
    {"The Cute Gamer"},
    {"The Sympathetic Gamer"},
    {"The Optimistic Gamer"},
    {"DrCute"},
    {"MikeChinspopper"},
    {"BigCuteCat"},
    {"ItIsYeCat"},
    {"M1k3"},
    {"Cat Boy"},
    {"Cat Girl"},
    {"Cat Person"},
    {"Captain Cute"},
    {"IHasTeeth"},
    {"Total Cat"},
    {"The Cute English Dude"},
    {"The Gaming Cat"},
    {"Gaming With Mike"},
    {"Juliarex"},
    {"IHasNipples"},
    {"Julia Curvaceous Nipples"},
    {"Juliaasaurus Rex"},
    {"Julia Scheming Cheeks"},
    {"Julia Chinese"},
    {"Uber Curvaceous Snake"},
    {"Disguised Snake"},
    {"CurvaceousNipplesOMG"},
    {"SchemingNipplesLOL"},
    {"RuthlessNipplesOMG"},
    {"CurvaceousCheeksLOL"},
    {"SchemingCheeksOMG"},
    {"RuthlessCheeksLMAO"},
    {"Iamcurvaceous"},
    {"Iamscheming"},
    {"Iamruthless"},
    {"IamJulia"},
    {"SnakeMilk"},
    {"Julia Ruthless Snake"},
    {"MindOfJulia"},
    {"Gamersnake"},
    {"The Curvaceous Gamer"},
    {"The Scheming Gamer"},
    {"The Ruthless Gamer"},
    {"DrCurvaceous"},
    {"JuliaNipplespopper"},
    {"BigCurvaceousSnake"},
    {"ItIsYeSnake"},
    {"Jul14"},
    {"Snake Boy"},
    {"Snake Girl"},
    {"Snake Person"},
    {"Captain Curvaceous"},
    {"IHasCheeks"},
    {"Total Snake"},
    {"The Curvaceous Chinese Dude"},
    {"The Gaming Snake"},
    {"Gaming With Julia"},

}

function GetRandomNickName()
	return possibleNames[math.random(1, #possibleNames)][1]
end

function GenerateUuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function GetCorrectExpForLevel(level)
	return math.floor(SharedConfig.expForLevel * (level^2) - 1)
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function GetPlayerLevelFromXp(xp, prestige)
    if prestige == nil then
        prestige = 0
    end
	local xp = xp
	local found = false
	local level = 1
	while not found do
		if xp < GetCorrectExpForLevel(level) then
			break
		else
			level = level + 1
		end
	end

	if level > 55 and prestige < 5 then
		level = 55
	end

	return level
end

function GetLicense(id)
    local identifiers = GetPlayerIdentifiers(id)
    for _, v in ipairs(identifiers) do
        if string.sub(v, 1, 8) == "license:" then
            return v
        end
    end
    return nil
end

function GetSteam(id)
    local identifiers = GetPlayerIdentifiers(id)
    for _, v in pairs(identifiers) do
        if string.find(v, "steam") then
            return v
        end
    end
end

function GetDiscord(id)
    local identifiers = GetPlayerIdentifiers(id)
    for _, v in pairs(identifiers) do
        if string.find(v, "discord") then
            return v
        end
    end
    return false
end

function GetFiveMLicense(id)
    local identifiers = GetPlayerIdentifiers(id)
    for _, v in pairs(identifiers) do
        if string.find(v, "fivem") then
            return v
        end
    end
    return "NULL"
end


function SplitSteam(steam)
    local parts = stringsplit(steam, ':')
    if parts then
        return parts[2]:lower()
    end
end

function stringsplit(input, seperator)
	if seperator == nil then
		seperator = '%s'
	end
	
	local t={}
	
    local i=1
	for str in string.gmatch(input, '([^'..seperator..']+)') do
		t[i] = str
		i = i + 1
	end
	
	return t
end

function copy(obj, seen)
    if type(obj) ~= 'table' then
        return obj
    end
    if seen and seen[obj] then
        return seen[obj]
    end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
        res[copy(k, s)] = copy(v, s)
    end
    return res
end


local function OnPlayerConnecting(name, setKickReason, deferrals)
    local source = source
    ConnectionDebug.Begin(source, name)

    if not SharedConfig.allowConnexion then
        ConnectionDebug.Finish(source, "connection_disabled")
        deferrals.done("For technical reasons, the WarV game servers are currently waiting for restart. Please be patient.")
        return
    end

    local player = source
    deferrals.defer()

    Wait(0)

    local identity, identityError = Players.GetIdentity(source)
    if identity == nil then
        ConnectionDebug.Finish(source, "identity_failed", tostring(identityError))
        deferrals.done("Rockstar license not found (" .. tostring(identityError) .. "). Restart FiveM and reconnect.")
        return
    end
    Players.BeginConnection(source, identity)

    local uid

    local userQuerySuccess, playerData, userQueryError = Db.Single(
        "SELECT `id` FROM `users` WHERE `identifier` = ? LIMIT 1",
        {identity.license}
    )
    if not userQuerySuccess then
        ConnectionDebug.Finish(source, "database_unavailable", tostring(userQueryError))
        deferrals.done("Database unavailable. Try again later.")
        CriticalPrint("Connect lookup [" .. source .. "]: " .. tostring(userQueryError))
        return
    end

    if playerData then
        uid = playerData.id
    end


    for _, token in ipairs(identity.tokens) do
        if string.sub(token, 1, 1) ~= "1" then
            local tokenQuerySuccess, results = Db.Single(
                "SELECT `UID` FROM `identifiers` WHERE `Identifier` = ? LIMIT 1",
                {token}
            )
            if tokenQuerySuccess and results and uid == nil then
                uid = results.UID
            end
        end
    end

    if uid then
        local banQuerySuccess, banData, banQueryError = Ban.FindActiveByUid(uid)
        if not banQuerySuccess then
            ConnectionDebug.Finish(source, "ban_lookup_failed", tostring(banQueryError))
            deferrals.done("Database unavailable. Try again later.")
            return
        end

        if banData ~= nil then
            ConnectionDebug.Finish(source, "banned")
            deferrals.done(Ban.FormatMessage(banData))
            return
        end
    end
    EnterServerQueue(deferrals, player)
end

AddEventHandler("playerConnecting", OnPlayerConnecting)

AddEventHandler('playerDropped', function (reason)
    local source = source
    if not ExitServerQueue(source, "playerDropped: " .. tostring(reason)) then
        ConnectionDebug.Forget(source, "playerDropped reason=" .. tostring(reason))
    end
    local player, session = Players.DetachPlayer(source)
    local identity = session and session.identity or nil

    Matchmaking.LeaveMatchmaking(source, true)
    Game.RemovePlayerFromAnyGame(source)

    if Groups.IsPlayerInAnyGroup(source) then
        Groups.Leave(Groups.GetPlayerGroup(source), source)
    end

    if player ~= nil then
        Friends.Unload(player.uid)
        Challenges.Unload(player.uid)

        local name = player.name or "Unknown"
        local ids = ""
        local identifiers = identity and identity.identifiers or {}

        Discord.SendLogType("disconnect", "```User disconnected: "..json.encode(player.name).."\nStats: "..json.encode(player.stats).."\nLevel: "..tostring(player.level).."\nReason: "..reason.."```")


        for _,v in ipairs(identifiers) do
            if not string.starts(v,"ip:") then
                ids = ids .. v .. ";\n"
            end
        end

        Discord.SendLogType("disconnect-public", "**Player disconnect**\n**Name**: "..name.."\n**OLD ID**: "..source.."\n**Ids**: ```"..ids.."```")
        Players.SaveDetachedPlayer(player, source)
    end

end)
  
function ShuffleTable(t) 
    local tbl = {}
    for i = 1, #t do
        tbl[i] = t[i]
    end
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end


function GetWeaponNameFromHash(hash)
    local weapon = WeaponRegistry.GetNameFromHash(hash)
    if weapon then return weapon end

    local configured = SharedConfig.weaponsSpriteByHash[hash]
    if configured and configured.weapon then
        return WeaponRegistry.NormalizeName(configured.weapon)
    end

    return nil
end
  
RegisterNetEvent("DeleteEntity")
AddEventHandler("DeleteEntity", function(net)
    local entity = NetworkGetEntityFromNetworkId(net)
    DeleteEntity(entity)
end)

local symboleToRemove = {
    "'",
    "\"",
    "^",
    "<",
    ">",
    "~",
    "\\"
}

function RemoveUnallowedSymboleFromString(str)
    local newStr = str
    for k,v in ipairs(symboleToRemove) do
        newStr = string.gsub(newStr, v, "") 
    end
    return newStr
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
 end


Utils = {}
function Utils.GetPlayersIdentifiersInString(source)
    local identifiers = GetPlayerIdentifiers(source)
    local ids = ""
    for k,v in pairs(identifiers) do
        if not string.starts(v,"ip:") then
            ids = ids .. v .. ";\n"
        end
    end
    return ids
end

function Utils.GetDistanceBetweenCoords(coords1, coords2)
    return #(coords1 - coords2)
end
