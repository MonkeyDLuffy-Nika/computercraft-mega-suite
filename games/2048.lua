-- ============================================================================
-- CYBER 2048 DELUXE PRO - EXPANDED CONTROLS & 3D DETAILED TILES
-- Giant Touch D-Pad, 3D Shaded Tiles, Undo History, High Scores & Synth Audio
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
    [colors.orange]    = 0xFF8C00, -- 8 Tile
    [colors.magenta]   = 0xE91E63, -- 64 Tile
    [colors.lightBlue] = 0x00E5FF, -- 512 Tile
    [colors.yellow]    = 0xFFD600, -- 2048 Tile
    [colors.lime]      = 0x00E676, -- 1024 Tile
    [colors.pink]      = 0xFF4081, -- 128 Tile
    [colors.gray]      = 0x212121, -- Empty Tile Base
    [colors.lightGray] = 0x455A64, -- 2 Tile
    [colors.cyan]      = 0x18FFFF, -- 256 Tile
    [colors.purple]    = 0x7C4DFF, -- 4096 Tile
    [colors.blue]      = 0x0D1B3E, -- Board Frame & Header
    [colors.brown]     = 0x6D4C41, -- 16 Tile
    [colors.green]     = 0x2E7D32, -- Restart Button
    [colors.red]       = 0xD50000, -- 32 Tile
    [colors.black]     = 0x0A0D14
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- TILE VISUAL STYLES & COLORS
-- ============================================================================
local TILE_STYLES = {
    [0]    = { bg = "gray", fg = "black", label = "    " },
    [2]    = { bg = "lightGray", fg = "white" },
    [4]    = { bg = "gray", fg = "yellow" },
    [8]    = { bg = "orange", fg = "white" },
    [16]   = { bg = "brown", fg = "yellow" },
    [32]   = { bg = "red", fg = "white" },
    [64]   = { bg = "magenta", fg = "white" },
    [128]  = { bg = "pink", fg = "yellow" },
    [256]  = { bg = "cyan", fg = "black" },
    [512]  = { bg = "lightBlue", fg = "black" },
    [1024] = { bg = "lime", fg = "black" },
    [2048] = { bg = "yellow", fg = "blue" },
    [4096] = { bg = "purple", fg = "white" },
    [8192] = { bg = "white", fg = "magenta" }
}

-- Sound Effects Engine
local function playSound(snd, val)
    if not speaker then return end
    pcall(function()
        if snd == "slide" then
            speaker.playNote("snare", 0.3, 12)
        elseif snd == "merge" then
            local pitch = math.min(24, 10 + math.floor(math.log(val or 2) / math.log(2)))
            speaker.playNote("bell", 0.6, pitch)
            speaker.playNote("chime", 0.6, pitch)
        elseif snd == "win" then
            for p = 14, 24, 2 do
                speaker.playNote("chime", 0.8, p)
                speaker.playNote("bell", 0.8, p)
                sleep(0.04)
            end
        elseif snd == "gameover" then
            speaker.playNote("bass", 0.8, 6)
            speaker.playNote("bass", 0.8, 4)
        end
    end)
end

-- ============================================================================
-- GAME STATE & HIGH SCORE
-- ============================================================================
local grid = {}
local history = nil
local score = 0
local highScore = 0
local movesCount = 0
local maxTile = 2
local hasWon = false
local isGameOver = false
local gameState = "PLAYING"

local function loadHighScore()
    if fs.exists(".2048_highscore") then
        local f = fs.open(".2048_highscore", "r")
        local num = tonumber(f.readAll())
        f.close()
        if num then highScore = num end
    end
end

local function saveHighScore()
    if score > highScore then
        highScore = score
        local f = fs.open(".2048_highscore", "w")
        f.write(tostring(highScore))
        f.close()
    end
end

