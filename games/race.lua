-- ============================================================================
-- HIGHWAY RACER PRO 2077 - HD SUPERCAR EDITION
-- High-Definition 4-Line Vehicle Models, Steering Tilt, Garage & Synth Audio
-- Clean, Non-Flickering High-Contrast Aesthetic
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
-- REALISTIC & CALM RETRO-MODERN PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xF57C00, -- Amber
    [colors.magenta]   = 0xD81B60, -- Crimson Pink
    [colors.lightBlue] = 0x29B6F6, -- Sky Blue
    [colors.yellow]    = 0xFFD600, -- Racing Yellow
    [colors.lime]      = 0x00E676, -- Nitro Green
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- Deep Asphalt Road
    [colors.lightGray] = 0x5C6479, -- Steel Guardrail
    [colors.cyan]      = 0x00E5FF, -- Cockpit Glass
    [colors.purple]    = 0x4A148C, -- Night Skyline
    [colors.blue]      = 0x0D1B3E, -- Midnight Sky
    [colors.brown]     = 0x4E342E,
    [colors.green]     = 0x1B4332, -- Dark Roadside Grass
    [colors.red]       = 0xD50000, -- Brake Lights
    [colors.black]     = 0x0A0D14  -- Deep Void
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- SOUND FX ENGINE
-- ============================================================================
local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "rev" then
            speaker.playNote("bass", 0.4, 6)
        elseif snd == "nitro" then
            speaker.playNote("snare", 0.7, 20)
            speaker.playNote("chime", 0.7, 24)
        elseif snd == "coin" then
            speaker.playNote("bell", 0.7, 20)
            speaker.playNote("chime", 0.7, 24)
        elseif snd == "close_call" then
            speaker.playNote("chime", 0.8, 22)
        elseif snd == "crash" then
            speaker.playNote("bass", 1.0, 4)
            speaker.playNote("snare", 1.0, 6)
        elseif snd == "win" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.8, p)
                sleep(0.04)
            end
        end
    end)
end

-- ============================================================================
-- SUPERCAR GARAGE & TUNING DATA (4-LINE HIGH-DETAIL MODELS)
-- ============================================================================
local CARS = {
    [1] = {
        name = "NISSAN GT-R NISMO", tag = "SPORT", col = "yellow",
        maxSpd = 260, accel = 3.8, grip = 3.2, nitroCap = 100, price = 0, unlocked = true,
        sprite = {
            "  __//==\\__  ",
            " (o[######]o) ",
            " [== GT-R ==] ",
            " |0========0| "
        }
    },
    [2] = {
        name = "MAZDA RX-7 DRIFT", tag = "DRIFT", col = "magenta",
        maxSpd = 290, accel = 4.4, grip = 4.2, nitroCap = 120, price = 1500, unlocked = false,
        sprite = {
            "  __{====}__  ",
            " <o[######]o> ",
            " <= RX-7 FD=> ",
            " |0========0| "
        }
    },
    [3] = {
        name = "PORSCHE 911 GT3", tag = "SUPER", col = "cyan",
        maxSpd = 330, accel = 5.2, grip = 3.9, nitroCap = 150, price = 3500, unlocked = false,
        sprite = {
            "  __[####]__  ",
            " /o[######]o\ ",
            " [# 911 GT3#] ",
            " |0========0| "
        }
    },
    [4] = {
        name = "BUGATTI CHIRON GT", tag = "HYPER", col = "lime",
        maxSpd = 390, accel = 6.2, grip = 4.8, nitroCap = 200, price = 7500, unlocked = false,
        sprite = {
            "  //======\\  ",
            " <o[######]o> ",
            " <>>CHIRON<<> ",
            " |0========0| "
        }
    }
}

local SPEED_MODES = {
    [1] = { name = "NOVICE (220 KM/H)", spdMul = 0.85, cashMul = 1.0, trafficDense = 4 },
    [2] = { name = "PRO RACER (300 KM/H)", spdMul = 1.15, cashMul = 1.5, trafficDense = 5 },
    [3] = { name = "HYPER TURBO (400 KM/H)", spdMul = 1.50, cashMul = 2.5, trafficDense = 6 }
}
local speedModeIdx = 2
local currentCarIdx = 1
local currentStage = 1
local stageSpeedBonus = 0
local gameState = "TITLE"  -- "TITLE", "RACING", "CRASHED", "GARAGE", "FINISHED"
local totalCash = 500
local raceScore = 0
local highScore = 15000
local distanceMeters = 0
local targetDistance = 5000 -- 5,000 meters race

