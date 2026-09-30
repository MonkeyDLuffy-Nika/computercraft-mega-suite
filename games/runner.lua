-- ============================================================================
-- CYBER RUNNER 2077 DELUXE PRO - CC: TWEAKED EDITION
-- 3-Lane Subway Parkour, Jump & Slide, Trains, Hoverboards & Synth Audio
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
-- HIGH-VIBRANCE NEON CYBER PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF8C00, -- Construction Barrier
    [colors.magenta]   = 0xE91E63, -- Cyber Runner Neon
    [colors.lightBlue] = 0x00E5FF, -- Hoverboard Glow
    [colors.yellow]    = 0xFFEB3B, -- Gold Coins / Shield
    [colors.lime]      = 0x00E676, -- Magnet Power-up
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- Subway Tracks
    [colors.lightGray] = 0x546E7A, -- Steel Rails
    [colors.cyan]      = 0x18FFFF,
    [colors.purple]    = 0x7B1FA2, -- Night Sky
    [colors.blue]      = 0x0D1B3E, -- Midnight Arena
    [colors.brown]     = 0x5D4037, -- Railway Ties
    [colors.green]     = 0x2E7D32,
    [colors.red]       = 0xFF1744, -- Train Red Lights
    [colors.black]     = 0x080B11
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
        if snd == "jump" then
            speaker.playNote("snare", 0.5, 18)
        elseif snd == "slide" then
            speaker.playNote("bass", 0.4, 8)
        elseif snd == "switch" then
            speaker.playNote("snare", 0.3, 14)
        elseif snd == "coin" then
            speaker.playNote("bell", 0.7, 22)
            speaker.playNote("chime", 0.7, 24)
        elseif snd == "power" then
            speaker.playNote("chime", 0.9, 20)
            speaker.playNote("bell", 0.9, 24)
        elseif snd == "crash" then
            speaker.playNote("bass", 1.0, 4)
            speaker.playNote("snare", 1.0, 6)
        elseif snd == "board" then
            speaker.playNote("chime", 0.8, 16)
            speaker.playNote("chime", 0.8, 22)
        end
    end)
end

-- ============================================================================
-- GAME STATE & RUNNER PHYSICS
-- ============================================================================
local gameState = "TITLE" -- "TITLE", "RUNNING", "CRASHED", "SHOP"
local score = 0
local highScore = 12400
local totalCoins = 50
local runDistance = 0
local gameSpeed = 1.0
local spawnCooldown = 0

-- Runner Character (3 Lanes: 1=Left, 2=Middle, 3=Right)
local runner = {
    lane = 2,           -- 1, 2, 3
    visualX = 0,        -- Smooth interpolation
    y = 0.0,            -- Jump vertical height (0 = ground, >0 = in air)
    vy = 0.0,
    isJumping = false,
    isSliding = false,
    slideTimer = 0,
    hasHoverboard = false,
    hoverboardTimer = 0,
    hasMagnet = false,
    magnetTimer = 0,
    runAnim = 0
}

local obstacles = {}
local coins = {}
local powerups = {}
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
local function initRun()
    runner.lane = 2
    runner.visualX = 0
    runner.y = 0.0
    runner.vy = 0.0
    runner.isJumping = false
    runner.isSliding = false
    runner.slideTimer = 0
    runner.hasHoverboard = false
    runner.hoverboardTimer = 0
    runner.hasMagnet = false
    runner.magnetTimer = 0
    runner.runAnim = 0
    
    score = 0
    runDistance = 0
    gameSpeed = 1.0
    spawnCooldown = 0
    obstacles = {}
    coins = {}
    powerups = {}
    popupAlert = nil
    gameState = "RUNNING"
end

