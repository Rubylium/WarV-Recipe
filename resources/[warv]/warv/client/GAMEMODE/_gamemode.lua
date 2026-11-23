Gamemode = {}
Gm = {}
Gamemode.utils = {}
Gamemode.assist = {}
Gamemode.AlreadyActiveKillstreak = {}
Gamemode.isInKillstreakCam = false
Gamemode.activeKillstreak = {
    {type = "UAV", kills = 3, unlocked = false, used = false},
    {type = "AIRSTRIKE", kills = 8, unlocked = false, used = false},
    {type = "SATELITTE", kills = 6, unlocked = false, used = false},
}
Gamemode.Playing = false
Gamemode.CustomPlayerModel = "none"
Gamemode.haveMapBounds = false
Gamemode.mapBounds = {}
Gamemode.isDead = false
Gamemode.Team = 0
Gamemode.PlayersData = {}
Gamemode.team1score = 0
Gamemode.team2score = 0
Gamemode.SpawnProtection = false
Gamemode.GamemodeWithoutKillstreaks = {
    ["ONE IN THE CHAMBER"] = true,
    ["GUN GAME"] = true,
}
Match = {}
GG = {}
TdmFutur = {}

function Gamemode.utils.InitPlayerKillstreaks()
    local db = rockdb:new()

    local killstreak = db:GetTable("KILLSTREAKS")
    if killstreak == nil then
        killstreak = {
            {type = "UAV", kills = 3, unlocked = false, used = false},
            {type = "AIRSTRIKE", kills = 8, unlocked = false, used = false},
            {type = "SATELITTE", kills = 6, unlocked = false, used = false},
        }
    end

    Gamemode.activeKillstreak = killstreak

    for k,v in pairs(Gamemode.activeKillstreak) do
        if SharedConfig.Killstreaks[v.type] ~= nil then
            v.kills = SharedConfig.Killstreaks[v.type].kill
        else
            v.type = "UAV"
            v.kills = SharedConfig.Killstreaks["UAV"].kill
        end
    end

    table.sort(Gamemode.activeKillstreak, function(a, b)
        if a.kills == b.kills then
            return a.type < b.type
        end
        return a.kills < b.kills
    end)
end


function Gamemode.utils.ResetKillstreak()
    for k,v in pairs(Gamemode.activeKillstreak) do
        v.unlocked = false
        v.used = false
    end
end

local combatControls = {
    24, 25, 45, 47, 68, 69, 70, 91, 92, 114, 121, 140, 141, 142, 257, 263, 264, 331,
}

function Gamemode.LockCombat()
    for _, control in ipairs(combatControls) do
        DisableControlAction(0, control, true)
    end
end

function Gamemode.utils.GetPed()
    return PlayerPedId()
end

function Gamemode.utils.GetSID()
    return GetPlayerServerId(GetPlayerIndex())
end

local _, cdc = AddRelationshipGroup("CDC")
local _, cia = AddRelationshipGroup("CIA")
local _, neutral = AddRelationshipGroup("NEUTRAL")
local _, ffaPlayer = AddRelationshipGroup("FFA_PLAYER")
local _, ffaHostile = AddRelationshipGroup("FFA_HOSTILE")

SetRelationshipBetweenGroups(5, cdc, cia)
SetRelationshipBetweenGroups(5, cia, cdc)

SetRelationshipBetweenGroups(5, neutral, cia)
SetRelationshipBetweenGroups(5, neutral, cdc)
SetRelationshipBetweenGroups(5, neutral, neutral)

Gamemode.NoTeams = false

local function setFfaRelationships()
    local ffa = { ffaPlayer, ffaHostile }
    for _, a in ipairs(ffa) do
        for _, b in ipairs(ffa) do
            SetRelationshipBetweenGroups(5, a, b)
        end
        for _, t in ipairs({ cdc, cia }) do
            SetRelationshipBetweenGroups(5, a, t)
            SetRelationshipBetweenGroups(5, t, a)
        end
    end
end
setFfaRelationships()

