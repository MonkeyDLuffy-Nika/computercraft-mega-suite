-- ============================================================================
-- CYBER CONNECT 4 2077 DELUXE PRO - 3D SHADED & EXPANDED EDITION
-- 3D Circular Disks, Gravity Drop Animation, Winning Strobe & Synth Audio
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
    [colors.orange]    = 0xFF9800, -- Highlight Indicator
    [colors.magenta]   = 0xE91E63, -- Winning Line Strobe
    [colors.lightBlue] = 0x00E5FF, -- Frame Highlights
    [colors.yellow]    = 0xFFD600, -- Player 2 / AI Disks
    [colors.lime]      = 0x00E676, -- Win Screen / P1 Banner
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- Empty Slot Cavity
    [colors.lightGray] = 0x37474F, -- Board Bevel
    [colors.cyan]      = 0x18FFFF, -- Column Selector Arrows
    [colors.purple]    = 0x7C4DFF,
    [colors.blue]      = 0x0D1B3E, -- Deep Chassis Frame
    [colors.brown]     = 0x4E342E,
    [colors.green]     = 0x1B4332,
    [colors.red]       = 0xFF1744, -- Player 1 Disks
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
        if snd == "click" then
            speaker.playNote("snare", 0.3, 16)
        elseif snd == "drop" then
            speaker.playNote("bass", 0.8, 8)
            speaker.playNote("snare", 0.4, 12)
        elseif snd == "win" then
            for p = 12, 24, 2 do
                speaker.playNote("chime", 0.8, p)
                speaker.playNote("bell", 0.8, p)
                sleep(0.04)
            end
        elseif snd == "draw" then
            speaker.playNote("bass", 0.6, 6)
        end
    end)
end

-- ============================================================================
-- GAME STATE & GRID (7 Columns x 6 Rows)
-- ============================================================================
local COLS = 7
local ROWS = 6

local board = {} -- [r][c] = 0 (empty), 1 (Red), 2 (Yellow)
local turn = 1   -- 1 = Player 1 (Red), 2 = Player 2 / AI (Yellow)
local gameMode = "AI_PRO" -- "PVP", "AI_EASY", "AI_PRO", "AI_MASTER"
local selectedCol = 4
local winningCells = {}
local isDropping = false
local p1Score = 0
local p2Score = 0
local totalGames = 0
local lastDropCol = nil
local streak = 0
local gameState = "TITLE" -- "TITLE", "PLAYING", "VICTORY", "DRAW"

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
-- WIN CHECK & AI ENGINE
-- ============================================================================
local function initBoard()
    board = {}
    for r = 1, ROWS do
        board[r] = {}
        for c = 1, COLS do
            board[r][c] = 0
        end
    end
    turn = 1
    selectedCol = 4
    winningCells = {}
    isDropping = false
    lastDropCol = nil
    gameState = "PLAYING"
end

local function checkConnect4(b)
    -- Horizontal
    for r = 1, ROWS do
        for c = 1, COLS - 3 do
            local p = b[r][c]
            if p ~= 0 and p == b[r][c+1] and p == b[r][c+2] and p == b[r][c+3] then
                return p, { {r, c}, {r, c+1}, {r, c+2}, {r, c+3} }
            end
        end
    end
    -- Vertical
    for r = 1, ROWS - 3 do
        for c = 1, COLS do
            local p = b[r][c]
            if p ~= 0 and p == b[r+1][c] and p == b[r+2][c] and p == b[r+3][c] then
                return p, { {r, c}, {r+1, c}, {r+2, c}, {r+3, c} }
            end
        end
    end
    -- Diagonal Up-Right
    for r = 4, ROWS do
        for c = 1, COLS - 3 do
            local p = b[r][c]
            if p ~= 0 and p == b[r-1][c+1] and p == b[r-2][c+2] and p == b[r-3][c+3] then
                return p, { {r, c}, {r-1, c+1}, {r-2, c+2}, {r-3, c+3} }
            end
        end
    end
    -- Diagonal Down-Right
    for r = 1, ROWS - 3 do
        for c = 1, COLS - 3 do
            local p = b[r][c]
            if p ~= 0 and p == b[r+1][c+1] and p == b[r+2][c+2] and p == b[r+3][c+3] then
                return p, { {r, c}, {r+1, c+1}, {r+2, c+2}, {r+3, c+3} }
            end
        end
    end
    
    -- Check Board Full (Draw)
    local full = true
    for c = 1, COLS do
        if b[1][c] == 0 then full = false break end
    end
    if full then return -1, {} end
    
    return 0, {}
end

local function getLowestEmptyRow(b, col)
    for r = ROWS, 1, -1 do
        if b[r][col] == 0 then return r end
    end
    return nil
end

