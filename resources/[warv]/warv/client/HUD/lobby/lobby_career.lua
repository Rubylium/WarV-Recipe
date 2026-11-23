local Career = {}
Career.buttons = {
    {
        label = "CALLING CARDS",
        actions = function()
            UiHandler.SetPageInactive("ui_barracks")
            UiHandler.SetPageActive("ui_emblem_choose")
        end,
    },
    {
        label = "EMBLEMS",
        actions = function()
            UiHandler.SetPageInactive("ui_barracks")
            UiHandler.SetPageActive("ui_logo_choose")
        end,
    },
    {
        label = "PRESTIGE MODE",
        actions = function()
            if tonumber(Career.level) ~= nil and tonumber(Career.level) >= 55 then
                TriggerServerEvent("warv:TriggerPrestige")
            else
                Lobby.ShowPopupMessage("ERROR", "You need to be level 55 or more.")
            end
        end,
    },
}

function RefreshCareerData(data)
    local index = GetPlayerIndex()
    Career.name = GetPlayerName(index)
    Career.level = tostring(data.level)
    Career.prestige = data.prestige
    Career.kills = tostring(data.kill)
    Career.death = tostring(data.death)
    Career.assist = tostring(data.assist)
    Career.kda = round((data.kill/data.death) or 0, 2)
    Career.win = tostring(data.stats.win) or 100
    Career.loss = tostring(data.stats.loose) or 79
    Career.draw = tostring(data.stats.draw) or 56
    if Career.win ~= nil and Career.loss ~= nil then
        Career.winLossRatio = round(tonumber(Career.win)/tonumber(Career.loss), 2)
    else
        Career.winLossRatio = "0.0"
    end

    if data.kill == 0 and data.death == 0 then
        Career.kda = "0.0"
    end

    if data.stats.win == 0 and data.stats.loose == 0 then
        Career.winLossRatio = "0.0"
    end
end

