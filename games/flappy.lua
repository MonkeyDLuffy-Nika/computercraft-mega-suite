-- ============================================================================
-- FLAPPY BIRD DELUXE HD - CC: TWEAKED EDITION
-- Expanded Flight Gap, Detailed 3-Line Bird, 3D Shaded Pipes & Floating Coins
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
-- VIBRANT RETRO-ARCADE COLOR PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF8C00, -- Bird Beak / Sunset
    [colors.magenta]   = 0xE91E63,
    [colors.lightBlue] = 0x4FC3F7, -- Daytime Sky
    [colors.yellow]    = 0xFFD600, -- Bird Body / Coins
    [colors.lime]      = 0x43A047, -- Pipe Highlight / Grass
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x37474F, -- Pipe Shadows
    [colors.lightGray] = 0x90A4AE, -- Clouds
    [colors.cyan]      = 0x00E5FF,
    [colors.purple]    = 0x7B1FA2,
    [colors.blue]      = 0x0288D1, -- Deep Sky
    [colors.brown]     = 0x5D4037, -- Soil Ground
    [colors.green]     = 0x2E7D32, -- Green Pipe Core
    [colors.red]       = 0xD50000, -- Medal Ribbon / Alert
    [colors.black]     = 0x0A0E17
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
        if snd == "flap" then
            speaker.playNote("snare", 0.4, 18)
        elseif snd == "point" then
            speaker.playNote("bell", 0.8, 20)
            speaker.playNote("chime", 0.8, 24)
        elseif snd == "coin" then
            speaker.playNote("chime", 0.9, 22)
            speaker.playNote("bell", 0.9, 24)
        elseif snd == "hit" then
            speaker.playNote("bass", 1.0, 8)
            speaker.playNote("snare", 1.0, 4)
        elseif snd == "die" then
            speaker.playNote("bass", 1.0, 4)
        elseif snd == "medal" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.8, p)
                sleep(0.03)
            end
        end
    end)
end

-- ============================================================================
-- BIRD SKINS & CUSTOMIZATION
-- ============================================================================
local BIRD_SKINS = {
    [1] = { name = "CLASSIC CANARY", col = "yellow", beakCol = "orange", price = 0, unlocked = true },
    [2] = { name = "CYBER PHOENIX", col = "magenta", beakCol = "cyan", price = 20, unlocked = false },
    [3] = { name = "EMERALD ROBIN", col = "lime", beakCol = "yellow", price = 50, unlocked = false },
    [4] = { name = "GOLDEN EAGLE", col = "orange", beakCol = "yellow", price = 100, unlocked = false }
}
local currentSkinIdx = 1

-- Game State & Physics Variables
local gameState = "TITLE" -- "TITLE", "READY", "PLAYING", "DYING", "GAMEOVER", "SHOP"
local score = 0
local highScore = 28
local totalCoins = 15

local bird = {
    x = 10,
    y = 12.0,
    vy = 0.0,
    gravity = 0.42,        -- Smooth floaty gravity
    jumpStrength = -1.75,   -- Responsive comfortable flap
    wingAnim = 0,
    deadTimer = 0
}

local pipes = {}
local bonusCoins = {}
local clouds = {}
local groundScroll = 0
local pipeSpawnTimer = 0
local medalAchieved = nil

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
-- LEVEL & PHYSICS INITIALIZATION
-- ============================================================================
local function initGame()
    local screenW, screenH = display.getSize()
    bird.x = math.floor(screenW * 0.22)
    bird.y = math.floor((screenH - 4) * 0.45)
    bird.vy = 0.0
    bird.wingAnim = 0
    bird.deadTimer = 0
    
    score = 0
    groundScroll = 0
    pipeSpawnTimer = 0
    pipes = {}
    bonusCoins = {}
    medalAchieved = nil
    
    -- Initialize Fluffy Sky Clouds
    clouds = {
        { x = 6, y = 3, w = 14 },
        { x = 30, y = 4, w = 18 },
        { x = 56, y = 2, w = 12 }
    }
    
    gameState = "READY"
end

local function flapBird()
    if gameState == "READY" then
        gameState = "PLAYING"
        bird.vy = bird.jumpStrength
        bird.wingAnim = 2.5
        playSound("flap")
    elseif gameState == "PLAYING" then
        bird.vy = bird.jumpStrength
        bird.wingAnim = 2.5
        playSound("flap")
    end
end

