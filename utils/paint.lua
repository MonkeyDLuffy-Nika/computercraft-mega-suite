--[[
================================================================================
                    PAINT PRO 2D for CC: Tweaked (Minecraft)
            Professional 2D Graphics Studio with Touch Controls
================================================================================
  Features:
    * Brush Size Presets:
        - [1:SM]  Small (1x1 precision)
        - [2:MD]  Medium (2x2 standard)
        - [3:LG]  Huge / Large (3x3 wide coverage)
        (Hotkeys: 1, 2, 3 or click buttons on screen)
    * 12 Rock-Solid Tools (Dual Mode: Mouse Drag & 2-Tap Touchscreen):
        - [PENCIL]   1x1 Precision Pixel Pencil
        - [BRUSH]    Multi-size Brush (S / M / L)
        - [ERASER]   Multi-size Eraser (S / M / L)
        - [FILL]     Smart Flood Bucket Fill
        - [LINE]     Straight Line (Drag or 2-Tap)
        - [RECT]     Hollow Rectangle (Drag or 2-Tap)
        - [BOX]      Solid Filled Box (Drag or 2-Tap)
        - [CIRCLE]   Smooth Circle / Ellipse (Zero gaps)
        - [DISC]     Solid Filled Disc / Ellipse
        - [SPRAY]    Airbrush Spray (S: 4 dots, M: 8 dots, L: 18 dots)
        - [DITHER]   2-Color Shading Pattern
        - [PICKER]   Eyedropper Color Picker
        - [TEXT]     Direct Text Stamp
    * 16-Color Palette (Primary & Secondary Color Selection)
    * Multi-Step Undo / Redo (Up to 25 history steps)
    * Save & Load Standard Minecraft .nfp Drawing Files
    * Canvas Grid Overlay [GRID], Full Canvas Clear [CLEAR]
    * Output: External Monitor on the LEFT ("left") or Terminal
    * Audio Feedback via CC Speaker peripheral
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
    printError("PAINT PRO requires an Advanced Computer or Color Monitor!")
    return
end

local screenW, screenH = display.getSize()

-- Audio Sound FX via Speaker
local speaker = peripheral and peripheral.find and peripheral.find("speaker")

local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "click" then
            speaker.playNote("hat", 0.5, 14)
        elseif snd == "draw" then
            speaker.playNote("snare", 0.3, 10)
        elseif snd == "fill" then
            speaker.playNote("chime", 0.8, 12)
            speaker.playNote("flute", 0.5, 16)
        elseif snd == "undo" then
            speaker.playNote("bass", 0.6, 10)
        elseif snd == "redo" then
            speaker.playNote("bass", 0.6, 14)
        elseif snd == "save" then
            speaker.playNote("bell", 0.9, 16)
            sleep(0.04)
            speaker.playNote("bell", 0.9, 20)
        elseif snd == "size" then
            speaker.playNote("pling", 0.7, 16)
        elseif snd == "error" then
            speaker.playNote("didgeridoo", 1.0, 4)
        end
    end)
end

-- 16 Minecraft Colors
local COLOR_HEX = {
    [colors.white]     = "0",
    [colors.orange]    = "1",
    [colors.magenta]   = "2",
    [colors.lightBlue] = "3",
    [colors.yellow]    = "4",
    [colors.lime]      = "5",
    [colors.pink]      = "6",
    [colors.gray]      = "7",
    [colors.lightGray] = "8",
    [colors.cyan]      = "9",
    [colors.purple]    = "a",
    [colors.blue]      = "b",
    [colors.brown]     = "c",
    [colors.green]     = "d",
    [colors.red]       = "e",
    [colors.black]     = "f"
}

local COLOR_LIST = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black
}

local COLOR_NAMES = {
    [colors.white] = "White", [colors.orange] = "Orange", [colors.magenta] = "Magenta",
    [colors.lightBlue] = "LightBlue", [colors.yellow] = "Yellow", [colors.lime] = "Lime",
    [colors.pink] = "Pink", [colors.gray] = "Gray", [colors.lightGray] = "LightGray",
    [colors.cyan] = "Cyan", [colors.purple] = "Purple", [colors.blue] = "Blue",
    [colors.brown] = "Brown", [colors.green] = "Green", [colors.red] = "Red", [colors.black] = "Black"
}

-- Canvas Placement
local CANVAS_X = 14
local CANVAS_Y = 3
local CANVAS_W = math.max(10, screenW - CANVAS_X - 1)
local CANVAS_H = math.max(10, screenH - CANVAS_Y - 2)

-- Editor State
local Editor = {
    tool = "BRUSH",
    brushSize = 2, -- 1: Small (1x1), 2: Medium (2x2), 3: Huge (3x3)
    primaryColor = colors.red,
    secondaryColor = colors.white,
    char = " ",
    showGrid = false,
    currentFile = "drawing.nfp",
    statusMessage = "Ready. Tap or drag on canvas to draw.",
    statusTimer = 3.0,
    cursorX = 1,
    cursorY = 1,
    isMouseDown = false,
    dragStartX = nil,
    dragStartY = nil,
    shapeAnchor = nil,
    previewPixels = {}
}

local SIZE_NAMES = {
    [1] = "Small (1x1)",
    [2] = "Medium (2x2)",
    [3] = "Huge (3x3)"
}

