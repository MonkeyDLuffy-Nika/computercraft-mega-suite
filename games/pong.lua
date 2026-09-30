-- ============================================================================
-- CYBER PONG 2077 DELUXE PRO - CC: TWEAKED EDITION
-- VS AI, 2-Player PvP, Power-Ups, Spin Physics, Big Scoreboard & Synth Audio
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
-- HIGH-CONTRAST NEON CYBER PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF9100,
    [colors.magenta]   = 0xFF007F, -- Player 1 Neon Magenta
    [colors.lightBlue] = 0x00E5FF, -- Player 2 Neon Cyan
    [colors.yellow]    = 0xFFEA00, -- Glowing Energy Ball
    [colors.lime]      = 0x00E676, -- Power-ups
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- Table Surface
    [colors.lightGray] = 0x546E7A, -- Table Borders
    [colors.cyan]      = 0x18FFFF,
    [colors.purple]    = 0x651FFF,
    [colors.blue]      = 0x0D1B3E, -- Midnight Arena
    [colors.brown]     = 0x5D4037,
    [colors.green]     = 0x00C853,
    [colors.red]       = 0xFF1744, -- Goal Alerts
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
        if snd == "paddle_hit" then
            speaker.playNote("snare", 0.7, 18)
            speaker.playNote("chime", 0.7, 22)
        elseif snd == "wall_hit" then
            speaker.playNote("bass", 0.6, 12)
        elseif snd == "goal" then
            speaker.playNote("chime", 0.9, 24)
            speaker.playNote("bell", 0.9, 20)
        elseif snd == "power" then
            speaker.playNote("bell", 0.8, 22)
            speaker.playNote("chime", 0.8, 24)
        elseif snd == "win" then
            for p = 12, 24, 3 do
                speaker.playNote("chime", 0.8, p)
                sleep(0.04)
            end
        end
    end)
end

-- ============================================================================
-- GAME STATE & SETTINGS
-- ============================================================================
local gameState = "TITLE" -- "TITLE", "PLAYING", "GOAL", "WIN", "SETTINGS"
local gameMode = "AI"     -- "AI" or "PVP"
local aiDifficulty = 2    -- 1=Easy, 2=Pro, 3=Master
local winningScore = 5

local p1 = {
    y = 10.0,
    h = 5,
    w = 2,
    score = 0,
    col = "magenta",
    name = "PLAYER 1",
    speed = 1.4,
    laserPower = false
}

local p2 = {
    y = 10.0,
    h = 5,
    w = 2,
    score = 0,
    col = "cyan",
    name = "AI BOT",
    speed = 1.4,
    laserPower = false
}

-- Balls & Particles
local balls = {}
local powerUps = {}
local goalTimer = 0
local goalScorer = ""
local matchWinner = ""

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
-- SPAWNERS & RESETS
-- ============================================================================
local function spawnBall(dirX)
    local screenW, screenH = display.getSize()
    local tableTop = 4
    local tableBottom = screenH - 3
    
    local spd = 1.2
    local angleY = (math.random() * 0.8 - 0.4)
    table.insert(balls, {
        x = math.floor(screenW / 2),
        y = math.floor((tableTop + tableBottom) / 2),
        vx = (dirX or ((math.random(1, 2) == 1) and 1 or -1)) * spd,
        vy = angleY,
        trail = {}
    })
end

