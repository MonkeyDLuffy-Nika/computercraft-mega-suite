-- ============================================================================
-- CYBER PAC-MAN ULTIMATE ARCADE 2077 - CC: TWEAKED EDITION
-- Perfect 27x16 Alignment, Wall-Integrated D-Pad, 3s Release & Sound FX
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
-- HIGH-CONTRAST RETRO ARCADE PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF8C14, -- Clyde
    [colors.magenta]   = 0xEB4BBE, -- Pinky
    [colors.lightBlue] = 0x1ED2DC, -- Inky
    [colors.yellow]    = 0xFFE600, -- Pac-Man / Dots
    [colors.lime]      = 0x5AEB28,
    [colors.pink]      = 0xFFB4C8, -- Ghost Door
    [colors.gray]      = 0x141824, -- Deep Grid Floor
    [colors.lightGray] = 0x506080, -- Metallic Wall Core
    [colors.cyan]      = 0x00D2FF, -- Wall Neon Edge
    [colors.purple]    = 0x8C32E6,
    [colors.blue]      = 0x122464, -- Dark Navy
    [colors.brown]     = 0x8C4B23,
    [colors.green]     = 0x24A530,
    [colors.red]       = 0xEB2828, -- Blinky / Alert
    [colors.black]     = 0x05070C
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- Sound Effects
local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "start" then
            local notes = { 12, 16, 19, 24, 21, 24, 21, 19 }
            for _, n in ipairs(notes) do
                speaker.playNote("chime", 0.9, n)
                sleep(0.04)
            end
        elseif snd == "waka" then
            speaker.playNote("snare", 0.3, 16)
        elseif snd == "power" then
            speaker.playNote("chime", 0.8, 20)
            speaker.playNote("bell", 0.8, 24)
        elseif snd == "eat_ghost" then
            speaker.playNote("bass", 1.0, 18)
            speaker.playNote("chime", 1.0, 24)
        elseif snd == "fruit" then
            speaker.playNote("bell", 1.0, 22)
            speaker.playNote("chime", 1.0, 24)
        elseif snd == "death" then
            speaker.playNote("bass", 1.0, 12)
            speaker.playNote("snare", 1.0, 8)
        elseif snd == "win" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.9, p)
                sleep(0.03)
            end
        end
    end)
end

-- ============================================================================
-- FULL-SCREEN 27x16 PERFECTLY ALIGNED LABYRINTH
-- Ghost Chamber at rows 7..9, cols 12..16 with Wall-Integrated D-Pad
-- ============================================================================
local MAZE_TEMPLATE = {
    "###########################",
    "#O.......##.....##.......O#",
    "#.######.##.###.##.######.#",
    "#.........................#",
    "#.######.##.###.##.######.#",
    "#........##     ##........#",
    "######.##  # - #  ##.######",
    "      .##  # 123# ##.      ",
    "######.##  #####  ##.######",
    "#........##  F  ##........#",
    "#.######.##.###.##.######.#",
    "#....###...........###....#",
    "####.###.##.###.##.###.####",
    "#........##..#..##........#",
    "#O.#####.###.#.###.#####.O#",
    "###########################"
}

local gameState = "TITLE" -- "TITLE", "PLAYING", "DYING", "GAMEOVER", "WIN"
local maze = {}
local totalDots = 0
local dotsRemaining = 0
local score = 0
local highScore = 10000
local lives = 3
local gameLevel = 1
local isPaused = false

-- Death state & Alert
local deathTimer = 0
local deathMsg = ""
local popupScore = nil
local fruitActive = false
local fruitTimer = 0
local fruitType = { name = "Cherry", pts = 100, sym = "[%]", col = "red" }

-- Pac-Man State
local pacman = {
    x = 14, y = 14,
    dirX = -1, dirY = 0,
    nextDirX = -1, nextDirY = 0,
    mouthAnim = 0
}

