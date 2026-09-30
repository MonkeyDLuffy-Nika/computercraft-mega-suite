-- ============================================================================
-- AMONG US 2077: THE SKELD FULL-SCREEN EDITION
-- Full Monitor Scaling, Interconnected Corridors, 8 Rooms, Tasks & Vents
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
    [colors.orange]    = 0xF57C00, -- Orange Crewmate
    [colors.magenta]   = 0xD81B60, -- Pink Crewmate
    [colors.lightBlue] = 0x29B6F6, -- Cyan Visor / Glass
    [colors.yellow]    = 0xFFD600, -- Yellow Crewmate / Tasks
    [colors.lime]      = 0x00E676, -- Task Completed Green
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x263238, -- Spaceship Wall Borders
    [colors.lightGray] = 0x455A64, -- Walkable Deck Floor
    [colors.cyan]      = 0x00E5FF, -- Cyan Crewmate / Vents
    [colors.purple]    = 0x6A1B9A, -- Purple Crewmate
    [colors.blue]      = 0x0A0F1D, -- Deep Space Background
    [colors.brown]     = 0x4E342E, -- Brown Crewmate
    [colors.green]     = 0x2E7D32, -- Green Crewmate
    [colors.red]       = 0xD50000, -- Red Impostor / Kill Alert
    [colors.black]     = 0x05070A
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- SOUND FX ENGINE
-- ============================================================================
local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "step" then
            speaker.playNote("snare", 0.2, 10)
        elseif snd == "task_complete" then
            speaker.playNote("chime", 0.7, 20)
            speaker.playNote("bell", 0.7, 24)
        elseif snd == "kill" then
            speaker.playNote("bass", 1.0, 4)
            speaker.playNote("snare", 1.0, 16)
        elseif snd == "vent" then
            speaker.playNote("snare", 0.6, 6)
        elseif snd == "emergency" then
            for p = 16, 24, 2 do
                speaker.playNote("chime", 0.9, p)
                speaker.playNote("bell", 0.9, p)
                sleep(0.04)
            end
        elseif snd == "eject" then
            speaker.playNote("bass", 0.8, 8)
        end
    end)
end

-- ============================================================================
-- CREWMATE ROSTER & ROLES
-- ============================================================================
local CREWMATES = {
    [1] = { name = "Red", col = "red", isImpostor = false, isAlive = true, x = 25, y = 6, tasksDone = 0 },
    [2] = { name = "Blue", col = "blue", isImpostor = false, isAlive = true, x = 12, y = 5, tasksDone = 0 },
    [3] = { name = "Green", col = "green", isImpostor = false, isAlive = true, x = 38, y = 5, tasksDone = 0 },
    [4] = { name = "Yellow", col = "yellow", isImpostor = false, isAlive = true, x = 8, y = 14, tasksDone = 0 },
    [5] = { name = "Cyan", col = "cyan", isImpostor = false, isAlive = true, x = 44, y = 14, tasksDone = 0 },
    [6] = { name = "Purple", col = "purple", isImpostor = false, isAlive = true, x = 25, y = 15, tasksDone = 0 }
}

local playerRole = "CREWMATE" -- "CREWMATE" or "IMPOSTOR"
local playerIdx = 1

-- Game State Variables
local gameState = "TITLE" -- "TITLE", "ROAMING", "MINITASK", "MEETING", "EJECTING", "VICTORY", "DEFEAT"
local totalTasks = 8
local completedTasks = 0
local killCooldown = 0
local maxKillCooldown = 20

local currentMiniTask = nil
local miniTaskProgress = 0
local meetingVotes = {}
local meetingLog = {}
local ejectionResult = ""

-- Dynamic Map Grid
local walkableGrid = {}
local rooms = {}
local corridors = {}
local vents = {}
local taskStations = {}
local deadBodies = {}

-- Touch Buttons Storage
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

