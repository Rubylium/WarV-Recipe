MapEnv = {}

MapEnv.Weathers = {
    "EXTRASUNNY", "CLEAR", "NEUTRAL", "SMOG", "FOGGY", "OVERCAST", "CLOUDS",
    "CLEARING", "RAIN", "THUNDER", "SNOW", "SNOWLIGHT", "BLIZZARD", "XMAS", "HALLOWEEN",
}

function MapEnv.Get(map)
    local env = type(map) == "table" and map.env or nil
    if type(env) ~= "table" then return nil end

    return math.floor(tonumber(env.hour) or 12) % 24,
        math.floor(tonumber(env.minute) or 0) % 60,
        tostring(env.weather or "EXTRASUNNY")
end

function MapEnv.ApplyClock(map)
    local hour, minute = MapEnv.Get(map)
    if not hour then return false end
    NetworkOverrideClockTime(hour, minute, 0)
    return true
end

function MapEnv.Set(hour, minute, weather)
    NetworkOverrideClockTime(hour, minute, 0)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
end

function MapEnv.Lobby()
    local env = LobbyLayout.Env()
    if env then
        MapEnv.Set(env.hour, env.minute, env.weather)
        return
    end
    MapEnv.Set(12, 0, "EXTRASUNNY")
end

function MapEnv.Apply(map)
    local hour, minute, weather = MapEnv.Get(map)
    if not hour then
        hour, minute, weather = 12, 0, "EXTRASUNNY"
    end

    MapEnv.Set(hour, minute, weather)
end