-- ============================================================================
-- PIPE SPAWNER (EXPANDED FLIGHT GAP & SPACING)
-- ============================================================================
local function spawnPipe()
    local screenW, screenH = display.getSize()
    local groundY = screenH - 3
    local playableH = groundY - 2
    local gapSize = 10 -- Expanded 10 lines gap for spacious comfortable passage
    
    local minTop = 2
    local maxTop = playableH - gapSize - 1
    local topH = math.random(minTop, maxTop)
    local botY = topH + gapSize + 1
    
    table.insert(pipes, {
        x = screenW + 2,
        w = 7, -- 7 characters wide sturdy pipe
        topH = topH,
        botY = botY,
        scored = false
    })
    
    -- Occasionally spawn a floating gold bonus coin in the gap
    if math.random(1, 3) == 1 then
        table.insert(bonusCoins, {
            x = screenW + 5,
            y = topH + math.floor(gapSize / 2),
            collected = false
        })
    end
end

-- ============================================================================
-- GAME TICK & UPDATE LOOP
-- ============================================================================
local function updateGame()
    local screenW, screenH = display.getSize()
    local groundY = screenH - 3
    
    -- Animate Clouds Parallax
    for _, c in ipairs(clouds) do
        c.x = c.x - 0.12
        if c.x + c.w < 0 then
            c.x = screenW + math.random(2, 10)
            c.y = math.random(2, 5)
        end
    end
    
    groundScroll = (groundScroll + 1) % 6
    
    if gameState == "READY" then
        -- Gentle Idle Bobbing
        bird.wingAnim = (bird.wingAnim + 0.2) % 3
        bird.y = math.floor((screenH - 4) * 0.45) + math.sin(os.clock() * 4) * 0.8
        return
    end
    
    if gameState == "PLAYING" then
        -- 1. Physics Engine
        bird.vy = bird.vy + bird.gravity
        bird.y = bird.y + bird.vy
        bird.wingAnim = math.max(0, bird.wingAnim - 0.22)
        
        -- 2. Pipes Spawning & Movement (Wider spacing: 32 ticks between pipes)
        pipeSpawnTimer = pipeSpawnTimer + 1
        if pipeSpawnTimer >= 32 then
            pipeSpawnTimer = 0
            spawnPipe()
        end
        
        for i = #pipes, 1, -1 do
            local p = pipes[i]
            p.x = p.x - 1.1
            
            -- Score Check
            if not p.scored and (p.x + p.w / 2) <= bird.x then
                p.scored = true
                score = score + 1
                totalCoins = totalCoins + 1
                if score > highScore then highScore = score end
                playSound("point")
            end
            
            -- Collision Check
            local birdBoxLeft = bird.x - 2
            local birdBoxRight = bird.x + 2
            local birdBoxTop = bird.y - 0.5
            local birdBoxBottom = bird.y + 0.8
            
            local pipeLeft = p.x
            local pipeRight = p.x + p.w - 1
            
            if birdBoxRight >= pipeLeft and birdBoxLeft <= pipeRight then
                if birdBoxTop <= p.topH or birdBoxBottom >= p.botY then
                    gameState = "DYING"
                    bird.vy = -1.0
                    playSound("hit")
                    return
                end
            end
            
            if p.x + p.w < -2 then
                table.remove(pipes, i)
            end
        end
        
        -- 3. Bonus Coins Movement & Collection
        for i = #bonusCoins, 1, -1 do
            local coin = bonusCoins[i]
            coin.x = coin.x - 1.1
            
            if not coin.collected and math.abs(coin.x - bird.x) < 2.5 and math.abs(coin.y - bird.y) < 1.8 then
                coin.collected = true
                totalCoins = totalCoins + 3
                score = score + 2
                playSound("coin")
            end
            
            if coin.x < -2 or coin.collected then
                table.remove(bonusCoins, i)
            end
        end
        
        -- 4. Ground / Ceiling Collision
        if bird.y >= groundY - 1 then
            bird.y = groundY - 1
            gameState = "GAMEOVER"
            playSound("hit")
            
            -- Determine Medal
            if score >= 40 then medalAchieved = { name = "PLATINUM", col = "cyan" }
            elseif score >= 25 then medalAchieved = { name = "GOLD", col = "yellow" }
            elseif score >= 10 then medalAchieved = { name = "SILVER", col = "lightGray" }
            elseif score >= 5 then medalAchieved = { name = "BRONZE", col = "orange" }
            end
            if medalAchieved then playSound("medal") end
            return
        elseif bird.y < 1 then
            bird.y = 1
            bird.vy = 0.5
        end
        
    elseif gameState == "DYING" then
        bird.vy = bird.vy + bird.gravity * 1.5
        bird.y = bird.y + bird.vy
        if bird.y >= groundY - 1 then
            bird.y = groundY - 1
            gameState = "GAMEOVER"
            playSound("die")
            
            if score >= 40 then medalAchieved = { name = "PLATINUM", col = "cyan" }
            elseif score >= 25 then medalAchieved = { name = "GOLD", col = "yellow" }
            elseif score >= 10 then medalAchieved = { name = "SILVER", col = "lightGray" }
            elseif score >= 5 then medalAchieved = { name = "BRONZE", col = "orange" }
            end
            if medalAchieved then playSound("medal") end
        end
    end
