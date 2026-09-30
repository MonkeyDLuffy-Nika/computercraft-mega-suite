--[[
================================================================================
                   TETRIS for CC: Tweaked (Minecraft)
            Clean English Arcade Edition with Touch Controls
================================================================================
  Features:
    * Clean standard English labels (100% ASCII - zero glitch characters)
    * On-screen touch buttons:
        Left:  [ HOLD ], [ < LEFT ], [ RIGHT > ], [ v SOFT DROP v ]
        Right: [ ROTATE ], [ CCW ], [ HARD DROP ], [ PAUSE ]
    * Output: External Monitor on the LEFT ("left") or Computer Terminal
    * Interactive Menus: Marathon, Level Select, Controls, Settings, High Scores
    * SRS Super Rotation System, 7-Bag Randomizer, Ghost Piece, Hold Slot
    * Sound FX via ComputerCraft Speaker peripheral
    * Dual Input: Full Touch / Mouse clicks + Keyboard (WASD / Arrows / Space)
================================================================================
]]

-- 1. Display Setup: Left Monitor ("left") or Terminal
local targetSide = "left"
local mon = peripheral.wrap(targetSide)
if not mon or (peripheral.getType and peripheral.getType(targetSide) ~= "monitor") then
    mon = peripheral.find("monitor")
end

local isMonitor = (mon ~= nil)
local display = mon or term

if isMonitor then
    pcall(function() mon.setTextScale(0.5) end)
end

if not display or not display.isColor or not display.isColor() then
    printError("TETRIS requires an Advanced Computer or Color Monitor!")
    return
end

local screenW, screenH = display.getSize()

-- Console Info Output
if isMonitor then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.cyan)
    term.clear()
    term.setCursorPos(1, 1)
    print("========================================")
    print("   TETRIS CC: Tweaked (Touch Screen)    ")
    print("========================================")
    term.setTextColor(colors.yellow)
    print("Monitor: " .. (targetSide or "external") .. " (" .. screenW .. "x" .. screenH .. ")")
    term.setTextColor(colors.lime)
    print("Touch buttons are active on screen!")
    term.setTextColor(colors.white)
    print("Tap screen buttons directly with mouse / hand.")
    print("Keyboard controls (WASD / Arrows / Space) are also active.")
end

-- Audio Sound FX via Speaker
local speaker = peripheral and peripheral.find and peripheral.find("speaker")

local function playSoundFX(soundType)
    if not speaker then return end
    pcall(function()
        if soundType == "move" then
            speaker.playNote("hat", 0.5, 14)
        elseif soundType == "rotate" then
            speaker.playNote("snare", 0.6, 18)
        elseif soundType == "hold" then
            speaker.playNote("chime", 0.7, 10)
        elseif soundType == "soft_drop" then
            speaker.playNote("hat", 0.3, 10)
        elseif soundType == "hard_drop" then
            speaker.playNote("bass", 0.9, 8)
        elseif soundType == "lock" then
            speaker.playNote("bass", 0.6, 12)
        elseif soundType == "clear_1" then
            speaker.playNote("bell", 0.9, 14)
        elseif soundType == "clear_2" then
            speaker.playNote("bell", 0.9, 14)
            sleep(0.04)
            speaker.playNote("bell", 0.9, 18)
        elseif soundType == "clear_3" then
            speaker.playNote("bell", 0.9, 14)
            sleep(0.04)
            speaker.playNote("bell", 0.9, 18)
            sleep(0.04)
            speaker.playNote("bell", 0.9, 22)
        elseif soundType == "tetris" then
            speaker.playNote("chime", 1.0, 12)
            speaker.playNote("flute", 0.8, 16)
            sleep(0.06)
            speaker.playNote("chime", 1.0, 19)
            speaker.playNote("flute", 0.8, 24)
        elseif soundType == "level_up" then
            speaker.playNote("chime", 1.0, 8)
            sleep(0.05)
            speaker.playNote("chime", 1.0, 12)
            sleep(0.05)
            speaker.playNote("chime", 1.0, 16)
            sleep(0.05)
            speaker.playNote("chime", 1.0, 20)
        elseif soundType == "gameover" then
            speaker.playNote("didgeridoo", 1.0, 6)
            sleep(0.1)
            speaker.playNote("didgeridoo", 1.0, 2)
        elseif soundType == "click" then
            speaker.playNote("hat", 0.6, 16)
        end
    end)
end

-- Double Buffering Graphics System
local Buffer = {
    chars = {},
    fg = {},
    bg = {}
}

local function initBuffer()
    screenW, screenH = display.getSize()
    Buffer.chars = {}
    Buffer.fg = {}
    Buffer.bg = {}
    for y = 1, screenH do
        Buffer.chars[y] = string.rep(" ", screenW)
        Buffer.fg[y] = string.rep("0", screenW)
        Buffer.bg[y] = string.rep("f", screenW)
    end
end