-- ============================================================================
-- DYNAMIC SPACESHIP MAP GENERATOR (CONNECTED ROOMS ACROSS FULL MONITOR)
-- ============================================================================
local function initMap()
    local screenW, screenH = display.getSize()
    walkableGrid = {}
    rooms = {}
    corridors = {}
    vents = {}
    taskStations = {}
    
    local topY = 3
    local botY = screenH - 4
    local mapH = botY - topY
    
    -- Define 7 Major Spacious Rooms Proportional to Screen
    local cafeW = math.floor(screenW * 0.32)
    local cafeH = math.max(6, math.floor(mapH * 0.38))
    local cafeX1 = math.floor((screenW - cafeW) / 2)
    local cafeY1 = topY + 1
    
    local sideW = math.floor(screenW * 0.22)
    local sideH = math.max(5, math.floor(mapH * 0.34))
    
    -- 1. Cafeteria (Top Center)
    table.insert(rooms, { name = "CAFETERIA", x1 = cafeX1, y1 = cafeY1, x2 = cafeX1 + cafeW, y2 = cafeY1 + cafeH })
    
    -- 2. MedBay (Top Left)
    table.insert(rooms, { name = "MEDBAY", x1 = 3, y1 = topY + 1, x2 = 3 + sideW, y2 = topY + 1 + sideH })
    
    -- 3. Weapons (Top Right)
    table.insert(rooms, { name = "WEAPONS", x1 = screenW - sideW - 3, y1 = topY + 1, x2 = screenW - 3, y2 = topY + 1 + sideH })
    
    -- 4. Reactor & Engines (Bottom Left)
    local botRoomY1 = botY - sideH
    table.insert(rooms, { name = "REACTOR", x1 = 3, y1 = botRoomY1, x2 = 3 + sideW, y2 = botY })
    
    -- 5. Admin & Storage (Bottom Center)
    table.insert(rooms, { name = "ADMIN", x1 = cafeX1 + 2, y1 = botRoomY1, x2 = cafeX1 + cafeW - 2, y2 = botY })
    
    -- 6. Navigation & Shields (Bottom Right)
    table.insert(rooms, { name = "SHIELDS", x1 = screenW - sideW - 3, y1 = botRoomY1, x2 = screenW - 3, y2 = botY })
    
    -- 7. Electrical (Mid Left)
    local midY1 = math.floor((topY + 1 + sideH + botRoomY1) / 2) - 2
    table.insert(rooms, { name = "ELECTRICAL", x1 = 3, y1 = midY1, x2 = 3 + sideW - 2, y2 = midY1 + 5 })
    
    -- Mark Room Floors as Walkable
    for _, r in ipairs(rooms) do
        for y = r.y1 + 1, r.y2 - 1 do
            for x = r.x1 + 1, r.x2 - 1 do
                walkableGrid[y .. "_" .. x] = true
            end
        end
    end
    
    -- Add Wide Connecting Hallways (Corridors)
    -- Corridor 1: MedBay <-> Cafeteria
    local midCafeY = math.floor((cafeY1 + cafeY1 + cafeH) / 2)
    for x = 3 + sideW, cafeX1 do
        for dy = -1, 1 do walkableGrid[(midCafeY + dy) .. "_" .. x] = true end
    end
    
    -- Corridor 2: Cafeteria <-> Weapons
    for x = cafeX1 + cafeW, screenW - sideW - 3 do
        for dy = -1, 1 do walkableGrid[(midCafeY + dy) .. "_" .. x] = true end
    end
    
    -- Corridor 3: Cafeteria <-> Admin (Main Central Spinal Corridor)
    local midCafeX = math.floor(screenW / 2)
    for y = cafeY1 + cafeH, botRoomY1 do
        for dx = -1, 1 do walkableGrid[y .. "_" .. (midCafeX + dx)] = true end
    end
    
    -- Corridor 4: Reactor <-> Electrical <-> MedBay (Left Vertical Hallway)
    local leftHallX = 3 + sideW - 1
    for y = topY + 1 + sideH, botRoomY1 do
        for dx = -1, 1 do walkableGrid[y .. "_" .. (leftHallX + dx)] = true end
    end
    
    -- Corridor 5: Admin <-> Shields & Reactor (Bottom Horizontal Hallway)
    local midBotY = math.floor((botRoomY1 + botY) / 2)
    for x = 3 + sideW, screenW - sideW - 3 do
        for dy = -1, 1 do walkableGrid[(midBotY + dy) .. "_" .. x] = true end
    end
    
    -- Corridor 6: Weapons <-> Shields (Right Vertical Hallway)
    local rightHallX = screenW - sideW - 2
    for y = topY + 1 + sideH, botRoomY1 do
        for dx = -1, 1 do walkableGrid[y .. "_" .. (rightHallX + dx)] = true end
    end
    
    -- Task Stations in each Room
    taskStations = {
        { name = "Fix Wiring", room = "CAFETERIA", x = cafeX1 + 4, y = cafeY1 + 2, type = "WIRING" },
        { name = "Submit Scan", room = "MEDBAY", x = 6, y = topY + 3, type = "SCAN" },
        { name = "Clear Asteroids", room = "WEAPONS", x = screenW - 7, y = topY + 3, type = "ASTEROIDS" },
        { name = "Calibrate Engine", room = "REACTOR", x = 6, y = botY - 2, type = "REACTOR" },
        { name = "Swipe Card", room = "ADMIN", x = midCafeX, y = botY - 2, type = "SWIPE" },
        { name = "Prime Shields", room = "SHIELDS", x = screenW - 7, y = botY - 2, type = "SHIELDS" },
        { name = "Reset Breakers", room = "ELECTRICAL", x = 6, y = midY1 + 2, type = "WIRING" }
    }
    
    -- Vents for Impostor (Interconnected Pairs)
    vents = {
        { x = 5, y = topY + 2, dest = 2 },                         -- MedBay <-> Electrical
        { x = 5, y = midY1 + 1, dest = 1 },
        { x = screenW - 5, y = topY + 2, dest = 4 },               -- Weapons <-> Shields
        { x = screenW - 5, y = botY - 1, dest = 3 },
        { x = cafeX1 + 3, y = cafeY1 + 1, dest = 6 },              -- Cafeteria <-> Admin
        { x = cafeX1 + 4, y = botY - 1, dest = 5 }
    }
