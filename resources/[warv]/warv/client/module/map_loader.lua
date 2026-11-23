MapLoader = {}
MapLoader.currentAssetName = ""
MapLoader.maxAsset = 1
MapLoader.currentAsset = 0

function MapLoader.LoadMapModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local loaded = HasModelLoaded(hash)
    print("Checking loaded model ", model, " - Load status: ", loaded)
    return loaded
end

function MapLoader.LoadMapAssets(map)
    print("Loading map assets", map)
    local assets = SharedConfig.Maps[map].modelsToLoad
    local falseLoad = false
    MapLoader.maxAsset = 0
    MapLoader.currentAsset = 0
    for k,v in pairs(assets) do
        MapLoader.maxAsset = MapLoader.maxAsset + 1
    end

    if MapLoader.maxAsset == MapLoader.currentAsset  then
        MapLoader.maxAsset = 100
        MapLoader.currentAsset = 0

        falseLoad = true
    end
    Citizen.CreateThread(function()
        if not falseLoad then
            local allLoaded = false
            while not allLoaded do
                local ready = true
                for k,v in pairs(assets) do
                    MapLoader.currentAssetName = v
                    local isLoaded = MapLoader.LoadMapModel(v)
                    if isLoaded then
                        MapLoader.currentAsset = MapLoader.currentAsset + 1
                    else
                        ready = false
                    end

                    if ready then
                        allLoaded = true
                    end
                    Wait(1)
                end 
            end
        else
            MapLoader.maxAsset = 1000
            for i = 1,1000 do
                MapLoader.currentAsset = MapLoader.currentAsset + 1.5
                Wait(1)
            end
        end

    end)

end

