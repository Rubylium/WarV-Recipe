Discord = {}
Config = {}

Config.Debug = false

Config.Webhook = GetConvar("warv_webhook_status", "")
Config.ServerName = 'WarV'

Config.MessageId = GetConvar("warv_status_message", "")

Config.Use24hClock = true
Config.JoinLink = GetConvar("warv_join_link", "")

Config.EmbedColor = 3066993
Config.EmbedColorOff = 15158332

Config.Locale = 'en'

Config.Locales = {
    ['en'] = {
        ['date'] = 'Date',
        ['time'] = 'Time',
        ['players'] = 'Players',
        ['connect'] = 'Connect to WarV',
    }
}

local locales = Config.Locales[Config.Locale]

Citizen.CreateThread(function()
    if Config.Webhook == "" then return end
    while true do
		if Config.MessageId ~= nil and Config.MessageId ~= '' then
			UpdateStatusMessage()
		else
			DeployStatusMessage()
			break
		end

		Citizen.Wait(3500)
    end
end)


function DeployStatusMessage()
	local footer = nil

	if Config.Use24hClock then
		footer = os.date(locales['date']..': %d/%m/%Y  |  '..locales['time']..': %H:%M')
	else
		footer = os.date(locales['date']..': %d/%m/%Y  |  '..locales['time']..': %I:%M %p')
	end

	if Config.Debug then
		print('Deplying Status Message ['..footer..']')
	end

	local embed = {
		{
			["color"] = Config.EmbedColor,
			["title"] = "** Deploying Status Message!**",
			["description"] = 'Copy this message id and put it into Config and restart script!',
			["footer"] = {
				["text"] = footer,
			},
		}
	}

	PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({
		embeds = embed,
	}), { ['Content-Type'] = 'application/json' })
end


function UpdateStatusMessage()
	if GetConvar("dev_mod", false) ~= nil and GetConvar("dev_mod", false) == "true" then

	else
		local players = #GetPlayers()
		local maxplayers = 500
		local footer = nil

		if Config.Use24hClock then
			footer = os.date(locales['date']..': %d/%m/%Y  |  '..locales['time']..': %H:%M')
		else
			footer = os.date(locales['date']..': %d/%m/%Y  |  '..locales['time']..': %I:%M %p')
		end

		if Config.Debug then
			print('Updating Status Message ['..footer..']')
		end

		local rankedCount = 0
		local unrankedCount = 0
		local rankedLobbyCount = 0
		local unrankedLobbyCount = 0

		local total = 0
		local rankedGames = {}
		local unrankedGames = {}


		for k,v in pairs(Game.games) do
			if v.ranked then
				rankedCount = rankedCount + #v.players
				rankedLobbyCount = rankedLobbyCount + 1
				if rankedGames[v.gamemode] == nil then
					rankedGames[v.gamemode] = 0
				end

				rankedGames[v.gamemode] = rankedGames[v.gamemode] + #v.players
			else
				unrankedCount = unrankedCount + #v.players
				unrankedLobbyCount = unrankedLobbyCount + 1

				if unrankedGames[v.gamemode] == nil then
					unrankedGames[v.gamemode] = 0
				end

				unrankedGames[v.gamemode] = unrankedGames[v.gamemode] + #v.players
			end
		end

		total = rankedCount + unrankedCount

		local games = ""
		if total ~= 0 then
			games = "\n:crossed_swords: Ranked (".. math.floor((rankedCount / total) * 100) .."% Players):"
			for k,v in pairs(rankedGames) do
				games = games .. "\n"..k..": `"..v.."`"
			end
			games = games .."\n\n:shield: Unranked (".. math.floor((unrankedCount / total) * 100) .."% Players):"
			for k,v in pairs(unrankedGames) do
				games = games .. "\n"..k..": `"..v.."`"
			end
		else
			games = "\n:crossed_swords: Ranked (0% Players):"
			for k,v in pairs(rankedGames) do
				games = games .. "\n"..k..": `"..v.."`"
			end
			games = games .."\n\n:shield: Unranked (0% Players):"
			for k,v in pairs(unrankedGames) do
				games = games .. "\n"..k..": `"..v.."`"
			end
		end

		local message = json.encode({
			embeds = {
				{

					["color"] = Config.EmbedColor,
					["title"] = '**'..Config.ServerName..'**',
					["description"] = ':busts_in_silhouette: '..locales['players']..': `'..players..' / '..maxplayers..'`\n'..games,
					["footer"] = {
						["text"] = footer,
					},
				}
			},

			components = {
				{
					["type"] = 1,
					["components"] = {
						{
							["type"] = 2,
							["label"] = locales['connect'],
							["style"] = 5,
							["url"] = Config.JoinLink,
						}
					},
				}
			}
		})

		PerformHttpRequest(Config.Webhook..'/messages/'..Config.MessageId, function(err, text, headers)
			if Config.Debug then
				print('[DEBUG] err=', err)
				print('[DEBUG] text=', text)
			end
		end, 'PATCH', message, { ['Content-Type'] = 'application/json' })
	end

end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    if Config.Webhook == "" or Config.MessageId == "" then return end

    local message = json.encode({
        embeds = {
            {

                ["color"] = Config.EmbedColorOff,
                ["title"] = '**'..Config.ServerName..'**',
                ["description"] = 'Server is offline',
            }
        },

        components = {
		{
			["type"] = 1,
			["components"] = {
				{
					["type"] = 2,
					["label"] = "Server offline",
					["style"] = 4,
					["url"] = "",
				}
			},
		}
	}

    })

    PerformHttpRequest(Config.Webhook..'/messages/'..Config.MessageId, function(err, text, headers)
        if Config.Debug then
            print('[DEBUG] err=', err)
            print('[DEBUG] text=', text)
        end
    end, 'PATCH', message, { ['Content-Type'] = 'application/json' })

end)

function Discord.SendLog(webhook, message)
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = "LOGS", content = message}), { ['Content-Type'] = 'application/json' })
end

local types = {
	["connexion"] = GetConvar("warv_webhook_connect", ""),
	["disconnect"] = GetConvar("warv_webhook_disconnect", ""),
	["new-user"] = GetConvar("warv_webhook_new_user", ""),
	["devtool"] = GetConvar("warv_webhook_devtool", ""),
	["ban"] = GetConvar("warv_webhook_ban", ""),
	["connexion-public"] = GetConvar("warv_webhook_connect_public", ""),
	["disconnect-public"] = GetConvar("warv_webhook_disconnect_public", ""),
	["softban-add"] = GetConvar("warv_webhook_softban", "")
}
function Discord.SendLogType(Type, message)
	if types[Type] ~= nil and types[Type] ~= "" then
		PerformHttpRequest(types[Type], function(err, text, headers) end, 'POST', json.encode({username = "LOGS", content = message}), { ['Content-Type'] = 'application/json' })
	end
end