local function setPedTeam(ped, team, ffaGroup)
    SetRelationshipBetweenGroups(5, cdc, cia)
    SetRelationshipBetweenGroups(5, cia, cdc)

    SetRelationshipBetweenGroups(5, neutral, cia)
    SetRelationshipBetweenGroups(5, neutral, cdc)
    SetRelationshipBetweenGroups(5, neutral, neutral)

    if Gamemode.NoTeams then
        setFfaRelationships()
        SetPedRelationshipGroupHash(ped, ffaGroup)
        SetCanAttackFriendly(ped, true, true)
        return
    end

    if team == 1 then
        SetPedRelationshipGroupHash(ped, cdc)
    elseif team == 2 then
        SetPedRelationshipGroupHash(ped, cia)
    elseif team == 0 then
        SetPedRelationshipGroupHash(ped, neutral)

        ClearRelationshipBetweenGroups(5, cdc, cia)
        ClearRelationshipBetweenGroups(5, cia, cdc)
    end
end

function Gamemode.SetTeam(team)
    setPedTeam(Gamemode.utils.GetPed(), team, ffaPlayer)
end

function Gamemode.SetTeamForPed(team, ped)
    setPedTeam(ped, team, ffaHostile)
end

function Gamemode.LoadPlayerSkinAndChoosenClass()
    Citizen.CreateThread(function()
        Appearance.LoadPlayer(Gamemode.Team)
    end)

    Gamemode.SetTeam(Gamemode.Team)
    ClassWeapons.GiveWeaponFromSelectedClass()
end


Gamemode.IsPlayerBeingSyncChecked = false
function Gamemode.IsPlayerSyncedWithTeam()
    if Gamemode.IsPlayerBeingSyncChecked then
        return Gamemode.Team ~= 0
    else
        Gamemode.IsPlayerBeingSyncChecked = true
        GamemodeRuntime.CreateThread("teamSync", function()
            if Gamemode.Team == 0 then
                Utils.TriggerGamemodeServerEvent("GetTeam")
                local count = 0
                local try = 0
                while Gamemode.IsPlayerBeingSyncChecked do
                    SetEntityVisible(Gamemode.utils.GetPed(), false, 1)
                    count = count + 1
                    if count >= 10 then
                        Utils.TriggerGamemodeServerEvent("GetTeam")
                        count = 0
                        try = try + 1
                        if try == 5 then
                            Gamemode.RemoveMapBounds()
                            Utils.TriggerGamemodeServerEvent("PlayerLeave")
                            GamemodeRuntime.Stop("team_load_timeout")
                            Lobby.ShowPopupMessage("Error", "Sorry, an error occurred while synchronizing your client with the game server. \nFor security reasons, you have been excluded from the game. \nPlease try again. If the problem persists, \nplease disconnect, and reconnect to the WarV server.")
                            return
                        end
                    end
                    if Gamemode.Team ~= 0 then
                        Gamemode.IsPlayerBeingSyncChecked = false
                        return
                    end
                    RealWait(100)
                end
                SetEntityVisible(Gamemode.utils.GetPed(), true, 1)
            end
        end)
    end
end