-- 4 Ghosts with Central Ghost House Spawns & 3s Sequential Release
local ghosts = {
    { name = "Blinky", col = "red", tag = "SHADOW", x = 14, y = 6, dirX = -1, dirY = 0, homeX = 14, homeY = 6, scatterX = 26, scatterY = 2, state = "CHASE", releaseDelay = 0 },
    { name = "Pinky", col = "magenta", tag = "SPEEDY", x = 13, y = 8, dirX = 0, dirY = -1, homeX = 13, homeY = 8, scatterX = 2, scatterY = 2, state = "HOUSE", releaseDelay = 15 },
    { name = "Inky", col = "lightBlue", tag = "BASHFUL", x = 14, y = 8, dirX = 0, dirY = -1, homeX = 14, homeY = 8, scatterX = 26, scatterY = 15, state = "HOUSE", releaseDelay = 30 },
    { name = "Clyde", col = "orange", tag = "POKEY", x = 15, y = 8, dirX = 0, dirY = -1, homeX = 15, homeY = 8, scatterX = 2, scatterY = 15, state = "HOUSE", releaseDelay = 45 }
}

local frightenedTimer = 0
local ghostCombo = 200
local ghostStepTick = 0

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
local function initLevel()
    maze = {}
    totalDots = 0
    
    for r, rowStr in ipairs(MAZE_TEMPLATE) do
        maze[r] = {}
        for c = 1, #rowStr do
            local ch = string.sub(rowStr, c, c)
            if ch == "1" or ch == "2" or ch == "3" then ch = " " end
            maze[r][c] = ch
            if ch == "." or ch == "O" then
                totalDots = totalDots + 1
            end
        end
    end
    
    dotsRemaining = totalDots
    pacman.x = 14
    pacman.y = 14
    pacman.dirX = -1
    pacman.dirY = 0
    pacman.nextDirX = -1
    pacman.nextDirY = 0
    
    ghosts[1].x = 14; ghosts[1].y = 6; ghosts[1].state = "CHASE"; ghosts[1].dirX = -1; ghosts[1].dirY = 0; ghosts[1].releaseDelay = 0
    ghosts[2].x = 13; ghosts[2].y = 8; ghosts[2].state = "HOUSE"; ghosts[2].dirX = 0; ghosts[2].dirY = -1; ghosts[2].releaseDelay = 15
    ghosts[3].x = 14; ghosts[3].y = 8; ghosts[3].state = "HOUSE"; ghosts[3].dirX = 0; ghosts[3].dirY = -1; ghosts[3].releaseDelay = 30
    ghosts[4].x = 15; ghosts[4].y = 8; ghosts[4].state = "HOUSE"; ghosts[4].dirX = 0; ghosts[4].dirY = -1; ghosts[4].releaseDelay = 45
    
    frightenedTimer = 0
    ghostCombo = 200
    deathTimer = 0
    fruitActive = false
    fruitTimer = 0
end

local function resetPositions()
    pacman.x = 14
    pacman.y = 14
    pacman.dirX = -1
    pacman.dirY = 0
    pacman.nextDirX = -1
    pacman.nextDirY = 0
    
    ghosts[1].x = 14; ghosts[1].y = 6; ghosts[1].state = "CHASE"; ghosts[1].dirX = -1; ghosts[1].dirY = 0; ghosts[1].releaseDelay = 0
    ghosts[2].x = 13; ghosts[2].y = 8; ghosts[2].state = "HOUSE"; ghosts[2].dirX = 0; ghosts[2].dirY = -1; ghosts[2].releaseDelay = 15
    ghosts[3].x = 14; ghosts[3].y = 8; ghosts[3].state = "HOUSE"; ghosts[3].dirX = 0; ghosts[3].dirY = -1; ghosts[3].releaseDelay = 30
    ghosts[4].x = 15; ghosts[4].y = 8; ghosts[4].state = "HOUSE"; ghosts[4].dirX = 0; ghosts[4].dirY = -1; ghosts[4].releaseDelay = 45
    
    frightenedTimer = 0
    deathTimer = 0
end

