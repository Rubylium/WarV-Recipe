Sheets = {}
Sheets.RunningAnimation = false
Sheets.list = {}


function Sheets.AddNew(dict, name, min, max, addZeroUnderTen)
    if addZeroUnderTen == nil then
        addZeroUnderTen = false
    end
    table.insert(Sheets.list, {
        name = name,
        min = min,
        max = max,
        dict = dict,
        addZeroUnderTen = addZeroUnderTen,
        actualLong = min,
    })
end

function Sheets.LoadSpriteSheets()
    for k,v in pairs(SharedConfig.Animated) do
        Sheets.AddNew(v.dict, v.sprite, v.min, v.max, v.addZeroUnderTen)
    end
    Sheets.InitLoop()
end

function Sheets.IsSpriteAnimated(dict, name)
    for i, sheet in pairs(Sheets.list) do
        if sheet.dict == dict and sheet.name == name then
            Sheets.RunningAnimation = true
            return true
        end
    end
    return false
end

function Sheets.GetActualFrame(dict, name)
    for i, v in pairs(Sheets.list) do
        if v.dict == dict and v.name == name then
            if v.addZeroUnderTen then
                if v.actualLong < 10 then
                    return "0" .. v.actualLong
                else
                    return v.actualLong
                end
            else
                return v.actualLong
            end
        end
    end
    return nil
end


function Sheets.InitLoop()
    Citizen.CreateThread(function()
        while true do
            if Sheets.RunningAnimation then
                for k,v in pairs(Sheets.list) do
                    if v.actualLong < v.max then
                        v.actualLong = v.actualLong + 1
                        if v.actualLong > v.max then
                            v.actualLong = v.max
                        end
                    else
                        v.actualLong = v.min
                    end
                end
            end
            Utils.RealWait(60)
        end
    end)
end