local minimapScaleform
function Gamemode.StartMinimap()
    GamemodeRuntime.CreateThread("minimap", function()
        minimapScaleform = RequestScaleformMovie("minimap")
        while not HasScaleformMovieLoaded(minimapScaleform) do
            Wait(0)
        end

        SetMinimapComponentPosition('minimap', 'L', 'B', 0.020, -0.725, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', -0.0045, -0.702, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.0045, -0.702, 0.266, 0.237)
        SetMinimapClipType(0)

        SetRadarBigmapEnabled(true, false)
        Wait(0)
        SetRadarBigmapEnabled(false, false)
        SetMinimapComponentPosition('minimap', 'L', 'B', 0.020, -0.725, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', -0.0045, -0.702, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.0045, -0.702, 0.266, 0.237)
    end)
end

function Gamemode.DrawMiniMap()
    BeginScaleformMovieMethod(minimapScaleform, "SETUP_HEALTH_ARMOUR")
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

local blips = {}
function Gamemode.HandleMinimap(players, myTeam, displayAll)
    for k,v in pairs(blips) do
        RemoveBlip(v)
    end

    blips = {}

    if Gamemode.NoTeams then
        return
    end

    for k,v in pairs(players) do
        if displayAll == nil or not displayAll then
            if myTeam ~= 0 and v.team == myTeam then
                local blip = AddBlipForEntity(GetPlayerPed((GetPlayerFromServerId(v.id))))
                SetBlipSprite(blip, 1)
                SetBlipColour(blip, 3)
                SetBlipScale(blip, 0.40)
                table.insert(blips, blip)
            end
        else
            if v.team == myTeam then
                local blip = AddBlipForEntity(GetPlayerPed((GetPlayerFromServerId(v.id))))
                SetBlipSprite(blip, 6)
                SetBlipColour(blip, 3)
                SetBlipScale(blip, 1.00)
                SetBlipRotation(blip, math.ceil(GetEntityHeading(GetPlayerPed((GetPlayerFromServerId(v.id))))))
                table.insert(blips, blip)
            else
                local blip = AddBlipForEntity(GetPlayerPed((GetPlayerFromServerId(v.id))))
                SetBlipSprite(blip, 6)
                SetBlipColour(blip, 47)
                SetBlipScale(blip, 1.00)
                SetBlipRotation(blip, math.ceil(GetEntityHeading(GetPlayerPed((GetPlayerFromServerId(v.id))))))
                table.insert(blips, blip)
            end
        end
    end

end

function Gamemode.SetupMapBounds(bounds, zBounds)
    if zBounds == nil then
        Gamemode.mapBounds = PolyZone:Create(bounds, {
            name="bounds",
        })
    else
        Gamemode.mapBounds = PolyZone:Create(bounds, {
            name="bounds",
            maxZ = zBounds
        })
    end

    Gamemode.haveMapBounds = true
end

function Gamemode.RemoveMapBounds()
    Gamemode.haveMapBounds = false

    Gamemode.mapBounds = {}
end

local oobPopup = "ui/warning/out_of_bounds_warning.wav"
local oobTick = "ui/warning/out_of_bounds_tick.wav"

local function CheckMapBounds(waiting)
    if Gamemode.mapBounds == nil then return end

    local function outside()
        return Gamemode.mapBounds ~= nil and not Status.GetIsPlayerInEndScreen()
            and Gamemode.Playing and Gamemode.haveMapBounds
            and not Gamemode.mapBounds:isPointInside(GetEntityCoords(Gamemode.utils.GetPed()))
            and not IsEntityDead(Gamemode.utils.GetPed())
    end
    if not outside() then return end

    local total = math.ceil(waiting / 1000)
    local remaining = total
    exports['warv-ui']:SetOob({ visible = true, seconds = remaining, total = total })
    PlayCustomSound(oobPopup,
        Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.03, 0.05))

    local acc = 0
    local last = GetGameTimer()
    while outside() do
        local now = GetGameTimer()
        acc = acc + (now - last)
        last = now
        if acc >= 1000 then
            acc = acc - 1000
            remaining = remaining - 1
            if remaining <= 0 then
                exports['warv-ui']:SetOob({ visible = false, seconds = 0, total = total })
                SetEntityHealth(Gamemode.utils.GetPed(), 0)
                Utils.TriggerGamemodeServerEvent("AddPlayerDeath")
                return
            end
            exports['warv-ui']:SetOob({ visible = true, seconds = remaining, total = total })
            PlayCustomSound(oobTick,
                Settings.GetScaledVolume(Settings.effectsSoundVolume, 0.03, 0.05))
        end
        Wait(0)
    end

    exports['warv-ui']:SetOob({ visible = false, seconds = 0, total = total })

end

Citizen.CreateThread(function()
    while true do

        if Matchmaking.selectedMap.minZ ~= nil and not Status.GetIsPlayerInEndScreen() and Gamemode.Playing and not Lobby.displayMapLoadingScreen and not Gamemode.isDead then
            local pPos = Player.GetPos()
            if pPos.z < Matchmaking.selectedMap.minZ then
                SetEntityHealth(Gamemode.utils.GetPed(), 0)
                Utils.TriggerGamemodeServerEvent("AddPlayerDeath")
            end
        end

        if Gamemode.mapBounds ~= nil and not Status.GetIsPlayerInEndScreen() and Gamemode.Playing and Gamemode.haveMapBounds and not Lobby.displayMapLoadingScreen then
            local waiting = 5000
            if Gamemode.mapBounds ~= {} then
                if not SafeExecuteFunction(CheckMapBounds, waiting) then
                    Gamemode.mapBounds = {}
                    Gamemode.haveMapBounds = false
                end
            end

            Wait(500)
        else
            Wait(1000)
        end
    end
end)
