local inQueue = {}
local queueCount = 0
local playersNameInQueue = ""
local queueMainMessage = "You have been placed in a queue to prevent servers from going above capacity.\n"

local function RemoveQueueEntry(queueEntry)
    for index, entry in ipairs(inQueue) do
        if entry == queueEntry then
            table.remove(inQueue, index)
            return
        end
    end
end

function ExitServerQueue(source, reason)
    for index, queueEntry in ipairs(inQueue) do
        if queueEntry.source == source then
            queueEntry.cancelled = true
            queueEntry.cancelReason = reason or "unknown"
            table.remove(inQueue, index)
            return true
        end
    end

    return false
end

function EnterServerQueue(def, source)
    local queueEntry = {
        source = source,
        time = 0,
        pos = 1,
        canEnter = false,
        cancelled = false,
        name = GetPlayerName(source),
        def = def,
    }

    table.insert(inQueue, queueEntry)
    queueCount = #inQueue
    queueEntry.pos = queueCount
    playersNameInQueue = playersNameInQueue
        .. (playersNameInQueue ~= "" and ", " or "")
        .. string.format("[%d]%s", queueEntry.pos, queueEntry.name or "unknown")

    while not queueEntry.canEnter and not queueEntry.cancelled do
        local updateMessage = queueMainMessage
            .. "Players count in queue: " .. queueCount
            .. "\nTime: " .. queueEntry.time .. "s"
            .. "\nPosition: " .. queueEntry.pos .. "/" .. queueCount
            .. "\n" .. playersNameInQueue

        local updated, updateError = pcall(def.update, updateMessage)
        if not updated then
            queueEntry.cancelled = true
            RemoveQueueEntry(queueEntry)
            ConnectionDebug.Finish(source, "queue_update_failed", tostring(updateError))
            return
        end

        queueEntry.time = queueEntry.time + 1
        Wait(1000)
    end

    if queueEntry.cancelled then
        pcall(def.done, "Queue session lost. Reconnect.")
        ConnectionDebug.Finish(source, "queue_cancelled", "reason=" .. tostring(queueEntry.cancelReason))
        return
    end

    ConnectionDebug.Finish(source, "admitted")
end

Citizen.CreateThread(function()
    while true do
        local names = {}

        for index = #inQueue, 1, -1 do
            local queueEntry = inQueue[index]

            if GetPlayerName(queueEntry.source) == nil then
                if queueEntry.sourceMissingAt == nil then
                    queueEntry.sourceMissingAt = GetGameTimer()
                elseif GetGameTimer() - queueEntry.sourceMissingAt >= 5000 then
                    queueEntry.cancelled = true
                    queueEntry.cancelReason = "source_missing_timeout"
                    table.remove(inQueue, index)
                end
            else
                queueEntry.sourceMissingAt = nil
            end
        end

        for index, queueEntry in ipairs(inQueue) do
            queueEntry.pos = index
            names[#names + 1] = string.format("[%d]%s", index, queueEntry.name or "unknown")
        end

        queueCount = #inQueue
        playersNameInQueue = table.concat(names, ", ")
        Wait(250)
    end
end)

Citizen.CreateThread(function()
    while true do
        if GetNumPlayerIndices() < GetConvarInt("sv_maxclients", 48) and #inQueue > 0 then
            local queueEntry = inQueue[1]
            local done, doneError = pcall(queueEntry.def.done)
            if done then
                queueEntry.canEnter = true
                table.remove(inQueue, 1)
                InfoPrint("Sending player " .. tostring(queueEntry.name) .. " on the server.")
            else
                ConnectionDebug.Log(queueEntry.source, "queue:admission_failed", tostring(doneError))
            end
        end

        Wait(1000)
    end
end)
