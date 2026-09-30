-- ============================================================================
-- CYBER WIRELESS REMOTE & BASE STATION HUB - CC: TWEAKED
-- Universal Multi-Device Remote Control, Redstone, Chat, Alarms & Telemetry
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
    [colors.gray]      = 0x3C3C46,
    [colors.lightGray] = 0xAAAFB9,
    [colors.cyan]      = 0x1ED2DC,
    [colors.purple]    = 0xA03CEB,
    [colors.blue]      = 0x285FEB,
    [colors.brown]     = 0x9B653B,
    [colors.green]     = 0x2DA537,
    [colors.red]       = 0xEB372D,
    [colors.black]     = 0x08080C
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- MODEM & REDNET SETUP
-- ============================================================================
local modemSide = nil
local modem = peripheral.find("modem", function(name, o)
    if o.isWireless() then
        modemSide = name
        return true
    end
    return false
end)

if not modem then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 2)
    display.write(" [!] ERROR: NO WIRELESS MODEM DETECTED! ")
    display.setCursorPos(1, 4)
    display.setTextColor(colors.yellow)
    display.write(" Please attach a Wireless Modem or Ender Modem")
    display.setCursorPos(1, 5)
    display.write(" to any side of this computer / pocket PC.")
    return
end

rednet.open(modemSide)
local myID = os.getComputerID()
local PROTOCOL = "CYBER_WIRELESS_NET"

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

local function playChime(pitch)
    if speaker then
        pcall(function() speaker.playNote("chime", 0.6, pitch or 12) end)
    end
end

