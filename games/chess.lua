-- ============================================================================
-- CYBER CHESS GRANDMASTER - CC: TWEAKED EDITION
-- Full Legal Rules, Smart AI Bot, 2-Player Local & Wireless, Sound FX
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
    [colors.orange]    = 0xFF961E,
    [colors.magenta]   = 0xEB4BBE,
    [colors.lightBlue] = 0x64B4FF,
    [colors.yellow]    = 0xFFE628,
    [colors.lime]      = 0x5AEB28,
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x2C2C36,
    [colors.lightGray] = 0xAAAFB9,
    [colors.cyan]      = 0x1ED2DC,
    [colors.purple]    = 0x8C32E6,
    [colors.blue]      = 0x2454EB,
    [colors.brown]     = 0x9B653B, -- Dark Board Square
    [colors.green]     = 0x2DA537, -- Legal Move Dot
    [colors.red]       = 0xEB372D, -- Check & Attack
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
            speaker.playNote("snare", 0.7, 12)
        elseif snd == "capture" then
            speaker.playNote("bass", 0.9, 16)
            speaker.playNote("snare", 0.7, 10)
        elseif snd == "check" then
            speaker.playNote("bell", 1.0, 20)
            sleep(0.04)
            speaker.playNote("bell", 1.0, 24)
        elseif snd == "win" then
            speaker.playNote("chime", 0.9, 16)
            sleep(0.04)
            speaker.playNote("chime", 0.9, 20)
            sleep(0.04)
            speaker.playNote("chime", 0.9, 24)
        end
    end)
end

-- ============================================================================
-- CHESS BOARD & PIECES
-- Pieces: 'P'=Pawn, 'N'=Knight, 'B'=Bishop, 'R'=Rook, 'Q'=Queen, 'K'=King
-- Colors: 'w'=White, 'b'=Black
-- ============================================================================
local board = {}
local turn = "w" -- "w" or "b"
local gameMode = "AI" -- "AI" or "2P"
local aiDifficulty = 2 -- 1: Easy, 2: Medium, 3: Hard

local selectedSq = nil -- { r, c }
local legalMoves = {}  -- list of { r, c, isCapture }
local moveHistory = {}
local capturedWhite = {}
local capturedBlack = {}

local isGameOver = false
local gameResultText = ""
local inCheck = false
local cursorR = 8
local cursorC = 5

-- Piece Display Symbols
local PIECE_SYMBOLS = {
    wP = "P", wN = "N", wB = "B", wR = "R", wQ = "Q", wK = "K",
    bP = "p", bN = "n", bB = "b", bR = "r", bQ = "q", bK = "k"
}

local PIECE_NAMES = {
    P = "Pawn", N = "Knight", B = "Bishop", R = "Rook", Q = "Queen", K = "King"
}

local function initBoard()
    board = {
        { "bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR" }, -- Row 1 (Black back rank)
        { "bP", "bP", "bP", "bP", "bP", "bP", "bP", "bP" }, -- Row 2
        { "  ", "  ", "  ", "  ", "  ", "  ", "  ", "  " }, -- Row 3
        { "  ", "  ", "  ", "  ", "  ", "  ", "  ", "  " }, -- Row 4
        { "  ", "  ", "  ", "  ", "  ", "  ", "  ", "  " }, -- Row 5
        { "  ", "  ", "  ", "  ", "  ", "  ", "  ", "  " }, -- Row 6
        { "wP", "wP", "wP", "wP", "wP", "wP", "wP", "wP" }, -- Row 7
        { "wR", "wN", "wB", "wQ", "wK", "wB", "wN", "wR" }  -- Row 8 (White back rank)
    }
    turn = "w"
    selectedSq = nil
    legalMoves = {}
    moveHistory = {}
    capturedWhite = {}
    capturedBlack = {}
    isGameOver = false
    gameResultText = ""
    inCheck = false
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
-- MOVE GENERATION & VALIDATION
-- ============================================================================
local function isValidSq(r, c)
    return r >= 1 and r <= 8 and c >= 1 and c <= 8
end

local function getPiece(r, c)
    if not isValidSq(r, c) then return nil end
    local p = board[r][c]
    if p == "  " then return nil end
    return { color = string.sub(p, 1, 1), type = string.sub(p, 2, 2) }