-- Tactical AI Move Generator
local function getAIMove()
    -- 1. Check if AI can win in 1 move
    for c = 1, COLS do
        local r = getLowestEmptyRow(board, c)
        if r then
            board[r][c] = 2
            local winner = checkConnect4(board)
            board[r][c] = 0
            if winner == 2 then return c end
        end
    end
    
    -- 2. Check if Human can win in 1 move (Block it!)
    for c = 1, COLS do
        local r = getLowestEmptyRow(board, c)
        if r then
            board[r][c] = 1
            local winner = checkConnect4(board)
            board[r][c] = 0
            if winner == 1 then return c end
        end
    end
    
    -- 3. Strategic Columns (Center 4, 3, 5)
    local colOrder = { 4, 3, 5, 2, 6, 1, 7 }
    if gameMode == "AI_EASY" then
        colOrder = { 1, 2, 3, 4, 5, 6, 7 }
        for i = #colOrder, 2, -1 do
            local j = math.random(1, i)
            colOrder[i], colOrder[j] = colOrder[j], colOrder[i]
        end
    end
    
    for _, c in ipairs(colOrder) do
        local r = getLowestEmptyRow(board, c)
        if r then
            if r > 1 then
                board[r][c] = 2
                board[r-1][c] = 1
                local humanWins = (checkConnect4(board) == 1)
                board[r-1][c] = 0
                board[r][c] = 0
                if not humanWins or gameMode == "AI_EASY" then return c end
            else
                return c
            end
        end
    end
    
    for c = 1, COLS do
        if getLowestEmptyRow(board, c) then return c end
    end
    return 4
end

-- Forward declaration of renderGame
local renderGame = nil

-- ============================================================================
-- DISK DROP & MOVE DISPATCHER WITH FALLING GRAVITY ANIMATION
-- ============================================================================
local function dropDisk(col)
    if gameState ~= "PLAYING" or isDropping then return false end
    local targetRow = getLowestEmptyRow(board, col)
    if not targetRow then return false end
    
    isDropping = true
    lastDropCol = col
    
    -- Animated Falling Disk Drop
    for curR = 1, targetRow do
        board[curR][col] = turn
        if curR > 1 then board[curR - 1][col] = 0 end
        if renderGame then renderGame() end
        sleep(0.03)
    end
    board[targetRow][col] = turn
    isDropping = false
    playSound("drop")
    
    local winner, cells = checkConnect4(board)
    if winner > 0 then
        winningCells = cells
        gameState = "VICTORY"
        if winner == 1 then
            p1Score = p1Score + 1
            streak = streak + 1
        else
            p2Score = p2Score + 1
            streak = 0
        end
        totalGames = totalGames + 1
        playSound("win")
    elseif winner == -1 then
        gameState = "DRAW"
        totalGames = totalGames + 1
        playSound("draw")
    else
        turn = (turn == 1) and 2 or 1
        
        -- Trigger AI Turn if Single Player
        if turn == 2 and gameMode ~= "PVP" then
            sleep(0.15)
            local aiCol = getAIMove()
            local aiTargetRow = getLowestEmptyRow(board, aiCol)
            if aiTargetRow then
                lastDropCol = aiCol
                for curR = 1, aiTargetRow do
                    board[curR][aiCol] = 2
                    if curR > 1 then board[curR - 1][aiCol] = 0 end
                    if renderGame then renderGame() end
                    sleep(0.03)
                end
                board[aiTargetRow][aiCol] = 2
                playSound("drop")
                
                local aiWin, aiCells = checkConnect4(board)
                if aiWin > 0 then
                    winningCells = aiCells
                    gameState = "VICTORY"
                    p2Score = p2Score + 1
                    streak = 0
                    totalGames = totalGames + 1
                    playSound("win")
                elseif aiWin == -1 then
                    gameState = "DRAW"
                    totalGames = totalGames + 1
                    playSound("draw")
                else
                    turn = 1
                end
            end
        end
    end
    return true
end

