GamemodeDefinitions = {
    byId = {},
    byName = {},
}

function GamemodeDefinitions.Register(def)
    GamemodeDefinitions.byId[def.id] = def
    GamemodeDefinitions.byName[def.name] = def
end

function GamemodeDefinitions.Get(id)
    return GamemodeDefinitions.byId[id] or GamemodeDefinitions.byName[id]
end

function GamemodeDefinitions.IsImplemented(id)
    local def = GamemodeDefinitions.Get(id)
    return def ~= nil and def.implemented == true
end

GamemodeDefinitions.Register({
    id = "tdm",
    name = "TEAM DEATHMATCH",
    implemented = true,
    capabilities = {
        bots = true,
        killstreaks = true,
        lateJoin = true,
        loadout = true,
        respawn = true,
        teams = true,
    },
    rules = { scoreLimit = 75 },
    objective = "Eliminate enemy players.",
    mapRequirements = {},
})

GamemodeDefinitions.Register({
    id = "ffa",
    name = "FFA",
    implemented = true,
    capabilities = {
        bots = true,
        killstreaks = true,
        lateJoin = true,
        loadout = true,
        respawn = true,
        teams = false,
    },
    rules = { fragLimit = 30 },
    objective = "Free for all. Highest kills wins.",
    mapRequirements = {},
})

GamemodeDefinitions.Register({
    id = "gungame",
    name = "GUN GAME",
    implemented = true,
    capabilities = {
        bots = true,
        killstreaks = false,
        lateJoin = true,
        loadout = false,
        respawn = true,
        teams = false,
    },
    rules = { fragLimit = #GunGame.ladder },
    objective = "Every kill moves you up. Finish the ladder to win.",
    mapRequirements = {},
})