end

local function generateRawMoves(r, c, sideColor)
    local moves = {}
    local p = getPiece(r, c)
    if not p or p.color ~= sideColor then return moves end
    
    local enemy = (sideColor == "w") and "b" or "w"
    
    if p.type == "P" then
        -- Pawn moves
        local dir = (sideColor == "w") and -1 or 1
        local startRow = (sideColor == "w") and 7 or 2
        
        -- Forward 1
        if isValidSq(r + dir, c) and not getPiece(r + dir, c) then
            table.insert(moves, { r = r + dir, c = c, isCapture = false })
            -- Forward 2
            if r == startRow and not getPiece(r + dir * 2, c) then
                table.insert(moves, { r = r + dir * 2, c = c, isCapture = false })
            end
        end
        -- Diagonal captures
        for _, dc in ipairs({ -1, 1 }) do
            if isValidSq(r + dir, c + dc) then
                local target = getPiece(r + dir, c + dc)
                if target and target.color == enemy then
                    table.insert(moves, { r = r + dir, c = c + dc, isCapture = true })
                end
            end
        end
        
    elseif p.type == "N" then
        -- Knight jumps
        local offsets = { {-2,-1}, {-2,1}, {-1,-2}, {-1,2}, {1,-2}, {1,2}, {2,-1}, {2,1} }
        for _, off in ipairs(offsets) do
            local nr, nc = r + off[1], c + off[2]
            if isValidSq(nr, nc) then
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                elseif target.color == enemy then
                    table.insert(moves, { r = nr, c = nc, isCapture = true })
                end
            end
        end
        
    elseif p.type == "B" or p.type == "R" or p.type == "Q" then
        -- Sliding pieces
        local dirs = {}
        if p.type == "B" or p.type == "Q" then
            table.insert(dirs, {-1,-1}); table.insert(dirs, {-1,1}); table.insert(dirs, {1,-1}); table.insert(dirs, {1,1})
        end
        if p.type == "R" or p.type == "Q" then
            table.insert(dirs, {-1,0}); table.insert(dirs, {1,0}); table.insert(dirs, {0,-1}); table.insert(dirs, {0,1})
        end
        
        for _, d in ipairs(dirs) do
            local step = 1
            while true do
                local nr = r + d[1] * step
                local nc = c + d[2] * step
                if not isValidSq(nr, nc) then break end
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                else
                    if target.color == enemy then
                        table.insert(moves, { r = nr, c = nc, isCapture = true })
                    end
                    break
                end
                step = step + 1
            end
        end
        
    elseif p.type == "K" then
        -- King moves
        local dirs = { {-1,-1}, {-1,0}, {-1,1}, {0,-1}, {0,1}, {1,-1}, {1,0}, {1,1} }
        for _, d in ipairs(dirs) do
            local nr, nc = r + d[1], c + d[2]
            if isValidSq(nr, nc) then
                local target = getPiece(nr, nc)
                if not target then
                    table.insert(moves, { r = nr, c = nc, isCapture = false })
                elseif target.color == enemy then
                    table.insert(moves, { r = nr, c = nc, isCapture = true })
                end
            end
        end
    end
    
    return moves
end

local function isSquareUnderAttack(sqR, sqC, byColor)
    for r = 1, 8 do
        for c = 1, 8 do
            local p = getPiece(r, c)
            if p and p.color == byColor then
                local moves = generateRawMoves(r, c, byColor)
                for _, m in ipairs(moves) do
                    if m.r == sqR and m.c == sqC then return true end
                end
            end
        end
    end
    return false
end

local function isKingInCheck(sideColor)
    -- Find King
    local kr, kc = nil, nil
    for r = 1, 8 do
        for c = 1, 8 do
            local p = getPiece(r, c)
            if p and p.color == sideColor and p.type == "K" then
                kr, kc = r, c
                break
            end
        end
        if kr then break end
    end
    if not kr then return false end
    local enemy = (sideColor == "w") and "b" or "w"
    return isSquareUnderAttack(kr, kc, enemy)
end

