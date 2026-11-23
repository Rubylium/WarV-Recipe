Outfits = {
    fileName = "data/clothing.json",
    data = {
        version = 3,
        outfits = {},
    },
}

local function migrateTeams(data)
    if (tonumber(data.version) or 0) >= 3 then
        return false
    end

    for _, outfit in ipairs(data.outfits) do
        if type(outfit.teams) ~= "table" then
            local prefix = tostring(outfit.id):sub(1, 7)
            if prefix == "team-1-" then
                outfit.teams = {1}
            elseif prefix == "team-2-" then
                outfit.teams = {2}
            else
                outfit.teams = {}
            end
        end
    end

    data.version = 3
    return true
end

local function decodeData(rawData)
    if rawData == nil or rawData == "" then
        return nil
    end

    local success, decoded = pcall(json.decode, rawData)
    if not success or type(decoded) ~= "table" then
        return nil
    end

    decoded.version = tonumber(decoded.version) or 1
    decoded.outfits = type(decoded.outfits) == "table" and decoded.outfits or {}
    return decoded
end

function Outfits.Load()
    local rawData = LoadResourceFile(GetCurrentResourceName(), Outfits.fileName)
    local decoded = decodeData(rawData)
    if decoded == nil then
        WarningPrint("Clothing data missing, empty catalog")
        decoded = {
            version = 1,
            outfits = {},
        }
    end

    Outfits.data = decoded
    if migrateTeams(decoded) then
        local saved, saveError = Outfits.Save(decoded)
        if not saved then
            WarningPrint("Clothing migration save: " .. tostring(saveError))
        end
    end
    return decoded
end

function Outfits.TeamOutfits(team)
    team = tonumber(team)
    local pool = {}

    for _, outfit in ipairs(Outfits.data.outfits) do
        for _, value in ipairs(type(outfit.teams) == "table" and outfit.teams or {}) do
            if tonumber(value) == team then
                pool[#pool + 1] = outfit
                break
            end
        end
    end

    if #pool == 0 then
        return Outfits.data.outfits
    end
    return pool
end

function Outfits.Save(data)
    local encoded = json.encode(data)
    local saved = SaveResourceFile(
        GetCurrentResourceName(),
        Outfits.fileName,
        encoded,
        -1
    )

    if not saved then
        return false, "Write failed: " .. Outfits.fileName
    end

    Outfits.data = data
    return true
end

Outfits.Load()
