GameSnapshot = {}

local playerFields = {
    "bestStreak",
    "deaths",
    "emblem",
    "gameLoaded",
    "id",
    "inGroup",
    "kills",
    "level",
    "logo",
    "losses",
    "name",
    "perms",
    "prestige",
    "ranking",
    "uid",
    "voted",
    "winStreak",
    "wins",
}

local function copyPlayer(player)
    local result = {}
    for _, field in ipairs(playerFields) do
        result[field] = player[field]
    end
    return result
end

function GameSnapshot.Build(game)
    local players = {}
    for _, player in ipairs(game.players) do
        table.insert(players, copyPlayer(player))
    end

    return {
        aimMode = game.aimMode,
        gameBucket = game.gameBucket,
        gameCanStart = game.gameCanStart,
        gameId = game.gameId,
        gameLocked = game.gameLocked,
        gameMap = game.gameMap,
        gameMap1 = game.gameMap1,
        gameMap2 = game.gameMap2,
        gameMapVote1 = game.gameMapVote1,
        gameMapVote2 = game.gameMapVote2,
        gameMapVoteRandom = game.gameMapVoteRandom,
        gameMapVoted = game.gameMapVoted,
        gameStarted = game.gameStarted,
        gameStarting = game.gameStarting,
        gameTimer = game.gameTimer,
        gameWaitingToStart = game.gameWaitingToStart,
        gameWaitingToStartTimer = game.gameWaitingToStartTimer,
        gamemode = game.gamemode,
        mapRandom = game.mapRandom,
        maxPlayer = game.maxPlayer,
        modeId = game.modeId,
        players = players,
        ranked = game.ranked,
        sessionGeneration = game.sessionGeneration,
        state = game.state,
    }
end
