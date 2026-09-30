-- ============================================================================
-- CYBER DOODLE JUMP DELUXE 2077 - CC: TWEAKED EDITION
-- Vertical Camera Scroll, Springs, Jetpacks, Monsters, Blaster & Synth Audio
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
-- COLOR PALETTE CONFIGURATION
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF8C00, -- Spring / Jetpack Flames
    [colors.magenta]   = 0xE91E63, -- Monster Magenta
    [colors.lightBlue] = 0x4FC3F7, -- Moving Platform Blue
    [colors.yellow]    = 0xFFEB3B, -- Doodler / Coins / Lasers
    [colors.lime]      = 0x4CAF50, -- Standard Green Platform
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x263238, -- Grid Paper Lines
    [colors.lightGray] = 0x78909C, -- Clouds
    [colors.cyan]      = 0x00E5FF, -- Shield
    [colors.purple]    = 0x7B1FA2, -- Black Hole Vortex
    [colors.blue]      = 0x0288D1,
    [colors.brown]     = 0x6D4C41, -- Breaking Platform
    [colors.green]     = 0x2E7D32,
    [colors.red]       = 0xD50000, -- Hazard / Alert
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
        if snd == "jump" then
            speaker.playNote("snare", 0.5, 16)
        elseif snd == "spring" then
            speaker.playNote("chime", 0.8, 20)
            speaker.playNote("bell", 0.8, 24)
        elseif snd == "jetpack" then
            speaker.playNote("snare", 0.7, 24)
        elseif snd == "shoot" then
            speaker.playNote("chime", 0.6, 24)
        elseif snd == "monster_hit" then
            speaker.playNote("bass", 1.0, 16)
            speaker.playNote("chime", 0.8, 20)
        elseif snd == "break" then
            speaker.playNote("bass", 0.8, 8)
        elseif snd == "fall" then
            speaker.playNote("bass", 1.0, 4)
            speaker.playNote("snare", 1.0, 4)
        end
    end)
end

-- ============================================================================
-- GAME STATE & CONSTANTS
-- ============================================================================
local gameState = "TITLE" -- "TITLE", "PLAYING", "GAMEOVER"
local score = 0
local highScore = 8500
local maxHeight = 0

-- Doodler Physics
local doodler = {
    x = 25.0,
    y = 20.0,
    vx = 0.0,
    vy = 0.0,
    facing = 1, -- -1=Left, 1=Right
    isShooting = 0,
    jetpackTimer = 0,
    springTimer = 0,
    hasShield = false
}

local platforms = {}
local monsters = {}
local bullets = {}
local stars = {}

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
-- PLATFORM & MONSTER GENERATOR
-- ============================================================================
local function generateInitialPlatforms()
    local screenW, screenH = display.getSize()
    platforms = {}
    monsters = {}
    bullets = {}
    
    -- Ground platform under player
    table.insert(platforms, {
        x = math.floor(screenW / 2) - 4,
        y = screenH - 3,
        w = 8,
        type = "GREEN",
        vx = 0
    })
    
    -- Generate platforms upwards
    local curY = screenH - 7
    while curY > -50 do
        local pType = "GREEN"
        local r = math.random(1, 10)
        local item = nil
        
        if r <= 5 then pType = "GREEN"
        elseif r <= 7 then pType = "BLUE" -- Moving
        elseif r <= 9 then pType = "BROWN" -- Breaking
        else pType = "DISAPPEAR" end
        
        -- Item on platform (Spring or Jetpack)
        if pType == "GREEN" and math.random(1, 8) == 1 then
            item = "SPRING"
        elseif pType == "GREEN" and math.random(1, 20) == 1 then
            item = "JETPACK"
        end
        
        local pw = (pType == "BROWN") and 6 or 7
        local px = math.random(2, screenW - pw - 1)
        
        table.insert(platforms, {
            x = px,
            y = curY,
            w = pw,
            type = pType,
            vx = (pType == "BLUE") and ((math.random(1, 2) == 1) and 0.8 or -0.8) or 0,
            item = item,
            broken = false
        })
        
        -- Spawn Monster
        if math.random(1, 14) == 1 and curY < screenH - 12 then
            table.insert(monsters, {
                x = math.random(4, screenW - 8),
                y = curY - 3,
                w = 5,
                hp = 1,
                vx = (math.random(1, 2) == 1) and 0.5 or -0.5
            })
        end
        
        curY = curY - math.random(3, 5)
    end
