Voice = {}
Voice.muted = {}
Voice.volume = 0.5

local voiceSig

function Voice.MuteOrUnmute(id)
    if Voice.muted[id] == nil then
        MumbleSetVolumeOverrideByServerId(id, 0.0)
        Voice.muted[id] = true
    else
        MumbleSetVolumeOverrideByServerId(id, Voice.volume)
        Voice.muted[id] = nil
    end
end


function Voice.AddPlayerToVoiceLobby(lobby)
    Citizen.CreateThread(function()
        NetworkClearVoiceChannel()
        
        local try = 0
        while not MumbleIsConnected() do
            NetworkSetVoiceActive(true)
            NetworkSetVoiceChannel(lobby)

            try = try + 1
            if try > 10 then
                break
            end
            Wait(100)
        end
        NetworkSetVoiceChannel(lobby)
    
        local try = 0
        while not MumbleGetVoiceChannelFromServerId(GetPlayerServerId(GetPlayerIndex())) do
            NetworkSetVoiceActive(true)
            NetworkSetVoiceChannel(lobby)
            try = try + 1
            if try > 10 then
                break
            end
            Wait(100)
        end 
    end)
end

function Voice.HandleLobbyVolume(players)
    for k,v in pairs(players) do
        if Voice.muted[v.id] == nil then
            MumbleSetVolumeOverrideByServerId(v.id, Voice.volume)
        end
    end
end


function Voice.ClearInGameVoiceChat()
    voiceSig = nil
    exports["warv-ui"]:SetVoiceChat({})
end

function Voice.DisplayInGameVoiceChat(players, myTeam)
    local list = {}
    for k, v in pairs(players) do
        if v.team == myTeam then
            list[#list + 1] = { name = v.name, talking = NetworkIsPlayerTalking(GetPlayerFromServerId(v.id)) }
        end
    end

    local sig = ""
    for _, p in ipairs(list) do
        sig = sig .. p.name .. (p.talking and "1" or "0") .. "|"
    end
    if sig ~= voiceSig then
        voiceSig = sig
        exports["warv-ui"]:SetVoiceChat(list)
    end
end

