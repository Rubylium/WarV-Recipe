EndScreen = {}
EndScreen.InAnimation = false
EndScreen.celeb = {
    [1] = {
        dict = "anim@mp_player_intcelebrationmale@photography",
        animation = "photography",
    },
    [2] = {
        dict = "anim@mp_player_intcelebrationmale@rock",
        animation = "rock",
    },
    [3] = {
        dict = "anim@mp_player_intcelebrationmale@you_loco",
        animation = "you_loco",
    },
    [4] = {
        dict = "anim@mp_player_intcelebrationmale@thumbs_up",
        animation = "thumbs_up",
    },
    [5] = {
        dict = "anim@mp_player_intcelebrationmale@thumbs_up",
        animation = "thumbs_up",
    },
    [6] = {
        dict = "anim@mp_player_intcelebrationmale@thumbs_up",
        animation = "thumbs_up",
    },
}

function EndScreen.Draw(players)
    Lobby.LockControls()

    local nearDof = 1.0
    local farDof = 3.5
    SetUseHiDof()

    local cammy = cam.Get("ENDSCREEN")
    SetCamDofStrength(cammy, 1.0)
    SetCamNearDof(cammy, nearDof)
    SetCamFarDof(cammy, farDof)
    SetCamUseShallowDofMode(cammy, true)

    local cammy = cam.Get("ENDSCREEN_2")
    SetCamDofStrength(cammy, 1.0)
    SetCamNearDof(cammy, nearDof)
    SetCamFarDof(cammy, farDof)
    SetCamUseShallowDofMode(cammy, true)

    local nearDof = 1.0
    local farDof = 4.5

    local cammy = cam.Get("ENDSCREEN_3")
    SetCamDofStrength(cammy, 1.0)
    SetCamNearDof(cammy, nearDof)
    SetCamFarDof(cammy, farDof)
    SetCamUseShallowDofMode(cammy, true)
end



EndScreen.celebNew = {
    {"anim@heists@heist_corona@single_team", "single_team_loop_one"},
    {"anim@heists@heist_corona@single_team", "single_team_loop_boss"},
    {"anim@heists@heist_corona@single_team", "single_team_loop_two"},
    {"anim@heists@heist_corona@single_team", "single_team_loop_three"},
}

EndScreen.PodiumOffsets = {
    { x = 0.0, y = 2.0, z = -1.0 },
    { x = -1.5, y = 3.0, z = -1.0 },
    { x = 1.5, y = 3.0, z = -1.0 },
    { x = -3.0, y = 5.0, z = -1.0 },
    { x = 3.0, y = 5.0, z = -1.0 },
    { x = -5.5, y = 7.0, z = -1.0 },
}
EndScreen.PodiumShown = 5

