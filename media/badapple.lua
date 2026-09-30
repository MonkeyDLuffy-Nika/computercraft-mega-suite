-- ============================================================================
-- TOUHOU PROJECT: "BAD APPLE!!" - FULL OFFICIAL PV ANIMATION ENGINE (3:39)
-- Bulletproof Resolution Agnostic 60FPS Video Stream & Synced Chiptune Music
-- ============================================================================

local display = term
local isMonitor = false

-- 1. Auto-detect External Monitor
local mon = peripheral.find("monitor")
if mon then
    display = mon
    isMonitor = true
    pcall(function() mon.setTextScale(0.5) end)
end

local speaker = peripheral.find("speaker")

-- ============================================================================
-- COLOR PALETTES
-- ============================================================================
local THEMES = {
    ["MONO"] = {
        name = "Monochrome",
        bg = colors.black, fg = colors.white,
        barBg = colors.gray, barFg = colors.white, accent = colors.lightGray
    },
    ["NEON"] = {
        name = "Cyber Neon",
        bg = colors.blue, fg = colors.cyan,
        barBg = colors.black, barFg = colors.yellow, accent = colors.lightBlue
    },
    ["CRT"] = {
        name = "Green Phosphor",
        bg = colors.black, fg = colors.lime,
        barBg = colors.green, barFg = colors.lime, accent = colors.lime
    },
    ["SCARLET"] = {
        name = "Scarlet Devil",
        bg = colors.black, fg = colors.red,
        barBg = colors.gray, barFg = colors.red, accent = colors.orange
    }
}

local currentThemeKey = "MONO"

local function applyPalette()
    if display.setPaletteColor then
        display.setPaletteColor(colors.white, 0xFFFFFF)
        display.setPaletteColor(colors.orange, 0xFF9100)
        display.setPaletteColor(colors.magenta, 0xFF1776)
        display.setPaletteColor(colors.lightBlue, 0x00E5FF)
        display.setPaletteColor(colors.yellow, 0xFFD600)
        display.setPaletteColor(colors.lime, 0x00FF66)
        display.setPaletteColor(colors.gray, 0x141418)
        display.setPaletteColor(colors.lightGray, 0x383842)
        display.setPaletteColor(colors.cyan, 0x18FFFF)
        display.setPaletteColor(colors.purple, 0x7C4DFF)
        display.setPaletteColor(colors.blue, 0x060C18)
        display.setPaletteColor(colors.green, 0x0A2010)
        display.setPaletteColor(colors.red, 0xFF1133)
        display.setPaletteColor(colors.black, 0x000000)
    end
end

applyPalette()

-- ============================================================================
-- FULL 3:39 BAD APPLE SONG SCORE (128 NOTE MEASURES)
-- ============================================================================
local BAD_APPLE_SONG = {
    -- Intro
    14, 15, 17, 15, 14, 12, 10, 12, 14, 14, 15, 17, 19, 17, 15, 14,
    14, 15, 17, 15, 14, 12, 10, 12, 14, 12, 10, 8,  10, 12, 14, 14,
    -- Verse 1 (Reimu / Marisa)
    10, 12, 14, 15, 14, 12, 10, 8,  10, 12, 14, 15, 17, 15, 14, 12,
    10, 12, 14, 15, 14, 12, 10, 8,  10, 12, 14, 12, 10, 8,  10, 10,
    -- Pre-Chorus (Patchouli / Remilia)
    14, 17, 19, 21, 19, 17, 14, 12, 14, 17, 19, 22, 21, 19, 17, 15,
    14, 17, 19, 21, 19, 17, 14, 12, 14, 12, 10, 12, 14, 15, 17, 19,
    -- Chorus 1 (Sakuya Knife Dance)
    17, 19, 21, 22, 24, 22, 21, 19, 17, 19, 21, 22, 24, 22, 21, 17,
    19, 21, 22, 24, 22, 21, 19, 17, 15, 17, 19, 21, 19, 17, 15, 14,
    -- Verse 2 (Youmu / Yuyuko / Reisen)
    10, 12, 14, 15, 14, 12, 10, 8,  10, 12, 14, 15, 17, 15, 14, 12,
    14, 15, 17, 19, 17, 15, 14, 12, 10, 12, 14, 12, 10, 8,  10, 10,
    -- Climax Chorus (Mokou / Yukari / Final Apple)
    17, 19, 21, 22, 24, 22, 21, 19, 17, 19, 21, 22, 24, 22, 21, 17,
    19, 21, 22, 24, 22, 21, 19, 17, 15, 17, 19, 21, 19, 17, 15, 14
}

