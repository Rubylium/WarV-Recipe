KillstreakHud = {}

local lastKey = ""
local lastVisible = nil
local keys = { "F1", "F2", "F3" }

function KillstreakHud.Update()
    local gm = Matchmaking.data.gamemode
    if gm and Gamemode.GamemodeWithoutKillstreaks[gm] then
        KillstreakHud.Hide()
        return
    end

    local cache = Score.cache
    local streaks = {}
    for i, v in ipairs(Gamemode.activeKillstreak or {}) do
        local cfg = SharedConfig.Killstreaks[v.type]
        if cfg then
            local needed = tonumber(v.kills) or tonumber(cfg.kill) or 0
            local cooldownRemaining = math.max(0, math.ceil(tonumber(Killstreaks.onCooldown[v.type]) or 0))
            local cooldownTotal = math.max(0, math.ceil(tonumber(cfg.cooldown) or 0))
            local state
            if v.unlocked and cooldownRemaining > 0 then
                state = "cooldown"
            elseif v.unlocked then
                state = "ready"
            elseif v.used then
                state = "spent"
            else
                state = "progress"
            end
            local pct = 0
            if needed > 0 then pct = math.floor(math.min(1, cache / needed) * 100) end
            streaks[#streaks + 1] = {
                key = keys[i] or ("F" .. i),
                type = v.type,
                icon = MenuUI.Slug(cfg.sprite or v.type),
                label = tostring(cfg.label or v.type),
                state = state,
                progress = cache,
                needed = needed,
                pct = pct,
                cooldownRemaining = cooldownRemaining,
                cooldownTotal = cooldownTotal,
            }
        end
    end

    local key = ""
    for _, s in ipairs(streaks) do
        key = key .. s.state .. "@" .. s.pct .. "@" .. s.cooldownRemaining .. "|"
    end
    if key == lastKey and lastVisible == true then return end
    lastKey = key
    lastVisible = true

    exports['warv-ui']:SetKillstreaks({ visible = true, streaks = streaks })
end

function KillstreakHud.Hide()
    if lastVisible == false then return end
    lastVisible = false
    lastKey = ""
    exports['warv-ui']:SetKillstreaks({ visible = false, streaks = {} })
end
