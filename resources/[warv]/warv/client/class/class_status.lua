Status = {}
Status.IsPlayerInGame = false
Status.InEndScreen = false
Status.CurrentGameId = 0
Status.gameStarted = false

function Status.GetIsPlayerInGame()
    return Status.IsPlayerInGame
end

function Status.SetIsPlayerInGame(value)
    Status.IsPlayerInGame = value
end

function Status.GetIsPlayerInEndScreen()
    return Status.InEndScreen
end

function Status.SetIsPlayerInEndScreen(value)
    Status.InEndScreen = value
end

function Status.GetCurrentGameId()
    return Status.CurrentGameId
end

function Status.SetCurrentGameId(value)
    Status.CurrentGameId = value
end
