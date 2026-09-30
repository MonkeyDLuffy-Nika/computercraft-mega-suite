-- ============================================================================
-- CYBER MINESWEEPER 2077 DELUXE PRO - 3D SHADED & EXPANDED EDITION
-- 3D Cells, Clearance Progress Bar, Safe First-Click, Flags, Chording & Synth FX
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
    [colors.orange]    = 0xFF9800, -- Number 5 / Accent
    [colors.magenta]   = 0xE91E63, -- Number 4 / Cursor
    [colors.lightBlue] = 0x00E5FF, -- Number 1
    [colors.yellow]    = 0xFFD600, -- Flag [F] / Title
    [colors.lime]      = 0x00E676, -- Number 2 / Progress Bar
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x263238, -- Unrevealed Covered Cell
    [colors.lightGray] = 0x455A64, -- Revealed Empty Cell Floor
    [colors.cyan]      = 0x18FFFF, -- Number 6 / Chording
    [colors.purple]    = 0x7C4DFF,
    [colors.blue]      = 0x0D1B3E, -- Deep Navy Header
    [colors.brown]     = 0x6D4C41,
    [colors.green]     = 0x1B4332, -- Solved / Win
    [colors.red]       = 0xFF1744, -- Number 3 / Mine [*]
    [colors.black]     = 0x0A0D14
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
        if snd == "dig" then
            speaker.playNote("snare", 0.3, 14)
        elseif snd == "flag" then
            speaker.playNote("bell", 0.5, 20)
        elseif snd == "cascade" then
            speaker.playNote("chime", 0.4, 18)
        elseif snd == "explode" then
            speaker.playNote("bass", 1.0, 4)
            speaker.playNote("snare", 1.0, 8)
        elseif snd == "win" then
            for p = 12, 24, 2 do
                speaker.playNote("chime", 0.8, p)
                speaker.playNote("bell", 0.8, p)
                sleep(0.04)
            end
        end
    end)
end

-- ============================================================================
-- NUMBER COLOR STYLES
-- ============================================================================
local NUM_COLORS = {
    [1] = colors.lightBlue,
    [2] = colors.lime,
    [3] = colors.red,
    [4] = colors.purple,
    [5] = colors.orange,
    [6] = colors.cyan,
    [7] = colors.white,
    [8] = colors.gray
}

-- Game State Variables
local gridRows = 9
local gridCols = 9
local totalMines = 10
local flagsPlaced = 0
local timerSeconds = 0
local isFirstClick = true
local touchMode = "DIG" -- "DIG" or "FLAG"
local cursorR = 1
local cursorC = 1
local gameState = "TITLE" -- "TITLE", "PLAYING", "VICTORY", "GAMEOVER"

-- Board Data: [r][c] = { isMine = bool, count = 0..8, isRevealed = bool, isFlagged = bool }
local board = {}

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
-- BOARD GENERATOR & RECURSIVE REVEAL
-- ============================================================================
local function initBoard(rows, cols, mines)
    gridRows = rows
    gridCols = cols
    totalMines = mines
    flagsPlaced = 0
    timerSeconds = 0
    isFirstClick = true
    cursorR = math.floor(rows / 2)
    cursorC = math.floor(cols / 2)
    board = {}
    
    for r = 1, gridRows do
        board[r] = {}
        for c = 1, gridCols do
            board[r][c] = {
                isMine = false,
                count = 0,
                isRevealed = false,
                isFlagged = false
            }
        end
    end
    
    gameState = "PLAYING"
end

local function placeMinesAndCounts(safeR, safeC)
    local placed = 0
    while placed < totalMines do
        local r = math.random(1, gridRows)
        local c = math.random(1, gridCols)
        -- Keep 3x3 around first click 100% safe
        if not board[r][c].isMine and (math.abs(r - safeR) > 1 or math.abs(c - safeC) > 1) then
            board[r][c].isMine = true
            placed = placed + 1
        end
    end
    
    -- Calculate Adjacent Counts
    for r = 1, gridRows do
        for c = 1, gridCols do
            if not board[r][c].isMine then
                local cnt = 0
                for dr = -1, 1 do
                    for dc = -1, 1 do
                        local nr = r + dr
                        local nc = c + dc
                        if nr >= 1 and nr <= gridRows and nc >= 1 and nc <= gridCols then
                            if board[nr][nc].isMine then cnt = cnt + 1 end
                        end
                    end
                end
                board[r][c].count = cnt
            end
        end
    end