-- ============================================================================
-- BASE STATION (SERVER / HOST MODE)
-- ============================================================================
local function runBaseStation()
    local logs = {}
    local function addLog(text, colorName)
        table.insert(logs, { text = text, color = colorName or "lightBlue", time = os.date("%H:%M:%S") })
        if #logs > 14 then table.remove(logs, 1) end
    end
    
    addLog("Base Station started on ID #" .. myID, "lime")
    addLog("Wireless modem open on: " .. tostring(modemSide), "cyan")
    addLog("Listening for remote commands...", "yellow")
    
    local redstoneSides = { "top", "bottom", "left", "right", "front", "back" }
    local rsStates = {}
    for _, s in ipairs(redstoneSides) do rsStates[s] = redstone.getOutput(s) end
    
    local function renderBase()
        local screenW, screenH = display.getSize()
        clearButtons()
        
        display.setBackgroundColor(colors.black)
        display.clear()
        
        -- Header Bar
        display.setCursorPos(1, 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        local headerText = string.format(" [ BASE STATION HUB - ID: #%d ]   MODEM: %s ", myID, string.upper(modemSide))
        display.setCursorPos(math.max(1, math.floor((screenW - #headerText) / 2)), 1)
        display.write(headerText)
        
        -- Left Panel: Redstone Outputs
        display.setCursorPos(2, 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" [ REDSTONE SIGNALS ] ")
        
        for idx, s in ipairs(redstoneSides) do
            local y = 4 + idx
            display.setCursorPos(2, y)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.white)
            display.write(string.format(" %-7s: ", string.upper(s)))
            local isHigh = rsStates[s]
            display.setBackgroundColor(isHigh and colors.red or colors.gray)
            display.setTextColor(colors.white)
            display.write(isHigh and " [ ON ] " or " [OFF] ")
            registerButton("BTN_TOGGLE_" .. s, 14, y, 7, 1, isHigh and "[ ON ]" or "[OFF]", "white", isHigh and "red" or "gray")
        end
        
        -- Right Panel: Real-Time Event Logs
        local logX = math.max(24, math.floor(screenW * 0.38))
        local logW = screenW - logX - 1
        display.setCursorPos(logX, 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write(" [ WIRELESS TRAFFIC & EVENT LOGS ] ")
        
        for idx, l in ipairs(logs) do
            local ly = 4 + idx
            if ly < screenH - 2 then
                display.setCursorPos(logX, ly)
                display.setBackgroundColor(colors.black)
                display.setTextColor(colors.gray)
                display.write(l.time .. " ")
                display.setTextColor(colors[l.color] or colors.white)
                display.write(string.sub(l.text, 1, logW - 10))
            end
        end
        
        -- Bottom Bar
        display.setCursorPos(1, screenH)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.lightBlue)
        display.write(string.rep(" ", screenW))
        local bottomHint = " [ WAITING FOR REMOTE COMMANDS ]   [ Q ] Exit to Menu "
        display.setCursorPos(math.max(2, math.floor((screenW - #bottomHint) / 2)), screenH)
        display.write(bottomHint)
        registerButton("BTN_EXIT", screenW - 6, screenH, 6, 1, "[ Q ]", "white", "red")
        
        drawButtons()
    end
    
    renderBase()
    
    local timerId = os.startTimer(1.0)
    
    while true do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(1.0)
            -- Periodic broadcast beacon
            rednet.broadcast({ type = "BEACON", hostID = myID, rs = rsStates }, PROTOCOL)
            renderBase()
            
        elseif event == "rednet_message" then
            local senderId, msg, proto = p1, p2, p3
            if proto == PROTOCOL and type(msg) == "table" then
                if msg.cmd == "PING" then
                    rednet.send(senderId, { type = "PONG", hostID = myID, rs = rsStates }, PROTOCOL)
                    addLog("Ping from Remote #" .. senderId, "lightBlue")
                    playChime(14)
                    
                elseif msg.cmd == "TOGGLE_RS" then
                    local s = msg.side
                    if s and rsStates[s] ~= nil then
                        rsStates[s] = not rsStates[s]
                        redstone.setOutput(s, rsStates[s])
                        addLog(string.format("Remote #%d toggled %s -> %s", senderId, s, rsStates[s] and "ON" or "OFF"), rsStates[s] and "lime" or "orange")
                        playChime(rsStates[s] and 18 or 10)
                        rednet.send(senderId, { type = "STATUS", rs = rsStates }, PROTOCOL)
                    end
                    
                elseif msg.cmd == "ALARM" then
                    addLog("Remote #" .. senderId .. " triggered ALARM!", "red")
                    if speaker then
                        for a = 1, 3 do
                            speaker.playNote("bell", 1.0, 24)
                            sleep(0.05)
                            speaker.playNote("bass", 1.0, 4)
                        end
                    end
                    
                elseif msg.cmd == "MSG" then
                    addLog(string.format("[#%d]: %s", senderId, tostring(msg.text)), "yellow")
                    playChime(20)
                end
                renderBase()
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            if cid == "BTN_EXIT" then
                break
            elseif cid and string.find(cid, "BTN_TOGGLE_") then
                local sideName = string.sub(cid, 12)
                rsStates[sideName] = not rsStates[sideName]
                redstone.setOutput(sideName, rsStates[sideName])
                addLog("Local toggle: " .. sideName .. " -> " .. (rsStates[sideName] and "ON" or "OFF"), "lime")
                playChime(16)
                renderBase()
            end
            
        elseif event == "key" then
            if p1 == keys.q or p1 == keys.escape then
                break
            end
        end
    end
end

-- ============================================================================
-- REMOTE CONTROLLER (CLIENT / POCKET PC MODE)
-- ============================================================================
local function runRemoteController()
    local targetID = nil
    local targetStates = { top = false, bottom = false, left = false, right = false, front = false, back = false }
    local discoveredHosts = {}
    local statusMsg = "Scanning for Base Stations..."
    local statusColor = "yellow"
    
    local function sendCmd(cmdData)
        if targetID then
            rednet.send(targetID, cmdData, PROTOCOL)
        else
            rednet.broadcast(cmdData, PROTOCOL)
        end
    end
    
    local function scanHosts()
        discoveredHosts = {}
        rednet.broadcast({ cmd = "PING" }, PROTOCOL)
        statusMsg = "Broadcast Ping sent..."
        statusColor = "cyan"
    end
    
    scanHosts()
    
    local function renderRemote()
        local screenW, screenH = display.getSize()
        clearButtons()
        
        display.setBackgroundColor(colors.black)
        display.clear()
        
        -- Header Bar
        display.setCursorPos(1, 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        local headStr = string.format(" [ CYBER REMOTE CONTROLLER #%d ] ", myID)
        display.setCursorPos(math.max(1, math.floor((screenW - #headStr) / 2)), 1)
        display.write(headStr)
        
        -- Discovered Base Stations List
        display.setCursorPos(2, 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" [ CONNECTED BASE STATION ] ")
        
        registerButton("BTN_SCAN", 30, 3, 10, 1, "[ SCAN ]", "yellow", "blue")
        
        if targetID then
            display.setCursorPos(2, 4)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.lime)
            display.write(string.format(" Active Target: BASE STATION #%d [CONNECTED]", targetID))
        else
            display.setCursorPos(2, 4)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.orange)
            display.write(" No base selected. Tap [ SCAN ] or select below:")
            
            local hIdx = 0
            for hid, _ in pairs(discoveredHosts) do
                hIdx = hIdx + 1
                local hy = 5 + hIdx
                if hy < screenH - 6 then
                    display.setCursorPos(4, hy)
                    display.setTextColor(colors.cyan)
                    display.write(string.format(" * Found Base Station #%d ", hid))
                    registerButton("BTN_SELECT_HOST_" .. hid, 30, hy, 12, 1, "[ CONNECT ]", "white", "blue")
                end
            end
        end
        
        -- Redstone Control Buttons
        local rsSides = { "top", "bottom", "left", "right", "front", "back" }
        display.setCursorPos(2, 8)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write(" [ REMOTE REDSTONE SWITCHES ] ")
        
        local gridX = 2
        local gridY = 10
        for i, s in ipairs(rsSides) do
            local isHigh = targetStates[s]
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local bx = gridX + col * 16
            local by = gridY + row * 2
            
            if bx + 14 < screenW and by < screenH - 3 then
                registerButton("BTN_RS_" .. s, bx, by, 14, 1, string.format(" %-5s:%s ", string.upper(s), isHigh and " ON " or " OFF"), "white", isHigh and "red" or "gray")
            end
        end
        
        -- Action Buttons: Alarm, Announce, Ping
        local actY = screenH - 4
        display.setCursorPos(2, actY)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" [ REMOTE ACTIONS ] ")
        
        registerButton("BTN_ALARM", 2, actY + 1, 12, 1, "[ ! ALARM ]", "white", "red")
        registerButton("BTN_CHIME", 16, actY + 1, 12, 1, "[ ♪ CHIME ]", "yellow", "blue")
        registerButton("BTN_PING", 30, actY + 1, 10, 1, "[ PING ]", "lime", "gray")
        
        -- Status Footer
        display.setCursorPos(1, screenH)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors[statusColor] or colors.white)
        display.write(string.rep(" ", screenW))
        display.setCursorPos(2, screenH)
        display.write(" STATUS: " .. statusMsg)
        
        registerButton("BTN_EXIT", screenW - 6, screenH, 6, 1, "[ Q ]", "white", "red")
        
        drawButtons()
    end
    
    renderRemote()
    
    local timerId = os.startTimer(0.5)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.5)
            renderRemote()
            
        elseif event == "rednet_message" then
            local senderId, msg, proto = p1, p2, p3
            if proto == PROTOCOL and type(msg) == "table" then
                if msg.type == "BEACON" or msg.type == "PONG" then
                    discoveredHosts[msg.hostID] = true
                    if not targetID then
                        targetID = msg.hostID
                        statusMsg = "Auto-connected to Base #" .. targetID
                        statusColor = "lime"
                    end
                    if msg.rs then targetStates = msg.rs end
                    playChime(18)
                    renderRemote()
                elseif msg.type == "STATUS" and msg.rs then
                    targetStates = msg.rs
                    statusMsg = "Base #" .. senderId .. " updated states"
                    statusColor = "lime"
                    renderRemote()
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_EXIT" then
                break
            elseif cid == "BTN_SCAN" then
                scanHosts()
                renderRemote()
            elseif cid and string.find(cid, "BTN_SELECT_HOST_") then
                local hid = tonumber(string.sub(cid, 17))
                if hid then
                    targetID = hid
                    statusMsg = "Connected to Base #" .. targetID
                    statusColor = "lime"
                    sendCmd({ cmd = "PING" })
                    playChime(20)
                    renderRemote()
                end
            elseif cid and string.find(cid, "BTN_RS_") then
                local sideName = string.sub(cid, 8)
                sendCmd({ cmd = "TOGGLE_RS", side = sideName })
                statusMsg = "Sent Toggle " .. sideName .. " to Base #" .. tostring(targetID or "ALL")
                statusColor = "yellow"
                playChime(15)
                renderRemote()
            elseif cid == "BTN_ALARM" then
                sendCmd({ cmd = "ALARM" })
                statusMsg = "Sent ALARM command to Base #" .. tostring(targetID or "ALL")
                statusColor = "red"
                playChime(8)
                renderRemote()
            elseif cid == "BTN_CHIME" then
                sendCmd({ cmd = "MSG", text = "Chime Note Played" })
                statusMsg = "Sent Chime signal"
                statusColor = "yellow"
                playChime(22)
                renderRemote()
            elseif cid == "BTN_PING" then
                scanHosts()
                renderRemote()
            end
            
        elseif event == "key" then
            if p1 == keys.q or p1 == keys.escape then
                break
            elseif p1 == keys.s then
                scanHosts()
                renderRemote()
            end
        end
    end
end

-- ============================================================================
-- MAIN SELECTION MENU
-- ============================================================================
local function main()
    while true do
        local screenW, screenH = display.getSize()
        clearButtons()
        
        display.setBackgroundColor(colors.black)
        display.clear()
        
        -- Header
        display.setCursorPos(1, 2)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        local title = " === CYBER WIRELESS CONTROL HUB v2.0 === "
        display.setCursorPos(math.max(1, math.floor((screenW - #title) / 2)), 2)
        display.write(title)
        
        display.setCursorPos(2, 4)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.cyan)
        display.write(" Local Computer ID: #" .. myID .. " | Wireless Modem: " .. string.upper(modemSide))
        
        display.setCursorPos(2, 6)
        display.setTextColor(colors.white)
        display.write(" Choose operation mode for this device:")
        
        -- Option 1: Base Station
        local btnY1 = 8
        registerButton("OPT_BASE", 4, btnY1, screenW - 8, 3, " [ 1 ] BASE STATION (Host / Server) - Controls Redstone & Listens ", "yellow", "gray")
        
        -- Option 2: Remote Controller
        local btnY2 = 12
        registerButton("OPT_REMOTE", 4, btnY2, screenW - 8, 3, " [ 2 ] REMOTE CONTROLLER (Pocket PC / Client) - Wireless Touchpad ", "lime", "gray")
        
        -- Exit Button
        registerButton("OPT_EXIT", math.floor(screenW / 2) - 6, screenH - 2, 12, 1, "[ QUIT (Q) ]", "white", "red")
        
        drawButtons()
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            if cid == "OPT_BASE" then
                runBaseStation()
            elseif cid == "OPT_REMOTE" then
                runRemoteController()
            elseif cid == "OPT_EXIT" then
                break
            end
        elseif event == "key" then
            if p1 == keys.one then
                runBaseStation()
            elseif p1 == keys.two then
                runRemoteController()
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Wireless Control Hub closed.")
    else
        print("Wireless Control Hub closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Wireless Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Wireless Error: " .. tostring(err))
end
