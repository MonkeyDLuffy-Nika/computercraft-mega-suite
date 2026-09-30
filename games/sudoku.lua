-- ============================================================================
-- CYBER SUDOKU 2077 DELUXE PRO - DYNAMIC FULL-SCREEN RESOLUTION
-- Massive 9x9 Grid, Giant Touch Numpad, Cell Highlights, Hints & Synth Audio
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
    [colors.orange]    = 0xFF9800, -- Highlighted Row/Col
    [colors.magenta]   = 0xE91E63, -- Selected Cell
    [colors.lightBlue] = 0x00E5FF, -- Given Fixed Numbers
    [colors.yellow]    = 0xFFEB3B, -- Title / Cursor Accent
    [colors.lime]      = 0x00E676, -- Player Numbers
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- 3x3 Subgrid Divider
    [colors.lightGray] = 0x37474F, -- Board Background
    [colors.cyan]      = 0x18FFFF, -- Number Pad
    [colors.purple]    = 0x7C4DFF,
    [colors.blue]      = 0x0D1B3E, -- Deep Navy Header
    [colors.brown]     = 0x4E342E,
    [colors.green]     = 0x1B4332, -- Solved Indicator
    [colors.red]       = 0xFF1744, -- Conflict Errors
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
local function playSound(snd, val)
    if not speaker then return end
    pcall(function()
        if snd == "click" then
            speaker.playNote("snare", 0.3, 16)
        elseif snd == "place" then
            local p = math.min(24, 10 + (val or 1) * 1.5)
            speaker.playNote("chime", 0.6, p)
        elseif snd == "error" then
            speaker.playNote("bass", 0.8, 4)
        elseif snd == "hint" then
            speaker.playNote("bell", 0.7, 20)
            speaker.playNote("chime", 0.7, 24)
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
-- SUDOKU PUZZLE GENERATOR & SOLVER
-- ============================================================================
local solutionBoard = {}
local initialBoard = {}
local board = {}

local selectedRow = 5
local selectedCol = 5
local difficulty = "MEDIUM" -- "EASY", "MEDIUM", "HARD"
local mistakes = 0
local maxMistakes = 3
local hintsRemaining = 3
local timerSeconds = 0
local gameState = "TITLE" -- "TITLE", "PLAYING", "VICTORY", "GAMEOVER"

local function isValidPlacement(b, r, c, val)
    for i = 1, 9 do
        if b[r][i] == val and i ~= c then return false end
        if b[i][c] == val and i ~= r then return false end
    end
    local boxR = math.floor((r - 1) / 3) * 3 + 1
    local boxC = math.floor((c - 1) / 3) * 3 + 1
    for br = 0, 2 do
        for bc = 0, 2 do
            local cr = boxR + br
            local cc = boxC + bc
            if b[cr][cc] == val and (cr ~= r or cc ~= c) then return false end
        end
    end
    return true
end

local function solveSudoku(b)
    for r = 1, 9 do
        for c = 1, 9 do
            if b[r][c] == 0 then
                local nums = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
                for i = #nums, 2, -1 do
                    local j = math.random(1, i)
                    nums[i], nums[j] = nums[j], nums[i]
                end
                for _, num in ipairs(nums) do
                    if isValidPlacement(b, r, c, num) then
                        b[r][c] = num
                        if solveSudoku(b) then return true end
                        b[r][c] = 0
                    end
                end
                return false
            end
        end
    end
    return true
end

local function generateNewPuzzle(diff)
    difficulty = diff or "MEDIUM"
    solutionBoard = {}
    initialBoard = {}
    board = {}
    
    for r = 1, 9 do
        solutionBoard[r] = {}
        initialBoard[r] = {}
        board[r] = {}
        for c = 1, 9 do
            solutionBoard[r][c] = 0
            initialBoard[r][c] = 0
            board[r][c] = 0
        end
    end
    
    -- Fill diagonal 3x3 boxes first
    for k = 1, 9, 3 do
        local nums = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
        for i = #nums, 2, -1 do
            local j = math.random(1, i)
            nums[i], nums[j] = nums[j], nums[i]
        end
        local idx = 1
        for r = 0, 2 do
            for c = 0, 2 do
                solutionBoard[k + r][k + c] = nums[idx]
                idx = idx + 1
            end
        end
    end
    
    solveSudoku(solutionBoard)
    
    -- Copy to working board
    for r = 1, 9 do
        for c = 1, 9 do
            board[r][c] = solutionBoard[r][c]
            initialBoard[r][c] = solutionBoard[r][c]
        end
    end
    
    -- Dig holes according to difficulty
    local holes = (diff == "EASY") and 38 or ((diff == "MEDIUM") and 48 or 56)
    while holes > 0 do
        local r = math.random(1, 9)
        local c = math.random(1, 9)
        if board[r][c] ~= 0 then
            board[r][c] = 0
            initialBoard[r][c] = 0
            holes = holes - 1
        end
    end
    
    selectedRow = 5
    selectedCol = 5
    mistakes = 0
    hintsRemaining = 3
    timerSeconds = 0
    gameState = "PLAYING"
end

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
-- GAME ACTIONS & INPUT
-- ============================================================================
local function inputNumber(num)
    if gameState ~= "PLAYING" then return end
    if initialBoard[selectedRow][selectedCol] ~= 0 then return end
    
    if num == 0 then
        board[selectedRow][selectedCol] = 0
        playSound("click")
        return
    end
    
    if solutionBoard[selectedRow][selectedCol] == num then
        board[selectedRow][selectedCol] = num
        playSound("place", num)
        
        -- Check Win
        local solved = true
        for r = 1, 9 do
            for c = 1, 9 do
                if board[r][c] ~= solutionBoard[r][c] then solved = false break end
            end
        end
        if solved then
            gameState = "VICTORY"
            playSound("win")
        end
    else
        board[selectedRow][selectedCol] = num
        mistakes = mistakes + 1
        playSound("error")
        if mistakes >= maxMistakes then
            gameState = "GAMEOVER"
        end
    end
end

local function useHint()
    if gameState ~= "PLAYING" or hintsRemaining <= 0 then return end
    if initialBoard[selectedRow][selectedCol] == 0 and board[selectedRow][selectedCol] ~= solutionBoard[selectedRow][selectedCol] then
        board[selectedRow][selectedCol] = solutionBoard[selectedRow][selectedCol]
        hintsRemaining = hintsRemaining - 1
        playSound("hint")
    end
end

-- ============================================================================
-- DYNAMIC FULL-SCREEN 9x9 GRID RENDERER
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
    local hud = string.format(" CYBER SUDOKU   DIFF:[%s]   TIME:%02d:%02d   MISTAKES:[%d/%d]   HINTS:%d ", 
        difficulty, mins, secs, mistakes, maxMistakes, hintsRemaining)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Proportional Board Sizing (Fills left 58% of the screen)
    local availW = math.floor(screenW * 0.58)
    local availH = screenH - 3
    
    local cellW = math.max(3, math.floor((availW - 6) / 9))
    local cellH = math.max(1, math.floor((availH - 4) / 9))
    
    local gridStartX = 2
    local gridStartY = 3
    
    -- Draw 9x9 Cells
    for r = 1, 9 do
        for c = 1, 9 do
            local extraX = math.floor((c - 1) / 3)
            local extraY = math.floor((r - 1) / 3)
            local tx = gridStartX + (c - 1) * cellW + extraX
            local ty = gridStartY + (r - 1) * cellH + extraY
            
            local val = board[r][c]
            local isInitial = (initialBoard[r][c] ~= 0)
            local isSelected = (r == selectedRow and c == selectedCol)
            local isHighlighted = (r == selectedRow or c == selectedCol or (math.floor((r - 1) / 3) == math.floor((selectedRow - 1) / 3) and math.floor((c - 1) / 3) == math.floor((selectedCol - 1) / 3)))
            local isConflict = (val ~= 0 and val ~= solutionBoard[r][c])
            
            -- Cell Background Color
            local bgCol = colors.gray
            if isSelected then
                bgCol = colors.magenta
            elseif isConflict then
                bgCol = colors.red
            elseif isHighlighted then
                bgCol = colors.lightGray
            elseif ((math.floor((r - 1) / 3) + math.floor((c - 1) / 3)) % 2 == 0) then
                bgCol = colors.gray
            else
                bgCol = colors.black
            end
            
            for dy = 0, cellH - 1 do
                display.setCursorPos(tx, ty + dy)
                display.setBackgroundColor(bgCol)
                display.write(string.rep(" ", cellW))
            end
            
            -- Text / Value Rendering
            local fgCol = colors.lime
            if isSelected then
                fgCol = colors.yellow
            elseif isInitial then
                fgCol = colors.lightBlue
            elseif isConflict then
                fgCol = colors.white
            end
            
            local midY = ty + math.floor((cellH - 1) / 2)
            local txt = (val == 0) and "." or tostring(val)
            display.setCursorPos(tx + math.floor((cellW - #txt) / 2), midY)
            display.setBackgroundColor(bgCol)
            display.setTextColor(fgCol)
            display.write(txt)
        end
    end
    
    -- 3. Right Side: Large Giant Touch Number Pad (1-9) & Actions
    local padStartX = gridStartX + 9 * cellW + 6
    local padStartY = 3
    local btnW = math.max(6, math.floor((screenW - padStartX - 4) / 3))
    local btnH = math.max(2, math.floor(availH / 6))
    
    display.setCursorPos(padStartX, padStartY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" == NUMBER PAD == ")
    
    for num = 1, 9 do
        local nr = math.floor((num - 1) / 3)
        local nc = (num - 1) % 3
        local bx = padStartX + nc * (btnW + 1)
        local by = padStartY + 2 + nr * (btnH + 1)
        registerButton("NUM_" .. num, bx, by, btnW, btnH, string.format(" [ %d ] ", num), "yellow", "blue")
    end
    
    -- Action Buttons (Erase, Hint, New Game)
    local actY = padStartY + 2 + 3 * (btnH + 1) + 1
    local halfBtnW = math.floor((btnW * 3 + 2) / 2)
    
    registerButton("BTN_ERASE", padStartX, actY, halfBtnW, btnH, " [ ERASE (X) ] ", "white", "red")
    registerButton("BTN_HINT", padStartX + halfBtnW + 1, actY, halfBtnW, btnH, string.format(" [ HINT (%d) ] ", hintsRemaining), "yellow", "purple")
    
    registerButton("BTN_NEW", padStartX, actY + btnH + 1, btnW * 3 + 2, btnH, " [ ⚡ NEW GAME (R) ] ", "yellow", "green")
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
        display.write("     *** SUDOKU SOLVED / WIN! ***     ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write(string.format("   TIME: %02d:%02d | DIFFICULTY: %-6s ", mins, secs, difficulty))
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_RETRY", midX - 14, midY + 2, 28, 2, " [ PLAY AGAIN (TAP) ] ", "yellow", "green")
        
    elseif gameState == "GAMEOVER" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 18, midY - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, midY - 2)
        display.write("      *** 3 MISTAKES / DEFEAT! ***    ")
        display.setCursorPos(midX - 18, midY - 1)
        display.write("   THE MATRIX REJECTED YOUR SOLUTION  ")
        display.setCursorPos(midX - 18, midY)
        display.write(" ==================================== ")
        
        registerButton("BTN_RETRY", midX - 14, midY + 2, 28, 2, " [ TRY AGAIN (TAP) ] ", "yellow", "blue")
    end
    
    drawButtons()
end

-- ============================================================================
-- UNIQUE CYBER SUDOKU SPLASH / TITLE SCREEN
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
    display.write("      CYBER SUDOKU 2077 DELUXE PRO     ")
    display.setCursorPos(midX - 19, titleY + 2)
    display.write(" ===================================== ")
    
    -- Hologram 3x3 Artwork Matrix
    display.setCursorPos(midX - 17, titleY + 4)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" +---+---+---+ ")
    display.setCursorPos(midX - 1, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lime)
    display.write(" >> QUANTUM MATRIX ENGINE <<")
    
    display.setCursorPos(midX - 17, titleY + 5)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" | 5 | 3 | . | ")
    display.setCursorPos(midX - 1, titleY + 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write("    9x9 Tactical Grid Solving")
    
    display.setCursorPos(midX - 17, titleY + 6)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" | 6 | . | 1 | ")
    display.setCursorPos(midX - 1, titleY + 6)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightGray)
    display.write("    Touch Numpad & Auto-Verify")
    
    display.setCursorPos(midX - 17, titleY + 7)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" +---+---+---+ ")
    
    -- Difficulty Selection Buttons
    display.setCursorPos(midX - 17, titleY + 9)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(" SELECT MISSION DIFFICULTY:")
    
    registerButton("DIFF_EASY", midX - 18, titleY + 11, 11, 2, " [ EASY ] ", "lime", "green")
    registerButton("DIFF_MEDIUM", midX - 6, titleY + 11, 12, 2, " [ MEDIUM ] ", "yellow", "blue")
    registerButton("DIFF_HARD", midX + 7, titleY + 11, 11, 2, " [ HARD ] ", "white", "red")
    
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
            if gameState == "PLAYING" then
                timerSeconds = timerSeconds + 1
            end
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.one then generateNewPuzzle("EASY")
                elseif p1 == keys.two or p1 == keys.space or p1 == keys.enter then generateNewPuzzle("MEDIUM")
                elseif p1 == keys.three then generateNewPuzzle("HARD")
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "PLAYING" then
                if p1 == keys.up or p1 == keys.w then
                    selectedRow = (selectedRow == 1) and 9 or (selectedRow - 1); playSound("click")
                elseif p1 == keys.down or p1 == keys.s then
                    selectedRow = (selectedRow == 9) and 1 or (selectedRow + 1); playSound("click")
                elseif p1 == keys.left or p1 == keys.a then
                    selectedCol = (selectedCol == 1) and 9 or (selectedCol - 1); playSound("click")
                elseif p1 == keys.right or p1 == keys.d then
                    selectedCol = (selectedCol == 9) and 1 or (selectedCol + 1); playSound("click")
                elseif p1 == keys.one then inputNumber(1)
                elseif p1 == keys.two then inputNumber(2)
                elseif p1 == keys.three then inputNumber(3)
                elseif p1 == keys.four then inputNumber(4)
                elseif p1 == keys.five then inputNumber(5)
                elseif p1 == keys.six then inputNumber(6)
                elseif p1 == keys.seven then inputNumber(7)
                elseif p1 == keys.eight then inputNumber(8)
                elseif p1 == keys.nine then inputNumber(9)
                elseif p1 == keys.backspace or p1 == keys.delete or p1 == keys.x then inputNumber(0)
                elseif p1 == keys.h then useHint()
                elseif p1 == keys.r then generateNewPuzzle(difficulty)
                elseif p1 == keys.q or p1 == keys.escape then break end
            elseif gameState == "VICTORY" or gameState == "GAMEOVER" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    generateNewPuzzle(difficulty)
                elseif p1 == keys.q or p1 == keys.escape then break end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "DIFF_EASY" then generateNewPuzzle("EASY")
                elseif cid == "DIFF_HARD" then generateNewPuzzle("HARD")
                else generateNewPuzzle("MEDIUM") end
            elseif gameState == "PLAYING" then
                if cid and string.sub(cid, 1, 4) == "NUM_" then
                    local num = tonumber(string.sub(cid, 5))
                    inputNumber(num)
                elseif cid == "BTN_ERASE" then
                    inputNumber(0)
                elseif cid == "BTN_HINT" then
                    useHint()
                elseif cid == "BTN_NEW" or cid == "BTN_RETRY" then
                    generateNewPuzzle(difficulty)
                elseif cid == "BTN_QUIT" then
                    break
                else
                    -- Direct Click on Large 9x9 Board Cell
                    local screenW, screenH = display.getSize()
                    local availW = math.floor(screenW * 0.58)
                    local availH = screenH - 3
                    local cellW = math.max(3, math.floor((availW - 6) / 9))
                    local cellH = math.max(1, math.floor((availH - 4) / 9))
                    local gridStartX = 2
                    local gridStartY = 3
                    
                    for r = 1, 9 do
                        for c = 1, 9 do
                            local extraX = math.floor((c - 1) / 3)
                            local extraY = math.floor((r - 1) / 3)
                            local tx = gridStartX + (c - 1) * cellW + extraX
                            local ty = gridStartY + (r - 1) * cellH + extraY
                            
                            if mx >= tx and mx < tx + cellW and my >= ty and my < ty + cellH then
                                selectedRow = r
                                selectedCol = c
                                playSound("click")
                                break
                            end
                        end
                    end
                end
            elseif gameState == "VICTORY" or gameState == "GAMEOVER" then
                if cid == "BTN_RETRY" then
                    generateNewPuzzle(difficulty)
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Sudoku closed.")
    else
        print("Sudoku closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Sudoku Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Sudoku Error: " .. tostring(err))
end
