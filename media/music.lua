--[[
    DFPWM Canonical Audio Player for ComputerCraft: Tweaked
    100% Gapless, Non-Discarding, Studio-Quality 48kHz Audio Stream
--]]

local args = { ... }
local audioPath = args[1] or "bad_apple.dfpwm"

local speaker = peripheral.find("speaker")
if not speaker then
    printError("Speaker peripheral not found! Attach a Speaker to play audio.")
    return
end

local hasDfpwm, dfpwm = pcall(require, "cc.audio.dfpwm")
if not hasDfpwm or not dfpwm then
    printError("cc.audio.dfpwm module not available in this CC version.")
    return
end

if not fs.exists(audioPath) then
    printError("Audio file not found: " .. tostring(audioPath))
    return
end

print(">> Playing audio: " .. audioPath)
print("Controls: Press [Q] to Stop.")

local decoder = dfpwm.make_decoder()
local file = fs.open(audioPath, "rb")
if not file then
    printError("Failed to open audio file.")
    return
end

local running = true

local function audioLoop()
    -- Standard 2KB DFPWM chunk (16384 samples)
    local chunkSize = 16 * 1024 / 8
    
    while running do
        local chunk = file.read(chunkSize)
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        -- Never discard audio chunks: keep retrying until speaker accepts it
        while running and not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file.close()
    if speaker.stop then pcall(function() speaker.stop() end) end
    running = false
end

local function inputLoop()
    while running do
        local ev, k = os.pullEvent("key")
        if k == keys.q or k == keys.escape or k == keys.x then
            running = false
            if speaker.stop then pcall(function() speaker.stop() end) end
            break
        end
    end
end

parallel.waitForAny(audioLoop, inputLoop)

if speaker.stop then pcall(function() speaker.stop() end) end
print("Playback ended.")