-- ============================================================================
-- PHYSICS & AI ENGINE
-- ============================================================================
local function isPassable(r, c, isGhost)
    if r < 1 or r > #maze then return false end
    if c < 1 or c > 27 then return true end -- Wrap tunnel
    
    local tile = maze[r][c]
    if tile == "#" then return false end
    if tile == "-" and not isGhost then return false end -- Ghost Door
    return true
end

local function updatePacman()
    if deathTimer > 0 then return end
    
    -- Buffered direction
    if pacman.nextDirX ~= 0 or pacman.nextDirY ~= 0 then
        local targetR = pacman.y + pacman.nextDirY
        local targetC = pacman.x + pacman.nextDirX
        if isPassable(targetR, targetC, false) then
            pacman.dirX = pacman.nextDirX
            pacman.dirY = pacman.nextDirY
        end
    end
    
    local nextR = pacman.y + pacman.dirY
    local nextC = pacman.x + pacman.dirX
    
    if isPassable(nextR, nextC, false) then
        pacman.x = nextC
        pacman.y = nextR
        
        -- Wrap Tunnel
        if pacman.x < 1 then pacman.x = 27
        elseif pacman.x > 27 then pacman.x = 1 end
        
        pacman.mouthAnim = (pacman.mouthAnim + 1) % 4
        
        local curTile = maze[pacman.y][pacman.x]
        if curTile == "." then
            maze[pacman.y][pacman.x] = " "
            score = score + 10
            dotsRemaining = dotsRemaining - 1
            playSound("waka")
        elseif curTile == "O" then
            maze[pacman.y][pacman.x] = " "
            score = score + 50
            dotsRemaining = dotsRemaining - 1
            frightenedTimer = 45
            ghostCombo = 200
            for _, g in ipairs(ghosts) do
                if g.state ~= "EATEN" and g.state ~= "HOUSE" then g.state = "FRIGHTENED" end
            end
            playSound("power")
        end
        
        -- Fruit Spawning
        if dotsRemaining == math.floor(totalDots * 0.5) and not fruitActive then
            fruitActive = true
            fruitTimer = 50
        end
        if fruitActive and pacman.y == 10 and pacman.x == 14 then
            fruitActive = false
            score = score + fruitType.pts
            popupScore = { text = "+" .. fruitType.pts, x = 14, y = 10, timer = 10 }
            playSound("fruit")
        end
        
        if score > highScore then highScore = score end
        
        if dotsRemaining <= 0 then
            gameState = "WIN"
            playSound("win")
        end
    end
end

