Emblems = {}

function Emblems.Message(name, message, embledId, friendly)
    local _, sprite = GetEmblemForId(embledId)
    exports['warv-ui']:KsAnnounce({
        name = tostring(name or ""),
        message = tostring(message or ""),
        card = tostring(sprite or ""),
        friendly = friendly == true,
    })
end

RegisterNetEvent("warv_revisted:GetEmblemMessage")
AddEventHandler("warv_revisted:GetEmblemMessage", function(name, message, embledId, friendly)
    Emblems.Message(name, message, embledId, friendly)
end)
