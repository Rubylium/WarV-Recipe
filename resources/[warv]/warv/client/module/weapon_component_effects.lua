WeaponComponentEffects = {}

local statOrder = {
    { key = "damage", label = "Damage", lowerIsBetter = false },
    { key = "recoil", label = "Recoil", lowerIsBetter = true },
    { key = "spread", label = "Spread", lowerIsBetter = true },
    { key = "range", label = "Range", lowerIsBetter = false },
    { key = "mobility", label = "Mobility", lowerIsBetter = false },
}

local function roundedPercent(value)
    local percent = value * 100
    if percent >= 0 then return math.floor(percent + 0.5) end
    return math.ceil(percent - 0.5)
end

local function signed(value)
    return (value > 0 and "+" or "") .. tostring(value) .. "%"
end

function WeaponComponentEffects.Build(component)
    local model = tostring(component.model or "")
    if model == "" then return { effects = {} } end

    local values = WeaponAttachmentStats.GetComponentDisplayEffects(model)
    local effects = {}
    for _, definition in ipairs(statOrder) do
        local percent = roundedPercent(values[definition.key])
        if percent ~= 0 then
            local improved = definition.lowerIsBetter and percent < 0 or not definition.lowerIsBetter and percent > 0
            effects[#effects + 1] = {
                label = definition.label,
                value = signed(percent),
                tone = improved and "positive" or "negative",
            }
        end
    end

    if values.clip > 0 then
        effects[#effects + 1] = {
            label = "Magazine",
            value = tostring(math.floor(values.clip + 0.5)),
            tone = "utility",
        }
    end
    return { effects = effects }
end
