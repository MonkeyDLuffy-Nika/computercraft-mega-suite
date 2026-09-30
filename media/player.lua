--[[
    Bad Apple Player for ComputerCraft: Tweaked (Minecraft)
    Plays compressed CCV2 video (.dfv) and DFPWM audio (.dfpwm)
    Supports Terminal & Monitors with Dual-Display Rendering & 16KB Audio Chunks
--]]

local args = { ... }
local videoPath = args[1] or "bad_apple.dfv"
local audioPath = args[2] or "bad_apple.dfpwm"
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

-- Auto-select HD video if monitor is large
if (videoPath == "bad_apple.dfv" or not videoPath) and scrW >= 70 and scrH >= 35 and fs.exists("bad_apple_76x38.dfv") then
    videoPath = "bad_apple_76x38.dfv"
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
    printError("Video file not found: " .. tostring(videoPath))
    print("Usage: player.lua [video.dfv] [audio.dfpwm] [monitor_side]")
    return
end

local hasAudio = false
if fs.exists(audioPath) and speaker and dfpwmModule then
    hasAudio = true
end

-- 4. Fast Teletext 2x3 Lookup Tables
local lut_char = {}
local lut_fg = {}
local lut_bg = {}
local space_runs = {}

for m = 0, 63 do
    if m < 32 then
        lut_char[m] = string.char(128 + m)
        lut_fg[m] = "0"
        lut_bg[m] = "f"
    else
        lut_char[m] = string.char(128 + (63 - m))
        lut_fg[m] = "f"
        lut_bg[m] = "0"
    end
end

for count = 1, 160 do
    space_runs[count] = string.rep(" ", count)
end

local function get_spaces(count)
    return space_runs[count] or string.rep(" ", count)
end

-- 5. Read Video Data
local vFile = fs.open(videoPath, "rb")
if not vFile then
    printError("Failed to open " .. videoPath)
    return
end

local fullContent = vFile.readAll()
vFile.close()

if not fullContent or #fullContent < 9 then
    printError("Invalid video file (too short)")
    return
end

local magic = string.sub(fullContent, 1, 4)
if magic ~= "CCV2" then
    printError("Invalid video format! Expected CCV2 header.")
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

-- Coroutine: Audio Streamer (Original 16KB Chunks with CPU Watchdog Reset)
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

-- Coroutine: Video Streamer (Renders to Both Terminal and Monitor)
local function playVideoCoroutine()
    local ptr = 1
    local row_text = {}
    local row_fg = {}
    local row_bg = {}
    for r = 0, vidH - 1 do
        row_text[r] = get_spaces(vidW)
        row_fg[r] = string.rep("0", vidW)
        row_bg[r] = string.rep("f", vidW)
    end

    local startTime = getTime()
    local frameIdx = 0

    while running and frameIdx < totalFrames and ptr <= vDataLen do
        if not paused then
            local numChanged = string.byte(vBytes, ptr)
            ptr = ptr + 1

            for _ = 1, numChanged do
                local rIdx = string.byte(vBytes, ptr)
                local cLen = string.byte(vBytes, ptr + 1)
                ptr = ptr + 2

                local endPos = ptr + cLen
                local tParts, fgParts, bgParts = {}, {}, {}
                local pIdx = 1

                while ptr < endPos do
                    local b = string.byte(vBytes, ptr)
                    ptr = ptr + 1

                    if b < 64 then
                        tParts[pIdx] = lut_char[b]
                        fgParts[pIdx] = lut_fg[b]
                        bgParts[pIdx] = lut_bg[b]
                        pIdx = pIdx + 1
                    elseif b < 128 then
                        local count = b - 64 + 2
                        tParts[pIdx] = get_spaces(count)
                        fgParts[pIdx] = string.rep("0", count)
                        bgParts[pIdx] = string.rep("f", count)
                        pIdx = pIdx + 1
                    elseif b < 192 then
                        local count = b - 128 + 2
                        tParts[pIdx] = get_spaces(count)
                        fgParts[pIdx] = string.rep("f", count)
                        bgParts[pIdx] = string.rep("0", count)
                        pIdx = pIdx + 1
                    else
                        local count = b - 192 + 2
                        local m = string.byte(vBytes, ptr)
                        ptr = ptr + 1
                        tParts[pIdx] = string.rep(lut_char[m], count)
                        fgParts[pIdx] = string.rep(lut_fg[m], count)
                        bgParts[pIdx] = string.rep(lut_bg[m], count)
                        pIdx = pIdx + 1
                    end
                end

                local rT = table.concat(tParts)
                local rF = table.concat(fgParts)
                local rB = table.concat(bgParts)
                row_text[rIdx] = rT
                row_fg[rIdx] = rF
                row_bg[rIdx] = rB

                -- Draw on Computer Terminal GUI
                termDisplay.setCursorPos(termOffX, termOffY + rIdx)
                termDisplay.blit(rT, rF, rB)

                -- Draw on External Monitor if present
                if monDisplay then
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

-- Coroutine: Input Handler
local function inputCoroutine()
    while running do
        local event, key = os.pullEvent()
        if event == "key" then
            if key == keys.q or key == keys.escape then
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

print("Playback ended.")
