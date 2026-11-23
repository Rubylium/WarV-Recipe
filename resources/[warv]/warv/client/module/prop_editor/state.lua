PropEditor = {}
PropEditor.active = false
PropEditor.mode = "pick"
PropEditor.mapName = ""
PropEditor.data = nil
PropEditor.selection = nil
PropEditor.placing = nil
PropEditor.hover = nil
PropEditor.dirty = false
PropEditor.typing = false
PropEditor.preview = nil
PropEditor.gizmo = nil
PropEditor.status = ""
PropEditor.history = {}
PropEditor.favorites = {}

PropEditor.ModSlots = {
    { id = 0, label = "Spoiler" },
    { id = 1, label = "Front bumper" },
    { id = 2, label = "Rear bumper" },
    { id = 3, label = "Skirts" },
    { id = 4, label = "Exhaust" },
    { id = 5, label = "Roll cage" },
    { id = 6, label = "Grille" },
    { id = 7, label = "Hood" },
    { id = 8, label = "Fender" },
    { id = 9, label = "Right fender" },
    { id = 10, label = "Roof" },
    { id = 11, label = "Engine" },
    { id = 12, label = "Brakes" },
    { id = 13, label = "Transmission" },
    { id = 14, label = "Horn" },
    { id = 15, label = "Suspension" },
    { id = 16, label = "Armor" },
    { id = 23, label = "Front wheels" },
    { id = 24, label = "Rear wheels" },
    { id = 25, label = "Plate holder" },
    { id = 27, label = "Trim" },
    { id = 28, label = "Ornaments" },
    { id = 29, label = "Dashboard" },
    { id = 30, label = "Dial" },
    { id = 31, label = "Door speaker" },
    { id = 32, label = "Seats" },
    { id = 33, label = "Steering wheel" },
    { id = 34, label = "Shifter" },
    { id = 35, label = "Plaques" },
    { id = 36, label = "Speakers" },
    { id = 37, label = "Trunk" },
    { id = 38, label = "Hydraulics" },
    { id = 39, label = "Engine block" },
    { id = 40, label = "Air filter" },
    { id = 41, label = "Struts" },
    { id = 42, label = "Arch cover" },
    { id = 43, label = "Aerials" },
    { id = 44, label = "Trim 2" },
    { id = 45, label = "Tank" },
    { id = 46, label = "Windows" },
    { id = 48, label = "Livery" },
}

PropEditor.ToggleSlots = {
    { id = 18, label = "Turbo" },
    { id = 22, label = "Xenon" },
    { id = 20, label = "Tyre smoke" },
    { id = 17, label = "Nitrous" },
    { id = 19, label = "Subwoofer" },
    { id = 21, label = "Hydraulics" },
}

PropEditor.Doors = {
    { id = 0, label = "Front left" },
    { id = 1, label = "Front right" },
    { id = 2, label = "Rear left" },
    { id = 3, label = "Rear right" },
    { id = 4, label = "Hood" },
    { id = 5, label = "Trunk" },
}

PropEditor.Windows = {
    { id = 0, label = "Front left" },
    { id = 1, label = "Front right" },
    { id = 2, label = "Rear left" },
    { id = 3, label = "Rear right" },
}

PropEditor.WheelTypes = {
    "Sport", "Muscle", "Lowrider", "SUV", "Offroad", "Tuner", "Bike", "High end", "Benny original", "Benny bespoke",
}