local function updateGhosts()
    if deathTimer > 0 then return end
    
    ghostStepTick = (ghostStepTick + 1) % 4
    
    if frightenedTimer > 0 then
        frightenedTimer = frightenedTimer - 1
        if frightenedTimer == 0 then
            for _, g in ipairs(ghosts) do
                if g.state == "FRIGHTENED" then g.state = "CHASE" end
            end
        end
    end
    
    if fruitActive then
        fruitTimer = fruitTimer - 1
        if fruitTimer <= 0 then fruitActive = false end
    end
    
    if popupScore then
        popupScore.timer = popupScore.timer - 1
        if popupScore.timer <= 0 then popupScore = nil end
    end
    
    local allDirs = { {1,0}, {-1,0}, {0,1}, {0,-1} }
    
    for _, g in ipairs(ghosts) do
        -- Sequential 3-second release countdown
        if g.releaseDelay > 0 then
            g.releaseDelay = g.releaseDelay - 1
            if g.releaseDelay <= 0 then
                g.state = "EXITING"
            end
        end
        
        -- Exit House Routine (Align to center x=14 then float up through door)
        if g.state == "EXITING" then
            if g.x < 14 then
                g.x = g.x + 1
            elseif g.x > 14 then
                g.x = g.x - 1
            else
                g.y = g.y - 1
                if g.y <= 6 then
                    g.y = 6
                    g.state = (frightenedTimer > 0) and "FRIGHTENED" or "CHASE"
                    g.dirX = (math.random(1, 2) == 1) and 1 or -1
                    g.dirY = 0
                end
            end
        elseif g.state == "EATEN" then
            if math.abs(g.x - 14) <= 1 and (g.y == 6 or g.y == 8) then
                g.state = (frightenedTimer > 0) and "FRIGHTENED" or "CHASE"
            end
        end
        
        if g.state ~= "HOUSE" and g.state ~= "EXITING" then
            local canMoveThisTick = true
            if g.state == "FRIGHTENED" then
                canMoveThisTick = (ghostStepTick % 2 == 0) -- 50% speed
            elseif g.state == "CHASE" then
                canMoveThisTick = (ghostStepTick ~= 3)     -- 75% speed
            end
            
            -- Target selection
            local targetX, targetY = pacman.x, pacman.y
            if g.state == "FRIGHTENED" then
                targetX = math.random(1, 27)
                targetY = math.random(1, 16)
            elseif g.state == "EATEN" then
                targetX, targetY = 14, 8
            elseif g.name == "Pinky" then
                targetX = pacman.x + pacman.dirX * 3
                targetY = pacman.y + pacman.dirY * 3
            elseif g.name == "Inky" then
                targetX = g.scatterX
                targetY = g.scatterY
            elseif g.name == "Clyde" then
                local dist = math.abs(g.x - pacman.x) + math.abs(g.y - pacman.y)
                if dist > 6 then targetX, targetY = pacman.x, pacman.y else targetX, targetY = g.scatterX, g.scatterY end
            end
            
            local validMoves = {}
            local reverseMove = nil
            
            for _, d in ipairs(allDirs) do
                local candR = g.y + d[2]
                local candC = g.x + d[1]
                if isPassable(candR, candC, true) then
                    if (d[1] == -g.dirX and d[2] == -g.dirY) then
                        reverseMove = d
                    else
                        table.insert(validMoves, d)
                    end
                end
            end
            
            local bestD = nil
            if #validMoves > 0 then
                local bestDist = 999999
                for _, d in ipairs(validMoves) do
                    local candR = g.y + d[2]
                    local candC = g.x + d[1]
                    local dist = (candC - targetX)^2 + (candR - targetY)^2
                    if dist < bestDist then
                        bestDist = dist
                        bestD = d
                    end
                end
            elseif reverseMove then
                bestD = reverseMove
            end
            
            if bestD and canMoveThisTick then
                g.dirX = bestD[1]
                g.dirY = bestD[2]
                g.x = g.x + g.dirX
                g.y = g.y + g.dirY
                
                if g.x < 1 then g.x = 27
                elseif g.x > 27 then g.x = 1 end
            end
            
            -- Collision with Pac-Man
            if g.x == pacman.x and g.y == pacman.y and gameState == "PLAYING" then
                if g.state == "FRIGHTENED" then
                    g.state = "EATEN"
                    score = score + ghostCombo
                    popupScore = { text = "+" .. ghostCombo, x = g.x, y = g.y, timer = 10 }
                    ghostCombo = ghostCombo * 2
                    playSound("eat_ghost")
                elseif g.state == "CHASE" then
                    lives = lives - 1
                    playSound("death")
                    if lives <= 0 then
                        gameState = "GAMEOVER"
                    else
                        gameState = "DYING"
                        deathTimer = 10
                        deathMsg = string.format("PAC-MAN CAUGHT BY %s! (%d LIVES LEFT)", string.upper(g.name), lives)
                    end
                    break
                end
            end
        end
    end
end

-- ============================================================================
-- 2-LINE SPRITE ENGINE
-- ============================================================================
local function getPacmanSprite(dy)
    if gameState == "DYING" then
        return (dy == 0) and " XX " or " -- "
    end
    
    if dy == 0 then
        if pacman.dirX == 1 then
            return (pacman.mouthAnim < 2) and "(O " or "(= "
        elseif pacman.dirX == -1 then
            return (pacman.mouthAnim < 2) and " O)" or " =)"
        elseif pacman.dirY == -1 then
            return " /\\ "
        else
            return "(  )"
        end
    else
        if pacman.dirX == 1 then
            return (pacman.mouthAnim < 2) and "(O " or "(= "
        elseif pacman.dirX == -1 then
            return (pacman.mouthAnim < 2) and " O)" or " =)"
        elseif pacman.dirY == 1 then
            return " \\/ "
        else
            return "(==)"
        end
    end
