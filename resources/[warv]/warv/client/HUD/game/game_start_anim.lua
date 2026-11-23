StartScreen = {}
StartScreen.DisplayCard = true
StartScreen.InAnimation = false
StartScreen.PedsToShow = {}
StartScreen.celebNew = {
    {"mp_deathmatch_intros@unarmed", "intro_male_unarmed_a"},
    {"mp_deathmatch_intros@unarmed", "intro_male_unarmed_b"},
    {"mp_deathmatch_intros@unarmed", "intro_male_unarmed_c"},
    {"mp_deathmatch_intros@unarmed", "intro_male_unarmed_d"},
    {"mp_deathmatch_intros@unarmed", "intro_male_unarmed_e"},
}

function StartScreen.Draw(players)
    if Gamemode.Team == 0 then
        Gamemode.Team = 2
    end

    if StartScreen.DisplayCard then
        local nearDof = 1.0
        local farDof = 3.5
        SetUseHiDof()

        local cammy = cam.Get("StartScreen")
        SetCamDofStrength(cammy, 3.0)
        SetCamNearDof(cammy, nearDof)
        SetCamFarDof(cammy, farDof)
        SetCamUseShallowDofMode(cammy, true)

        cammy = cam.Get("StartScreen_2")
        SetCamDofStrength(cammy, 3.0)
        SetCamNearDof(cammy, nearDof)
        SetCamFarDof(cammy, farDof)
        SetCamUseShallowDofMode(cammy, true)
    end

    for v in EnumeratePeds() do
        if StartScreen.PedsToShow[v] == nil then
            SetEntityAlpha(v, 0, true)
        end
    end

    Lobby.LockControls()
end

local tag
local tagSmooth = 0.14

function StartScreen.ProjectFocusTag()
    local f = StartScreen.focus
    if not f or not f.entity or not DoesEntityExist(f.entity) then return end
    local head = GetPedBoneCoords(f.entity, 0x796E, 0.0, 0.0, 0.32)

    if not tag or tag.key ~= f.key then
        tag = { key = f.key, x = head.x, y = head.y, z = head.z }
    else
        tag.x = tag.x + (head.x - tag.x) * tagSmooth
        tag.y = tag.y + (head.y - tag.y) * tagSmooth
        tag.z = tag.z + (head.z - tag.z) * tagSmooth
    end

    local ok, sx, sy = World3dToScreen2d(tag.x, tag.y, tag.z)
    exports['warv-ui']:SetIntroTag({
        visible = ok == true,
        name = f.name or "",
        key = f.key or 0,
        x = sx or 0.5,
        y = sy or 0.5,
        teamColor = Gamemode.Team == 1 and "blue" or "red",
    })
end

StartScreen.ShowcaseOffsets = {
    { x = 2.4, y = 3.0, z = -1.0 },
    { x = 1.2, y = 2.5, z = -1.0 },
    { x = 0.0, y = 2.0, z = -1.0 },
    { x = -1.2, y = 2.5, z = -1.0 },
    { x = -2.4, y = 3.0, z = -1.0 },
    { x = 0.0, y = 4.5, z = -0.7 },
    { x = 0.0, y = -3.0, z = -0.7 },
}
StartScreen.ShowcaseShown = 5

