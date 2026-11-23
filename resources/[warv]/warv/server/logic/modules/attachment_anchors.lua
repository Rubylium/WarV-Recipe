local anchorFile = "data/attachment_anchors.json"

local function clamped(value, limit)
    local number = tonumber(value)
    if not number then return nil end
    return math.max(-limit, math.min(limit, number))
end

local function cleanCoord(value)
    local number = tonumber(value)
    if not number then return nil end
    return math.max(-0.2, math.min(1.2, number))
end

local function sanitize(payload)
    local clean = {}
    for weapon, slots in pairs(type(payload) == "table" and payload or {}) do
        if type(weapon) == "string" and #weapon <= 64 and type(slots) == "table" then
            local weaponSlots = {}
            for slot, anchor in pairs(slots) do
                if type(slot) == "string" and #slot <= 32 and type(anchor) == "table" then
                    if slot == "offset" then
                        local x, y, z = clamped(anchor.x, 0.5), clamped(anchor.y, 0.5), clamped(anchor.z, 0.5)
                        if x and y and z then weaponSlots.offset = { x = x, y = y, z = z } end
                    else
                        local b, h = cleanCoord(anchor.b), cleanCoord(anchor.h)
                        if b and h then weaponSlots[slot] = { b = b, h = h } end
                    end
                end
            end
            if next(weaponSlots) then clean[weapon] = weaponSlots end
        end
    end
    return clean
end

RegisterNetEvent("warv:SaveAttachAnchors")
AddEventHandler("warv:SaveAttachAnchors", function(payload)
    local src = source
    if not Permissions.Has(src, "Owner") then return end

    SaveResourceFile(GetCurrentResourceName(), anchorFile, json.encode(sanitize(payload)), -1)
end)
