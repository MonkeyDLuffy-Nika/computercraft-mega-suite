--[[
    🔴 LIVE TV & TWITCH STREAM PLAYER FOR COMPUTERCRAFT: TWEAKED
    Real-Time WebSocket Video & Audio Streaming Client (Multiplayer & Hosting Ready)
--]]

local args = { ... }
local configPath = ".twitch_server"

-- Load saved URL or argument or default
local serverUrl = args[1]
if not serverUrl and fs.exists(configPath) then
    local f = fs.open(configPath, "r")
    if f then
        local saved = f.readLine()
        f.close()
        if saved and #saved > 0 then
            serverUrl = saved
        end
    end
end

if not serverUrl then
    serverUrl = "ws://localhost:8080/stream"
end

-- 1. Check HTTP & WebSocket capabilities
if not http or not http.websocket then
    printError("Error: HTTP/WebSocket is disabled in ComputerCraft config!")
    return
end

-- 2. Locate Displays (Terminal AND External Monitor)
local termDisplay = term.current()
local monDisplay = peripheral.find("monitor")

if monDisplay and monDisplay.setTextScale then
    pcall(function() monDisplay.setTextScale(0.5) end)
    monDisplay.setBackgroundColor(colors.black)
    monDisplay.setTextColor(colors.white)
    monDisplay.clear()
    monDisplay.setCursorBlink(false)
end

termDisplay.setBackgroundColor(colors.black)
termDisplay.setTextColor(colors.white)
termDisplay.clear()
termDisplay.setCursorBlink(false)

-- 3. Locate Speaker (Optional)
local speaker = peripheral.find("speaker")
local dfpwmModule = nil
local hasDfpwm, mod = pcall(require, "cc.audio.dfpwm")
if hasDfpwm and mod then
    dfpwmModule = mod
end

local function connectWebSocket(url)
    termDisplay.setCursorPos(1, 2)
    termDisplay.setTextColor(colors.red)
    termDisplay.write(" [🔴 LIVE TV] ")
    termDisplay.setTextColor(colors.white)
    termDisplay.write("Connecting to: ")
    termDisplay.setCursorPos(1, 3)
    termDisplay.setTextColor(colors.yellow)
    termDisplay.write(url)

    if monDisplay then
        monDisplay.setCursorPos(1, 2)
        monDisplay.setTextColor(colors.red)
        monDisplay.write(" [🔴 LIVE TV] ")
        monDisplay.setTextColor(colors.white)
        monDisplay.write("Connecting to " .. url)
    end

    local ws, err = http.websocket(url)
    return ws, err
end

local ws, err = connectWebSocket(serverUrl)

-- If connection failed, allow user to enter their PC IP / Tunnel URL directly in-game!
if not ws then
    termDisplay.setTextColor(colors.red)
    termDisplay.setCursorPos(1, 5)
    print("Connection failed: " .. tostring(err))
    
    termDisplay.setTextColor(colors.lightGray)
    print("\nIf playing on a SERVER HOSTING:")
    print("1. Allow '$private' in serverconfig/computercraft-server.toml")
    print("2. OR enter your PC's IP or Tunnel URL below:")
    
    termDisplay.setTextColor(colors.lime)
    write("\nEnter WebSocket URL [ws://...]: ")
    termDisplay.setTextColor(colors.white)
    local inputUrl = read()
    
    if inputUrl and #inputUrl > 3 then
        if not string.find(inputUrl, "^ws://") and not string.find(inputUrl, "^wss://") then
            inputUrl = "ws://" .. inputUrl
        end
        if not string.find(inputUrl, "/stream") then
            inputUrl = inputUrl .. "/stream"
        end
        serverUrl = inputUrl
        
        -- Save for future launches
        local f = fs.open(configPath, "w")
        if f then
            f.writeLine(serverUrl)
            f.close()
        end
        
        termDisplay.clear()
        ws, err = connectWebSocket(serverUrl)
    end
end

if not ws then
    termDisplay.setTextColor(colors.red)
    print("\nCould not connect to " .. tostring(serverUrl))
    print("Error: " .. tostring(err))
    return
end

termDisplay.clear()
if monDisplay then monDisplay.clear() end

local decoder = dfpwmModule and dfpwmModule.make_decoder() or nil
local running = true
local muted = false
local showHud = true
local frameCount = 0
local fps = 0
local lastFpsTime = os.epoch("utc") / 1000

local termW, termH = termDisplay.getSize()
local monW, monH = monDisplay and monDisplay.getSize() or 1, 1