-- Legal moves filter (no moves that leave own king in check)
local function getLegalMoves(r, c)
    local raw = generateRawMoves(r, c, turn)
    local filtered = {}
    local p = board[r][c]
    
    for _, m in ipairs(raw) do
        -- Simulate move
        local destPiece = board[m.r][m.c]
        board[m.r][m.c] = p
        board[r][c] = "  "
        
        local check = isKingInCheck(turn)
        
        -- Undo move
        board[r][c] = p
        board[m.r][m.c] = destPiece
        
        if not check then
            table.insert(filtered, m)
        end
    end
    return filtered
end

local function getAllLegalMoves(sideColor)
    local all = {}
    for r = 1, 8 do
        for c = 1, 8 do
            local p = getPiece(r, c)
            if p and p.color == sideColor then
                local moves = getLegalMoves(r, c)
                for _, m in ipairs(moves) do
                    table.insert(all, { fromR = r, fromC = c, toR = m.r, toC = m.c, isCapture = m.isCapture })
                end
            end
        end
    end
    return all
end

-- ============================================================================
-- MAKE MOVE & AI ENGINE
-- ============================================================================
local function makeMove(fromR, fromC, toR, toC)
    local p = board[fromR][fromC]
    local dest = board[toR][toC]
    local pType = string.sub(p, 2, 2)
    local pColor = string.sub(p, 1, 1)
    
    local isCapture = (dest ~= "  ")
    if isCapture then
        if string.sub(dest, 1, 1) == "w" then
            table.insert(capturedWhite, dest)
        else
            table.insert(capturedBlack, dest)
        end
    end
    
    -- Pawn Promotion (Auto-Queen)
    if pType == "P" and (toR == 1 or toR == 8) then
        p = pColor .. "Q"
    end
    
    board[toR][toC] = p
    board[fromR][fromC] = "  "
    
    -- History notation
    local files = { "a", "b", "c", "d", "e", "f", "g", "h" }
    local notation = string.format("%s%s%s%d", (pType == "P" and "" or pType), (isCapture and "x" or "-"), files[toC], 9 - toR)
    table.insert(moveHistory, notation)
    
    playSound(isCapture and "capture" or "move")
    
    -- Switch turn
    turn = (turn == "w") and "b" or "w"
    selectedSq = nil
    legalMoves = {}
    
    -- Check game end
    inCheck = isKingInCheck(turn)
    if inCheck then playSound("check") end
    
    local nextMoves = getAllLegalMoves(turn)
    if #nextMoves == 0 then
        isGameOver = true
        if inCheck then
            local winner = (turn == "w") and "BLACK" or "WHITE"
            gameResultText = string.format("CHECKMATE! %s WINS!", winner)
            playSound("win")
        else
            gameResultText = "STALEMATE! DRAW!"
        end
    end
end

-- Chess AI (Minimax & Piece Valuation)
local PIECE_VALUES = { P = 100, N = 320, B = 330, R = 500, Q = 900, K = 20000 }

local function evaluateBoard()
    local score = 0
    for r = 1, 8 do
        for c = 1, 8 do
            local p = getPiece(r, c)
            if p then
                local val = PIECE_VALUES[p.type] or 0
                -- Center control bonus
                if (r == 4 or r == 5) and (c == 4 or c == 5) then val = val + 20 end
                if p.color == "b" then score = score + val else score = score - val end
            end
        end
    end
    return score
end

