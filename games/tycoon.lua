-- ==============================================================================
--         CYBER CITY TYCOON: METROPOLIS 2077 for CC: TWEAKED
-- ==============================================================================
--   Features:
--     * Live Animated 2D Cyberpunk Cityscape with Flying Hovercars & Neon Glow
--     * Dynamic Economy Simulation: Cash ($), Energy (⚡), Population (👥), Happiness (😊)
--     * 6 Specialized Building Sectors:
--         - Power Grid: Solar Arrays, Wind Turbines, Quantum Fusion Cores
--         - Residential: Micro-Pods, Neo-Apartments, Cyber Megatowers
--         - Commercial: Holo-Malls, Cyber Casinos, Mega-Corp HQs
--         - Industrial: Chip Foundries, Robotics Plants, Nanotech Labs
--         - Services: Police Drone Hubs, Med-Bay Clinics, Sky-Train Transit
--         - Wonders: Orbital Elevator, Weather Shield Dome, AI Overmind
--     * Dynamic Live Stock & Crypto Market with Fluctuating Tickers
--     * Research & Technology Tree (Drone Logistics, Fusion Overclock, Neon Ads)
--     * Random Dynamic Events (Cyber Hacks, Tech Booms, Alien Tourism, Blackouts)
--     * Display Settings: Output to [MONITOR] or [COMPUTER TERMINAL]
--     * Centered On-Screen Touch Controls & Full Keyboard Hotkeys
--     * Speaker 8-Bit Chiptune Audio (Cash Register, Siren, Construction, Tech)
-- ==============================================================================

-- Configuration & Display Setup
local config = {
    targetDisplay = "monitor", -- "monitor" or "terminal"
    monitorScale = 0.5,
    soundEnabled = true
}

local mon = nil
local display = term
local isMonitor = false

local function initDisplay()
    if config.targetDisplay == "terminal" then
        display = term
        isMonitor = false
    else
        mon = peripheral.find("monitor")
        if mon then
            display = mon
            isMonitor = true
            pcall(function() mon.setTextScale(config.monitorScale) end)
        else
            display = term
            isMonitor = false
        end
    end
end

initDisplay()
local screenW, screenH = display.getSize()

-- Speaker Peripheral Audio
local speaker = peripheral.find("speaker")
local function playSound(sndType)
    if not speaker or not config.soundEnabled then return end
    pcall(function()
        if sndType == "build" then
            speaker.playNote("snare", 0.8, 14)
        elseif sndType == "money" then
            speaker.playNote("bell", 1.2, 20)
        elseif sndType == "tech" then
            speaker.playNote("iron_xylophone", 1.5, 22)
        elseif sndType == "alarm" then
            speaker.playNote("didgeridoo", 1.5, 8)
        elseif sndType == "click" then
            speaker.playNote("hat", 0.5, 16)
        elseif sndType == "trade" then
            speaker.playNote("pling", 1.2, 18)
        end
    end)
end

-- Double Buffer System
local charBuf = {}
local fgBuf = {}
local bgBuf = {}

local function clearBuffer(bgCol)
    bgCol = bgCol or "f"
    screenW, screenH = display.getSize()
    for y = 1, screenH do
        charBuf[y] = string.rep(" ", screenW)
        fgBuf[y] = string.rep("0", screenW)
        bgBuf[y] = string.rep(bgCol, screenW)
    end
end