-- Player Car Physics
local player = {
    laneX = 0,         -- -10.0 (far left) to +10.0 (far right)
    speed = 0,         -- km/h (0 to 390)
    targetSpeed = 0,
    nitro = 100,
    isNitro = false,
    isBraking = false,
    steerDir = 0,      -- -1=Left, 0=Straight, 1=Right
    gear = 1,
    combo = 0,
    hp = 100
}

-- Highway Road & Traffic
local roadScroll = 0
local roadCurve = 0
local targetCurve = 0
local curveTimer = 0

local traffic = {}
local collectibles = {}
local popupAlert = nil

-- Touch Buttons Storage
local TouchButtons = {}
local function clearButtons() TouchButtons = {} end
local function registerButton(id, x, y, w, h, label, fg, bg)
    table.insert(TouchButtons, {
        id = id, x1 = x, y1 = y, x2 = x + w - 1, y2 = y + h - 1,
        w = w, h = h, label = label, fg = fg or "white", bg = bg or "gray"
    })
end

local function drawButtons()
    for _, btn in ipairs(TouchButtons) do
        for dy = 0, btn.h - 1 do
            display.setCursorPos(btn.x1, btn.y1 + dy)
            display.setBackgroundColor(colors[btn.bg] or colors.gray)
            display.setTextColor(colors[btn.fg] or colors.white)
            display.write(btn.label)
        end
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

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local function initRace()
    player.laneX = 0
    player.speed = 50 * SPEED_MODES[speedModeIdx].spdMul
    currentStage = 1
    stageSpeedBonus = 0
    player.nitro = CARS[currentCarIdx].nitroCap
    player.isNitro = false
    player.isBraking = false
    player.steerDir = 0
    player.gear = 1
    player.combo = 0
    player.hp = 100
    
    distanceMeters = 0
    raceScore = 0
    roadScroll = 0
    roadCurve = 0
    targetCurve = 0
    curveTimer = 35
    traffic = {}
    collectibles = {}
    popupAlert = nil
    gameState = "RACING"
    playSound("rev")
end

-- ============================================================================
-- TRAFFIC SPONSOR & CAR TYPES (3-LINE DETAILED MODELS)
-- ============================================================================
local TRAFFIC_TYPES = {
    {
        name = "Sedan", col = "lightGray", speed = 110,
        sprite = {
            "  __[====]__  ",
            " [==SEDAN==]  ",
            " |0======0|   "
        }
    },
    {
        name = "CyberTruck", col = "orange", speed = 85,
        sprite = {
            "  [########]  ",
            "  |#CYBER#|   ",
            " |00====00|   "
        }
    },
    {
        name = "CityTaxi", col = "yellow", speed = 125,
        sprite = {
            "   -[TAXI]-   ",
            "  [==CAB===]  ",
            "  |0======0|  "
        }
    },
    {
        name = "Police", col = "lightBlue", speed = 155,
        sprite = {
            "  [*POLICE*]  ",
            "  [#PATROL#]  ",
            "  |0======0|  "
        },
        isCop = true
    },
    {
        name = "Supercar", col = "red", speed = 185,
        sprite = {
            "   //====\\   ",
            "  <=SF-90=>   ",
            "  |0======0|  "
        }
    }
}