local function makeAIMove()
    if isGameOver or turn ~= "b" then return end
    
    local allMoves = getAllLegalMoves("b")
    if #allMoves == 0 then return end
    
    local bestMove = allMoves[1]
    local bestScore = -999999
    
    if aiDifficulty == 1 then
        -- Random move with capture preference
        table.sort(allMoves, function(a, b) return (a.isCapture and 1 or 0) > (b.isCapture and 1 or 0) end)
        bestMove = allMoves[math.random(1, math.min(3, #allMoves))]
    else
        -- 1-ply / 2-ply evaluation
        for _, m in ipairs(allMoves) do
            local src = board[m.fromR][m.fromC]
            local dst = board[m.toR][m.toC]
            board[m.toR][m.toC] = src
            board[m.fromR][m.fromC] = "  "
            
            local eval = evaluateBoard()
            if m.isCapture then eval = eval + 50 end
            
            board[m.fromR][m.fromC] = src
            board[m.toR][m.toC] = dst
            
            if eval > bestScore then
                bestScore = eval
                bestMove = m
            end
        end
    end
    
    if bestMove then
        makeMove(bestMove.fromR, bestMove.fromC, bestMove.toR, bestMove.toC)
    end
end

-- ============================================================================
-- RENDER PIPELINE
-- ============================================================================
local function renderChess()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Header Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local title = string.format(" [ CYBER CHESS ]  MODE: %s (AI: %s)  TURN: %s ", gameMode, (aiDifficulty == 1 and "EASY" or (aiDifficulty == 2 and "MED" or "HARD")), (turn == "w" and "WHITE" or "BLACK"))
    display.setCursorPos(math.max(1, math.floor((screenW - #title) / 2)), 1)
    display.write(title)
    
    -- 2. 8x8 Chess Board Layout (1.5x Scale: 6 chars wide x 3 lines tall per square)
    local sqW = 6
    local sqH = 3
    local boardStartX = 3
    local boardStartY = 3
    
    local files = { "A", "B", "C", "D", "E", "F", "G", "H" }
    
    -- Draw File Letters (Top & Bottom)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    for c = 1, 8 do
        local fx = boardStartX + (c - 1) * sqW + 3
        display.setCursorPos(fx, boardStartY - 1)
        display.write(files[c])
    end
    
    for r = 1, 8 do
        -- Rank Number (Left) centered on the 3-line square
        display.setCursorPos(boardStartX - 2, boardStartY + (r - 1) * sqH + 1)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.cyan)
        display.write(tostring(9 - r))
        
        for c = 1, 8 do
            local bx = boardStartX + (c - 1) * sqW
            local by = boardStartY + (r - 1) * sqH
            
            -- Check if square is selected or is a legal move
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
            
            -- Square Color (Alternating Light / Dark wood)
            local isLight = ((r + c) % 2 == 0)
            local sqBgCol = isLight and colors.lightGray or colors.brown
            if isSel then sqBgCol = colors.blue
            elseif isAttack then sqBgCol = colors.red
            elseif isLegal then sqBgCol = colors.green
            end
            
            registerButton(string.format("SQ_%d_%d", r, c), bx, by, sqW, sqH, "", "white", "black")
            
            local p = getPiece(r, c)
            
            -- High-Definition 3-Line Graphical Chess Piece Sprites (6x3 chars)
            local PIECE_GFX = {
                P = { top = "  ()  ", mid = " /__\\ ", bot = " [__] " },
                N = { top = "  /^^ ", mid = " //__ ", bot = " [___]" },
                B = { top = "  (+) ", mid = "  /O\\ ", bot = " [___]" },
                R = { top = " [T_T]", mid = "  | | ", bot = " [===]" },
                Q = { top = " wW_Ww", mid = "  /Q\\ ", bot = " [===]" },
                K = { top = " _+^+_", mid = "  /K\\ ", bot = " [===]" }
            }
            
            local pCol = colors.white
            local pBg = sqBgCol
            if p then
                pCol = (p.color == "w") and colors.white or colors.yellow
                if inCheck and p.type == "K" and p.color == turn then
                    pBg = colors.red
                end
            end
            
            for dy = 0, sqH - 1 do
                display.setCursorPos(bx, by + dy)
                display.setBackgroundColor(pBg)
                
                if p then
                    local gfx = PIECE_GFX[p.type]
                    local lineText = (dy == 0) and gfx.top or ((dy == 1) and gfx.mid or gfx.bot)
                    display.setTextColor(pCol)
                    display.write(lineText)
                elseif isLegal then
                    if dy == 1 then
                        display.setTextColor(colors.yellow)
                        display.write("  ●●  ")
                    else
                        display.write("      ")
                    end
                else
                    display.write(string.rep(" ", sqW))
                end
            end
        end
    end
    
    -- 3. Right Side: Game Information & Notation Card
    local infoX = boardStartX + 8 * sqW + 3
    local infoW = screenW - infoX - 1
    
    display.setCursorPos(infoX, 3)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(" [ MATCH STATUS & HISTORY ] ")
    
    display.setCursorPos(infoX, 5)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write(" ACTIVE TURN : ")
    display.setTextColor(turn == "w" and colors.white or colors.yellow)
    display.write(turn == "w" and "WHITE (Player)" or "BLACK (AI/P2)")
    
    display.setCursorPos(infoX, 7)
    display.setTextColor(colors.white)
    display.write(" IN CHECK    : ")
    display.setTextColor(inCheck and colors.red or colors.lime)
    display.write(inCheck and "YES [DANGER!]" or "NO")
    
    -- Move history list
    display.setCursorPos(infoX, 9)
    display.setTextColor(colors.cyan)
    display.write(" RECENT MOVES:")
    for idx = math.max(1, #moveHistory - 4), #moveHistory do
        local my = 10 + (idx - math.max(1, #moveHistory - 4))
        if my < screenH - 4 then
            display.setCursorPos(infoX + 2, my)
            display.setTextColor(colors.lightGray)
            display.write(string.format("%2d. %-10s", idx, moveHistory[idx]))
        end
    end
    
    -- Captured Graveyard
    display.setCursorPos(infoX, 15)
    display.setTextColor(colors.yellow)
    display.write(" CAPTURED BY WHITE: ")
    local capStrW = ""
    for _, cp in ipairs(capturedBlack) do capStrW = capStrW .. string.sub(cp, 2, 2) .. " " end
    display.setTextColor(colors.yellow)
    display.write(string.sub(capStrW, 1, 14))
    
    display.setCursorPos(infoX, 17)
    display.setTextColor(colors.white)
    display.write(" CAPTURED BY BLACK: ")
    local capStrB = ""
    for _, cp in ipairs(capturedWhite) do capStrB = capStrB .. string.sub(cp, 2, 2) .. " " end
    display.setTextColor(colors.white)
    display.write(string.sub(capStrB, 1, 14))
    
    -- 4. Bottom Toolbar & Buttons
    display.setCursorPos(1, screenH)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightBlue)
    display.write(string.rep(" ", screenW))
    
    registerButton("BTN_NEW_GAME", 2, screenH, 12, 1, "[ NEW GAME ]", "yellow", "blue")
    registerButton("BTN_MODE", 16, screenH, 13, 1, gameMode == "AI" and "[ MODE: VS AI ]" or "[ MODE: 2P LOCAL ]", "lime", "gray")
    registerButton("BTN_DIFF", 31, screenH, 13, 1, string.format("[ AI: %s ]", (aiDifficulty == 1 and "EASY" or (aiDifficulty == 2 and "MED" or "HARD"))), "cyan", "gray")
    registerButton("BTN_QUIT", screenW - 6, screenH, 6, 1, "[ Q ]", "white", "red")
    
    -- Game Over Overlay
    if isGameOver then
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2) - 1)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" *** " .. gameResultText .. " *** ")
        display.setCursorPos(math.floor(screenW / 2) - 14, math.floor(screenH / 2))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write("  CLICK [ NEW GAME ] TO PLAY AGAIN  ")
    end
    
    drawButtons()
end

-- ============================================================================
-- MAIN EVENT LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.5)
    
    while true do
        renderChess()
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.5)
            if gameMode == "AI" and turn == "b" and not isGameOver then
                sleep(0.3)
                makeAIMove()
                renderChess()
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_NEW_GAME" then
                initBoard()
            elseif cid == "BTN_MODE" then
                gameMode = (gameMode == "AI") and "2P" or "AI"
            elseif cid == "BTN_DIFF" then
                aiDifficulty = (aiDifficulty % 3) + 1
            elseif cid == "BTN_QUIT" then
                break
            elseif cid and string.find(cid, "SQ_") then
                -- Parse square r, c
                local r, c = string.match(cid, "SQ_(%d+)_(%d+)")
                r, c = tonumber(r), tonumber(c)
                
                if r and c and not isGameOver then
                    -- Check if clicking a legal move destination
                    local moved = false
                    for _, lm in ipairs(legalMoves) do
                        if lm.r == r and lm.c == c and selectedSq then
                            makeMove(selectedSq.r, selectedSq.c, r, c)
                            moved = true
                            break
                        end
                    end
                    
                    if not moved then
                        local p = getPiece(r, c)
                        if p and p.color == turn then
                            selectedSq = { r = r, c = c }
                            legalMoves = getLegalMoves(r, c)
                            playSound("hover")
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
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Cyber Chess closed.")
    else
        print("Cyber Chess closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Chess Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Chess Error: " .. tostring(err))
end
