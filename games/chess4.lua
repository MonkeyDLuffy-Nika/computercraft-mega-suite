-- ============================================================================
-- CYBER 4-PLAYER CHESS BATTLE ROYALE - CC: TWEAKED EDITION
-- 14x14 Cross Board, 4 Armies (Red, Blue, Yellow, Green), AI Bots, Teams & FFA
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
-- 4-PLAYER VIBRANT COLOR PALETTE
-- ============================================================================
local PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF961E,
    [colors.magenta]   = 0xEB4BBE,
    [colors.lightBlue] = 0x64B4FF,
    [colors.yellow]    = 0xFFE628, -- Yellow Player (North)
    [colors.lime]      = 0x5AEB28,
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x242430, -- Void / Inaccessible corners
    [colors.lightGray] = 0x9696A8, -- Light Board Square
    [colors.cyan]      = 0x1ED2DC, -- Cyan UI
    [colors.purple]    = 0x8C32E6,
    [colors.blue]      = 0x2468EB, -- Blue Player (West)
    [colors.brown]     = 0x784B28, -- Dark Board Square
    [colors.green]     = 0x24A530, -- Green Player (East)
    [colors.red]       = 0xEB2828, -- Red Player (South)
    [colors.black]     = 0x08080C
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
        if snd == "move" then
            speaker.playNote("snare", 0.7, 14)
        elseif snd == "capture" then
            speaker.playNote("bass", 1.0, 16)
            speaker.playNote("snare", 0.8, 10)
        elseif snd == "eliminate" then
            speaker.playNote("bell", 1.0, 10)
            sleep(0.04)
            speaker.playNote("bass", 1.0, 4)
        elseif snd == "win" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.9, p)
                sleep(0.03)
            end
        end
    end)
end

-- ============================================================================
-- 14x14 BOARD GEOMETRY
-- Valid squares: Rows 1..14, Cols 1..14 EXCLUDING four 3x3 corners:
-- Top-Left: (r 1..3, c 1..3), Top-Right: (r 1..3, c 12..14)
-- Bot-Left: (r 12..14, c 1..3), Bot-Right: (r 12..14, c 12..14)
-- ============================================================================
local function isVoid(r, c)
    if r < 1 or r > 14 or c < 1 or c > 14 then return true end
    if (r <= 3 and c <= 3) or (r <= 3 and c >= 12) or
       (r >= 12 and c <= 3) or (r >= 12 and c >= 12) then
        return true
    end
    return false
end

-- 4 Armies: "r" (Red/South), "b" (Blue/West), "y" (Yellow/North), "g" (Green/East)
local PLAYERS = {
    { id = "r", name = "RED", col = "red", isAlive = true, isAI = false, score = 0 },
    { id = "b", name = "BLUE", col = "blue", isAlive = true, isAI = true, score = 0 },
    { id = "y", name = "YELLOW", col = "yellow", isAlive = true, isAI = true, score = 0 },
    { id = "g", name = "GREEN", col = "green", isAlive = true, isAI = true, score = 0 }
}

local board = {}
local turnIdx = 1 -- 1: Red, 2: Blue, 3: Yellow, 4: Green
local selectedSq = nil
local legalMoves = {}
local moveLog = {}
local isGameOver = false
local winnerName = ""

local function initBoard()
    board = {}
    for r = 1, 14 do
        board[r] = {}
        for c = 1, 14 do
            board[r][c] = "  "
        end
    end
    
    -- 1. Yellow Army (Top / North: Rows 1..3, Cols 4..11)
    local yellowBack = { "yR", "yN", "yB", "yK", "yQ", "yB", "yN", "yR" }
    for i = 1, 8 do
        board[1][3 + i] = yellowBack[i]
        board[2][3 + i] = "yP"
    end
    
    -- 2. Red Army (Bottom / South: Rows 12..14, Cols 4..11)
    local redBack = { "rR", "rN", "rB", "rQ", "rK", "rB", "rN", "rR" }
    for i = 1, 8 do
        board[14][3 + i] = redBack[i]
        board[13][3 + i] = "rP"
    end
    
    -- 3. Blue Army (Left / West: Rows 4..11, Cols 1..3)
    local blueBack = { "bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR" }
    for i = 1, 8 do
        board[3 + i][1] = blueBack[i]
        board[3 + i][2] = "bP"
    end
    
    -- 4. Green Army (Right / East: Rows 4..11, Cols 12..14)
    local greenBack = { "gR", "gN", "gB", "gK", "gQ", "gB", "gN", "gR" }
    for i = 1, 8 do
        board[3 + i][14] = greenBack[i]
        board[3 + i][13] = "gP"
    end
    
    for _, pl in ipairs(PLAYERS) do
        pl.isAlive = true
        pl.score = 0
    end
    
    turnIdx = 1
    selectedSq = nil
    legalMoves = {}
    moveLog = {}
    isGameOver = false
    winnerName = ""
