Logger = {}
Logger.Type = {
    ["staff_kick"] = {
        webhook = GetConvar("warv_webhook_staff_kick", ""),
        message = "**Player kicked by staff %s**.\n\n**Name**: %s\n**ID**: %s\n**UID**: %s\n**Identifiers**:\n%s\n**Reason**: %s",
    },
    ["staff_ban"] = {
        webhook = GetConvar("warv_webhook_staff_ban", ""),
        message = "**Player banned by staff %s**.\n\n**Name**: %s\n**ID**: %s\n**UID**: %s\n**Identifiers**:\n%s\n**Reason**: %s",
    },
}

function Logger.Log(type, ...)
    if Logger.Type[type] ~= nil and Logger.Type[type].webhook ~= "" then

        local message = string.format(Logger.Type[type].message, ...)
        local embed = {
            {
                ["color"] = 15158332,
                ["title"] = "**WarV Moderation**",
                ["description"] = message,
            }
        }

	    PerformHttpRequest(Logger.Type[type].webhook, function(err, text, headers) end, 'POST', json.encode({
            username = "WarV",
	    	embeds = embed, 
	    }), { ['Content-Type'] = 'application/json' })
    end
end
