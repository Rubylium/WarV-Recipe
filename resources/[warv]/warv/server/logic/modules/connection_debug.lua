ConnectionDebug = {
    sessions = {},
    nextId = 0,
}

local function IsEnabled()
    local value = string.lower(GetConvar("warv_connection_debug", "0"))
    return value ~= "0" and value ~= "false" and value ~= "off"
end

local function Sanitize(value)
    return tostring(value or ""):gsub("[\r\n]", " ")
end

local function GetElapsedMs(session)
    if session == nil then
        return 0
    end

    return GetGameTimer() - session.startedAt
end

function ConnectionDebug.Begin(source, playerName)
    ConnectionDebug.nextId = ConnectionDebug.nextId + 1

    local session = {
        id = string.format("%s-%04d", tostring(source), ConnectionDebug.nextId),
        playerName = Sanitize(playerName),
        startedAt = GetGameTimer(),
    }

    ConnectionDebug.sessions[source] = session
    ConnectionDebug.Log(source, "received", "name=" .. session.playerName)
    return session.id
end

function ConnectionDebug.Log(source, stage, details)
    if not IsEnabled() then
        return
    end

    local session = ConnectionDebug.sessions[source]
    local reference = session and session.id or tostring(source)
    local playerName = session and session.playerName or Sanitize(GetPlayerName(source) or "unknown")
    local suffix = details and details ~= "" and " | " .. Sanitize(details) or ""

    print(string.format(
        "^5[CONNECTION]^7 [%s] +%dms source=%s name=%s stage=%s%s",
        reference,
        GetElapsedMs(session),
        tostring(source),
        playerName,
        Sanitize(stage),
        suffix
    ))
end

function ConnectionDebug.Finish(source, outcome, details)
    ConnectionDebug.Log(source, "finished:" .. tostring(outcome), details)
    ConnectionDebug.sessions[source] = nil
end

function ConnectionDebug.Forget(source, reason)
    ConnectionDebug.Log(source, "forgotten", reason)
    ConnectionDebug.sessions[source] = nil
end