local function spawnTraffic()
    if #traffic >= 5 then return end
    
    local lanePositions = { -10.5, -5.2, 0.0, 5.2, 10.5 }
    local chosenLane = lanePositions[math.random(1, #lanePositions)]
    
    for _, t in ipairs(traffic) do
        if math.abs(t.laneX - chosenLane) < 2 and t.distance > 80 then return end
    end
    
    local tType = TRAFFIC_TYPES[math.random(1, #TRAFFIC_TYPES)]
    table.insert(traffic, {
        type = tType,
        laneX = chosenLane,
        distance = 100,
        speed = tType.speed + math.random(-8, 12),
        col = tType.col,
        siren = 0
    })
end

local function spawnCollectible()
    if #collectibles >= 3 then return end
    local lanePositions = { -10.5, -5.2, 0.0, 5.2, 10.5 }
    local chosenLane = lanePositions[math.random(1, #lanePositions)]
    
    local r = math.random(1, 10)
    local itemType = "COIN"
    if r <= 6 then itemType = "COIN"
    elseif r <= 8 then itemType = "NITRO"
    else itemType = "BOOST" end
    
    table.insert(collectibles, {
        type = itemType,
        laneX = chosenLane,
        distance = 100
    })
end

-- ============================================================================
-- PHYSICS & UPDATE LOOP
-- ============================================================================
local function updateRace()
    local car = CARS[currentCarIdx]
    
    -- 1. Acceleration & Top Speed
    local mode = SPEED_MODES[speedModeIdx]
    local effectiveMaxSpd = (car.maxSpd + stageSpeedBonus) * mode.spdMul
    if player.isNitro and player.nitro > 0 then
        effectiveMaxSpd = effectiveMaxSpd + 80
        player.nitro = math.max(0, player.nitro - 2.2)
        if player.nitro <= 0 then
            player.isNitro = false
        end
    else
        player.nitro = math.min(car.nitroCap, player.nitro + 0.35)
    end
    
    -- Dynamic Stage Progression (Every 1500m speed level increases!)
    local newStage = math.floor(distanceMeters / 1500) + 1
    if newStage > currentStage and newStage <= 3 then
        currentStage = newStage
        stageSpeedBonus = stageSpeedBonus + 30
        popupAlert = { text = string.format("SPEED LEVEL UP! STAGE %d (+30 KM/H)", currentStage), col = "yellow", timer = 20 }
        playSound("nitro")
    end
    
    if player.isBraking then
        player.speed = math.max(25, player.speed - 14.0)
    else
        local accelRate = (player.isNitro and car.accel * 1.8 or car.accel)
        if player.speed < effectiveMaxSpd then
            player.speed = math.min(effectiveMaxSpd, player.speed + accelRate)
        elseif player.speed > effectiveMaxSpd then
            player.speed = math.max(effectiveMaxSpd, player.speed - 3.0)
        end
    end
    
    player.gear = math.min(6, math.floor(player.speed / 55) + 1)
    
    -- Distance & Score
    local distanceDelta = (player.speed / 3.6) * 0.15
    distanceMeters = distanceMeters + distanceDelta
    raceScore = raceScore + math.floor(player.speed * 0.1)
    
    if raceScore > highScore then highScore = raceScore end
    
    if distanceMeters >= targetDistance then
        gameState = "FINISHED"
        local reward = 1200 + math.floor(raceScore / 10)
        totalCash = totalCash + reward
        playSound("win")
        return
    end
    
    -- Road Curve System
    curveTimer = curveTimer - 1
    if curveTimer <= 0 then
        curveTimer = math.random(35, 70)
        targetCurve = math.random(-3, 3)
    end
    roadCurve = roadCurve + (targetCurve - roadCurve) * 0.06
    roadScroll = (roadScroll + player.speed * 0.05) % 1000
    
    -- Curve Pull on Car
    player.laneX = player.laneX - (roadCurve * 0.05 * (player.speed / 200))
    player.laneX = math.max(-14.0, math.min(14.0, player.laneX))
    
    -- Off-Road Penalty (Grass drag)
    if math.abs(player.laneX) > 13.2 then
        player.speed = math.max(40, player.speed - 6.0)
        player.hp = math.max(0, player.hp - 1)
        if player.hp <= 0 then
            gameState = "CRASHED"
            playSound("crash")
            return
        end
    end
    
    -- Spawners
    if math.random(1, 6) == 1 then spawnTraffic() end
    if math.random(1, 9) == 1 then spawnCollectible() end
    
    -- Update Traffic
    for i = #traffic, 1, -1 do
        local t = traffic[i]
        local relSpeed = (player.speed - t.speed) / 3.6
        t.distance = t.distance - relSpeed * 0.15
        
        -- Near Miss / Close Call Check
        if math.abs(t.distance) < 4 and math.abs(t.laneX - player.laneX) < 2.8 and not t.scoredNearMiss then
            t.scoredNearMiss = true
            player.combo = player.combo + 1
            local comboCash = 50 * player.combo
            totalCash = totalCash + comboCash
            raceScore = raceScore + 300 * player.combo
            popupAlert = { text = string.format("CLOSE CALL! x%d +$%d", player.combo, comboCash), col = "yellow", timer = 12 }
            playSound("close_call")
        end
        
        -- Collision with Traffic
        if math.abs(t.distance) < 2.2 and math.abs(t.laneX - player.laneX) < 2.0 then
            player.speed = player.speed * 0.4
            player.hp = player.hp - 35
            player.combo = 0
            table.remove(traffic, i)
            playSound("crash")
            
            if player.hp <= 0 then
                gameState = "CRASHED"
                return
            else
                popupAlert = { text = "COLLISION! -35 HULL", col = "red", timer = 14 }
            end
        elseif t.distance < -15 or t.distance > 120 then
            table.remove(traffic, i)
        end
    end
    
    -- Update Collectibles
    for i = #collectibles, 1, -1 do
        local c = collectibles[i]
        local relSpeed = player.speed / 3.6
        c.distance = c.distance - relSpeed * 0.15
        
        if math.abs(c.distance) < 2.5 and math.abs(c.laneX - player.laneX) < 2.2 then
            if c.type == "COIN" then
                totalCash = totalCash + 100
                raceScore = raceScore + 500
                popupAlert = { text = "+$100 CASH", col = "yellow", timer = 10 }
                playSound("coin")
            elseif c.type == "NITRO" then
                player.nitro = car.nitroCap
                popupAlert = { text = "NITRO RECHARGED!", col = "lime", timer = 10 }
                playSound("nitro")
            elseif c.type == "BOOST" then
                player.speed = math.min(car.maxSpd + 80, player.speed + 60)
                popupAlert = { text = "TURBO SPEED! 300+ KM/H", col = "cyan", timer = 10 }
                playSound("nitro")
            end
            table.remove(collectibles, i)
        elseif c.distance < -10 then
            table.remove(collectibles, i)
        end
    end
    
    if popupAlert then
        popupAlert.timer = popupAlert.timer - 1
        if popupAlert.timer <= 0 then popupAlert = nil end
    end
end

-- ============================================================================
-- HIGH-DEFINITION PSEUDO-3D HIGHWAY RENDERER
-- ============================================================================
local function renderRace()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Starry Sky & Forest / Mountain Horizon (Lines 1 to 6)
    for y = 1, 6 do
        display.setCursorPos(1, y)
        if y <= 3 then
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.lightBlue)
            if y == 2 then
                display.write("   .   *      .        *   [ NEON HORIZON HIGHWAY ]   *      .   *      ")
            else
                display.write(" *        .        *         .          *         .        *         .  ")
            end
        elseif y == 4 then
            -- Distant Alpine Mountain Peaks
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.purple)
            display.write("   /\\_    /\\/\\_     /\\_    /\\/\\_     /\\_    /\\/\\_     /\\_    /\\/\\_   ")
        elseif y == 5 then
            -- Dense Horizon Pine Tree Line
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.lime)
            display.write("  /\\   /\\/\\   /\\  /\\/\\   /\\   /\\/\\   /\\  /\\/\\   /\\   /\\/\\   /\\  /\\/\\  ")
        elseif y == 6 then
            -- Shaded Pine Trunks & Forest Base
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.green)
            display.write(" /||\\ /||||\\ /||\\/||||\\ /||\\ /||||\\ /||\\/||||\\ /||\\ /||||\\ /||\\/||||\\ ")
        end
    end
    
    -- 2. Clean Pseudo-3D Asphalt Road (Lines 7 to screenH - 4)
    local horizonY = 7
    local roadBottomY = screenH - 4
    local roadHeight = roadBottomY - horizonY + 1
    local centerX = math.floor(screenW / 2)
    
    for y = horizonY, roadBottomY do
        local progress = (y - horizonY) / roadHeight -- 0.0 (top) to 1.0 (bottom)
        local curRoadW = math.min(screenW - 2, math.floor(20 + progress * (screenW - 4)))
        local curveOffset = math.floor(roadCurve * (1.0 - progress) * 5)
        local roadLeft = math.floor(centerX - curRoadW / 2 + curveOffset)
        local roadRight = roadLeft + curRoadW - 1
        
        -- Solid Dark Green Grass with Scrolling Roadside Pine Trees
        display.setCursorPos(1, y)
        display.setBackgroundColor(colors.green)
        display.write(string.rep(" ", math.max(1, roadLeft)))
        
        display.setCursorPos(math.min(screenW, roadRight + 1), y)
        display.setBackgroundColor(colors.green)
        display.write(string.rep(" ", math.max(0, screenW - roadRight)))
        
        -- Detailed Multi-Tier Roadside Pine Trees (Left & Right Grass Verges)
        local treeCycle = (math.floor(roadScroll * 0.15 + y * 2)) % 16
        
        if roadLeft >= 7 then
            local treeX = math.max(1, roadLeft - 6)
            display.setCursorPos(treeX, y)
            display.setBackgroundColor(colors.green)
            if treeCycle == 0 then
                display.setTextColor(colors.lime)
                display.write("  /\\  ")
            elseif treeCycle == 1 then
                display.setTextColor(colors.lime)
                display.write(" /##\\ ")
            elseif treeCycle == 2 then
                display.setTextColor(colors.green)
                display.write("/####\\")
            elseif treeCycle == 3 then
                display.setTextColor(colors.brown)
                display.write("  ||  ")
            end
        end
        
        if (screenW - roadRight) >= 7 then
            local treeX = roadRight + 2
            display.setCursorPos(treeX, y)
            display.setBackgroundColor(colors.green)
            if treeCycle == 0 then
                display.setTextColor(colors.lime)
                display.write("  /\\  ")
            elseif treeCycle == 1 then
                display.setTextColor(colors.lime)
                display.write(" /##\\ ")
            elseif treeCycle == 2 then
                display.setTextColor(colors.green)
                display.write("/####\\")
            elseif treeCycle == 3 then
                display.setTextColor(colors.brown)
                display.write("  ||  ")
            end
        end
        
        -- Solid Dark Charcoal Asphalt Road
        display.setCursorPos(math.max(1, roadLeft), y)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", curRoadW))
        
        -- Solid Clean Steel Guardrails
        display.setCursorPos(math.max(1, roadLeft), y)
        display.setBackgroundColor(colors.lightGray)
        display.write(" ")
        
        display.setCursorPos(math.max(1, roadRight), y)
        display.setBackgroundColor(colors.lightGray)
        display.write(" ")
        
        -- Smooth White Dashed Center Lane Dividers
        local isDash = (math.floor(roadScroll * 0.15 + y) % 4 < 2)
        if isDash and curRoadW > 24 then
            local laneStep = curRoadW / 5
            for l = 1, 4 do
                local lx = math.floor(roadLeft + l * laneStep)
                display.setCursorPos(lx, y)
                display.setBackgroundColor(colors.white)
                display.write(" ")
            end
        end
    end
    
    -- 3. Render Detailed Traffic Vehicles
    for _, t in ipairs(traffic) do
        if t.distance > 0 and t.distance < 90 then
            local normDist = 1.0 - (t.distance / 90.0)
            local ty = math.floor(horizonY + normDist * (roadHeight - 4))
            local curRoadW = math.min(screenW - 2, math.floor(20 + normDist * (screenW - 4)))
            local curveOffset = roadCurve * (1.0 - normDist) * 5
            local tx = math.floor(centerX + (t.laneX / 14.0) * (curRoadW * 0.44) + curveOffset)
            
            if ty >= horizonY and ty <= roadBottomY - 2 then
                -- Line 1: Roof / Cab
                display.setCursorPos(math.max(1, tx - 6), ty)
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.cyan)
                display.write(t.type.sprite[1])
                
                -- Line 2: Body / Brand
                display.setCursorPos(math.max(1, tx - 6), ty + 1)
                display.setTextColor(colors[t.col] or colors.white)
                display.write(t.type.sprite[2])
                
                -- Line 3: Wheels & Taillights
                display.setCursorPos(math.max(1, tx - 6), ty + 2)
                display.setTextColor(colors.red)
                display.write(t.type.sprite[3])
            end
        end
    end
    
    -- 4. Render Collectibles (Coins & Nitro)
    for _, c in ipairs(collectibles) do
        if c.distance > 0 and c.distance < 90 then
            local normDist = 1.0 - (c.distance / 90.0)
            local cy = math.floor(horizonY + normDist * (roadHeight - 2))
            local curRoadW = math.min(screenW - 2, math.floor(20 + normDist * (screenW - 4)))
            local curveOffset = roadCurve * (1.0 - normDist) * 5
            local cx = math.floor(centerX + (c.laneX / 14.0) * (curRoadW * 0.44) + curveOffset)
            
            if cy >= horizonY and cy <= roadBottomY then
                display.setCursorPos(math.max(1, cx - 2), cy)
                display.setBackgroundColor(colors.gray)
                if c.type == "COIN" then
                    display.setTextColor(colors.yellow)
                    display.write("[$]")
                elseif c.type == "NITRO" then
                    display.setTextColor(colors.lime)
                    display.write("[N]")
                else
                    display.setTextColor(colors.cyan)
                    display.write("[>>]")
                end
            end
        end
    end
    
    -- 5. Render Player 4-Line Detailed Supercar (At bottom center)
    local playerY = roadBottomY - 4
    local curRoadW = math.min(screenW - 2, math.floor(20 + 1.0 * (screenW - 4)))
    local playerX = math.floor(centerX + (player.laneX / 14.0) * (curRoadW * 0.44))
    local car = CARS[currentCarIdx]
    
    -- Line 1: Aerodynamic Roof & Mirrors
    display.setCursorPos(math.max(1, playerX - 6), playerY)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightGray)
    display.write(car.sprite[1])
    
    -- Line 2: Tinted Glass Windshield & Headlights
    display.setCursorPos(math.max(1, playerX - 6), playerY + 1)
    display.setTextColor(colors.cyan)
    display.write(car.sprite[2])
    
    -- Line 3: Metallic Sports Body & Decals
    display.setCursorPos(math.max(1, playerX - 6), playerY + 2)
    display.setTextColor(colors[car.col])
    display.write(car.sprite[3])
    
    -- Line 4: Racing Slicks & Glowing Taillights / Exhausts
    display.setCursorPos(math.max(1, playerX - 6), playerY + 3)
    display.setTextColor(player.isBraking and colors.red or colors.white)
    display.write(car.sprite[4])
    
    -- Nitro Exhaust Flames
    if player.isNitro then
        display.setCursorPos(math.max(1, playerX - 3), playerY + 4)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write("^^   ^^")
    end
    
    -- 6. HUD Dashboard (Top & Bottom Overlays)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local distPct = math.min(100, math.floor((distanceMeters / targetDistance) * 100))
    local hud = string.format(" STAGE %d  %3d KM/H [G%d]   DIST: %4dm (%d%%)   $%d   SCORE: %06d ", 
        currentStage, math.floor(player.speed), player.gear, math.floor(distanceMeters), distPct, totalCash, raceScore)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- Nitro & Hull Gauges (Top Row 2)
    display.setCursorPos(2, 2)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lime)
    local nitroBars = math.floor((player.nitro / car.nitroCap) * 10)
    display.write(string.format("NITRO: [%s%s]", string.rep("|", nitroBars), string.rep(" ", 10 - nitroBars)))
    
    display.setCursorPos(screenW - 20, 2)
    display.setTextColor(player.hp > 30 and colors.lime or colors.red)
    local hpBars = math.floor((player.hp / 100) * 10)
    display.write(string.format("HULL: [%s%s]", string.rep("#", hpBars), string.rep(" ", 10 - hpBars)))
    
    -- Popups
    if popupAlert then
        display.setCursorPos(math.floor(screenW / 2) - math.floor(#popupAlert.text / 2), 5)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors[popupAlert.col] or colors.yellow)
        display.write(" " .. popupAlert.text .. " ")
    end
    
    -- 7. Touch Controls Matrix
    local ctrlY = screenH - 1
    registerButton("BTN_LEFT", 2, ctrlY, 11, 2, " [ < LEFT ] ", "yellow", "blue")
    registerButton("BTN_NITRO", 14, ctrlY, 15, 2, " [ NITRO (W) ] ", "cyan", "blue")
    registerButton("BTN_BRAKE", 30, ctrlY, 15, 2, " [ BRAKE (S) ] ", "red", "blue")
    registerButton("BTN_RIGHT", 46, ctrlY, 11, 2, " [ RIGHT > ] ", "yellow", "blue")
    registerButton("BTN_GARAGE", screenW - 16, ctrlY, 10, 2, " [GARAGE] ", "yellow", "purple")
    registerButton("BTN_QUIT", screenW - 5, ctrlY, 5, 2, "[ Q ]", "white", "red")
    
    -- Game Over / Win Overlays
    if gameState == "CRASHED" then
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) - 2)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================ ")
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) - 1)
        display.write("     VEHICLE TOTALED / CRASH!     ")
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2))
        display.write(string.format("  DISTANCE: %4dm | SCORE: %06d  ", math.floor(distanceMeters), raceScore))
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", math.floor(screenW / 2) - 16, math.floor(screenH / 2) + 3, 32, 2, " [ REPAIR & TRY AGAIN (TAP) ] ", "yellow", "blue")
        
    elseif gameState == "FINISHED" then
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) - 2)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ================================ ")
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) - 1)
        display.write("    *** RACE COMPLETED! ***      ")
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2))
        display.write(string.format("  PRIZE: +$1200 | TOTAL: $%d   ", totalCash))
        display.setCursorPos(math.floor(screenW / 2) - 16, math.floor(screenH / 2) + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", math.floor(screenW / 2) - 16, math.floor(screenH / 2) + 3, 32, 2, " [ NEXT HIGHWAY RACE (TAP) ] ", "yellow", "green")
    end
    
    drawButtons()
end

-- ============================================================================
-- GARAGE & SHOWROOM MENU
-- ============================================================================
local function renderGarage()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- Title
    display.setCursorPos(math.floor(screenW / 2) - 16, 2)
    display.setBackgroundColor(colors.purple)
    display.setTextColor(colors.yellow)
    display.write(" ================================ ")
    display.setCursorPos(math.floor(screenW / 2) - 16, 3)
    display.write("    CYBER GARAGE & TUNING PRO     ")
    display.setCursorPos(math.floor(screenW / 2) - 16, 4)
    display.write(" ================================ ")
    
    display.setCursorPos(4, 6)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(string.format("YOUR WALLET: $%d", totalCash))
    
    -- Display 4 Supercars
    for idx, c in ipairs(CARS) do
        local cy = 8 + (idx - 1) * 3
        display.setCursorPos(4, cy)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors[c.col])
        display.write(string.format(" %s [%s] ", c.name, c.tag))
        
        display.setCursorPos(28, cy)
        display.setTextColor(colors.white)
        display.write(string.format("MAX: %d km/h | ACCEL: %.1f | NITRO: %d", c.maxSpd, c.accel, c.nitroCap))
        
        if c.unlocked then
            if currentCarIdx == idx then
                registerButton("BTN_SEL_" .. idx, screenW - 14, cy, 12, 2, " [SELECTED] ", "lime", "blue")
            else
                registerButton("BTN_SEL_" .. idx, screenW - 14, cy, 12, 2, " [ EQUIP ] ", "yellow", "blue")
            end
        else
            registerButton("BTN_BUY_" .. idx, screenW - 14, cy, 12, 2, string.format("[$%d BUY]", c.price), (totalCash >= c.price) and "yellow" or "lightGray", "purple")
        end
    end
    
    registerButton("BTN_BACK", math.floor(screenW / 2) - 12, screenH - 3, 24, 2, " [ < BACK TO RACE ] ", "yellow", "blue")
    
    drawButtons()