end

local function initGame()
    local screenW, screenH = display.getSize()
    doodler.x = math.floor(screenW / 2)
    doodler.y = screenH - 5
    doodler.vx = 0.0
    doodler.vy = -1.6
    doodler.facing = 1
    doodler.isShooting = 0
    doodler.jetpackTimer = 0
    doodler.springTimer = 0
    doodler.hasShield = false
    
    score = 0
    maxHeight = 0
    generateInitialPlatforms()
    gameState = "PLAYING"
    playSound("jump")
end

-- ============================================================================
-- SHOOTING BLASTER
-- ============================================================================
local function shootBlaster()
    doodler.isShooting = 3
    table.insert(bullets, {
        x = doodler.x,
        y = doodler.y - 1,
        vy = -2.2
    })
    playSound("shoot")
end

-- ============================================================================
-- PHYSICS & UPDATE LOOP
-- ============================================================================
local function updateGame()
    local screenW, screenH = display.getSize()
    
    if gameState ~= "PLAYING" then return end
    
    -- 1. Jetpack / Spring Special Physics
    if doodler.jetpackTimer > 0 then
        doodler.jetpackTimer = doodler.jetpackTimer - 1
        doodler.vy = -2.8
        if doodler.jetpackTimer % 3 == 0 then playSound("jetpack") end
    elseif doodler.springTimer > 0 then
        doodler.springTimer = doodler.springTimer - 1
        doodler.vy = -2.2
    else
        -- Standard Gravity
        doodler.vy = doodler.vy + 0.14
    end
    
    doodler.x = doodler.x + doodler.vx
    doodler.y = doodler.y + doodler.vy
    
    -- Horizontal Drag
    doodler.vx = doodler.vx * 0.85
    
    -- Screen Wrap-Around
    if doodler.x < 1 then doodler.x = screenW
    elseif doodler.x > screenW then doodler.x = 1 end
    
    if doodler.isShooting > 0 then
        doodler.isShooting = doodler.isShooting - 1
    end
    
    -- 2. Vertical Camera Scrolling (When Doodler rises above mid-screen)
    local cameraThreshold = math.floor(screenH * 0.42)
    if doodler.y < cameraThreshold then
        local deltaY = cameraThreshold - doodler.y
        doodler.y = cameraThreshold
        score = score + math.floor(deltaY * 10)
        if score > highScore then highScore = score end
        
        -- Shift Platforms & Monsters down
        for _, p in ipairs(platforms) do
            p.y = p.y + deltaY
        end
        for _, m in ipairs(monsters) do
            m.y = m.y + deltaY
        end
        for _, b in ipairs(bullets) do
            b.y = b.y + deltaY
        end
    end
    
    -- 3. Update Platforms (Movement & Despawning)
    local highestPlatformY = screenH
    for i = #platforms, 1, -1 do
        local p = platforms[i]
        
        if p.y < highestPlatformY then highestPlatformY = p.y end
        
        -- Blue Moving Platforms
        if p.type == "BLUE" then
            p.x = p.x + p.vx
            if p.x <= 2 then
                p.x = 2
                p.vx = math.abs(p.vx)
            elseif p.x + p.w >= screenW - 1 then
                p.x = screenW - p.w - 1
                p.vx = -math.abs(p.vx)
            end
        end
        
        -- Platform Collision (Landing on top when falling downwards)
        if doodler.vy > 0 and doodler.jetpackTimer <= 0 then
            local footX = doodler.x
            local footY = doodler.y + 1.2
            
            if footX >= p.x - 1 and footX <= p.x + p.w and math.abs(footY - p.y) < 1.2 then
                if p.type == "BROWN" then
                    p.broken = true
                    playSound("break")
                elseif p.type == "DISAPPEAR" then
                    table.remove(platforms, i)
                    doodler.vy = -1.65
                    playSound("jump")
                else
                    -- Check for Springs & Jetpacks
                    if p.item == "SPRING" and math.abs(footX - (p.x + p.w / 2)) < 2 then
                        doodler.springTimer = 18
                        playSound("spring")
                    elseif p.item == "JETPACK" and math.abs(footX - (p.x + p.w / 2)) < 2 then
                        doodler.jetpackTimer = 45
                        p.item = nil
                        playSound("jetpack")
                    else
                        doodler.vy = -1.65
                        playSound("jump")
                    end
                end
            end
        end
        
        -- Remove platforms that scrolled off screen bottom
        if p.y > screenH + 2 or (p.type == "BROWN" and p.broken) then
            table.remove(platforms, i)
        end
    end
    
    -- Spawn new platforms at the top
    while highestPlatformY > -10 do
        local pType = "GREEN"
        local r = math.random(1, 10)
        local item = nil
        
        if r <= 5 then pType = "GREEN"
        elseif r <= 7 then pType = "BLUE"
        elseif r <= 9 then pType = "BROWN"
        else pType = "DISAPPEAR" end
        
        if pType == "GREEN" and math.random(1, 8) == 1 then item = "SPRING"
        elseif pType == "GREEN" and math.random(1, 20) == 1 then item = "JETPACK" end
        
        local pw = (pType == "BROWN") and 6 or 7
        local px = math.random(2, screenW - pw - 1)
        local py = highestPlatformY - math.random(3, 5)
        
        table.insert(platforms, {
            x = px,
            y = py,
            w = pw,
            type = pType,
            vx = (pType == "BLUE") and ((math.random(1, 2) == 1) and 0.8 or -0.8) or 0,
            item = item,
            broken = false
        })
        
        if math.random(1, 12) == 1 then
            table.insert(monsters, {
                x = math.random(4, screenW - 8),
                y = py - 3,
                w = 5,
                hp = 1,
                vx = (math.random(1, 2) == 1) and 0.5 or -0.5
            })
        end
        
        highestPlatformY = py
    end
    
    -- 4. Update Bullets & Monster Collisions
    for bIdx = #bullets, 1, -1 do
        local b = bullets[bIdx]
        b.y = b.y + b.vy
        
        for mIdx = #monsters, 1, -1 do
            local m = monsters[mIdx]
            if math.abs(b.x - m.x) < 3 and math.abs(b.y - m.y) < 2 then
                table.remove(monsters, mIdx)
                table.remove(bullets, bIdx)
                score = score + 200
                playSound("monster_hit")
                break
            end
        end
        
        if b.y < -5 then table.remove(bullets, bIdx) end
    end
    
    -- 5. Update Monsters Movement & Player Collisions
    for i = #monsters, 1, -1 do
        local m = monsters[i]
        m.x = m.x + m.vx
        if m.x < 3 or m.x > screenW - 6 then m.vx = -m.vx end
        
        -- Player Jump on Monster Head
        if doodler.vy > 0 and math.abs(doodler.x - m.x) < 3.5 and math.abs((doodler.y + 1) - m.y) < 1.5 then
            table.remove(monsters, i)
            doodler.vy = -1.8
            score = score + 300
            playSound("monster_hit")
        -- Monster Bites Player
        elseif math.abs(doodler.x - m.x) < 2.5 and math.abs(doodler.y - m.y) < 1.5 then
            if doodler.jetpackTimer <= 0 then
                gameState = "GAMEOVER"
                playSound("fall")
                return
            end
        end
        
        if m.y > screenH + 4 then table.remove(monsters, i) end
    end
    
    -- 6. Fall Death
    if doodler.y > screenH + 2 then
        gameState = "GAMEOVER"
        playSound("fall")
    end