end

-- ============================================================================
-- FULL-SCREEN RENDER PIPELINE
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local groundY = screenH - 3
    display.setBackgroundColor(colors.lightBlue)
    display.clear()
    
    -- 1. Sky & Parallax Clouds
    for _, c in ipairs(clouds) do
        local cx = math.floor(c.x)
        if cx < screenW and cx + c.w > 1 then
            display.setCursorPos(math.max(1, cx), c.y)
            display.setBackgroundColor(colors.white)
            display.setTextColor(colors.lightGray)
            display.write(string.rep(" ", c.w))
            
            display.setCursorPos(math.max(1, cx + 2), c.y - 1)
            display.write(string.rep(" ", math.max(1, c.w - 4)))
        end
    end
    
    -- 2. Distant Hills & Pine Tree Line Horizon
    display.setCursorPos(1, groundY - 2)
    display.setBackgroundColor(colors.lightBlue)
    display.setTextColor(colors.lime)
    display.write("   /\\     /\\/\\    /\\     /\\/\\    /\\     /\\/\\    /\\     /\\/\\    /\\   ")
    
    display.setCursorPos(1, groundY - 1)
    display.setTextColor(colors.green)
    display.write("  /||\\   /||||\\   /||\\   /||||\\   /||\\   /||||\\   /||\\   /||||\\   /||\\  ")
    
    -- 3. Render 3D Shaded Green Pipes
    for _, p in ipairs(pipes) do
        local px = math.floor(p.x)
        local pw = p.w
        
        if px < screenW and px + pw > 1 then
            -- Top Pipe Stem
            for y = 1, p.topH - 1 do
                display.setCursorPos(math.max(1, px), y)
                display.setBackgroundColor(colors.lime)
                display.write(" ")
                display.setBackgroundColor(colors.green)
                display.write(string.rep(" ", pw - 2))
                display.setBackgroundColor(colors.gray)
                display.write(" ")
            end
            
            -- Top Pipe Rim / Cap with Rivet Accents
            if p.topH >= 1 then
                display.setCursorPos(math.max(1, px - 1), p.topH)
                display.setBackgroundColor(colors.lime)
                display.setTextColor(colors.black)
                display.write("[#")
                display.setBackgroundColor(colors.green)
                display.setTextColor(colors.lime)
                display.write(string.rep("=", pw - 3))
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.white)
                display.write("#]")
            end
            
            -- Bottom Pipe Rim / Cap with Rivet Accents
            if p.botY <= groundY - 1 then
                display.setCursorPos(math.max(1, px - 1), p.botY)
                display.setBackgroundColor(colors.lime)
                display.setTextColor(colors.black)
                display.write("[#")
                display.setBackgroundColor(colors.green)
                display.setTextColor(colors.lime)
                display.write(string.rep("=", pw - 3))
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.white)
                display.write("#]")
            end
            
            -- Bottom Pipe Stem
            for y = p.botY + 1, groundY - 1 do
                display.setCursorPos(math.max(1, px), y)
                display.setBackgroundColor(colors.lime)
                display.write(" ")
                display.setBackgroundColor(colors.green)
                display.write(string.rep(" ", pw - 2))
                display.setBackgroundColor(colors.gray)
                display.write(" ")
            end
        end
    end
    
    -- 4. Render Floating Bonus Gold Coins
    for _, coin in ipairs(bonusCoins) do
        if not coin.collected and coin.x > 0 and coin.x < screenW then
            display.setCursorPos(math.floor(coin.x), math.floor(coin.y))
            display.setBackgroundColor(colors.lightBlue)
            display.setTextColor(colors.yellow)
            display.write("[$]")
        end
    end
    
    -- 5. Ground (Lush Grass + Textured Soil)
    display.setCursorPos(1, groundY)
    display.setBackgroundColor(colors.lime)
    display.setTextColor(colors.green)
    display.write(string.rep("W", screenW))
    
    for gy = groundY + 1, screenH do
        display.setCursorPos(1, gy)
        display.setBackgroundColor(colors.brown)
        display.setTextColor(colors.yellow)
        local pattern = ""
        for i = 1, screenW do
            pattern = pattern .. (((i + groundScroll + gy) % 4 == 0) and "." or " ")
        end
        display.write(pattern)
    end
    
    -- 6. Render Detailed Flappy Bird (3-Line Sprite with Animated Wings)
    local bx = math.floor(bird.x)
    local by = math.floor(bird.y)
    local skin = BIRD_SKINS[currentSkinIdx]
    
    if by >= 1 and by <= groundY then
        local wingUp = (bird.wingAnim > 1)
        
        -- Line 1: Crown & Eyebrow
        display.setCursorPos(math.max(1, bx - 3), by - 1)
        display.setBackgroundColor(colors.lightBlue)
        display.setTextColor(colors[skin.col])
        display.write(" /---\ ")
        
        -- Line 2: Big Eye, Beak & Wing Flap
        display.setCursorPos(math.max(1, bx - 3), by)
        display.setTextColor(colors[skin.col])
        display.write("(")
        display.setTextColor(colors.white)
        display.write("@")
        display.setTextColor(colors[skin.beakCol])
        display.write(">")
        display.setTextColor(colors[skin.col])
        display.write(wingUp and " )^" or " )~")
        
        -- Line 3: Round Belly & Tail
        display.setCursorPos(math.max(1, bx - 3), by + 1)
        display.setTextColor(colors[skin.col])
        display.write(" \===/ ")
    end
    
    -- 7. HUD Score Banner (Top Center)
    if gameState == "PLAYING" or gameState == "READY" then
        local scoreStr = string.format("  SCORE: %d   HIGH: %d   COINS: %d  ", score, highScore, totalCoins)
        display.setCursorPos(math.max(1, math.floor((screenW - #scoreStr) / 2)), 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(scoreStr)
    end
    
    -- 8. Ready / Tutorial Overlay
    if gameState == "READY" then
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 3)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(" ============================ ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 2)
        display.write("     TAP / SPACE TO FLAP!     ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 1)
        display.write(" ============================ ")
        
        registerButton("BTN_FLAP", 1, 1, screenW, screenH, "", "white", "lightBlue")
    end
    
    -- 9. Game Over Score Board Overlay
    if gameState == "GAMEOVER" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        
        display.setCursorPos(midX - 16, midY - 5)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 4)
        display.write("           GAME OVER!             ")
        display.setCursorPos(midX - 16, midY - 3)
        display.write(" ================================ ")
        
        -- Score Card
        display.setCursorPos(midX - 16, midY - 2)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.format("  FINAL SCORE: %-4d   BEST: %-4d ", score, highScore))
        display.setCursorPos(midX - 16, midY - 1)
        display.write(string.format("  TOTAL COINS: +%-3d ($%d)        ", score, totalCoins))
        
        display.setCursorPos(midX - 16, midY)
        if medalAchieved then
            display.setTextColor(colors[medalAchieved.col] or colors.white)
            display.write(string.format("  MEDAL WON: [%s MEDAL]    ", medalAchieved.name))
        else
            display.setTextColor(colors.lightGray)
            display.write("  MEDAL: NONE (REACH 5 PTS)       ")
        end
        display.setCursorPos(midX - 16, midY + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 16, midY + 3, 15, 2, " [ REPLAY ] ", "yellow", "blue")
        registerButton("BTN_SKINS", midX + 1, midY + 3, 15, 2, " [ BIRDS ] ", "lime", "purple")
        registerButton("BTN_QUIT", screenW - 6, screenH - 1, 6, 2, "[ Q ]", "white", "red")
    end
    
    drawButtons()
end

-- ============================================================================
-- BIRD SKINS SHOP MENU
-- ============================================================================
local function renderShop()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local midX = math.floor(screenW / 2)
    display.setCursorPos(midX - 16, 2)
    display.setBackgroundColor(colors.purple)
    display.setTextColor(colors.yellow)
    display.write(" ================================ ")
    display.setCursorPos(midX - 16, 3)
    display.write("       FLAPPY BIRD NEST SHOP      ")
    display.setCursorPos(midX - 16, 4)
    display.write(" ================================ ")
    
    display.setCursorPos(4, 6)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(string.format("YOUR COINS: %d COINS", totalCoins))
    
    for idx, s in ipairs(BIRD_SKINS) do
        local sy = 8 + (idx - 1) * 3
        display.setCursorPos(4, sy)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors[s.col])
        display.write(string.format(" (o>) %s ", s.name))
        
        if s.unlocked then
            if currentSkinIdx == idx then
                registerButton("BTN_SKIN_" .. idx, screenW - 14, sy, 12, 2, " [EQUIPPED] ", "lime", "blue")
            else
                registerButton("BTN_SKIN_" .. idx, screenW - 14, sy, 12, 2, " [ SELECT ] ", "yellow", "blue")
            end
        else
            registerButton("BTN_BUY_" .. idx, screenW - 14, sy, 12, 2, string.format("[%d COINS]", s.price), (totalCoins >= s.price) and "yellow" or "lightGray", "purple")
        end
    end
    
    registerButton("BTN_BACK", midX - 10, screenH - 2, 20, 2, " [ < BACK TO NEST ] ", "yellow", "blue")
    
    drawButtons()
end

-- ============================================================================
-- TITLE SCREEN
-- ============================================================================
local function renderTitleScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.lightBlue)
    display.clear()
    
    local midX = math.floor(screenW / 2)
    local titleY = 4
    
    display.setCursorPos(midX - 16, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ================================ ")
    display.setCursorPos(midX - 16, titleY + 1)
    display.write("     FLAPPY BIRD DELUXE 2077      ")
    display.setCursorPos(midX - 16, titleY + 2)
    display.write(" ================================ ")
    
    -- Big Bird Mascot Preview (3-Line HD)
    local skin = BIRD_SKINS[currentSkinIdx]
    display.setCursorPos(midX - 4, titleY + 4)
    display.setBackgroundColor(colors.lightBlue)
    display.setTextColor(colors[skin.col])
    display.write("  /---\  ")
    display.setCursorPos(midX - 4, titleY + 5)
    display.write(" (")
    display.setTextColor(colors.white)
    display.write("@")
    display.setTextColor(colors[skin.beakCol])
    display.write(">")
    display.setTextColor(colors[skin.col])
    display.write(")^  ")
    display.setCursorPos(midX - 4, titleY + 6)
    display.write("  \===/  ")
    
    display.setCursorPos(midX - 16, titleY + 8)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.white)
    display.write("   TAP ANYWHERE / SPACE TO FLY    ")
    display.setCursorPos(midX - 16, titleY + 9)
    display.setTextColor(colors.yellow)
    display.write(string.format("   HIGH SCORE: %-3d | COINS: %-4d ", highScore, totalCoins))
    display.setCursorPos(midX - 16, titleY + 10)
    display.write(" ================================ ")
    
    registerButton("BTN_START", midX - 14, screenH - 5, 28, 2, " [ TAP / SPACE TO START ] ", "yellow", "blue")
    registerButton("BTN_SHOP", midX - 14, screenH - 2, 28, 2, " [ BIRD SKINS SHOP ] ", "lime", "purple")
    
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
        elseif gameState == "SHOP" then
            renderShop()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.08)
            if gameState == "READY" or gameState == "PLAYING" or gameState == "DYING" then
                updateGame()
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    initGame()
                elseif p1 == keys.s then
                    gameState = "SHOP"
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "SHOP" then
                if p1 == keys.q or p1 == keys.escape or p1 == keys.space then
                    gameState = "TITLE"
                end
            elseif gameState == "READY" or gameState == "PLAYING" then
                if p1 == keys.space or p1 == keys.up or p1 == keys.w or p1 == keys.enter then
                    flapBird()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "GAMEOVER" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    initGame()
                elseif p1 == keys.s then
                    gameState = "SHOP"
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "BTN_SHOP" then
                    gameState = "SHOP"
                else
                    initGame()
                end
            elseif gameState == "SHOP" then
                if cid == "BTN_BACK" then
                    gameState = "TITLE"
                elseif cid and string.sub(cid, 1, 9) == "BTN_SKIN_" then
                    local idx = tonumber(string.sub(cid, 10))
                    if idx and BIRD_SKINS[idx].unlocked then currentSkinIdx = idx end
                elseif cid and string.sub(cid, 1, 8) == "BTN_BUY_" then
                    local idx = tonumber(string.sub(cid, 9))
                    if idx and not BIRD_SKINS[idx].unlocked and totalCoins >= BIRD_SKINS[idx].price then
                        totalCoins = totalCoins - BIRD_SKINS[idx].price
                        BIRD_SKINS[idx].unlocked = true
                        currentSkinIdx = idx
                        playSound("point")
                    end
                end
            elseif gameState == "READY" or gameState == "PLAYING" then
                flapBird()
            elseif gameState == "GAMEOVER" then
                if cid == "BTN_RETRY" then
                    initGame()
                elseif cid == "BTN_SKINS" then
                    gameState = "SHOP"
                elseif cid == "BTN_QUIT" then
                    break
                else
                    initGame()
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Flappy Bird closed.")
    else
        print("Flappy Bird closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Flappy Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Flappy Error: " .. tostring(err))
end
