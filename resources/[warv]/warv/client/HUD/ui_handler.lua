UiHandler = {}
UiHandler.pages = {}

local lockedControls = {
    1, 2, 4, 5, 14, 15, 16, 17, 24, 30, 31, 32, 33, 34, 35, 69, 70, 92,
    114, 121, 140, 141, 142, 257, 263, 264, 331,
}

function UiHandler.Register(page)
    if UiHandler.pages[page] == nil then
        UiHandler.pages[page] = false
    end
end

function UiHandler.IsPageActive(page)
    return UiHandler.pages[page] == true
end

function UiHandler.IsAnySubMenuActive()
    for _, active in pairs(UiHandler.pages) do
        if active then return true end
    end
    return false
end

function UiHandler.SetPageActive(page)
    if UiHandler.pages[page] ~= nil then
        UiHandler.pages[page] = true
    end
end

function UiHandler.SetPageInactive(page)
    if UiHandler.pages[page] ~= nil then
        UiHandler.pages[page] = false
    end
end

function UiHandler.CloseAllPages()
    for page in pairs(UiHandler.pages) do
        UiHandler.pages[page] = false
    end
end

Citizen.CreateThread(function()
    while true do
        if UiHandler.IsAnySubMenuActive() then
            for _, control in ipairs(lockedControls) do
                DisableControlAction(0, control, true)
            end
        end
        Wait(1)
    end
end)