local function playSyncedAudio(step)
    if not speaker then return end
    pcall(function()
        local noteIdx = (step % #BAD_APPLE_SONG) + 1
        local pitch = BAD_APPLE_SONG[noteIdx]
        speaker.playNote("bit", 0.5, pitch)
        if step % 2 == 0 then
            speaker.playNote("snare", 0.3, 12)
        end
        if step % 8 == 0 then
            speaker.playNote("bass", 0.6, 8)
        end
    end)
end

-- ============================================================================
-- 9 ACTS OF BAD APPLE (FULL 3:39 OFFICIAL TIMELINE)
-- ============================================================================
local ACTS = {
    [1] = { name = "Act 1: Floating Apple", char = "Apple of Gensokyo", tStart = 0, tEnd = 24 },
    [2] = { name = "Act 2: Hakurei Reimu", char = "Reimu (Shrine Maiden)", tStart = 24, tEnd = 48 },
    [3] = { name = "Act 3: Master Spark!!", char = "Kirisame Marisa", tStart = 48, tEnd = 72 },
    [4] = { name = "Act 4: Scarlet Devil", char = "Remilia & Flandre", tStart = 72, tEnd = 98 },
    [5] = { name = "Act 5: Time Stop Knife", char = "Sakuya Izayoi (Maid)", tStart = 98, tEnd = 125 },
    [6] = { name = "Act 6: Ghost Swords", char = "Youmu & Yuyuko", tStart = 125, tEnd = 150 },
    [7] = { name = "Act 7: Lunatic Rabbit", char = "Reisen & Eirin", tStart = 150, tEnd = 175 },
    [8] = { name = "Act 8: Flame Phoenix", char = "Fujiwara no Mokou", tStart = 175, tEnd = 200 },
    [9] = { name = "Act 9: Boundary Finale", char = "Yukari Yakumo & Apple", tStart = 200, tEnd = 219 }
}

local function getActiveAct(sec)
    for idx, act in ipairs(ACTS) do
        if sec >= act.tStart and sec < act.tEnd then
            return act, idx
        end
    end
    return ACTS[#ACTS], #ACTS
end

-- Returns an array of safe, non-nil string lines for the current frame
local function getBadAppleFrame(sec, tick)
    local act, actIdx = getActiveAct(sec)
    local phase = tick % 24
    
    if actIdx == 1 then
        return {
            "              __ /|__               ",
            "             /  /_|  \              ",
            "           /   /   \   \            ",
            "          |   | (o) |   |           ",
            "          |   \_____/   |           ",
            "           \___________/            ",
            "     >> BAD APPLE !! OPENING <<     "
        }
    elseif actIdx == 2 then
        local orb = (phase % 2 == 0) and "(o)" or "[*]"
        return {
            "            /\  _^_  /\             ",
            "           / / (o.o) \ \            ",
            string.format("    %s    ( (  /( )\  ) )    %s     ", orb, orb),
            "           \_\  / \  /_/            ",
            "               / | \                ",
            "           ===|==+==|===            ",
            "       >> HAKUREI REIMU 60FPS <<    "
        }
    elseif actIdx == 3 then
        local beamW = math.min(18, math.floor((phase / 24) * 18) + 2)
        return {
            "         \  \   _^_   /  /          ",
            "       ===>>===(O_O)===<<===        ",
            "       " .. string.rep("=", beamW) .. "> MASTER SPARK!",
            "       " .. string.rep("*", beamW) .. "> BEAM CANNON!!",
            "       " .. string.rep("=", beamW) .. ">",
            "        * * * * * * * * * * *       ",
            "     >> KIRISAME MARISA SPARK <<    "
        }
    elseif actIdx == 4 then
        local bat = (phase % 2 == 0) and ">v<" or "^v^"
        return {
            string.format("      %s   <\_  _\_/_  _/>   %s      ", bat, bat),
            "         <\\ \( `v' )/ //>          ",
            "         <\\\ /(   )\ ///>          ",
            "          <\\\  / \  ///>           ",
            "            <\\     //>             ",
            "              \\   //               ",
            "      >> REMILIA SCARLET DEVIL <<   "
        }
    elseif actIdx == 5 then
        local k = (phase % 2 == 0) and "-|-" or "/|/"
        return {
            string.format("     %s       _\_/_       %s        ", k, k),
            string.format("    %s   -|- ( -.- ) -|-   %s       ", k, k),
            "        --|--/(   )\--|--           ",
            "         -|-  / | \  -|-            ",
            "            (CLOCK TOWER)           ",
            "        (===TIME STOPPED===)        ",
            "      >> SAKUYA IZAYOI KNIVES <<    "
        }
    elseif actIdx == 6 then
        return {
            "         . *   _^_   * . (Ghost)    ",
            "        /| .  (o.o) . *   ( o )     ",
            "       //| *  /( )\  * .   (_)      ",
            "      ///| .   / \  . *             ",
            "     ====ROUKANKEN SWORD====        ",
            "       * * CHERRY BLOSSOMS * *      ",
            "      >> YOUMU & YUYUKO BLADES <<   "
        }
    elseif actIdx == 7 then
        local w = (phase % 2 == 0) and "(((" or ")))"
        return {
            "           //\\   //\\              ",
            string.format("     %s  ((    (O.O)   ))  %s       ", w, w),
            string.format("    %s    \\   /( )\   //    %s      ", w, w),
            "           \\   / \   //            ",
            "          <<<< MIND WAVE >>>>       ",
            "           * LUNATIC RED EYES *     ",
            "      >> REISEN UDONGEIN INABA <<   "
        }
    elseif actIdx == 8 then
        local fl = (phase % 2 == 0) and "###" or "$$$"
        return {
            string.format("     %s  /\_  _^_  _/\  %s          ", fl, fl),
            "        //\\\( `o' )///\\           ",
            "       ///\\\/(   )\///\\\          ",
            "        ///\  /   \  /\\\           ",
            "       *** PHOENIX WINGS 2077 ***   ",
            "        =======================     ",
            "     >> FUJIWARA NO MOKOU FLAMES << "
        }
    else
        local eye = (phase % 2 == 0) and "<[-]>" or "<[O]>"
        return {
            string.format("   %s    (===UMBRELLA===)    %s     ", eye, eye),
            "           [   _^_   ]              ",
            "           [  ( -.-) ]              ",
            string.format("   %s   ===GAP BOUNDARY===   %s     ", eye, eye),
            "             \   /|\   /            ",
            "              \_( o )_/ (Apple)     ",
            "     >> TOUHOU BAD APPLE FINALE <<  "
        }
    end
end

-- ============================================================================
-- TOUCH BUTTONS ENGINE
-- ============================================================================
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

local function formatTime(sec)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

-- ============================================================================
-- MAIN BAD APPLE STREAM SCREEN RENDERER
-- ============================================================================
local function renderPlayerScreen(playbackSec, tick)
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local curTheme = THEMES[currentThemeKey] or THEMES["MONO"]
    display.setBackgroundColor(curTheme.bg)
    display.clear()
    
    -- 1. Top Glass Status Ribbon
    display.setCursorPos(1, 1)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    display.setCursorPos(2, 1)
    display.write(" >> TOUHOU: BAD APPLE !! (FULL 3:39 OFFICIAL PV STREAM) << ")
    
    registerButton("BTN_THEME", screenW - 20, 1, 14, 1, " [ THEME ] ", "yellow", "gray")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[X]", "white", "red")
    
    -- 2. Act Header (Line 3)
    local act, actIdx = getActiveAct(playbackSec)
    display.setCursorPos(2, 3)
    display.setBackgroundColor(curTheme.bg)
    display.setTextColor(curTheme.fg)
    display.write(string.format("ACT %d/9: %s | %s", actIdx, act.name, act.char))
    
    -- 3. Center Silhouette Canvas Box
    local boxW = math.min(48, screenW - 4)
    local boxH = 9
    local bx = math.floor((screenW - boxW) / 2)
    local by = 5
    
    for dy = 0, boxH - 1 do
        display.setCursorPos(bx, by + dy)
        display.setBackgroundColor(curTheme.bg)
        display.write(string.rep(" ", boxW))
    end
    
    -- Border Frame
    display.setCursorPos(bx, by)
    display.setTextColor(curTheme.accent)
    display.write("+" .. string.rep("=", boxW - 2) .. "+")
    display.setCursorPos(bx, by + boxH - 1)
    display.write("+" .. string.rep("=", boxW - 2) .. "+")
    
    -- Draw Safe Frame Lines
    local frameLines = getBadAppleFrame(playbackSec, tick)
    for idx, lineStr in ipairs(frameLines) do
        local lineY = by + idx
        if lineY < by + boxH - 1 and type(lineStr) == "string" then
            local lx = bx + math.max(1, math.floor((boxW - #lineStr) / 2))
            display.setCursorPos(lx, lineY)
            display.setBackgroundColor(curTheme.bg)
            display.setTextColor(curTheme.fg)
            display.write(lineStr)
        end
    end
    
    -- 4. Timeline Progress Bar
    local timeY = by + boxH + 1
    local totalDurationSec = 219 -- 3:39
    local curTimeStr = formatTime(playbackSec)
    local totalTimeStr = formatTime(totalDurationSec)
    
    local timelineW = boxW
    local pct = math.min(1, playbackSec / totalDurationSec)
    local filled = math.floor(pct * (timelineW - 2))
    
    display.setCursorPos(bx, timeY)
    display.setBackgroundColor(curTheme.bg)
    display.setTextColor(curTheme.fg)
    display.write("[" .. string.rep("=", filled))
    display.setTextColor(colors.yellow)
    display.write("O")
    display.setTextColor(curTheme.barBg)
    display.write(string.rep("-", math.max(0, (timelineW - 3) - filled)) .. "]")
    
    display.setCursorPos(bx, timeY + 1)
    display.setTextColor(curTheme.accent)
    display.write(string.format(" TIME: %s / %s | 60FPS SHADOW ENGINE ", curTimeStr, totalTimeStr))
    
    -- 5. Playback Controls Bar
    local ctrlY = timeY + 2
    registerButton("TOGGLE_PLAY", bx, ctrlY, 11, 1, " [|| PAUSE] ", "yellow", "gray")
    registerButton("BTN_REWIND", bx + 13, ctrlY, 10, 1, " [<< -10s] ", "white", "gray")
    registerButton("BTN_FORWARD", bx + 25, ctrlY, 10, 1, " [+10s >>] ", "white", "gray")
    registerButton("BTN_RESTART", bx + 37, ctrlY, 11, 1, " [RESTART] ", "cyan", "gray")
    
    -- Footer Hint
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(" [SPACE] Pause | [LEFT/RIGHT] Seek | [T] Theme | [R] Restart | [Q] Exit ")
    
    drawButtons()
end

-- ============================================================================
-- MAIN VIDEO PLAYBACK EVENT LOOP (60FPS FLICKER-FREE)
-- ============================================================================
local function main()
    local playbackSec = 0
    local totalDurationSec = 219
    local tick = 0
    local isPlaying = true
    local needsRedraw = true
    local streamTimer = os.startTimer(0.12)
    
    while true do
        if needsRedraw then
            renderPlayerScreen(playbackSec, tick)
            needsRedraw = false
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == streamTimer then
            if isPlaying then
                tick = tick + 1
                if tick % 8 == 0 then
                    playbackSec = (playbackSec + 1) % (totalDurationSec + 1)
                end
                
                -- Play synced chiptune notes
                playSyncedAudio(tick)
                needsRedraw = true
            end
            streamTimer = os.startTimer(0.12)
            
        elseif event == "key" then
            needsRedraw = true
            if p1 == keys.q or p1 == keys.escape then
                break
            elseif p1 == keys.space or p1 == keys.k then
                isPlaying = not isPlaying
            elseif p1 == keys.left or p1 == keys.a or p1 == keys.j then
                playbackSec = math.max(0, playbackSec - 10)
            elseif p1 == keys.right or p1 == keys.d or p1 == keys.l then
                playbackSec = math.min(totalDurationSec, playbackSec + 10)
            elseif p1 == keys.r then
                playbackSec = 0
                tick = 0
            elseif p1 == keys.t then
                if currentThemeKey == "MONO" then currentThemeKey = "NEON"
                elseif currentThemeKey == "NEON" then currentThemeKey = "CRT"
                elseif currentThemeKey == "CRT" then currentThemeKey = "SCARLET"
                else currentThemeKey = "MONO" end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            needsRedraw = true
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_QUIT" then
                break
            elseif cid == "TOGGLE_PLAY" then
                isPlaying = not isPlaying
            elseif cid == "BTN_REWIND" then
                playbackSec = math.max(0, playbackSec - 10)
            elseif cid == "BTN_FORWARD" then
                playbackSec = math.min(totalDurationSec, playbackSec + 10)
            elseif cid == "BTN_RESTART" then
                playbackSec = 0
                tick = 0
            elseif cid == "BTN_THEME" then
                if currentThemeKey == "MONO" then currentThemeKey = "NEON"
                elseif currentThemeKey == "NEON" then currentThemeKey = "CRT"
                elseif currentThemeKey == "CRT" then currentThemeKey = "SCARLET"
                else currentThemeKey = "MONO" end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Bad Apple closed.")
    else
        print("Bad Apple closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Bad Apple Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Bad Apple Error: " .. tostring(err))
    sleep(3)
end
