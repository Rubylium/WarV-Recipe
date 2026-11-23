ErrorCatcher = {}

local hooks = {
    client = GetConvar("warv_webhook_catch_client", ""),
    server = GetConvar("warv_webhook_catch_server", ""),
    mysql = GetConvar("warv_webhook_catch_mysql", ""),
}


function ErrorCatcher.SendClientErrorToDiscord(source, error)
    if hooks.client == "" then return end
    local discord = GetDiscord(source)
    local name = GetPlayerName(source)
    if discord == false then
        discord = "N/A"
    end
    local message = "Client side script error catched by "..name.." (<@"..tostring(discord)..">\n ```"..error.."```"
    PerformHttpRequest(hooks.client, function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end

function ErrorCatcher.SendServerErrorToDiscord(error)
    if hooks.server == "" then return end
    local message = "Server side script error catched\n ```"..error.."```"
    PerformHttpRequest(hooks.server, function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end

function ErrorCatcher.SendMysqlErrorToDiscord(error)
    if hooks.mysql == "" then return end
    local message = "MYSQL catched\n ```"..error.."```"
    PerformHttpRequest(hooks.mysql, function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end


RegisterNetEvent("error:Catch")
AddEventHandler("error:Catch", function(error)
    ErrorCatcher.SendClientErrorToDiscord(source, error)
end)

AddEventHandler("error:CatchMysql", function(error)
    ErrorCatcher.SendMysqlErrorToDiscord(error)
end)


Citizen.Trace = function(text)
    print(text)
    if #text ~= 0 then
        if string.find(text, "SCRIPT ERROR") then
            ErrorCatcher.SendServerErrorToDiscord(text)
        end
    end
end