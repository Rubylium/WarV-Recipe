Utils = {}
Utils.cachedData = {}
Utils.TimeFrame = 0
local possibleNames = {     {"Charlizerex"},
{"IHasFeet"},
{"Charlize Red Feet"},
{"Charlizeasaurus Rex"},
{"Charlize Loving Insides"},
{"Charlize English"},
{"Uber Red Fox"},
{"Disguised Fox"},
{"RedFeetOMG"},
{"LovingFeetLOL"},
{"AdorableFeetOMG"},
{"RedInsidesLOL"},
{"LovingInsidesOMG"},
{"AdorableInsidesLMAO"},
{"Iamred"},
{"Iamloving"},
{"Iamadorable"},
{"IamCharlize"},
{"FoxMilk"},
{"Charlize Adorable Fox"},
{"MindOfCharlize"},
{"Gamerfox"},
{"The Red Gamer"},
{"The Loving Gamer"},
{"The Adorable Gamer"},
{"DrRed"},
{"CharlizeFeetpopper"},
{"BigRedFox"},
{"ItIsYeFox"},
{"Ch4rl1z3"},
{"Fox Boy"},
{"Fox Girl"},
{"Fox Person"},
{"Captain Red"},
{"IHasInsides"},
{"Total Fox"},
{"The Red English Dude"},
{"The Gaming Fox"},
{"Gaming With Charlize"},
{"Marcrex"},
{"IHasArm Pits"},
{"Marc Hungry Arm Pits"},
{"Marcasaurus Rex"},
{"Marc Tall Hands"},
{"Marc Spanish"},
{"Uber Hungry Lizard"},
{"Disguised Lizard"},
{"HungryArm PitsOMG"},
{"TallArm PitsLOL"},
{"GivingArm PitsOMG"},
{"HungryHandsLOL"},
{"TallHandsOMG"},
{"GivingHandsLMAO"},
{"Iamhungry"},
{"Iamtall"},
{"Iamgiving"},
{"IamMarc"},
{"LizardMilk"},
{"Marc Giving Lizard"},
{"MindOfMarc"},
{"Gamerlizard"},
{"The Hungry Gamer"},
{"The Tall Gamer"},
{"The Giving Gamer"},
{"DrHungry"},
{"MarcArm Pitspopper"},
{"BigHungryLizard"},
{"ItIsYeLizard"},
{"M4rc"},
{"Lizard Boy"},
{"Lizard Girl"},
{"Lizard Person"},
{"Captain Hungry"},
{"IHasHands"},
{"Total Lizard"},
{"The Hungry Spanish Dude"},
{"The Gaming Lizard"},
{"Gaming With Marc"},
{"Mikerex"},
{"IHasChins"},
{"Mike Cute Chins"},
{"Mikeasaurus Rex"},
{"Mike Sympathetic Teeth"},
{"Mike English"},
{"Uber Cute Cat"},
{"Disguised Cat"},
{"CuteChinsOMG"},
{"SympatheticChinsLOL"},
{"OptimisticChinsOMG"},
{"CuteTeethLOL"},
{"SympatheticTeethOMG"},
{"OptimisticTeethLMAO"},
{"Iamcute"},
{"Iamsympathetic"},
{"Iamoptimistic"},
{"IamMike"},
{"CatMilk"},
{"Mike Optimistic Cat"},
{"MindOfMike"},
{"Gamercat"},
{"The Cute Gamer"},
{"The Sympathetic Gamer"},
{"The Optimistic Gamer"},
{"DrCute"},
{"MikeChinspopper"},
{"BigCuteCat"},
{"ItIsYeCat"},
{"M1k3"},
{"Cat Boy"},
{"Cat Girl"},
{"Cat Person"},
{"Captain Cute"},
{"IHasTeeth"},
{"Total Cat"},
{"The Cute English Dude"},
{"The Gaming Cat"},
{"Gaming With Mike"},
{"Juliarex"},
{"IHasNipples"},
{"Julia Curvaceous Nipples"},
{"Juliaasaurus Rex"},
{"Julia Scheming Cheeks"},
{"Julia Chinese"},
{"Uber Curvaceous Snake"},
{"Disguised Snake"},
{"CurvaceousNipplesOMG"},
{"SchemingNipplesLOL"},
{"RuthlessNipplesOMG"},
{"CurvaceousCheeksLOL"},
{"SchemingCheeksOMG"},
{"RuthlessCheeksLMAO"},
{"Iamcurvaceous"},
{"Iamscheming"},
{"Iamruthless"},
{"IamJulia"},
{"SnakeMilk"},
{"Julia Ruthless Snake"},
{"MindOfJulia"},
{"Gamersnake"},
{"The Curvaceous Gamer"},
{"The Scheming Gamer"},
{"The Ruthless Gamer"},
{"DrCurvaceous"},
{"JuliaNipplespopper"},
{"BigCurvaceousSnake"},
{"ItIsYeSnake"},
{"Jul14"},
{"Snake Boy"},
{"Snake Girl"},
{"Snake Person"},
{"Captain Curvaceous"},
{"IHasCheeks"},
{"Total Snake"},
{"The Curvaceous Chinese Dude"},
{"The Gaming Snake"},
{"Gaming With Julia"},

}

