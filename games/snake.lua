--[[
================================================================================
                    SNAKE 2D DELUXE for CC: Tweaked
      Customizable Retro Arcade Edition with Touch Controls & Power-ups
================================================================================
  Features:
    * Custom Settings & Difficulty Configurator:
        - Apples on Board: 1, 2, 3, 5, or 10 apples simultaneously!
        - Speed Presets: Slow (0.16s), Normal (0.12s), Fast (0.08s), Hyper (0.05s)
        - Tail Growth Rate: +1, +2, or +3 per apple
        - Power-up Frequency: Off, Rare, Normal, Chaos
        - Speed Acceleration (On/Off)
        - 5 Custom Snake Skins (Neon Viper, Dragon Flame, Cyber Matrix, Royal Gold, Shadow)
    * Multiple Game Modes:
        1. [CLASSIC] Solid border walls, classic arcade snake
        2. [PORTAL] Screen wrap-around (infinite torus field)
        3. [MAZE] Brick obstacles, pillars & maze traps
        4. [RUSH] Time Attack countdown challenge
    * Power-ups & Special Fruits:
        - [A] Red Apple (Configurable count on field)
        - [G] Golden Fruit (+50 pts, rare timed bonus)
        - [D] Diamond Star (+100 pts + Ghost Tail for 5s)
        - [S] Snail Freeze (Slows down speed for 6s)
        - [X] Tail Cutter (Trims length by 3 segments)
    * Touchscreen & Dual Input Controls:
        - On-screen D-Pad: [ ^ UP ], [ < LEFT ], [ RGHT > ], [ v DOWN ]
        - Action Buttons: [ SPEED BOOST ], [ PAUSE ], [ LOBBY ]
        - Direct quadrant tap on canvas
    * Output: External Monitor on the LEFT ("left") or Terminal
    * Dynamic Sound FX via ComputerCraft Speaker peripheral
    * Persistent Auto-Save (High Scores + Custom Settings)
    * 100% Clean ASCII English UI (Zero font / encoding glitches)
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
    printError("SNAKE DELUXE requires an Advanced Computer or Color Monitor!")
    return
end

local screenW, screenH = display.getSize()

-- Sound FX via CC Speaker
local speaker = peripheral and peripheral.find and peripheral.find("speaker")

-- =============================================================================
--                             CONFIG & SKINS
-- =============================================================================

local Config = {
    appleCount = 2,       -- 1, 2, 3, 5, 10
    speedPreset = 2,      -- 1: Slow, 2: Normal, 3: Fast, 4: Hyper
    speedGrowth = true,   -- Speed up as snake eats apples
    powerupFreq = 2,      -- 0: Off, 1: Rare, 2: Normal, 3: Chaos
    growthRate = 1,       -- 1: +1 seg, 2: +2 seg, 3: +3 seg
    sound = true,
    skinId = 1            -- 1: Neon, 2: Dragon, 3: Cyber, 4: Gold, 5: Shadow
}

local SPEED_VALUES = {
    [1] = { name = "Slow",   val = 0.16 },
    [2] = { name = "Normal", val = 0.12 },
    [3] = { name = "Fast",   val = 0.08 },
    [4] = { name = "Hyper",  val = 0.05 }
}

local POWERUP_NAMES = {
    [0] = "Disabled",
    [1] = "Rare (30s)",
    [2] = "Normal (15s)",
    [3] = "Chaos (7s)"
}

local Skins = {
    [1] = { name = "Neon Viper",    headChar = ">", headFg = "4", headBg = "5", bodyChar = "O", bodyFg1 = "5", bodyFg2 = "d" },
    [2] = { name = "Dragon Flame",  headChar = "#", headFg = "4", headBg = "e", bodyChar = "=", bodyFg1 = "e", bodyFg2 = "1" },
    [3] = { name = "Cyber Matrix",  headChar = "@", headFg = "0", headBg = "9", bodyChar = "*", bodyFg1 = "9", bodyFg2 = "3" },
    [4] = { name = "Royal Gold",    headChar = "$", headFg = "0", headBg = "4", bodyChar = "%", bodyFg1 = "4", bodyFg2 = "e" },
    [5] = { name = "Shadow Phantom",headChar = "X", headFg = "f", headBg = "a", bodyChar = "+", bodyFg1 = "a", bodyFg2 = "2" }
}

local function playSound(snd)
    if not speaker or not Config.sound then return end
    pcall(function()
        if snd == "click" then
            speaker.playNote("hat", 0.5, 14)
        elseif snd == "turn" then
            speaker.playNote("hat", 0.3, 18)
        elseif snd == "eat" then
            speaker.playNote("chime", 0.8, 14)
            speaker.playNote("bell", 0.6, 18)
        elseif snd == "eat_gold" then
            speaker.playNote("chime", 1.0, 18)
            speaker.playNote("flute", 0.8, 22)
            sleep(0.04)
            speaker.playNote("chime", 1.0, 24)
        elseif snd == "powerup" then
            speaker.playNote("bell", 0.9, 12)
            speaker.playNote("bell", 0.9, 16)
            speaker.playNote("bell", 0.9, 20)
        elseif snd == "die" then
            speaker.playNote("didgeridoo", 1.0, 4)
            speaker.playNote("bass", 0.8, 6)
        elseif snd == "pause" then
            speaker.playNote("snare", 0.6, 10)
        elseif snd == "highscore" then
            for n = 12, 24, 4 do
                speaker.playNote("chime", 1.0, n)
                sleep(0.04)
            end
        end
    end)
end

-- Double Buffering Graphics System
local Buffer = { chars = {}, fg = {}, bg = {} }

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

-- Touch Button Management
local TouchButtons = {}
local activePressedId = nil
local activePressedTimer = 0

local function clearButtons()
    TouchButtons = {}
end

local function registerButton(id, x, y, w, h, label, fg, bg, activeBg, hotkey)
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
        activeBg = activeBg or "e",
        hotkey = hotkey
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
            activePressedTimer = 0.1
            return btn.id
        end
    end
    return nil
end

-- Persistent Storage
local SAVE_FILE = "snake_save.txt"
local HighScores = {
    CLASSIC = 0,
    NOWALLS = 0,
    MAZE = 0,
    TIMEATTACK = 0
}

local function loadData()
    if fs.exists(SAVE_FILE) then
        local f = fs.open(SAVE_FILE, "r")
        if f then
            local str = f.readAll()
            f.close()
            local c, nw, m, ta, ac, sp, sg, pf, gr, sk = string.match(str, "(%d+):(%d+):(%d+):(%d+)|?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*)")
            if c then
                HighScores.CLASSIC = tonumber(c) or 0
                HighScores.NOWALLS = tonumber(nw) or 0
                HighScores.MAZE = tonumber(m) or 0
                HighScores.TIMEATTACK = tonumber(ta) or 0
            end
            if ac and #ac > 0 then Config.appleCount = tonumber(ac) or Config.appleCount end
            if sp and #sp > 0 then Config.speedPreset = tonumber(sp) or Config.speedPreset end
            if sg and #sg > 0 then Config.speedGrowth = (tonumber(sg) == 1) end
            if pf and #pf > 0 then Config.powerupFreq = tonumber(pf) or Config.powerupFreq end
            if gr and #gr > 0 then Config.growthRate = tonumber(gr) or Config.growthRate end
            if sk and #sk > 0 then Config.skinId = tonumber(sk) or Config.skinId end
        end
    end
end

local function saveData()
    local f = fs.open(SAVE_FILE, "w")
    if f then
        f.write(string.format("%d:%d:%d:%d|%d:%d:%d:%d:%d:%d",
            HighScores.CLASSIC, HighScores.NOWALLS, HighScores.MAZE, HighScores.TIMEATTACK,
            Config.appleCount, Config.speedPreset, Config.speedGrowth and 1 or 0, Config.powerupFreq, Config.growthRate, Config.skinId
        ))
        f.close()
    end
end

-- =============================================================================
--                             GAME STATE & LOGIC
-- =============================================================================

local Game = {
    state = "MENU", -- MENU, PLAYING, PAUSED, GAMEOVER
    mode = "CLASSIC",
    score = 0,
    applesEaten = 0,
    timeLeft = 60,
    speed = 0.12,
    baseSpeed = 0.12,
    boostActive = false,
    ghostTailTimer = 0,
    freezeTimer = 0,
    growthPending = 0,
    
    boardX = 2,
    boardY = 3,
    boardW = 32,
    boardH = 16,
    
    snake = {},
    dirX = 1,
    dirY = 0,
    nextDirX = 1,
    nextDirY = 0,
    
    fruits = {},
    powerups = {},
    obstacles = {}
}

-- Mazes
local function buildMazeObstacles()
    Game.obstacles = {}
    local bw, bh = Game.boardW, Game.boardH
    if Game.mode == "MAZE" then
        local midX = math.floor(bw / 2)
        local midY = math.floor(bh / 2)
        
        for x = midX - 4, midX + 4 do
            if x ~= midX then
                table.insert(Game.obstacles, { x = x, y = midY - 3 })
                table.insert(Game.obstacles, { x = x, y = midY + 3 })
            end
        end
        for y = 3, 6 do
            table.insert(Game.obstacles, { x = 6, y = y })
            table.insert(Game.obstacles, { x = bw - 5, y = y })
            table.insert(Game.obstacles, { x = 6, y = bh - y + 1 })
            table.insert(Game.obstacles, { x = bw - 5, y = bh - y + 1 })
        end
    end
end

local function isOccupied(x, y)
    for _, seg in ipairs(Game.snake) do
        if seg.x == x and seg.y == y then return true end
    end
    for _, obs in ipairs(Game.obstacles) do
        if obs.x == x and obs.y == y then return true end
    end
    for _, f in ipairs(Game.fruits) do
        if f.x == x and f.y == y then return true end
    end
    for _, p in ipairs(Game.powerups) do
        if p.x == x and p.y == y then return true end
    end
    return false
end

local function spawnFruit(fruitType)
    local tries = 0
    while tries < 100 do
        tries = tries + 1
        local rx = math.random(1, Game.boardW)
        local ry = math.random(1, Game.boardH)
        if not isOccupied(rx, ry) then
            if fruitType == "GOLD" then
                table.insert(Game.fruits, { x = rx, y = ry, type = "GOLD", char = "G", fg = "4", bg = "0", pts = 50, life = 12.0 })
            else
                table.insert(Game.fruits, { x = rx, y = ry, type = "APPLE", char = "A", fg = "e", bg = "0", pts = 10 })
            end
            return
        end
    end
end

local function ensureApples()
    local currentApples = 0
    for _, f in ipairs(Game.fruits) do
        if f.type == "APPLE" then currentApples = currentApples + 1 end
    end
    while currentApples < Config.appleCount do
        spawnFruit("APPLE")
        currentApples = currentApples + 1
    end
end

local function spawnPowerup()
    if Config.powerupFreq == 0 then return end
    local types = {
        { type = "STAR", char = "*", fg = "9", bg = "0", name = "Ghost Star" },
        { type = "SNAIL", char = "S", fg = "3", bg = "0", name = "Slow Snail" },
        { type = "CUTTER", char = "X", fg = "c", bg = "0", name = "Tail Cutter" }
    }
    local chosen = types[math.random(1, #types)]
    local tries = 0
    while tries < 100 do
        tries = tries + 1
        local rx = math.random(1, Game.boardW)
        local ry = math.random(1, Game.boardH)
        if not isOccupied(rx, ry) then
            table.insert(Game.powerups, { x = rx, y = ry, type = chosen.type, char = chosen.char, fg = chosen.fg, bg = chosen.bg, life = 10.0 })
            return
        end
    end
end

local function initGame(mode)
    Game.mode = mode or "CLASSIC"
    Game.score = 0
    Game.applesEaten = 0
    Game.timeLeft = (Game.mode == "TIMEATTACK") and 45 or 0
    
    local preset = SPEED_VALUES[Config.speedPreset] or SPEED_VALUES[2]
    Game.baseSpeed = (Game.mode == "TIMEATTACK") and math.min(0.09, preset.val) or preset.val
    Game.speed = Game.baseSpeed
    Game.boostActive = false
    Game.ghostTailTimer = 0
    Game.freezeTimer = 0
    Game.growthPending = 0
    
    -- Adjust Board size according to screen
    Game.boardX = 2
    Game.boardY = 3
    Game.boardW = math.max(20, screenW - 22)
    Game.boardH = math.max(12, screenH - 5)
    
    -- Snake starts in middle moving right
    local startX = math.floor(Game.boardW / 2)
    local startY = math.floor(Game.boardH / 2)
    Game.snake = {
        { x = startX, y = startY },
        { x = startX - 1, y = startY },
        { x = startX - 2, y = startY }
    }
    Game.dirX = 1
    Game.dirY = 0
    Game.nextDirX = 1
    Game.nextDirY = 0
    
    Game.fruits = {}
    Game.powerups = {}
    buildMazeObstacles()
    
    ensureApples()
    Game.state = "PLAYING"
end

-- Change Snake Direction
local function setDirection(dx, dy)
    -- Prevent reversing 180 degrees
    if (dx ~= 0 and Game.dirX ~= -dx) or (dy ~= 0 and Game.dirY ~= -dy) then
        Game.nextDirX = dx
        Game.nextDirY = dy
        playSound("turn")
    end
end

-- Render the Game Screen
local function renderGame()
    clearBuffer("0", "f")
    clearButtons()
    
    local curSkin = Skins[Config.skinId] or Skins[1]
    
    -- 1. Top Header Bar
    drawText(1, 1, string.rep(" ", screenW), "0", "7")
    drawText(2, 1, "SNAKE 2D DELUXE", "5", "7")
    drawText(19, 1, "| " .. Game.mode .. " [" .. curSkin.name .. "]", "0", "7")
    
    local scoreStr = string.format("SCORE: %05d", Game.score)
    drawText(screenW - #scoreStr - 18, 1, scoreStr, "4", "7")
    
    local hiStr = string.format("BEST: %05d", HighScores[Game.mode] or 0)
    drawText(screenW - #hiStr - 1, 1, hiStr, "e", "7")
    
    -- 2. Board Frame & Grid
    local bx, by = Game.boardX, Game.boardY
    local bw, bh = Game.boardW, Game.boardH
    
    local wallFg = (Game.mode == "NOWALLS") and "8" or "7"
    local wallBg = (Game.mode == "NOWALLS") and "7" or "8"
    
    local borderChar = (Game.mode == "NOWALLS") and "." or "="
    drawText(bx - 1, by - 1, "+" .. string.rep(borderChar, bw) .. "+", wallFg, wallBg)
    drawText(bx - 1, by + bh, "+" .. string.rep(borderChar, bw) .. "+", wallFg, wallBg)
    
    for y = 0, bh - 1 do
        drawText(bx - 1, by + y, (Game.mode == "NOWALLS" and ":" or "|"), wallFg, wallBg)
        drawText(bx + bw, by + y, (Game.mode == "NOWALLS" and ":" or "|"), wallFg, wallBg)
        
        local floorLine = ""
        local floorFg = ""
        local floorBg = ""
        for x = 1, bw do
            local dot = ((x + y) % 2 == 0) and "." or " "
            floorLine = floorLine .. dot
            floorFg = floorFg .. "8"
            floorBg = floorBg .. "0"
        end
        drawText(bx, by + y, floorLine, floorFg, floorBg)
    end
    
    -- 3. Draw Maze Obstacles
    for _, obs in ipairs(Game.obstacles) do
        drawText(bx + obs.x - 1, by + obs.y - 1, "#", "7", "8")
    end
    
    -- 4. Draw Fruits & Powerups
    for _, f in ipairs(Game.fruits) do
        drawText(bx + f.x - 1, by + f.y - 1, f.char, f.fg, f.bg)
    end
    for _, p in ipairs(Game.powerups) do
        drawText(bx + p.x - 1, by + p.y - 1, p.char, p.fg, p.bg)
    end
    
    -- 5. Draw Snake with Selected Skin
    for i, seg in ipairs(Game.snake) do
        local sx = bx + seg.x - 1
        local sy = by + seg.y - 1
        if i == 1 then
            local headChar = curSkin.headChar
            if headChar == ">" then
                if Game.dirX == 1 then headChar = ">"
                elseif Game.dirX == -1 then headChar = "<"
                elseif Game.dirY == 1 then headChar = "v"
                elseif Game.dirY == -1 then headChar = "^" end
            end
            local headFg = (Game.ghostTailTimer > 0) and "9" or curSkin.headFg
            local headBg = (Game.ghostTailTimer > 0) and "3" or curSkin.headBg
            drawText(sx, sy, headChar, headFg, headBg)
        else
            local bodyFg = (Game.ghostTailTimer > 0) and "3" or ((i % 2 == 0) and curSkin.bodyFg1 or curSkin.bodyFg2)
            drawText(sx, sy, curSkin.bodyChar, bodyFg, "0")
        end
    end
    
    -- 6. Right Sidebar Controls & Stats
    local sideX = bx + bw + 2
    
    drawText(sideX, by, "=== CONTROLS ===", "4", "f")
    
    -- D-Pad Touch Buttons
    local dpadY = by + 2
    registerButton("BTN_UP", sideX + 5, dpadY, 7, 2, " ^ UP ", "0", "5", "4", "up")
    registerButton("BTN_LEFT", sideX + 1, dpadY + 2, 7, 2, "< LEFT", "0", "5", "4", "left")
    registerButton("BTN_RIGHT", sideX + 9, dpadY + 2, 7, 2, "RGHT >", "0", "5", "4", "right")
    registerButton("BTN_DOWN", sideX + 5, dpadY + 4, 7, 2, "v DOWN", "0", "5", "4", "down")
    
    -- Action Buttons
    local actY = dpadY + 7
    registerButton("BTN_BOOST", sideX + 1, actY, 15, 2, "[ SPEED BOOST ]", Game.boostActive and "f" or "0", Game.boostActive and "e" or "4", "5", "space")
    registerButton("BTN_PAUSE", sideX + 1, actY + 3, 7, 2, "PAUSE", "0", "7", "e", "p")
    registerButton("BTN_MENU", sideX + 9, actY + 3, 7, 2, "LOBBY", "0", "e", "4", "q")
    
    -- Stats & Active Buffs
    local statY = actY + 6
    drawText(sideX, statY, string.format("Length: %d", #Game.snake), "e", "f")
    drawText(sideX, statY + 1, string.format("Apples: %d", Game.applesEaten), "d", "f")
    drawText(sideX, statY + 2, string.format("Field: %d apples", Config.appleCount), "4", "f")
    
    if Game.mode == "TIMEATTACK" then
        local tCol = (Game.timeLeft <= 10) and "e" or "5"
        drawText(sideX, statY + 3, string.format("TIME: %02.1fs", math.max(0, Game.timeLeft)), tCol, "f")
    end
    
    if Game.ghostTailTimer > 0 then
        drawText(sideX, statY + 4, string.format("* GHOST: %02.1fs", Game.ghostTailTimer), "9", "f")
    elseif Game.freezeTimer > 0 then
        drawText(sideX, statY + 4, string.format("S SLOW: %02.1fs", Game.freezeTimer), "3", "f")
    end
    
    drawRegisteredButtons()
    flushBuffer()
end

-- =============================================================================
--                             CUSTOM SETTINGS MENU
-- =============================================================================

local function runSettingsMenu()
    local appleOpts = { 1, 2, 3, 5, 10 }
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        
        drawText(1, 1, string.rep(" ", screenW), "0", "7")
        drawText(2, 1, "SNAKE 2D DELUXE", "5", "7")
        drawText(screenW - 20, 1, "CUSTOM SETTINGS", "4", "7")
        
        drawCenteredText(3, "================================================", "4", "f")
        drawCenteredText(4, "* * *  CUSTOM DIFFICULTY & SKINS  * * *", "e", "f")
        drawCenteredText(5, "================================================", "4", "f")
        
        local boxW = 46
        local startX = math.floor((screenW - boxW) / 2) + 1
        local startY = 7
        
        -- 1. Apples on Board
        drawText(startX, startY, string.format("1. Apples on Field  : [ %d Apples ]", Config.appleCount), "e", "f")
        registerButton("SET_APPLE_MINUS", startX + 34, startY, 4, 1, "[-]", "0", "7", "e")
        registerButton("SET_APPLE_PLUS", startX + 39, startY, 4, 1, "[+]", "0", "7", "e")
        
        -- 2. Base Speed
        local spdName = (SPEED_VALUES[Config.speedPreset] and SPEED_VALUES[Config.speedPreset].name) or "Normal"
        drawText(startX, startY + 2, string.format("2. Base Game Speed  : [ %-7s ]", spdName), "e", "f")
        registerButton("SET_SPD_MINUS", startX + 34, startY + 2, 4, 1, "[-]", "0", "7", "e")
        registerButton("SET_SPD_PLUS", startX + 39, startY + 2, 4, 1, "[+]", "0", "7", "e")
        
        -- 3. Snake Growth Rate
        drawText(startX, startY + 4, string.format("3. Tail Growth Rate : [ +%d Segments ]", Config.growthRate), "e", "f")
        registerButton("SET_GROWTH_MINUS", startX + 34, startY + 4, 4, 1, "[-]", "0", "7", "e")
        registerButton("SET_GROWTH_PLUS", startX + 39, startY + 4, 4, 1, "[+]", "0", "7", "e")
        
        -- 4. Power-up Frequency
        local pwName = POWERUP_NAMES[Config.powerupFreq] or "Normal"
        drawText(startX, startY + 6, string.format("4. Powerup Spawns   : [ %-12s ]", pwName), "e", "f")
        registerButton("SET_POW_MINUS", startX + 34, startY + 6, 4, 1, "[-]", "0", "7", "e")
        registerButton("SET_POW_PLUS", startX + 39, startY + 6, 4, 1, "[+]", "0", "7", "e")
        
        -- 5. Snake Skin Selection
        local skinName = (Skins[Config.skinId] and Skins[Config.skinId].name) or "Neon Viper"
        drawText(startX, startY + 8, string.format("5. Snake Skin Theme : [ %-14s ]", skinName), "5", "f")
        registerButton("SET_SKIN_MINUS", startX + 34, startY + 8, 4, 1, "[-]", "0", "7", "e")
        registerButton("SET_SKIN_PLUS", startX + 39, startY + 8, 4, 1, "[+]", "0", "7", "e")
        
        -- 6. Speed Growth Toggle
        local sgText = Config.speedGrowth and "[ ON ]" or "[ OFF ]"
        drawText(startX, startY + 10, string.format("6. Dynamic Speed Up : %s", sgText), "e", "f")
        registerButton("SET_TOGGLE_SG", startX + 34, startY + 10, 9, 1, Config.speedGrowth and "ENABLED" or "OFF", "0", Config.speedGrowth and "5" or "7", "e")
        
        -- Back Button
        registerButton("SET_BACK", startX + 10, startY + 13, 24, 2, "<< SAVE & RETURN >>", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local cid = nil
        
        if event == "key" then
            if p1 == keys.escape or p1 == keys.q or p1 == keys.enter or p1 == keys.space then
                saveData()
                return
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            cid = checkButtonClicked(p2, p3)
        end
        
        if cid == "SET_BACK" then
            playSound("click")
            saveData()
            return
        elseif cid == "SET_APPLE_MINUS" then
            for i = #appleOpts, 1, -1 do
                if appleOpts[i] < Config.appleCount then
                    Config.appleCount = appleOpts[i]
                    break
                end
            end
            playSound("click")
        elseif cid == "SET_APPLE_PLUS" then
            for i = 1, #appleOpts do
                if appleOpts[i] > Config.appleCount then
                    Config.appleCount = appleOpts[i]
                    break
                end
            end
            playSound("click")
        elseif cid == "SET_SPD_MINUS" then
            Config.speedPreset = math.max(1, Config.speedPreset - 1)
            playSound("click")
        elseif cid == "SET_SPD_PLUS" then
            Config.speedPreset = math.min(#SPEED_VALUES, Config.speedPreset + 1)
            playSound("click")
        elseif cid == "SET_GROWTH_MINUS" then
            Config.growthRate = math.max(1, Config.growthRate - 1)
            playSound("click")
        elseif cid == "SET_GROWTH_PLUS" then
            Config.growthRate = math.min(3, Config.growthRate + 1)
            playSound("click")
        elseif cid == "SET_POW_MINUS" then
            Config.powerupFreq = math.max(0, Config.powerupFreq - 1)
            playSound("click")
        elseif cid == "SET_POW_PLUS" then
            Config.powerupFreq = math.min(3, Config.powerupFreq + 1)
            playSound("click")
        elseif cid == "SET_SKIN_MINUS" then
            Config.skinId = (Config.skinId <= 1) and #Skins or (Config.skinId - 1)
            playSound("click")
        elseif cid == "SET_SKIN_PLUS" then
            Config.skinId = (Config.skinId >= #Skins) and 1 or (Config.skinId + 1)
            playSound("click")
        elseif cid == "SET_TOGGLE_SG" then
            Config.speedGrowth = not Config.speedGrowth
            playSound("click")
        end
    end
end

-- Pause Menu Modal
local function runPauseMenu()
    playSound("pause")
    local boxW = 30
    local boxH = 10
    local startX = math.floor((screenW - boxW) / 2) + 1
    local startY = math.floor((screenH - boxH) / 2) + 1
    
    while true do
        clearButtons()
        for y = startY, startY + boxH do drawText(startX, y, string.rep(" ", boxW), "0", "8") end
        drawCenteredText(startY + 1, "=== GAME PAUSED ===", "4", "8")
        
        registerButton("PAUSE_RESUME", startX + 4, startY + 3, 22, 2, "[ RESUME GAME ]", "0", "5", "4")
        registerButton("PAUSE_SETTINGS", startX + 4, startY + 5, 22, 2, "[ CUSTOM SETTINGS ]", "0", "7", "e")
        registerButton("PAUSE_RESTART", startX + 4, startY + 7, 22, 2, "[ RESTART MODE ]", "0", "e", "4")
        registerButton("PAUSE_LOBBY", startX + 4, startY + 9, 22, 2, "[ EXIT TO LOBBY ]", "0", "8", "7")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.p or p1 == keys.escape or p1 == keys.space then return "RESUME"
            elseif p1 == keys.q then return "LOBBY" end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local cid = checkButtonClicked(p2, p3)
            if cid == "PAUSE_RESUME" then return "RESUME"
            elseif cid == "PAUSE_SETTINGS" then
                runSettingsMenu()
                return "RESUME"
            elseif cid == "PAUSE_RESTART" then return "RESTART"
            elseif cid == "PAUSE_LOBBY" then return "LOBBY" end
        end
    end
end

-- Game Over Screen Modal
local function runGameOverScreen()
    playSound("die")
    local isNewHi = (Game.score > (HighScores[Game.mode] or 0))
    if isNewHi then
        HighScores[Game.mode] = Game.score
        saveData()
        playSound("highscore")
    end
    
    local boxW = 34
    local boxH = 10
    local startX = math.floor((screenW - boxW) / 2) + 1
    local startY = math.floor((screenH - boxH) / 2) + 1
    
    while true do
        clearButtons()
        for y = startY, startY + boxH do drawText(startX, y, string.rep(" ", boxW), "0", "8") end
        
        if isNewHi then
            drawCenteredText(startY + 1, "*** NEW HIGH SCORE! ***", "e", "8")
        else
            drawCenteredText(startY + 1, "=== GAME OVER ===", "e", "8")
        end
        
        drawCenteredText(startY + 3, string.format("FINAL SCORE : %05d", Game.score), "4", "8")
        drawCenteredText(startY + 4, string.format("LENGTH      : %d", #Game.snake), "5", "8")
        drawCenteredText(startY + 5, string.format("BEST RECORD : %05d", HighScores[Game.mode] or 0), "e", "8")
        
        registerButton("GO_RETRY", startX + 3, startY + 7, 13, 2, "[ PLAY AGAIN ]", "0", "5", "4")
        registerButton("GO_LOBBY", startX + 18, startY + 7, 13, 2, "[ LOBBY ]", "0", "e", "4")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.enter or p1 == keys.space or p1 == keys.r then return "RETRY"
            elseif p1 == keys.escape or p1 == keys.q then return "LOBBY" end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local cid = checkButtonClicked(p2, p3)
            if cid == "GO_RETRY" then return "RETRY"
            elseif cid == "GO_LOBBY" then return "LOBBY" end
        end
    end
end

-- =============================================================================
--                             MAIN GAME LOOP
-- =============================================================================

local function runSnakeGame(mode)
    initGame(mode)
    
    local timerId = os.startTimer(Game.speed)
    local lastTickTime = os.epoch("utc") / 1000.0
    local goldSpawnTimer = 8.0
    local powInterval = (Config.powerupFreq == 1 and 30) or ((Config.powerupFreq == 3 and 7) or 15)
    local powerupSpawnTimer = powInterval
    
    while Game.state == "PLAYING" do
        renderGame()
        
        local event, p1, p2, p3 = os.pullEvent()
        local curTime = os.epoch("utc") / 1000.0
        local dt = math.min(0.1, curTime - lastTickTime)
        lastTickTime = curTime
        
        if Game.ghostTailTimer > 0 then Game.ghostTailTimer = math.max(0, Game.ghostTailTimer - dt) end
        if Game.freezeTimer > 0 then
            Game.freezeTimer = math.max(0, Game.freezeTimer - dt)
            if Game.freezeTimer == 0 then Game.speed = Game.baseSpeed end
        end
        
        if Game.mode == "TIMEATTACK" then
            Game.timeLeft = Game.timeLeft - dt
            if Game.timeLeft <= 0 then
                Game.state = "GAMEOVER"
            end
        end
        
        -- Gold fruit countdown
        goldSpawnTimer = goldSpawnTimer - dt
        if goldSpawnTimer <= 0 then
            goldSpawnTimer = math.random(12, 20)
            spawnFruit("GOLD")
        end
        
        -- Powerup spawn countdown
        if Config.powerupFreq > 0 then
            powerupSpawnTimer = powerupSpawnTimer - dt
            if powerupSpawnTimer <= 0 then
                powerupSpawnTimer = math.random(powInterval - 2, powInterval + 6)
                spawnPowerup()
            end
        end
        
        for i = #Game.fruits, 1, -1 do
            local f = Game.fruits[i]
            if f.life then
                f.life = f.life - dt
                if f.life <= 0 then table.remove(Game.fruits, i) end
            end
        end
        for i = #Game.powerups, 1, -1 do
            local p = Game.powerups[i]
            p.life = p.life - dt
            if p.life <= 0 then table.remove(Game.powerups, i) end
        end
        
        if event == "timer" and p1 == timerId then
            local curSpeed = Game.boostActive and (Game.speed * 0.5) or Game.speed
            timerId = os.startTimer(curSpeed)
            
            Game.dirX = Game.nextDirX
            Game.dirY = Game.nextDirY
            
            local head = Game.snake[1]
            local newX = head.x + Game.dirX
            local newY = head.y + Game.dirY
            
            if Game.mode == "NOWALLS" then
                if newX < 1 then newX = Game.boardW
                elseif newX > Game.boardW then newX = 1 end
                if newY < 1 then newY = Game.boardH
                elseif newY > Game.boardH then newY = 1 end
            else
                if newX < 1 or newX > Game.boardW or newY < 1 or newY > Game.boardH then
                    Game.state = "GAMEOVER"
                end
            end
            
            for _, obs in ipairs(Game.obstacles) do
                if obs.x == newX and obs.y == newY then
                    Game.state = "GAMEOVER"
                end
            end
            
            if Game.ghostTailTimer <= 0 then
                for i = 1, #Game.snake - 1 do
                    local seg = Game.snake[i]
                    if seg.x == newX and seg.y == newY then
                        Game.state = "GAMEOVER"
                    end
                end
            end
            
            if Game.state ~= "GAMEOVER" then
                table.insert(Game.snake, 1, { x = newX, y = newY })
                
                local ateFruit = false
                for i = #Game.fruits, 1, -1 do
                    local f = Game.fruits[i]
                    if f.x == newX and f.y == newY then
                        ateFruit = true
                        Game.score = Game.score + f.pts
                        Game.applesEaten = Game.applesEaten + 1
                        Game.growthPending = Game.growthPending + (Config.growthRate - 1)
                        
                        if Game.mode == "TIMEATTACK" then
                            Game.timeLeft = Game.timeLeft + (f.type == "GOLD" and 10 or 4)
                        end
                        playSound(f.type == "GOLD" and "eat_gold" or "eat")
                        table.remove(Game.fruits, i)
                        
                        if f.type == "APPLE" then
                            ensureApples()
                            if Config.speedGrowth then
                                Game.baseSpeed = math.max(0.04, Game.baseSpeed - 0.001)
                                if Game.freezeTimer <= 0 then Game.speed = Game.baseSpeed end
                            end
                        end
                        break
                    end
                end
                
                for i = #Game.powerups, 1, -1 do
                    local p = Game.powerups[i]
                    if p.x == newX and p.y == newY then
                        playSound("powerup")
                        if p.type == "STAR" then
                            Game.ghostTailTimer = 5.0
                            Game.score = Game.score + 100
                        elseif p.type == "SNAIL" then
                            Game.freezeTimer = 6.0
                            Game.speed = Game.baseSpeed * 1.6
                        elseif p.type == "CUTTER" then
                            for _ = 1, 3 do
                                if #Game.snake > 3 then table.remove(Game.snake) end
                            end
                            Game.score = Game.score + 50
                        end
                        table.remove(Game.powerups, i)
                        break
                    end
                end
                
                if not ateFruit then
                    if Game.growthPending > 0 then
                        Game.growthPending = Game.growthPending - 1
                    else
                        table.remove(Game.snake)
                    end
                end
            end
            
        elseif event == "key" then
            if p1 == keys.up or p1 == keys.w then setDirection(0, -1)
            elseif p1 == keys.down or p1 == keys.s then setDirection(0, 1)
            elseif p1 == keys.left or p1 == keys.a then setDirection(-1, 0)
            elseif p1 == keys.right or p1 == keys.d then setDirection(1, 0)
            elseif p1 == keys.space then Game.boostActive = true
            elseif p1 == keys.p then
                local res = runPauseMenu()
                if res == "RESTART" then return runSnakeGame(mode)
                elseif res == "LOBBY" then return "LOBBY" end
                lastTickTime = os.epoch("utc") / 1000.0
                timerId = os.startTimer(Game.speed)
            elseif p1 == keys.q or p1 == keys.escape then
                return "LOBBY"
            end
            
        elseif event == "key_up" then
            if p1 == keys.space then Game.boostActive = false end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local clickedId = checkButtonClicked(mx, my)
            
            if clickedId == "BTN_UP" then setDirection(0, -1)
            elseif clickedId == "BTN_DOWN" then setDirection(0, 1)
            elseif clickedId == "BTN_LEFT" then setDirection(-1, 0)
            elseif clickedId == "BTN_RIGHT" then setDirection(1, 0)
            elseif clickedId == "BTN_BOOST" then Game.boostActive = not Game.boostActive
            elseif clickedId == "BTN_PAUSE" then
                local res = runPauseMenu()
                if res == "RESTART" then return runSnakeGame(mode)
                elseif res == "LOBBY" then return "LOBBY" end
                lastTickTime = os.epoch("utc") / 1000.0
                timerId = os.startTimer(Game.speed)
            elseif clickedId == "BTN_MENU" then
                return "LOBBY"
            else
                local bx, by = Game.boardX, Game.boardY
                if mx >= bx and mx <= bx + Game.boardW and my >= by and my <= by + Game.boardH then
                    local head = Game.snake[1]
                    local relX = (mx - bx + 1) - head.x
                    local relY = (my - by + 1) - head.y
                    if math.abs(relX) > math.abs(relY) then
                        setDirection(relX > 0 and 1 or -1, 0)
                    else
                        setDirection(0, relY > 0 and 1 or -1)
                    end
                end
            end
        end
    end
    
    if Game.state == "GAMEOVER" then
        local goRes = runGameOverScreen()
        if goRes == "RETRY" then
            return runSnakeGame(mode)
        else
            return "LOBBY"
        end
    end
end

-- =============================================================================
--                             MAIN MENU & ENTRY
-- =============================================================================

local function runMainMenu()
    local selectedIdx = 1
    local modes = {
        { id = "CLASSIC",    title = "1. [CLASSIC] Solid Walls", desc = "Standard arcade snake with solid border walls" },
        { id = "NOWALLS",    title = "2. [PORTAL] No Walls (Wrap)", desc = "Wrap-around screen edges (infinite torus field)" },
        { id = "MAZE",       title = "3. [MAZE] Brick Obstacles", desc = "Navigate complex brick obstacles & pillars" },
        { id = "TIMEATTACK", title = "4. [RUSH] Time Attack", desc = "Race the clock! Eat fruit to add extra seconds" },
        { id = "SETTINGS",   title = "5. [CUSTOM] Settings & Skins", desc = "Customize berry count, speed, skins & growth" },
        { id = "QUIT",       title = "6. [EXIT] Quit Game", desc = "Return to computer terminal" }
    }
    
    -- Demo AI Snake on Background
    local demoSnake = {
        { x = 12, y = 2 }, { x = 11, y = 2 }, { x = 10, y = 2 },
        { x = 9, y = 2 }, { x = 8, y = 2 }, { x = 7, y = 2 }
    }
    local demoDir = { x = 1, y = 0 }
    local demoApples = { { x = 20, y = 2 }, { x = 5, y = screenH - 2 }, { x = screenW - 6, y = 14 } }
    local animTick = 0
    local menuTimer = os.startTimer(0.1)
    
    local neonColors = { "4", "1", "5", "d", "9", "2", "e" }
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        
        animTick = animTick + 1
        local neonCol = neonColors[(math.floor(animTick / 2) % #neonColors) + 1]
        local curSkin = Skins[Config.skinId] or Skins[1]
        
        -- 1. Animated Border Particles & Demo Apples
        for _, da in ipairs(demoApples) do
            drawText(da.x, da.y, "A", "e", "0")
        end
        
        -- Draw Demo Snake crawling in background
        for idx, seg in ipairs(demoSnake) do
            if idx == 1 then
                local hCh = (demoDir.x == 1 and ">") or ((demoDir.x == -1 and "<") or ((demoDir.y == 1 and "v") or "^"))
                drawText(seg.x, seg.y, hCh, "4", "5")
            else
                local bFg = (idx % 2 == 0) and curSkin.bodyFg1 or curSkin.bodyFg2
                drawText(seg.x, seg.y, curSkin.bodyChar, bFg, "0")
            end
        end
        
        -- 2. Top Header Bar
        drawText(1, 1, string.rep(" ", screenW), "0", "7")
        drawText(2, 1, "SNAKE 2D DELUXE", neonCol, "7")
        drawText(screenW - 24, 1, "SKIN: " .. curSkin.name, "4", "7")
        
        -- 3. Pulsing Neon Title Banner
        local chase1 = ((animTick % 2 == 0) and "* * *" or " . . .")
        local chase2 = ((animTick % 2 == 1) and "* * *" or " . . .")
        drawCenteredText(3, "================================================", neonCol, "f")
        drawCenteredText(4, chase1 .. "  S N A K E   2 D   D E L U X E  " .. chase2, "e", "f")
        drawCenteredText(5, "================================================", neonCol, "f")
        
        -- 4. Mode Selection Buttons
        local btnW = 38
        local startX = math.floor((screenW - btnW) / 2) + 1
        local startY = 7
        
        for i, m in ipairs(modes) do
            local by = startY + (i - 1) * 2
            local isSel = (i == selectedIdx)
            local fg = isSel and "0" or "f"
            local bg = isSel and "4" or (i == 5 and "5" or (i == 6 and "e" or "7"))
            registerButton("MODE_" .. m.id, startX, by, btnW, 2, m.title, fg, bg, "e")
        end
        
        -- 5. Animated Bottom Marquee
        local hiY = startY + (#modes * 2) + 1
        drawCenteredText(hiY, string.format("Apples: %d | Speed: %s | Growth: +%d | Powerups: %s", Config.appleCount, SPEED_VALUES[Config.speedPreset].name, Config.growthRate, POWERUP_NAMES[Config.powerupFreq]), "e", "f")
        
        local pulseIndicator = (animTick % 4 < 2) and ">> [CLICK TO PLAY] <<" or "-- [CLICK TO PLAY] --"
        drawCenteredText(screenH - 1, pulseIndicator .. " or Use 1-6 / Arrow Keys", "8", "f")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local chosenMode = nil
        
        if event == "timer" and p1 == menuTimer then
            menuTimer = os.startTimer(0.1)
            
            -- Move Demo Snake around the screen perimeter
            local head = demoSnake[1]
            local target = demoApples[1]
            
            -- Simple AI towards apple
            if target then
                if math.random(1, 10) <= 7 then
                    if head.x < target.x and demoDir.x ~= -1 then demoDir = { x = 1, y = 0 }
                    elseif head.x > target.x and demoDir.x ~= 1 then demoDir = { x = -1, y = 0 }
                    elseif head.y < target.y and demoDir.y ~= -1 then demoDir = { x = 0, y = 1 }
                    elseif head.y > target.y and demoDir.y ~= 1 then demoDir = { x = 0, y = -1 } end
                end
            end
            
            local nx = head.x + demoDir.x
            local ny = head.y + demoDir.y
            if nx < 1 then nx = screenW elseif nx > screenW then nx = 1 end
            if ny < 2 then ny = screenH - 1 elseif ny > screenH - 1 then ny = 2 end
            
            table.insert(demoSnake, 1, { x = nx, y = ny })
            
            -- Check if demo snake ate apple
            local ate = false
            for ai, da in ipairs(demoApples) do
                if da.x == nx and da.y == ny then
                    ate = true
                    demoApples[ai] = { x = math.random(4, screenW - 4), y = math.random(2, screenH - 2) }
                    break
                end
            end
            if not ate then
                table.remove(demoSnake)
            end
            
        elseif event == "key" then
            if p1 == keys.one then chosenMode = "CLASSIC"
            elseif p1 == keys.two then chosenMode = "NOWALLS"
            elseif p1 == keys.three then chosenMode = "MAZE"
            elseif p1 == keys.four then chosenMode = "TIMEATTACK"
            elseif p1 == keys.five then chosenMode = "SETTINGS"
            elseif p1 == keys.six or p1 == keys.q or p1 == keys.escape then return
            elseif p1 == keys.up or p1 == keys.w then
                selectedIdx = math.max(1, selectedIdx - 1)
                playSound("click")
            elseif p1 == keys.down or p1 == keys.s then
                selectedIdx = math.min(#modes, selectedIdx + 1)
                playSound("click")
            elseif p1 == keys.enter or p1 == keys.space then
                chosenMode = modes[selectedIdx].id
                playSound("click")
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local cid = checkButtonClicked(p2, p3)
            if cid then
                playSound("click")
                chosenMode = string.sub(cid, 6)
            end
        end
        
        if chosenMode == "QUIT" then
            return
        elseif chosenMode == "SETTINGS" then
            runSettingsMenu()
            menuTimer = os.startTimer(0.1)
        elseif chosenMode then
            runSnakeGame(chosenMode)
            menuTimer = os.startTimer(0.1)
        end
    end
end

local function main()
    loadData()
    initBuffer()
    runMainMenu()
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Snake 2D Deluxe closed. Thanks for playing!")
    else
        print("Thanks for playing SNAKE 2D Deluxe!")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Snake Error: " .. tostring(err))
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.setCursorPos(1, 1)
    print("Snake Error: " .. tostring(err))
end