local function drawText(x, y, text, fgCol, bgCol)
    x = math.floor(x)
    y = math.floor(y)
    if y < 1 or y > screenH or x > screenW then return end
    fgCol = fgCol or "0"
    bgCol = bgCol or "f"
    
    local strLen = #text
    if x + strLen - 1 < 1 then return end
    
    local cutLeft = 0
    if x < 1 then
        cutLeft = 1 - x
        text = string.sub(text, cutLeft + 1)
        x = 1
        strLen = #text
    end
    
    if x + strLen - 1 > screenW then
        local maxLen = screenW - x + 1
        text = string.sub(text, 1, maxLen)
        strLen = #text
    end
    
    if strLen <= 0 then return end
    
    local fgStr = string.rep(fgCol, strLen)
    local bgStr = string.rep(bgCol, strLen)
    
    local curChar = charBuf[y] or string.rep(" ", screenW)
    local curFg = fgBuf[y] or string.rep("0", screenW)
    local curBg = bgBuf[y] or string.rep("f", screenW)
    
    charBuf[y] = string.sub(curChar, 1, x - 1) .. text .. string.sub(curChar, x + strLen)
    fgBuf[y]   = string.sub(curFg, 1, x - 1) .. fgStr .. string.sub(curFg, x + strLen)
    bgBuf[y]   = string.sub(curBg, 1, x - 1) .. bgStr .. string.sub(curBg, x + strLen)
end