function GetRandomNickName()
	return possibleNames[math.random(1, #possibleNames)][1]
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end


function ScreenToWorldOnlyEntity(screenPosition, maxDistance)

    local cam = GetRenderingCam()

    local pos = 0
    local rot = 0
    local fov = 0

    if cam == -1 then
        pos = GetGameplayCamCoord()
        rot = GetGameplayCamRot(0)
        fov = GetGameplayCamFov()
    else
        pos = GetCamCoord(cam)
        rot = GetCamRot(cam, 0)
        fov = GetCamFov(cam)
    end

    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, 0, 2)
    local camRight, camForward, camUp, camPos = GetCamMatrix(cam)
    DestroyCam(cam, true)

    screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0
    
    local fovRadians = DegToRad(fov)
    local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * 0.95) - (camUp * screenPosition.y * fovRadians * 0.53)

    local direction = (to - camPos) * maxDistance
    local endPoint = camPos + direction
    
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, 1, 0, 0)
    local retreval, hit, endCoords, surfaceNormal, entity = GetShapeTestResult(rayHandle)
    
    return retreval, hit, endCoords, surfaceNormal, entity
end

function DegToRad(degrees)
    return (degrees * 3.14) / 180.0
end


function SecToDisplay(time)
    local _ = math.floor(time/86400)
    local remaining = time % 86400
    local hours = math.floor(remaining/3600)
    remaining = remaining % 3600
    local minutes = math.floor(remaining/60)
    remaining = remaining % 60
    local seconds = remaining
    if (hours < 10) then
      hours = "0" .. tostring(hours)
    end
    if (minutes < 10) then
      minutes = "0" .. tostring(minutes)
    end
    if (seconds < 10) then
      seconds = "0" .. tostring(seconds)
    end
    return minutes..':'..seconds
end


function GetCorrectPingImage(ping)
    if ping == nil then
        ping = 0
    end
    if ping >= 200 then
        return "ping_bar_01"
    elseif ping >= 100 then
        return "ping_bar_02"
    elseif ping >= 60 then
        return "ping_bar_03"
    else
        return "ping_bar_04"
    end
end

function GetCorrectRankingImage(rank)
    if rank == nil then
        rank = 0
    end
    local base = "division_"
    if rank <= 800 then
        return base.."0"
    elseif rank <= 1000 then
        return base.."1"
    elseif rank <= 1100 then
        return base.."2"
    elseif rank <= 1200 then
        return base.."3"
    elseif rank <= 1300 then
        return base.."4"
    elseif rank <= 1400 then
        return base.."5"
    elseif rank <= 1500 then
        return base.."6"
    elseif rank <= 1600 then
        return base.."7"
    elseif rank <= 1700 then
        return base.."8"
    elseif rank <= 1800 then
        return base.."9"
    elseif rank <= 1900 then
        return base.."10"
    elseif rank <= 2000 then
        return base.."11"
    elseif rank <= 2100 then
        return base.."12"
    elseif rank <= 2500 then
        return base.."12"
    elseif rank <= 2800 then
        return base.."13"
    elseif rank <= 3100 then
        return base.."14"
    elseif rank <= 3500 then
        return base.."15"
    elseif rank <= 3800 then
        return base.."16"
    elseif rank <= 4100 then
        return base.."17"
    elseif rank <= 4500 then
        return base.."18"
    elseif rank <= 4800 then
        return base.."19"
    elseif rank <= 5000 then
        return base.."20"
    elseif rank <= 5200 then
        return base.."21"
    elseif rank <= 5400 then
        return base.."22"
    elseif rank <= 5600 then
        return base.."23"
    elseif rank <= 5800 then
        return base.."24"
    elseif rank <= 6500 then
        return base.."25"
    elseif rank <= 7000 then
        return base.."26"
    elseif rank <= 8000 then
        return base.."27"
    else
        return base.."28"
    end
