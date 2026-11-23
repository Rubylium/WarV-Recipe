Citizen.CreateThread(function()
    if SharedConfig.devmod then
        local positions = {}
        local closest = 0

        RegisterCommand("add", function(source, args, rawCommand)
            local pos = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())
            table.insert(positions, {pos = vector4(pos.x, pos.y, pos.z, heading)})
            print(#positions)
        end, false)

        RegisterCommand("remove", function(source, args, rawCommand)
            table.remove(positions, closest)
            print(#positions)
        end, false)

        RegisterCommand("reset", function(source, args, rawCommand)
            positions = {}
        end, false)

        RegisterCommand("displayPos", function(source, args, rawCommand)
            for k,v in pairs(positions) do
                print("{pos = vector4("..v.pos[1]..", "..v.pos[2]..", "..v.pos[3]..", "..v.pos[4]..")},")
            end
        end, false)

        RegisterCommand("load", function(source, args, rawCommand)
            if SharedConfig.Maps[args[1]] ~= nil then
                for k,v in pairs(SharedConfig.Maps[args[1]].spawns or {}) do
                    print("Adding position "..k)
                    table.insert(positions, {pos = v.pos})
                end
            else
                print("Map not found")
            end
            
        end, false)

        RegisterCommand('tp', function(source, args, rawCommand)
            print(args[1], args[2], args[3])
            local posToGo
            if SharedConfig.Maps[args[1]] ~= nil then
                local pos = SharedConfig.Maps[args[1]].spawns[1].pos
                posToGo = vector4(pos.x, pos.y, pos.z + 1.0, 0)
            else
                posToGo = vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
            end
            SetEntityCoordsNoOffset(PlayerPedId(), posToGo.xyz, false, false, false)
        
            print(GetEntityCoords(PlayerPedId()))
        end)
        

        Citizen.CreateThread(function()
            while true do
                if #positions == 0 then
                    Wait(500)
                else
                    local closestDistance = 5000
                    for k,v in pairs(positions) do
                        DrawMarker(0, v.pos.xyz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 50.0, 0, 255, 0, 150, 0, 1, 2, 0, nil, nil, 0)
                        DrawMarker(23, v.pos.x, v.pos.y, v.pos.z - 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 0, 255, 0, 150, 0, 1, 2, 0, nil, nil, 0)
                        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.pos.xyz, true) < closestDistance then
                            closest = k
                            closestDistance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.pos.xyz, true)
                        end
                    end

                    DrawMarker(42, positions[closest].pos.xyz, 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 252, 186, 3, 200, 0, 1, 2, 0, nil, nil, 0)

                    for k,v in pairs(positions) do
                        for k2,v2 in pairs(positions) do
                            if k ~= k2 then
                                local dist = #(v.pos.xyz - v2.pos.xyz)
                                if dist <= 30.0 then
                                    DrawLine(v.pos.x, v.pos.y, v.pos.z, v2.pos.x, v2.pos.y, v2.pos.z, 0, 255, 0, 255)
                                end
                            end
                        end
                    end
                    Wait(1)
                end
            end
        end)
    end
end)