end

initBoard()

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
-- 4-WAY MOVE GENERATION & VALIDATION
-- ============================================================================
local function getPiece(r, c)
    if isVoid(r, c) then return nil end
    local p = board[r][c]
    if p == "  " then return nil end
    return { color = string.sub(p, 1, 1), type = string.sub(p, 2, 2) }
end

local function getLegalMoves4(r, c)
    local moves = {}
    local p = getPiece(r, c)
    if not p then return moves end
    
    local myColor = p.color
    local pType = p.type
    
    -- 1. Pawns (Direction depends on army!)
    if pType == "P" then
        local dr, dc = 0, 0
        local startCheck = false
        if myColor == "r" then dr = -1; startCheck = (r == 13)
        elseif myColor == "y" then dr = 1; startCheck = (r == 2)
        elseif myColor == "b" then dc = 1; startCheck = (c == 2)
        elseif myColor == "g" then dc = -1; startCheck = (c == 13)
        end
        
        -- Move 1 step forward
        local nr, nc = r + dr, c + dc
        if not isVoid(nr, nc) and not getPiece(nr, nc) then
            table.insert(moves, { r = nr, c = nc, isCapture = false })
            -- Double move on start
            if startCheck then
                local nnr, nnc = r + dr * 2, c + dc * 2
                if not isVoid(nnr, nnc) and not getPiece(nnr, nnc) then
                    table.insert(moves, { r = nnr, c = nnc, isCapture = false })
                end
            end
        end
        
        -- Diagonal captures in marching direction
        local diagOffsets = {}
        if dr ~= 0 then
            diagOffsets = { { dr, -1 }, { dr, 1 } }
        else
            diagOffsets = { { -1, dc }, { 1, dc } }
        end
        for _, off in ipairs(diagOffsets) do
            local capR, capC = r + off[1], c + off[2]
            if not isVoid(capR, capC) then
                local target = getPiece(capR, capC)
                if target and target.color ~= myColor then
                    table.insert(moves, { r = capR, c = capC, isCapture = true })
                end
            end
        end
        
    -- 2. Knight (8 L-jumps)
    elseif pType == "N" then
        local offsets = { {-2,-1}, {-2,1}, {-1,-2}, {-1,2}, {1,-2}, {1,2}, {2,-1}, {2,1} }
        for _, off in ipairs(offsets) do
            local nr, nc = r + off[1], c + off[2]
            if not isVoid(nr, nc) then
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                elseif target.color ~= myColor then
                    table.insert(moves, { r = nr, c = nc, isCapture = true })
                end
            end
        end
        
    -- 3. Sliding Pieces: Bishop, Rook, Queen
    elseif pType == "B" or pType == "R" or pType == "Q" then
        local dirs = {}
        if pType == "B" or pType == "Q" then
            table.insert(dirs, {-1,-1}); table.insert(dirs, {-1,1}); table.insert(dirs, {1,-1}); table.insert(dirs, {1,1})
        end
        if pType == "R" or pType == "Q" then
            table.insert(dirs, {-1,0}); table.insert(dirs, {1,0}); table.insert(dirs, {0,-1}); table.insert(dirs, {0,1})
        end
        
        for _, d in ipairs(dirs) do
            local step = 1
            while true do
                local nr = r + d[1] * step
                local nc = c + d[2] * step
                if isVoid(nr, nc) then break end
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                else
                    if target.color ~= myColor then
                        table.insert(moves, { r = nr, c = nc, isCapture = true })
                    end
                    break
                end
                step = step + 1
            end
        end
        
    -- 4. King (1 step any direction)
    elseif pType == "K" then
        local dirs = { {-1,-1}, {-1,0}, {-1,1}, {0,-1}, {0,1}, {1,-1}, {1,0}, {1,1} }
        for _, d in ipairs(dirs) do
            local nr, nc = r + d[1], c + d[2]
            if not isVoid(nr, nc) then
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                elseif target.color ~= myColor then
                    table.insert(moves, { r = nr, c = nc, isCapture = true })
                end
            end
        end
    end
    
    return moves
