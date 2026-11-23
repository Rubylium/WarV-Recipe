GamemodeSession = {}
GamemodeSession.__index = GamemodeSession

GamemodeSessionState = {
    Waiting = "waiting",
    Countdown = "countdown",
    Starting = "starting",
    Loading = "loading",
    Running = "running",
    Ending = "ending",
    Resetting = "resetting",
    Destroyed = "destroyed",
}

local function trace(err)
    return debug.traceback(tostring(err), 2)
end

local function setState(session, state)
    local game = session.game
    session.state = state
    game.state = state
    game.gameWaitingToStart = state == GamemodeSessionState.Waiting or state == GamemodeSessionState.Countdown
    game.gameStarting = state == GamemodeSessionState.Starting or state == GamemodeSessionState.Loading
    game.gameStarted = state == GamemodeSessionState.Running
    game.gameFinish = state == GamemodeSessionState.Ending or state == GamemodeSessionState.Resetting
    game.gameLocked = game.gameFinish
    if not game.gameWaitingToStart then
        game.gameCanStart = false
    end
end

function GamemodeSession.New(game, definition, factory)
    game.sessionGeneration = (game.sessionGeneration or 0) + 1
    local session = setmetatable({
        definition = definition,
        destroyed = false,
        ending = false,
        factory = factory,
        game = game,
        generation = game.sessionGeneration,
        instance = nil,
        loadingDeadlineAt = GetGameTimer() + (definition.loadingTimeoutMs or 180000),
        netRoutes = {},
    }, GamemodeSession)
    session.scope = GamemodeScope.New(session)
    setState(session, GamemodeSessionState.Starting)
    return session
end

function GamemodeSession:Start()
    return self.scope:Run("start", function()
        self.instance = self.factory({
            definition = self.definition,
            game = self.game,
            scope = self.scope,
            session = self,
        })
        setState(self, GamemodeSessionState.Loading)
        self.instance:start()
    end)
end

function GamemodeSession:MarkRunning()
    if not self.destroyed and not self.ending then
        setState(self, GamemodeSessionState.Running)
    end
end

function GamemodeSession:IsRunning()
    return not self.destroyed and self.state == GamemodeSessionState.Running
end

function GamemodeSession:HasLoadingTimedOut()
    return not self.destroyed
        and not self.ending
        and self.state == GamemodeSessionState.Loading
        and GetGameTimer() >= self.loadingDeadlineAt
end

function GamemodeSession:End(reason)
    if self.destroyed or self.ending then
        return false
    end
    self.ending = true
    setState(self, GamemodeSessionState.Ending)
    self.scope:Cancel()
    Citizen.CreateThread(function()
        local resetDelay = 0
        if self.instance and self.instance.stop then
            local ok, result = xpcall(self.instance.stop, trace, self.instance, reason)
            if not ok then
                CriticalPrint("Gamemode stop [" .. self.game.gameId .. "]: " .. result)
            elseif type(result) == "number" then
                resetDelay = math.max(0, result)
            end
        end

        Wait(resetDelay)
        self:Reset()
    end)
    return true
end

function GamemodeSession:Fail(origin, err)
    if self.destroyed or self.ending then
        return
    end
    CriticalPrint("Gamemode [" .. self.game.gameId .. "] " .. origin .. ": " .. tostring(err))
    self.ending = true
    setState(self, GamemodeSessionState.Ending)
    self.scope:Cancel()
    for _, player in ipairs(self.game.players) do
        self.scope:EmitClient(player.id, "StopGame", "runtime_error")
        TriggerClientEvent("warv:GoBackToLobby", player.id, self.game.gameId)
    end
    Citizen.CreateThread(function()
        self:Reset()
    end)
end

function GamemodeSession:Reset()
    if self.destroyed then
        return
    end
    setState(self, GamemodeSessionState.Resetting)
    if self.instance and self.instance.destroy then
        local ok, err = xpcall(self.instance.destroy, trace, self.instance)
        if not ok then
            CriticalPrint("Gamemode destroy [" .. self.game.gameId .. "]: " .. err)
        end
    end
    self.scope:Cancel()
    self.destroyed = true
    GamemodeSessionManager.sessions[self.game.gameId] = nil
    local ok, result = xpcall(Game.ResetLobbyForId, trace, self.game.gameId, true)
    if not ok or result == false then
        CriticalPrint("Lobby reset [" .. self.game.gameId .. "]: " .. tostring(result))
        setState(self, GamemodeSessionState.Waiting)
        self.game.gameCanStart = false
        self.game.gameWaitingToStartTimer = Game.DefaultLobbyValues.gameWaitingToStartTimer
        local refreshed, refreshError = xpcall(Game.RefreshCanStartStatus, trace, self.game.gameId)
        if not refreshed then
            CriticalPrint(refreshError)
        end
        Game.RefreshGameDataForLobby(self.game, self.game.players)
    end
end

function GamemodeSession:Destroy(reason)
    if self.destroyed then
        return
    end
    self.destroyed = true
    self.ending = true
    setState(self, GamemodeSessionState.Destroyed)
    if self.instance and self.instance.destroy then
        local ok, err = xpcall(self.instance.destroy, trace, self.instance, reason)
        if not ok then
            CriticalPrint(err)
        end
    end
    self.scope:Cancel()
end

GamemodeSessionManager = {
    sessions = {},
}

function GamemodeSessionManager.Start(game)
    if GamemodeSessionManager.sessions[game.gameId] ~= nil then
        return false, "session exists"
    end
    local definition = GamemodeDefinitions.Get(game.gamemode)
    if definition == nil or definition.implemented ~= true then
        return false, "not implemented: " .. tostring(game.gamemode)
    end
    local factory = GamemodeServerRegistry.Get(definition.id)
    if factory == nil then
        return false, "no factory: " .. definition.id
    end
    local session = GamemodeSession.New(game, definition, factory)
    GamemodeSessionManager.sessions[game.gameId] = session
    local started, startError = session:Start()
    if not started then
        return false, startError
    end
    return true, session
end

function GamemodeSessionManager.Get(gameId)
    return GamemodeSessionManager.sessions[gameId]
end

function GamemodeSessionManager.End(gameId, reason)
    local session = GamemodeSessionManager.sessions[gameId]
    return session ~= nil and session:End(reason)
end

function GamemodeSessionManager.Destroy(gameId, reason)
    local session = GamemodeSessionManager.sessions[gameId]
    if session == nil then
        return false
    end
    session:Destroy(reason)
    GamemodeSessionManager.sessions[gameId] = nil
    return true
end
