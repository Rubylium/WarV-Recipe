function Medals.ShowMedal(medal, gameID)
    if medal == nil or gameID == nil or tostring(gameID) == "0" then return end
    if Status.GetIsPlayerInEndScreen() then return end

    exports['warv-ui']:ShowMedal({
        image = medal.sprite,
        label = medal.label,
        points = medal.points,
    })
end