end

function GetRankIcon(level, prestige)
    if level == nil then
        level = 0
    end

    if prestige == nil then
        prestige = 0
    end

    if tonumber(level) >= 55 then
        level = 55
    end
        

    if prestige == nil then
        return "rank_"..level, 76
    else

        if tonumber(prestige) > 0 and prestige ~= "0" then
            return "rank_prestige_"..prestige, 128
        else
            return "rank_"..level, 256
        end
    end
end

function GetRankIconSmall(level, prestige)

    if level == nil then
        level = 0
    end

    if prestige == nil then
        prestige = 0
    end

    if tonumber(level) >= 55 then
        level = 55
    end
        

    if prestige == nil then
        return "rank_"..level, 76
    else

        if tonumber(prestige) > 0 and prestige ~= "0" then
            return "rank_prestige_"..prestige, 128
        else
            return "rank_small_"..level, 64
        end
    end
end

function KeyboardInputLobby(text, max)
    local amount = nil
    if max == nil then
        max = 255
    end
    AddTextEntry("CUSTOM_AMOUNT", text)
    DisplayOnscreenKeyboard(1, "CUSTOM_AMOUNT", '', "", '', '', '', max)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)

        if not Matchmaking.ranked then
            DrawSprite("images", "lobby_background_blur", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
        else
            DrawSprite("images", "lobby_ranked_background", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
        end
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        amount = GetOnscreenKeyboardResult()
    end
    return amount
end

function KeyboardInput(text, max)
    local amount = nil
    if max == nil then
        max = 255
    end
    AddTextEntry("CUSTOM_AMOUNT", text)
    DisplayOnscreenKeyboard(1, "CUSTOM_AMOUNT", '', "", '', '', '', max)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        amount = GetOnscreenKeyboardResult()
    end
    return amount
end



function GetGxtForWeapon(weapon)
    local name = ""
    local config = SharedConfig.weaponsSpriteByHash[GetHashKey(weapon)]
    if config ~= nil then
        name = GetLabelText(config.GXT)
        if name == "" or name == "NULL" then
            name = config.sprite
        end
        return name
    end

    WeaponsData.Load()
    local wd = WeaponsData.byName[tostring(weapon):upper()]
    return wd and wd.label or "Unknown"
end

function GetClosestPlayerWithOwnPlayer(coord)
	local pPed = GetPlayerPed(-1)
	local players = GetActivePlayers()
	local coords = GetEntityCoords(pPed)
	if coord ~= nil then
		coords = coord
	end
	local pCloset = nil
	local _ = nil
	local pClosetDst = nil
	for k,v in pairs(players) do
		if GetPlayerPed(v) ~= pPed then
			local oPed = GetPlayerPed(v)
			local oCoords = GetEntityCoords(oPed)
			local dst = GetDistanceBetweenCoords(oCoords, coords, true)
			if pCloset == nil then
				pCloset = v
				_ = oCoords
				pClosetDst = dst
			else
				if dst < pClosetDst then
					pCloset = v
					_ = oCoords
					pClosetDst = dst
				end
			end
		end
	end

	return pCloset, pClosetDst
end

function GetClosestPlayer(coord)
	local pPed = GetPlayerPed(-1)
	local players = GetActivePlayers()
	local coords = GetEntityCoords(pPed)
	if coord ~= nil then
		coords = coord
	end
	local pCloset = nil
	local _ = nil
	local pClosetDst = nil
	for k,v in pairs(players) do
			local oPed = GetPlayerPed(v)
			local oCoords = GetEntityCoords(oPed)
			local dst = GetDistanceBetweenCoords(oCoords, coords, true)
			if pCloset == nil then
				pCloset = v
				_ = oCoords
				pClosetDst = dst
			else
				if dst < pClosetDst then
					pCloset = v
					_ = oCoords
					pClosetDst = dst
				end
			end
	end

	return pCloset, pClosetDst
end


function GetEmblemForId(id)
    local card = SharedConfig.callingCards[id]
    if card == nil then
        print("^1ERROR: ^7Avoided crash, wrong embrem ID ("..tostring(id)..")")
        card = SharedConfig.callingCards[1]
    end
    return card.dict, card.sprite
end


function GetEmbledIdFromServerid(players, id)
    for k,v in pairs(players) do
        if v.id == id then
            return v.emblemsId
        end
    end

    return 1
end

function GetWeaponImageFromHash(hash)
    if SharedConfig.weaponsSpriteByHash[hash] ~= nil then
        return SharedConfig.weaponsSpriteByHash[hash].weapon
    end
    WeaponsData.Load()
    return WeaponsData.byHash[hash] or "suicide"
end


function GetWeaponNameFromName(name)
    local hash = GetHashKey(name)
    if SharedConfig.weaponsSpriteByHash[hash] ~= nil then
        return GetLabelText(SharedConfig.weaponsSpriteByHash[hash].GXT)
    end
    return "Unknow"
end

Citizen.CreateThread(function()
    if SharedConfig.devmod then
        if not Data.FirstLoaded then
            TriggerServerEvent("warv:Init")
        end
    end
end)


RegisterNetEvent("warv:RefreshPlayerData")
AddEventHandler("warv:RefreshPlayerData", function(playerData)
    Lobby.playerData = playerData
    Lobby.playerLevel = playerData.level
    Lobby.playerPrestige = playerData.prestige
    Class.customClass = playerData.class
    ClasseCreation.Rebind()
    RefreshCareerData(playerData)
    PlayersDisplay.SyncMyWeapon()
end)

RegisterNetEvent("warv:RefreshUnlockedContent")
AddEventHandler("warv:RefreshUnlockedContent", function(playerData)
    Lobby.playerData.unlockedContent = playerData
end)

local entityEnumerator = {
    __gc = function(enum)
      if enum.destructor and enum.handle then
        enum.destructor(enum.handle)
      end
      enum.destructor = nil
      enum.handle = nil
    end
  }
  
  local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
      local iter, id = initFunc()
      if not id or id == 0 then
        disposeFunc(iter)
        return
      end
      
      local enum = {handle = iter, destructor = disposeFunc}
      setmetatable(enum, entityEnumerator)
      
      local next = true
      repeat
        coroutine.yield(id)
        next, id = moveFunc(iter)
      until not next
      
      enum.destructor, enum.handle = nil, nil
      disposeFunc(iter)
    end)
  end
  
  function EnumerateObjects()
    return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
  end
  
  function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
  end
  
  function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
  end
  
  function EnumeratePickups()
    return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
  end


function RealWait(ms, cb)
    local timer = GetGameTimer() + ms
    while GetGameTimer() < timer do
        if cb ~= nil then
            cb(function(stop)
                if stop then
                    timer = 0
                    return
                end
            end)
        end
        Wait(0)
    end
end


local permsSprite = {
    [100] = "matchmaking_player_place_holder_dev",
    [5] = "matchmaking_player_place_holder_mod",
}
function GetPlayerPlaceHolderSpriteForPerms(perms)

    if permsSprite[perms] ~= nil then
        return permsSprite[perms]
    else
        return "matchmaking_player_place_holder"
    end

end


function LoadModel(model)
    local hash = GetHashKey(model)
    if IsModelInCdimage(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(1)
        end
    else
        print("Model "..model.." do not exist. Please report this error to a dev.")
    end
    Citizen.CreateThread(function()
        Wait(5000)
        SetModelAsNoLongerNeeded(hash)
    end)
end

function LoadModelbyHash(model)
    local hash = model
    if IsModelInCdimage(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(1)
        end
    else
        print("Model "..model.." do not exist. Please report this error to a dev.")
    end
    SetModelAsNoLongerNeeded(hash)
end

function GetCorrectExpForLevel(level)
    if level < 1 then level = 1 end
	return math.floor(SharedConfig.expForLevel * (level^2) - 1)
end

function GetExpForLevel(xp)
	local xp = xp
	local found = false
	local level = 1
	while not found do
		if xp < GetCorrectExpForLevel(level) then
			break
		else
			level = level + 1
		end
	end
    
	return level
end


function CheckInputRotation(cam)
    local zoomvalue = (1.0/(80.0-10.0))*((80.0+10.0)*0.5-10.0)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		local new_z = rotation.z + rightAxisX*-1.0*(5.0)*(zoomvalue+0.1)
		local new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(5.0)*(zoomvalue+0.1)), -89.5)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function RotAnglesToVec(rot)
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end

Citizen.CreateThread(function()
    while true do
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        Wait(500)
    end
end)


function LoadAnimDict(animDict)
    RequestAnimDict(animDict)
    if DoesAnimDictExist(animDict) then
        while not HasAnimDictLoaded(animDict) do
            Wait(1)
        end
    else
        print("^1Trying to load anim dict that do not exist ", animDict)
    end
end


Citizen.CreateThread(function()
	LoadMpDlcMaps()
	OnEnterMp()
end)

local islandVec = vector3(4840.571, -5174.425, 2.0)
Citizen.CreateThread(function()
    while true do
		local pCoords = GetEntityCoords(GetPlayerPed(-1))		
		local distance1 = #(pCoords - islandVec)
		if distance1 < 1500.0 then
			SetIslandHopperEnabled("HeistIsland", true)
			SetToggleMinimapHeistIsland(true)

			SetAiGlobalPathNodesType(true)
			SetScenarioGroupEnabled('Heist_Island_Peds', true)

			SetAudioFlag('PlayerOnDLCHeist4Island', true)
			SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', true, true)
			SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', false, true)
			SetZoneEnabled(59, false)
			
		else
				SetIslandHopperEnabled("HeistIsland", false)
				SetToggleMinimapHeistIsland(false)
				
				SetAiGlobalPathNodesType(false)
				SetScenarioGroupEnabled('Heist_Island_Peds', false)
				
				SetAudioFlag('PlayerOnDLCHeist4Island', false)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', false, false)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', true, false)
		end
		Citizen.Wait(1000)
    end
end)