end

local function isWalkable(x, y)
    return walkableGrid[y .. "_" .. x] == true
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local function initGame(role)
    playerRole = role or "CREWMATE"
    playerIdx = 1
    initMap()
    
    local screenW, screenH = display.getSize()
    local midX = math.floor(screenW / 2)
    local cafeY = math.floor((rooms[1].y1 + rooms[1].y2) / 2)
    
    -- Pick 1 Impostor
    local impIdx = (playerRole == "IMPOSTOR") and 1 or math.random(2, 6)
    for idx, c in ipairs(CREWMATES) do
        c.isAlive = true
        c.isImpostor = (idx == impIdx)
        c.x = midX + (idx - 3) * 3
        c.y = cafeY
        c.tasksDone = 0
    end
    
    deadBodies = {}
    completedTasks = 0
    totalTasks = 7
    killCooldown = 15
    currentMiniTask = nil
    
    gameState = "ROAMING"
    playSound("emergency")
end

-- ============================================================================
-- EMERGENCY MEETING & VOTING
-- ============================================================================
local function startEmergencyMeeting(caller, reason)
    gameState = "MEETING"
    meetingVotes = {}
    meetingLog = {}
    
    table.insert(meetingLog, string.format("%s called an Emergency Meeting! (%s)", caller.name, reason or "Dead Body Reported"))
    
    -- AI Discussion
    for _, c in ipairs(CREWMATES) do
        if c.isAlive and c ~= CREWMATES[playerIdx] then
            if c.isImpostor then
                local targets = {}
                for _, other in ipairs(CREWMATES) do
                    if other.isAlive and not other.isImpostor then table.insert(targets, other.name) end
                end
                local blame = targets[math.random(1, #targets)] or "Skip"
                table.insert(meetingLog, string.format("%s: 'I saw %s near Electrical acting sus!'", c.name, blame))
                meetingVotes[c.name] = blame
            else
                local sus = (math.random(1, 3) == 1) and "Red" or "Skip"
                table.insert(meetingLog, string.format("%s: 'Where was the body? Voting %s.'", c.name, sus))
                meetingVotes[c.name] = sus
            end
        end
    end
    
    playSound("emergency")
end

local function castVote(voterName, targetName)
    meetingVotes[voterName] = targetName
    
    local tally = {}
    for _, tgt in pairs(meetingVotes) do
        tally[tgt] = (tally[tgt] or 0) + 1
    end
    
    local maxV = 0
    local ejected = nil
    local tie = false
    for tgt, count in pairs(tally) do
        if count > maxV then
            maxV = count
            ejected = tgt
            tie = false
        elseif count == maxV then
            tie = true
        end
    end
    
    gameState = "EJECTING"
    if tie or ejected == "Skip" or not ejected then
        ejectionResult = "No one was ejected. (Tie / Skipped)"
    else
        for _, c in ipairs(CREWMATES) do
            if c.name == ejected then
                c.isAlive = false
                if c.isImpostor then
                    ejectionResult = string.format("%s was An Impostor! 0 Impostors remain.", c.name)
                else
                    ejectionResult = string.format("%s was not An Impostor. 1 Impostor remains.", c.name)
                end
                break
            end
        end
    end
    
    playSound("eject")
end

-- ============================================================================
-- AI CREWMATES ROAMING & TASK SIMULATION
-- ============================================================================
local function updateGame()
    if gameState == "ROAMING" then
        killCooldown = math.max(0, killCooldown - 1)
        
        -- AI Movement
        for idx, c in ipairs(CREWMATES) do
            if idx ~= playerIdx and c.isAlive then
                if c.isImpostor then
                    -- Impostor hunts nearest crewmate
                    local target = nil
                    for oIdx, other in ipairs(CREWMATES) do
                        if oIdx ~= idx and other.isAlive and not other.isImpostor then
                            target = other
                            break
                        end
                    end
                    
                    if target then
                        local dx = (target.x > c.x) and 1 or ((target.x < c.x) and -1 or 0)
                        local dy = (target.y > c.y) and 1 or ((target.y < c.y) and -1 or 0)
                        
                        if isWalkable(c.x + dx, c.y) then c.x = c.x + dx
                        elseif isWalkable(c.x, c.y + dy) then c.y = c.y + dy end
                        
                        -- AI Kill
                        if math.abs(c.x - target.x) <= 2 and math.abs(c.y - target.y) <= 1 and killCooldown <= 0 then
                            target.isAlive = false
                            table.insert(deadBodies, { x = target.x, y = target.y, name = target.name, col = target.col })
                            killCooldown = maxKillCooldown
                            playSound("kill")
                        end
                    end
                else
                    -- Innocent Crewmate roams smoothly along corridors
                    local moves = { {dx = 1, dy = 0}, {dx = -1, dy = 0}, {dx = 0, dy = 1}, {dx = 0, dy = -1} }
                    local mv = moves[math.random(1, #moves)]
                    if isWalkable(c.x + mv.dx, c.y + mv.dy) then
                        c.x = c.x + mv.dx
                        c.y = c.y + mv.dy
                    end
                    
                    -- Simulating task completion
                    if math.random(1, 60) == 1 and completedTasks < totalTasks then
                        completedTasks = math.min(totalTasks, completedTasks + 1)
                        if completedTasks >= totalTasks then
                            gameState = "VICTORY"
                            playSound("task_complete")
                            return
                        end
                    end
                end
            end
        end
        
        -- Win / Loss Conditions
        local aliveInnocents = 0
        local impostorAlive = false
        for _, c in ipairs(CREWMATES) do
            if c.isAlive then
                if c.isImpostor then impostorAlive = true else aliveInnocents = aliveInnocents + 1 end
            end
        end
        
        if not impostorAlive then
            gameState = "VICTORY"
        elseif aliveInnocents <= 1 then
            gameState = "DEFEAT"
        end
    end
end

-- ============================================================================
-- FULL-SCREEN SKELD MAP RENDERER
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.blue)
    display.clear()
    
    -- 1. Top HUD Status Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local taskPct = math.floor((completedTasks / totalTasks) * 10)
    local taskBar = string.rep("|", taskPct) .. string.rep(" ", 10 - taskPct)
    local hud = string.format(" TOTAL TASKS: [%s] %d/%d   ROLE: [%s] ", 
        taskBar, completedTasks, totalTasks, (playerRole == "IMPOSTOR") and "IMPOSTOR" or "CREWMATE")
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Render Walkable Corridors & Decks
    local botY = screenH - 4
    for y = 2, botY do
        display.setCursorPos(1, y)
        for x = 1, screenW do
            if walkableGrid[y .. "_" .. x] then
                display.setBackgroundColor(colors.lightGray)
                display.setTextColor(colors.gray)
                if (x % 5 == 0 and y % 3 == 0) then
                    display.write("+")
                else
                    display.write(" ")
                end
            else
                display.setBackgroundColor(colors.blue)
                if (x % 14 == 0 and y % 7 == 0) then
                    display.setTextColor(colors.yellow)
                    display.write("*")
                else
                    display.write(" ")
                end
            end
        end
    end
    
    -- 3. Render Room Name Banners
    for _, r in ipairs(rooms) do
        local rMidX = math.floor((r.x1 + r.x2) / 2)
        local rName = " " .. r.name .. " "
        display.setCursorPos(math.max(r.x1 + 1, rMidX - math.floor(#rName / 2)), r.y1 + 1)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write(rName)
    end
    
    -- 4. Render Task Stations
    for _, ts in ipairs(taskStations) do
        display.setCursorPos(ts.x - 1, ts.y)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.black)
        display.write("[!]")
    end
    
    -- 5. Render Vents
    for _, v in ipairs(vents) do
        display.setCursorPos(v.x - 1, v.y)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write("[V]")
    end
    
    -- 6. Render Dead Bodies
    for _, b in ipairs(deadBodies) do
        display.setCursorPos(b.x - 1, b.y)
        display.setBackgroundColor(colors.lightGray)
        display.setTextColor(colors[b.col])
        display.write("(_x_)")
    end
    
    -- 7. Render Crewmates
    for idx, c in ipairs(CREWMATES) do
        if c.isAlive then
            display.setCursorPos(c.x - 1, c.y)
            display.setBackgroundColor(colors.lightGray)
            display.setTextColor(colors[c.col])
            display.write("(o")
            display.setTextColor(colors.lightBlue)
            display.write("=")
            display.setTextColor(colors[c.col])
            display.write(")>")
            
            -- Name Tag
            display.setCursorPos(c.x - 1, c.y - 1)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors[c.col])
            display.write(c.name)
        end
    end
    
    -- 8. Interactive Action Buttons (Bottom Bar Lines screenH - 3 to screenH)
    local p = CREWMATES[playerIdx]
    local ctrlY = screenH - 2
    
    registerButton("BTN_UP", 8, ctrlY - 1, 5, 1, "[ ^ ]", "yellow", "blue")
    registerButton("BTN_LEFT", 2, ctrlY, 5, 1, "[ < ]", "yellow", "blue")
    registerButton("BTN_DOWN", 8, ctrlY, 5, 1, "[ v ]", "yellow", "blue")
    registerButton("BTN_RIGHT", 14, ctrlY, 5, 1, "[ > ]", "yellow", "blue")
    
    -- Check nearby task
    local nearbyTask = nil
    for _, ts in ipairs(taskStations) do
        if math.abs(p.x - ts.x) <= 2 and math.abs(p.y - ts.y) <= 1 then
            nearbyTask = ts
            break
        end
    end
    
    if nearbyTask and playerRole == "CREWMATE" then
        registerButton("BTN_USE", 22, ctrlY, 14, 2, " [ USE TASK (E) ] ", "lime", "purple")
    else
        registerButton("BTN_REPORT", 22, ctrlY, 14, 2, " [ REPORT (R) ] ", "yellow", "red")
    end
    
    if playerRole == "IMPOSTOR" then
        if killCooldown <= 0 then
            registerButton("BTN_KILL", 38, ctrlY, 12, 2, " [ KILL (K) ] ", "white", "red")
        else
            registerButton("BTN_KILL", 38, ctrlY, 12, 2, string.format(" [ KILL (%d) ] ", killCooldown), "lightGray", "gray")
        end
        registerButton("BTN_VENT", screenW - 14, ctrlY, 12, 2, " [ VENT (V) ] ", "cyan", "blue")
    else
        registerButton("BTN_EMERGENCY", 38, ctrlY, 16, 2, " [ EMERGENCY (M) ] ", "yellow", "blue")
    end
    
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- Mini-Task Overlay
    if gameState == "MINITASK" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 16, midY - 4)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 3)
        display.write(string.format("   TASK: %-23s  ", currentMiniTask or "WIRING"))
        display.setCursorPos(midX - 16, midY - 2)
        display.write(" ================================ ")
        
        display.setCursorPos(midX - 16, midY - 1)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.cyan)
        display.write("  [TAP PROGRESS TO COMPLETE TASK] ")
        display.setCursorPos(midX - 16, midY)
        display.write(string.format("  PROGRESS: [%s%s] ", string.rep("#", miniTaskProgress * 2), string.rep("-", 10 - miniTaskProgress * 2)))
        display.setCursorPos(midX - 16, midY + 1)
        display.write(" ================================ ")
        
        registerButton("BTN_TASK_STEP", midX - 14, midY + 3, 28, 2, " [ COMPLETE STEP (TAP) ] ", "yellow", "green")
    end
    
    -- Emergency Meeting Screen Overlay
    if gameState == "MEETING" then
        local midX = math.floor(screenW / 2)
        display.setBackgroundColor(colors.black)
        display.clear()
        
        display.setCursorPos(midX - 18, 2)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ==================================== ")
        display.setCursorPos(midX - 18, 3)
        display.write("      *** EMERGENCY MEETING ***       ")
        display.setCursorPos(midX - 18, 4)
        display.write(" ==================================== ")
        
        for lIdx, logMsg in ipairs(meetingLog) do
            display.setCursorPos(3, 5 + lIdx)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.yellow)
            display.write("• " .. logMsg)
        end
        
        local vY = screenH - 4
        display.setCursorPos(3, vY - 1)
        display.setTextColor(colors.cyan)
        display.write("CAST YOUR VOTE:")
        
        local bx = 3
        for _, c in ipairs(CREWMATES) do
            if c.isAlive then
                registerButton("VOTE_" .. c.name, bx, vY, 7, 2, "[" .. c.name .. "]", colors[c.col], "gray")
                bx = bx + 8
            end
        end
        registerButton("VOTE_Skip", screenW - 10, vY, 8, 2, "[ SKIP ]", "yellow", "blue")
    end
    
    -- Ejection Animation Overlay
    if gameState == "EJECTING" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setBackgroundColor(colors.blue)
        display.clear()
        
        display.setCursorPos(midX - 18, midY - 2)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(" .         *          .          *          . ")
        display.setCursorPos(midX - 18, midY)
        display.setTextColor(colors.white)
        display.write("   " .. ejectionResult .. "   ")
        display.setCursorPos(midX - 18, midY + 2)
        display.write(" .         *          .          *          . ")
        
        registerButton("BTN_RESUME", midX - 14, midY + 4, 28, 2, " [ CONTINUE MISSION (TAP) ] ", "yellow", "blue")
    end
    
    -- Victory / Defeat Overlays
    if gameState == "VICTORY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 16, midY - 3)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 2)
        display.write("      *** VICTORY! ***            ")
        display.setCursorPos(midX - 16, midY - 1)
        display.write("  ALL TASKS DONE / IMPOSTOR EJECT ")
        display.setCursorPos(midX - 16, midY)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 14, midY + 2, 28, 2, " [ PLAY AGAIN (TAP) ] ", "yellow", "green")
        
    elseif gameState == "DEFEAT" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 16, midY - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 2)
        display.write("       *** DEFEAT! ***            ")
        display.setCursorPos(midX - 16, midY - 1)
        display.write("   THE IMPOSTOR HAS TAKEN OVER    ")
        display.setCursorPos(midX - 16, midY)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 14, midY + 2, 28, 2, " [ TRY AGAIN (TAP) ] ", "yellow", "blue")
    end
    
    drawButtons()
