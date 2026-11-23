function MatchLogic.AttachExplosionHandler(instance, gamePlayersData)
    function instance:onExplosion(sender, explosion)
        local sourceIsInGame = false
        for _, player in pairs(gamePlayersData) do
            if tonumber(player.id) == tonumber(sender) then
                sourceIsInGame = true
                break
            end
        end
        if not sourceIsInGame or not SharedConfig.ExplosionSounds[explosion.explosionType] then
            return
        end

        local data = {
            type = explosion.explosionType,
            pos = vector3(explosion.posX, explosion.posY, explosion.posZ),
        }
        for _, player in pairs(gamePlayersData) do
            TriggerClientEvent("warv:explosionSound", player.id, data)
        end
    end
end