-- Canvas Data Matrix
local Canvas = {
    chars = {},
    fg = {},
    bg = {}
}

local UndoStack = {}
local RedoStack = {}
local MAX_HISTORY = 25

local function initCanvas(w, h, fillBg)
    CANVAS_W = w or CANVAS_W
    CANVAS_H = h or CANVAS_H
    fillBg = fillBg or colors.black
    local bgHex = COLOR_HEX[fillBg] or "f"
    
    Canvas.chars = {}
    Canvas.fg = {}
    Canvas.bg = {}
    
    for y = 1, CANVAS_H do
        Canvas.chars[y] = {}
        Canvas.fg[y] = {}
        Canvas.bg[y] = {}
        for x = 1, CANVAS_W do
            Canvas.chars[y][x] = " "
            Canvas.fg[y][x] = "0"
            Canvas.bg[y][x] = bgHex
        end
    end
    UndoStack = {}
    RedoStack = {}
    Editor.shapeAnchor = nil
    Editor.previewPixels = {}
end

local function cloneCanvasState()
    local snap = { chars = {}, fg = {}, bg = {}, w = CANVAS_W, h = CANVAS_H }
    for y = 1, CANVAS_H do
        snap.chars[y] = {}
        snap.fg[y] = {}
        snap.bg[y] = {}
        for x = 1, CANVAS_W do
            snap.chars[y][x] = Canvas.chars[y][x]
            snap.fg[y][x] = Canvas.fg[y][x]
            snap.bg[y][x] = Canvas.bg[y][x]
        end
    end
    return snap
end

local function restoreCanvasState(snap)
    if not snap then return end
    CANVAS_W = snap.w
    CANVAS_H = snap.h
    for y = 1, CANVAS_H do
        Canvas.chars[y] = Canvas.chars[y] or {}
        Canvas.fg[y] = Canvas.fg[y] or {}
        Canvas.bg[y] = Canvas.bg[y] or {}
        for x = 1, CANVAS_W do
            Canvas.chars[y][x] = snap.chars[y][x]
            Canvas.fg[y][x] = snap.fg[y][x]
            Canvas.bg[y][x] = snap.bg[y][x]
        end
    end
    Editor.shapeAnchor = nil
    Editor.previewPixels = {}
end

local function pushUndo()
    table.insert(UndoStack, cloneCanvasState())
    if #UndoStack > MAX_HISTORY then
        table.remove(UndoStack, 1)
    end
    RedoStack = {}
end

local function performUndo()
    if #UndoStack > 0 then
        table.insert(RedoStack, cloneCanvasState())
        local state = table.remove(UndoStack)
        restoreCanvasState(state)
        Editor.statusMessage = "Undo action performed."
        Editor.statusTimer = 2.0
        playSound("undo")
    else
        Editor.statusMessage = "Nothing to undo."
        Editor.statusTimer = 1.5
    end
end

local function performRedo()
    if #RedoStack > 0 then
        table.insert(UndoStack, cloneCanvasState())
        local state = table.remove(RedoStack)
        restoreCanvasState(state)
        Editor.statusMessage = "Redo action performed."
        Editor.statusTimer = 2.0
        playSound("redo")
    else
        Editor.statusMessage = "Nothing to redo."
        Editor.statusTimer = 1.5
    end
end

-- =============================================================================
--                             BUTTON & DRAW UTILITIES
-- =============================================================================

local Buttons = {}

local function clearButtons()
    Buttons = {}
end

local function registerButton(id, x, y, w, h, label, fg, bg, activeBg, tooltip)
    table.insert(Buttons, {
        id = id,
        x1 = x,
        y1 = y,
        x2 = x + w - 1,
        y2 = y + h - 1,
        w = w,
        h = h,
        label = label,
        fg = fg or "0",
        bg = bg or "7",
        activeBg = activeBg or "e",
        tooltip = tooltip
    })
end

local function checkButtonClicked(clickX, clickY)
    for _, btn in ipairs(Buttons) do
        if clickX >= btn.x1 and clickX <= btn.x2 and clickY >= btn.y1 and clickY <= btn.y2 then
            return btn
        end
    end
    return nil
end

