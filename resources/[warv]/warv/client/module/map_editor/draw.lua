MapEditorDraw = {}

local boundsLift = 1.0
local groundCache = {}
local cacheSize = 0

function MapEditorDraw.ClearCache()
    groundCache = {}
    cacheSize = 0
end

local function cachedGround(x, y, fallback)
    local key = math.floor(x * 10) .. ":" .. math.floor(y * 10)
    local cached = groundCache[key]
    if cached ~= nil then return cached end

    if cacheSize > 4000 then MapEditorDraw.ClearCache() end
    local ground = MapEditor.GroundZ(x, y) or fallback
    groundCache[key] = ground
    cacheSize = cacheSize + 1
    return ground
end

local function pointZ(layer, point)
    if layer.vec ~= 2 then return point.z end

    local data = MapEditor.data
    local middle = data and data.middleMapPos
    local fallback = (middle and middle.z) or MapEditorCam.focus.z
    return cachedGround(point.x, point.y, fallback) + boundsLift
end

local function markerScale()
    return math.max(1.0, MapEditorCam.height / 35.0)
end

local function drawHeading(point, scale, r, g, b)
    local rad = math.rad(point.w)
    local reach = 1.8 * scale
    local tipX = point.x - math.sin(rad) * reach
    local tipY = point.y + math.cos(rad) * reach
    DrawLine(point.x, point.y, point.z + 0.15, tipX, tipY, point.z + 0.15, r, g, b, 255)
    DrawMarker(0, tipX, tipY, point.z + 1.0 * scale, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.3 * scale, 0.3 * scale, 0.4 * scale, r, g, b, 220, 0, 0, 2, 0, nil, nil, 0)
end

local function slotsFor(layer)
    if layer.key == "startFirstPos1" or layer.key == "startFirstPos2" then
        return StartScreen.ShowcaseOffsets, StartScreen.ShowcaseShown
    end
    if layer.key == "endScreenPos" then
        return EndScreen.PodiumOffsets, EndScreen.PodiumShown
    end
    return nil
end

local function drawShowcase(anchor, scale, r, g, b, offsets, shown)
    local rad = math.rad(anchor.w)
    local forwardX, forwardY = -math.sin(rad), math.cos(rad)
    local rightX, rightY = math.cos(rad), math.sin(rad)

    for index, offset in ipairs(offsets) do
        if index <= (shown or 5) then
            local x = anchor.x + rightX * offset.x + forwardX * offset.y
            local y = anchor.y + rightY * offset.x + forwardY * offset.y
            local z = anchor.z + offset.z
            local ground = cachedGround(x, y, z)
            local sunken = z < ground - 0.35

            local pr, pg, pb = r, g, b
            if sunken then pr, pg, pb = 255, 60, 60 end

            DrawMarker(1, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.5 * scale, 0.5 * scale, 0.15 * scale, pr, pg, pb, 200, 0, 0, 2, 0, nil, nil, 0)
            DrawLine(x, y, z, x, y, z + 1.9 * scale, pr, pg, pb, sunken and 255 or 150)
            DrawLine(anchor.x, anchor.y, anchor.z, x, y, z, pr, pg, pb, 70)
        end
    end
end

local function drawPolygon(layer, points, selectedIndex)
    local r, g, b = layer.color[1], layer.color[2], layer.color[3]
    local scale = markerScale()

    for index, point in ipairs(points) do
        local z = pointZ(layer, point)
        local nextPoint = points[index + 1] or points[1]
        local nextZ = pointZ(layer, nextPoint)

        DrawLine(point.x, point.y, z, nextPoint.x, nextPoint.y, nextZ, r, g, b, 220)
        DrawLine(point.x, point.y, z, point.x, point.y, z + 4.0 * scale, r, g, b, 110)

        local size = (index == selectedIndex and 0.9 or 0.55) * scale
        DrawMarker(28, point.x, point.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            size, size, size, r, g, b, 220, 0, 0, 2, 0, nil, nil, 0)
    end
end

function MapEditorDraw.Frame()
    if not MapEditor.data then return end
    local selection = MapEditor.selection
    local hover = MapEditor.hover
    local scale = markerScale()

    for _, layer in ipairs(MapEditor.Layers()) do
        local id = MapEditor.LayerId(layer)
        local active = id == MapEditor.layer
        local points = MapEditor.Points(layer)
        local r, g, b = layer.color[1], layer.color[2], layer.color[3]
        local alpha = active and 235 or 120

        if layer.kind == "polygon" then
            drawPolygon(layer, points, selection and selection.layer == id and selection.index or nil)
        else
            for index, point in ipairs(points) do
                local z = pointZ(layer, point)
                local isSelected = selection and selection.layer == id and selection.index == index
                local isHover = hover and hover.layer == id and hover.index == index
                local emphasis = isSelected and 1.5 or (isHover and 1.25 or 1.0)
                local size = 0.8 * scale * emphasis

                DrawMarker(1, point.x, point.y, z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    size, size, 0.3 * scale, r, g, b, alpha, 0, 0, 2, 0, nil, nil, 0)
                DrawLine(point.x, point.y, z, point.x, point.y, z + 3.2 * scale, r, g, b, active and 200 or 90)
                DrawMarker(0, point.x, point.y, z + 4.6 * scale, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.7 * scale * emphasis, 0.7 * scale * emphasis, 0.9 * scale * emphasis,
                    r, g, b, alpha, 0, 1, 2, 0, nil, nil, 0)

                if layer.vec == 4 then drawHeading(point, scale, r, g, b) end
                local offsets, shown = slotsFor(layer)
                if offsets then drawShowcase(point, scale, r, g, b, offsets, shown) end
            end
        end
    end
end

function MapEditorDraw.Pick()
    local cursorX, cursorY = MapEditorCam.cursor.x, MapEditorCam.cursor.y
    local aspect = GetAspectRatio(false)
    local best, bestDistance = nil, 0.035

    for _, layer in ipairs(MapEditor.Layers()) do
        local id = MapEditor.LayerId(layer)
        for index, point in ipairs(MapEditor.Points(layer)) do
            local onScreen, sx, sy = World3dToScreen2d(point.x, point.y, pointZ(layer, point))
            if onScreen then
                local dx = (sx - cursorX) * aspect
                local dy = sy - cursorY
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < bestDistance then
                    bestDistance = distance
                    best = { layer = id, index = index }
                end
            end
        end
    end
    return best
end