function StartScreen.NewStartScreen(pos, players)
    StartScreen.InAnimation = true
    StartScreen.PedsToShow = {}
    for k,v in pairs(StartScreen.celebNew) do
        LoadAnimDict(v[1])
    end

    for v in EnumeratePeds() do
        SetEntityAlpha(v, 0, true)
    end

    local ostStyleId = math.random(1,4)
    local StartScreenActive = true
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
    for index, offset in ipairs(StartScreen.ShowcaseOffsets) do
        zones[index] = { pos = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z) }
    end


    local places = {}
    for index = 1, math.min(StartScreen.ShowcaseShown, #players) do
        local participant = players[index]
        participant.pos = zones[index]
        table.insert(places, participant)
    end

    local FirstPed
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
            ResetEntityAlpha(participant.entity)
            SetEntityVisible(participant.entity, true, false)
            SetBlockingOfNonTemporaryEvents(participant.entity, true)
            SetEntityCoordsNoOffset(participant.entity, participant.pos.pos.xyz, false, false, false)
            SetEntityHeading(participant.entity, pos.w - 180)

            if FirstPed == nil then
                FirstPed = participant.entity
            end

            StartScreen.PedsToShow[participant.entity] = true
            table.insert(tempPeds, participant.entity)
            table.insert(validPlaces, participant)
        end
    end
    places = validPlaces

    if not IsScreenFadedOut() then
        DoScreenFadeOut(200)
        RealWait(200)
    end
    PlayCustomSound("ui/match_start/start_".. ostStyleId ..".mp3",
        Settings.GetScaledVolume(Settings.MusicsVolume, 0.045, 0.02), false)
    DeleteEntity(ped)

    cam.create("StartScreen_2")
    cam.create("StartScreen")

    local done = false

    StartScreen.DisplayCard = true
    local MyPed = GetPlayerPed(GetPlayerFromServerId(Player.GetServerId()))

    StartScreen.focus = nil
    local function pushIntro()
        exports['warv-ui']:SetMatchIntro({
            visible = true,
            map = string.upper(tostring(Matchmaking.selectedMap.name or "")),
            gamemode = string.upper(tostring(Matchmaking.data.gamemode or ""):gsub("~%a~", "")),
            team = Gamemode.Team == 1 and "ISA" or "MERCS",
            teamColor = Gamemode.Team == 1 and "blue" or "red",
            name = "",
            nameKey = 0,
        })
    end
    pushIntro()

    Citizen.CreateThread(function()

        Citizen.CreateThread(function()
            Utils.RealWait(1000)
            if Matchmaking.selectedMap.name == nil or Matchmaking.selectedMap.name == "DEBUG" then
                Matchmaking.selectedMap.name = "DEBUG MAP TEST"
                Matchmaking.selectedMap.description = "This is a debug description for a map loading!"
                Matchmaking.selectedMap.spritePreview = "map_construct"
                Matchmaking.selectedMap.uiImage = "construct"

                MapLoader.maxAsset = 100
                MapLoader.currentAsset = MapLoader.currentAsset + 0.1
                if MapLoader.currentAsset > MapLoader.maxAsset then
                    MapLoader.currentAsset = 0
                end

                Matchmaking.data.gamemode = "TEAM DEATHMATCH"
            end
            pushIntro()
        end)

        for k,v in pairs(places) do
            if v.id == Player.GetServerId() then
                MyPed = v.entity
            end
            local firstPos = GetOffsetFromEntityInWorldCoords(v.entity, 0.0, 2.5, 0.55)
            local lookAt = GetOffsetFromEntityInWorldCoords(v.entity, -0.5, 0.0, 0.55)

            StartScreen.focus = { entity = v.entity, name = v.name or "", key = k }


            cam.setFov("StartScreen_2", 30.0)
            cam.setPos("StartScreen_2", vector3(firstPos.x, firstPos.y, firstPos.z))
            cam.lookAtCoords("StartScreen_2", vector3(lookAt.x, lookAt.y, lookAt.z))
            if k ~= 1 then
                cam.switchToCam("StartScreen_2", "StartScreen", 500)
            else
                cam.render("StartScreen_2", true, false, 0)
            end
            
            if IsScreenFadedOut() then
                DoScreenFadeIn(200)
            end

            local randomAnim = StartScreen.celebNew[math.random(1,#StartScreen.celebNew)]
            TaskPlayAnim(v.entity, randomAnim[1], randomAnim[2], 1.0, 1.0, -1, 2, -1, false, false, false)
            RealWait(450)

            local firstPos = GetOffsetFromEntityInWorldCoords(v.entity, 0.0, 2.5, 0.5)


            cam.setFov("StartScreen", 25.0)
            cam.setPos("StartScreen", vector3(firstPos.x, firstPos.y, firstPos.z))
            cam.lookAtCoords("StartScreen", vector3(lookAt.x, lookAt.y, lookAt.z))
            cam.switchToCam("StartScreen", "StartScreen_2", 1700)
            RealWait(1600)
        end
        done = true
        StartScreen.DisplayCard = false
    end)




    Citizen.CreateThread(function()
        while StartScreenActive do
            StartScreen.Draw(places)
            StartScreen.ProjectFocusTag()
            Wait(1)
        end
    end)

    while not done do
        Wait(1)
    end



    local firstPos = zones[7].pos
    local lookAt = zones[6].pos


    cam.setFov("StartScreen_2", 40.0)
    cam.setPos("StartScreen_2", vector3(firstPos.x, firstPos.y, firstPos.z))
    cam.lookAtCoords("StartScreen_2", vector3(lookAt.x, lookAt.y, lookAt.z))
    cam.switchToCam("StartScreen_2", "StartScreen", 500)
    RealWait(600)

    local lookAt = GetOffsetFromEntityInWorldCoords(MyPed, 0.0, 0.0, 0.7)

    local firstPos = GetOffsetFromEntityInWorldCoords(MyPed, 0.0, 0.0, 0.7)

    cam.setFov("StartScreen", 10.0)
    cam.setPos("StartScreen", vector3(firstPos.x, firstPos.y, firstPos.z))
    cam.lookAtCoords("StartScreen", vector3(lookAt.x, lookAt.y, lookAt.z))
    cam.switchToCam("StartScreen", "StartScreen_2", 350)

    StartScreen.focus = nil
    exports['warv-ui']:SetIntroTag({ visible = false, name = "", key = 0, x = 0.5, y = 0.5, teamColor = "blue" })
    exports['warv-ui']:SetMatchIntro({ visible = false, map = "", gamemode = "", team = "", teamColor = "blue", name = "", nameKey = 0 })
    DoScreenFadeOut(500)
    RealWait(300)


    local pPos = GetEntityCoords(MyPed, true)
    local pHeading = GetEntityHeading(MyPed)
    SetEntityCoords(Player.GetPed(), vector3(pPos.x, pPos.y, pPos.z - 1.0), false, false, false, false)
    SetEntityHeading(Player.GetPed(), pHeading)

    StartScreenActive = false
    for k,v in pairs(tempPeds) do
        SetEntityAsNoLongerNeeded(v)
        DeleteEntity(v)
    end

    for v in EnumeratePeds() do
        ResetEntityAlpha(v)
    end

    cam.delete("StartScreen")
    cam.delete("StartScreen_2")
    StartScreen.InAnimation = false
    DoScreenFadeIn(50)
end
