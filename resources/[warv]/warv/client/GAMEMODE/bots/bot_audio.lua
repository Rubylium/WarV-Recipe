Bot.silencedEntities = {}

function Bot.DisableAudio(entity)
    DisablePedPainAudio(entity, true)
    BlockAllSpeechFromPed(entity, true, true)
end

local function silenceStreamedBots()
    local activeNetIds = {}

    for team = 1, 2 do
        for _, profile in pairs(Bot.list[team]) do
            local netId = profile.netId
            if netId ~= nil and netId ~= 0 then
                activeNetIds[netId] = true

                if NetworkDoesNetworkIdExist(netId) then
                    local entity = NetworkGetEntityFromNetworkId(netId)
                    if entity ~= 0 and DoesEntityExist(entity) and Bot.silencedEntities[netId] ~= entity then
                        Bot.DisableAudio(entity)
                        Bot.silencedEntities[netId] = entity
                    end
                end
            end
        end
    end

    for netId in pairs(Bot.silencedEntities) do
        if not activeNetIds[netId] then
            Bot.silencedEntities[netId] = nil
        end
    end
end

Citizen.CreateThread(function()
    while true do
        if Bot.GameId ~= 0 then
            silenceStreamedBots()
            Wait(250)
        else
            Bot.silencedEntities = {}
            Wait(500)
        end
    end
end)