end

local function getGhostSprite(ghost, dy)
    if ghost.state == "EATEN" then
        return (dy == 0) and " oo " or "    "
    elseif ghost.state == "FRIGHTENED" then
        return (dy == 0) and "(~~)" or "\\WW/"
    elseif ghost.state == "HOUSE" then
        return (dy == 0) and "(..)" or " -- "
    else
        local eyeLook = "(oo)"
        if ghost.dirX == -1 then eyeLook = "(o. )"
        elseif ghost.dirX == 1 then eyeLook = "( .o)"
        elseif ghost.dirY == -1 then eyeLook = "(^^)"
        elseif ghost.dirY == 1 then eyeLook = "(..)"
        end
        return (dy == 0) and eyeLook or "/VV\\"
    end
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
    display.setCursorPos(math.floor(screenW / 2) - 16, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ================================= ")
    display.setCursorPos(math.floor(screenW / 2) - 16, titleY + 1)
    display.write("   CYBER PAC-MAN 2077 ARCADE PRO   ")
    display.setCursorPos(math.floor(screenW / 2) - 16, titleY + 2)
    display.write(" ================================= ")
    
    local paradeY = titleY + 5
    display.setCursorPos(math.floor(screenW / 2) - 18, paradeY)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write("  CHARACTER / NICKNAME    POINTS  ")
    
    for idx, g in ipairs(ghosts) do
        local gy = paradeY + 2 + (idx - 1) * 2
        display.setCursorPos(math.floor(screenW / 2) - 18, gy)
        display.setTextColor(colors[g.col])
        display.write(string.format("  (oo)  %-8s [%s]", g.name, g.tag))
        display.setCursorPos(math.floor(screenW / 2) + 12, gy)
        display.setTextColor(colors.yellow)
        display.write(string.format("%d PTS", idx * 200))
    end
    
    local ptsY = paradeY + 11
    display.setCursorPos(math.floor(screenW / 2) - 18, ptsY)
    display.setTextColor(colors.yellow)
    display.write("   .  Dot: 10 PTS     [O] Power: 50 PTS  ")
    display.setCursorPos(math.floor(screenW / 2) - 18, ptsY + 1)
    display.setTextColor(colors.red)
    display.write("  [%] Bonus Fruit: 100 - 1000 PTS       ")
    
    local btnY = screenH - 4
    registerButton("BTN_START", math.floor(screenW / 2) - 15, btnY, 30, 2, " [ TAP / SPACE TO START ] ", "yellow", "blue")
    
    drawButtons()
end

-- ============================================================================
-- GAMEPLAY RENDER PIPELINE
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top HUD
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" 1UP %06d   HIGH %06d   LIVES: %s   LVL %d ", score, highScore, string.rep("(C) ", math.max(0, lives)), gameLevel)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Full-Screen 27x16 Labyrinth (3 cols x 2 lines per cell)
    local cellW = 3
    local cellH = 2
    local totalMazeW = 27 * cellW
    local mazeStartX = math.max(2, math.floor((screenW - totalMazeW) / 2))
    local mazeStartY = 3
    
    for r = 1, #maze do
        for c = 1, 27 do
            local bx = mazeStartX + (c - 1) * cellW
            local by = mazeStartY + (r - 1) * cellH
            local tile = maze[r][c]
            
            local ghostHere = nil
            for _, g in ipairs(ghosts) do
                if g.y == r and g.x == c then ghostHere = g; break end
            end
            local isPacman = (pacman.y == r and pacman.x == c)
            local isFruit = (fruitActive and r == 10 and c == 14)
            
            -- Wall-Integrated D-Pad Button Positions (Shifted Left & Centered on House)
            local isUpBtn = (r == 7 and (c == 13 or c == 15))
            local isLeftBtn = (r == 8 and c == 12)
            local isRightBtn = (r == 8 and c == 16)
            local isDownBtn = (r == 9 and c == 14)
            
            if isUpBtn then
                registerButton("BTN_UP", bx, by, cellW, cellH, "", "yellow", "blue")
            elseif isLeftBtn then
                registerButton("BTN_LEFT", bx, by, cellW, cellH, "", "yellow", "blue")
            elseif isRightBtn then
                registerButton("BTN_RIGHT", bx, by, cellW, cellH, "", "yellow", "blue")
            elseif isDownBtn then
                registerButton("BTN_DOWN", bx, by, cellW, cellH, "", "yellow", "blue")
            end
            
            for dy = 0, cellH - 1 do
                display.setCursorPos(bx, by + dy)
                
                if isPacman then
                    display.setBackgroundColor(colors.gray)
                    display.setTextColor(colors.yellow)
                    display.write(getPacmanSprite(dy))
                    
                elseif ghostHere then
                    display.setBackgroundColor(colors.gray)
                    if ghostHere.state == "FRIGHTENED" then
                        local isFlash = (frightenedTimer < 12 and frightenedTimer % 4 < 2)
                        display.setTextColor(isFlash and colors.white or colors.cyan)
                    elseif ghostHere.state == "EATEN" then
                        display.setTextColor(colors.white)
                    else
                        display.setTextColor(colors[ghostHere.col] or colors.red)
                    end
                    display.write(getGhostSprite(ghostHere, dy))
                    
                elseif isFruit then
                    display.setBackgroundColor(colors.gray)
                    display.setTextColor(colors[fruitType.col] or colors.red)
                    display.write((dy == 0) and fruitType.sym or " . ")
                    
                -- Wall-Integrated D-Pad Buttons
                elseif isUpBtn then
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.yellow)
                    display.write((dy == 0) and " ^ " or "[W]")
                elseif isLeftBtn then
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.yellow)
                    display.write((dy == 0) and "<--" or "[A]")
                elseif isRightBtn then
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.yellow)
                    display.write((dy == 0) and "-->" or "[D]")
                elseif isDownBtn then
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.yellow)
                    display.write((dy == 0) and " v " or "[S]")
                    
                elseif tile == "-" then
                    -- Pink Ghost House Door
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.pink)
                    display.write((dy == 0) and "---" or "   ")
                    
                elseif tile == "#" then
                    local isOuter = (r == 1 or r == #maze or c == 1 or c == 27)
                    display.setBackgroundColor(isOuter and colors.blue or colors.gray)
                    display.setTextColor(isOuter and colors.cyan or colors.lightGray)
                    display.write((dy == 0) and "[=]" or "[=]")
                    
                elseif tile == "." then
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.yellow)
                    display.write((dy == 0) and " . " or "   ")
                    
                elseif tile == "O" then
                    display.setBackgroundColor(colors.black)
                    display.setTextColor((frightenedTimer % 4 < 2) and colors.yellow or colors.white)
                    display.write((dy == 0) and "[O]" or "   ")
                    
                else
                    display.setBackgroundColor(colors.black)
                    display.write("   ")
                end
            end
        end
    end
    
    -- Score Popups
    if popupScore then
        local px = mazeStartX + (popupScore.x - 1) * cellW
        local py = mazeStartY + (popupScore.y - 1) * cellH
        display.setCursorPos(px, py)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(popupScore.text)
    end
    
    -- Death Alert Card
    if gameState == "DYING" then
        display.setCursorPos(math.floor(screenW / 2) - 18, math.floor(screenH / 2) - 4)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================== ")
        display.setCursorPos(math.floor(screenW / 2) - 18, math.floor(screenH / 2) - 3)
        display.write(string.format("  %-32s", deathMsg))
        display.setCursorPos(math.floor(screenW / 2) - 18, math.floor(screenH / 2) - 2)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write("       RESPAWNING IN 1 SEC...       ")
    end
    
    -- Small corner Exit button
    registerButton("BTN_QUIT", screenW - 6, screenH, 6, 1, "[ Q ]", "white", "red")
    
    -- Game Over / Stage Cleared Overlays with Clickable Buttons
    if gameState == "GAMEOVER" then
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ============================ ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 2)
        display.write("        GAME OVER!            ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 1)
        display.write(string.format("     FINAL SCORE: %06d     ", score))
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2))
        display.write(" ============================ ")
        
        registerButton("BTN_RETRY", math.floor(screenW / 2) - 14, math.floor(screenH / 2) + 2, 28, 2, " [ RESTART GAME (TAP) ] ", "yellow", "blue")
    elseif gameState == "WIN" then
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 3)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ============================ ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 2)
        display.write("    *** STAGE CLEARED! ***    ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 1)
        display.write(string.format("     TOTAL SCORE: %06d     ", score))
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2))
        display.write(" ============================ ")
        
        registerButton("BTN_NEXT_LVL", math.floor(screenW / 2) - 14, math.floor(screenH / 2) + 2, 28, 2, " [ NEXT LEVEL > (TAP) ] ", "yellow", "green")
    end
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    initLevel()
    local timerId = os.startTimer(0.20)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.20)
            
            if gameState == "DYING" then
                deathTimer = deathTimer - 1
                if deathTimer <= 0 then
                    resetPositions()
                    gameState = "PLAYING"
                end
            elseif gameState == "PLAYING" and not isPaused then
                updatePacman()
                updateGhosts()
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    gameState = "PLAYING"
                    playSound("start")
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            else
                if p1 == keys.left or p1 == keys.a then
                    pacman.nextDirX = -1; pacman.nextDirY = 0
                elseif p1 == keys.right or p1 == keys.d then
                    pacman.nextDirX = 1; pacman.nextDirY = 0
                elseif p1 == keys.up or p1 == keys.w then
                    pacman.nextDirX = 0; pacman.nextDirY = -1
                elseif p1 == keys.down or p1 == keys.s then
                    pacman.nextDirX = 0; pacman.nextDirY = 1
                elseif p1 == keys.r then
                    if gameState == "WIN" then
                        gameLevel = gameLevel + 1
                        gameState = "PLAYING"
                        initLevel()
                    else
                        score = 0
                        lives = 3
                        gameLevel = 1
                        gameState = "PLAYING"
                        initLevel()
                    end
                elseif p1 == keys.p then
                    isPaused = not isPaused
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                gameState = "PLAYING"
                playSound("start")
            elseif cid == "BTN_RETRY" then
                score = 0
                lives = 3
                gameLevel = 1
                gameState = "PLAYING"
                initLevel()
            elseif cid == "BTN_NEXT_LVL" then
                gameLevel = gameLevel + 1
                gameState = "PLAYING"
                initLevel()
            elseif cid == "BTN_UP" then
                pacman.nextDirX = 0; pacman.nextDirY = -1
            elseif cid == "BTN_DOWN" then
                pacman.nextDirX = 0; pacman.nextDirY = 1
            elseif cid == "BTN_LEFT" then
                pacman.nextDirX = -1; pacman.nextDirY = 0
            elseif cid == "BTN_RIGHT" then
                pacman.nextDirX = 1; pacman.nextDirY = 0
            elseif cid == "BTN_QUIT" then
                break
            else
                local screenW, screenH = display.getSize()
                local midX = math.floor(screenW / 2)
                local midY = math.floor(screenH / 2)
                
                if math.abs(mx - midX) > math.abs(my - midY) then
                    if mx < midX then pacman.nextDirX = -1; pacman.nextDirY = 0
                    else pacman.nextDirX = 1; pacman.nextDirY = 0 end
                else
                    if my < midY then pacman.nextDirX = 0; pacman.nextDirY = -1
                    else pacman.nextDirX = 0; pacman.nextDirY = 1 end
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Pac-Man Arcade closed.")
    else
        print("Pac-Man Arcade closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Pac-Man Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Pac-Man Error: " .. tostring(err))
end