end

-- ============================================================================
-- TITLE SCREEN
-- ============================================================================
local function renderTitleScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local titleY = 4
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ==================================== ")
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 1)
    display.write("       HIGHWAY RACER 2077 PRO         ")
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 2)
    display.write(" ==================================== ")
    
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("  HIGHWAY DISTANCE: 5,000 METERS      ")
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 7)
    display.setTextColor(colors.white)
    display.write("  CONTROLS: [A/D] Steer | [W] Nitro   ")
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 8)
    display.write("            [S] Brake   | [G] Garage  ")
    display.setCursorPos(math.floor(screenW / 2) - 18, titleY + 10)
    display.setTextColor(colors.yellow)
    display.write(string.format("  HIGH SCORE: %06d | CASH: $%d", highScore, totalCash))
    
        -- Speed Mode Selector
    local midX = math.floor(screenW / 2)
    display.setCursorPos(midX - 16, titleY + 9)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write("   SELECT SPEED MODE DIFFICULTY:      ")
    
    registerButton("BTN_SPD_1", midX - 18, titleY + 11, 11, 2, " [ NOVICE ] ", (speedModeIdx == 1) and "lime" or "white", (speedModeIdx == 1) and "green" or "gray")
    registerButton("BTN_SPD_2", midX - 5, titleY + 11, 11, 2, " [  PRO  ] ", (speedModeIdx == 2) and "yellow" or "white", (speedModeIdx == 2) and "blue" or "gray")
    registerButton("BTN_SPD_3", midX + 8, titleY + 11, 11, 2, " [ HYPER ] ", (speedModeIdx == 3) and "red" or "white", (speedModeIdx == 3) and "purple" or "gray")
    
    registerButton("BTN_START", midX - 16, screenH - 3, 32, 2, " [ TAP / SPACE TO START RACE ] ", "yellow", "blue")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.12)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        elseif gameState == "GARAGE" then
            renderGarage()
        else
            renderRace()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.12)
            if gameState == "RACING" then
                updateRace()
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    initRace()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "GARAGE" then
                if p1 == keys.q or p1 == keys.escape or p1 == keys.g then
                    gameState = "TITLE"
                end
            else
                if p1 == keys.left or p1 == keys.a then
                    player.laneX = math.max(-14.0, player.laneX - 2.6)
                elseif p1 == keys.right or p1 == keys.d then
                    player.laneX = math.min(14.0, player.laneX + 2.6)
                elseif p1 == keys.up or p1 == keys.w or p1 == keys.space then
                    player.isNitro = true
                    playSound("nitro")
                elseif p1 == keys.down or p1 == keys.s then
                    player.isBraking = true
                elseif p1 == keys.g then
                    gameState = "GARAGE"
                elseif p1 == keys.r then
                    initRace()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "key_up" then
            if p1 == keys.up or p1 == keys.w or p1 == keys.space then
                player.isNitro = false
            elseif p1 == keys.down or p1 == keys.s then
                player.isBraking = false
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "BTN_SPD_1" then
                    speedModeIdx = 1
                elseif cid == "BTN_SPD_2" then
                    speedModeIdx = 2
                elseif cid == "BTN_SPD_3" then
                    speedModeIdx = 3
                else
                    initRace()
                end
            elseif gameState == "GARAGE" then
                if cid == "BTN_BACK" then
                    gameState = "RACING"
                elseif cid and string.sub(cid, 1, 8) == "BTN_SEL_" then
                    local idx = tonumber(string.sub(cid, 9))
                    if idx and CARS[idx].unlocked then currentCarIdx = idx end
                elseif cid and string.sub(cid, 1, 8) == "BTN_BUY_" then
                    local idx = tonumber(string.sub(cid, 9))
                    if idx and not CARS[idx].unlocked and totalCash >= CARS[idx].price then
                        totalCash = totalCash - CARS[idx].price
                        CARS[idx].unlocked = true
                        currentCarIdx = idx
                        playSound("coin")
                    end
                end
            else
                if cid == "BTN_RETRY" then
                    initRace()
                elseif cid == "BTN_GARAGE" then
                    gameState = "GARAGE"
                elseif cid == "BTN_LEFT" then
                    player.laneX = math.max(-14.0, player.laneX - 3.2)
                elseif cid == "BTN_RIGHT" then
                    player.laneX = math.min(14.0, player.laneX + 3.2)
                elseif cid == "BTN_NITRO" then
                    player.isNitro = not player.isNitro
                    if player.isNitro then playSound("nitro") end
                elseif cid == "BTN_BRAKE" then
                    player.isBraking = not player.isBraking
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Screen-Half Touch Control (Left half -> Steer Left, Right half -> Steer Right)
                    local screenW, screenH = display.getSize()
                    local midX = math.floor(screenW / 2)
                    
                    if mx < midX then
                        player.laneX = math.max(-14.0, player.laneX - 3.2)
                    else
                        player.laneX = math.min(14.0, player.laneX + 3.2)
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
        display.write("Highway Racer closed.")
    else
        print("Highway Racer closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Race Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Race Error: " .. tostring(err))
end
