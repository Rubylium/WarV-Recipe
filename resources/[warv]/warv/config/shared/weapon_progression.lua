WeaponProgression = {}

WeaponProgression.MaxLevel = 50
WeaponProgression.XpPerKill = 100
WeaponProgression.XpHeadshotBonus = 50

local baseXp = 110
local curve = 1.75

function WeaponProgression.XpForLevel(level)
    level = math.floor(tonumber(level) or 1)
    if level <= 1 then return 0 end
    if level > WeaponProgression.MaxLevel then level = WeaponProgression.MaxLevel end
    return math.floor(baseXp * ((level - 1) ^ curve) + 0.5)
end

function WeaponProgression.LevelFromXp(xp)
    xp = tonumber(xp) or 0
    local lvl = 1
    for l = 2, WeaponProgression.MaxLevel do
        if xp >= WeaponProgression.XpForLevel(l) then lvl = l else break end
    end
    return lvl
end

function WeaponProgression.Progress(xp)
    xp = tonumber(xp) or 0
    local level = WeaponProgression.LevelFromXp(xp)
    local base = WeaponProgression.XpForLevel(level)
    if level >= WeaponProgression.MaxLevel then
        return level, 0, 0
    end
    local nextXp = WeaponProgression.XpForLevel(level + 1)
    return level, xp - base, nextXp - base
end
