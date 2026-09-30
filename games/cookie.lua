-- ==============================================================================
--           CYBER COOKIE CLICKER: DELUXE EDITION for CC: TWEAKED
-- ==============================================================================
--   Features:
--     * Giant Interactive Cookie with Click Bounce & Crumb Physics
--     * 10 Tiers of Production Buildings (Grandmas, Farms, Mines, Factories, etc.)
--     * 15 Permanent Science Lab Upgrades (Double CPS, Golden Chips, Auto-Ovens)
--     * Shimmering Golden Cookies with Random Events (Frenzy, Lucky, Click Frenzy)
--     * Floating Animated Click Numbers (+1, +777) & Particle Bursts
--     * Prestige & Ascension System (Heavenly Chips permanent multiplier)
--     * Speaker Chiptune Sound Effects (Crunch, Coin Ding, Fanfare, Golden Sparkle)
--     * Full Touchscreen & Keyboard Controls (Space/Enter/Numbers)
-- ==============================================================================

-- Display & Hardware Setup
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

local screenW, screenH = display.getSize()

-- Speaker Peripheral Audio
local speaker = peripheral.find("speaker")
local function playSound(sndType)
    if not speaker then return end
    pcall(function()
        if sndType == "click" then
            speaker.playNote("snare", 0.6, 18)
        elseif sndType == "crunch" then
            speaker.playNote("hat", 1.0, 12)
        elseif sndType == "buy" then
            speaker.playNote("bell", 1.2, 16)
        elseif sndType == "upgrade" then
            speaker.playNote("iron_xylophone", 1.5, 20)
        elseif sndType == "golden" then
            speaker.playNote("chime", 1.5, 24)
        elseif sndType == "frenzy" then
            speaker.playNote("flute", 1.5, 22)
        elseif sndType == "prestige" then
            speaker.playNote("harp", 1.2, 24)
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

-- Particle & Floating Text System
local particles = {}
local floatTexts = {}

local function addCrumbs(x, y, count)
    count = count or 6
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = math.random() * 1.5 + 0.5
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd * 0.6,
            life = math.random(5, 10),
            char = (math.random(1, 2) == 1 and "." or "*"),
            col = (math.random(1, 2) == 1 and "1" or "c")
        })
    end
end

local function addFloatText(x, y, text, col)
    table.insert(floatTexts, {
        x = x + math.random(-2, 2),
        y = y,
        text = text,
        col = col or "4",
        life = 12
    })
end

local function updateParticles()
    local nextP = {}
    for _, p in ipairs(particles) do
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.life = p.life - 1
        if p.life > 0 then table.insert(nextP, p) end
    end
    particles = nextP
    
    local nextT = {}
    for _, ft in ipairs(floatTexts) do
        ft.y = ft.y - 0.25
        ft.life = ft.life - 1
        if ft.life > 0 then table.insert(nextT, ft) end
    end
    floatTexts = nextT
end

local function drawParticles()
    for _, p in ipairs(particles) do
        drawText(math.floor(p.x), math.floor(p.y), p.char, p.col, "f")
    end
    for _, ft in ipairs(floatTexts) do
        drawText(math.floor(ft.x), math.floor(ft.y), ft.text, ft.col, "f")
    end
end

-- Game State
local state = {
    cookies = 0,
    totalBaked = 0,
    clickPower = 1,
    heavenlyChips = 0,
    frenzyTimer = 0,
    clickFrenzyTimer = 0,
    cookieScale = 0, -- bounce animation
    goldenCookie = nil
}

-- 10 Tiers of Production Buildings
local BUILDINGS = {
    { id = "cursor",   name = "Auto-Cursor",       baseCost = 15,        cps = 0.5,     count = 0, icon = ">" },
    { id = "grandma",  name = "Bakery Grandma",    baseCost = 100,       cps = 4.0,     count = 0, icon = "@" },
    { id = "farm",     name = "Cookie Farm",       baseCost = 600,       cps = 16.0,    count = 0, icon = "#" },
    { id = "mine",     name = "Chocolate Mine",    baseCost = 3500,      cps = 64.0,    count = 0, icon = "%" },
    { id = "factory",  name = "Industrial Factory",baseCost = 20000,     cps = 260.0,   count = 0, icon = "&" },
    { id = "bank",     name = "Cookie Bank Vault", baseCost = 120000,    cps = 1100.0,  count = 0, icon = "$" },
    { id = "temple",   name = "Dough Temple",      baseCost = 800000,    cps = 4800.0,  count = 0, icon = "^" },
    { id = "wizard",   name = "Wizard Tower",      baseCost = 5000000,   cps = 22000.0, count = 0, icon = "*" },
    { id = "condenser",name = "Antimatter Bakery", baseCost = 32000000,  cps = 95000.0, count = 0, icon = "O" },
    { id = "prism",    name = "Prism Converter",   baseCost = 250000000, cps = 450000.0,count = 0, icon = "X" }
}

