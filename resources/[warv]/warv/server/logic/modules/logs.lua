local webhooks = {
    clientError = GetConvar("warv_webhook_client_error", ""),
    serverError = GetConvar("warv_webhook_server_error", ""),
}

local colorError = 15158332

local function trunc(s, n)
    s = tostring(s or "")
    if #s > n then return s:sub(1, n - 3) .. "..." end
    return s
end

local lastSent = {}
local function throttled(key)
    local now = GetGameTimer()
    if lastSent[key] and (now - lastSent[key]) < 4000 then return true end
    lastSent[key] = now
    return false
end

local function sendEmbed(webhook, embed)
    if webhook == "" then return end
    PerformHttpRequest(webhook, function() end, "POST", json.encode({
        username = "WarV Logs",
        embeds = { embed },
    }), { ["Content-Type"] = "application/json" })
end

local function serverError(message)
    if throttled("srv|" .. tostring(message)) then return end

    sendEmbed(webhooks.serverError, {
        color = colorError,
        title = "SERVER ERROR",
        description = "**Critical**\n```" .. trunc(message, 1400) .. "```",
        footer = { text = "WarV • " .. os.date("%d/%m/%Y %H:%M:%S") },
    })
end

local function clientError(src, data)
    if throttled("cli|" .. tostring(data.kind) .. "|" .. tostring(data.message)) then return end

    local fields = {
        { name = "Player", value = tostring(GetPlayerName(src) or "?") .. " (" .. tostring(src) .. ")", inline = true },
        { name = "Kind", value = tostring(data.kind or "error"), inline = true },
    }
    if data.source then
        fields[#fields + 1] = {
            name = "Location",
            value = trunc(tostring(data.source) .. ":" .. tostring(data.line or "?") .. ":" .. tostring(data.col or "?"), 300),
        }
    end
    if data.stack then
        fields[#fields + 1] = { name = "Stack", value = "```" .. trunc(data.stack, 1000) .. "```" }
    end
    if data.componentStack then
        fields[#fields + 1] = { name = "Component stack", value = "```" .. trunc(data.componentStack, 800) .. "```" }
    end

    sendEmbed(webhooks.clientError, {
        color = colorError,
        title = "CLIENT UI ERROR",
        description = "```" .. trunc(data.message or "unknown error", 1400) .. "```",
        fields = fields,
        footer = { text = "WarV • " .. os.date("%d/%m/%Y %H:%M:%S") },
    })
end

RegisterNetEvent("warv:reportClientError")
AddEventHandler("warv:reportClientError", function(data)
    if type(data) ~= "table" then return end
    clientError(source, data)
end)

local consoleCriticalPrint = CriticalPrint
function CriticalPrint(text)
    consoleCriticalPrint(text)
    serverError(text)
end
