GamemodeServerRegistry = {
    factories = {},
}

function GamemodeServerRegistry.Register(modeId, factory)
    GamemodeServerRegistry.factories[modeId] = factory
end

function GamemodeServerRegistry.Get(modeId)
    return GamemodeServerRegistry.factories[modeId]
end

function GamemodeServerRegistry.IsRegistered(modeId)
    return GamemodeServerRegistry.factories[modeId] ~= nil
end