-- 12 Science Lab Upgrades
local UPGRADES = {
    { id = "plastic_mouse", name = "Reinforced Mouse",  cost = 100,     bought = false, desc = "Click Power x2", apply = function() state.clickPower = state.clickPower * 2 end },
    { id = "iron_mouse",    name = "Titanium Cursors",  cost = 800,     bought = false, desc = "Click Power x2", apply = function() state.clickPower = state.clickPower * 2 end },
    { id = "grandma_rollers",name = "Rolling Pins",     cost = 1200,    bought = false, desc = "Grandmas 2x CPS", apply = function() BUILDINGS[2].cps = BUILDINGS[2].cps * 2 end },
    { id = "fertilizer",    name = "Rich Cocoa Soil",   cost = 5000,    bought = false, desc = "Farms 2x CPS",    apply = function() BUILDINGS[3].cps = BUILDINGS[3].cps * 2 end },
    { id = "sugar_rush",    name = "Pure Sugar Rush",   cost = 25000,   bought = false, desc = "+25% Total CPS",  apply = function() state.cpsBonus = (state.cpsBonus or 1.0) * 1.25 end },
    { id = "gold_chips",    name = "Golden Choco Chips",cost = 100000,  bought = false, desc = "Click Power +10", apply = function() state.clickPower = state.clickPower + 10 end },
    { id = "auto_ovens",    name = "Supercharged Ovens",cost = 500000,  bought = false, desc = "Factories 2x CPS",apply = function() BUILDINGS[5].cps = BUILDINGS[5].cps * 2 end },
    { id = "compound_int",  name = "Compound Interest", cost = 2000000, bought = false, desc = "Banks 2x CPS",     apply = function() BUILDINGS[6].cps = BUILDINGS[6].cps * 2 end },
    { id = "divine_dough",  name = "Divine Blessing",   cost = 10000000,bought = false, desc = "+50% Total CPS",  apply = function() state.cpsBonus = (state.cpsBonus or 1.0) * 1.5 end },
    { id = "chrono_bakery", name = "Time Warp Ovens",   cost = 50000000,bought = false, desc = "All CPS x2",      apply = function() state.cpsBonus = (state.cpsBonus or 1.0) * 2.0 end }
}

-- Calculate Current Total CPS
local function getTotalCPS()
    local raw = 0
    for _, b in ipairs(BUILDINGS) do
        raw = raw + (b.count * b.cps)
    end
    raw = raw * (state.cpsBonus or 1.0)
    raw = raw * (1.0 + (state.heavenlyChips * 0.02)) -- +2% per Heavenly Chip
    if state.frenzyTimer > 0 then
        raw = raw * 7
    end
    return raw
end

-- Building Cost Formula: baseCost * 1.15^count
local function getBuildingCost(b)
    return math.floor(b.baseCost * (1.15 ^ b.count))
end

-- Number Formatter (1.2K, 3.4M, 5.6B, etc.)
local function formatNum(n)
    if n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return string.format("%d", math.floor(n)) end
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

-- Click Giant Cookie Handler
local cookieCenterX = 15
local cookieCenterY = 10

local function clickGiantCookie()
    state.cookieScale = 3 -- bounce
    local mult = (state.clickFrenzyTimer > 0 and 777 or 1)
    local gained = state.clickPower * mult
    state.cookies = state.cookies + gained
    state.totalBaked = state.totalBaked + gained
    
    addCrumbs(cookieCenterX, cookieCenterY, 8)
    addFloatText(cookieCenterX, cookieCenterY - 4, "+" .. formatNum(gained), (mult > 1 and "e" or "4"))
    playSound(mult > 1 and "frenzy" or "crunch")