-- ============================================================================
-- FULL-SCREEN 3D CHASSIS RENDERER
-- ============================================================================
renderGame = function()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top HUD Status Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local p1Name = "RED (P1)"
    local p2Name = (gameMode == "PVP") and "YELLOW (P2)" or "CYBER AI"
    local hud = string.format(" %s: %d   [%s]   %s: %d   GAMES:%d ", 
        p1Name, p1Score, (turn == 1) and ">> RED'S TURN <<" or ">> YELLOW'S TURN <<", p2Name, p2Score, totalGames)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Vertical Grid Sizing (Left 62% of the screen)
    local availW = math.floor(screenW * 0.62)
    local availH = screenH - 5
    
    local cellW = math.max(4, math.floor((availW - 8) / COLS))
    local cellH = math.max(2, math.floor(availH / ROWS))
    
    local startX = 3
    local startY = 5
    
    -- Column Drop Selector Arrows (Line 3-4)
    for c = 1, COLS do
        local tx = startX + (c - 1) * (cellW + 1)
        local isSel = (c == selectedCol)
        registerButton("DROP_" .. c, tx, 3, cellW, 2, "  v  ", isSel and "yellow" or "cyan", isSel and "blue" or "gray")
    end
    
    -- Draw 7x6 3D Shaded Chassis Grid
    for r = 1, ROWS do
        for c = 1, COLS do
            local tx = startX + (c - 1) * (cellW + 1)
            local ty = startY + (r - 1) * (cellH + 1)
            local val = board[r][c]
            
            local isWinning = false
            for _, wc in ipairs(winningCells) do
                if wc[1] == r and wc[2] == c then isWinning = true break end
            end
            
            -- Slot Cavity Background
            local bgCol = isWinning and colors.magenta or colors.blue
            for dy = 0, cellH - 1 do
                display.setCursorPos(tx, ty + dy)
                display.setBackgroundColor(bgCol)
                display.write(string.rep(" ", cellW))
            end
            
            -- 3D Disk Relief
            local midY = ty + math.floor(cellH / 2)
            display.setCursorPos(tx, midY)
            if val == 1 then
                display.setBackgroundColor(bgCol)
                display.setTextColor(colors.red)
                display.write(isWinning and "*(R)*" or " (R) ")
            elseif val == 2 then
                display.setBackgroundColor(bgCol)
                display.setTextColor(colors.yellow)
                display.write(isWinning and "*(Y)*" or " (Y) ")
            else
                display.setBackgroundColor(bgCol)
                display.setTextColor(colors.gray)
                display.write(" [.] ")
            end
        end
    end
    
    -- 3. Right Side: Tactical Panel & Controls
    local ctrlStartX = startX + COLS * (cellW + 1) + 2
    local ctrlW = math.max(16, screenW - ctrlStartX - 2)
    local ctrlH = 2
    
    display.setCursorPos(ctrlStartX, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" == TACTICAL PANEL == ")
    
    display.setCursorPos(ctrlStartX, 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write(string.format("MODE: %-12s", gameMode))
    
    display.setCursorPos(ctrlStartX, 6)
    display.setTextColor(colors.lime)
    display.write(string.format("WIN STREAK: %d", streak))
    
    if lastDropCol then
        display.setCursorPos(ctrlStartX, 7)
        display.setTextColor(colors.white)
        display.write(string.format("LAST DROP: Col %d", lastDropCol))
    end
    
    -- Action Buttons
    registerButton("BTN_DROP_SEL", ctrlStartX, 9, ctrlW, ctrlH, " [ DROP DISK (SPACE) ] ", "yellow", "green")
    registerButton("BTN_RESTART", ctrlStartX, 12, ctrlW, ctrlH, " [ ⚡ RESTART (R) ] ", "white", "blue")
    registerButton("BTN_MENU", ctrlStartX, 15, ctrlW, ctrlH, " [ MENU / MODES ] ", "yellow", "purple")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- Win / Draw Overlay
    if gameState == "VICTORY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        local winName = (turn == 1) and "RED PLAYER (P1)" or ((gameMode == "PVP") and "YELLOW PLAYER (P2)" or "CYBER AI")
        local winCol = (turn == 1) and colors.red or colors.yellow
        
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(winCol)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write(string.format("     *** %s WON! ***     ", winName))
        display.setCursorPos(midX - 18, midY - 1)
        display.write("      4 IN A ROW CONNECTED VICTORY    ")
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_PLAY_AGAIN", midX - 14, midY + 2, 28, 2, " [ PLAY AGAIN (TAP) ] ", "yellow", "blue")
        
    elseif gameState == "DRAW" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("       *** STALEMATE / DRAW! ***      ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write("       THE GRID IS COMPLETELY FULL    ")
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_PLAY_AGAIN", midX - 14, midY + 2, 28, 2, " [ PLAY AGAIN (TAP) ] ", "yellow", "blue")
    end
    
    drawButtons()
end

-- ============================================================================
-- UNIQUE CYBER CONNECT 4 SPLASH SCREEN
-- ============================================================================
local function renderTitleScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local midX = math.floor(screenW / 2)
    local titleY = math.max(2, math.floor(screenH / 2) - 7)
    
    -- Glowing Sci-Fi Header
    display.setCursorPos(midX - 19, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ===================================== ")
    display.setCursorPos(midX - 19, titleY + 1)
    display.write("      CYBER CONNECT 4 2077 DELUXE      ")
    display.setCursorPos(midX - 19, titleY + 2)
    display.write(" ===================================== ")
    
    -- Holographic Connect 4 Chassis Artwork
    display.setCursorPos(midX - 17, titleY + 4)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.red)
    display.write(" | (R) ")
    display.setTextColor(colors.yellow)
    display.write("(Y) ")
    display.setTextColor(colors.red)
    display.write("(R) ")
    display.setTextColor(colors.yellow)
    display.write("(Y) | ")
    display.setCursorPos(midX + 2, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lime)
    display.write(">> GRAVITY DISK ARENA <<")
    
    display.setCursorPos(midX - 17, titleY + 5)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" | (Y) ")
    display.setTextColor(colors.red)
    display.write("(R) ")
    display.setTextColor(colors.yellow)
    display.write("(Y) ")
    display.setTextColor(colors.red)
    display.write("(R) | ")
    display.setCursorPos(midX + 2, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write("   7x6 Vertical Drop Grid")
    
    display.setCursorPos(midX - 17, titleY + 6)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.cyan)
    display.write(" +==================+ ")
    display.setCursorPos(midX + 2, titleY + 6)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightGray)
    display.write("   VS Smart AI & 2P Local PvP")
    
    -- Mode Selection Buttons
    display.setCursorPos(midX - 17, titleY + 8)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(" SELECT GAMEPLAY MODE:")
    
    registerButton("MODE_EASY", midX - 18, titleY + 10, 11, 2, " [ VS EASY ] ", "lime", "green")
    registerButton("MODE_PRO", midX - 6, titleY + 10, 12, 2, " [ VS PRO AI ] ", "yellow", "blue")
    registerButton("MODE_MASTER", midX + 7, titleY + 10, 11, 2, " [ VS MASTER ] ", "white", "purple")
    registerButton("MODE_PVP", midX - 12, titleY + 13, 24, 2, " [ 2-PLAYER LOCAL PVP ] ", "yellow", "red")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.one then gameMode = "AI_EASY"; initBoard()
                elseif p1 == keys.two or p1 == keys.space or p1 == keys.enter then gameMode = "AI_PRO"; initBoard()
                elseif p1 == keys.three then gameMode = "AI_MASTER"; initBoard()
                elseif p1 == keys.four or p1 == keys.p then gameMode = "PVP"; initBoard()
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "PLAYING" then
                if p1 == keys.left or p1 == keys.a then
                    selectedCol = (selectedCol == 1) and COLS or (selectedCol - 1); playSound("click")
                elseif p1 == keys.right or p1 == keys.d then
                    selectedCol = (selectedCol == COLS) and 1 or (selectedCol + 1); playSound("click")
                elseif p1 == keys.space or p1 == keys.enter or p1 == keys.down or p1 == keys.s then
                    dropDisk(selectedCol)
                elseif p1 == keys.one then dropDisk(1)
                elseif p1 == keys.two then dropDisk(2)
                elseif p1 == keys.three then dropDisk(3)
                elseif p1 == keys.four then dropDisk(4)
                elseif p1 == keys.five then dropDisk(5)
                elseif p1 == keys.six then dropDisk(6)
                elseif p1 == keys.seven then dropDisk(7)
                elseif p1 == keys.r then initBoard()
                elseif p1 == keys.m then gameState = "TITLE"
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "VICTORY" or gameState == "DRAW" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    initBoard()
                elseif p1 == keys.q or p1 == keys.escape then break end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "MODE_EASY" then gameMode = "AI_EASY"; initBoard()
                elseif cid == "MODE_MASTER" then gameMode = "AI_MASTER"; initBoard()
                elseif cid == "MODE_PVP" then gameMode = "PVP"; initBoard()
                else gameMode = "AI_PRO"; initBoard() end
            elseif gameState == "PLAYING" then
                if cid and string.sub(cid, 1, 5) == "DROP_" then
                    local c = tonumber(string.sub(cid, 6))
                    selectedCol = c
                    dropDisk(c)
                elseif cid == "BTN_DROP_SEL" then
                    dropDisk(selectedCol)
                elseif cid == "BTN_RESTART" or cid == "BTN_PLAY_AGAIN" then
                    initBoard()
                elseif cid == "BTN_MENU" then
                    gameState = "TITLE"
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Click on Column in Grid
                    local availW = math.floor(display.getSize() * 0.62)
                    local cellW = math.max(4, math.floor((availW - 8) / COLS))
                    local startX = 3
                    for c = 1, COLS do
                        local tx = startX + (c - 1) * (cellW + 1)
                        if mx >= tx and mx <= tx + cellW then
                            selectedCol = c
                            dropDisk(c)
                            break
                        end
                    end
                end
            elseif gameState == "VICTORY" or gameState == "DRAW" then
                if cid == "BTN_PLAY_AGAIN" then
                    initBoard()
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Connect 4 closed.")
    else
        print("Connect 4 closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Connect 4 Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Connect 4 Error: " .. tostring(err))
end
