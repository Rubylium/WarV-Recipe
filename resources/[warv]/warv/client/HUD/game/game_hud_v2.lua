HudV2 = {}
HudV2.labelCache = {}

function HudV2.Reset()
    ScoreHud.Hide()
    KillstreakHud.Hide()
    WeaponHud.Hide()
    PlayersUI.Clear()
    Voice.ClearInGameVoiceChat()
    Lobby.HideScoreboard()
    exports['warv-ui']:ResetGameHud()
end


function HudV2.Draw(scoreTeam1, scoreTeam2, maxScore, myTeam, playersData)
    local pPed = Gamemode.utils.GetPed()
    local _, weapon = GetCurrentPedWeapon(pPed, 1)
    local _, ammoClip = GetAmmoInClip(pPed, weapon)
    local ammo = GetAmmoInPedWeapon(pPed, weapon) - ammoClip
    local weapName
    local weapSprite

    Gamemode.DrawMiniMap()
    Voice.DisplayInGameVoiceChat(Gamemode.PlayersData, Gamemode.Team)
    if SharedConfig.weaponsSpriteByHash[weapon] ~= nil then
        weapSprite = SharedConfig.weaponsSpriteByHash[weapon]
        if HudV2.labelCache[weapon] == nil then
            weapName = GetLabelText(SharedConfig.weaponsSpriteByHash[weapon].GXT)
            if weapName == "NULL" then
                weapName = "UNKNOW WEAPON"
            end
            HudV2.labelCache[weapon] = weapName
        else
            weapName = HudV2.labelCache[weapon]
        end
    else
        weapName = "UNKNOW WEAPON"
    end

    local clipMax = GetMaxAmmoInClip(pPed, weapon, 1)

    local grenade = -1
    if Class.selected and Class.selected.weapons and Class.selected.weapons.extra then
        local nadeModel = Class.selected.weapons.extra.weapon
        if nadeModel and nadeModel ~= "" then
            grenade = GetAmmoInPedWeapon(pPed, GetHashKey(nadeModel)) or 0
        end
    end

    if Matchmaking.data.gameTimer == nil then
        Matchmaking.data.gameTimer = 300
    end
    ScoreHud.Update(scoreTeam1, scoreTeam2, maxScore, myTeam)

    WeaponHud.Update(weapName, weapSprite, ammoClip, ammo, clipMax, grenade)

    KillstreakHud.Update()
end