local function GetIntFromBlob(b, s, o)
	local r = 0
	for i=1,s,1 do
		r = r | (string.byte(b,o+i)<<(i-1)*8)
	end
	return r
end

local function GetStringFromBlob(b, s, o)
	local r = ''
	for i=1,s,1 do
		if string.byte(b,o+i) ~= 0 then
			r = r .. string.char(string.byte(b,o+i))
		else
			break
		end
	end
	return r
end

function GetDlcVehicleData(dlcVehicleIndex, none)
	local blob = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
	local retval = Citizen.InvokeNative(0x33468EDC08E371F6, dlcVehicleIndex, blob, Citizen.ReturnResultAnyway())
	local val1 = GetIntFromBlob(blob,8,0)
	local hash = GetIntFromBlob(blob,8,8)
	local val3 = GetIntFromBlob(blob,8,16)
	return retval, val1, hash, val3
end

function GetDlcWeaponData(dlcWeaponIndex, none)
	local blob = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
	local retval = Citizen.InvokeNative(0x79923CD21BECE14E, dlcWeaponIndex, blob, Citizen.ReturnResultAnyway())
	local emptyCheck = GetIntFromBlob(blob,8,0)
	local weaponHash = GetIntFromBlob(blob,8,8)
	local val3 = GetIntFromBlob(blob,8,16)
	local weaponCost = GetIntFromBlob(blob,8,24)
	local ammoCost = GetIntFromBlob(blob,8,32)
	local ammoType = GetIntFromBlob(blob,8,40)
	local clipSize = GetIntFromBlob(blob,8,48)
	local nameLabel = GetStringFromBlob(blob,64,56)
	local descLabel = GetStringFromBlob(blob,64,120)
	local desc2Label = GetStringFromBlob(blob,64,184)
	local upperCaseNameLabel = GetStringFromBlob(blob,64,248)
	return retval, emptyCheck, weaponHash, val3, weaponCost, ammoCost, ammoType, clipSize, nameLabel, descLabel, desc2Label, upperCaseNameLabel
