GamemodeScope = {}
GamemodeScope.__index = GamemodeScope

local function trace(err)
    return debug.traceback(tostring(err), 2)
end

function GamemodeScope.New(session)
    return setmetatable({
        active = true,
        session = session,
    }, GamemodeScope)
end

function GamemodeScope:IsActive()
    return self.active and not self.session.destroyed
end

function GamemodeScope:Run(label, callback, ...)
    if not self:IsActive() then
        return false
    end

    local result = table.pack(xpcall(callback, trace, ...))
    if not result[1] then
        self.session:Fail(label, result[2])
        return false, result[2]
    end

    return true, table.unpack(result, 2, result.n)
end

function GamemodeScope:CreateThread(label, callback)
    Citizen.CreateThread(function()
        self:Run("thread:" .. label, callback)
    end)
end

function GamemodeScope:SetTimeout(label, delay, callback)
    self:CreateThread("timeout:" .. label, function()
        Wait(delay)
        if self:IsActive() then
            callback()
        end
    end)
end

function GamemodeScope:OnNet(eventName, callback)
    self.session.netRoutes[eventName] = callback
end

function GamemodeScope:EmitClient(playerSource, eventName, ...)
    TriggerClientEvent(
        "warv:GamemodeEvent",
        playerSource,
        self.session.game.gameId,
        self.session.generation,
        eventName,
        table.pack(...)
    )
end

function GamemodeScope:Cancel()
    self.active = false
    self.session.netRoutes = {}
end