loadHighScore()

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
-- 2048 GRID LOGIC & SPAWNING
-- ============================================================================
local function updateMaxTile()
    for r = 1, 4 do
        for c = 1, 4 do
            if grid[r][c] > maxTile then maxTile = grid[r][c] end
        end
    end
end

local function spawnRandomTile()
    local emptyCells = {}
    for r = 1, 4 do
        for c = 1, 4 do
            if grid[r][c] == 0 then
                table.insert(emptyCells, { r = r, c = c })
            end
        end
    end
    
    if #emptyCells > 0 then
        local cell = emptyCells[math.random(1, #emptyCells)]
        grid[cell.r][cell.c] = (math.random() < 0.9) and 2 or 4
    end
    updateMaxTile()
end

local function saveUndoState()
    history = {
        grid = {},
        score = score,
        movesCount = movesCount,
        maxTile = maxTile
    }
    for r = 1, 4 do
        history.grid[r] = {}
        for c = 1, 4 do
            history.grid[r][c] = grid[r][c]
        end
    end
end

local function undoMove()
    if not history then return end
    for r = 1, 4 do
        for c = 1, 4 do
            grid[r][c] = history.grid[r][c]
        end
    end
    score = history.score
    movesCount = history.movesCount
    maxTile = history.maxTile
    history = nil
    isGameOver = false
    gameState = "PLAYING"
    playSound("slide")
end

local function initGame()
    grid = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
    score = 0
    movesCount = 0
    maxTile = 2
    hasWon = false
    isGameOver = false
    history = nil
    gameState = "PLAYING"
    
    spawnRandomTile()
    spawnRandomTile()
end

-- Slide & Merge Row / Column
local function slideRow(row)
    local nonZero = {}
    for _, v in ipairs(row) do
        if v ~= 0 then table.insert(nonZero, v) end
    end
    
    local merged = {}
    local gainedScore = 0
    local skip = false
    
    for i = 1, #nonZero do
        if skip then
            skip = false
        elseif i < #nonZero and nonZero[i] == nonZero[i + 1] then
            local val = nonZero[i] * 2
            table.insert(merged, val)
            gainedScore = gainedScore + val
            if val == 2048 and not hasWon then
                hasWon = true
                gameState = "WIN_OVERLAY"
                playSound("win")
            end
            playSound("merge", val)
            skip = true
        else
            table.insert(merged, nonZero[i])
        end
    end
    
    while #merged < 4 do table.insert(merged, 0) end
    return merged, gainedScore
end

-- Move Grid (Directions: 1=Up, 2=Down, 3=Left, 4=Right)
local function moveGrid(dir)
    if gameState ~= "PLAYING" then return false end
    
    saveUndoState()
    local moved = false
    local totalGained = 0
    
    if dir == 3 then -- Left
        for r = 1, 4 do
            local newRow, pts = slideRow(grid[r])
            totalGained = totalGained + pts
            for c = 1, 4 do
                if grid[r][c] ~= newRow[c] then moved = true end
                grid[r][c] = newRow[c]
            end
        end
    elseif dir == 4 then -- Right
        for r = 1, 4 do
            local revRow = { grid[r][4], grid[r][3], grid[r][2], grid[r][1] }
            local newRow, pts = slideRow(revRow)
            totalGained = totalGained + pts
            local finalRow = { newRow[4], newRow[3], newRow[2], newRow[1] }
            for c = 1, 4 do
                if grid[r][c] ~= finalRow[c] then moved = true end
                grid[r][c] = finalRow[c]
            end
        end
    elseif dir == 1 then -- Up
        for c = 1, 4 do
            local col = { grid[1][c], grid[2][c], grid[3][c], grid[4][c] }
            local newCol, pts = slideRow(col)
            totalGained = totalGained + pts
            for r = 1, 4 do
                if grid[r][c] ~= newCol[r] then moved = true end
                grid[r][c] = newCol[r]
            end
        end
    elseif dir == 2 then -- Down
        for c = 1, 4 do
            local col = { grid[4][c], grid[3][c], grid[2][c], grid[1][c] }
            local newCol, pts = slideRow(col)
            totalGained = totalGained + pts
            local finalCol = { newCol[4], newCol[3], newCol[2], newCol[1] }
            for r = 1, 4 do
                if grid[r][c] ~= finalCol[r] then moved = true end
                grid[r][c] = finalCol[r]
            end
        end
    end
    
    if moved then
        score = score + totalGained
        movesCount = movesCount + 1
        saveHighScore()
        spawnRandomTile()
        playSound("slide")
        
        -- Check Game Over
        local canMove = false
        for r = 1, 4 do
            for c = 1, 4 do
                if grid[r][c] == 0 then canMove = true end
                if c < 4 and grid[r][c] == grid[r][c + 1] then canMove = true end
                if r < 4 and grid[r][c] == grid[r + 1][c] then canMove = true end
            end
        end
        
        if not canMove then
            isGameOver = true
            gameState = "GAMEOVER_OVERLAY"
            playSound("gameover")
        end
    else
        history = nil
    end
    
    return moved
end

-- ============================================================================
-- FULL-SCREEN DETAILED RENDERER WITH LARGE CONTROLS
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.blue)
    display.clear()
    
    -- 1. Top HUD Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" >> 2048 CYBER PRO <<   SCORE: %-6d   BEST: %-6d   MAX: [%d] ", score, highScore, maxTile)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Board Placement (Left Side or Center)
    local cellW = math.max(6, math.floor((screenW * 0.50) / 4) - 1)
    local cellH = math.max(2, math.floor((screenH - 5) / 4) - 1)
    
    local boardW = (cellW + 1) * 4 + 1
    local boardH = (cellH + 1) * 4 + 1
    local startX = 3
    local startY = 3
    
    -- Draw Outer Board Frame
    for dy = 0, boardH - 1 do
        display.setCursorPos(startX, startY + dy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", boardW))
    end
    
    -- Draw 16 Individual 3D Shaded Tiles
    for r = 1, 4 do
        for c = 1, 4 do
            local val = grid[r][c]
            local style = TILE_STYLES[val] or { bg = "purple", fg = "white" }
            local tx = startX + 1 + (c - 1) * (cellW + 1)
            local ty = startY + 1 + (r - 1) * (cellH + 1)
            
            for dy = 0, cellH - 1 do
                display.setCursorPos(tx, ty + dy)
                display.setBackgroundColor(colors[style.bg] or colors.gray)
                display.write(string.rep(" ", cellW))
            end
            
            -- Highlight Top & Bottom Borders for 3D Relief
            if val > 0 and cellH >= 2 then
                display.setCursorPos(tx, ty)
                display.setBackgroundColor(colors[style.bg])
                display.setTextColor(colors.white)
                display.write(string.rep("-", cellW))
            end
            
            -- Center Number Text
            if val > 0 then
                local txt = (val >= 2048) and ("*" .. val .. "*") or tostring(val)
                local midY = ty + math.floor(cellH / 2)
                display.setCursorPos(tx + math.max(0, math.floor((cellW - #txt) / 2)), midY)
                display.setBackgroundColor(colors[style.bg])
                display.setTextColor(colors[style.fg])
                display.write(txt)
            end
        end
    end
    
    -- 3. Right Side: Large Touch Control D-Pad & Action Panel
    local ctrlStartX = startX + boardW + 3
    local dpadW = 11
    local dpadH = 2
    
    -- Stats Box
    display.setCursorPos(ctrlStartX, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.cyan)
    display.write("== GAME STATS ==")
    display.setCursorPos(ctrlStartX, 4)
    display.setTextColor(colors.white)
    display.write(string.format("Moves:  %-5d", movesCount))
    display.setCursorPos(ctrlStartX, 5)
    display.write(string.format("Target: 2048"))
    
    -- Large Giant Touch D-Pad
    local padY = 7
    registerButton("BTN_UP", ctrlStartX + dpadW + 1, padY, dpadW, dpadH, " [   ^ UP   ] ", "yellow", "blue")
    registerButton("BTN_LEFT", ctrlStartX, padY + 3, dpadW, dpadH, " [  < LEFT  ] ", "yellow", "blue")
    registerButton("BTN_DOWN", ctrlStartX + dpadW + 1, padY + 3, dpadW, dpadH, " [  v DOWN  ] ", "yellow", "blue")
    registerButton("BTN_RIGHT", ctrlStartX + (dpadW + 1) * 2, padY + 3, dpadW, dpadH, " [  RIGHT > ] ", "yellow", "blue")
    
    -- Large Action Buttons (Undo & Restart)
    local actY = padY + 7
    if history then
        registerButton("BTN_UNDO", ctrlStartX, actY, 15, 2, " [ (U) UNDO ] ", "yellow", "purple")
    else
        registerButton("BTN_UNDO", ctrlStartX, actY, 15, 2, " [ (U) UNDO ] ", "gray", "lightGray")
    end
    
    registerButton("BTN_RESTART", ctrlStartX + 17, actY, 17, 2, " [ (R) NEW GAME ] ", "yellow", "green")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- Win Overlay
    if gameState == "WIN_OVERLAY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("       *** YOU REACHED 2048! ***      ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write(string.format("   FINAL SCORE: %06d | MOVES: %d   ", score, movesCount))
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_KEEP_PLAYING", midX - 14, midY + 2, 28, 2, " [ KEEP GOING (TAP) ] ", "yellow", "green")
        
    elseif gameState == "GAMEOVER_OVERLAY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("          *** GAME OVER! ***          ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write(string.format("      SCORE: %06d | BEST: %06d   ", score, highScore))
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_TRY_AGAIN", midX - 14, midY + 2, 28, 2, " [ TRY AGAIN (TAP) ] ", "yellow", "blue")
    end
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    initGame()
    local dragStartX, dragStartY = nil, nil
    
    while true do
        renderGame()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            if p1 == keys.up or p1 == keys.w then moveGrid(1)
            elseif p1 == keys.down or p1 == keys.s then moveGrid(2)
            elseif p1 == keys.left or p1 == keys.a then moveGrid(3)
            elseif p1 == keys.right or p1 == keys.d then moveGrid(4)
            elseif p1 == keys.u then undoMove()
            elseif p1 == keys.r then initGame()
            elseif p1 == keys.space and (gameState == "WIN_OVERLAY" or gameState == "GAMEOVER_OVERLAY") then
                if gameState == "WIN_OVERLAY" then gameState = "PLAYING" else initGame() end
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            dragStartX, dragStartY = mx, my
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_UP" then moveGrid(1)
            elseif cid == "BTN_DOWN" then moveGrid(2)
            elseif cid == "BTN_LEFT" then moveGrid(3)
            elseif cid == "BTN_RIGHT" then moveGrid(4)
            elseif cid == "BTN_UNDO" then undoMove()
            elseif cid == "BTN_RESTART" or cid == "BTN_TRY_AGAIN" then initGame()
            elseif cid == "BTN_KEEP_PLAYING" then gameState = "PLAYING"
            elseif cid == "BTN_QUIT" then
                break
            end
            
        elseif event == "mouse_up" or event == "mouse_drag" then
            local mx, my = p2, p3
            if dragStartX and dragStartY then
                local dx = mx - dragStartX
                local dy = my - dragStartY
                if math.abs(dx) > 3 or math.abs(dy) > 2 then
                    if math.abs(dx) > math.abs(dy) then
                        if dx > 0 then moveGrid(4) else moveGrid(3) end
                    else
                        if dy > 0 then moveGrid(2) else moveGrid(1) end
                    end
                    dragStartX, dragStartY = nil, nil
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("2048 closed.")
    else
        print("2048 closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("2048 Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("2048 Error: " .. tostring(err))
end
