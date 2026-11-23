GG.tier = 1

local equipSeq = 0

local function ladderClass(weapon)
    return {
        name = "GUN GAME",
        weapons = {
            primary = { weapon = weapon, comps = {} },
            secondary = { weapon = weapon, comps = {} },
            extra = { weapon = "", ammo = 0 },
        },
    }
end

local function armPed(ped, hash)
    GiveWeaponToPed(ped, hash, 255, false, true)
    SetPedAmmo(ped, hash, 255)
    SetCurrentPedWeapon(ped, hash, true)
end

function GG.Reset()
    GG.tier = 1
    Class.selected = ladderClass(GunGame.ladder[1])
end

function GG.Equip()
    equipSeq = equipSeq + 1
    local seq = equipSeq
    local hash = GetHashKey(GunGame.ladder[GG.tier])

    GamemodeRuntime.CreateThread("gunGameEquip", function()
        RemoveAllPedWeapons(Player.GetPed(), 1)
        RequestWeaponAsset(hash, 31, 0)
        WeaponBack.RemoveWeaponFromBack()
        Class.ResetIndex()

        local deadline = GetGameTimer() + 5000
        while seq == equipSeq and GamemodeRuntime.IsActive() and GetGameTimer() < deadline do
            local ped = Player.GetPed()
            armPed(ped, hash)
            if IsPedArmed(ped, 7) then return end
            Wait(100)
        end
    end)
end

function GG.Promote(tier)
    local climbed = tier > GG.tier
    GG.tier = tier
    Class.selected = ladderClass(GunGame.ladder[tier])

    if climbed and not Gamemode.isDead then
        GG.Equip()
    end
end

function GG.Sync()
    local selfId = Gamemode.utils.GetSID()
    for _, player in pairs(Gamemode.PlayersData) do
        if tonumber(player.id) == tonumber(selfId) then
            GG.Promote(GunGame.TierFromKills(player.kill))
            return
        end
    end
end

function GG.BotWeapon(profile)
    return GetHashKey(GunGame.WeaponForKills(profile.kill))
end

function GG.SyncBotWeapon(profile, state)
    local tier = GunGame.TierFromKills(profile.kill)
    if state.tier == tier or not Bot.RequestControl(state.entity, 100) then return end

    state.tier = tier
    RemoveAllPedWeapons(state.entity, 1)
    local hash = GetHashKey(GunGame.ladder[tier])
    RequestWeaponAsset(hash, 31, 0)
    armPed(state.entity, hash)
end

GamemodeClientRegistry.Register("gungame", {
    start = function(context)
        Match.OnStart = GG.Reset
        Match.GiveWeapons = GG.Equip
        Match.OnPlayersData = GG.Sync
        Bot.WeaponFor = GG.BotWeapon
        Bot.SyncWeapon = GG.SyncBotWeapon
        Match.Start(context)
    end,
    stop = function()
        Bot.WeaponFor = nil
        Bot.SyncWeapon = nil
        Match.Stop()
    end,
})
