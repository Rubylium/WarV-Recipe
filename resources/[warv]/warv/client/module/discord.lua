Discord = {}
Discord.currentState = "lobby"
Discord.currentStateArgs = {}
Discord.states = {
    ["lobby"] = {
        presence = "In the lobby (1 of 1)",
        mainImage = "logo",
        smallImage = "",
    },
    ["matchmaking"] = {
        presence = "%s\nMatchmaking (%s of 10)",
        mainImage = "logo",
        smallImage = "",
    },
    ["playing"] = {
        presence = "%s\nOn %s (%s of 10)",
        mainImage = "matchmaking",
        smallImage = "",
    },
}

function Discord.SetState(state)
    Discord.currentState = state
end

function Discord.GetGamemodeFromName(name)
    local gamemode = "Unknow"
    for k,v in pairs(SharedConfig.Gamemode) do
        if v.name == name then
            gamemode = v.label
        end
    end
    return gamemode
end

Citizen.CreateThread(function()
    while true do
        SetDiscordAppId(858731608093360138)
        local data = Discord.states[Discord.currentState]

        if Discord.currentState == "lobby" then
            SetRichPresence(string.format(data.presence))
        elseif Discord.currentState == "matchmaking" then
            SetRichPresence(string.format(data.presence, Discord.GetGamemodeFromName(Matchmaking.data.gamemode), #GetActivePlayers()))
        elseif Discord.currentState == "playing" then
            SetRichPresence(string.format(data.presence, Discord.GetGamemodeFromName(Matchmaking.data.gamemode), Matchmaking.selectedMap.name, #GetActivePlayers()))
            data.mainImage = Matchmaking.selectedMap.spritePreview
        end

        SetDiscordRichPresenceAsset(data.mainImage)
        SetDiscordRichPresenceAssetSmall(data.smallImage)

        SetDiscordRichPresenceAction(0, "Discord", "https://discord.gg/warv")
        Wait(3000)
    end
end)