end

function GetDlcWeaponComponentData(dlcWeaponIndex, dlcWeapCompIndex, none)
	local blob = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
	local retval = Citizen.InvokeNative(0x6CF598A2957C2BF8, dlcWeaponIndex, dlcWeapCompIndex, blob, Citizen.ReturnResultAnyway())
	local attachBone = GetIntFromBlob(blob,8,0)
	local bActiveByDefault = GetIntFromBlob(blob,8,8)
	local val3 = GetIntFromBlob(blob,8,16)
	local componentHash = GetIntFromBlob(blob,8,24)
	local val5 = GetIntFromBlob(blob,8,32)
	local componentCost = GetIntFromBlob(blob,8,40)
	local nameLabel = GetStringFromBlob(blob,64,48)
	local descLabel = GetStringFromBlob(blob,64,112)
	return retval, attachBone, bActiveByDefault, val3, componentHash, val5, componentCost, nameLabel, descLabel
end

function GetWeaponHudStats(weaponHash, none)
	local blob = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
	local retval = Citizen.InvokeNative(0xD92C739EE34C9EBA, weaponHash, blob, Citizen.ReturnResultAnyway())
	local hudDamage = GetIntFromBlob(blob,8,0)
	local hudSpeed = GetIntFromBlob(blob,8,8)
	local hudCapacity = GetIntFromBlob(blob,8,16)
	local hudAccuracy = GetIntFromBlob(blob,8,24)
	local hudRange = GetIntFromBlob(blob,8,32)
	return retval, hudDamage, hudSpeed, hudCapacity, hudAccuracy, hudRange