end

-- ============================================================================
-- FULL-SCREEN NOTEBOOK RENDER PIPELINE
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    -- 1. Graph Paper Notebook Background
    display.setBackgroundColor(colors.black)
    display.clear()
    
    for y = 2, screenH do
        display.setCursorPos(1, y)
        if y % 3 == 0 then
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.gray)
            display.write(string.rep("-", screenW))
        end
    end
    
    -- 2. Render Platforms
    for _, p in ipairs(platforms) do
        local px = math.floor(p.x)
        local py = math.floor(p.y)
        
        if py >= 2 and py <= screenH then
            display.setCursorPos(math.max(1, px), py)
            
            if p.type == "GREEN" then
                display.setBackgroundColor(colors.green)
                display.setTextColor(colors.lime)
                display.write("[" .. string.rep("=", p.w - 2) .. "]")
                
                -- Springs / Jetpack items on platform
                if p.item == "SPRING" then
                    display.setCursorPos(math.floor(px + p.w / 2), py - 1)
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.orange)
                    display.write("§")
                elseif p.item == "JETPACK" then
                    display.setCursorPos(math.floor(px + p.w / 2) - 1, py - 1)
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.cyan)
                    display.write("[J]")
                end
                
            elseif p.type == "BLUE" then
                display.setBackgroundColor(colors.blue)
                display.setTextColor(colors.lightBlue)
                display.write("<" .. string.rep("=", p.w - 2) .. ">")
                
            elseif p.type == "BROWN" then
                display.setBackgroundColor(colors.brown)
                display.setTextColor(colors.yellow)
                display.write("[x--x]")
                
            elseif p.type == "DISAPPEAR" then
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.yellow)
                display.write("(?==?)")
            end
        end
    end
    
    -- 3. Render Monsters
    for _, m in ipairs(monsters) do
        local mx = math.floor(m.x)
        local my = math.floor(m.y)
        
        if my >= 2 and my <= screenH then
            display.setCursorPos(math.max(1, mx - 1), my)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.magenta)
            display.write("(o_O)")
            
            display.setCursorPos(math.max(1, mx - 1), my + 1)
            display.setTextColor(colors.red)
            display.write("WWWWW")
        end
    end
    
    -- 4. Render Bullets
    for _, b in ipairs(bullets) do
        local bx = math.floor(b.x)
        local by = math.floor(b.y)
        if by >= 2 and by <= screenH and bx >= 1 and bx <= screenW then
            display.setCursorPos(bx, by)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.yellow)
            display.write("^")
        end
    end
    
    -- 5. Render Doodler Sprite (2-Line Detailed)
    local dx = math.floor(doodler.x)
    local dy = math.floor(doodler.y)
    
    if dy >= 1 and dy <= screenH then
        display.setBackgroundColor(colors.black)
        
        if doodler.jetpackTimer > 0 then
            -- Flying Jetpack Doodler
            display.setCursorPos(math.max(1, dx - 2), dy)
            display.setTextColor(colors.cyan)
            display.write("[J]")
            display.setTextColor(colors.yellow)
            display.write("(^^)")
            
            display.setCursorPos(math.max(1, dx - 2), dy + 1)
            display.setTextColor(colors.orange)
            display.write(" ^^ ^^ ")
            
        elseif doodler.isShooting > 0 then
            -- Shooting Upwards
            display.setCursorPos(math.max(1, dx - 2), dy)
            display.setTextColor(colors.yellow)
            display.write(" (^^) ")
            display.setCursorPos(math.max(1, dx - 2), dy + 1)
            display.write(" (||) ")
            
        else
            -- Walking / Jumping Doodler
            if doodler.facing == -1 then
                display.setCursorPos(math.max(1, dx - 2), dy)
                display.setTextColor(colors.yellow)
                display.write("(o..) ")
                display.setCursorPos(math.max(1, dx - 2), dy + 1)
                display.write("(=//) ")
            else
                display.setCursorPos(math.max(1, dx - 2), dy)
                display.setTextColor(colors.yellow)
                display.write(" (..o)")
                display.setCursorPos(math.max(1, dx - 2), dy + 1)
                display.write(" (\\=)")
            end
        end
    end
    
    -- 6. HUD Score Bar (Top Header)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" SCORE: %06d   HIGH: %06d   HEIGHT: %dm ", score, highScore, math.floor(score / 10))
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 7. Touch Controls (Bottom Bar)
    local ctrlY = screenH - 1
    registerButton("BTN_LEFT", 2, ctrlY, 11, 2, " [ < LEFT ] ", "yellow", "blue")
    registerButton("BTN_SHOOT", math.floor(screenW / 2) - 8, ctrlY, 16, 2, " [ SHOOT (W) ] ", "cyan", "purple")
    registerButton("BTN_RIGHT", screenW - 13, ctrlY, 12, 2, " [ RIGHT > ] ", "yellow", "blue")
    
    -- Game Over Overlay
    if gameState == "GAMEOVER" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        
        display.setCursorPos(midX - 16, midY - 4)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 3)
        display.write("           GAME OVER!             ")
        display.setCursorPos(midX - 16, midY - 2)
        display.write(" ================================ ")
        
        display.setCursorPos(midX - 16, midY - 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.format("  FINAL SCORE: %06d            ", score))
        display.setCursorPos(midX - 16, midY)
        display.write(string.format("  BEST RECORD: %06d            ", highScore))
        display.setCursorPos(midX - 16, midY + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 16, midY + 3, 32, 2, " [ JUMP AGAIN (TAP) ] ", "yellow", "blue")
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
    display.write("     CYBER DOODLE JUMP 2077 PRO       ")
    display.setCursorPos(midX - 18, titleY + 2)
    display.write(" ==================================== ")
    
    -- Doodler Preview
    display.setCursorPos(midX - 3, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(" (..o)")
    display.setCursorPos(midX - 3, titleY + 5)
    display.write(" (\\=)")
    
    display.setCursorPos(midX - 18, titleY + 7)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.white)
    display.write("  CONTROLS: [A/D] Move | [W] Shoot    ")
    display.setCursorPos(midX - 18, titleY + 8)
    display.setTextColor(colors.yellow)
    display.write(string.format("  HIGH SCORE: %06d               ", highScore))
    display.setCursorPos(midX - 18, titleY + 9)
    display.write(" ==================================== ")
    
    registerButton("BTN_START", midX - 16, screenH - 4, 32, 2, " [ TAP / SPACE TO START ] ", "yellow", "blue")
    
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
            if gameState == "PLAYING" then
                updateGame()
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    initGame()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            else
                if p1 == keys.left or p1 == keys.a then
                    doodler.vx = -1.6
                    doodler.facing = -1
                elseif p1 == keys.right or p1 == keys.d then
                    doodler.vx = 1.6
                    doodler.facing = 1
                elseif p1 == keys.up or p1 == keys.w or p1 == keys.space then
                    shootBlaster()
                elseif p1 == keys.r then
                    initGame()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                initGame()
            else
                if cid == "BTN_RETRY" then
                    initGame()
                elseif cid == "BTN_LEFT" then
                    doodler.vx = -1.8
                    doodler.facing = -1
                elseif cid == "BTN_RIGHT" then
                    doodler.vx = 1.8
                    doodler.facing = 1
                elseif cid == "BTN_SHOOT" then
                    shootBlaster()
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Screen Half Touch Steering
                    local screenW, screenH = display.getSize()
                    local midX = math.floor(screenW / 2)
                    
                    if my < 6 then
                        shootBlaster()
                    elseif mx < midX then
                        doodler.vx = -1.8
                        doodler.facing = -1
                    else
                        doodler.vx = 1.8
                        doodler.facing = 1
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
        display.write("Doodle Jump closed.")
    else
        print("Doodle Jump closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Doodle Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Doodle Error: " .. tostring(err))
end