-- Safe Blit Renderer (guarantees exact length matching)
local function drawBlit(x, y, text, fg, bg)
    if y < 1 or y > screenH or x > screenW then return end
    if not text or #text == 0 then return end
    local len = #text
    
    if not fg or #fg ~= len then
        local fillChar = (fg and #fg > 0) and string.sub(fg, 1, 1) or "0"
        fg = string.rep(fillChar, len)
    end
    if not bg or #bg ~= len then
        local fillChar = (bg and #bg > 0) and string.sub(bg, 1, 1) or "f"
        bg = string.rep(fillChar, len)
    end
    
    display.setCursorPos(x, y)
    pcall(function()
        display.blit(text, fg, bg)
    end)
end

local function drawText(x, y, text, fgCol, bgCol)
    if y < 1 or y > screenH or x > screenW then return end
    if not text or #text == 0 then return end
    local fgChar = COLOR_HEX[fgCol] or "0"
    local bgChar = COLOR_HEX[bgCol] or "f"
    drawBlit(x, y, text, string.rep(fgChar, #text), string.rep(bgChar, #text))
end

-- =============================================================================
--                             DRAWING ALGORITHMS
-- =============================================================================

local function setPixel(cx, cy, char, fgColor, bgColor)
    if cx >= 1 and cx <= CANVAS_W and cy >= 1 and cy <= CANVAS_H then
        Canvas.chars[cy][cx] = char or Editor.char
        Canvas.fg[cy][cx] = COLOR_HEX[fgColor or Editor.secondaryColor] or "0"
        Canvas.bg[cy][cx] = COLOR_HEX[bgColor or Editor.primaryColor] or "f"
    end
end

-- Stamp with size
local function stampBrush(cx, cy, size, char, fgColor, bgColor)
    if size == 1 then
        setPixel(cx, cy, char, fgColor, bgColor)
    elseif size == 2 then
        setPixel(cx, cy, char, fgColor, bgColor)
        setPixel(cx + 1, cy, char, fgColor, bgColor)
        setPixel(cx, cy + 1, char, fgColor, bgColor)
        setPixel(cx + 1, cy + 1, char, fgColor, bgColor)
    elseif size >= 3 then
        for dy = -1, 1 do
            for dx = -1, 1 do
                setPixel(cx + dx, cy + dy, char, fgColor, bgColor)
            end
        end
    end
end

-- Stamp Eraser with size
local function stampEraser(cx, cy, size)
    if size == 1 then
        setPixel(cx, cy, " ", colors.white, colors.black)
    elseif size == 2 then
        setPixel(cx, cy, " ", colors.white, colors.black)
        setPixel(cx + 1, cy, " ", colors.white, colors.black)
        setPixel(cx, cy + 1, " ", colors.white, colors.black)
        setPixel(cx + 1, cy + 1, " ", colors.white, colors.black)
    elseif size >= 3 then
        for dy = -1, 1 do
            for dx = -1, 1 do
                setPixel(cx + dx, cy + dy, " ", colors.white, colors.black)
            end
        end
    end
end

-- Flood Fill (BFS)
local function floodFill(startX, startY, targetChar, targetFg, targetBg, fillChar, fillFg, fillBg)
    if startX < 1 or startX > CANVAS_W or startY < 1 or startY > CANVAS_H then return end
    local fillFgHex = COLOR_HEX[fillFg]
    local fillBgHex = COLOR_HEX[fillBg]
    
    if targetChar == fillChar and targetFg == fillFgHex and targetBg == fillBgHex then
        return
    end
    
    local queue = { {startX, startY} }
    local visited = {}
    
    while #queue > 0 do
        local pt = table.remove(queue, 1)
        local x, y = pt[1], pt[2]
        local key = x .. "," .. y
        
        if not visited[key] and x >= 1 and x <= CANVAS_W and y >= 1 and y <= CANVAS_H then
            visited[key] = true
            if Canvas.chars[y][x] == targetChar and Canvas.bg[y][x] == targetBg and Canvas.fg[y][x] == targetFg then
                Canvas.chars[y][x] = fillChar
                Canvas.fg[y][x] = fillFgHex
                Canvas.bg[y][x] = fillBgHex
                
                table.insert(queue, {x + 1, y})
                table.insert(queue, {x - 1, y})
                table.insert(queue, {x, y + 1})
                table.insert(queue, {x, y - 1})
            end
        end
    end
    playSound("fill")
end

-- Bresenham's Line Algorithm
local function getLinePixels(x0, y0, x1, y1)
    local pixels = {}
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = (x0 < x1) and 1 or -1
    local sy = (y0 < y1) and 1 or -1
    local err = dx - dy
    
    local curX, curY = x0, y0
    while true do
        table.insert(pixels, { curX, curY })
        if curX == x1 and curY == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            curX = curX + sx
        end
        if e2 < dx then
            err = err + dx
            curY = curY + sy
        end
    end
    return pixels
end

-- Rectangle Generator
local function getRectPixels(x0, y0, x1, y1, filled)
    local minX, maxX = math.min(x0, x1), math.max(x0, x1)
    local minY, maxY = math.min(y0, y1), math.max(y0, y1)
    local pixels = {}
    
    for y = minY, maxY do
        for x = minX, maxX do
            if filled or (x == minX or x == maxX or y == minY or y == maxY) then
                table.insert(pixels, { x, y })
            end
        end
    end
    return pixels
end

-- Circle / Ellipse Generator (Smooth, continuous, zero gaps)
local function getCirclePixels(x0, y0, x1, y1, filled)
    local minX, maxX = math.min(x0, x1), math.max(x0, x1)
    local minY, maxY = math.min(y0, y1), math.max(y0, y1)
    local pixels = {}
    
    if minX == maxX and minY == maxY then
        return { { minX, minY } }
    end
    
    local rx = (maxX - minX) / 2
    local ry = (maxY - minY) / 2
    local cx = minX + rx
    local cy = minY + ry
    
    if rx < 0.5 then rx = 0.5 end
    if ry < 0.5 then ry = 0.5 end
    
    if filled then
        for y = minY, maxY do
            for x = minX, maxX do
                local normX = (x - cx) / rx
                local normY = (y - cy) / ry
                if (normX * normX + normY * normY) <= 1.15 then
                    table.insert(pixels, { x, y })
                end
            end
        end
    else
        local plotted = {}
        local steps = math.max(16, math.floor(math.max(rx, ry) * 10))
        for i = 0, steps do
            local angle = (i / steps) * (2 * math.pi)
            local px = math.floor(cx + rx * math.cos(angle) + 0.5)
            local py = math.floor(cy + ry * math.sin(angle) + 0.5)
            local key = px .. "," .. py
            if not plotted[key] then
                plotted[key] = true
                table.insert(pixels, { px, py })
            end
        end
    end
    return pixels
end

-- Commit a Shape
local function commitShape(pixels)
    if not pixels or #pixels == 0 then return end
    for _, pt in ipairs(pixels) do
        setPixel(pt[1], pt[2], Editor.char, Editor.secondaryColor, Editor.primaryColor)
    end
    playSound("draw")
    Editor.previewPixels = {}
    Editor.shapeAnchor = nil
end

-- Apply Freehand Tools with Brush Size
local function applyFreehandTool(canvasX, canvasY)
    if canvasX < 1 or canvasX > CANVAS_W or canvasY < 1 or canvasY > CANVAS_H then return end
    
    if Editor.tool == "PENCIL" then
        setPixel(canvasX, canvasY, Editor.char, Editor.secondaryColor, Editor.primaryColor)
        playSound("draw")
    elseif Editor.tool == "BRUSH" then
        stampBrush(canvasX, canvasY, Editor.brushSize, Editor.char, Editor.secondaryColor, Editor.primaryColor)
        playSound("draw")
    elseif Editor.tool == "ERASER" then
        stampEraser(canvasX, canvasY, Editor.brushSize)
    elseif Editor.tool == "PICKER" then
        local bgHex = Canvas.bg[canvasY][canvasX]
        for col, hex in pairs(COLOR_HEX) do
            if hex == bgHex then
                Editor.primaryColor = col
                Editor.statusMessage = "Picked color: " .. COLOR_NAMES[col]
                Editor.statusTimer = 2.0
                playSound("click")
                break
            end
        end
    elseif Editor.tool == "FILL" then
        local tChar = Canvas.chars[canvasY][canvasX]
        local tFg = Canvas.fg[canvasY][canvasX]
        local tBg = Canvas.bg[canvasY][canvasX]
        floodFill(canvasX, canvasY, tChar, tFg, tBg, Editor.char, Editor.secondaryColor, Editor.primaryColor)
    elseif Editor.tool == "SPRAY" then
        local count = (Editor.brushSize == 1) and 4 or ((Editor.brushSize == 2) and 8 or 18)
        local radius = (Editor.brushSize == 1) and 1 or ((Editor.brushSize == 2) and 2 or 4)
        for _ = 1, count do
            local ox = math.random(-radius, radius)
            local oy = math.random(-math.floor(radius / 2 + 0.5), math.floor(radius / 2 + 0.5))
            setPixel(canvasX + ox, canvasY + oy, Editor.char, Editor.secondaryColor, Editor.primaryColor)
        end
        playSound("draw")
    elseif Editor.tool == "DITHER" then
        local r = (Editor.brushSize == 1) and 0 or ((Editor.brushSize == 2) and 1 or 2)
        for dy = -r, r do
            for dx = -r, r do
                local px = canvasX + dx
                local py = canvasY + dy
                local isAlt = ((px + py) % 2 == 0)
                local col = isAlt and Editor.primaryColor or Editor.secondaryColor
                setPixel(px, py, " ", colors.white, col)
            end
        end
        playSound("draw")
    end
end

-- =============================================================================
--                             SAVE / LOAD FILES
-- =============================================================================

local function saveNfpFile(filepath)
    local f = fs.open(filepath, "w")
    if not f then
        Editor.statusMessage = "Failed to save file: " .. filepath
        Editor.statusTimer = 3.0
        playSound("error")
        return false
    end
    
    for y = 1, CANVAS_H do
        local line = ""
        for x = 1, CANVAS_W do
            line = line .. Canvas.bg[y][x]
        end
        f.writeLine(line)
    end
    f.close()
    
    Editor.currentFile = filepath
    Editor.statusMessage = "File saved: " .. filepath
    Editor.statusTimer = 3.0
    playSound("save")
    return true
end

local function loadNfpFile(filepath)
    if not fs.exists(filepath) then
        Editor.statusMessage = "File not found: " .. filepath
        Editor.statusTimer = 3.0
        playSound("error")
        return false
    end
    
    local f = fs.open(filepath, "r")
    if not f then return false end
    
    pushUndo()
    local lines = {}
    local line = f.readLine()
    while line do
        table.insert(lines, line)
        line = f.readLine()
    end
    f.close()
    
    local newH = #lines
    local newW = 0
    for _, l in ipairs(lines) do
        newW = math.max(newW, #l)
    end
    
    if newW > 0 and newH > 0 then
        initCanvas(newW, newH)
        for y = 1, math.min(CANVAS_H, newH) do
            local l = lines[y]
            for x = 1, math.min(CANVAS_W, #l) do
                local ch = string.sub(l, x, x)
                Canvas.bg[y][x] = ch
                Canvas.chars[y][x] = " "
                Canvas.fg[y][x] = "0"
            end
        end
        Editor.currentFile = filepath
        Editor.statusMessage = "Loaded: " .. filepath .. " (" .. newW .. "x" .. newH .. ")"
        Editor.statusTimer = 3.0
        playSound("save")
        return true
    end
    return false
end

-- =============================================================================
--                             GUI RENDERING
-- =============================================================================

local TOOLS = {
    { id = "PENCIL", label = "PENCIL", desc = "1x1 Pixel Pencil" },
    { id = "BRUSH",  label = "BRUSH",  desc = "Multi-size Brush" },
    { id = "ERASER", label = "ERASER", desc = "Multi-size Eraser" },
    { id = "FILL",   label = "FILL",   desc = "Flood Bucket Fill" },
    { id = "LINE",   label = "LINE",   desc = "Straight Line (Drag/2-Tap)" },
    { id = "RECT",   label = "RECT",   desc = "Hollow Rect (Drag/2-Tap)" },
    { id = "BOX",    label = "BOX",    desc = "Solid Box (Drag/2-Tap)" },
    { id = "CIRCLE", label = "CIRCLE", desc = "Hollow Circle (Drag/2-Tap)" },
    { id = "DISC",   label = "DISC",   desc = "Solid Disc (Drag/2-Tap)" },
    { id = "SPRAY",  label = "SPRAY",  desc = "Airbrush Spray" },
    { id = "DITHER", label = "DITHER", desc = "2-Color Shading" },
    { id = "PICKER", label = "PICKER", desc = "Eyedropper Color Picker" },
    { id = "TEXT",   label = "TEXT",   desc = "Stamp Text on Canvas" }
}

local function renderGUI()
    clearButtons()
    display.setBackgroundColor(colors.gray)
    display.clear()
    
    -- 1. Top Bar
    drawBlit(1, 1, string.rep(" ", screenW), string.rep("0", screenW), string.rep("8", screenW))
    drawText(2, 1, "PAINT PRO 2D", colors.yellow, colors.lightGray)
    drawText(16, 1, "[" .. Editor.currentFile .. "]", colors.white, colors.lightGray)
    
    registerButton("BTN_NEW", screenW - 32, 1, 5, 1, "NEW", "0", "8", "e", "Create blank canvas")
    registerButton("BTN_OPEN", screenW - 26, 1, 6, 1, "OPEN", "0", "8", "e", "Open file")
    registerButton("BTN_SAVE", screenW - 19, 1, 6, 1, "SAVE", "0", "5", "e", "Save NFP drawing")
    registerButton("BTN_UNDO", screenW - 12, 1, 5, 1, "UNDO", "0", "8", "e", "Undo last step")
    registerButton("BTN_REDO", screenW - 6, 1, 5, 1, "REDO", "0", "8", "e", "Redo step")
    
    -- 2. Left Column: Tools
    local toolBoxW = 12
    drawBlit(1, 2, string.rep(" ", toolBoxW), string.rep("0", toolBoxW), string.rep("7", toolBoxW))
    drawText(2, 2, "- TOOLS -", colors.white, colors.gray)
    
    for i, t in ipairs(TOOLS) do
        local ty = 3 + (i - 1)
        if ty < screenH - 11 then
            local isAct = (Editor.tool == t.id)
            local fg = isAct and "0" or "f"
            local bg = isAct and "4" or "8"
            registerButton("TOOL_" .. t.id, 2, ty, toolBoxW - 2, 1, t.label, fg, bg, "e", t.desc)
        end
    end
    
    -- 3. Left Column: Brush Size Selector (S / M / L)
    local sizeY = math.min(16, screenH - 11)
    drawText(2, sizeY, "- SIZE -", colors.white, colors.gray)
    
    local sizeOpts = {
        { id = 1, label = "S", w = 3 },
        { id = 2, label = "M", w = 3 },
        { id = 3, label = "L", w = 3 }
    }
    for i, s in ipairs(sizeOpts) do
        local sx = 2 + (i - 1) * 4
        local isAct = (Editor.brushSize == s.id)
        local fg = isAct and "0" or "f"
        local bg = isAct and "5" or "8"
        registerButton("SIZE_" .. s.id, sx, sizeY + 1, 3, 1, s.label, fg, bg, "e", SIZE_NAMES[s.id])
    end
    
    -- 4. Left Column: 16-Color Palette
    local palY = sizeY + 3
    drawText(2, palY, "- COLORS -", colors.white, colors.gray)
    
    local palCols = 4
    local palRows = 4
    for i, col in ipairs(COLOR_LIST) do
        local cIdx = i - 1
        local px = 2 + (cIdx % palCols) * 2
        local py = palY + 1 + math.floor(cIdx / palCols)
        local hex = COLOR_HEX[col]
        local isPri = (Editor.primaryColor == col)
        local marker = isPri and "[]" or "  "
        registerButton("COL_" .. hex, px, py, 2, 1, marker, isPri and "0" or "f", hex, "e")
    end
    
    -- Color Indicators
    local curColY = palY + palRows + 1
    if curColY + 1 <= screenH - 1 then
        drawText(2, curColY, "Pri:", colors.white, colors.gray)
        drawBlit(7, curColY, "    ", "0000", string.rep(COLOR_HEX[Editor.primaryColor], 4))
        drawText(2, curColY + 1, "Sec:", colors.white, colors.gray)
        drawBlit(7, curColY + 1, "    ", "0000", string.rep(COLOR_HEX[Editor.secondaryColor], 4))
    end
    
    -- 5. Center Area: Canvas & Borders
    local frameFg = string.rep("8", CANVAS_W + 2)
    local frameBg = string.rep("7", CANVAS_W + 2)
    drawBlit(CANVAS_X - 1, CANVAS_Y - 1, "+" .. string.rep("-", CANVAS_W) .. "+", frameFg, frameBg)
    drawBlit(CANVAS_X - 1, CANVAS_Y + CANVAS_H, "+" .. string.rep("-", CANVAS_W) .. "+", frameFg, frameBg)
    
    for y = 1, CANVAS_H do
        drawBlit(CANVAS_X - 1, CANVAS_Y + y - 1, "|", "8", "7")
        drawBlit(CANVAS_X + CANVAS_W, CANVAS_Y + y - 1, "|", "8", "7")
        
        local lineChars = ""
        local lineFg = ""
        local lineBg = ""
        
        for x = 1, CANVAS_W do
            local ch = Canvas.chars[y][x]
            local fg = Canvas.fg[y][x]
            local bg = Canvas.bg[y][x]
            
            -- Check Anchor Marker (First tap in 2-tap mode)
            local isAnchor = (Editor.shapeAnchor and Editor.shapeAnchor.x == x and Editor.shapeAnchor.y == y)
            
            -- Preview Check
            local isPreview = false
            if Editor.previewPixels then
                for _, pt in ipairs(Editor.previewPixels) do
                    if pt[1] == x and pt[2] == y then
                        bg = COLOR_HEX[Editor.primaryColor]
                        ch = Editor.char
                        isPreview = true
                        break
                    end
                end
            end
            
            if isAnchor and not isPreview then
                ch = "+"
                fg = "4"
            elseif Editor.showGrid and not isPreview and ch == " " and ((x + y) % 2 == 0) then
                ch = "."
                fg = (bg == "f") and "7" or "f"
            end
            
            lineChars = lineChars .. ch
            lineFg = lineFg .. fg
            lineBg = lineBg .. bg
        end
        
        display.setCursorPos(CANVAS_X, CANVAS_Y + y - 1)
        pcall(function()
            display.blit(lineChars, lineFg, lineBg)
        end)
    end
    
    -- 6. Bottom Status Bar
    drawBlit(1, screenH, string.rep(" ", screenW), string.rep("0", screenW), string.rep("8", screenW))
    local coordStr = string.format("X:%02d Y:%02d", Editor.cursorX, Editor.cursorY)
    drawText(2, screenH, coordStr, colors.yellow, colors.lightGray)
    drawText(12, screenH, "| " .. Editor.tool .. " [" .. (Editor.brushSize == 1 and "S" or (Editor.brushSize == 2 and "M" or "L")) .. "]", colors.white, colors.lightGray)
    drawText(26, screenH, "| " .. Editor.statusMessage, colors.cyan, colors.lightGray)
    
    registerButton("BTN_GRID", screenW - 14, screenH, 6, 1, Editor.showGrid and "GRID*" or "GRID", "0", "8", "e", "Toggle canvas grid")
    registerButton("BTN_CLEAR", screenW - 7, screenH, 6, 1, "CLEAR", "0", "e", "4", "Clear whole canvas")
    
    -- Render All Buttons
    for _, btn in ipairs(Buttons) do
        local bFg = string.rep(btn.fg, btn.w)
        local bBg = string.rep(btn.bg, btn.w)
        for by = btn.y1, btn.y2 do
            drawBlit(btn.x1, by, string.rep(" ", btn.w), bFg, bBg)
        end
        local lblX = btn.x1 + math.floor((btn.w - #btn.label) / 2)
        local lblY = btn.y1 + math.floor((btn.h - 1) / 2)
        local lblFg = string.rep(btn.fg, #btn.label)
        local lblBg = string.rep(btn.bg, #btn.label)
        drawBlit(lblX, lblY, btn.label, lblFg, lblBg)
    end
end

-- =============================================================================
--                             MODALS & FILE EXPLORER
-- =============================================================================

local function promptTextInput(title, defaultVal)
    local boxW = 38
    local boxH = 6
    local startX = math.floor((screenW - boxW) / 2)
    local startY = math.floor((screenH - boxH) / 2)
    
    for y = startY, startY + boxH do
        drawBlit(startX, y, string.rep(" ", boxW), string.rep("0", boxW), string.rep("8", boxW))
    end
    drawText(startX + 2, startY + 1, title, colors.yellow, colors.lightGray)
    
    display.setCursorPos(startX + 2, startY + 3)
    display.setTextColor(colors.black)
    display.setBackgroundColor(colors.white)
    display.write(string.rep(" ", boxW - 4))
    
    display.setCursorPos(startX + 3, startY + 3)
    display.setCursorBlink(true)
    
    local input = read(nil, nil, nil, defaultVal)
    display.setCursorBlink(false)
    return input
end

local function runFileExplorer(mode)
    local files = fs.list("")
    local nfpFiles = {}
    for _, f in ipairs(files) do
        if not fs.isDir(f) and (string.sub(f, -4) == ".nfp" or string.sub(f, -4) == ".txt") then
            table.insert(nfpFiles, f)
        end
    end
    table.sort(nfpFiles)
    
    if mode == "SAVE" then
        local name = promptTextInput("Enter filename to save (.nfp):", Editor.currentFile)
        if name and #name > 0 then
            if not string.find(name, "%.") then name = name .. ".nfp" end
            saveNfpFile(name)
        end
        return
    end
    
    if #nfpFiles == 0 then
        Editor.statusMessage = "No .nfp files found in root directory."
        Editor.statusTimer = 3.0
        return
    end
    
    local sel = 1
    while true do
        local boxW = 40
        local boxH = math.min(14, #nfpFiles + 6)
        local startX = math.floor((screenW - boxW) / 2)
        local startY = math.floor((screenH - boxH) / 2)
        
        for y = startY, startY + boxH do
            drawBlit(startX, y, string.rep(" ", boxW), string.rep("0", boxW), string.rep("8", boxW))
        end
        
        drawText(startX + 2, startY + 1, "=== SELECT FILE TO OPEN ===", colors.yellow, colors.lightGray)
        
        for i = 1, math.min(#nfpFiles, 8) do
            local f = nfpFiles[i]
            local isSel = (i == sel)
            local fg = isSel and colors.black or colors.white
            local bg = isSel and colors.yellow or colors.gray
            drawText(startX + 2, startY + 2 + i, string.format("%-36s", f), fg, bg)
        end
        
        drawText(startX + 2, startY + boxH - 1, "[Enter] Open | [Esc] Cancel", colors.lightBlue, colors.lightGray)
        
        local ev, p1 = os.pullEvent()
        if ev == "key" then
            if p1 == keys.up or p1 == keys.w then
                sel = math.max(1, sel - 1)
                playSound("click")
            elseif p1 == keys.down or p1 == keys.s then
                sel = math.min(#nfpFiles, sel + 1)
                playSound("click")
            elseif p1 == keys.enter or p1 == keys.space then
                loadNfpFile(nfpFiles[sel])
                return
            elseif p1 == keys.escape or p1 == keys.q then
                return
            end
        elseif ev == "mouse_click" or ev == "monitor_touch" then
            return
        end
    end
end

-- =============================================================================
--                             MAIN PROGRAM LOOP
-- =============================================================================

local function main()
    initCanvas()
    local isRunning = true
    
    local timerId = os.startTimer(0.1)
    local lastTime = os.epoch("utc") / 1000.0
    
    local isShapeTool = function(tool)
        return tool == "LINE" or tool == "RECT" or tool == "BOX" or tool == "CIRCLE" or tool == "DISC"
    end
    
    local calculateShape = function(x0, y0, x1, y1, tool)
        if tool == "LINE" then
            return getLinePixels(x0, y0, x1, y1)
        elseif tool == "RECT" then
            return getRectPixels(x0, y0, x1, y1, false)
        elseif tool == "BOX" then
            return getRectPixels(x0, y0, x1, y1, true)
        elseif tool == "CIRCLE" then
            return getCirclePixels(x0, y0, x1, y1, false)
        elseif tool == "DISC" then
            return getCirclePixels(x0, y0, x1, y1, true)
        end
        return {}
    end
    
    while isRunning do
        renderGUI()
        
        local event, p1, p2, p3 = os.pullEvent()
        local curTime = os.epoch("utc") / 1000.0
        local dt = math.min(0.2, curTime - lastTime)
        lastTime = curTime
        
        if Editor.statusTimer > 0 then
            Editor.statusTimer = Editor.statusTimer - dt
            if Editor.statusTimer <= 0 then
                Editor.statusMessage = "Ready. Tool: " .. Editor.tool .. " [" .. SIZE_NAMES[Editor.brushSize] .. "]"
            end
        end
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.1)
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local btn = checkButtonClicked(mx, my)
            
            if btn then
                playSound("click")
                Editor.shapeAnchor = nil
                Editor.previewPixels = {}
                
                if btn.id == "BTN_NEW" then
                    pushUndo()
                    initCanvas()
                    Editor.statusMessage = "New blank canvas created."
                    Editor.statusTimer = 2.0
                elseif btn.id == "BTN_OPEN" then
                    runFileExplorer("OPEN")
                elseif btn.id == "BTN_SAVE" then
                    runFileExplorer("SAVE")
                elseif btn.id == "BTN_UNDO" then
                    performUndo()
                elseif btn.id == "BTN_REDO" then
                    performRedo()
                elseif btn.id == "BTN_GRID" then
                    Editor.showGrid = not Editor.showGrid
                elseif btn.id == "BTN_CLEAR" then
                    pushUndo()
                    for y = 1, CANVAS_H do
                        for x = 1, CANVAS_W do
                            Canvas.bg[y][x] = "f"
                            Canvas.chars[y][x] = " "
                        end
                    end
                    Editor.statusMessage = "Canvas cleared."
                    Editor.statusTimer = 2.0
                elseif string.sub(btn.id, 1, 5) == "TOOL_" then
                    Editor.tool = string.sub(btn.id, 6)
                    Editor.statusMessage = "Tool: " .. Editor.tool .. (isShapeTool(Editor.tool) and " (Drag or 2-Tap)" or "")
                    Editor.statusTimer = 2.5
                elseif string.sub(btn.id, 1, 5) == "SIZE_" then
                    local sNum = tonumber(string.sub(btn.id, 6))
                    if sNum then
                        Editor.brushSize = sNum
                        Editor.statusMessage = "Brush Size: " .. SIZE_NAMES[sNum]
                        Editor.statusTimer = 2.0
                        playSound("size")
                    end
                elseif string.sub(btn.id, 1, 4) == "COL_" then
                    local hex = string.sub(btn.id, 5, 5)
                    for col, h in pairs(COLOR_HEX) do
                        if h == hex then
                            if p1 == 2 then -- Right click: Secondary
                                Editor.secondaryColor = col
                                Editor.statusMessage = "Secondary color: " .. COLOR_NAMES[col]
                            else
                                Editor.primaryColor = col
                                Editor.statusMessage = "Primary color: " .. COLOR_NAMES[col]
                            end
                            Editor.statusTimer = 2.0
                            break
                        end
                    end
                end
            else
                -- Click Canvas
                if mx >= CANVAS_X and mx < CANVAS_X + CANVAS_W and my >= CANVAS_Y and my < CANVAS_Y + CANVAS_H then
                    local cx = mx - CANVAS_X + 1
                    local cy = my - CANVAS_Y + 1
                    Editor.cursorX = cx
                    Editor.cursorY = cy
                    
                    if Editor.tool == "TEXT" then
                        pushUndo()
                        local txt = promptTextInput("Enter text to stamp on canvas:", "")
                        if txt and #txt > 0 then
                            for i = 1, #txt do
                                local tx = cx + i - 1
                                if tx <= CANVAS_W then
                                    setPixel(tx, cy, string.sub(txt, i, i), Editor.secondaryColor, Editor.primaryColor)
                                end
                            end
                            playSound("draw")
                        end
                        
                    elseif isShapeTool(Editor.tool) then
                        if Editor.shapeAnchor then
                            pushUndo()
                            local shapePixels = calculateShape(Editor.shapeAnchor.x, Editor.shapeAnchor.y, cx, cy, Editor.tool)
                            commitShape(shapePixels)
                            Editor.statusMessage = Editor.tool .. " drawn!"
                            Editor.statusTimer = 2.0
                        else
                            Editor.isMouseDown = true
                            Editor.dragStartX = cx
                            Editor.dragStartY = cy
                            Editor.shapeAnchor = { x = cx, y = cy }
                            Editor.previewPixels = { {cx, cy} }
                            Editor.statusMessage = "Point 1 set (" .. cx .. "," .. cy .. "). Drag or Tap Point 2."
                            Editor.statusTimer = 4.0
                        end
                    else
                        pushUndo()
                        Editor.isMouseDown = true
                        Editor.dragStartX = cx
                        Editor.dragStartY = cy
                        applyFreehandTool(cx, cy)
                    end
                end
            end
            
        elseif event == "mouse_drag" then
            local mx, my = p2, p3
            if Editor.isMouseDown and mx >= CANVAS_X and mx < CANVAS_X + CANVAS_W and my >= CANVAS_Y and my < CANVAS_Y + CANVAS_H then
                local cx = mx - CANVAS_X + 1
                local cy = my - CANVAS_Y + 1
                Editor.cursorX = cx
                Editor.cursorY = cy
                
                if isShapeTool(Editor.tool) then
                    Editor.previewPixels = calculateShape(Editor.dragStartX, Editor.dragStartY, cx, cy, Editor.tool)
                else
                    applyFreehandTool(cx, cy)
                end
            end
            
        elseif event == "mouse_up" then
            if Editor.isMouseDown then
                local mx, my = p2, p3
                local cx = math.min(CANVAS_W, math.max(1, mx - CANVAS_X + 1))
                local cy = math.min(CANVAS_H, math.max(1, my - CANVAS_Y + 1))
                
                if isShapeTool(Editor.tool) then
                    if math.abs(cx - Editor.dragStartX) > 0 or math.abs(cy - Editor.dragStartY) > 0 then
                        pushUndo()
                        local shapePixels = calculateShape(Editor.dragStartX, Editor.dragStartY, cx, cy, Editor.tool)
                        commitShape(shapePixels)
                        Editor.statusMessage = Editor.tool .. " drawn!"
                        Editor.statusTimer = 2.0
                    end
                end
                
                Editor.isMouseDown = false
            end
            
        elseif event == "key" then
            if p1 == keys.one then
                Editor.brushSize = 1
                Editor.statusMessage = "Size: Small (1x1)"
                Editor.statusTimer = 2.0
                playSound("size")
            elseif p1 == keys.two then
                Editor.brushSize = 2
                Editor.statusMessage = "Size: Medium (2x2)"
                Editor.statusTimer = 2.0
                playSound("size")
            elseif p1 == keys.three then
                Editor.brushSize = 3
                Editor.statusMessage = "Size: Huge (3x3)"
                Editor.statusTimer = 2.0
                playSound("size")
            elseif p1 == keys.z then
                performUndo()
            elseif p1 == keys.y then
                performRedo()
            elseif p1 == keys.s then
                runFileExplorer("SAVE")
            elseif p1 == keys.o then
                runFileExplorer("OPEN")
            elseif p1 == keys.g then
                Editor.showGrid = not Editor.showGrid
            elseif p1 == keys.q or p1 == keys.escape then
                isRunning = false
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Paint Pro 2D closed.")
    else
        print("Paint Pro 2D closed. Goodbye!")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Paint Pro Error: " .. tostring(err))
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.setCursorPos(1, 1)
    print("Paint Pro Error: " .. tostring(err))
end
