local function persist()
    SaveResourceFile(GetCurrentResourceName(), MapStore.File, json.encode(MapStore.Serialize()), -1)
end

RegisterNetEvent("warv:SaveMap")
AddEventHandler("warv:SaveMap", function(name, data)
    local src = source
    if not Permissions.Has(src, "Owner") then return end
    if type(name) ~= "string" or name == "" or #name > 48 then return end
    if type(data) ~= "table" then return end

    MapStore.ApplyOne(name, data)
    persist()
    TriggerClientEvent("warv:MapUpdated", -1, name, data)
end)

RegisterNetEvent("warv:DeleteMap")
AddEventHandler("warv:DeleteMap", function(name)
    local src = source
    if not Permissions.Has(src, "Owner") then return end
    if type(name) ~= "string" or name == "" then return end

    MapStore.ApplyOne(name, nil)
    persist()
    TriggerClientEvent("warv:MapUpdated", -1, name, nil)
end)
