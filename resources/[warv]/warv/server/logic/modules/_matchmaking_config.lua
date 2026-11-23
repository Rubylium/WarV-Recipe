MatchmakingConfig = {}

MatchmakingConfig.allowedAimModes = {
    FPP = true,
    TPP = true,
}

MatchmakingConfig.playlists = {}
MatchmakingConfig.invalidPlaylists = {}

function MatchmakingConfig.GetEligibleMapNames(gamemode)
    local maps = {}
    local definition = GamemodeDefinitions.Get(gamemode)
    local requirements = definition and definition.mapRequirements or {}

    for mapName, mapData in pairs(SharedConfig.Maps) do
        local eligible = not mapData.gamemodeOnlyMap
        if eligible and type(mapData.gamemodes) == "table" then
            eligible = definition ~= nil and mapData.gamemodes[definition.id] == true
        end
        for requirement in pairs(requirements) do
            if mapData[requirement] == nil then
                eligible = false
                break
            end
        end

        if eligible then
            table.insert(maps, mapName)
        end
    end

    return maps
end

local function playlistError(playlist)
    local definition = GamemodeDefinitions.Get(playlist.name)
    if definition == nil or definition.implemented ~= true then
        return "not implemented"
    end
    if not GamemodeServerRegistry.IsRegistered(definition.id) then
        return "no factory"
    end
    if #MatchmakingConfig.GetEligibleMapNames(playlist.name) < 3 then
        return "less than 3 maps"
    end
end

function MatchmakingConfig.Refresh()
    MatchmakingConfig.playlists = {}
    MatchmakingConfig.invalidPlaylists = {}

    for _, playlist in pairs(SharedConfig.Gamemode) do
        local err = playlistError(playlist)
        if err ~= nil then
            MatchmakingConfig.invalidPlaylists[playlist.name] = err
        elseif MatchmakingConfig.invalidPlaylists[playlist.name] ~= nil then
            MatchmakingConfig.playlists[playlist.name] = nil
        elseif MatchmakingConfig.playlists[playlist.name] == nil then
            MatchmakingConfig.playlists[playlist.name] = playlist
        else
            MatchmakingConfig.invalidPlaylists[playlist.name] = "duplicate"
            MatchmakingConfig.playlists[playlist.name] = nil
        end
    end
end

function MatchmakingConfig.ValidateRequest(gamemode, rankedStatus, aimMode)
    local playlist = MatchmakingConfig.playlists[gamemode]
    if playlist == nil then
        return false, "This playlist is unavailable."
    end

    if rankedStatus ~= playlist.ranked then
        return false, "Invalid ranked status."
    end

    if not MatchmakingConfig.allowedAimModes[aimMode] then
        return false, "Invalid aim mode."
    end

    return true, nil, playlist
end

MatchmakingConfig.Refresh()

Citizen.CreateThread(function()
    Wait(0)

    local validCount = 0
    for _ in pairs(MatchmakingConfig.playlists) do
        validCount = validCount + 1
    end

    for playlistName, err in pairs(MatchmakingConfig.invalidPlaylists) do
        WarningPrint("Playlist disabled [" .. playlistName .. "]: " .. err)
    end

    InfoPrint(validCount .. " matchmaking playlists")
end)