end

-- ============================================================================
-- TITLE SCREEN
-- ============================================================================
local function renderTitleScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local midX = math.floor(screenW / 2)
    local titleY = math.max(2, math.floor(screenH / 2) - 6)
    
    display.setCursorPos(midX - 18, titleY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(" ==================================== ")
    display.setCursorPos(midX - 18, titleY + 1)
    display.write("       AMONG US 2077: THE SKELD       ")
    display.setCursorPos(midX - 18, titleY + 2)
    display.write(" ==================================== ")
    
    -- Crewmate Character Preview
    display.setCursorPos(midX - 3, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.write("(o")
    display.setTextColor(colors.lightBlue)
    display.write("=")
    display.setTextColor(colors.red)
    display.write(")>  ")
    display.setCursorPos(midX - 3, titleY + 5)
    display.write("/| |\ ")
    
    display.setCursorPos(midX - 18, titleY + 7)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("  CONTROLS: [W/A/S/D] Move | [E] Use  ")
    display.setCursorPos(midX - 18, titleY + 8)
    display.setTextColor(colors.yellow)
    display.write("            [R] Report     | [K] Kill ")
    
    registerButton("BTN_START_CREW", midX - 16, titleY + 10, 32, 2, " [ PLAY AS CREWMATE ] ", "yellow", "blue")
    registerButton("BTN_START_IMP", midX - 16, titleY + 13, 32, 2, " [ PLAY AS IMPOSTOR 🔪 ] ", "red", "purple")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.12)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.12)
            updateGame()
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.one or p1 == keys.space or p1 == keys.enter then
                    initGame("CREWMATE")
                elseif p1 == keys.two then
                    initGame("IMPOSTOR")
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "ROAMING" then
                local p = CREWMATES[playerIdx]
                if (p1 == keys.w or p1 == keys.up) and isWalkable(p.x, p.y - 1) then
                    p.y = p.y - 1; playSound("step")
                elseif (p1 == keys.s or p1 == keys.down) and isWalkable(p.x, p.y + 1) then
                    p.y = p.y + 1; playSound("step")
                elseif (p1 == keys.a or p1 == keys.left) and isWalkable(p.x - 1, p.y) then
                    p.x = p.x - 1; playSound("step")
                elseif (p1 == keys.d or p1 == keys.right) and isWalkable(p.x + 1, p.y) then
                    p.x = p.x + 1; playSound("step")
                elseif p1 == keys.e then
                    for _, ts in ipairs(taskStations) do
                        if math.abs(p.x - ts.x) <= 2 and math.abs(p.y - ts.y) <= 1 then
                            currentMiniTask = ts.name
                            miniTaskProgress = 0
                            gameState = "MINITASK"
                            playSound("task_complete")
                            break
                        end
                    end
                elseif p1 == keys.r then
                    startEmergencyMeeting(p, "Dead Body Reported")
                elseif p1 == keys.k and playerRole == "IMPOSTOR" and killCooldown <= 0 then
                    for idx, c in ipairs(CREWMATES) do
                        if idx ~= playerIdx and c.isAlive and math.abs(p.x - c.x) <= 2 and math.abs(p.y - c.y) <= 2 then
                            c.isAlive = false
                            table.insert(deadBodies, { x = c.x, y = c.y, name = c.name, col = c.col })
                            killCooldown = maxKillCooldown
                            playSound("kill")
                            break
                        end
                    end
                elseif p1 == keys.v and playerRole == "IMPOSTOR" then
                    for _, v in ipairs(vents) do
                        if math.abs(p.x - v.x) <= 2 and math.abs(p.y - v.y) <= 1 then
                            local destVent = vents[v.dest]
                            p.x = destVent.x
                            p.y = destVent.y
                            playSound("vent")
                            break
                        end
                    end
                elseif p1 == keys.m then
                    startEmergencyMeeting(p, "Emergency Button Pressed")
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            elseif gameState == "MINITASK" then
                if p1 == keys.space or p1 == keys.enter then
                    miniTaskProgress = miniTaskProgress + 1
                    playSound("task_complete")
                    if miniTaskProgress >= 5 then
                        completedTasks = math.min(totalTasks, completedTasks + 1)
                        gameState = "ROAMING"
                        if completedTasks >= totalTasks then gameState = "VICTORY" end
                    end
                elseif p1 == keys.q or p1 == keys.escape then
                    gameState = "ROAMING"
                end
            elseif gameState == "EJECTING" then
                if p1 == keys.space or p1 == keys.enter then
                    gameState = "ROAMING"
                end
            elseif gameState == "VICTORY" or gameState == "DEFEAT" then
                if p1 == keys.space or p1 == keys.enter or p1 == keys.r then
                    initGame(playerRole)
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            local p = CREWMATES[playerIdx]
            
            if gameState == "TITLE" then
                if cid == "BTN_START_IMP" then
                    initGame("IMPOSTOR")
                else
                    initGame("CREWMATE")
                end
            elseif gameState == "ROAMING" then
                if cid == "BTN_UP" and isWalkable(p.x, p.y - 1) then p.y = p.y - 1; playSound("step")
                elseif cid == "BTN_DOWN" and isWalkable(p.x, p.y + 1) then p.y = p.y + 1; playSound("step")
                elseif cid == "BTN_LEFT" and isWalkable(p.x - 1, p.y) then p.x = p.x - 1; playSound("step")
                elseif cid == "BTN_RIGHT" and isWalkable(p.x + 1, p.y) then p.x = p.x + 1; playSound("step")
                elseif cid == "BTN_USE" then
                    for _, ts in ipairs(taskStations) do
                        if math.abs(p.x - ts.x) <= 2 and math.abs(p.y - ts.y) <= 1 then
                            currentMiniTask = ts.name
                            miniTaskProgress = 0
                            gameState = "MINITASK"
                            playSound("task_complete")
                            break
                        end
                    end
                elseif cid == "BTN_REPORT" then
                    startEmergencyMeeting(p, "Dead Body Reported")
                elseif cid == "BTN_EMERGENCY" then
                    startEmergencyMeeting(p, "Emergency Button Pressed")
                elseif cid == "BTN_KILL" and playerRole == "IMPOSTOR" and killCooldown <= 0 then
                    for idx, c in ipairs(CREWMATES) do
                        if idx ~= playerIdx and c.isAlive and math.abs(p.x - c.x) <= 2 and math.abs(p.y - c.y) <= 2 then
                            c.isAlive = false
                            table.insert(deadBodies, { x = c.x, y = c.y, name = c.name, col = c.col })
                            killCooldown = maxKillCooldown
                            playSound("kill")
                            break
                        end
                    end
                elseif cid == "BTN_VENT" and playerRole == "IMPOSTOR" then
                    for _, v in ipairs(vents) do
                        if math.abs(p.x - v.x) <= 2 and math.abs(p.y - v.y) <= 1 then
                            local destVent = vents[v.dest]
                            p.x = destVent.x
                            p.y = destVent.y
                            playSound("vent")
                            break
                        end
                    end
                elseif cid == "BTN_QUIT" then
                    break
                end
            elseif gameState == "MINITASK" then
                if cid == "BTN_TASK_STEP" then
                    miniTaskProgress = miniTaskProgress + 1
                    playSound("task_complete")
                    if miniTaskProgress >= 5 then
                        completedTasks = math.min(totalTasks, completedTasks + 1)
                        gameState = "ROAMING"
                        if completedTasks >= totalTasks then gameState = "VICTORY" end
                    end
                end
            elseif gameState == "MEETING" then
                if cid and string.sub(cid, 1, 5) == "VOTE_" then
                    local target = string.sub(cid, 6)
                    castVote(p.name, target)
                end
            elseif gameState == "EJECTING" then
                if cid == "BTN_RESUME" then
                    gameState = "ROAMING"
                end
            elseif gameState == "VICTORY" or gameState == "DEFEAT" then
                if cid == "BTN_RETRY" then
                    initGame(playerRole)
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Among Us closed.")
    else
        print("Among Us closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Among Us Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Among Us Error: " .. tostring(err))
end