end

local function getAllMovesForPlayer(playerColor)
    local list = {}
    for r = 1, 14 do
        for c = 1, 14 do
            if not isVoid(r, c) then
                local p = getPiece(r, c)
                if p and p.color == playerColor then
                    local mList = getLegalMoves4(r, c)
                    for _, m in ipairs(mList) do
                        table.insert(list, { fromR = r, fromC = c, toR = m.r, toC = m.c, isCapture = m.isCapture })
                    end
                end
            end
        end
    end
    return list
end

-- ============================================================================
-- MAKE MOVE & ROTATE TURN
-- ============================================================================
local function checkAlivePlayers()
    local aliveCount = 0
    local lastAlive = nil
    for _, pl in ipairs(PLAYERS) do
        -- Check if player still has a King
        local hasKing = false
        for r = 1, 14 do
            for c = 1, 14 do
                local p = getPiece(r, c)
                if p and p.color == pl.id and p.type == "K" then
                    hasKing = true
                    break
                end
            end
            if hasKing then break end
        end
        if not hasKing and pl.isAlive then
            pl.isAlive = false
            playSound("eliminate")
            table.insert(moveLog, pl.name .. " KING FALLEN! [ELIMINATED]")
        end
        if pl.isAlive then
            aliveCount = aliveCount + 1
            lastAlive = pl
        end
    end
    
    if aliveCount <= 1 and lastAlive then
        isGameOver = true
        winnerName = lastAlive.name
        playSound("win")
    end
end

local function makeMove4(fromR, fromC, toR, toC)
    local p = board[fromR][fromC]
    local dest = board[toR][toC]
    local pColor = string.sub(p, 1, 1)
    local pType = string.sub(p, 2, 2)
    
    local isCapture = (dest ~= "  ")
    if isCapture then
        local capturedType = string.sub(dest, 2, 2)
        local curPl = PLAYERS[turnIdx]
        curPl.score = curPl.score + (capturedType == "K" and 200 or (capturedType == "Q" and 90 or 10))
        table.insert(moveLog, string.format("%s took %s on (%d,%d)", curPl.name, dest, toR, toC))
        playSound("capture")
    else
        playSound("move")
    end
    
    -- Pawn Promotion (at center or opposite edge)
    if pType == "P" then
        if (pColor == "r" and toR <= 7) or (pColor == "y" and toR >= 8) or
           (pColor == "b" and toC >= 8) or (pColor == "g" and toC <= 7) then
            p = pColor .. "Q"
        end
    end
    
    board[toR][toC] = p
    board[fromR][fromC] = "  "
    
    selectedSq = nil
    legalMoves = {}
    
    checkAlivePlayers()
    
    -- Advance turn to next alive player
    if not isGameOver then
        for step = 1, 4 do
            turnIdx = (turnIdx % 4) + 1
            if PLAYERS[turnIdx].isAlive then break end
        end
    end
end

-- 4-Player AI
local function makeAIMove4()
    if isGameOver then return end
    local curPl = PLAYERS[turnIdx]
    if not curPl.isAlive or not curPl.isAI then return end
    
    local moves = getAllMovesForPlayer(curPl.id)
    if #moves == 0 then
        curPl.isAlive = false
        checkAlivePlayers()
        return
    end
    
    -- Pick captures first, or King attacks, otherwise random move
    local best = moves[1]
    local bestVal = -999
    for _, m in ipairs(moves) do
        local dst = board[m.toR][m.toC]
        local val = math.random(1, 10)
        if dst ~= "  " then
            local t = string.sub(dst, 2, 2)
            if t == "K" then val = val + 1000
            elseif t == "Q" then val = val + 200
            elseif t == "R" then val = val + 100
            else val = val + 50 end
        end
        if val > bestVal then
            bestVal = val
            best = m
        end
    end
    
    if best then
        makeMove4(best.fromR, best.fromC, best.toR, best.toC)
    end