end

function GetWeaponComponentHudStats(componentHash, none)
	local blob = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
	local retval = Citizen.InvokeNative(0xB3CAF387AE12E9F8, componentHash, blob, Citizen.ReturnResultAnyway())
	local hudDamage = GetIntFromBlob(blob,8,0)
	local hudSpeed = GetIntFromBlob(blob,8,8)
	local hudCapacity = GetIntFromBlob(blob,8,16)
	local hudAccuracy = GetIntFromBlob(blob,8,24)
	local hudRange = GetIntFromBlob(blob,8,32)
	return retval, hudDamage, hudSpeed, hudCapacity, hudAccuracy, hudRange
end

function Utils.RealWait(ms, cb)
    local timer = GetGameTimer() + ms
    while GetGameTimer() < timer do
        if cb ~= nil then
            cb(function(stop)
                if stop then
                    timer = 0
                    return
                end
            end, timer - GetGameTimer())
        end
        Wait(0)
    end
end

function Utils.GetDistanceBetweenCoords(coords1, coords2)
    return #(coords1 - coords2)
end


Utils.RegisterGamemodeNetEvent = GamemodeRuntime.On
Utils.RegisterEventHandler = GamemodeRuntime.OnLocal
Utils.TriggerGamemodeServerEvent = GamemodeRuntime.EmitServer

function Utils.comma_value(amount)
    local formatted = amount
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

function Utils.Copy(obj, seen)
    if type(obj) ~= 'table' then
        return obj
    end
    if seen and seen[obj] then
        return seen[obj]
    end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
        res[Utils.Copy(k, s)] = Utils.Copy(v, s)
    end
    return res
end

function Utils.KeyboardInput(text, max)
    local amount = nil
    if max == nil then
        max = 255
    end
    AddTextEntry("CUSTOM_AMOUNT", text)
    DisplayOnscreenKeyboard(1, "CUSTOM_AMOUNT", '', "", '', '', '', max)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        amount = GetOnscreenKeyboardResult()
    end
    return amount
end


local timer = GetGameTimer()
Citizen.CreateThread(function()
	while true do
		Utils.TimeFrame = (GetGameTimer() - timer)
		timer = GetGameTimer()
		Wait(0)
	end
end)
