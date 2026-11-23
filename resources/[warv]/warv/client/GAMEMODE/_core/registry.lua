GamemodeClientRegistry = {
    adapters = {},
}

function GamemodeClientRegistry.Register(modeId, adapter)
    GamemodeClientRegistry.adapters[modeId] = adapter
end

function GamemodeClientRegistry.Get(modeId)
    return GamemodeClientRegistry.adapters[modeId]
end
