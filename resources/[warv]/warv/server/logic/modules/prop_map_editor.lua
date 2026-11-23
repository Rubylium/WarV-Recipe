local function persist()
    SaveResourceFile(GetCurrentResourceName(), PropMapStore.File, json.encode(PropMapStore.Serialize()), -1)
end

RegisterNetEvent("warv:SavePropMap")
AddEventHandler("warv:SavePropMap", function(name, map)
    local src = source
    if not Permissions.Has(src, "Owner") then return end
    if type(name) ~= "string" or name == "" or #name > 48 then return end
    if type(map) ~= "table" then return end

    PropMapStore.Set(name, map)
    persist()
    TriggerClientEvent("warv:PropMapUpdated", -1, PropMapStore.Key(name), PropMapStore.Get(name))
end)

RegisterNetEvent("warv:DeletePropMap")
AddEventHandler("warv:DeletePropMap", function(name)
    local src = source
    if not Permissions.Has(src, "Owner") then return end
    if type(name) ~= "string" or name == "" then return end

    PropMapStore.Set(name, nil)
    persist()
    TriggerClientEvent("warv:PropMapUpdated", -1, PropMapStore.Key(name), nil)
end)
