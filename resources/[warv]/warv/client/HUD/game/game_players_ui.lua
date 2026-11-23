PlayersUI = {}

local markerVh = 14.0
local deadVh = 13.0
local minVh = 2.2
local maxVh = 6.5

local function pushMarker(markers, pPos, kind)
    local pos = vector3(pPos.x, pPos.y, pPos.z + 1.0)
    local ok, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z)
    if not ok then return end
    local dist = #(GetGameplayCamCoords() - pos)
    if dist < 0.01 then dist = 0.01 end
    local scale = (2.0 / dist) * (100.0 / GetGameplayCamFov())
    local raw = (kind == "dead" and deadVh or markerVh) * scale
    markers[#markers + 1] = {
        x = sx,
        y = sy,
        kind = kind,
        size = math.max(minVh, math.min(maxVh, raw)),
    }
end

local function pedOf(v)
    if v.bot then return NetworkGetEntityFromNetworkId(v.netId) end
    return GetPlayerPed(GetPlayerFromServerId(v.id))
end

function PlayersUI.Clear()
    exports["warv-ui"]:SetPlayerMarkers({})
end

function PlayersUI.DrawPlayersUI(players, myTeam)
    local playersToDisplay = {}
    local otherPlayers = {}
    local players1 = {}
    local players2 = {}
    local allPlayersAndBots = {}

    if myTeam ~= 0 then
        for k, v in pairs(players) do
            if v.team == 1 then
                table.insert(players1, v)
            elseif v.team == 2 then
                table.insert(players2, v)
            end
            table.insert(allPlayersAndBots, v)
        end
    elseif myTeam == 0 then
        for k, v in pairs(players) do
            table.insert(playersToDisplay, v)
            table.insert(allPlayersAndBots, v)
        end
    end

    for t = 1, 2 do
        for _, v in pairs(Bot.list[t] or {}) do
            if NetworkDoesNetworkIdExist(v.netId) then
                v.bot = true
                if v.team == 1 then
                    table.insert(players1, v)
                elseif v.team == 2 then
                    table.insert(players2, v)
                end
                table.insert(allPlayersAndBots, v)
            end
        end
    end

    if Gamemode.NoTeams then
        playersToDisplay = {}
        otherPlayers = allPlayersAndBots
    elseif myTeam == 1 then
        playersToDisplay = players1
        otherPlayers = players2
    elseif myTeam == 2 then
        playersToDisplay = players2
        otherPlayers = players1
    end

    local markers = {}

    local myID = Gamemode.utils.GetSID()
    local myPed = Gamemode.utils.GetPed()
    for k, v in pairs(otherPlayers) do
        if v.id ~= myID then
            local pPed = pedOf(v)
            local pPos = GetEntityCoords(pPed)
            if HasEntityClearLosToEntity(pPed, myPed, 17) and not IsEntityDead(pPed) and IsEntityVisible(pPed) and pPed ~= myPed then
                pushMarker(markers, pPos, "enemy")
            end
        end
    end

    local playerPed = Player.GetPed()
    for k, v in pairs(playersToDisplay) do
        if v.id ~= myID then
            local pPed = pedOf(v)
            local pPos = GetEntityCoords(pPed)
            if not IsEntityDead(pPed) and pPed ~= playerPed and IsEntityVisible(pPed) then
                pushMarker(markers, pPos, "friendly")
            elseif IsEntityVisible(pPed) and pPed ~= myPed then
                pushMarker(markers, pPos, "dead")
            end
        end
    end

    if Killstreaks.GetAllyDronePositions then
        for _, dPos in pairs(Killstreaks.GetAllyDronePositions()) do
            pushMarker(markers, dPos, "drone")
        end
    end

    if Killstreaks.GetFriendlyUavPositions then
        for _, uPos in pairs(Killstreaks.GetFriendlyUavPositions()) do
            pushMarker(markers, uPos, "friendly")
        end
    end

    exports["warv-ui"]:SetPlayerMarkers(markers)
end
