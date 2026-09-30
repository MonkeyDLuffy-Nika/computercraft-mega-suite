-- ============================================================================
-- SOLAR SYSTEM ORRERY & ENCYCLOPEDIA 3D - CC: TWEAKED
-- Real-time Orbital Mechanics, Planetary Telemetry & Interactive Zoom
-- ============================================================================

local display = term
local isMonitor = false

-- Auto-detect external monitor
local mon = peripheral.find("monitor")
if mon then
    display = mon
    isMonitor = true
    pcall(function() mon.setTextScale(0.5) end)
end

local speaker = peripheral.find("speaker")

-- ============================================================================
-- VIBRANT SPACE PALETTE
-- ============================================================================
local SPACE_PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF961E,
    [colors.magenta]   = 0xEB4BBE,
    [colors.lightBlue] = 0x64B4FF,
    [colors.yellow]    = 0xFFE628,
    [colors.lime]      = 0x5AEB28,
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x3C3C46,
    [colors.lightGray] = 0xAAAFB9,
    [colors.cyan]      = 0x1ED2DC,
    [colors.purple]    = 0xA03CEB,
    [colors.blue]      = 0x285FEB,
    [colors.brown]     = 0x9B653B,
    [colors.green]     = 0x2DA537,
    [colors.red]       = 0xEB372D,
    [colors.black]     = 0x06060A
}

