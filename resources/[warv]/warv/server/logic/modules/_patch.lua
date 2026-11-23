local current_build = "1.1.7B"
local patchHook = GetConvar("warv_webhook_patch", "")
local pushHook = GetConvar("warv_webhook_push", "")
local patch_note = {
}


Citizen.CreateThread(function()
    Wait(1000)
    local db = rockdb:new()
    local lastCommit = db:GetString("lastCommit")
    if lastCommit == nil or lastCommit ~= current_build then
        if GetConvar("dev_mod", false) ~= nil and GetConvar("dev_mod", false) == "true" then
            WarningPrint("Pushing patch")
            db:SaveString("lastCommit", current_build)

            local connect = {
                {
                    ["author"] = {
                        ["name"] = "Rubylium",
                        ["url"] = "https://twitter.com/Rubylium_",
                        ["icon_url"] = "https://cdn.discordapp.com/attachments/859030675943587840/876039503440117790/1Fnf1P4U_400x400.jpg",
                    },
                    ["thumbnail"] = {
                        ["url"] = "https://media.discordapp.net/attachments/846335607634395146/874243849248210944/ezgif-3-c2708a8e4279.gif",
                    },
                    ["color"] = "4259756",
                    ["title"] = "**WarV Update** ("..current_build..")",
                    ["footer"] = {
                        ["text"] = "Update "..current_build.." pushed by @Rubylium",
                    },
                    ["fields"] = {}
                }
            }

            if #patch_note > 0 then
                for k,v in pairs(patch_note) do
                    connect[1]["fields"][k] = {
                        ["name"] = v[1],
                        ["value"] = v[2],
                        ["inline"] = false
                    }
                end
                
    
                if patchHook ~= "" then PerformHttpRequest(patchHook, function(err, text, headers) end, 'POST', json.encode({username = "WarV - Patch", embeds = connect, avatar_url = "https://cdn.discordapp.com/attachments/867604148623376394/875855333547991100/WarVLogotester2.png"}), {       ['Content-Type'] = 'application/json' }) end
            end

        else
            if lastCommit == nil then
                lastCommit = "0.0.0"
            end
            db:SaveString("lastCommit", current_build)
            local connect = {
                {
                    ["color"] = "4259756",
                    ["title"] = "**WarV production push** ("..current_build..")",
                    ["description"] = "WarV Production server got updated! "..lastCommit.." -> "..current_build.."",
                    ["footer"] = {
                        ["text"] = "Pushed by @Rubylium",
                    },
                }
            }


            if pushHook ~= "" then PerformHttpRequest(pushHook, function(err, text, headers) end, 'POST', json.encode({username = "WarV - Push", embeds = connect, avatar_url = "https://cdn.discordapp.com/attachments/867604148623376394/875855333547991100/WarVLogotester2.png"}), {       ['Content-Type'] = 'application/json' }) end
        end
    else
        WarningPrint("No patch to push")
    end
end)