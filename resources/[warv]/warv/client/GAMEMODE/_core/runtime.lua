GamemodeRuntime = {
    current = nil,
    routeInstallers = {},
    threadOwners = setmetatable({}, {__mode = "k"}),
}

local function reportFailure(current, reason)
    TriggerServerEvent("warv:GamemodeClientFailed", current.gameId, current.generation, reason)
end

local function trace(err)
    return debug.traceback(tostring(err), 2)
end

function GamemodeRuntime.Prepare(sessionData)
    if type(sessionData) ~= "table"
        or type(sessionData.gameId) ~= "string"
        or type(sessionData.modeId) ~= "string"
        or type(sessionData.generation) ~= "number" then
        return false, "bad session"
    end

    if GamemodeRuntime.current ~= nil then
        GamemodeRuntime.Stop("replaced")
    end
    local adapter = GamemodeClientRegistry.Get(sessionData.modeId)
    if adapter == nil then
        return false, "unknown mode " .. sessionData.modeId
    end

    GamemodeRuntime.current = {
        adapter = adapter,
        gameId = sessionData.gameId,
        generation = sessionData.generation,
        localHandlers = {},
        modeId = sessionData.modeId,
        routes = {},
        active = true,
        started = false,
    }
    Status.SetCurrentGameId(sessionData.gameId)
    return true
end

function GamemodeRuntime.Start(fastLoad)
    local current = GamemodeRuntime.current
    if current == nil or current.started then
        return false
    end
    current.started = true
    local success, startError = xpcall(function()
        local context = {
            fastLoad = fastLoad == true,
            gameId = current.gameId,
            generation = current.generation,
            modeId = current.modeId,
        }
        for _, installRoutes in ipairs(GamemodeRuntime.routeInstallers) do
            installRoutes(context)
        end
        current.adapter.start(context)
    end, trace)
    if not success then
        Console.CriticalPrint("gamemode start: " .. startError)
        reportFailure(current, "startup_error")
        GamemodeRuntime.Stop("startup_error")
        return false
    end
    return true
end

function GamemodeRuntime.RegisterRouteInstaller(installRoutes)
    GamemodeRuntime.routeInstallers[#GamemodeRuntime.routeInstallers + 1] = installRoutes
end

function GamemodeRuntime.On(eventName, callback)
    local current = GamemodeRuntime.current
    if current == nil then
        return false
    end
    current.routes[eventName] = callback
    return true
end

function GamemodeRuntime.OnLocal(eventName, callback)
    local current = GamemodeRuntime.current
    if current == nil then
        return false
    end
    local handler = AddEventHandler(eventName, function(...)
        if GamemodeRuntime.current ~= current or not current.active then
            return
        end
        local success, handlerError = xpcall(callback, trace, ...)
        if not success and GamemodeRuntime.current == current and current.active then
            Console.CriticalPrint("gamemode event " .. eventName .. ": " .. handlerError)
            reportFailure(current, "local_event_error")
            GamemodeRuntime.Stop("event_error")
        end
    end)
    table.insert(current.localHandlers, handler)
    return true
end

function GamemodeRuntime.IsActive()
    local runningThread = coroutine.running()
    local owner = runningThread and GamemodeRuntime.threadOwners[runningThread] or nil
    if owner ~= nil then
        return GamemodeRuntime.current == owner and owner.active
    end
    return GamemodeRuntime.current ~= nil and GamemodeRuntime.current.active
end

function GamemodeRuntime.CreateThread(label, callback)
    local owner = GamemodeRuntime.current
    if owner == nil or not owner.active then
        return false
    end
    Citizen.CreateThread(function()
        local runningThread = coroutine.running()
        GamemodeRuntime.threadOwners[runningThread] = owner
        if GamemodeRuntime.current ~= owner or not owner.active then
            GamemodeRuntime.threadOwners[runningThread] = nil
            return
        end
        local success, threadError = xpcall(callback, trace)
        GamemodeRuntime.threadOwners[runningThread] = nil
        if not success and GamemodeRuntime.current == owner and owner.active then
            Console.CriticalPrint("gamemode thread " .. label .. ": " .. threadError)
            reportFailure(owner, "thread_error")
            GamemodeRuntime.Stop("thread_error")
        end
    end)
    return true
end

function GamemodeRuntime.EmitServer(eventName, ...)
    local current = GamemodeRuntime.current
    if current == nil then
        return false
    end
    TriggerServerEvent(
        "warv:GamemodeEvent",
        current.gameId,
        current.generation,
        eventName,
        table.pack(...)
    )
    return true
end

function GamemodeRuntime.Fail(reason)
    local current = GamemodeRuntime.current
    if current == nil then
        return
    end
    reportFailure(current, reason)
    GamemodeRuntime.Stop(reason)
end

function GamemodeRuntime.Stop(reason)
    local current = GamemodeRuntime.current
    if current == nil then
        return
    end
    current.active = false
    current.routes = {}
    for _, handler in ipairs(current.localHandlers) do
        RemoveEventHandler(handler)
    end
    current.localHandlers = {}
    if current.started then
        local success, stopError = xpcall(current.adapter.stop, trace, reason)
        if not success then
            Console.CriticalPrint(stopError)
        end
    end
    GamemodeRuntime.current = nil
end

RegisterNetEvent("warv:GamemodeEvent", function(gameId, generation, eventName, arguments)
    local current = GamemodeRuntime.current
    if current == nil
        or current.gameId ~= gameId
        or current.generation ~= tonumber(generation)
        or type(eventName) ~= "string"
        or type(arguments) ~= "table" then
        return
    end
    local route = current.routes[eventName]
    if not route then
        return
    end
    local success, routeError = xpcall(route, trace, table.unpack(arguments, 1, arguments.n or #arguments))
    if not success then
        Console.CriticalPrint("gamemode route " .. eventName .. ": " .. routeError)
        reportFailure(current, "network_event_error")
        GamemodeRuntime.Stop("event_error")
    end
end)