function EndScreen.NewEndScreen(pos, players, win, draw, soloGamemode)
    EndScreen.InAnimation = true
    for k,v in pairs(EndScreen.celebNew) do
        LoadAnimDict(v[1])
    end

    for v in EnumeratePeds() do
        SetEntityAlpha(v, 0, true)
    end

    local ostStyleId = math.random(1,3)
    local endscreenActive = true
    local tempPeds = {}
    local pos = pos
    LoadModel("mp_m_freemode_01")
    local ped = CreatePed(5, GetHashKey("mp_m_freemode_01"), pos.xyz, pos.w, false, true)

    local try = 0
    while not DoesEntityExist(ped) do
        try = try + 1
        if try > 3 then
            DeleteEntity(ped)
            try = 0
            ped = CreatePed(5, GetHashKey("mp_m_freemode_01"), pos.xyz, pos.w, false, true)
        end
        RealWait(100)
    end
    PlaceObjectOnGroundProperly(ped)
    SetVehicleOnGroundProperly(ped)
    SetEntityVisible(ped, false, 1)
    FreezeEntityPosition(ped, true)

    local zones = {}
    for index, offset in ipairs(EndScreen.PodiumOffsets) do
        zones[index] = { pos = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z) }
    end


    table.sort(players, function(first, second)
        if (first.score or 0) == (second.score or 0) then
            if (first.kill or 0) == (second.kill or 0) then
                return (first.death or 0) < (second.death or 0)
            end
            return (first.kill or 0) > (second.kill or 0)
        end
        return (first.score or 0) > (second.score or 0)
    end)

    local places = {}
    for index = 1, math.min(EndScreen.PodiumShown, #players) do
        local participant = players[index]
        participant.pos = zones[index]
        participant.emblem = participant.emblemsId
        participant.logo = participant.logoId
        table.insert(places, participant)
    end

    local validPlaces = {}
    for _, participant in pairs(places) do
        local sourceEntity = 0
        if participant.bot then
            sourceEntity = Bot.GetEntityById(participant.id)
        else
            local player = GetPlayerFromServerId(tonumber(participant.id))
            if player ~= -1 then
                sourceEntity = GetPlayerPed(player)
            end
        end

        if sourceEntity ~= 0 and DoesEntityExist(sourceEntity) then
            participant.entity = ClonePed(sourceEntity, false, true, false)
        else
            participant.entity = CreatePed(4, GetHashKey("mp_m_freemode_01"), participant.pos.pos.xyz, pos.w, false, true)
            if participant.entity ~= nil and participant.entity ~= 0 and participant.bot then
                Appearance.ApplyOutfit(participant.entity, participant.outfit)
            end
        end

        if participant.entity ~= nil and participant.entity ~= 0 and DoesEntityExist(participant.entity) then
            Player.Revive(participant.entity)
            ResetEntityAlpha(participant.entity)
            SetEntityVisible(participant.entity, true, false)
            FreezeEntityPosition(participant.entity, true)
            SetEntityInvincible(participant.entity, true)
            SetBlockingOfNonTemporaryEvents(participant.entity, true)
            SetEntityCoordsNoOffset(participant.entity, participant.pos.pos.xyz, false, false, false)
            SetEntityHeading(participant.entity, pos.w - 180)

            local randomAnim = EndScreen.celebNew[math.random(1,#EndScreen.celebNew)]
            TaskPlayAnim(participant.entity, randomAnim[1], randomAnim[2], 1.0, 1.0, -1, 8, -1, false, false, false)
            table.insert(tempPeds, participant.entity)
            table.insert(validPlaces, participant)
        end
    end
    places = validPlaces

    DoScreenFadeOut(200)
    RealWait(200)
    PlayCustomSound("ui/match_end/loop_".. ostStyleId ..".ogg", Settings.MusicsVolume, true)
    DeleteEntity(ped)
    local spawnZone = zones[1].pos

    cam.create("ENDSCREEN_2")
    cam.create("ENDSCREEN")

    cam.setFov("ENDSCREEN", 40.0)
    cam.setPos("ENDSCREEN", vector3(pos.x, pos.y, pos.z - 0.1))
    cam.lookAtCoords("ENDSCREEN", vector3(spawnZone.x, spawnZone.y, spawnZone.z + 0.2))
    cam.render("ENDSCREEN", true, false, 0)
    local done = false

    local mySID = Gamemode.utils.GetSID()
    local function isMe(participant)
        if participant.bot then return nil end
        return tonumber(participant.id) == tonumber(mySID) or nil
    end

    local podiumRoster = {}
    for index, participant in ipairs(places) do
        podiumRoster[index] = {
            place = index,
            name = tostring(participant.name or ""),
            id = participant.id,
            team = tonumber(participant.team),
            me = isMe(participant),
        }
    end
    exports['warv-ui']:SetPodium({
        visible = true,
        total = #podiumRoster,
        players = podiumRoster,
    })

        Citizen.CreateThread(function()
            for k,v in pairs(places) do
                local EntityPos = GetEntityCoords(v.entity)
                local firstPos = GetOffsetFromEntityInWorldCoords(v.entity, 0.5, 1.5, 0.55)

                local deaths = v.death or 0
                local kills = v.kill or 0
                local ratio = deaths > 0 and math.round(kills / deaths, 3) or kills
                exports['warv-ui']:SetPodium({
                    visible = true,
                    total = #podiumRoster,
                    player = {
                        place = k,
                        name = tostring(v.name or ""),
                        score = tonumber(v.score) or 0,
                        kills = kills,
                        deaths = deaths,
                        ratio = ratio,
                        id = v.id,
                        level = tonumber(v.level),
                        team = tonumber(v.team),
                        me = isMe(v),
                        card = MenuUI.CallingCardSprite(v.emblemsId),
                    },
                })


                cam.setFov("ENDSCREEN_2", 30.0)
                cam.setPos("ENDSCREEN_2", vector3(firstPos.x, firstPos.y, firstPos.z))
                cam.lookAtCoords("ENDSCREEN_2", vector3(EntityPos.x, EntityPos.y, EntityPos.z + 0.55))
                cam.switchToCam("ENDSCREEN_2", "ENDSCREEN", 200)

                RealWait(150)

                local firstPos = GetOffsetFromEntityInWorldCoords(v.entity, 0.3, 1.5, 0.5)


                cam.setFov("ENDSCREEN", 25.0)
                cam.setPos("ENDSCREEN", vector3(firstPos.x, firstPos.y, firstPos.z))
                cam.lookAtCoords("ENDSCREEN", vector3(EntityPos.x, EntityPos.y, EntityPos.z + 0.55))
                cam.switchToCam("ENDSCREEN", "ENDSCREEN_2", 4000)
                RealWait(4000)
            end
            done = true
        end)
    



    exports['warv-ui']:SetPodium({ visible = true })
    DoScreenFadeIn(500)

    Citizen.CreateThread(function()
        while endscreenActive do
            EndScreen.Draw(places)
            Wait(1)
        end
    end)
    
    while not done do
        Wait(1)
    end
    Sounds.StopAllSounds()
    PlayCustomSound("ui/match_end/outro_".. ostStyleId ..".ogg", Settings.MusicsVolume, false)

    cam.create("ENDSCREEN_3")
    cam.setFov("ENDSCREEN_3", 60.0)
    cam.setPos("ENDSCREEN_3", vector3(pos.x, pos.y, pos.z + 0.5))
    cam.lookAtCoords("ENDSCREEN_3", vector3(spawnZone.x, spawnZone.y, spawnZone.z + 0.2))
    exports['warv-ui']:SetPodium({ visible = true, summary = true })
    cam.switchToCam("ENDSCREEN_3", "ENDSCREEN", 2000)
    RealWait(2500)
    DoScreenFadeOut(1500)
    RealWait(1500)
    exports['warv-ui']:SetPodium({ visible = false })

    endscreenActive = false
    for k,v in pairs(tempPeds) do
        SetEntityAsNoLongerNeeded(v)
        DeleteEntity(v)
    end

    for v in EnumeratePeds() do
        ResetEntityAlpha(v)
    end

    cam.delete("ENDSCREEN")
    cam.delete("ENDSCREEN_2")
    cam.delete("ENDSCREEN_3")
    EndScreen.InAnimation = false
end

function EndScreen.EndScreen(pos, players, win, draw, soloGamemode)
    EndScreen.NewEndScreen(pos, players, win, draw, soloGamemode)
end
