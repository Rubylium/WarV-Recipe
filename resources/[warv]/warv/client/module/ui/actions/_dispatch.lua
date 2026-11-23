AddEventHandler("warv-ui:menuAction", function(payload)
    local action = payload and payload.action
    local handler = action and MenuUI.actions[action]
    if handler then handler(payload) end
end)