PropEditor.Scenarios = {
    "WORLD_HUMAN_GUARD_STAND",
    "WORLD_HUMAN_GUARD_PATROL",
    "WORLD_HUMAN_SMOKING",
    "WORLD_HUMAN_STAND_MOBILE",
    "WORLD_HUMAN_STAND_IMPATIENT",
    "WORLD_HUMAN_LEANING",
    "WORLD_HUMAN_CLIPBOARD",
    "WORLD_HUMAN_HAMMERING",
    "WORLD_HUMAN_WELDING",
    "WORLD_HUMAN_CONST_DRILL",
    "WORLD_HUMAN_JANITOR",
    "WORLD_HUMAN_BUM_STANDING",
    "WORLD_HUMAN_BINOCULARS",
    "WORLD_HUMAN_COP_IDLES",
    "WORLD_HUMAN_SEAT_LEDGE",
    "WORLD_HUMAN_SEAT_WALL",
    "WORLD_HUMAN_PICNIC",
    "WORLD_HUMAN_DRINKING",
    "WORLD_HUMAN_AA_SMOKE",
    "WORLD_HUMAN_PUSH_UPS",
    "WORLD_HUMAN_SIT_UPS",
    "WORLD_HUMAN_YOGA",
    "WORLD_HUMAN_MUSCLE_FLEX",
    "PROP_HUMAN_SEAT_CHAIR",
}

local historyKey = "warv:propedit:history"
local favoritesKey = "warv:propedit:favorites"
local historyMax = 24

local function readKvp(key)
    local raw = GetResourceKvpString(key)
    if not raw then return {} end
    local ok, value = pcall(json.decode, raw)
    if not ok or type(value) ~= "table" then return {} end
    return value
end

local function writeKvp(key, value)
    SetResourceKvp(key, json.encode(value))
end

function PropEditor.LoadLibrary()
    PropEditor.history = {}
    for _, model in ipairs(readKvp(historyKey)) do
        if type(model) == "string" then PropEditor.history[#PropEditor.history + 1] = model end
    end

    PropEditor.favorites = {}
    for _, entry in ipairs(readKvp(favoritesKey)) do
        if type(entry) == "table" and type(entry.model) == "string" then
            PropEditor.favorites[#PropEditor.favorites + 1] = { model = entry.model, label = tostring(entry.label or entry.model) }
        end
    end
end

function PropEditor.PushHistory(model)
    if type(model) ~= "string" or model == "" then return end
    for index = #PropEditor.history, 1, -1 do
        if PropEditor.history[index] == model then table.remove(PropEditor.history, index) end
    end
    table.insert(PropEditor.history, 1, model)
    while #PropEditor.history > historyMax do table.remove(PropEditor.history) end
    writeKvp(historyKey, PropEditor.history)
end

function PropEditor.ClearHistory()
    PropEditor.history = {}
    writeKvp(historyKey, PropEditor.history)
end

function PropEditor.AddFavorite(model, label)
    if type(model) ~= "string" or model == "" then return end
    for _, entry in ipairs(PropEditor.favorites) do
        if entry.model == model then return end
    end
    PropEditor.favorites[#PropEditor.favorites + 1] = { model = model, label = tostring(label or model) }
    writeKvp(favoritesKey, PropEditor.favorites)
end

function PropEditor.RenameFavorite(index, label)
    local entry = PropEditor.favorites[index]
    if not entry then return end
    entry.label = tostring(label or entry.model)
    writeKvp(favoritesKey, PropEditor.favorites)
end

function PropEditor.RemoveFavorite(index)
    if not PropEditor.favorites[index] then return end
    table.remove(PropEditor.favorites, index)
    writeKvp(favoritesKey, PropEditor.favorites)
end

function PropEditor.FlagList(definitions, stored)
    local out = {}
    for _, definition in ipairs(definitions) do
        local on = false
        for _, slot in ipairs(stored or {}) do
            if slot.id == definition.id then on = slot.on end
        end
        out[#out + 1] = { id = definition.id, label = definition.label, on = on }
    end
    return out
end

function PropEditor.IsFavorite(model)
    for _, entry in ipairs(PropEditor.favorites) do
        if entry.model == model then return true end
    end
    return false
end

function PropEditor.ModelName(model)
    if type(model) == "string" then return model end
    return string.format("0x%X", PropMap.Hash(model) & 0xFFFFFFFF)
end

PropEditor.LoadLibrary()