local function spawnPowerUp()
    if #powerUps >= 2 then return end
    local screenW, screenH = display.getSize()
    local tableTop = 5
    local tableBottom = screenH - 4
    
    local types = { "EXTEND", "SPEED", "MULTIBALL" }
    local chosenType = types[math.random(1, #types)]
    
    table.insert(powerUps, {
        x = math.random(math.floor(screenW * 0.3), math.floor(screenW * 0.7)),
        y = math.random(tableTop, tableBottom),
        type = chosenType,
        timer = 120
    })
end

local function resetRound(scorer)
    local screenW, screenH = display.getSize()
    local tableTop = 4
    local tableBottom = screenH - 3
    local midY = math.floor((tableTop + tableBottom) / 2)
    
    p1.y = midY
    p2.y = midY
    p1.h = 5
    p2.h = 5
    balls = {}
    powerUps = {}
    
    if scorer then
        gameState = "GOAL"
        goalTimer = 18
        goalScorer = scorer
        playSound("goal")
    else
        gameState = "PLAYING"
        spawnBall()
    end
end

local function initMatch()
    p1.score = 0
    p2.score = 0
    p2.name = (gameMode == "AI") and "AI BOT" or "PLAYER 2"
    resetRound(nil)
end

-- ============================================================================
-- PHYSICS & AI ENGINE
-- ============================================================================
local function updateGame()
    local screenW, screenH = display.getSize()
    local tableTop = 4
    local tableBottom = screenH - 3
    local p1X = 3
    local p2X = screenW - 3
    
    if gameState == "GOAL" then
        goalTimer = goalTimer - 1
        if goalTimer <= 0 then
            if p1.score >= winningScore then
                gameState = "WIN"
                matchWinner = p1.name
                playSound("win")
            elseif p2.score >= winningScore then
                gameState = "WIN"
                matchWinner = p2.name
                playSound("win")
            else
                gameState = "PLAYING"
                spawnBall((goalScorer == p1.name) and -1 or 1)
            end
        end
        return
    end
    
    if gameState ~= "PLAYING" then return end
    
    -- 1. AI Paddle Behavior (Pro & Master with prediction and spin)
    if gameMode == "AI" and #balls > 0 then
        -- Track nearest incoming ball
        local targetBall = balls[1]
        for _, b in ipairs(balls) do
            if b.vx > 0 and (not targetBall or b.x > targetBall.x) then
                targetBall = b
            end
        end
        
        if targetBall then
            local aiSpeed = (aiDifficulty == 1) and 0.8 or ((aiDifficulty == 2) and 1.3 or 1.8)
            local diff = targetBall.y - p2.y
            if math.abs(diff) > 0.6 then
                p2.y = p2.y + (diff > 0 and 1 or -1) * math.min(aiSpeed, math.abs(diff))
            end
        end
    end
    
    -- Paddle Boundaries
    p1.y = math.max(tableTop + math.floor(p1.h / 2), math.min(tableBottom - math.floor(p1.h / 2), p1.y))
    p2.y = math.max(tableTop + math.floor(p2.h / 2), math.min(tableBottom - math.floor(p2.h / 2), p2.y))
    
    -- Power-Up Spawner (Rare chance)
    if math.random(1, 120) == 1 then spawnPowerUp() end
    
    for i = #powerUps, 1, -1 do
        local pw = powerUps[i]
        pw.timer = pw.timer - 1
        if pw.timer <= 0 then table.remove(powerUps, i) end
    end
    
    -- 2. Update Balls Physics & Collisions
    for i = #balls, 1, -1 do
        local b = balls[i]
        
        -- Trail
        table.insert(b.trail, 1, { x = b.x, y = b.y })
        if #b.trail > 3 then table.remove(b.trail) end
        
        b.x = b.x + b.vx
        b.y = b.y + b.vy
        
        -- Top / Bottom Wall Bounces
        if b.y <= tableTop then
            b.y = tableTop
            b.vy = math.abs(b.vy)
            playSound("wall_hit")
        elseif b.y >= tableBottom then
            b.y = tableBottom
            b.vy = -math.abs(b.vy)
            playSound("wall_hit")
        end
        
        -- Left Paddle Collision (Player 1)
        if b.x <= p1X + 1.2 and b.x >= p1X - 1.0 and b.vx < 0 then
            local paddleTop = p1.y - p1.h / 2
            local paddleBottom = p1.y + p1.h / 2
            
            if b.y >= paddleTop - 0.5 and b.y <= paddleBottom + 0.5 then
                local hitOffset = (b.y - p1.y) / (p1.h / 2) -- -1.0 (top edge) to +1.0 (bottom edge)
                b.vx = math.min(2.5, math.abs(b.vx) * 1.08)
                b.vy = hitOffset * 1.3
                playSound("paddle_hit")
            end
        end
        
        -- Right Paddle Collision (Player 2 / AI)
        if b.x >= p2X - 1.2 and b.x <= p2X + 1.0 and b.vx > 0 then
            local paddleTop = p2.y - p2.h / 2
            local paddleBottom = p2.y + p2.h / 2
            
            if b.y >= paddleTop - 0.5 and b.y <= paddleBottom + 0.5 then
                local hitOffset = (b.y - p2.y) / (p2.h / 2)
                b.vx = -math.min(2.5, math.abs(b.vx) * 1.08)
                b.vy = hitOffset * 1.3
                playSound("paddle_hit")
            end
        end
        
        -- Power-Up Collision
        for pIdx = #powerUps, 1, -1 do
            local pw = powerUps[pIdx]
            if math.abs(b.x - pw.x) < 2.0 and math.abs(b.y - pw.y) < 1.5 then
                if pw.type == "EXTEND" then
                    if b.vx > 0 then p1.h = math.min(9, p1.h + 2) else p2.h = math.min(9, p2.h + 2) end
                elseif pw.type == "SPEED" then
                    b.vx = b.vx * 1.4
                elseif pw.type == "MULTIBALL" then
                    spawnBall(-b.vx)
                end
                table.remove(powerUps, pIdx)
                playSound("power")
            end
        end
        
        -- Goal Scoring
        if b.x < 1 then
            p2.score = p2.score + 1
            resetRound(p2.name)
            return
        elseif b.x > screenW then
            p1.score = p1.score + 1
            resetRound(p1.name)
            return
        end
    end
end

-- ============================================================================
-- FULL-SCREEN TABLE RENDERER
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local tableTop = 4
    local tableBottom = screenH - 3
    local centerX = math.floor(screenW / 2)
    local p1X = 3
    local p2X = screenW - 3
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top HUD & Big Digital Scoreboard
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hudTitle = string.format(" [ %s ]   %s: %d  |  %s: %d   (FIRST TO %d) ", 
        (gameMode == "AI") and ("VS AI (" .. ((aiDifficulty == 1) and "EASY" or ((aiDifficulty == 2) and "PRO" or "MASTER")) .. ")") or "2-PLAYER PVP",
        p1.name, p1.score, p2.name, p2.score, winningScore)
    display.setCursorPos(math.max(1, math.floor((screenW - #hudTitle) / 2)), 1)
    display.write(hudTitle)
    
    -- 2. Neon Table Arena (Lines tableTop to tableBottom)
    for y = tableTop, tableBottom do
        display.setCursorPos(1, y)
        
        if y == tableTop or y == tableBottom then
            -- Metallic Glowing Border
            display.setBackgroundColor(colors.lightGray)
            display.setTextColor(colors.cyan)
            display.write(string.rep("=", screenW))
        else
            -- Table Surface
            display.setBackgroundColor(colors.gray)
            display.write(string.rep(" ", screenW))
            
            -- Center Dashed Net
            if y % 2 == 0 then
                display.setCursorPos(centerX, y)
                display.setBackgroundColor(colors.lightGray)
                display.write(" ")
            end
        end
    end
    
    -- 3. Render Power-Ups
    for _, pw in ipairs(powerUps) do
        display.setCursorPos(pw.x - 1, pw.y)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.lime)
        if pw.type == "EXTEND" then display.write("[+]")
        elseif pw.type == "SPEED" then display.write("[>>]")
        else display.write("[x3]") end
    end
    
    -- 4. Render Ball & Particle Trails
    for _, b in ipairs(balls) do
        -- Trail
        for tIdx, tr in ipairs(b.trail) do
            if tr.y >= tableTop + 1 and tr.y <= tableBottom - 1 then
                display.setCursorPos(math.floor(tr.x), math.floor(tr.y))
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.lightGray)
                display.write(".")
            end
        end
        
        -- Glowing Energy Ball
        local bx = math.floor(b.x)
        local by = math.floor(b.y)
        if by >= tableTop + 1 and by <= tableBottom - 1 and bx >= 1 and bx <= screenW then
            display.setCursorPos(bx, by)
            display.setBackgroundColor(colors.gray)
            display.setTextColor(colors.yellow)
            display.write("(O)")
        end
    end
    
    -- 5. Render Detailed Metallic Paddles
    -- Player 1 Paddle (Left)
    local p1Top = math.floor(p1.y - p1.h / 2)
    for py = p1Top, p1Top + p1.h - 1 do
        if py >= tableTop + 1 and py <= tableBottom - 1 then
            display.setCursorPos(p1X, py)
            display.setBackgroundColor(colors[p1.col])
            display.setTextColor(colors.white)
            display.write("||")
        end
    end
    
    -- Player 2 / AI Paddle (Right)
    local p2Top = math.floor(p2.y - p2.h / 2)
    for py = p2Top, p2Top + p2.h - 1 do
        if py >= tableTop + 1 and py <= tableBottom - 1 then
            display.setCursorPos(p2X - 1, py)
            display.setBackgroundColor(colors[p2.col])
            display.setTextColor(colors.white)
            display.write("||")
        end
    end
    
    -- 6. Bottom Touch Controls Matrix
    local ctrlY = screenH - 1
    registerButton("BTN_P1_UP", 2, ctrlY, 9, 2, " [ ^ W ] ", "magenta", "blue")
    registerButton("BTN_P1_DOWN", 12, ctrlY, 9, 2, " [ v S ] ", "magenta", "blue")
    
    if gameMode == "PVP" then
        registerButton("BTN_P2_UP", screenW - 20, ctrlY, 9, 2, " [ ^ UP ] ", "cyan", "blue")
        registerButton("BTN_P2_DOWN", screenW - 10, ctrlY, 9, 2, " [ v DN ] ", "cyan", "blue")
    else
        registerButton("BTN_MODE", centerX - 10, ctrlY, 20, 2, " [ MODE: VS AI ] ", "yellow", "purple")
    end
    
    registerButton("BTN_QUIT", screenW - 6, 2, 6, 2, "[ Q ]", "white", "red")
    
    -- Goal & Victory Overlays
    if gameState == "GOAL" then
        display.setCursorPos(centerX - 14, math.floor((tableTop + tableBottom) / 2) - 1)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ============================ ")
        display.setCursorPos(centerX - 14, math.floor((tableTop + tableBottom) / 2))
        display.write(string.format("   GOAL SCORED BY %-10s! ", goalScorer))
        display.setCursorPos(centerX - 14, math.floor((tableTop + tableBottom) / 2) + 1)
        display.write(" ============================ ")
        
    elseif gameState == "WIN" then
        display.setCursorPos(centerX - 16, math.floor((tableTop + tableBottom) / 2) - 2)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ================================ ")
        display.setCursorPos(centerX - 16, math.floor((tableTop + tableBottom) / 2) - 1)
        display.write(string.format("    *** %s WINS MATCH! ***    ", matchWinner))
        display.setCursorPos(centerX - 16, math.floor((tableTop + tableBottom) / 2))
        display.write(string.format("     FINAL SCORE: %d - %d         ", p1.score, p2.score))
        display.setCursorPos(centerX - 16, math.floor((tableTop + tableBottom) / 2) + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_REMATCH", centerX - 16, math.floor((tableTop + tableBottom) / 2) + 3, 32, 2, " [ NEW MATCH (TAP) ] ", "yellow", "blue")
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
    display.write("       CYBER PONG 2077 DELUXE PRO     ")
    display.setCursorPos(midX - 18, titleY + 2)
    display.write(" ==================================== ")
    
    display.setCursorPos(midX - 18, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("  CONTROLS: [W/S] Left Paddle         ")
    display.setCursorPos(midX - 18, titleY + 6)
    display.setTextColor(colors.magenta)
    display.write("            [Up/Down] Right Paddle    ")
    display.setCursorPos(midX - 18, titleY + 8)
    display.setTextColor(colors.yellow)
    display.write("  TOUCH: Tap Left / Right screen half ")
    
    registerButton("BTN_START_AI", midX - 16, titleY + 10, 32, 2, " [ 1 PLAYER VS AI BOT ] ", "yellow", "blue")
    registerButton("BTN_START_PVP", midX - 16, titleY + 13, 32, 2, " [ 2 PLAYERS LOCAL PVP ] ", "lime", "purple")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.06) -- Super Smooth 16 FPS Physics
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1_ev, p2_ev, p3_ev = os.pullEvent()
        
        if event == "timer" and p1_ev == timerId then
            timerId = os.startTimer(0.06)
            updateGame()
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1_ev == keys.one or p1_ev == keys.space or p1_ev == keys.enter then
                    gameMode = "AI"
                    initMatch()
                elseif p1_ev == keys.two then
                    gameMode = "PVP"
                    initMatch()
                elseif p1_ev == keys.q or p1_ev == keys.escape then
                    break
                end
            else
                -- Player 1 Controls (W / S)
                if p1_ev == keys.w then
                    p1.y = p1.y - p1.speed
                elseif p1_ev == keys.s then
                    p1.y = p1.y + p1.speed
                end
                
                -- Player 2 Controls (Up / Down)
                if p1_ev == keys.up then
                    p2.y = p2.y - p2.speed
                elseif p1_ev == keys.down then
                    p2.y = p2.y + p2.speed
                elseif p1_ev == keys.r then
                    initMatch()
                elseif p1_ev == keys.q or p1_ev == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
            local mx, my = p2_ev, p3_ev
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "BTN_START_PVP" then
                    gameMode = "PVP"
                    initMatch()
                else
                    gameMode = "AI"
                    initMatch()
                end
            else
                if cid == "BTN_REMATCH" then
                    initMatch()
                elseif cid == "BTN_P1_UP" then
                    p1.y = p1.y - p1.speed * 1.5
                elseif cid == "BTN_P1_DOWN" then
                    p1.y = p1.y + p1.speed * 1.5
                elseif cid == "BTN_P2_UP" then
                    p2.y = p2.y - p2.speed * 1.5
                elseif cid == "BTN_P2_DOWN" then
                    p2.y = p2.y + p2.speed * 1.5
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Touch Dragging on Screen (Left half -> P1 paddle, Right half -> P2 paddle)
                    local screenW, screenH = display.getSize()
                    local midX = math.floor(screenW / 2)
                    
                    if mx < midX then
                        p1.y = my
                    else
                        if gameMode == "PVP" then
                            p2.y = my
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
        display.write("Cyber Pong closed.")
    else
        print("Cyber Pong closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Pong Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Pong Error: " .. tostring(err))
end