end

-- Check Win Condition
local function checkVictory()
    for r = 1, gridRows do
        for c = 1, gridCols do
            if not board[r][c].isMine and not board[r][c].isRevealed then
                return false
            end
        end
    end
    gameState = "VICTORY"
    playSound("win")
    return true
end

-- Cascade Flood Fill
local function revealCell(r, c)
    if r < 1 or r > gridRows or c < 1 or c > gridCols then return end
    local cell = board[r][c]
    if cell.isRevealed or cell.isFlagged then return end
    
    if isFirstClick then
        isFirstClick = false
        placeMinesAndCounts(r, c)
    end
    
    cell.isRevealed = true
    
    if cell.isMine then
        -- Detonation Game Over!
        gameState = "GAMEOVER"
        playSound("explode")
        for br = 1, gridRows do
            for bc = 1, gridCols do
                if board[br][bc].isMine then board[br][bc].isRevealed = true end
            end
        end
        return
    end
    
    playSound("dig")
    
    -- Cascade Reveal if Zero Count
    if cell.count == 0 then
        for dr = -1, 1 do
            for dc = -1, 1 do
                if dr ~= 0 or dc ~= 0 then
                    revealCell(r + dr, c + dc)
                end
            end
        end
    end
    
    checkVictory()
end

local function toggleFlag(r, c)
    if r < 1 or r > gridRows or c < 1 or c > gridCols then return end
    local cell = board[r][c]
    if cell.isRevealed then return end
    
    cell.isFlagged = not cell.isFlagged
    flagsPlaced = flagsPlaced + (cell.isFlagged and 1 or -1)
    playSound("flag")
end

-- Quick Chording on Revealed Number
local function chordCell(r, c)
    local cell = board[r][c]
    if not cell.isRevealed or cell.count == 0 then return end
    
    local flagCount = 0
    for dr = -1, 1 do
        for dc = -1, 1 do
            local nr = r + dr
            local nc = c + dc
            if nr >= 1 and nr <= gridRows and nc >= 1 and nc <= gridCols then
                if board[nr][nc].isFlagged then flagCount = flagCount + 1 end
            end
        end
    end
    
    if flagCount == cell.count then
        for dr = -1, 1 do
            for dc = -1, 1 do
                local nr = r + dr
                local nc = c + dc
                if nr >= 1 and nr <= gridRows and nc >= 1 and nc <= gridCols then
                    if not board[nr][nc].isFlagged and not board[nr][nc].isRevealed then
                        revealCell(nr, nc)
                    end
                end
            end
        end
    end
end

-- Calculate Clearance Percentage
local function getClearanceStats()
    local revealedCount = 0
    local totalSafe = gridRows * gridCols - totalMines
    for r = 1, gridRows do
        for c = 1, gridCols do
            if board[r][c].isRevealed and not board[r][c].isMine then
                revealedCount = revealedCount + 1
            end
        end
    end
    local pct = math.floor((revealedCount / totalSafe) * 100)
    return revealedCount, totalSafe, pct
end