local function clearBuffer(fgChar, bgChar)
    screenW, screenH = display.getSize()
    fgChar = (fgChar and #fgChar > 0) and string.sub(fgChar, 1, 1) or "0"
    bgChar = (bgChar and #bgChar > 0) and string.sub(bgChar, 1, 1) or "f"
    for y = 1, screenH do
        Buffer.chars[y] = string.rep(" ", screenW)
        Buffer.fg[y] = string.rep(fgChar, screenW)
        Buffer.bg[y] = string.rep(bgChar, screenW)
    end
end

local function drawText(x, y, text, fg, bg)
    if y < 1 or y > screenH or x > screenW then return end
    if not text or #text == 0 then return end
    local len = #text
    if x + len - 1 < 1 then return end
    
    local startIdx = 1
    local drawX = x
    if drawX < 1 then
        startIdx = 2 - drawX
        drawX = 1
    end
    local drawLen = math.min(len - startIdx + 1, screenW - drawX + 1)
    if drawLen <= 0 then return end
    
    local subText = string.sub(text, startIdx, startIdx + drawLen - 1)
    local fillFg = (fg and #fg > 0) and string.sub(fg, 1, 1) or "0"
    local fillBg = (bg and #bg > 0) and string.sub(bg, 1, 1) or "f"
    local subFg = string.rep(fillFg, drawLen)
    local subBg = string.rep(fillBg, drawLen)
    
    Buffer.chars[y] = Buffer.chars[y] or string.rep(" ", screenW)
    Buffer.fg[y] = Buffer.fg[y] or string.rep("0", screenW)
    Buffer.bg[y] = Buffer.bg[y] or string.rep("f", screenW)
    
    local leftChars = string.sub(Buffer.chars[y], 1, drawX - 1)
    local rightChars = string.sub(Buffer.chars[y], drawX + drawLen)
    Buffer.chars[y] = leftChars .. subText .. rightChars
    
    local leftFg = string.sub(Buffer.fg[y], 1, drawX - 1)
    local rightFg = string.sub(Buffer.fg[y], drawX + drawLen)
    Buffer.fg[y] = leftFg .. subFg .. rightFg
    
    local leftBg = string.sub(Buffer.bg[y], 1, drawX - 1)
    local rightBg = string.sub(Buffer.bg[y], drawX + drawLen)
    Buffer.bg[y] = leftBg .. subBg .. rightBg
end

local function drawCenteredText(y, text, fg, bg)
    local x = math.floor((screenW - #text) / 2) + 1
    drawText(x, y, text, fg, bg)
end

local function flushBuffer()
    screenW, screenH = display.getSize()
    for y = 1, screenH do
        local c = Buffer.chars[y] or string.rep(" ", screenW)
        local f = Buffer.fg[y] or string.rep("0", screenW)
        local b = Buffer.bg[y] or string.rep("f", screenW)
        
        if #c < screenW then c = c .. string.rep(" ", screenW - #c)
        elseif #c > screenW then c = string.sub(c, 1, screenW) end
        
        if #f < screenW then f = f .. string.rep("0", screenW - #f)
        elseif #f > screenW then f = string.sub(f, 1, screenW) end
        
        if #b < screenW then b = b .. string.rep("f", screenW - #b)
        elseif #b > screenW then b = string.sub(b, 1, screenW) end
        
        display.setCursorPos(1, y)
        pcall(function()
            display.blit(c, f, b)
        end)
    end
end

-- Touch Button Interactive System
local TouchButtons = {}
local activePressedId = nil
local activePressedTimer = 0

local function clearButtons()
    TouchButtons = {}
end

local function registerButton(id, x, y, w, h, label, fg, bg, activeBg)
    table.insert(TouchButtons, {
        id = id,
        x1 = x,
        y1 = y,
        x2 = x + w - 1,
        y2 = y + h - 1,
        w = w,
        h = h,
        label = label,
        fg = fg or "0",
        bg = bg or "8",
        activeBg = activeBg or "e"
    })
end

local function drawRegisteredButtons()
    for _, btn in ipairs(TouchButtons) do
        local isPressed = (activePressedId == btn.id)
        local curBg = isPressed and btn.activeBg or btn.bg
        local curFg = isPressed and "f" or btn.fg
        
        for by = btn.y1, btn.y2 do
            drawText(btn.x1, by, string.rep(" ", btn.w), curFg, curBg)
        end
        
        local lblX = btn.x1 + math.floor((btn.w - #btn.label) / 2)
        local lblY = btn.y1 + math.floor((btn.h - 1) / 2)
        drawText(lblX, lblY, btn.label, curFg, curBg)
    end
end

local function checkButtonClicked(clickX, clickY)
    for _, btn in ipairs(TouchButtons) do
        if clickX >= btn.x1 and clickX <= btn.x2 and clickY >= btn.y1 and clickY <= btn.y2 then
            activePressedId = btn.id
            activePressedTimer = 0.12
            return btn.id
        end
    end
    return nil
end

-- Settings
local Settings = {
    sound = true,
    ghostPiece = true,
    gridLines = true,
    startingLevel = 1,
    highScore = 0
}

-- Tetromino Definitions
local TETROMINOES = {
    I = {
        color = "9",
        char = "[]",
        shape = {
            [0] = { {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} },
            [1] = { {0,0,1,0}, {0,0,1,0}, {0,0,1,0}, {0,0,1,0} },
            [2] = { {0,0,0,0}, {0,0,0,0}, {1,1,1,1}, {0,0,0,0} },
            [3] = { {0,1,0,0}, {0,1,0,0}, {0,1,0,0}, {0,1,0,0} }
        },
        size = 4
    },
    J = {
        color = "b",
        char = "[]",
        shape = {
            [0] = { {1,0,0}, {1,1,1}, {0,0,0} },
            [1] = { {0,1,1}, {0,1,0}, {0,1,0} },
            [2] = { {0,0,0}, {1,1,1}, {0,0,1} },
            [3] = { {0,1,0}, {0,1,0}, {1,1,0} }
        },
        size = 3
    },
    L = {
        color = "1",
        char = "[]",
        shape = {
            [0] = { {0,0,1}, {1,1,1}, {0,0,0} },
            [1] = { {0,1,0}, {0,1,0}, {0,1,1} },
            [2] = { {0,0,0}, {1,1,1}, {1,0,0} },
            [3] = { {1,1,0}, {0,1,0}, {0,1,0} }
        },
        size = 3
    },
    O = {
        color = "4",
        char = "[]",
        shape = {
            [0] = { {1,1}, {1,1} },
            [1] = { {1,1}, {1,1} },
            [2] = { {1,1}, {1,1} },
            [3] = { {1,1}, {1,1} }
        },
        size = 2
    },
    S = {
        color = "5",
        char = "[]",
        shape = {
            [0] = { {0,1,1}, {1,1,0}, {0,0,0} },
            [1] = { {0,1,0}, {0,1,1}, {0,0,1} },
            [2] = { {0,0,0}, {0,1,1}, {1,1,0} },
            [3] = { {1,0,0}, {1,1,0}, {0,1,0} }
        },
        size = 3
    },
    T = {
        color = "a",
        char = "[]",
        shape = {
            [0] = { {0,1,0}, {1,1,1}, {0,0,0} },
            [1] = { {0,1,0}, {0,1,1}, {0,0,0} },
            [2] = { {0,0,0}, {1,1,1}, {0,1,0} },
            [3] = { {0,1,0}, {1,1,0}, {0,1,0} }
        },
        size = 3
    },
    Z = {
        color = "e",
        char = "[]",
        shape = {
            [0] = { {1,1,0}, {0,1,1}, {0,0,0} },
            [1] = { {0,0,1}, {0,1,1}, {0,1,0} },
            [2] = { {0,0,0}, {1,1,0}, {0,1,1} },
            [3] = { {0,1,0}, {1,1,0}, {1,0,0} }
        },
        size = 3
    }
}

local BOARD_WIDTH = 10
local BOARD_HEIGHT = 20

local Game = {
    state = "MENU",
    board = {},
    bag = {},
    nextQueue = {},
    holdPiece = nil,
    canHold = true,
    currentPiece = nil,
    curX = 4,
    curY = 1,
    curRot = 0,
    score = 0,
    lines = 0,
    level = 1,
    combo = -1,
    backToBack = false,
    dropTimer = 0,
    lockTimer = 0,
    isLocking = false,
    bannerText = "",
    bannerTimer = 0,
    bannerColor = "4"
}

local runMainMenu, runGameLoop

local function getNextPiece()
    if #Game.bag == 0 then
        local pool = { "I", "J", "L", "O", "S", "T", "Z" }
        while #pool > 0 do
            local idx = math.random(1, #pool)
            table.insert(Game.bag, pool[idx])
            table.remove(pool, idx)
        end
    end
    return table.remove(Game.bag, 1)
end

local function spawnPiece(pieceType)
    Game.currentPiece = pieceType or table.remove(Game.nextQueue, 1)
    table.insert(Game.nextQueue, getNextPiece())
    
    local def = TETROMINOES[Game.currentPiece]
    Game.curRot = 0
    Game.curX = math.floor((BOARD_WIDTH - def.size) / 2) + 1
    Game.curY = (Game.currentPiece == "I") and -1 or 0
    Game.lockTimer = 0
    Game.isLocking = false
    Game.canHold = true
end

local function checkCollision(pieceType, rot, gridX, gridY)
    local def = TETROMINOES[pieceType]
    local matrix = def.shape[rot]
    for r = 1, def.size do
        for c = 1, def.size do
            if matrix[r][c] == 1 then
                local bx = gridX + c - 1
                local by = gridY + r - 1
                
                if bx < 1 or bx > BOARD_WIDTH or by > BOARD_HEIGHT then
                    return true
                end
                
                if by >= 1 and Game.board[by] and Game.board[by][bx] ~= nil then
                    return true
                end
            end
        end
    end
    return false
end

local function tryRotate(dir)
    local newRot = (Game.curRot + dir) % 4
    local kicks = { {0, 0}, {-1, 0}, {1, 0}, {0, -1}, {-1, -1}, {1, -1} }
    
    for _, kick in ipairs(kicks) do
        local testX = Game.curX + kick[1]
        local testY = Game.curY + kick[2]
        if not checkCollision(Game.currentPiece, newRot, testX, testY) then
            Game.curRot = newRot
            Game.curX = testX
            Game.curY = testY
            playSoundFX("rotate")
            return true
        end
    end
    return false
end

local function getGhostY()
    local ghostY = Game.curY
    while not checkCollision(Game.currentPiece, Game.curRot, Game.curX, ghostY + 1) do
        ghostY = ghostY + 1
    end
    return ghostY
end

local function lockPiece()
    local def = TETROMINOES[Game.currentPiece]
    local matrix = def.shape[Game.curRot]
    local isGameOver = false
    
    for r = 1, def.size do
        for c = 1, def.size do
            if matrix[r][c] == 1 then
                local bx = Game.curX + c - 1
                local by = Game.curY + r - 1
                if by < 1 then
                    isGameOver = true
                else
                    Game.board[by][bx] = def.color
                end
            end
        end
    end
    
    playSoundFX("lock")
    
    if isGameOver then
        Game.state = "GAMEOVER"
        playSoundFX("gameover")
        return
    end
    
    local clearedLines = 0
    local y = BOARD_HEIGHT
    while y >= 1 do
        local full = true
        for x = 1, BOARD_WIDTH do
            if Game.board[y][x] == nil then
                full = false
                break
            end
        end
        
        if full then
            clearedLines = clearedLines + 1
            table.remove(Game.board, y)
            local emptyRow = {}
            for x = 1, BOARD_WIDTH do emptyRow[x] = nil end
            table.insert(Game.board, 1, emptyRow)
        else
            y = y - 1
        end
    end
    
    if clearedLines > 0 then
        Game.combo = Game.combo + 1
        local lineScores = { [1] = 100, [2] = 300, [3] = 500, [4] = 800 }
        local baseScore = (lineScores[clearedLines] or 100) * Game.level
        
        if clearedLines == 4 then
            if Game.backToBack then
                baseScore = math.floor(baseScore * 1.5)
                Game.bannerText = "B2B TETRIS!"
                Game.bannerColor = "e"
            else
                Game.bannerText = "TETRIS!"
                Game.bannerColor = "4"
            end
            Game.backToBack = true
            playSoundFX("tetris")
        else
            Game.backToBack = false
            if clearedLines == 1 then
                Game.bannerText = "SINGLE"
                Game.bannerColor = "3"
                playSoundFX("clear_1")
            elseif clearedLines == 2 then
                Game.bannerText = "DOUBLE!"
                Game.bannerColor = "5"
                playSoundFX("clear_2")
            elseif clearedLines == 3 then
                Game.bannerText = "TRIPLE!"
                Game.bannerColor = "1"
                playSoundFX("clear_3")
            end
        end
        
        if Game.combo > 0 then
            baseScore = baseScore + (50 * Game.combo * Game.level)
            Game.bannerText = Game.bannerText .. " (" .. Game.combo .. " Combo)"
        end
        
        Game.bannerTimer = 2.0
        Game.score = Game.score + baseScore
        Game.lines = Game.lines + clearedLines
        
        local newLevel = math.floor(Game.lines / 10) + Settings.startingLevel
        if newLevel > Game.level then
            Game.level = newLevel
            playSoundFX("level_up")
        end
    else
        Game.combo = -1
    end
    
    if Game.score > Settings.highScore then
        Settings.highScore = Game.score
    end
    
    spawnPiece()
    if checkCollision(Game.currentPiece, Game.curRot, Game.curX, Game.curY) then
        Game.state = "GAMEOVER"
        playSoundFX("gameover")
    end
end

local function initGame()
    Game.board = {}
    for y = 1, BOARD_HEIGHT do
        Game.board[y] = {}
        for x = 1, BOARD_WIDTH do
            Game.board[y][x] = nil
        end
    end
    
    Game.bag = {}
    Game.nextQueue = {}
    for _ = 1, 3 do
        table.insert(Game.nextQueue, getNextPiece())
    end
    
    Game.holdPiece = nil
    Game.canHold = true
    Game.score = 0
    Game.lines = 0
    Game.level = Settings.startingLevel
    Game.combo = -1
    Game.backToBack = false
    Game.dropTimer = 0
    Game.bannerText = ""
    Game.bannerTimer = 0
    
    spawnPiece()
end

-- =============================================================================
--                             SCREEN RENDERING
-- =============================================================================

local TETRIS_BANNER = {
    " _____ _____ _____ ____  ___ ____  ",
    "|_   _| ____|_   _|  _ \\|_ _/ ___| ",
    "  | | |  _|   | | | |_) || |\\___ \\ ",
    "  | | | |___  | | |  _ < | | ___) |",
    "  |_| |_____| |_| |_| \\_\\___|____/ "
}

local function drawTetrisLogo(centerY)
    local bannerW = #TETRIS_BANNER[1]
    local startX = math.floor((screenW - bannerW) / 2) + 1
    local colorsArr = { "e", "1", "4", "5", "9" }
    
    for i, line in ipairs(TETRIS_BANNER) do
        local y = centerY + i - 1
        local fg = colorsArr[i] or "4"
        drawText(startX, y, line, fg, "f")
    end
end

local function drawMiniPiece(pieceType, startX, startY, fgColor)
    if not pieceType then return end
    local def = TETROMINOES[pieceType]
    local matrix = def.shape[0]
    for r = 1, def.size do
        for c = 1, def.size do
            if matrix[r][c] == 1 then
                drawText(startX + (c - 1) * 2, startY + r - 1, "[]", fgColor or def.color, "f")
            end
        end
    end
end

-- Render In-Game Board with Interactive Touch Buttons
local function renderGameScreen()
    clearBuffer("0", "f")
    clearButtons()
    
    local boardPixelW = BOARD_WIDTH * 2
    local boardPixelH = BOARD_HEIGHT
    local startX = math.floor((screenW - boardPixelW) / 2)
    local startY = math.max(2, math.floor((screenH - boardPixelH) / 2))
    
    -- 1. Left Section: HOLD Box, STATS & D-Pad Touch Buttons
    local leftBoxW = 16
    local leftBoxX = math.max(2, startX - leftBoxW - 3)
    
    -- HOLD Box
    drawText(leftBoxX, startY, "+-- [ HOLD ] ---+", "7", "f")
    for y = 1, 3 do
        drawText(leftBoxX, startY + y, "|               |", "7", "f")
    end
    drawText(leftBoxX, startY + 4, "+---------------+", "7", "f")
    
    if Game.holdPiece then
        drawMiniPiece(Game.holdPiece, leftBoxX + 4, startY + 1, Game.canHold and nil or "8")
    end
    
    -- HOLD Button
    registerButton("BTN_HOLD", leftBoxX, startY + 5, leftBoxW + 1, 2, "[ HOLD ]", "0", "3", "b")
    
    -- STATS Box
    local statsY = startY + 8
    drawText(leftBoxX, statsY, "+-- [ STATS ] --+", "7", "f")
    drawText(leftBoxX, statsY + 1, "| SCORE:        |", "7", "f")
    drawText(leftBoxX + 2, statsY + 2, string.format("%-12d", Game.score), "4", "f")
    drawText(leftBoxX, statsY + 3, "| LINES:        |", "7", "f")
    drawText(leftBoxX + 2, statsY + 4, string.format("%-12d", Game.lines), "3", "f")
    drawText(leftBoxX, statsY + 5, "| LEVEL:        |", "7", "f")
    drawText(leftBoxX + 2, statsY + 6, string.format("%-12d", Game.level), "e", "f")
    drawText(leftBoxX, statsY + 7, "+---------------+", "7", "f")
    
    -- Movement Touch Buttons: < LEFT / RIGHT > and v SOFT DROP v
    local moveY = statsY + 9
    registerButton("BTN_LEFT", leftBoxX, moveY, 8, 2, "< LEFT", "0", "7", "4")
    registerButton("BTN_RIGHT", leftBoxX + 9, moveY, 8, 2, "RIGHT >", "0", "7", "4")
    registerButton("BTN_SOFT", leftBoxX, moveY + 3, leftBoxW + 1, 2, "v SOFT DROP v", "0", "8", "7")
    
    -- 2. Center Section: Board Frame & Grid
    drawText(startX - 1, startY - 1, "+" .. string.rep("-", boardPixelW) .. "+", "0", "f")
    for by = 1, BOARD_HEIGHT do
        drawText(startX - 1, startY + by - 1, "|", "0", "f")
        drawText(startX + boardPixelW, startY + by - 1, "|", "0", "f")
        
        for bx = 1, BOARD_WIDTH do
            local cell = Game.board[by][bx]
            local px = startX + (bx - 1) * 2
            local py = startY + by - 1
            if cell then
                drawText(px, py, "[]", cell, "f")
            else
                local gridChar = Settings.gridLines and " ." or "  "
                drawText(px, py, gridChar, "8", "f")
            end
        end
    end
    drawText(startX - 1, startY + BOARD_HEIGHT, "+" .. string.rep("=", boardPixelW) .. "+", "0", "f")
    
    -- Ghost Piece Projection
    if Settings.ghostPiece and Game.currentPiece then
        local ghostY = getGhostY()
        local def = TETROMINOES[Game.currentPiece]
        local matrix = def.shape[Game.curRot]
        for r = 1, def.size do
            for c = 1, def.size do
                if matrix[r][c] == 1 then
                    local bx = Game.curX + c - 1
                    local by = ghostY + r - 1
                    if by >= 1 and by <= BOARD_HEIGHT and bx >= 1 and bx <= BOARD_WIDTH then
                        local px = startX + (bx - 1) * 2
                        local py = startY + by - 1
                        drawText(px, py, "::", "8", "f")
                    end
                end
            end
        end
    end
    
    -- Active Falling Piece
    if Game.currentPiece then
        local def = TETROMINOES[Game.currentPiece]
        local matrix = def.shape[Game.curRot]
        for r = 1, def.size do
            for c = 1, def.size do
                if matrix[r][c] == 1 then
                    local bx = Game.curX + c - 1
                    local by = Game.curY + r - 1
                    if by >= 1 and by <= BOARD_HEIGHT and bx >= 1 and bx <= BOARD_WIDTH then
                        local px = startX + (bx - 1) * 2
                        local py = startY + by - 1
                        drawText(px, py, "[]", def.color, "f")
                    end
                end
            end
        end
    end
    
    -- 3. Right Section: NEXT Queue & Action Buttons
    local rightBoxW = 16
    local rightBoxX = startX + boardPixelW + 3
    
    drawText(rightBoxX, startY, "+-- [ NEXT ] ---+", "7", "f")
    for y = 1, 9 do
        drawText(rightBoxX, startY + y, "|               |", "7", "f")
    end
    drawText(rightBoxX, startY + 10, "+---------------+", "7", "f")
    
    for i = 1, math.min(2, #Game.nextQueue) do
        local piece = Game.nextQueue[i]
        local slotY = startY + 1 + (i - 1) * 4
        drawMiniPiece(piece, rightBoxX + 4, slotY)
    end
    
    -- Right Action Touch Buttons: ROTATE, CCW, HARD DROP, PAUSE
    local actY = startY + 12
    registerButton("BTN_ROT_CW", rightBoxX, actY, 8, 2, "ROTATE", "0", "e", "1")
    registerButton("BTN_ROT_CCW", rightBoxX + 9, actY, 8, 2, "CCW", "0", "a", "5")
    registerButton("BTN_HARD", rightBoxX, actY + 3, rightBoxW + 1, 2, "HARD DROP", "0", "4", "e")
    registerButton("BTN_PAUSE", rightBoxX, actY + 6, rightBoxW + 1, 2, "PAUSE", "0", "8", "7")
    
    -- Event Banner Messages
    if Game.bannerTimer > 0 and #Game.bannerText > 0 then
        drawCenteredText(startY - 2, ">>> " .. Game.bannerText .. " <<<", Game.bannerColor, "f")
    end
    
    -- Render All Touch Buttons
    drawRegisteredButtons()
    
    -- Header Title
    drawCenteredText(1, "--- TETRIS CC: TWEAKED ---", "3", "f")
end

-- Main Menu
runMainMenu = function()
    local selectedIndex = 1
    local menuItems = {
        { text = "MARATHON (START)", action = "START" },
        { text = "SELECT LEVEL", action = "LEVEL_SELECT" },
        { text = "HOW TO PLAY", action = "CONTROLS" },
        { text = "SETTINGS", action = "SETTINGS" },
        { text = "HIGH SCORES", action = "SCORES" },
        { text = "CREDITS", action = "CREDITS" },
        { text = "QUIT TO SHELL", action = "QUIT" }
    }
    
    local animTick = 0
    local menuTimer = os.startTimer(0.1)
    local bgPieces = {
        { x = 4, y = 3, type = "T", col = "a" },
        { x = 7, y = 12, type = "I", col = "9" },
        { x = screenW - 8, y = 5, type = "L", col = "1" },
        { x = screenW - 6, y = 14, type = "O", col = "4" }
    }
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        
        animTick = animTick + 1
        
        -- 1. Animated Falling Background Tetrominoes
        for _, bp in ipairs(bgPieces) do
            drawText(bp.x, bp.y, "[##]", bp.col, "0")
            drawText(bp.x, bp.y + 1, "[##]", bp.col, "0")
        end
        
        drawTetrisLogo(2)
        
        local subtitle = isMonitor and "-- RUNNING ON LEFT MONITOR --" or "-- CC: TWEAKED EDITION --"
        local subCol = (animTick % 4 < 2) and "e" or "7"
        drawCenteredText(8, subtitle, subCol, "f")
        
        local btnW = 28
        local btnH = 2
        local startX = math.floor((screenW - btnW) / 2) + 1
        local startY = 10
        
        for i, item in ipairs(menuItems) do
            local y = startY + (i - 1) * 2
            if y + btnH - 1 <= screenH - 1 then
                local isSelected = (i == selectedIndex)
                local fg = isSelected and "0" or "7"
                local bg = isSelected and "e" or "8"
                registerButton("MENU_" .. i, startX, y, btnW, btnH, item.text, fg, bg, "4")
            end
        end
        
        drawRegisteredButtons()
        
        local pulseInd = (animTick % 4 < 2) and ">> [CLICK / TOUCH BUTTONS] <<" or "-- [CLICK / TOUCH BUTTONS] --"
        drawCenteredText(screenH, pulseInd .. " or Use Keyboard", "8", "f")
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == menuTimer then
            menuTimer = os.startTimer(0.12)
            
            -- Move background pieces down
            for _, bp in ipairs(bgPieces) do
                bp.y = bp.y + 1
                if bp.y > screenH - 2 then
                    bp.y = 2
                    bp.x = math.random(1, 2) == 1 and math.random(2, 8) or math.random(screenW - 9, screenW - 4)
                end
            end
            
        elseif event == "key" then
            if p1 == keys.up or p1 == keys.w then
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #menuItems end
                playSoundFX("click")
            elseif p1 == keys.down or p1 == keys.s then
                selectedIndex = selectedIndex + 1
                if selectedIndex > #menuItems then selectedIndex = 1 end
                playSoundFX("click")
            elseif p1 == keys.enter or p1 == keys.space then
                playSoundFX("click")
                return menuItems[selectedIndex].action
            elseif p1 == keys.q then
                return "QUIT"
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local clickedId = checkButtonClicked(p2, p3)
            if clickedId then
                playSoundFX("click")
                for i = 1, #menuItems do
                    if clickedId == "MENU_" .. i then
                        selectedIndex = i
                        return menuItems[i].action
                    end
                end
            end
        end
    end
end

-- Starting Level Selection Screen
local function runLevelSelect()
    local selectedLevel = Settings.startingLevel
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== SELECT STARTING LEVEL ===", "4", "f")
        
        local gridCols = 5
        local btnW = 12
        local btnH = 2
        local startX = math.floor((screenW - (gridCols * (btnW + 2))) / 2) + 1
        local startY = 11
        
        for lvl = 1, 10 do
            local col = (lvl - 1) % gridCols
            local row = math.floor((lvl - 1) / gridCols)
            local bx = startX + col * (btnW + 2)
            local by = startY + row * (btnH + 1)
            
            local isSel = (lvl == selectedLevel)
            registerButton("LVL_" .. lvl, bx, by, btnW, btnH, "LEVEL " .. lvl, isSel and "0" or "7", isSel and "e" or "8", "4")
        end
        
        local confirmX = math.floor((screenW - 20) / 2) + 1
        registerButton("CONFIRM_LVL", confirmX, startY + 8, 20, 2, "START GAME", "0", "5", "4")
        registerButton("BACK_LVL", confirmX, startY + 11, 20, 2, "BACK TO MENU", "0", "8", "e")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.up or p1 == keys.w or p1 == keys.left or p1 == keys.a then
                selectedLevel = math.max(1, selectedLevel - 1)
                playSoundFX("click")
            elseif p1 == keys.down or p1 == keys.s or p1 == keys.right or p1 == keys.d then
                selectedLevel = math.min(10, selectedLevel + 1)
                playSoundFX("click")
            elseif p1 == keys.enter or p1 == keys.space then
                Settings.startingLevel = selectedLevel
                playSoundFX("click")
                return "START"
            elseif p1 == keys.escape or p1 == keys.q then
                return "MENU"
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local clickedId = checkButtonClicked(p2, p3)
            if clickedId then
                playSoundFX("click")
                if clickedId == "CONFIRM_LVL" then
                    Settings.startingLevel = selectedLevel
                    return "START"
                elseif clickedId == "BACK_LVL" then
                    return "MENU"
                else
                    for lvl = 1, 10 do
                        if clickedId == "LVL_" .. lvl then
                            selectedLevel = lvl
                            Settings.startingLevel = lvl
                        end
                    end
                end
            end
        end
    end
end

-- Controls / Instructions Screen
local function runControlsScreen()
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== HOW TO PLAY ===", "4", "f")
        
        local controls = {
            { "[ < LEFT ] / [ RIGHT > ]", "Move piece left / right" },
            { "[ ROTATE ] / [ CCW ]", "Rotate piece (SRS Wall Kicks)" },
            { "[ HARD DROP ]", "Instant drop & lock to bottom" },
            { "[ v SOFT DROP v ]", "Fast drop while pressed" },
            { "[ HOLD ]", "Swap piece into hold reserve" },
            { "[ PAUSE ]", "Pause / resume active game" }
        }
        
        local startY = 11
        for i, c in ipairs(controls) do
            local line = string.format("%-28s : %s", c[1], c[2])
            drawCenteredText(startY + i - 1, line, "0", "f")
        end
        
        local btnW = 24
        local btnX = math.floor((screenW - btnW) / 2) + 1
        registerButton("BACK_CONTROLS", btnX, screenH - 3, btnW, 2, "<< BACK TO MENU >>", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            playSoundFX("click")
            return "MENU"
        end
    end
end

-- Settings Menu
local function runSettingsScreen()
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== SETTINGS ===", "4", "f")
        
        local options = {
            { id = "SET_SOUND", name = "Sound FX (Speaker)", val = Settings.sound and "ENABLED" or "DISABLED" },
            { id = "SET_GHOST", name = "Ghost Piece Preview", val = Settings.ghostPiece and "ON" or "OFF" },
            { id = "SET_GRID", name = "Board Grid Dots", val = Settings.gridLines and "ON" or "OFF" }
        }
        
        local btnW = 38
        local btnX = math.floor((screenW - btnW) / 2) + 1
        local startY = 11
        
        for i, opt in ipairs(options) do
            local y = startY + (i - 1) * 3
            local label = string.format("%-22s: [%s]", opt.name, opt.val)
            registerButton(opt.id, btnX, y, btnW, 2, label, "0", "7", "e")
        end
        
        registerButton("BACK_SETTINGS", btnX, startY + 10, btnW, 2, "<< SAVE & BACK >>", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.escape or p1 == keys.q or p1 == keys.enter or p1 == keys.space then
                return "MENU"
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local clickedId = checkButtonClicked(p2, p3)
            if clickedId then
                playSoundFX("click")
                if clickedId == "SET_SOUND" then
                    Settings.sound = not Settings.sound
                elseif clickedId == "SET_GHOST" then
                    Settings.ghostPiece = not Settings.ghostPiece
                elseif clickedId == "SET_GRID" then
                    Settings.gridLines = not Settings.gridLines
                elseif clickedId == "BACK_SETTINGS" then
                    return "MENU"
                end
            end
        end
    end
end

-- High Scores Screen
local function runScoresScreen()
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== HIGH SCORES ===", "4", "f")
        
        drawCenteredText(12, "TOP RECORD SCORE : " .. string.format("%07d", Settings.highScore), "e", "f")
        drawCenteredText(14, "MAX LEVEL REACHED: " .. tostring(Settings.startingLevel), "3", "f")
        
        local btnW = 24
        local btnX = math.floor((screenW - btnW) / 2) + 1
        registerButton("BACK_SCORES", btnX, screenH - 3, btnW, 2, "<< BACK TO MENU >>", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            playSoundFX("click")
            return "MENU"
        end
    end
end

-- Credits Screen
local function runCreditsScreen()
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== ABOUT TETRIS ===", "4", "f")
        
        local lines = {
            "TETRIS CC: Tweaked Touch Edition",
            "Screen Output: " .. (isMonitor and ("Monitor on '" .. targetSide .. "'") or "Computer Terminal"),
            "",
            "Original Tetris (c) Alexey Pajitnov",
            "Engine: Pure Lua SRS with Touch Screen Controls",
            "Audio: ComputerCraft Speaker API",
            "",
            "Enjoy the stack and clear those Tetris lines!"
        }
        
        local startY = 11
        for i, l in ipairs(lines) do
            drawCenteredText(startY + i - 1, l, (i == 1 or i == 8) and "4" or "7", "f")
        end
        
        local btnW = 24
        local btnX = math.floor((screenW - btnW) / 2) + 1
        registerButton("BACK_CREDITS", btnX, screenH - 3, btnW, 2, "<< BACK TO MENU >>", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            playSoundFX("click")
            return "MENU"
        end
    end
end

-- Pause Menu
local function runPauseMenu()
    local pauseOptions = {
        { id = "PAUSE_RESUME", text = "RESUME GAME", action = "RESUME" },
        { id = "PAUSE_RESTART", text = "RESTART GAME", action = "RESTART" },
        { id = "PAUSE_MENU", text = "MAIN MENU", action = "MENU" },
        { id = "PAUSE_QUIT", text = "QUIT TO SHELL", action = "QUIT" }
    }
    
    while true do
        clearButtons()
        local boxW = 32
        local boxH = 12
        local startX = math.floor((screenW - boxW) / 2)
        local startY = math.floor((screenH - boxH) / 2)
        
        for y = startY, startY + boxH do
            drawText(startX, y, string.rep(" ", boxW), "0", "8")
        end
        
        drawText(startX + 10, startY + 1, "=== PAUSED ===", "4", "8")
        
        for i, opt in ipairs(pauseOptions) do
            local y = startY + 2 + (i - 1) * 2
            registerButton(opt.id, startX + 3, y, boxW - 6, 2, opt.text, "0", "7", "e")
        end
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.p or p1 == keys.escape or p1 == keys.enter or p1 == keys.space then
                return "RESUME"
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local clickedId = checkButtonClicked(p2, p3)
            if clickedId then
                playSoundFX("click")
                for _, opt in ipairs(pauseOptions) do
                    if clickedId == opt.id then
                        return opt.action
                    end
                end
            end
        end
    end
end

-- Game Over Screen
local function runGameOverScreen()
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawTetrisLogo(2)
        drawCenteredText(8, "=== GAME OVER ===", "e", "f")
        
        local startY = 11
        drawCenteredText(startY, "FINAL SCORE : " .. string.format("%07d", Game.score), "4", "f")
        drawCenteredText(startY + 2, "LINES CLEARED: " .. tostring(Game.lines), "3", "f")
        drawCenteredText(startY + 4, "LEVEL REACHED: " .. tostring(Game.level), "5", "f")
        
        local btnW = 26
        local btnX = math.floor((screenW - btnW) / 2) + 1
        registerButton("RETRY_GAME", btnX, startY + 7, btnW, 2, "PLAY AGAIN", "0", "e", "4")
        registerButton("QUIT_GAME", btnX, startY + 10, btnW, 2, "MAIN MENU", "0", "8", "7")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.enter or p1 == keys.space then
                playSoundFX("click")
                return "START"
            elseif p1 == keys.escape or p1 == keys.q then
                return "MENU"
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local clickedId = checkButtonClicked(p2, p3)
            if clickedId == "RETRY_GAME" then
                playSoundFX("click")
                return "START"
            elseif clickedId == "QUIT_GAME" then
                playSoundFX("click")
                return "MENU"
            end
        end
    end
end

-- =============================================================================
--                             MAIN GAME LOOP
-- =============================================================================

runGameLoop = function()
    initGame()
    Game.state = "PLAYING"
    
    local timerId = os.startTimer(0.05)
    local lastTime = os.epoch("utc") / 1000.0
    
    local keysDown = {}
    local dasTimer = 0
    local dasKey = nil
    
    local function executeAction(act)
        if act == "LEFT" then
            if not checkCollision(Game.currentPiece, Game.curRot, Game.curX - 1, Game.curY) then
                Game.curX = Game.curX - 1
                playSoundFX("move")
            end
        elseif act == "RIGHT" then
            if not checkCollision(Game.currentPiece, Game.curRot, Game.curX + 1, Game.curY) then
                Game.curX = Game.curX + 1
                playSoundFX("move")
            end
        elseif act == "ROT_CW" then
            tryRotate(1)
        elseif act == "ROT_CCW" then
            tryRotate(-1)
        elseif act == "SOFT" then
            if not checkCollision(Game.currentPiece, Game.curRot, Game.curX, Game.curY + 1) then
                Game.curY = Game.curY + 1
                Game.score = Game.score + 1
                playSoundFX("soft_drop")
            end
        elseif act == "HARD" then
            local dropCount = 0
            while not checkCollision(Game.currentPiece, Game.curRot, Game.curX, Game.curY + 1) do
                Game.curY = Game.curY + 1
                dropCount = dropCount + 1
            end
            Game.score = Game.score + (dropCount * 2)
            playSoundFX("hard_drop")
            lockPiece()
        elseif act == "HOLD" then
            if Game.canHold then
                local cur = Game.currentPiece
                if Game.holdPiece == nil then
                    Game.holdPiece = cur
                    spawnPiece()
                else
                    local temp = Game.holdPiece
                    Game.holdPiece = cur
                    spawnPiece(temp)
                end
                Game.canHold = false
                playSoundFX("hold")
            end
        elseif act == "PAUSE" then
            local pauseAct = runPauseMenu()
            if pauseAct == "RESTART" then
                initGame()
            elseif pauseAct == "MENU" then
                Game.state = "MENU"
            elseif pauseAct == "QUIT" then
                return "QUIT"
            end
            lastTime = os.epoch("utc") / 1000.0
            timerId = os.startTimer(0.05)
        end
    end
    
    while Game.state == "PLAYING" do
        renderGameScreen()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local curTime = os.epoch("utc") / 1000.0
        local dt = math.min(0.1, curTime - lastTime)
        lastTime = curTime
        
        if Game.bannerTimer > 0 then
            Game.bannerTimer = math.max(0, Game.bannerTimer - dt)
        end
        if activePressedTimer > 0 then
            activePressedTimer = math.max(0, activePressedTimer - dt)
            if activePressedTimer == 0 then
                activePressedId = nil
            end
        end
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.05)
            
            local dropInterval = math.max(0.06, (0.8 - ((Game.level - 1) * 0.045)))
            Game.dropTimer = Game.dropTimer + dt
            
            if dasKey then
                dasTimer = dasTimer + dt
                if dasTimer > 0.18 then
                    if dasKey == keys.left or dasKey == keys.a then
                        executeAction("LEFT")
                    elseif dasKey == keys.right or dasKey == keys.d then
                        executeAction("RIGHT")
                    elseif dasKey == keys.down or dasKey == keys.s then
                        executeAction("SOFT")
                    end
                end
            end
            
            if Game.dropTimer >= dropInterval then
                Game.dropTimer = 0
                if not checkCollision(Game.currentPiece, Game.curRot, Game.curX, Game.curY + 1) then
                    Game.curY = Game.curY + 1
                    Game.isLocking = false
                    Game.lockTimer = 0
                else
                    Game.isLocking = true
                end
            end
            
            if Game.isLocking then
                Game.lockTimer = Game.lockTimer + dt
                if Game.lockTimer >= 0.45 then
                    lockPiece()
                end
            end
            
        elseif event == "key" then
            keysDown[p1] = true
            dasKey = p1
            dasTimer = 0
            
            if p1 == keys.left or p1 == keys.a then
                executeAction("LEFT")
            elseif p1 == keys.right or p1 == keys.d then
                executeAction("RIGHT")
            elseif p1 == keys.up or p1 == keys.w or p1 == keys.x then
                executeAction("ROT_CW")
            elseif p1 == keys.z then
                executeAction("ROT_CCW")
            elseif p1 == keys.down or p1 == keys.s then
                executeAction("SOFT")
            elseif p1 == keys.space then
                executeAction("HARD")
            elseif p1 == keys.c or p1 == keys.leftShift or p1 == keys.rightShift then
                executeAction("HOLD")
            elseif p1 == keys.p or p1 == keys.escape then
                local res = executeAction("PAUSE")
                if res == "QUIT" then return "QUIT" end
            end
            
        elseif event == "key_up" then
            keysDown[p1] = nil
            if dasKey == p1 then
                dasKey = nil
                dasTimer = 0
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local clickedId = checkButtonClicked(mx, my)
            
            if clickedId == "BTN_LEFT" then
                executeAction("LEFT")
            elseif clickedId == "BTN_RIGHT" then
                executeAction("RIGHT")
            elseif clickedId == "BTN_ROT_CW" then
                executeAction("ROT_CW")
            elseif clickedId == "BTN_ROT_CCW" then
                executeAction("ROT_CCW")
            elseif clickedId == "BTN_SOFT" then
                executeAction("SOFT")
            elseif clickedId == "BTN_HARD" then
                executeAction("HARD")
            elseif clickedId == "BTN_HOLD" then
                executeAction("HOLD")
            elseif clickedId == "BTN_PAUSE" then
                local res = executeAction("PAUSE")
                if res == "QUIT" then return "QUIT" end
            else
                -- Tap directly on board grid: rotate piece
                local boardPixelW = BOARD_WIDTH * 2
                local startX = math.floor((screenW - boardPixelW) / 2)
                if mx >= startX and mx <= startX + boardPixelW then
                    executeAction("ROT_CW")
                end
            end
        end
    end
    
    if Game.state == "GAMEOVER" then
        return runGameOverScreen()
    end
    
    return "MENU"
end

-- =============================================================================
--                                ENTRY POINT
-- =============================================================================

local function main()
    display.clear()
    if display.setCursorBlink then display.setCursorBlink(false) end
    initBuffer()
    
    local nextAction = "MENU"
    
    while nextAction ~= "QUIT" do
        if nextAction == "MENU" then
            nextAction = runMainMenu()
        elseif nextAction == "LEVEL_SELECT" then
            nextAction = runLevelSelect()
        elseif nextAction == "CONTROLS" then
            nextAction = runControlsScreen()
        elseif nextAction == "SETTINGS" then
            nextAction = runSettingsScreen()
        elseif nextAction == "SCORES" then
            nextAction = runScoresScreen()
        elseif nextAction == "CREDITS" then
            nextAction = runCreditsScreen()
        elseif nextAction == "START" then
            nextAction = runGameLoop()
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("TETRIS Closed. Thanks for playing!")
    else
        print("Thanks for playing TETRIS CC: Tweaked!")
    end
    
    if isMonitor then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("TETRIS finished. Monitor cleared.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("TETRIS Error: " .. tostring(err))
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.setCursorPos(1, 1)
    print("TETRIS Error: " .. tostring(err))
end