-- ============================================================================
-- SPAWNERS & OBSTACLES
-- ============================================================================
local function spawnObstacle()
    local spawnDist = 90
    
    -- Check if any obstacle is already near the spawn distance (Prevent overlapping!)
    for _, obs in ipairs(obstacles) do
        if obs.dist > 65 then return end
    end
    
    -- Choose 1 or 2 lanes to block, NEVER all 3! (Guaranteed open escape lane)
    local blockedLanes = {}
    local numObstacles = (math.random(1, 10) <= 7) and 1 or 2
    local availableLanes = { 1, 2, 3 }
    
    -- Shuffle lanes
    for i = 3, 2, -1 do
        local j = math.random(1, i)
        availableLanes[i], availableLanes[j] = availableLanes[j], availableLanes[i]
    end
    
    for i = 1, numObstacles do
        local chosenLane = availableLanes[i]
        local r = math.random(1, 10)
        local obsType = "BARRIER_LOW"
        
        if r <= 4 then
            obsType = "BARRIER_LOW"   -- Jump over
        elseif r <= 7 then
            obsType = "BARRIER_HIGH"  -- Slide under
        else
            obsType = "TRAIN"         -- Massive train
        end
        
        table.insert(obstacles, {
            lane = chosenLane,
            dist = spawnDist,
            type = obsType
        })
        blockedLanes[chosenLane] = true
    end
    
    -- Spawn Clean Coin Arcs ONLY in unblocked open lanes!
    for l = 1, 3 do
        if not blockedLanes[l] and math.random(1, 2) == 1 then
            for step = 0, 3 do
                table.insert(coins, {
                    lane = l,
                    dist = spawnDist + step * 5,
                    collected = false
                })
            end
            
            -- Rare Power-Up in the open lane
            if math.random(1, 12) == 1 then
                table.insert(powerups, {
                    lane = l,
                    dist = spawnDist + 22,
                    type = (math.random(1, 2) == 1) and "MAGNET" or "BOARD"
                })
            end
        end
    end
end

-- ============================================================================
-- PHYSICS & UPDATE LOOP
-- ============================================================================
local function updateRun()
    if gameState ~= "RUNNING" then return end
    
    runDistance = runDistance + 1 * gameSpeed
    score = score + math.floor(1.5 * gameSpeed)
    if score > highScore then highScore = score end
    
    -- Dynamic Speed Ramp
    gameSpeed = math.min(2.4, 1.0 + (runDistance / 3000) * 0.8)
    
    -- Runner Animation & Jump Physics
    runner.runAnim = (runner.runAnim + 1) % 4
    
    if runner.isJumping then
        runner.vy = runner.vy - 0.28
        runner.y = runner.y + runner.vy
        if runner.y <= 0 then
            runner.y = 0
            runner.vy = 0
            runner.isJumping = false
        end
    end
    
    if runner.isSliding then
        runner.slideTimer = runner.slideTimer - 1
        if runner.slideTimer <= 0 then
            runner.isSliding = false
        end
    end
    
    if runner.hoverboardTimer > 0 then
        runner.hoverboardTimer = runner.hoverboardTimer - 1
        if runner.hoverboardTimer <= 0 then runner.hasHoverboard = false end
    end
    
    if runner.magnetTimer > 0 then
        runner.magnetTimer = runner.magnetTimer - 1
        if runner.magnetTimer <= 0 then runner.hasMagnet = false end
    end
    
    -- Strict Distance Spawner Timer
    spawnCooldown = spawnCooldown - 1
    if spawnCooldown <= 0 then
        spawnCooldown = math.random(22, 30)
        spawnObstacle()
    end
    
    -- Update Obstacles
    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.dist = obs.dist - (1.6 * gameSpeed)
        
        -- Collision Check
        if obs.dist <= 3.5 and obs.dist >= -1.0 and obs.lane == runner.lane then
            local hit = false
            
            if obs.type == "BARRIER_LOW" then
                -- Must be JUMPING (height > 1.8)
                if runner.y < 1.8 then hit = true end
            elseif obs.type == "BARRIER_HIGH" then
                -- Must be SLIDING
                if not runner.isSliding then hit = true end
            elseif obs.type == "TRAIN" then
                -- Must be above train (height > 3.2) or hit
                if runner.y < 3.2 then hit = true end
            end
            
            if hit then
                if runner.hasHoverboard then
                    -- Save from crash with hoverboard
                    runner.hasHoverboard = false
                    runner.hoverboardTimer = 0
                    table.remove(obstacles, i)
                    popupAlert = { text = "HOVERBOARD SAVED YOU!", col = "cyan", timer = 14 }
                    playSound("crash")
                else
                    gameState = "CRASHED"
                    playSound("crash")
                    return
                end
            end
        end
        
        if obs.dist < -10 then table.remove(obstacles, i) end
    end
    
    -- Update Coins
    for i = #coins, 1, -1 do
        local c = coins[i]
        c.dist = c.dist - (1.6 * gameSpeed)
        
        -- Magnet Pull
        if runner.hasMagnet and math.abs(c.dist) < 25 then
            if c.lane < runner.lane then c.lane = c.lane + 0.1
            elseif c.lane > runner.lane then c.lane = c.lane - 0.1 end
        end
        
        if not c.collected and math.abs(c.dist) < 2.5 and math.abs(c.lane - runner.lane) < 0.6 then
            c.collected = true
            totalCoins = totalCoins + 1
            score = score + 50
            playSound("coin")
        end
        
        if c.dist < -10 or c.collected then table.remove(coins, i) end
    end
    
    -- Update Power-ups
    for i = #powerups, 1, -1 do
        local pw = powerups[i]
        pw.dist = pw.dist - (1.6 * gameSpeed)
        
        if math.abs(pw.dist) < 2.5 and pw.lane == runner.lane then
            if pw.type == "MAGNET" then
                runner.hasMagnet = true
                runner.magnetTimer = 100
                popupAlert = { text = "COIN MAGNET ACTIVE!", col = "lime", timer = 14 }
                playSound("power")
            elseif pw.type == "BOARD" then
                runner.hasHoverboard = true
                runner.hoverboardTimer = 150
                popupAlert = { text = "HOVERBOARD ACTIVATED!", col = "cyan", timer = 14 }
                playSound("board")
            end
            table.remove(powerups, i)
        elseif pw.dist < -10 then
            table.remove(powerups, i)
        end
    end
    
    if popupAlert then
        popupAlert.timer = popupAlert.timer - 1
        if popupAlert.timer <= 0 then popupAlert = nil end
    end