-- ============================================================================
-- FULL-SCREEN 3D GRID RENDERER
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top HUD Status Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local mins = math.floor(timerSeconds / 60)
    local secs = timerSeconds % 60
    local remMines = math.max(0, totalMines - flagsPlaced)
    local _, _, clearPct = getClearanceStats()
    
    local hud = string.format(" MINES: [%02d/%02d]   CLEARED: %3d%%   TIME: %02d:%02d   MODE: [%s] ", 
        remMines, totalMines, clearPct, mins, secs, touchMode)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Board Placement (Dynamic 3D Shaded Proportions)
    local availW = math.floor(screenW * 0.62)
    local availH = screenH - 3
    
    local cellW = math.max(3, math.floor(availW / gridCols))
    local cellH = math.max(1, math.floor(availH / gridRows))
    
    local startX = 2
    local startY = 3
    
    -- Draw 3D Shaded Cells
    for r = 1, gridRows do
        for c = 1, gridCols do
            local tx = startX + (c - 1) * cellW
            local ty = startY + (r - 1) * cellH
            local cell = board[r][c]
            local isCursor = (r == cursorR and c == cursorC)
            
            local bgCol = cell.isRevealed and colors.lightGray or colors.gray
            if isCursor then bgCol = colors.magenta end
            
            for dy = 0, cellH - 1 do
                display.setCursorPos(tx, ty + dy)
                display.setBackgroundColor(bgCol)
                display.write(string.rep(" ", cellW))
            end
            
            -- 3D Top Relief on Unrevealed Cells
            if not cell.isRevealed and cellH >= 2 and not isCursor then
                display.setCursorPos(tx, ty)
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.lightGray)
                display.write(string.rep("-", cellW))
            end
            
            local midY = ty + math.floor((cellH - 1) / 2)
            display.setCursorPos(tx + math.floor((cellW - 1) / 2), midY)
            display.setBackgroundColor(bgCol)
            
            if cell.isRevealed then
                if cell.isMine then
                    display.setTextColor(colors.red)
                    display.write("*")
                elseif cell.count > 0 then
                    display.setTextColor(NUM_COLORS[cell.count] or colors.white)
                    display.write(tostring(cell.count))
                else
                    display.setTextColor(colors.gray)
                    display.write(" ")
                end
            elseif cell.isFlagged then
                display.setTextColor(colors.yellow)
                display.write("F")
            else
                display.setTextColor(colors.black)
                display.write("#")
            end
        end
    end
    
    -- 3. Right Side: Tactical Radar & Action Controls
    local ctrlStartX = startX + gridCols * cellW + 3
    local ctrlW = math.max(16, screenW - ctrlStartX - 2)
    local ctrlH = 2
    
    display.setCursorPos(ctrlStartX, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" == TACTICAL OPS == ")
    
    -- Clearance Progress Bar
    display.setCursorPos(ctrlStartX, 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("SECTOR CLEARED:")
    
    local barWidth = math.max(10, ctrlW - 2)
    local filledBars = math.floor((clearPct / 100) * barWidth)
    display.setCursorPos(ctrlStartX, 6)
    display.setTextColor(colors.lime)
    display.write("[" .. string.rep("=", filledBars) .. string.rep("-", barWidth - filledBars) .. "]")
    
    -- Mode Switcher (Dig vs Flag)
    local digCol = (touchMode == "DIG") and "green" or "gray"
    local flagCol = (touchMode == "FLAG") and "yellow" or "gray"
    registerButton("BTN_MODE_DIG", ctrlStartX, 8, ctrlW, ctrlH, " [ DIG MODE (D) ] ", (touchMode == "DIG") and "yellow" or "white", digCol)
    registerButton("BTN_MODE_FLAG", ctrlStartX, 11, ctrlW, ctrlH, " [ FLAG MODE (F) ] ", (touchMode == "FLAG") and "black" or "white", flagCol)
    
    -- Restart & Menu Buttons
    registerButton("BTN_RESTART", ctrlStartX, 14, ctrlW, ctrlH, " [ ⚡ RESTART (R) ] ", "white", "blue")
    registerButton("BTN_MENU", ctrlStartX, 17, ctrlW, ctrlH, " [ MENU / DIFF ] ", "yellow", "purple")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- Win / Defeat Overlays
    if gameState == "VICTORY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("      *** SECTOR DEMINED / WIN! ***   ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write(string.format("   TIME: %02d:%02d | ALL %d MINES CLEARED ", mins, secs, totalMines))
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_PLAY_AGAIN", midX - 14, midY + 2, 28, 2, " [ PLAY AGAIN (TAP) ] ", "yellow", "green")
        
    elseif gameState == "GAMEOVER" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("     *** MINE DETONATED / BOOM! ***   ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write("     TACTICAL SQUAD HAS ELIMINATED    ")
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_PLAY_AGAIN", midX - 14, midY + 2, 28, 2, " [ TRY AGAIN (TAP) ] ", "yellow", "blue")
    end
    
    drawButtons()
end

-- ============================================================================
-- UNIQUE CYBER MINESWEEPER SPLASH SCREEN
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
    display.write("    CYBER MINESWEEPER 2077 DELUXE     ")
    display.setCursorPos(midX - 19, titleY + 2)
    display.write(" ===================================== ")
    
    -- Holographic Mine Artwork
    display.setCursorPos(midX - 17, titleY + 4)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.red)
    display.write("   \  |  /   ")
    display.setCursorPos(midX - 1, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lime)
    display.write(" >> DETONATION PROTOCOL <<")
    
    display.setCursorPos(midX - 17, titleY + 5)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write("  -- [#] --  ")
    display.setCursorPos(midX - 1, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write("    First-Click 100% Safe Zone")
    
    display.setCursorPos(midX - 17, titleY + 6)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.red)
    display.write("   /  |  \   ")
    display.setCursorPos(midX - 1, titleY + 6)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightGray)
    display.write("    Direct Touch Dig & Fast Flags")
    
    -- Difficulty Selection Buttons
    display.setCursorPos(midX - 17, titleY + 8)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(" SELECT MISSION DIFFICULTY:")
    
    registerButton("DIFF_NOVICE", midX - 18, titleY + 10, 11, 2, " [ NOVICE ] ", "lime", "green")
    registerButton("DIFF_EXPERT", midX - 6, titleY + 10, 12, 2, " [ EXPERT ] ", "yellow", "blue")
    registerButton("DIFF_CYBER", midX + 7, titleY + 10, 11, 2, " [ CYBER ] ", "white", "red")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(1.0)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(1.0)
            if gameState == "PLAYING" and not isFirstClick then
                timerSeconds = timerSeconds + 1
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.one then initBoard(9, 9, 10)
                elseif p1 == keys.two or p1 == keys.space or p1 == keys.enter then initBoard(16, 12, 30)
                elseif p1 == keys.three then initBoard(22, 14, 55)
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "PLAYING" then
                if p1 == keys.up or p1 == keys.w then
                    cursorR = (cursorR == 1) and gridRows or (cursorR - 1); playSound("dig")
                elseif p1 == keys.down or p1 == keys.s then
                    cursorR = (cursorR == gridRows) and 1 or (cursorR + 1); playSound("dig")
                elseif p1 == keys.left or p1 == keys.a then
                    cursorC = (cursorC == 1) and gridCols or (cursorC - 1); playSound("dig")
                elseif p1 == keys.right or p1 == keys.d then
                    cursorC = (cursorC == gridCols) and 1 or (cursorC + 1); playSound("dig")
                elseif p1 == keys.space or p1 == keys.enter then
                    if touchMode == "DIG" then revealCell(cursorR, cursorC) else toggleFlag(cursorR, cursorC) end
                elseif p1 == keys.f then
                    toggleFlag(cursorR, cursorC)
                elseif p1 == keys.c then
                    chordCell(cursorR, cursorC)
                elseif p1 == keys.r then
                    initBoard(gridRows, gridCols, totalMines)
                elseif p1 == keys.m then
                    gameState = "TITLE"
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "VICTORY" or gameState == "GAMEOVER" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    initBoard(gridRows, gridCols, totalMines)
                elseif p1 == keys.q or p1 == keys.escape then break end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local btn = p1 -- 1=Left click, 2=Right click
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "DIFF_NOVICE" then initBoard(9, 9, 10)
                elseif cid == "DIFF_CYBER" then initBoard(22, 14, 55)
                else initBoard(16, 12, 30) end
            elseif gameState == "PLAYING" then
                if cid == "BTN_MODE_DIG" then
                    touchMode = "DIG"
                    playSound("dig")
                elseif cid == "BTN_MODE_FLAG" then
                    touchMode = "FLAG"
                    playSound("flag")
                elseif cid == "BTN_RESTART" or cid == "BTN_PLAY_AGAIN" then
                    initBoard(gridRows, gridCols, totalMines)
                elseif cid == "BTN_MENU" then
                    gameState = "TITLE"
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Click on Grid Cell
                    local availW = math.floor(display.getSize() * 0.62)
                    local availH = select(2, display.getSize()) - 3
                    local cellW = math.max(3, math.floor(availW / gridCols))
                    local cellH = math.max(1, math.floor(availH / gridRows))
                    local startX = 2
                    local startY = 3
                    
                    for r = 1, gridRows do
                        for c = 1, gridCols do
                            local tx = startX + (c - 1) * cellW
                            local ty = startY + (r - 1) * cellH
                            if mx >= tx and mx < tx + cellW and my >= ty and my < ty + cellH then
                                cursorR = r
                                cursorC = c
                                if btn == 2 then
                                    toggleFlag(r, c)
                                else
                                    if board[r][c].isRevealed then
                                        chordCell(r, c)
                                    elseif touchMode == "DIG" then
                                        revealCell(r, c)
                                    else
                                        toggleFlag(r, c)
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            elseif gameState == "VICTORY" or gameState == "GAMEOVER" then
                if cid == "BTN_PLAY_AGAIN" then
                    initBoard(gridRows, gridCols, totalMines)
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Minesweeper closed.")
    else
        print("Minesweeper closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Mines Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Mines Error: " .. tostring(err))
end
