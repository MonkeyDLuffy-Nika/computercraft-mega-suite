--[[
    JOJO - MISTA'S PAST (Golden Wind)
    Full-Color HD Video & Audio Player for CC: Tweaked
    Architecture: Exact 16KB Bad Apple Engine
--]]

local args = { ... }
local videoPath = args[1]
local audioPath = args[2] or "mista.dfpwm"
local targetSide = args[3]

-- 1. Locate display devices (Both Terminal AND External Monitor)
local termDisplay = term.current()
local monDisplay = nil

if targetSide then
    local p = peripheral.wrap(targetSide)
    if p and p.blit then
        monDisplay = p
    end
else
    local mon = peripheral.find("monitor")
    if mon and mon.blit then
        monDisplay = mon
    end
end

if monDisplay and monDisplay.setTextScale then
    pcall(function() monDisplay.setTextScale(0.5) end)
end

-- Primary display for size calculation
local display = monDisplay or termDisplay
local scrW, scrH = display.getSize()

-- Auto-select HD 76x38 video if on large monitor
if not videoPath then
    if scrW >= 70 and scrH >= 35 and fs.exists("mista_76x38.cfv") then
        videoPath = "mista_76x38.cfv"
    elseif fs.exists("mista.cfv") then
        videoPath = "mista.cfv"
    elseif fs.exists("mista_76x38.cfv") then
        videoPath = "mista_76x38.cfv"
    else
        videoPath = "mista.cfv"
    end
end

-- 2. Locate speaker device (Optional)
local speaker = peripheral.find("speaker")
local dfpwmModule = nil
local hasDfpwm, mod = pcall(require, "cc.audio.dfpwm")
if hasDfpwm and mod then
    dfpwmModule = mod
end

-- 3. Check Files
if not fs.exists(videoPath) then
    printError("Color video file not found: " .. tostring(videoPath))
    return
end

local hasAudio = false
if fs.exists(audioPath) and speaker and dfpwmModule then
    hasAudio = true
end

-- 4. Read Full-Color Video Data (CCV3 Format)
local vFile = fs.open(videoPath, "rb")
if not vFile then
    printError("Failed to open " .. videoPath)
    return
end

local fullContent = vFile.readAll()
vFile.close()

if not fullContent or #fullContent < 9 then
    printError("Invalid color video file (too short)")
    return
end

local magic = string.sub(fullContent, 1, 4)
if magic ~= "CCV3" then
    printError("Invalid video format! Expected CCV3 header.")
    return
end

local vidW = string.byte(fullContent, 5)
local vidH = string.byte(fullContent, 6)
local fps = string.byte(fullContent, 7)
if fps <= 0 then fps = 15 end
local b1 = string.byte(fullContent, 8)
local b2 = string.byte(fullContent, 9)
local totalFrames = b1 + b2 * 256
local vBytes = string.sub(fullContent, 10)
local vDataLen = #vBytes

-- Setup screen dimensions and offsets for both displays
local termW, termH = termDisplay.getSize()
local termOffX = math.max(1, math.floor((termW - vidW) / 2) + 1)
local termOffY = math.max(1, math.floor((termH - vidH) / 2) + 1)

local monOffX, monOffY = 1, 1
if monDisplay then
    local mW, mH = monDisplay.getSize()
    monOffX = math.max(1, math.floor((mW - vidW) / 2) + 1)
    monOffY = math.max(1, math.floor((mH - vidH) / 2) + 1)
    monDisplay.setBackgroundColor(colors.black)
    monDisplay.setTextColor(colors.white)
    monDisplay.clear()
    monDisplay.setCursorBlink(false)
end

termDisplay.setBackgroundColor(colors.black)
termDisplay.setTextColor(colors.white)
termDisplay.clear()
termDisplay.setCursorBlink(false)

local function getTime()
    if os.epoch then
        return os.epoch("utc") / 1000
    end
    return os.clock()