end

-- ============================================================================
-- FULL-SCREEN 3-LANE SUBWAY RENDER PIPELINE
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local horizonY = 5
    local groundY = screenH - 4
    local roadH = groundY - horizonY + 1
    local centerX = math.floor(screenW / 2)
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Midnight Sky & Neon Billboard Horizon
    for y = 1, horizonY do
        display.setCursorPos(1, y)
        if y <= 3 then
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.lightBlue)
            if y == 2 then
                display.write("   *     .       [ CYBER SUBWAY RUNNER 2077 ]       *      .     *    ")
            else
                display.write(" .         *          .          *          .          *         .    ")
            end
        elseif y == 4 then
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.magenta)
            display.write("  |#SUBWAY#|    |===NEON===|    |#CYBER#|    |===METRO===|    |#PARKOUR#| ")
        elseif y == 5 then
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.lightGray)
            display.write("========================================================================")
        end
    end
    
    -- 2. 3 Perspective Subway Rail Lanes (Left, Mid, Right)
    for y = horizonY + 1, groundY do
        local progress = (y - horizonY) / roadH -- 0.0 (top) to 1.0 (bottom)
        local curTrackW = math.floor(18 + progress * (screenW - 20))
        local trackLeft = math.floor(centerX - curTrackW / 2)
        local trackRight = trackLeft + curTrackW - 1
        
        -- Dark Ballast Track Surface
        display.setCursorPos(math.max(1, trackLeft), y)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", curTrackW))
        
        -- 3 Rails (Dividing the 3 Subway Lanes)
        local laneStep = curTrackW / 3
        for l = 0, 3 do
            local lx = math.floor(trackLeft + l * laneStep)
            if lx >= 1 and lx <= screenW then
                display.setCursorPos(lx, y)
                display.setBackgroundColor(colors.lightGray)
                display.write(" ")
            end
        end
        
        -- Wooden Railway Ties
        if (math.floor(runDistance * 0.5 + y) % 3 == 0) then
            for l = 0, 2 do
                local lx = math.floor(trackLeft + l * laneStep + laneStep * 0.3)
                if lx >= 1 and lx <= screenW - 3 then
                    display.setCursorPos(lx, y)
                    display.setBackgroundColor(colors.brown)
                    display.write("---")
                end
            end
        end
    end
    
    -- 3. Render Obstacles (Trains, Low & High Barriers)
    for _, obs in ipairs(obstacles) do
        if obs.dist > 0 and obs.dist < 80 then
            local normDist = 1.0 - (obs.dist / 80.0)
            local oy = math.floor(horizonY + normDist * (roadH - 3))
            local curTrackW = 18 + normDist * (screenW - 20)
            local trackLeft = centerX - curTrackW / 2
            local laneStep = curTrackW / 3
            local ox = math.floor(trackLeft + (obs.lane - 0.5) * laneStep)
            
            if oy >= horizonY + 1 and oy <= groundY - 1 then
                if obs.type == "BARRIER_LOW" then
                    -- Low Jump Barrier (Orange & White Stripes)
                    display.setCursorPos(math.max(1, ox - 3), oy)
                    display.setBackgroundColor(colors.orange)
                    display.setTextColor(colors.white)
                    display.write("[/\/\/]")
                elseif obs.type == "BARRIER_HIGH" then
                    -- High Overhead Duck Barrier
                    display.setCursorPos(math.max(1, ox - 3), oy - 1)
                    display.setBackgroundColor(colors.red)
                    display.setTextColor(colors.yellow)
                    display.write("[#DUCK#]")
                    display.setCursorPos(math.max(1, ox - 3), oy)
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.yellow)
                    display.write(" |    | ")
                elseif obs.type == "TRAIN" then
                    -- Detailed 4-Line Oncoming Bullet Train
                    display.setCursorPos(math.max(1, ox - 5), oy - 3)
                    display.setBackgroundColor(colors.lightGray)
                    display.setTextColor(colors.cyan)
                    display.write(" /---------\\ ")
                    
                    display.setCursorPos(math.max(1, ox - 5), oy - 2)
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.yellow)
                    display.write("|[#]METRO[#]|")
                    
                    display.setCursorPos(math.max(1, ox - 5), oy - 1)
                    display.setBackgroundColor(colors.lightGray)
                    display.setTextColor(colors.cyan)
                    display.write("| |=======| |")
                    
                    display.setCursorPos(math.max(1, ox - 5), oy)
                    display.setBackgroundColor(colors.red)
                    display.setTextColor(colors.white)
                    display.write("|_ (O) (O) _|")
                end
            end
        end
    end
    
    -- 4. Render Floating Gold Coins & Power-ups
    for _, c in ipairs(coins) do
        if not c.collected and c.dist > 0 and c.dist < 80 then
            local normDist = 1.0 - (c.dist / 80.0)
            local cy = math.floor(horizonY + normDist * (roadH - 3))
            local curTrackW = 18 + normDist * (screenW - 20)
            local trackLeft = centerX - curTrackW / 2
            local laneStep = curTrackW / 3
            local cx = math.floor(trackLeft + (c.lane - 0.5) * laneStep)
            
            if cy >= horizonY + 1 and cy <= groundY then
                display.setCursorPos(math.max(1, cx - 1), cy)
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.yellow)
                display.write("[$]")
            end
        end
    end
    
    for _, pw in ipairs(powerups) do
        if pw.dist > 0 and pw.dist < 80 then
            local normDist = 1.0 - (pw.dist / 80.0)
            local py = math.floor(horizonY + normDist * (roadH - 3))
            local curTrackW = 18 + normDist * (screenW - 20)
            local trackLeft = centerX - curTrackW / 2
            local laneStep = curTrackW / 3
            local px = math.floor(trackLeft + (pw.lane - 0.5) * laneStep)
            
            if py >= horizonY + 1 and py <= groundY then
                display.setCursorPos(math.max(1, px - 2), py)
                display.setBackgroundColor(colors.gray)
                if pw.type == "MAGNET" then
                    display.setTextColor(colors.lime)
                    display.write("[MAG]")
                else
                    display.setTextColor(colors.cyan)
                    display.write("[SKATE]")
                end
            end
        end
    end
    
    -- 5. Render Cyber Parkour Runner (At Bottom)
    local curTrackW = 18 + 1.0 * (screenW - 20)
    local trackLeft = centerX - curTrackW / 2
    local laneStep = curTrackW / 3
    local rx = math.floor(trackLeft + (runner.lane - 0.5) * laneStep)
    local ry = math.floor(groundY - runner.y)
    
    if runner.hasHoverboard then
        -- Hoverboard Trail
        display.setCursorPos(math.max(1, rx - 4), ry + 1)
        display.setBackgroundColor(colors.cyan)
        display.setTextColor(colors.white)
        display.write("<==HOVER==>")
    end
    
    if runner.isSliding then
        -- Detailed Sliding Runner Sprite (2 Lines)
        display.setCursorPos(math.max(1, rx - 3), ry)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write("===[o.o]>")
        display.setCursorPos(math.max(1, rx - 3), ry + 1)
        display.setTextColor(colors.magenta)
        display.write("  <====> ")
    else
        -- Detailed 3-Line Standing / Jumping Runner Sprite
        display.setCursorPos(math.max(1, rx - 3), ry - 2)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write("  _[o.o]_ ")
        
        display.setCursorPos(math.max(1, rx - 3), ry - 1)
        display.setTextColor(colors.magenta)
        display.write(" <|RUN|> ")
        
        display.setCursorPos(math.max(1, rx - 3), ry)
        display.setTextColor(colors.cyan)
        if runner.isJumping then
            display.write("  /\\  /\\ ")
        else
            display.write((runner.runAnim % 2 == 0) and "  //  \\  " or "  \\  //  ")
        end
    end
    
    -- 6. HUD Dashboard (Top Header)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" SCORE: %06d   HIGH: %06d   COINS: $%d   DIST: %4dm ", 
        score, highScore, totalCoins, math.floor(runDistance))
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- Power-up Indicators (Line 2)
    if runner.hasHoverboard or runner.hasMagnet then
        display.setCursorPos(2, 2)
        display.setBackgroundColor(colors.black)
        if runner.hasHoverboard then
            display.setTextColor(colors.cyan)
            display.write("[HOVERBOARD ACTIVE] ")
        end
        if runner.hasMagnet then
            display.setTextColor(colors.lime)
            display.write("[MAGNET ONLINE] ")
        end
    end
    
    if popupAlert then
        display.setCursorPos(math.floor(screenW / 2) - math.floor(#popupAlert.text / 2), 3)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors[popupAlert.col] or colors.yellow)
        display.write(" " .. popupAlert.text .. " ")
    end
    
    -- 7. Touch Controls (Bottom Bar)
    local ctrlY = screenH - 1
    registerButton("BTN_LEFT", 2, ctrlY, 9, 2, " [ < A ] ", "yellow", "blue")
    registerButton("BTN_JUMP", 13, ctrlY, 13, 2, " [ JUMP (W) ] ", "cyan", "purple")
    registerButton("BTN_SLIDE", 28, ctrlY, 13, 2, " [ SLIDE (S) ] ", "magenta", "purple")
    registerButton("BTN_RIGHT", 43, ctrlY, 9, 2, " [ D > ] ", "yellow", "blue")
    registerButton("BTN_QUIT", screenW - 6, ctrlY, 6, 2, "[ Q ]", "white", "red")
    
    -- Game Over Overlay
    if gameState == "CRASHED" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        
        display.setCursorPos(midX - 18, midY - 4)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 3)
        display.write("         RUN OVER / CAUGHT!           ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write(" ==================================== ")
        
        display.setCursorPos(midX - 18, midY - 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.format("  DISTANCE: %4dm   | SCORE: %06d    ", math.floor(runDistance), score))
        display.setCursorPos(midX - 18, midY)
        display.write(string.format("  TOTAL COINS: +$%-3d (TOTAL: $%d)   ", math.floor(score / 50), totalCoins))
        display.setCursorPos(midX - 18, midY + 1)
        display.write(" ==================================== ")
        
        registerButton("BTN_RETRY", midX - 18, midY + 3, 36, 2, " [ >>> RESTART RUN (TAP/SPACE) <<< ] ", "yellow", "blue")
        registerButton("BTN_QUIT", screenW - 6, 2, 6, 2, "[ Q ]", "white", "red")
    end
    
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
    
    local midX = math.floor(screenW / 2)
    local titleY = 4
    
    display.setCursorPos(midX - 18, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ==================================== ")
    display.setCursorPos(midX - 18, titleY + 1)
    display.write("       CYBER SUBWAY RUNNER 2077       ")
    display.setCursorPos(midX - 18, titleY + 2)
    display.write(" ==================================== ")
    
    display.setCursorPos(midX - 18, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("  CONTROLS: [A/D] Change Lanes        ")
    display.setCursorPos(midX - 18, titleY + 6)
    display.setTextColor(colors.yellow)
    display.write("            [W/Space] Jump | [S] Slide")
    display.setCursorPos(midX - 18, titleY + 8)
    display.setTextColor(colors.magenta)
    display.write(string.format("  HIGH SCORE: %06d | COINS: $%d", highScore, totalCoins))
    display.setCursorPos(midX - 18, titleY + 9)
    display.write(" ==================================== ")
    
    registerButton("BTN_START", midX - 16, screenH - 4, 32, 2, " [ TAP / SPACE TO START RUN ] ", "yellow", "blue")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.08)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.08)
            if gameState == "RUNNING" then
                updateRun()
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    initRun()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "CRASHED" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    initRun()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            else
                if p1 == keys.left or p1 == keys.a then
                    if runner.lane > 1 then
                        runner.lane = runner.lane - 1
                        playSound("switch")
                    end
                elseif p1 == keys.right or p1 == keys.d then
                    if runner.lane < 3 then
                        runner.lane = runner.lane + 1
                        playSound("switch")
                    end
                elseif p1 == keys.up or p1 == keys.w or p1 == keys.space then
                    if not runner.isJumping then
                        runner.isJumping = true
                        runner.vy = 1.9
                        playSound("jump")
                    end
                elseif p1 == keys.down or p1 == keys.s then
                    if not runner.isSliding then
                        runner.isSliding = true
                        runner.slideTimer = 12
                        playSound("slide")
                    end
                elseif p1 == keys.r then
                    initRun()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                initRun()
            elseif gameState == "CRASHED" then
                if cid == "BTN_QUIT" then
                    break
                else
                    initRun()
                end
            else
                if cid == "BTN_RETRY" then
                    initRun()
                elseif cid == "BTN_LEFT" then
                    if runner.lane > 1 then runner.lane = runner.lane - 1; playSound("switch") end
                elseif cid == "BTN_RIGHT" then
                    if runner.lane < 3 then runner.lane = runner.lane + 1; playSound("switch") end
                elseif cid == "BTN_JUMP" then
                    if not runner.isJumping then runner.isJumping = true; runner.vy = 1.9; playSound("jump") end
                elseif cid == "BTN_SLIDE" then
                    if not runner.isSliding then runner.isSliding = true; runner.slideTimer = 12; playSound("slide") end
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Touch Navigation: Left/Right halves for lane switch, Top for Jump, Bottom for Slide!
                    local screenW, screenH = display.getSize()
                    local midX = math.floor(screenW / 2)
                    
                    if my < 6 then
                        if not runner.isJumping then runner.isJumping = true; runner.vy = 1.9; playSound("jump") end
                    elseif my > screenH - 5 then
                        if not runner.isSliding then runner.isSliding = true; runner.slideTimer = 12; playSound("slide") end
                    elseif mx < midX then
                        if runner.lane > 1 then runner.lane = runner.lane - 1; playSound("switch") end
                    else
                        if runner.lane < 3 then runner.lane = runner.lane + 1; playSound("switch") end
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
        display.write("Cyber Runner closed.")
    else
        print("Cyber Runner closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Runner Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Runner Error: " .. tostring(err))
end