end

-- ============================================================================
-- RENDER 14x14 CROSS BOARD
-- ============================================================================
local function renderChess4()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top Cyber Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local curPl = PLAYERS[turnIdx]
    local topTitle = string.format(" [ 4-PLAYER CHESS BATTLE ROYALE ]   TURN: %s ", curPl and curPl.name or "---")
    display.setCursorPos(math.max(1, math.floor((screenW - #topTitle) / 2)), 1)
    display.write(topTitle)
    
    -- 2. 14x14 Board Grid (2x Scale: 4 chars wide x 2 lines tall per square)
    local sqW = 4
    local sqH = 2
    local boardStartX = 2
    local boardStartY = 3
    
    local PIECE_GFX_4 = {
        P = { top = " () ", bot = "/__\\" },
        N = { top = " /^^", bot = " /__" },
        B = { top = " (+)", bot = " /O\\" },
        R = { top = " [T]", bot = " [=]" },
        Q = { top = " wWw", bot = " /Q\\" },
        K = { top = " +^+", bot = " /K\\" }
    }
    
    for r = 1, 14 do
        for c = 1, 14 do
            local bx = boardStartX + (c - 1) * sqW
            local by = boardStartY + (r - 1) * sqH
            
            if isVoid(r, c) then
                for dy = 0, sqH - 1 do
                    display.setCursorPos(bx, by + dy)
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.gray)
                    display.write(" ·  ")
                end
            else
                local isSel = (selectedSq and selectedSq.r == r and selectedSq.c == c)
                local isLegal = false
                local isAttack = false
                for _, lm in ipairs(legalMoves) do
                    if lm.r == r and lm.c == c then
                        isLegal = true
                        if lm.isCapture then isAttack = true end
                        break
                    end
                end
                
                local isLight = ((r + c) % 2 == 0)
                local sqBg = isLight and colors.lightGray or colors.brown
                if isSel then sqBg = colors.blue
                elseif isAttack then sqBg = colors.red
                elseif isLegal then sqBg = colors.green
                end
                
                registerButton(string.format("SQ4_%d_%d", r, c), bx, by, sqW, sqH, "", "white", "black")
                
                local p = getPiece(r, c)
                local pColorObj = colors.white
                if p then
                    if p.color == "r" then pColorObj = colors.red
                    elseif p.color == "b" then pColorObj = colors.lightBlue
                    elseif p.color == "y" then pColorObj = colors.yellow
                    elseif p.color == "g" then pColorObj = colors.lime
                    end
                end
                
                for dy = 0, sqH - 1 do
                    display.setCursorPos(bx, by + dy)
                    display.setBackgroundColor(sqBg)
                    
                    if p then
                        local gfx = PIECE_GFX_4[p.type]
                        local lineText = (dy == 0) and gfx.top or gfx.bot
                        display.setTextColor(pColorObj)
                        display.write(lineText)
                    elseif isLegal then
                        if dy == 0 then
                            display.write("    ")
                        else
                            display.setTextColor(colors.yellow)
                            display.write(" ●● ")
                        end
                    else
                        display.write(string.rep(" ", sqW))
                    end
                end
            end
        end
    end
    
    -- 3. Right Side: 4 Armies Status Cards & Score
    local infoX = boardStartX + 14 * sqW + 3
    local infoW = screenW - infoX - 1
    
    display.setCursorPos(infoX, 3)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(" [ 4 ARMIES LEADERBOARD ] ")
    
    for idx, pl in ipairs(PLAYERS) do
        local py = 4 + (idx - 1) * 3
        display.setCursorPos(infoX, py)
        display.setBackgroundColor(colors.black)
        
        local isCurrent = (turnIdx == idx and not isGameOver)
        display.setTextColor(isCurrent and colors.yellow or colors.white)
        display.write(isCurrent and ">> " or "   ")
        
        display.setBackgroundColor(colors[pl.col] or colors.red)
        display.setTextColor(colors.white)
        display.write(string.format(" %-6s ", pl.name))
        
        if pl.isAlive then
            local roleLabel = pl.isAI and "[ BOT ]" or "[ HUMAN ]"
            local roleFg = pl.isAI and "yellow" or "white"
            local roleBg = pl.isAI and "blue" or "green"
            registerButton("TOGGLE_PLAYER_" .. idx, infoX + 11, py, 9, 1, roleLabel, roleFg, roleBg)
        else
            display.setCursorPos(infoX + 11, py)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.red)
            display.write(" [ DEAD ] ")
        end
        
        display.setCursorPos(infoX + 3, py + 1)
        display.setTextColor(colors.lightGray)
        display.write(string.format("Score: %4d PTS   [Tap to Toggle] ", pl.score))
    end
    
    -- Recent Battle Events Log
    display.setCursorPos(infoX, 17)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" [ BATTLE ROYALE LOG ] ")
    
    for idx = math.max(1, #moveLog - 3), #moveLog do
        local ly = 18 + (idx - math.max(1, #moveLog - 3))
        if ly < screenH - 2 then
            display.setCursorPos(infoX, ly)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.lightBlue)
            display.write(string.sub(moveLog[idx], 1, infoW))
        end
    end
    
    -- 4. Bottom Toolbar
    display.setCursorPos(1, screenH)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightBlue)
    display.write(string.rep(" ", screenW))
    
    registerButton("BTN_NEW4", 2, screenH, 12, 1, "[ NEW GAME ]", "yellow", "blue")
    registerButton("BTN_QUIT", screenW - 6, screenH, 6, 1, "[ Q ]", "white", "red")
    
    -- Game Over Screen
    if isGameOver then
        display.setCursorPos(math.floor(screenW / 2) - 15, math.floor(screenH / 2) - 1)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.red)
        display.write(" *** " .. winnerName .. " ARMY VICTORIOUS! *** ")
        display.setCursorPos(math.floor(screenW / 2) - 15, math.floor(screenH / 2))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write("  BATTLE ROYALE OVER - CLICK [ NEW GAME ]  ")
    end
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.4)
    
    while true do
        renderChess4()
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.4)
            local curPl = PLAYERS[turnIdx]
            if curPl and curPl.isAlive and curPl.isAI and not isGameOver then
                sleep(0.2)
                makeAIMove4()
                renderChess4()
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_NEW4" then
                initBoard()
            elseif cid == "BTN_QUIT" then
                break
            elseif cid and string.find(cid, "TOGGLE_PLAYER_") then
                local pIdx = tonumber(string.sub(cid, 15))
                if pIdx and PLAYERS[pIdx] then
                    PLAYERS[pIdx].isAI = not PLAYERS[pIdx].isAI
                    playSound("hover")
                    renderChess4()
                end
            elseif cid and string.find(cid, "SQ4_") then
                local r, c = string.match(cid, "SQ4_(%d+)_(%d+)")
                r, c = tonumber(r), tonumber(c)
                
                local curPl = PLAYERS[turnIdx]
                if r and c and curPl and not curPl.isAI and not isGameOver then
                    local moved = false
                    for _, lm in ipairs(legalMoves) do
                        if lm.r == r and lm.c == c and selectedSq then
                            makeMove4(selectedSq.r, selectedSq.c, r, c)
                            moved = true
                            break
                        end
                    end
                    
                    if not moved then
                        local p = getPiece(r, c)
                        if p and p.color == curPl.id then
                            selectedSq = { r = r, c = c }
                            legalMoves = getLegalMoves4(r, c)
                        else
                            selectedSq = nil
                            legalMoves = {}
                        end
                    end
                end
            end
            
        elseif event == "key" then
            if p1 == keys.q or p1 == keys.escape then
                break
            elseif p1 == keys.r then
                initBoard()
            elseif p1 == keys.one then PLAYERS[1].isAI = not PLAYERS[1].isAI; playSound("hover")
            elseif p1 == keys.two then PLAYERS[2].isAI = not PLAYERS[2].isAI; playSound("hover")
            elseif p1 == keys.three then PLAYERS[3].isAI = not PLAYERS[3].isAI; playSound("hover")
            elseif p1 == keys.four then PLAYERS[4].isAI = not PLAYERS[4].isAI; playSound("hover")
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("4-Player Chess closed.")
    else
        print("4-Player Chess closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("4-Player Chess Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("4-Player Chess Error: " .. tostring(err))
end