end

local running = true
local paused = false

-- ============================================================================
-- COROUTINE 1: AUDIO STREAMER (EXACT ORIGINAL 16KB ENGINE)
-- ============================================================================
local function playAudioCoroutine()
    if not hasAudio then
        while running do os.sleep(1) end
        return
    end

    local aFile = fs.open(audioPath, "rb")
    if not aFile then
        while running do os.sleep(1) end
        return
    end

    local decoder = dfpwmModule.make_decoder()
    local chunkSize = 16 * 1024 -- Original 16KB audio chunk

    while running do
        if not paused then
            local chunkData = aFile.read(chunkSize)
            if not chunkData then break end
            
            -- Reset Java watchdog timer so 16KB decode NEVER times out
            os.sleep(0)
            
            local pcm = decoder(chunkData)
            while not speaker.playAudio(pcm) and running and not paused do
                os.pullEvent("speaker_audio_empty")
            end
        else
            os.sleep(0.05)
        end
    end
    
    aFile.close()
    if speaker and speaker.stop then pcall(function() speaker.stop() end) end
    while running do os.sleep(0.5) end
end

-- ============================================================================
-- COROUTINE 2: HIGH-SPEED 16-COLOR VIBRANT SUBPIXEL VIDEO STREAMER
-- ============================================================================
local function playVideoCoroutine()
    local ptr = 1
    local startTime = getTime()
    local frameIdx = 0

    while running and frameIdx < totalFrames and ptr <= vDataLen do
        if not paused then
            local numChanged = string.byte(vBytes, ptr)
            ptr = ptr + 1

            for _ = 1, numChanged do
                local rIdx = string.byte(vBytes, ptr)
                ptr = ptr + 1

                local rT = string.sub(vBytes, ptr, ptr + vidW - 1)
                ptr = ptr + vidW
                local rF = string.sub(vBytes, ptr, ptr + vidW - 1)
                ptr = ptr + vidW
                local rB = string.sub(vBytes, ptr, ptr + vidW - 1)
                ptr = ptr + vidW

                -- Draw on Computer Terminal GUI
                if rIdx < termH then
                    termDisplay.setCursorPos(termOffX, termOffY + rIdx)
                    termDisplay.blit(rT, rF, rB)
                end

                -- Draw on External Monitor if connected
                if monDisplay and rIdx < scrH then
                    monDisplay.setCursorPos(monOffX, monOffY + rIdx)
                    monDisplay.blit(rT, rF, rB)
                end
            end

            frameIdx = frameIdx + 1
            local targetTime = startTime + (frameIdx / fps)
            local now = getTime()
            local dt = targetTime - now
            if dt > 0.005 then
                os.sleep(dt)
            end
        else
            os.sleep(0.05)
        end
    end
    running = false
end

-- ============================================================================
-- COROUTINE 3: KEYBOARD & TOUCH INPUT HANDLER
-- ============================================================================
local function inputCoroutine()
    while running do
        local event, key = os.pullEvent()
        if event == "key" then
            if key == keys.q or key == keys.escape or key == keys.x then
                running = false
                break
            elseif key == keys.space then
                paused = not paused
            end
        elseif event == "monitor_touch" or event == "mouse_click" then
            paused = not paused
        end
    end
end

-- Run player coroutines in parallel
parallel.waitForAny(playVideoCoroutine, playAudioCoroutine, inputCoroutine)

-- Cleanup
if speaker and speaker.stop then pcall(function() speaker.stop() end) end
termDisplay.setBackgroundColor(colors.black)
termDisplay.setTextColor(colors.white)
termDisplay.clear()
termDisplay.setCursorPos(1, 1)

if monDisplay then
    monDisplay.setBackgroundColor(colors.black)
    monDisplay.setTextColor(colors.white)
    monDisplay.clear()
    monDisplay.setCursorPos(1, 1)
end

print("Video playback ended.")
