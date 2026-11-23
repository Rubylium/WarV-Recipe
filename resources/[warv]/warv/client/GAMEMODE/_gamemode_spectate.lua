Spectate = {}
Spectate.killcamMs = 3000
Spectate.totalMs = 20000
Spectate.target = ""
Spectate.seq = 0
Spectate.skip = false

local camName = "SPECTATE"
local headBone = 31086
local mounted = false
local index = 1

local function respawnPressed()
    DisableControlAction(0, 22, true)
    return IsDisabledControlJustPressed(0, 22)
end

function Spectate.Begin()
    Spectate.skip = false
    Spectate.target = ""
end

function Spectate.RequestRespawn()
    Spectate.skip = true
end

function Spectate.Hold(ms)
    local deadline = GetGameTimer() + ms
    while GetGameTimer() < deadline and not Spectate.skip and GamemodeRuntime.IsActive() do
        if respawnPressed() then
            Spectate.RequestRespawn()
            break
        end
        Wait(0)
    end
end

function Spectate.DeathMs()
    if Gamemode.NoTeams then return Spectate.killcamMs end
    return Spectate.totalMs
end

local function livePed(ped)
    return ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped)
end

local function allies()
    local pool = {}
    if Gamemode.NoTeams then return pool end

    local myId = Gamemode.utils.GetSID()
    for _, player in pairs(Gamemode.PlayersData) do
        if player.team == Gamemode.Team and tonumber(player.id) ~= tonumber(myId) then
            local ped = GetPlayerPed(GetPlayerFromServerId(player.id))
            if livePed(ped) then
                pool[#pool + 1] = { name = player.name, ped = ped }
            end
        end
    end

    for _, profile in pairs(Bot.list[Gamemode.Team] or {}) do
        local ped = Bot.GetEntityById(profile.id)
        if livePed(ped) then
            pool[#pool + 1] = { name = profile.name, ped = ped }
        end
    end

    return pool
end

local function mount(entry)
    Spectate.target = entry.name
    Spectate.seq = Spectate.seq + 1

    DoScreenFadeOut(0)
    cam.attachToEntityBone(camName, entry.ped, headBone, 0.0, 0.22, 0.04, true)
    cam.setActive(camName, true)
    RenderScriptCams(true, false, 0, 1, 1)
    SetFocusEntity(entry.ped)
    Lobby.PushDeath()
    Utils.RealWait(120)
    DoScreenFadeIn(60)
end

function Spectate.Stop()
    if not mounted then return end
    mounted = false
    Spectate.target = ""
    ClearFocus()
    cam.delete(camName)
end

function Spectate.Run()
    if Spectate.skip or Status.GetIsPlayerInEndScreen() then return end

    local pool = allies()
    if #pool == 0 then return end

    index = 1
    mounted = true
    cam.create(camName)
    cam.setFov(camName, 62.0)
    mount(pool[index])

    local deadline = GetGameTimer() + Spectate.totalMs - Spectate.killcamMs

    while mounted and not Spectate.skip and GamemodeRuntime.IsActive() and GetGameTimer() < deadline do
        if respawnPressed() then
            Spectate.RequestRespawn()
            break
        end

        local watched = pool[index].ped
        if livePed(watched) then
            local aim = GetEntityRotation(watched, 2)
            cam.rotation(camName, aim.x, 0.0, aim.z)
        end

        local step = 0
        if IsControlJustPressed(0, 174) then
            step = -1
        elseif IsControlJustPressed(0, 175) then
            step = 1
        end

        if step ~= 0 or not livePed(watched) then
            pool = allies()
            if #pool == 0 then break end
            index = ((index - 1 + step) % #pool) + 1
            mount(pool[index])
        end

        Wait(0)
    end
end