if display.setPaletteColor then
    for col, hexVal in pairs(SPACE_PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- CELESTIAL BODIES DATA
-- ============================================================================
local BODIES = {
    [1] = {
        name = "The Sun (Sol)", symbol = "☀️", type = "Yellow Dwarf Star (G2V)",
        color = "yellow", bg = "orange", r = 4, orbitR = 0, speed = 0,
        dist = "0 AU (0 km)", diam = "1,392,700 km", mass = "1.989 x 10^30 kg",
        temp = "5,500 C (Core: 15M C)", period = "27 days (rotation)", moons = "8 Planets, 5 Dwarfs",
        desc = "The star at the center of our Solar System. Contains 99.86% of the total system mass."
    },
    [2] = {
        name = "Mercury", symbol = "☿", type = "Terrestrial Planet",
        color = "lightGray", bg = "gray", r = 1, orbitR = 5, speed = 4.15,
        dist = "0.39 AU (57.9M km)", diam = "4,879 km", mass = "3.30 x 10^23 kg",
        temp = "-180 C to 430 C", period = "88 Earth days", moons = "0 moons",
        desc = "The smallest planet and closest to the Sun. Heavily cratered with extreme temperature shifts."
    },
    [3] = {
        name = "Venus", symbol = "♀", type = "Terrestrial Planet",
        color = "yellow", bg = "orange", r = 1, orbitR = 8, speed = 1.62,
        dist = "0.72 AU (108.2M km)", diam = "12,104 km", mass = "4.87 x 10^24 kg",
        temp = "465 C (Hottest Planet)", period = "225 Earth days", moons = "0 moons",
        desc = "Earth's toxic twin. Choked by thick CO2 atmosphere and sulfuric acid clouds causing runaway greenhouse effect."
    },
    [4] = {
        name = "Earth (Terra)", symbol = "🜨", type = "Terrestrial Ocean Planet",
        color = "lightBlue", bg = "blue", r = 2, orbitR = 12, speed = 1.00,
        dist = "1.00 AU (149.6M km)", diam = "12,742 km", mass = "5.97 x 10^24 kg",
        temp = "-88 C to 58 C (Avg 15 C)", period = "365.25 days", moons = "1 Moon (Luna)",
        desc = "The cradle of humanity. The only known world with liquid surface water, active plate tectonics, and thriving life."
    },
    [5] = {
        name = "Mars (Ares)", symbol = "♂", type = "Terrestrial Desert Planet",
        color = "red", bg = "orange", r = 1, orbitR = 16, speed = 0.53,
        dist = "1.52 AU (227.9M km)", diam = "6,779 km", mass = "6.42 x 10^23 kg",
        temp = "-140 C to 20 C", period = "687 Earth days", moons = "2 (Phobos, Deimos)",
        desc = "The Red Planet. Home to Olympus Mons (highest volcano in solar system) and massive Valles Marineris canyon."
    },
    [6] = {
        name = "Jupiter (Jove)", symbol = "♃", type = "Gas Giant",
        color = "orange", bg = "brown", r = 3, orbitR = 22, speed = 0.28,
        dist = "5.20 AU (778.5M km)", diam = "139,820 km", mass = "1.90 x 10^27 kg",
        temp = "-110 C (Cloud top)", period = "11.86 Earth years", moons = "95 (Io, Europa, Ganymede...)",
        desc = "The King of Planets. Massive magnetic field, colorful atmospheric bands, and the ancient Great Red Spot storm."
    },
    [7] = {
        name = "Saturn (Cronus)", symbol = "♄", type = "Gas Giant (Ringed)",
        color = "yellow", bg = "brown", r = 3, orbitR = 28, speed = 0.19,
        dist = "9.58 AU (1.43B km)", diam = "116,460 km", mass = "5.68 x 10^26 kg",
        temp = "-140 C", period = "29.45 Earth years", moons = "146 (Titan, Enceladus...)",
        desc = "The Jewel of the Solar System. Famous for its majestic icy ring system and Titan, a moon with methane lakes."
    },
    [8] = {
        name = "Uranus", symbol = "♅", type = "Ice Giant",
        color = "cyan", bg = "lightBlue", r = 2, orbitR = 34, speed = 0.12,
        dist = "19.2 AU (2.87B km)", diam = "50,724 km", mass = "8.68 x 10^25 kg",
        temp = "-195 C (Coldest Atmosphere)", period = "84.0 Earth years", moons = "28 (Titania, Oberon...)",
        desc = "The tilted ice giant. Rotates on its side (98 deg axial tilt) with faint rings and methane-rich cyan atmosphere."
    },
    [9] = {
        name = "Neptune", symbol = "♆", type = "Ice Giant",
        color = "blue", bg = "cyan", r = 2, orbitR = 40, speed = 0.08,
        dist = "30.1 AU (4.50B km)", diam = "49,244 km", mass = "1.02 x 10^26 kg",
        temp = "-200 C", period = "164.8 Earth years", moons = "16 (Triton, Proteus...)",
        desc = "The windiest world. Supersonic storms reaching 2,100 km/h, deep azure blue atmosphere, and retrograde moon Triton."
    },
    [10] = {
        name = "Pluto (Dwarf)", symbol = "♇", type = "Kuiper Belt Dwarf Planet",
        color = "lightGray", bg = "brown", r = 1, orbitR = 46, speed = 0.05,
        dist = "39.5 AU (5.91B km)", diam = "2,376 km", mass = "1.30 x 10^22 kg",
        temp = "-230 C", period = "248.0 Earth years", moons = "5 (Charon, Styx, Nix...)",
        desc = "Dwarf planet in the Kuiper Belt with a heart-shaped nitrogen glacier (Tombaugh Regio) and binary partner Charon."
    }
}

-- Application State
local currentView = "MAP" -- "MAP", "INSPECT", "SCALE"
local selectedBodyIdx = 1
local zoomLevel = 1.0
local panX = 0
local panY = 0
local simSpeed = 1.0
local isPaused = false
local simTime = 0
local isAudioOn = true

-- Touch Buttons Storage
local TouchButtons = {}
local function clearButtons() TouchButtons = {} end
local function registerButton(id, x, y, w, h, label, fg, bg)
    table.insert(TouchButtons, {
        id = id, x1 = x, y1 = y, x2 = x + w - 1, y2 = y + h - 1,
        w = w, h = h, label = label, fg = fg or "0", bg = bg or "7"
    })
end

local function drawButtons()
    for _, btn in ipairs(TouchButtons) do
        display.setCursorPos(btn.x1, btn.y1)
        display.setBackgroundColor(colors[btn.bg] or colors.gray)
        display.setTextColor(colors[btn.fg] or colors.white)
        display.write(btn.label)
    end
end

local function checkButtonClicked(clickX, clickY)
    for _, btn in ipairs(TouchButtons) do
        if clickX >= btn.x1 and clickX <= btn.x2 and clickY >= btn.y1 and clickY <= btn.y2 then
            return btn.id
        end
    end
    return nil
end

local function playBeep(pitch)
    if not isAudioOn or not speaker then return end
    pcall(function() speaker.playNote("chime", 0.4, pitch or 12) end)
end

-- ============================================================================
-- ORBITAL CALCULATIONS & POSITIONS
-- ============================================================================
local function getBodyPosition(idx, timeVal)
    local body = BODIES[idx]
    if body.orbitR == 0 then
        return 0, 0
    end
    local angle = (timeVal * body.speed * 0.05) % (2 * math.pi)
    local x = math.cos(angle) * (body.orbitR * zoomLevel * 1.8)
    local y = math.sin(angle) * (body.orbitR * zoomLevel * 0.9)
    return x, y
end

-- ============================================================================
-- VIEW 1: 2D/3D ORRERY ORBIT MAP
-- ============================================================================
local function drawOrbitMap(w, h)
    local centerX = math.floor(w / 2) + panX
    local centerY = math.floor(h / 2) + panY
    
    -- Draw Distant Twinkling Stars
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setTextColor(colors.gray)
    for s = 1, 30 do
        local sx = (s * 17) % w + 1
        local sy = (s * 23) % (h - 3) + 2
        if (s + math.floor(simTime)) % 8 == 0 then
            display.setTextColor(colors.white)
            display.setCursorPos(sx, sy)
            display.write("+")
        else
            display.setTextColor(colors.gray)
            display.setCursorPos(sx, sy)
            display.write(".")
        end
    end
    
    -- Draw Orbit Paths (Ellipses)
    for i = 2, #BODIES do
        local b = BODIES[i]
        local rx = b.orbitR * zoomLevel * 1.8
        local ry = b.orbitR * zoomLevel * 0.9
        
        display.setTextColor(colors.gray)
        if rx > 2 and rx < w * 2 then
            for step = 0, 32 do
                local a = step * (math.pi / 16)
                local ox = math.floor(centerX + math.cos(a) * rx)
                local oy = math.floor(centerY + math.sin(a) * ry)
                if ox >= 2 and ox <= w - 1 and oy >= 2 and oy <= h - 2 then
                    display.setCursorPos(ox, oy)
                    display.write(".")
                end
            end
        end
    end
    
    -- Draw Asteroid Belt Particles (between Mars and Jupiter: orbit 18..20)
    display.setTextColor(colors.brown)
    local astR = 19 * zoomLevel * 1.8
    local astRy = 19 * zoomLevel * 0.9
    for ast = 1, 24 do
        local a = (ast * 0.26 + simTime * 0.02) % (2 * math.pi)
        local ax = math.floor(centerX + math.cos(a) * astR)
        local ay = math.floor(centerY + math.sin(a) * astRy)
        if ax >= 2 and ax <= w - 1 and ay >= 2 and ay <= h - 2 then
            display.setCursorPos(ax, ay)
            display.write(",")
        end
    end
    
    -- Draw Sun (Sol) at Center with Pulsing Corona
    if centerX >= 1 and centerX <= w and centerY >= 2 and centerY <= h - 2 then
        local sunCorona = (math.floor(simTime * 2) % 2 == 0)
        display.setCursorPos(math.max(1, centerX - 2), centerY - 1)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.orange)
        display.write(sunCorona and " \\\\|/ " or " -O- ")
        
        display.setCursorPos(math.max(1, centerX - 2), centerY)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.red)
        display.write(" [SUN] ")
        
        display.setCursorPos(math.max(1, centerX - 2), centerY + 1)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.orange)
        display.write(sunCorona and " /|\\\\ " or " -O- ")
    end
    
    -- Draw All Orbiting Planets
    for i = 2, #BODIES do
        local b = BODIES[i]
        local px, py = getBodyPosition(i, simTime)
        local drawX = math.floor(centerX + px)
        local drawY = math.floor(centerY + py)
        
        if drawX >= 2 and drawX <= w - 6 and drawY >= 2 and drawY <= h - 2 then
            local isSel = (i == selectedBodyIdx)
            display.setCursorPos(drawX, drawY)
            display.setBackgroundColor(colors[b.bg] or colors.black)
            display.setTextColor(colors[b.color] or colors.white)
            
            if b.name == "Saturn (Cronus)" then
                display.write("=O=") -- Saturn Rings
            elseif b.r >= 3 then
                display.write("(O)") -- Large gas giant
            elseif b.r == 2 then
                display.write("()")  -- Medium planet
            else
                display.write("o")   -- Small rocky planet
            end
            
            -- Draw Planet Name Tag
            if zoomLevel >= 0.8 or isSel then
                display.setCursorPos(drawX + 1, drawY + 1)
                display.setBackgroundColor(isSel and colors.blue or colors.black)
                display.setTextColor(isSel and colors.yellow or colors.lightGray)
                display.write(string.sub(b.name, 1, 8))
            end
        end
    end
    
    -- Bottom Quick Info Banner for Selected Planet
    local selBody = BODIES[selectedBodyIdx]
    display.setCursorPos(2, h - 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    local infoStr = string.format(" TARGET: %-16s | %-12s | DIST: %-18s | [ENTER] Inspect 3D ", selBody.name, selBody.type, selBody.dist)
    display.write(string.sub(infoStr, 1, w - 4))
end

-- ============================================================================
-- VIEW 2: 3D CLOSE-UP PLANETARY INSPECTOR & ENCYCLOPEDIA
-- ============================================================================
local function drawPlanetInspector(w, h)
    local b = BODIES[selectedBodyIdx]
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local midX = math.floor(w * 0.3)
    local midY = math.floor(h * 0.5)
    
    -- 1. Draw Big Rotating 3D Celestial Body on Left
    local pRadius = math.min(7, math.floor(h * 0.32))
    for py = -pRadius, pRadius do
        local rW = math.floor(math.sqrt(math.max(0, pRadius*pRadius - py*py)) * 2.2)
        local px = midX - math.floor(rW / 2)
        local dy = midY + py
        if dy >= 3 and dy <= h - 2 and rW > 0 then
            display.setCursorPos(px, dy)
            for x = 1, rW do
                local rot = (x + math.floor(simTime * 2)) % 8
                if b.name == "The Sun (Sol)" then
                    -- Sun Corona Fire
                    local sunCol = (rot < 4) and colors.yellow or colors.orange
                    display.setBackgroundColor(sunCol)
                    display.setTextColor(colors.red)
                    display.write((rot % 2 == 0) and "*" or "~")
                elseif b.name == "Earth (Terra)" then
                    -- Ocean & Continents
                    if rot < 3 and py > -pRadius + 1 and py < pRadius - 1 then
                        display.setBackgroundColor(colors.green)
                        display.setTextColor(colors.lime)
                        display.write("~")
                    else
                        display.setBackgroundColor(colors.blue)
                        display.setTextColor(colors.lightBlue)
                        display.write(" ")
                    end
                elseif b.name == "Jupiter (Jove)" then
                    -- Jupiter Atmospheric Bands & Red Spot
                    if py == 0 and rot == 4 then
                        display.setBackgroundColor(colors.red) -- Great Red Spot
                        display.setTextColor(colors.white)
                        display.write("@")
                    elseif py % 2 == 0 then
                        display.setBackgroundColor(colors.orange)
                        display.setTextColor(colors.brown)
                        display.write("=")
                    else
                        display.setBackgroundColor(colors.brown)
                        display.setTextColor(colors.yellow)
                        display.write("~")
                    end
                else
                    display.setBackgroundColor(colors[b.bg] or colors.gray)
                    display.setTextColor(colors[b.color] or colors.white)
                    display.write((rot == 0) and ":" or " ")
                end
            end
        end
    end
    
    -- Saturn / Uranus Rings in 3D
    if b.name == "Saturn (Cronus)" then
        display.setTextColor(colors.yellow)
        display.setBackgroundColor(colors.black)
        local ringY = midY
        local ringLeft = midX - pRadius * 3
        local ringRight = midX + pRadius * 3
        if ringLeft >= 2 then
            display.setCursorPos(ringLeft, ringY)
            display.write("<=========")
        end
        if ringRight <= w - 2 then
            display.setCursorPos(midX + pRadius + 2, ringY)
            display.write("=========>")
        end
    end
    
    -- 2. Planetary Scientific Telemetry Encyclopedia Card on Right
    local cardX = math.floor(w * 0.55)
    local cardW = w - cardX - 2
    
    display.setCursorPos(cardX, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" == " .. string.upper(b.name) .. " == ")
    
    local fields = {
        { label = "CLASS", val = b.type },
        { label = "DISTANCE", val = b.dist },
        { label = "DIAMETER", val = b.diam },
        { label = "MASS", val = b.mass },
        { label = "SURFACE TEMP", val = b.temp },
        { label = "ORBIT PERIOD", val = b.period },
        { label = "MOONS", val = b.moons }
    }
    
    for idx, f in ipairs(fields) do
        local fy = 5 + (idx - 1) * 2
        if fy < h - 4 then
            display.setCursorPos(cardX, fy)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.cyan)
            display.write(string.format("%-13s: ", f.label))
            display.setTextColor(colors.white)
            display.write(f.val)
        end
    end
    
    -- Description text box
    display.setCursorPos(cardX, h - 5)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(" SCIENTIFIC LOG: ")
    
    display.setCursorPos(cardX, h - 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightGray)
    display.write(string.sub(b.desc, 1, cardW))
    if #b.desc > cardW then
        display.setCursorPos(cardX, h - 3)
        display.write(string.sub(b.desc, cardW + 1, cardW * 2))
    end