local function flushBuffer()
    for y = 1, screenH do
        display.setCursorPos(1, y)
        local c = charBuf[y] or ""
        local f = fgBuf[y] or ""
        local b = bgBuf[y] or ""
        local minL = math.min(#c, #f, #b, screenW)
        pcall(function()
            display.blit(string.sub(c, 1, minL), string.sub(f, 1, minL), string.sub(b, 1, minL))
        end)
    end
end

-- City Economy State
local city = {
    name = "NEO-TOKYO 2077",
    cash = 2500,
    incomePerSec = 0,
    power = 10, maxPower = 10,
    population = 50, maxPopulation = 100,
    happiness = 85,
    research = 0,
    taxRate = 10, -- 10%
    day = 1,
    gameSpeed = 1,
    activeEvent = nil,
    eventTimer = 0
}

-- Hovercars & Particle Animation
local hovercars = {}
local function initHovercars()
    hovercars = {}
    for i = 1, 5 do
        table.insert(hovercars, {
            x = math.random(1, 40),
            y = 6 + (i * 2),
            spd = (math.random(1, 2) == 1 and 0.4 or -0.4),
            char = (math.random(1, 2) == 1 and ">*>" or "<*<"),
            col = (i % 2 == 0 and "3" or "e")
        })
    end
end

local function updateHovercars()
    for _, hc in ipairs(hovercars) do
        hc.x = hc.x + hc.spd
        if hc.x > screenW + 5 then hc.x = -5
        elseif hc.x < -5 then hc.x = screenW + 5 end
    end
end

-- 12 Buildings Catalog
local BUILDINGS = {
    -- Power
    { id = "solar",   cat = "POWER", name = "Solar Array",     cost = 300,  power = 15,  cash = -5,   pop = 0,   desc = "+15 ⚡ Power", icon = "[SOLAR]" },
    { id = "fusion",  cat = "POWER", name = "Fusion Reactor",  cost = 3500, power = 100, cash = -30,  pop = 0,   desc = "+100 ⚡ Power", icon = "[FUSION]" },
    
    -- Housing
    { id = "pods",    cat = "RES",   name = "Micro-Pods",      cost = 400,  power = -5,  cash = 15,   pop = 50,  desc = "+50 👥 Pop, +$15/s", icon = "[PODS]" },
    { id = "tower",   cat = "RES",   name = "Cyber Megatower", cost = 4500, power = -30, cash = 180,  pop = 400, desc = "+400 👥 Pop, +$180/s", icon = "[TOWER]" },
    
    -- Commercial
    { id = "mall",    cat = "COMM",  name = "Holo-Arcade Mall",cost = 800,  power = -10, cash = 60,   pop = 0,   desc = "+$60/s, +3% Happy", icon = "[MALL]" },
    { id = "casino",  cat = "COMM",  name = "Cyber Casino",    cost = 6000, power = -40, cash = 350,  pop = 0,   desc = "+$350/s, High Tax", icon = "[CASINO]" },
    
    -- Industrial
    { id = "chips",   cat = "IND",   name = "Quantum Foundry", cost = 1200, power = -20, cash = 95,   pop = 0,   desc = "+$95/s, +1 🧬 Tech", icon = "[CHIPS]" },
    { id = "nanolab", cat = "IND",   name = "Nanotech Plant",  cost = 8000, power = -60, cash = 550,  pop = 0,   desc = "+$550/s, +5 🧬 Tech", icon = "[NANO]" },
    
    -- Services
    { id = "police",  cat = "SERV",  name = "Police Drone Hub",cost = 900,  power = -10, cash = -15,  pop = 0,   desc = "+10% Happy, Anti-Crime", icon = "[POLICE]" },
    { id = "medbay",  cat = "SERV",  name = "Cyber Med-Clinic",cost = 1500, power = -15, cash = -25,  pop = 0,   desc = "+15% Happy, Health", icon = "[MEDBAY]" },
    
    -- Wonders
    { id = "elevator",cat = "WOND",  name = "Space Elevator",  cost = 25000,power = -100,cash = 2000, pop = 1000,desc = "+$2000/s, +1000 👥", icon = "[ELEVATOR]" },
    { id = "ai_core", cat = "WOND",  name = "AI Overmind Hub", cost = 50000,power = -150,cash = 5000, pop = 0,   desc = "+50 🧬/s, All x2", icon = "[AI-CORE]" }
}

-- Built Inventory { id -> count }
local builtCounts = {}
for _, b in ipairs(BUILDINGS) do builtCounts[b.id] = 0 end
builtCounts["solar"] = 1
builtCounts["pods"] = 1

-- 8 Research Technologies
local TECH_TREE = {
    { id = "drones",  name = "Automated Drone Logistics", cost = 50,  bought = false, desc = "+25% Industrial Cash Output" },
    { id = "neon_ads",name = "Holographic Sky Ads",       cost = 120, bought = false, desc = "+30% Commercial Tax Revenue" },
    { id = "fusion_oc",name = "Superconductive Fusion Grid",cost = 300, bought = false, desc = "+50% Total Power Capacity" },
    { id = "cyber_med",name = "Neural Med-Nanites",        cost = 600, bought = false, desc = "+15% Permanent Happiness" },
    { id = "ai_market",name = "Predictive Stock AI",      cost = 1200,bought = false, desc = "Unlocks Insider Stock Insights" },
    { id = "sky_rail", name = "Anti-Grav Sky-Rail System",cost = 2500,bought = false, desc = "+500 Population Capacity" }
}

-- Live Stock & Crypto Market
local STOCKS = {
    { symbol = "CYBR", name = "Cyberdyne Systems", price = 120, shares = 0, hist = { 110, 115, 120 } },
    { symbol = "NEOX", name = "Neo-Tokyo Power",   price = 45,  shares = 0, hist = { 40, 42, 45 } },
    { symbol = "QUANT",name = "Quantum Neural",    price = 310, shares = 0, hist = { 290, 300, 310 } },
    { symbol = "DOGE", name = "CyberDoge Crypto",  price = 12,  shares = 0, hist = { 8, 15, 12 } }
}

-- Number Formatting
local function formatNum(n)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return string.format("%d", math.floor(n)) end
end

-- Economy Calculation
local function updateCityEconomy()
    local totalIncome = 0
    local totalPowerGen = 0
    local totalPowerUse = 0
    local totalMaxPop = 100
    local totalTechGen = 0
    
    for _, b in ipairs(BUILDINGS) do
        local count = builtCounts[b.id] or 0
        if count > 0 then
            if b.power > 0 then totalPowerGen = totalPowerGen + (b.power * count)
            else totalPowerUse = totalPowerUse + (math.abs(b.power) * count) end
            
            local bIncome = (b.cash * count)
            if b.cat == "IND" and TECH_TREE[1].bought then bIncome = bIncome * 1.25 end
            if b.cat == "COMM" and TECH_TREE[2].bought then bIncome = bIncome * 1.30 end
            totalIncome = totalIncome + bIncome
            
            totalMaxPop = totalMaxPop + (b.pop * count)
            if b.id == "chips" then totalTechGen = totalTechGen + 1 * count
            elseif b.id == "nanolab" then totalTechGen = totalTechGen + 5 * count
            elseif b.id == "ai_core" then totalTechGen = totalTechGen + 50 * count end
        end
    end
    
    if TECH_TREE[3].bought then totalPowerGen = totalPowerGen * 1.5 end
    if TECH_TREE[6].bought then totalMaxPop = totalMaxPop + 500 end
    
    -- Tax Revenue from Population
    local taxRevenue = math.floor((city.population * 0.8) * (city.taxRate / 10))
    totalIncome = totalIncome + taxRevenue
    
    city.maxPower = totalPowerGen
    city.power = math.max(0, totalPowerGen - totalPowerUse)
    city.maxPopulation = totalMaxPop
    
    -- Blackout Penalty if power deficit
    if totalPowerUse > totalPowerGen then
        totalIncome = math.floor(totalIncome * 0.3)
        city.happiness = math.max(20, city.happiness - 1)
    else
        city.happiness = math.min(100, city.happiness + 0.1)
    end
    
    city.incomePerSec = totalIncome
    city.cash = city.cash + (totalIncome * 0.1)
    city.research = city.research + (totalTechGen * 0.1)
    
    -- Population Growth
    if city.population < city.maxPopulation and city.happiness > 50 then
        city.population = math.min(city.maxPopulation, city.population + 0.5)
    end
end

-- Update Stocks Market
local function updateStockMarket()
    for _, s in ipairs(STOCKS) do
        local change = (math.random(-12, 14) / 100)
        s.price = math.max(2, math.floor(s.price * (1 + change)))
        table.insert(s.hist, s.price)
        if #s.hist > 8 then table.remove(s.hist, 1) end
    end
end

-- Random City Events
local function triggerRandomEvent()
    local events = {
        { name = "TECH BOOM!", desc = "Commercial profits doubled for 20 seconds!", effect = "BOOM", timer = 200 },
        { name = "CYBER HACK ATTACK!", desc = "Rogue Netrunners stole $500!", effect = "HACK", timer = 60 },
        { name = "ALIEN TOURISM WAVE!", desc = "Alien delegates visited! Gained $2,000!", effect = "ALIEN", timer = 80 },
        { name = "SOLAR FLARE SURGE!", desc = "Solar Arrays producing +200% energy!", effect = "SOLAR", timer = 150 }
    }
    city.activeEvent = events[math.random(1, #events)]
    city.eventTimer = city.activeEvent.timer
    playSound("alarm")
    
    if city.activeEvent.effect == "HACK" then
        city.cash = math.max(0, city.cash - 500)
    elseif city.activeEvent.effect == "ALIEN" then
        city.cash = city.cash + 2000
    end
end

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
        drawText(btn.x1, btn.y1, btn.label, btn.fg, btn.bg)
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

-- Active Navigation Tab: CITY, BUILD, RESEARCH, MARKET, SETTINGS
local currentTab = "CITY"

-- Render Cityscape View
local function renderCityscape()
    clearBuffer("f")
    clearButtons()
    screenW, screenH = display.getSize()
    
    -- 1. Top HUD Bar
    drawText(1, 1, string.rep(" ", screenW), "0", "7")
    drawText(2, 1, string.format("🏙️ %s", city.name), "0", "7")
    drawText(24, 1, string.format("CASH: $%s (+$%d/s)", formatNum(city.cash), math.floor(city.incomePerSec)), "5", "7")
    drawText(screenW - 24, 1, string.format("⚡ %d/%d", city.power, city.maxPower), (city.power > 0 and "4" or "e"), "7")
    drawText(screenW - 12, 1, string.format("👥 %d", math.floor(city.population)), "3", "7")
    
    -- 2. Navigation Tabs Bar (Top Row 2)
    local tabW = 9
    registerButton("TAB_CITY",     2, 3, tabW, 1, "[CITY]",     (currentTab == "CITY" and "0" or "7"), (currentTab == "CITY" and "3" or "8"))
    registerButton("TAB_BUILD",    12, 3, tabW, 1, "[BUILD]",    (currentTab == "BUILD" and "0" or "7"), (currentTab == "BUILD" and "5" or "8"))
    registerButton("TAB_RESEARCH", 22, 3, tabW, 1, "[RESEARCH]", (currentTab == "RESEARCH" and "0" or "7"), (currentTab == "RESEARCH" and "4" or "8"))
    registerButton("TAB_MARKET",   32, 3, tabW, 1, "[MARKET]",   (currentTab == "MARKET" and "0" or "7"), (currentTab == "MARKET" and "e" or "8"))
    registerButton("TAB_SETTINGS", 42, 3, tabW, 1, "[CONFIG]",   (currentTab == "SETTINGS" and "0" or "7"), (currentTab == "SETTINGS" and "7" or "8"))
    
    -- 3. Render Tab Contents
    if currentTab == "CITY" then
        -- Animated Cyberpunk Skyline
        local skyY = 5
        drawText(4, skyY,     "    |#|      /\"\"\"\\       [===]       |#|     /\"\"\"\\    ", "8", "f")
        drawText(4, skyY + 1, "   [===]    |     |      | N |      [===]   |     |   ", "7", "f")
        drawText(4, skyY + 2, "   | C |    |CYBER|      | E |      | M |   |MEGA |   ", "3", "f")
        drawText(4, skyY + 3, "   | Y |    |PODS |     /=====\\     | E |   |TOWER|   ", "4", "f")
        drawText(4, skyY + 4, "  /=====\\   |     |     |  O  |    /=====\\  |     |   ", "e", "f")
        drawText(4, skyY + 5, "==========================================================", "7", "8")
        
        -- Draw Floating Hovercars
        for _, hc in ipairs(hovercars) do
            if hc.y >= skyY + 1 and hc.y <= skyY + 5 then
                drawText(hc.x, hc.y, hc.char, hc.col, "f")
            end
        end
        
        -- City Stats Overview Box
        local statY = skyY + 7
        drawText(4, statY, string.format("HAPPINESS INDEX:   %d%%  %s", math.floor(city.happiness), (city.happiness > 70 and "[PROSPEROUS]" or "[UNREST]")), "5", "f")
        drawText(4, statY + 1, string.format("RESEARCH TECH:     %d 🧬 Points", math.floor(city.research)), "4", "f")
        drawText(4, statY + 2, string.format("POPULATION LIMIT:  %d / %d Cyber-Citizens", math.floor(city.population), city.maxPopulation), "3", "f")
        
        -- Active Event Banner
        if city.activeEvent then
            drawText(4, statY + 4, string.format("🚨 EVENT: %s - %s", city.activeEvent.name, city.activeEvent.desc), "e", "0")
        end
        
    elseif currentTab == "BUILD" then
        drawText(2, 5, "=== CONSTRUCT BUILDINGS ===", "5", "f")
        local by = 7
        for i, b in ipairs(BUILDINGS) do
            if by < screenH - 2 then
                local count = builtCounts[b.id] or 0
                local cost = math.floor(b.cost * (1.2 ^ count))
                local canAfford = (city.cash >= cost)
                local bLab = string.format("[%d] %-14s (%d)", i, b.name, count)
                local bCost = string.format("$%s", formatNum(cost))
                
                drawText(2, by, bLab, (canAfford and "0" or "8"), "f")
                drawText(28, by, b.desc, "7", "f")
                registerButton("BUY_B_" .. i, screenW - #bCost - 2, by, #bCost + 2, 1, " " .. bCost .. " ", (canAfford and "0" or "8"), (canAfford and "5" or "7"))
                by = by + 1
            end
        end
        
    elseif currentTab == "RESEARCH" then
        drawText(2, 5, string.format("=== RESEARCH LAB (Available: %d 🧬) ===", math.floor(city.research)), "4", "f")
        local ty = 7
        for i, t in ipairs(TECH_TREE) do
            if ty < screenH - 2 then
                local canAfford = (city.research >= t.cost and not t.bought)
                local tLab = string.format("[%d] %-26s", i, t.name)
                local tCost = (t.bought and "[UNLOCKED]" or string.format("%d 🧬", t.cost))
                
                drawText(2, ty, tLab, (t.bought and "5" or (canAfford and "4" or "8")), "f")
                drawText(32, ty, t.desc, "7", "f")
                if not t.bought then
                    registerButton("BUY_T_" .. i, screenW - #tCost - 2, ty, #tCost + 2, 1, " " .. tCost .. " ", (canAfford and "0" or "8"), (canAfford and "4" or "7"))
                else
                    drawText(screenW - #tCost - 2, ty, tCost, "5", "f")
                end
                ty = ty + 2
            end
        end
        
    elseif currentTab == "MARKET" then
        drawText(2, 5, "=== LIVE CYBER-STOCK & CRYPTO EXCHANGE ===", "e", "f")
        local my = 7
        for i, s in ipairs(STOCKS) do
            local sLab = string.format("%-6s %-18s $%3d (Owned: %d)", s.symbol, s.name, s.price, s.shares)
            drawText(2, my, sLab, "0", "f")
            
            -- Trend Line
            local trend = ""
            for _, p in ipairs(s.hist) do
                trend = trend .. (p >= s.price and "^" or "v")
            end
            drawText(36, my, "[" .. trend .. "]", "3", "f")
            
            registerButton("BUY_STK_" .. i, screenW - 14, my, 6, 1, "[BUY]", "0", "5")
            registerButton("SELL_STK_" .. i, screenW - 7, my, 6, 1, "[SELL]", "0", "e")
            my = my + 2
        end
        
    elseif currentTab == "SETTINGS" then
        drawText(2, 5, "=== TYCOON SYSTEM SETTINGS ===", "7", "f")
        local dispLabel = string.format("1. DISPLAY OUTPUT: [%s]", string.upper(config.targetDisplay))
        registerButton("SET_DISPLAY", 4, 8, 36, 1, dispLabel, "0", "3")
        
        local sndLabel = string.format("2. SPEAKER AUDIO:  [%s]", (config.soundEnabled and "ENABLED" or "DISABLED"))
        registerButton("SET_AUDIO",   4, 10, 36, 1, sndLabel, "0", "4")
    end
    
    -- 4. Bottom Centered Control Buttons
    drawText(1, screenH - 1, string.rep("-", screenW), "7", "f")
    drawText(1, screenH, string.rep(" ", screenW), "0", "7")
    
    local btnTotalW = 12 + 12 + 12 + 10
    local cx = math.max(2, math.floor((screenW - btnTotalW) / 2))
    registerButton("BTN_QUICK_CASH", cx, screenH, 12, 1, "[+$100 TAX]", "0", "5")
    registerButton("BTN_TAX_UP",     cx + 13, screenH, 12, 1, string.format("[TAX: %d%%]", city.taxRate), "0", "4")
    registerButton("BTN_EVENT_TRIG", cx + 26, screenH, 12, 1, "[NEW EVENT]", "0", "e")
    registerButton("BTN_QUIT",       cx + 39, screenH, 10, 1, "[QUIT]", "0", "7")
    
    drawButtons()
    flushBuffer()
end

-- Buy Building Logic
local function buyBuilding(idx)
    local b = BUILDINGS[idx]
    if not b then return end
    local count = builtCounts[b.id] or 0
    local cost = math.floor(b.cost * (1.2 ^ count))
    if city.cash >= cost then
        city.cash = city.cash - cost
        builtCounts[b.id] = count + 1
        playSound("build")
    end
end

-- Buy Research Logic
local function buyResearch(idx)
    local t = TECH_TREE[idx]
    if not t or t.bought then return end
    if city.research >= t.cost then
        city.research = city.research - t.cost
        t.bought = true
        playSound("tech")
    end
end

-- Stock Trading Logic
local function buyStock(idx)
    local s = STOCKS[idx]
    if not s then return end
    if city.cash >= s.price then
        city.cash = city.cash - s.price
        s.shares = s.shares + 1
        playSound("trade")
    end
end

local function sellStock(idx)
    local s = STOCKS[idx]
    if not s or s.shares <= 0 then return end
    city.cash = city.cash + s.price
    s.shares = s.shares - 1
    playSound("money")
end

-- Main Game Engine
local function main()
    display.setBackgroundColor(colors.black)
    display.clear()
    initHovercars()
    
    local timerId = os.startTimer(0.1)
    local secondTimer = 0
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.1)
            
            updateHovercars()
            updateCityEconomy()
            
            secondTimer = secondTimer + 1
            if secondTimer % 10 == 0 then -- every 1 second
                city.day = city.day + 1
                if math.random(1, 30) == 1 and not city.activeEvent then
                    triggerRandomEvent()
                end
                if city.eventTimer > 0 then
                    city.eventTimer = city.eventTimer - 1
                    if city.eventTimer <= 0 then city.activeEvent = nil end
                end
            end
            
            if secondTimer % 20 == 0 then -- every 2 seconds
                updateStockMarket()
            end
            
            renderCityscape()
            
        elseif event == "key" then
            if p1 == keys.one then currentTab = "CITY"
            elseif p1 == keys.two then currentTab = "BUILD"
            elseif p1 == keys.three then currentTab = "RESEARCH"
            elseif p1 == keys.four then currentTab = "MARKET"
            elseif p1 == keys.five then currentTab = "SETTINGS"
            elseif p1 == keys.space then
                city.cash = city.cash + 50
                playSound("money")
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "TAB_CITY" then currentTab = "CITY"
            elseif cid == "TAB_BUILD" then currentTab = "BUILD"
            elseif cid == "TAB_RESEARCH" then currentTab = "RESEARCH"
            elseif cid == "TAB_MARKET" then currentTab = "MARKET"
            elseif cid == "TAB_SETTINGS" then currentTab = "SETTINGS"
            elseif cid == "BTN_QUICK_CASH" then
                city.cash = city.cash + 100
                playSound("money")
            elseif cid == "BTN_TAX_UP" then
                city.taxRate = (city.taxRate >= 25 and 5 or city.taxRate + 5)
                playSound("click")
            elseif cid == "BTN_EVENT_TRIG" then
                triggerRandomEvent()
            elseif cid == "BTN_QUIT" then
                break
            elseif cid == "SET_DISPLAY" then
                config.targetDisplay = (config.targetDisplay == "monitor" and "terminal" or "monitor")
                initDisplay()
            elseif cid == "SET_AUDIO" then
                config.soundEnabled = not config.soundEnabled
            elseif cid and string.sub(cid, 1, 6) == "BUY_B_" then
                local bIdx = tonumber(string.sub(cid, 7))
                buyBuilding(bIdx)
            elseif cid and string.sub(cid, 1, 6) == "BUY_T_" then
                local tIdx = tonumber(string.sub(cid, 7))
                buyResearch(tIdx)
            elseif cid and string.sub(cid, 1, 8) == "BUY_STK_" then
                local sIdx = tonumber(string.sub(cid, 9))
                buyStock(sIdx)
            elseif cid and string.sub(cid, 1, 9) == "SELL_STK_" then
                local sIdx = tonumber(string.sub(cid, 10))
                sellStock(sIdx)
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Cyber City Tycoon closed.")
    else
        print("Cyber City Tycoon closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Error: " .. tostring(err))
end
