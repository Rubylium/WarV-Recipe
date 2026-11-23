ClasseCreation = {}
ClasseCreation.ClassSelected = 0
local fromMenu = "matchmaking"

function ClasseCreation.Rebind()
    if ClasseCreation.ClassSelected == 0 then return end
    local cls = Class.customClass[Class.editingIndex or 1]
    if cls then ClasseCreation.ClassSelected = cls end
end

function Lobby.SetClassCreationFromMenu(menu)
    fromMenu = menu
    MenuUI.SetLoadoutTab("CHANGE CLASS")
end

function Lobby.GetClassCreationFromMenu()
    return fromMenu
end