end

-- Buy Building Handler
local function buyBuilding(idx)
    local b = BUILDINGS[idx]
    if not b then return end
    local cost = getBuildingCost(b)
    if state.cookies >= cost then
        state.cookies = state.cookies - cost
        b.count = b.count + 1
        playSound("buy")
    end
end

-- Buy Upgrade Handler
local function buyUpgrade(idx)
    local u = UPGRADES[idx]
    if not u or u.bought then return end
    if state.cookies >= u.cost then
        state.cookies = state.cookies - u.cost
        u.bought = true
        u.apply()
        playSound("upgrade")
    end
end

-- Golden Cookie Spawner & Click Handler
local function updateGoldenCookie()
    if state.goldenCookie then
        state.goldenCookie.life = state.goldenCookie.life - 1
        if state.goldenCookie.life <= 0 then
            state.goldenCookie = nil
        end
    else
        -- 1% chance every second to spawn Golden Cookie
        if math.random(1, 250) == 1 then
            state.goldenCookie = {
                x = math.random(5, screenW - 12),
                y = math.random(3, screenH - 4),
                life = 160 -- 8 seconds
            }
            playSound("golden")
        end
    end
end

local function clickGoldenCookie()
    if not state.goldenCookie then return end
    state.goldenCookie = nil
    playSound("frenzy")
    
    local r = math.random(1, 3)
    if r == 1 then
        -- Frenzy: 7x CPS for 15s
        state.frenzyTimer = 300
        addFloatText(cookieCenterX, cookieCenterY - 5, "FRENZY x7 CPS!", "e")
    elseif r == 2 then
        -- Click Frenzy: 777x Clicks for 10s
        state.clickFrenzyTimer = 200
        addFloatText(cookieCenterX, cookieCenterY - 5, "CLICK FRENZY x777!", "4")
    else
        -- Lucky: Instant +15% Cookies
        local bonus = math.max(100, math.floor(state.cookies * 0.15 + getTotalCPS() * 15))
        state.cookies = state.cookies + bonus
        state.totalBaked = state.totalBaked + bonus
        addFloatText(cookieCenterX, cookieCenterY - 5, "+$" .. formatNum(bonus) .. " LUCKY!", "5")
    end
end

-- Active Tab: BUILDINGS, UPGRADES, STATS
local currentTab = "BUILDINGS"