-- ============================================================================
-- COROUTINE 1: LIVE STREAM RECEIVER & RENDERER
-- ============================================================================
local function streamCoroutine()
    while running do
        local msg, isBinary = ws.receive()
        if not msg then
            break
        end

        local pLen = #msg
        if pLen >= 4 then
            local pType = string.byte(msg, 1)
            local vidW = string.byte(msg, 2)
            local vidH = string.byte(msg, 3)
            local numChanged = string.byte(msg, 4)

            local termOffX = math.max(1, math.floor((termW - vidW) / 2) + 1)
            local termOffY = math.max(1, math.floor((termH - vidH) / 2) + 1)

            local monOffX, monOffY = 1, 1
            if monDisplay then
                monOffX = math.max(1, math.floor((monW - vidW) / 2) + 1)
                monOffY = math.max(1, math.floor((monH - vidH) / 2) + 1)
            end

            local ptr = 5
            for _ = 1, numChanged do
                if ptr + 1 + vidW * 3 - 1 > pLen then break end
                local rIdx = string.byte(msg, ptr)
                ptr = ptr + 1

                local rT = string.sub(msg, ptr, ptr + vidW - 1)
                ptr = ptr + vidW
                local rF = string.sub(msg, ptr, ptr + vidW - 1)
                ptr = ptr + vidW
                local rB = string.sub(msg, ptr, ptr + vidW - 1)
                ptr = ptr + vidW

                -- Render to Computer Terminal
                if rIdx < termH then
                    termDisplay.setCursorPos(termOffX, termOffY + rIdx)
                    termDisplay.blit(rT, rF, rB)
                end

                -- Render to External Monitor
                if monDisplay and rIdx < monH then
                    monDisplay.setCursorPos(monOffX, monOffY + rIdx)
                    monDisplay.blit(rT, rF, rB)
                end
            end

            -- Read and play audio if included
            if ptr + 2 <= pLen and speaker and decoder and not muted then
                local a1 = string.byte(msg, ptr)
                local a2 = string.byte(msg, ptr + 1)
                ptr = ptr + 2
                local aLen = a1 + a2 * 256
                if aLen > 0 and ptr + aLen - 1 <= pLen then
                    local audioBytes = string.sub(msg, ptr, ptr + aLen - 1)
                    local pcm = decoder(audioBytes)
                    speaker.playAudio(pcm)
                end
            end

            -- FPS Counter
            frameCount = frameCount + 1
            local now = os.epoch("utc") / 1000
            if now - lastFpsTime >= 1.0 then
                fps = math.floor(frameCount / (now - lastFpsTime))
                frameCount = 0
                lastFpsTime = now

                -- Draw HUD on top row
                if showHud then
                    local hudStr = string.format(" 🔴 LIVE | FPS: %2d | [M] %s | [Q] Exit ", fps, muted and "MUTED" or "AUDIO ON")
                    
                    termDisplay.setCursorPos(1, 1)
                    termDisplay.setBackgroundColor(colors.gray)
                    termDisplay.setTextColor(colors.white)
                    termDisplay.write(hudStr)

                    if monDisplay then
                        monDisplay.setCursorPos(1, 1)
                        monDisplay.setBackgroundColor(colors.gray)
                        monDisplay.setTextColor(colors.white)
                        monDisplay.write(hudStr)
                    end
                end
            end
        end
    end
    running = false
end

-- ============================================================================
-- COROUTINE 2: INPUT HANDLER
-- ============================================================================
local function inputCoroutine()
    while running do
        local event, key = os.pullEvent()
        if event == "key" then
            if key == keys.q or key == keys.escape or key == keys.x then
                running = false
                break
            elseif key == keys.m or key == keys.space then
                muted = not muted
                if muted and speaker and speaker.stop then
                    pcall(function() speaker.stop() end)
                end
            elseif key == keys.h then
                showHud = not showHud
                if not showHud then
                    termDisplay.setCursorPos(1, 1)
                    termDisplay.write(string.rep(" ", termW))
                    if monDisplay then
                        monDisplay.setCursorPos(1, 1)
                        monDisplay.write(string.rep(" ", monW))
                    end
                end
            end
        elseif event == "monitor_touch" or event == "mouse_click" then
            muted = not muted
            if muted and speaker and speaker.stop then
                pcall(function() speaker.stop() end)
            end
        end
    end
end

-- Run streaming and input coroutines
parallel.waitForAny(streamCoroutine, inputCoroutine)

-- Cleanup
pcall(function() ws.close() end)
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

print("Live stream session ended.")