end

-- ============================================================================
-- VIEW 3: SCALE SIZE COMPARISON VIEW
-- ============================================================================
local function drawScaleView(w, h)
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setCursorPos(2, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" [ PLANETARY RELATIVE SIZE SCALE COMPARISON ] ")
    
    local startX = 3
    local startY = math.floor(h * 0.5)
    
    for i = 1, #BODIES do
        local b = BODIES[i]
        local dSize = math.max(1, b.r)
        
        display.setCursorPos(startX, startY - dSize)
        display.setBackgroundColor(colors[b.bg] or colors.gray)
        display.setTextColor(colors[b.color] or colors.white)
        
        for dy = -dSize, dSize do
            if startY + dy >= 4 and startY + dy <= h - 4 then
                display.setCursorPos(startX, startY + dy)
                display.write(string.rep("#", dSize * 2))
            end
        end
        
        display.setCursorPos(startX, startY + dSize + 2)
        display.setBackgroundColor(colors.black)
        display.setTextColor((i == selectedBodyIdx) and colors.yellow or colors.cyan)
        display.write(string.sub(b.name, 1, 7))
        
        startX = startX + (dSize * 2) + 4
        if startX > w - 8 then break end
    end
end

-- ============================================================================
-- MAIN RENDER PIPELINE
-- ============================================================================
local function render()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    -- 1. Top Header Toolbar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    -- Navigation Buttons
    registerButton("BTN_VIEW_MAP", 2, 1, 9, 1, "[ ORBITS ]", (currentView == "MAP") and "yellow" or "white", (currentView == "MAP") and "blue" or "gray")
    registerButton("BTN_VIEW_INSPECT", 12, 1, 10, 1, "[ 3D VIEW ]", (currentView == "INSPECT") and "yellow" or "white", (currentView == "INSPECT") and "blue" or "gray")
    registerButton("BTN_VIEW_SCALE", 23, 1, 9, 1, "[ SCALE ]", (currentView == "SCALE") and "yellow" or "white", (currentView == "SCALE") and "blue" or "gray")
    
    -- Zoom & Speed Controls
    registerButton("BTN_ZOOM_IN", 33, 1, 4, 1, "[+]", "lime", "gray")
    registerButton("BTN_ZOOM_OUT", 38, 1, 4, 1, "[-]", "red", "gray")
    registerButton("BTN_PAUSE", 43, 1, 5, 1, isPaused and "[ > ]" or "[ || ]", "yellow", "gray")
    registerButton("BTN_SPEED", 49, 1, 6, 1, string.format("[%dx]", simSpeed), "cyan", "gray")
    
    -- Audio & Exit
    registerButton("BTN_AUDIO", screenW - 14, 1, 7, 1, isAudioOn and "[ SFX ]" or "[ MUTE ]", isAudioOn and "lime" or "red", "gray")
    registerButton("BTN_EXIT", screenW - 6, 1, 6, 1, "[ Q ]", "white", "red")
    
    -- 2. Draw Active Viewport
    if currentView == "MAP" then
        drawOrbitMap(screenW, screenH)
    elseif currentView == "INSPECT" then
        drawPlanetInspector(screenW, screenH)
    elseif currentView == "SCALE" then
        drawScaleView(screenW, screenH)
    end
    
    -- 3. Outer Neon Cyber Frame Border
    display.setTextColor(colors.cyan)
    display.setBackgroundColor(colors.gray)
    for y = 2, screenH - 1 do
        display.setCursorPos(1, y)
        display.write("|")
        display.setCursorPos(screenW, y)
        display.write("|")
    end
    display.setCursorPos(1, 2)
    display.write("+" .. string.rep("=", screenW - 2) .. "+")
    display.setCursorPos(1, screenH - 1)
    display.write("+" .. string.rep("=", screenW - 2) .. "+")
    
    -- 4. Bottom Quick Nav Status Bar
    display.setCursorPos(1, screenH)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightBlue)
    display.write(string.rep(" ", screenW))
    
    local bottomHelp = " [ 1-9, 0 ] Select Planet    [ TAB ] Next    [ +/- ] Zoom    [ ARROWS ] Pan    [ SPACE ] Pause "
    display.setCursorPos(math.max(2, math.floor((screenW - #bottomHelp) / 2)), screenH)
    display.write(bottomHelp)
    
    drawButtons()
end

-- ============================================================================
-- MAIN EVENT LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.06)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.06)
            if not isPaused then
                simTime = simTime + (0.1 * simSpeed)
            end
            render()
            
        elseif event == "key" then
            -- View Switching
            if p1 == keys.m then
                currentView = "MAP"
                playBeep(12)
            elseif p1 == keys.i or p1 == keys.enter then
                currentView = "INSPECT"
                playBeep(16)
            elseif p1 == keys.s then
                currentView = "SCALE"
                playBeep(14)
            -- Planet Selection 1..9, 0
            elseif p1 == keys.one then selectedBodyIdx = 1; playBeep(8)
            elseif p1 == keys.two then selectedBodyIdx = 2; playBeep(10)
            elseif p1 == keys.three then selectedBodyIdx = 3; playBeep(12)
            elseif p1 == keys.four then selectedBodyIdx = 4; playBeep(14)
            elseif p1 == keys.five then selectedBodyIdx = 5; playBeep(16)
            elseif p1 == keys.six then selectedBodyIdx = 6; playBeep(18)
            elseif p1 == keys.seven then selectedBodyIdx = 7; playBeep(20)
            elseif p1 == keys.eight then selectedBodyIdx = 8; playBeep(22)
            elseif p1 == keys.nine then selectedBodyIdx = 9; playBeep(24)
            elseif p1 == keys.zero then selectedBodyIdx = 10; playBeep(6)
            -- Cycle Selection
            elseif p1 == keys.tab then
                selectedBodyIdx = (selectedBodyIdx % #BODIES) + 1
                playBeep(15)
            -- Zoom & Pan
            elseif p1 == keys.equals or p1 == keys.plus or p1 == keys.rightBracket then
                zoomLevel = math.min(3.5, zoomLevel + 0.25)
            elseif p1 == keys.minus or p1 == keys.leftBracket then
                zoomLevel = math.max(0.4, zoomLevel - 0.25)
            elseif p1 == keys.left then panX = panX + 3
            elseif p1 == keys.right then panX = panX - 3
            elseif p1 == keys.up then panY = panY + 2
            elseif p1 == keys.down then panY = panY - 2
            -- Pause & Speed
            elseif p1 == keys.space then
                isPaused = not isPaused
                playBeep(isPaused and 8 or 16)
            -- Audio toggle
            elseif p1 == keys.a then
                isAudioOn = not isAudioOn
            -- Quit
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        elseif event == "mouse_scroll" then
            if p1 < 0 then
                zoomLevel = math.min(3.5, zoomLevel + 0.25)
            else
                zoomLevel = math.max(0.4, zoomLevel - 0.25)
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_VIEW_MAP" then
                currentView = "MAP"
                playBeep(12)
            elseif cid == "BTN_VIEW_INSPECT" then
                currentView = "INSPECT"
                playBeep(16)
            elseif cid == "BTN_VIEW_SCALE" then
                currentView = "SCALE"
                playBeep(14)
            elseif cid == "BTN_ZOOM_IN" then
                zoomLevel = math.min(3.5, zoomLevel + 0.25)
            elseif cid == "BTN_ZOOM_OUT" then
                zoomLevel = math.max(0.4, zoomLevel - 0.25)
            elseif cid == "BTN_PAUSE" then
                isPaused = not isPaused
                playBeep(isPaused and 8 or 16)
            elseif cid == "BTN_SPEED" then
                if simSpeed == 1 then simSpeed = 5
                elseif simSpeed == 5 then simSpeed = 25
                elseif simSpeed == 25 then simSpeed = 100
                else simSpeed = 1 end
                playBeep(18)
            elseif cid == "BTN_AUDIO" then
                isAudioOn = not isAudioOn
            elseif cid == "BTN_EXIT" then
                break
            else
                -- Click on screen to select planet in Orbit Map
                if currentView == "MAP" then
                    local screenW, screenH = display.getSize()
                    local centerX = math.floor(screenW / 2) + panX
                    local centerY = math.floor(screenH / 2) + panY
                    
                    for i = 1, #BODIES do
                        local px, py = getBodyPosition(i, simTime)
                        local bx = math.floor(centerX + px)
                        local by = math.floor(centerY + py)
                        if math.abs(mx - bx) <= 3 and math.abs(my - by) <= 2 then
                            selectedBodyIdx = i
                            playBeep(18)
                            break
                        end
                    end
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Solar System Simulation closed.")
    else
        print("Solar System Simulation closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Simulation Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Simulation Error: " .. tostring(err))
end