-- Render Screen
local function renderGame()
    clearBuffer("f")
    clearButtons()
    
    screenW, screenH = display.getSize()
    cookieCenterX = math.max(12, math.floor(screenW * 0.28))
    cookieCenterY = math.max(7, math.floor(screenH * 0.48))
    
    -- 1. Top Header Banner
    drawText(1, 1, string.rep(" ", screenW), "0", "7")
    local titleStr = " * CYBER COOKIE CLICKER DELUXE * "
    drawText(math.max(1, math.floor((screenW - #titleStr) / 2)), 1, titleStr, "4", "7")
    
    -- 2. Left Panel: Cookie Stats
    local cStr = string.format("COOKIES: %s", formatNum(state.cookies))
    drawText(cookieCenterX - math.floor(#cStr / 2), cookieCenterY - 6, cStr, "4", "f")
    
    local cpsStr = string.format("per second: %s", formatNum(getTotalCPS()))
    drawText(cookieCenterX - math.floor(#cpsStr / 2), cookieCenterY - 5, cpsStr, "8", "f")
    
    if state.frenzyTimer > 0 then
        drawText(cookieCenterX - 8, cookieCenterY - 7, "[FRENZY x7 ACTIVE!]", "e", "f")
    elseif state.clickFrenzyTimer > 0 then
        drawText(cookieCenterX - 11, cookieCenterY - 7, "[CLICK FRENZY x777!]", "4", "f")
    end
    
    -- 3. Draw Giant Cookie (Animated Bounce)
    local cx = cookieCenterX
    local cy = cookieCenterY
    local bounce = (state.cookieScale > 0)
    
    local cookieArt = {
        "   .---'\"\"\"'---.   ",
        " .'  (#)   (#)  '. ",
        "/ (#)    (#)   (#)\\",
        "|   (#) (#)   (#) |",
        "\\ (#)    (#)   (#)/",
        " '.  (#)   (#)  .' ",
        "   '---.....---'   "
    }
    
    if bounce then
        cookieArt = {
            "   .------------.   ",
            " .'  (#)    (#)  '. ",
            "| (#)   (#)   (#) | ",
            " '.  (#)    (#)  .' ",
            "   '------------'   "
        }
        cy = cy + 1
    end
    
    for i, line in ipairs(cookieArt) do
        local lineX = cx - math.floor(#line / 2)
        local lineY = cy - 3 + i
        drawText(lineX, lineY, line, (bounce and "4" or "1"), "c")
    end
    
    -- Register Giant Cookie Click Zone
    registerButton("COOKIE_CLICK", cx - 9, cy - 3, 19, #cookieArt, "", "0", "c")
    
    -- 4. Golden Cookie
    if state.goldenCookie then
        local gLab = "[* GOLDEN COOKIE *]"
        registerButton("GOLDEN_COOKIE", state.goldenCookie.x, state.goldenCookie.y, #gLab, 1, gLab, "0", "4")
    end
    
    -- 5. Right Panel: Tabs & Market
    local panelX = math.max(cookieCenterX + 12, math.floor(screenW * 0.52))
    local panelW = screenW - panelX
    
    -- Tab Selector Buttons
    registerButton("TAB_BUILDINGS", panelX, 3, 11, 1, "[BUILDINGS]", (currentTab == "BUILDINGS" and "0" or "7"), (currentTab == "BUILDINGS" and "4" or "8"))
    registerButton("TAB_UPGRADES",  panelX + 12, 3, 10, 1, "[UPGRADES]", (currentTab == "UPGRADES" and "0" or "7"), (currentTab == "UPGRADES" and "4" or "8"))
    registerButton("TAB_PRESTIGE",  panelX + 23, 3, 10, 1, "[PRESTIGE]", (currentTab == "PRESTIGE" and "0" or "7"), (currentTab == "PRESTIGE" and "4" or "8"))
    
    -- Tab Contents
    if currentTab == "BUILDINGS" then
        for i, b in ipairs(BUILDINGS) do
            local y = 5 + (i - 1) * 1
            if y < screenH - 2 then
                local cost = getBuildingCost(b)
                local canAfford = (state.cookies >= cost)
                local bLab = string.format("%d.%-11s (%d)", i % 10, string.sub(b.name, 1, 11), b.count)
                local costLab = string.format("$%s", formatNum(cost))
                
                drawText(panelX, y, bLab, (canAfford and "0" or "8"), "f")
                registerButton("BUY_B_" .. i, panelX + panelW - #costLab - 1, y, #costLab, 1, costLab, (canAfford and "0" or "8"), (canAfford and "5" or "7"))
            end
        end
        
    elseif currentTab == "UPGRADES" then
        local drawn = 0
        for i, u in ipairs(UPGRADES) do
            local y = 5 + drawn * 2
            if y < screenH - 2 and not u.bought then
                drawn = drawn + 1
                local canAfford = (state.cookies >= u.cost)
                local uLab = string.format("[%d] %-14s", drawn, string.sub(u.name, 1, 14))
                local uCost = string.format("$%s", formatNum(u.cost))
                
                drawText(panelX, y, uLab, (canAfford and "4" or "8"), "f")
                drawText(panelX + 2, y + 1, u.desc, "7", "f")
                registerButton("BUY_U_" .. i, panelX + panelW - #uCost - 1, y, #uCost, 1, uCost, (canAfford and "0" or "8"), (canAfford and "5" or "7"))
            end
        end
        if drawn == 0 then
            drawText(panelX, 7, "ALL UPGRADES PURCHASED!", "5", "f")
        end
        
    elseif currentTab == "PRESTIGE" then
        drawText(panelX, 5, "=== HEAVENLY ASCENSION ===", "4", "f")
        drawText(panelX, 7, string.format("HEAVENLY CHIPS: %d (+%d%% CPS)", state.heavenlyChips, state.heavenlyChips * 2), "3", "f")
        drawText(panelX, 9, string.format("TOTAL BAKED: %s", formatNum(state.totalBaked)), "7", "f")
        
        local chipsGained = math.floor((state.totalBaked / 1000000) ^ 0.5)
        drawText(panelX, 11, string.format("CHIPS UPON RESET: +%d", chipsGained), "e", "f")
        
        if chipsGained > 0 then
            registerButton("BTN_ASCEND", panelX, 13, 20, 1, "[ ASCEND / RESTART ]", "0", "e")
        else
            drawText(panelX, 13, "(Bake 1M+ cookies to Ascend)", "8", "f")
        end
    end
    
    -- 6. Draw Crumbs & Particles
    drawParticles()
    
    -- 7. Bottom Centered Quick Control Bar
    drawText(1, screenH - 1, string.rep("-", screenW), "7", "f")
    drawText(1, screenH, string.rep(" ", screenW), "0", "7")
    
    local btnW = 20
    local cx = math.max(2, math.floor((screenW - btnW) / 2))
    registerButton("BTN_CLICK_COOKIE", cx, screenH, btnW, 1, "[*** CLICK COOKIE ***]", "0", "5")
    
    drawButtons()
    flushBuffer()
end

-- Main Game Loop
local function main()
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local timerId = os.startTimer(0.05)
    local secondTimer = 0
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.05)
            
            -- Passive Cookie Income (0.05s per tick)
            local cps = getTotalCPS()
            state.cookies = state.cookies + (cps * 0.05)
            state.totalBaked = state.totalBaked + (cps * 0.05)
            
            if state.cookieScale > 0 then state.cookieScale = state.cookieScale - 1 end
            if state.frenzyTimer > 0 then state.frenzyTimer = state.frenzyTimer - 1 end
            if state.clickFrenzyTimer > 0 then state.clickFrenzyTimer = state.clickFrenzyTimer - 1 end
            
            secondTimer = secondTimer + 1
            if secondTimer >= 20 then
                secondTimer = 0
                updateGoldenCookie()
            end
            
            updateParticles()
            renderGame()
            
        elseif event == "key" then
            if p1 == keys.space or p1 == keys.enter then
                clickGiantCookie()
            elseif p1 == keys.one then buyBuilding(1)
            elseif p1 == keys.two then buyBuilding(2)
            elseif p1 == keys.three then buyBuilding(3)
            elseif p1 == keys.four then buyBuilding(4)
            elseif p1 == keys.five then buyBuilding(5)
            elseif p1 == keys.six then buyBuilding(6)
            elseif p1 == keys.seven then buyBuilding(7)
            elseif p1 == keys.eight then buyBuilding(8)
            elseif p1 == keys.nine then buyBuilding(9)
            elseif p1 == keys.zero then buyBuilding(10)
            elseif p1 == keys.b then currentTab = "BUILDINGS"
            elseif p1 == keys.u then currentTab = "UPGRADES"
            elseif p1 == keys.p then currentTab = "PRESTIGE"
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "COOKIE_CLICK" or cid == "BTN_CLICK_COOKIE" then
                clickGiantCookie()
            elseif cid == "GOLDEN_COOKIE" then
                clickGoldenCookie()
            elseif cid == "TAB_BUILDINGS" then
                currentTab = "BUILDINGS"
            elseif cid == "TAB_UPGRADES" then
                currentTab = "UPGRADES"
            elseif cid == "TAB_PRESTIGE" then
                currentTab = "PRESTIGE"
            elseif cid and string.sub(cid, 1, 6) == "BUY_B_" then
                local bIdx = tonumber(string.sub(cid, 7))
                buyBuilding(bIdx)
            elseif cid and string.sub(cid, 1, 6) == "BUY_U_" then
                local uIdx = tonumber(string.sub(cid, 7))
                buyUpgrade(uIdx)
            elseif cid == "BTN_ASCEND" then
                local chipsGained = math.floor((state.totalBaked / 1000000) ^ 0.5)
                if chipsGained > 0 then
                    state.heavenlyChips = state.heavenlyChips + chipsGained
                    state.cookies = 0
                    state.totalBaked = 0
                    state.clickPower = 1
                    for _, b in ipairs(BUILDINGS) do b.count = 0 end
                    for _, u in ipairs(UPGRADES) do u.bought = false end
                    playSound("prestige")
                end
            else
                -- Clicked directly on the left side (Cookie side)
                if mx < cookieCenterX + 10 then
                    clickGiantCookie()
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Cookie Clicker closed.")
    else
        print("Cookie Clicker closed.")
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
