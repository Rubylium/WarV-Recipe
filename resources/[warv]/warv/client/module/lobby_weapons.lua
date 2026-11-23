LobbyWeapons = {}
LobbyWeapons.RefreshDone = true
LobbyWeapons.obj = 0
LobbyWeapons.slot = nil
LobbyWeapons.customModelHash = 0
LobbyWeapons.displayPos = vector3(351.40231323242, 4838.2900390625, -58.639203643799)
LobbyWeapons.displayHeading = 180.0
local buildSeq = 0

function LobbyWeapons.Display()
    local weapon = LobbyLayout.Weapon()
    if weapon then return vector3(weapon.x, weapon.y, weapon.z), weapon.h end
    return LobbyWeapons.displayPos, LobbyWeapons.displayHeading
end

local function selData()
    local sel = ClasseCreation.ClassSelected
    if not (type(sel) == "table" and sel.weapons and LobbyWeapons.slot) then return nil end
    return sel.weapons[LobbyWeapons.slot]
end

local function possibleComps(weaponModel)
    local out = {}
    local wd = WeaponsData.byName[tostring(weaponModel):upper()]
    for _, list in pairs((wd and wd.slots) or {}) do
        for _, c in ipairs(list) do
            if type(c.model) == "string" and c.model ~= "" and not WeaponsData.VirtualComponents[c.model] then
                out[#out + 1] = c.model
            end
        end
    end
    return out
end

local syncSeq = 0
local function applyComponentList(obj, components, seq)
    for _, component in ipairs(components) do
        if seq ~= syncSeq or not DoesEntityExist(obj) then return end
        local componentHash = GetHashKey(component.model)
        local modelHash = GetWeaponComponentTypeModel(componentHash)
        if modelHash ~= 0 and not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            local deadline = GetGameTimer() + 3000
            while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(0) end
        end
        GiveWeaponComponentToWeaponObject(obj, componentHash)
        if modelHash ~= 0 then SetModelAsNoLongerNeeded(modelHash) end
    end
end

local function syncNow(seq)
    local w = selData()
    local obj = LobbyWeapons.obj
    if not (w and w.weapon and obj ~= 0 and DoesEntityExist(obj)) then return end
    local comps = type(w.comps) == "table" and w.comps or {}
    for _, model in ipairs(possibleComps(w.weapon)) do
        if seq ~= syncSeq or not DoesEntityExist(obj) then return end
        if not WeaponComponentVisuals.IsFinish(nil, model) then
            RemoveWeaponComponentFromWeaponObject(obj, GetHashKey(model))
        end
    end
    SetWeaponObjectTintIndex(obj, tonumber(comps.tint) or 0)
    applyComponentList(obj, WeaponComponentVisuals.Split(comps), seq)
end

function LobbyWeapons.SyncComps()
    local w = selData()
    local desiredModelHash = WeaponComponentVisuals.GetObjectCustomModelHash(w and w.comps or {})
    if desiredModelHash ~= LobbyWeapons.customModelHash then
        LobbyWeapons.Build(LobbyWeapons.slot)
        return
    end
    syncSeq = syncSeq + 1
    local seq = syncSeq
    Citizen.CreateThread(function()
        syncNow(seq)
    end)
end

local function clearObject()
    LobbyWeapons.slot = nil
    while DoesEntityExist(LobbyWeapons.obj) do
        DeleteObject(LobbyWeapons.obj)
    end
    LobbyWeapons.obj = 0
    LobbyWeapons.customModelHash = 0
end

function LobbyWeapons.Clear()
    buildSeq = buildSeq + 1
    clearObject()
end

function LobbyWeapons.Build(slot)
    buildSeq = buildSeq + 1
    local currentBuildSeq = buildSeq
    LobbyWeapons.RefreshDone = false
    Citizen.CreateThread(function()
        if currentBuildSeq ~= buildSeq then return end
        Gunsmith.CaptureRebuildCenter()
        clearObject()
        LobbyWeapons.slot = slot
        local w = selData()
        if not (w and w.weapon and w.weapon ~= "") then
            clearObject()
            LobbyWeapons.RefreshDone = true
            return
        end
        local hash = GetHashKey(w.weapon)
        RequestWeaponAsset(hash, 31, 0)
        while not HasWeaponAssetLoaded(hash) and currentBuildSeq == buildSeq do Wait(0) end
        if currentBuildSeq ~= buildSeq then return end
        local customModelHash = WeaponComponentVisuals.GetObjectCustomModelHash(w.comps or {})
        if customModelHash ~= 0 then
            RequestModel(customModelHash)
            local deadline = GetGameTimer() + 3000
            while not HasModelLoaded(customModelHash) and GetGameTimer() < deadline and currentBuildSeq == buildSeq do
                Wait(0)
            end
            if not HasModelLoaded(customModelHash) then customModelHash = 0 end
        end
        if currentBuildSeq ~= buildSeq then return end

        local p, heading = LobbyWeapons.Display()
        local obj = CreateWeaponObject(hash, 50, p.x, p.y, p.z, true, 1.0, customModelHash)
        if currentBuildSeq ~= buildSeq then
            if DoesEntityExist(obj) then DeleteObject(obj) end
            return
        end
        SetEntityCollision(obj, false, false)
        FreezeEntityPosition(obj, true)
        SetEntityRotation(obj, 0.0, 0.0, heading, 2, false)
        LobbyWeapons.obj = obj
        LobbyWeapons.customModelHash = customModelHash
        if customModelHash ~= 0 then SetModelAsNoLongerNeeded(customModelHash) end
        syncSeq = syncSeq + 1
        syncNow(syncSeq)
        LobbyWeapons.RefreshDone = true
    end)
end
