-- ============================================================================
-- CYBER SOLS RNG 2077: MYTHIC AURAS DELUXE EDITION
-- Authentic Cooldown System, Speed Potions, Reel Spin & Mythic Supernova FX
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
    [colors.orange]    = 0xFF8C00, -- Legendary Auras
    [colors.magenta]   = 0xE91E63, -- Cosmic Auras
    [colors.lightBlue] = 0x00E5FF, -- Rare / Divine
    [colors.yellow]    = 0xFFD600, -- Coins / Transcendent
    [colors.lime]      = 0x00E676, -- Uncommon / Success
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x181F2C, -- Base Hull
    [colors.lightGray] = 0x303E55, -- Card Panels
    [colors.cyan]      = 0x18FFFF, -- Luck Multiplier
    [colors.purple]    = 0x7C4DFF, -- Epic Auras
    [colors.blue]      = 0x0D1628, -- Deep Navy Frame
    [colors.brown]     = 0x4E342E,
    [colors.green]     = 0x1B4332,
    [colors.red]       = 0xFF1744, -- Mythic Auras
    [colors.black]     = 0x080B11
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- TOUCH BUTTONS ENGINE
-- ============================================================================
local TouchButtons = {}
local function clearButtons()
    TouchButtons = {}
end

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
-- AURA TIERS & ROSTER (1 in 2 to 1 in 10,000,000!)
-- ============================================================================
local AURAS = {
    [1]  = { name = "Pebble", odds = 2, tier = "COMMON", col = "lightGray", sound = "common", auraArt = "( * )" },
    [2]  = { name = "Crystal Sprout", odds = 5, tier = "UNCOMMON", col = "lime", sound = "common", auraArt = "< * >" },
    [3]  = { name = "Gilded Spark", odds = 15, tier = "UNCOMMON", col = "yellow", sound = "common", auraArt = "+ * +" },
    [4]  = { name = "Plasma Spark", odds = 50, tier = "RARE", col = "lightBlue", sound = "rare", auraArt = "~[O]~" },
    [5]  = { name = "Glacier Frost", odds = 150, tier = "RARE", col = "cyan", sound = "rare", auraArt = "*[*] *" },
    [6]  = { name = "Shadow Vortex", odds = 500, tier = "EPIC", col = "purple", sound = "rare", auraArt = "((#))" },
    [7]  = { name = "Neon Lightning", odds = 1500, tier = "EPIC", col = "magenta", sound = "rare", auraArt = "//\\\\" },
    [8]  = { name = "Solar Flare", odds = 5000, tier = "LEGENDARY", col = "orange", sound = "legendary", auraArt = "==[O]==" },
    [9]  = { name = "Infernal Blaze", odds = 25000, tier = "LEGENDARY", col = "red", sound = "legendary", auraArt = "###(O)###" },
    [10] = { name = "Blood Moon", odds = 100000, tier = "MYTHIC", col = "red", sound = "mythic", auraArt = "<[[BLOOD]]>" },
    [11] = { name = "Archangel Seraph", odds = 500000, tier = "DIVINE", col = "lightBlue", sound = "mythic", auraArt = "<--{DIVINE}-->" },
    [12] = { name = "Galaxy Destroyer", odds = 2000000, tier = "COSMIC", col = "magenta", sound = "cosmic", auraArt = "**[[COSMOS]]**" },
    [13] = { name = "CHRONOS LORD", odds = 10000000, tier = "TRANSCENDENT", col = "yellow", sound = "cosmic", auraArt = "<**[TIME-LORD]**>" }
}

-- GAUNTLETS & SPEED UPGRADES (COOLDOWN & LUCK)
local GAUNTLETS = {
    [1] = { name = "Basic Gauntlet", cost = 0, luckMult = 1.0, cdSec = 2.0 },
    [2] = { name = "Lucky Clover Glove", cost = 500, luckMult = 1.5, cdSec = 1.6 },
    [3] = { name = "Solar Flare Glove", cost = 2500, luckMult = 2.5, cdSec = 1.2 },
    [4] = { name = "Quantum Chrono Glove", cost = 10000, luckMult = 5.0, cdSec = 0.8 },
    [5] = { name = "ARCHANGEL GAUNTLET", cost = 50000, luckMult = 12.0, cdSec = 0.4 }
}

-- ============================================================================
-- GAME STATE ENGINE & PERSISTENCE
-- ============================================================================
local SAVE_FILE = ".sols_rng_save"
local state = {
    rolls = 0,
    coins = 100,
    equippedAura = 1,
    bestAura = 1,
    unlocked = { [1] = true },
    gauntletLevel = 1,
    autoRoll = false,
    autoSkipTier = 1,
    speedBoostPotion = 0 -- extra speed buff
}

local function loadState()
    if fs.exists(SAVE_FILE) then
        local f = fs.open(SAVE_FILE, "r")
        if f then
            local data = textutils.unserialize(f.readAll())
            f.close()
            if type(data) == "table" then
                for k, v in pairs(data) do state[k] = v end
            end
        end
    end
end

local function saveState()
    local f = fs.open(SAVE_FILE, "w")
    if f then
        f.write(textutils.serialize(state))
        f.close()
    end
end

loadState()

local currentRollAura = AURAS[state.equippedAura] or AURAS[1]
local currentView = "ROLL" -- "ROLL", "COLLECTION", "SHOP"
local isRolling = false
local lastRollTime = 0

local function getActiveCooldown()
    local g = GAUNTLETS[state.gauntletLevel] or GAUNTLETS[1]
    local baseCD = g.cdSec
    if state.speedBoostPotion > 0 then
        baseCD = baseCD * 0.5
    end
    return baseCD
end

local function getRemainingCooldown()
    local now = os.clock()
    local elapsed = now - lastRollTime
    local cd = getActiveCooldown()
    local rem = cd - elapsed
    return (rem > 0) and rem or 0
end

-- ============================================================================
-- ANIMATIONS: REEL SPIN & MYTHIC SUPERNOVA EXPLOSION FX
-- ============================================================================
local function playMythicExplosionFX(aura)
    local screenW, screenH = display.getSize()
    local midX = math.floor(screenW / 2)
    local midY = math.floor(screenH / 2)
    
    local isSuperMythic = (aura.odds >= 100000)
    local flashColors = isSuperMythic and { colors.yellow, colors.magenta, colors.red, colors.white } or { colors.cyan, colors.lime, colors.lightBlue }
    
    -- 1. Screen Flash & Nova Burst
    for step = 1, 4 do
        display.setBackgroundColor(flashColors[(step % #flashColors) + 1])
        display.clear()
        
        display.setCursorPos(math.max(2, midX - 18), midY - 3)
        display.setTextColor(colors.white)
        display.write(">> * * * MYTHIC AURA DISCOVERED * * * <<")
        
        display.setCursorPos(math.max(2, midX - math.floor(#aura.name / 2) - 4), midY)
        display.setTextColor(colors.yellow)
        display.write(string.format(">>> %s <<<", aura.name))
        
        display.setCursorPos(math.max(2, midX - 12), midY + 3)
        display.setTextColor(colors.cyan)
        display.write(string.format("ODDS: 1 in %s", tostring(aura.odds)))
        
        sleep(0.06)
    end
    
    -- 2. Expanding Particle Rays
    for r = 1, 3 do
        display.setBackgroundColor(colors.black)
        display.clear()
        
        display.setCursorPos(midX - 2, midY - r - 1)
        display.setTextColor(colors.yellow)
        display.write("\\ | /")
        
        display.setCursorPos(midX - 4, midY)
        display.setTextColor(colors.magenta)
        display.write("-- * --")
        
        display.setCursorPos(midX - 2, midY + r + 1)
        display.setTextColor(colors.yellow)
        display.write("/ | \\")
        
        display.setCursorPos(math.max(2, midX - math.floor(#aura.name / 2) - 4), midY)
        display.setTextColor(colors.white)
        display.write(string.format("[ %s ]", aura.name))
        
        sleep(0.05)
    end
    
    sleep(0.15)
end

-- Holographic Slot Reel Spin Animation
local function runRollAnimation(chosenAura)
    local screenW, screenH = display.getSize()
    local midX = math.floor(screenW / 2)
    local midY = math.floor(screenH / 2)
    
    local spins = 10
    for s = 1, spins do
        local randomAura = AURAS[math.random(1, #AURAS)]
        
        local bw = 38
        local bx = math.floor((screenW - bw) / 2)
        local by = midY - 3
        
        for dy = 0, 6 do
            display.setCursorPos(bx, by + dy)
            display.setBackgroundColor(colors.blue)
            display.write(string.rep(" ", bw))
        end
        
        display.setCursorPos(bx, by)
        display.setTextColor(colors.cyan)
        display.write("+" .. string.rep("=", bw - 2) .. "+")
        display.setCursorPos(bx, by + 6)
        display.write("+" .. string.rep("=", bw - 2) .. "+")
        
        display.setCursorPos(bx + 4, by + 2)
        display.setTextColor(colors.yellow)
        display.write(">> * ROLLING COSMIC AURAS * <<")
        
        display.setCursorPos(bx + 6, by + 4)
        display.setTextColor(colors[randomAura.col] or colors.white)
        display.write(string.format(">>> %-18s <<<", string.sub(randomAura.name, 1, 18)))
        
        sleep(0.02 + (s / spins) * 0.04)
    end
    
    if chosenAura.odds >= 5000 then
        playMythicExplosionFX(chosenAura)
    else
        sleep(0.08)
    end
end

-- ============================================================================
-- ROLL LOGIC
-- ============================================================================
local function executeRoll()
    if getRemainingCooldown() > 0 then return end
    
    isRolling = true
    lastRollTime = os.clock()
    state.rolls = state.rolls + 1
    
    local g = GAUNTLETS[state.gauntletLevel] or GAUNTLETS[1]
    local effectiveLuck = g.luckMult
    
    -- Pick Aura based on weighted RNG
    local pickedAura = AURAS[1]
    for i = #AURAS, 1, -1 do
        local a = AURAS[i]
        local rollVal = math.random(1, math.max(1, math.floor(a.odds / effectiveLuck)))
        if rollVal == 1 then
            pickedAura = a
            break
        end
    end
    
    -- Animation
    runRollAnimation(pickedAura)
    
    currentRollAura = pickedAura
    state.unlocked[pickedAura.odds] = true
    
    -- Coins Reward
    local coinReward = math.max(5, math.floor(math.log10(pickedAura.odds + 1) * 35))
    state.coins = state.coins + coinReward
    
    -- Check Best Aura
    if pickedAura.odds > (AURAS[state.bestAura] and AURAS[state.bestAura].odds or 0) then
        for idx, a in ipairs(AURAS) do
            if a.odds == pickedAura.odds then state.bestAura = idx break end
        end
    end
    
    -- Auto-Equip if better than current
    if pickedAura.odds > (AURAS[state.equippedAura] and AURAS[state.equippedAura].odds or 0) then
        for idx, a in ipairs(AURAS) do
            if a.odds == pickedAura.odds then state.equippedAura = idx break end
        end
    end
    
    saveState()
    isRolling = false
end

-- ============================================================================
-- UI RENDERERS (ROLL, COLLECTION, SHOP)
-- ============================================================================
local function renderMainRollScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top Glass Status Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local leftHdr = " >> SOLS RNG 2077 PRO <<"
    display.setCursorPos(2, 1)
    display.write(leftHdr)
    
    local g = GAUNTLETS[state.gauntletLevel] or GAUNTLETS[1]
    local rightStatus = string.format(" COINS: $%d | ROLLS: %d | LUCK: %.1fx ", state.coins, state.rolls, g.luckMult)
    display.setCursorPos(screenW - #rightStatus, 1)
    display.setTextColor(colors.lightBlue)
    display.write(rightStatus)
    
    registerButton("BTN_QUIT", screenW - 3, 1, 3, 1, "[X]", "white", "red")
    
    -- 2. Navigation Tabs (Line 3)
    registerButton("TAB_ROLL", 2, 3, 12, 1, " [* ROLL] ", "yellow", "green")
    registerButton("TAB_COLLECTION", 16, 3, 16, 1, " [ COLLECTION ] ", "lightGray", "gray")
    registerButton("TAB_SHOP", 34, 3, 12, 1, " [ SHOP ] ", "lightGray", "gray")
    
    -- 3. Center Aura Showcase Card
    local midX = math.floor(screenW / 2)
    local cardW = math.min(46, screenW - 6)
    local cardH = 10
    local cardX = math.floor((screenW - cardW) / 2)
    local cardY = 5
    
    for dy = 0, cardH - 1 do
        display.setCursorPos(cardX, cardY + dy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", cardW))
    end
    
    display.setCursorPos(cardX, cardY)
    display.setTextColor(colors.lightGray)
    display.write("+" .. string.rep("=", cardW - 2) .. "+")
    display.setCursorPos(cardX, cardY + cardH - 1)
    display.write("+" .. string.rep("=", cardW - 2) .. "+")
    
    -- Aura Glyph Art
    display.setCursorPos(cardX + math.floor((cardW - #currentRollAura.auraArt) / 2), cardY + 2)
    display.setTextColor(colors[currentRollAura.col] or colors.yellow)
    display.write(currentRollAura.auraArt)
    
    -- Aura Name
    local nameStr = string.format(">> %s <<", currentRollAura.name)
    display.setCursorPos(cardX + math.floor((cardW - #nameStr) / 2), cardY + 4)
    display.setTextColor(colors.white)
    display.write(nameStr)
    
    -- Tier & Odds
    local tierStr = string.format("TIER: %s | RARITY: 1 in %s", currentRollAura.tier, tostring(currentRollAura.odds))
    display.setCursorPos(cardX + math.floor((cardW - #tierStr) / 2), cardY + 6)
    display.setTextColor(colors.cyan)
    display.write(tierStr)
    
    -- Equipped Badge
    local eqAura = AURAS[state.equippedAura] or AURAS[1]
    display.setCursorPos(cardX + 2, cardY + 8)
    display.setTextColor(colors.yellow)
    display.write(string.format("EQUIPPED: %-16s | BEST: %s", eqAura.name, (AURAS[state.bestAura] and AURAS[state.bestAura].name or "Pebble")))
    
    -- 4. Cooldown Bar & Roll Controls (Lines 16 to 18)
    local remCD = getRemainingCooldown()
    local totalCD = getActiveCooldown()
    local isReady = (remCD <= 0)
    
    local cdPct = (totalCD > 0) and math.max(0, math.min(1, 1 - (remCD / totalCD))) or 1
    local barW = math.min(36, screenW - 12)
    local barX = math.floor((screenW - barW) / 2)
    local filledSegs = math.floor(cdPct * (barW - 2))
    
    display.setCursorPos(barX, 16)
    display.setBackgroundColor(colors.black)
    display.setTextColor(isReady and colors.lime or colors.yellow)
    local cdLabel = isReady and " [ READY TO ROLL ] " or string.format(" [ COOLDOWN: %.1fs ] ", remCD)
    display.setCursorPos(math.max(2, math.floor((screenW - #cdLabel) / 2)), 16)
    display.write(cdLabel)
    
    -- Graphical Cooldown Gauge
    display.setCursorPos(barX, 17)
    display.setTextColor(colors.cyan)
    display.write("[")
    display.setTextColor(isReady and colors.lime or colors.orange)
    display.write(string.rep("=", filledSegs))
    display.setTextColor(colors.gray)
    display.write(string.rep("-", (barW - 2) - filledSegs))
    display.setTextColor(colors.cyan)
    display.write("]")
    
    -- 5. Roll Buttons
    local rollBtnW = 16
    local rollBtnX = math.floor((screenW - (rollBtnW * 2 + 4)) / 2)
    
    local rollLbl = isReady and " [>> ROLL (R) <<] " or string.format(" [ CD: %.1fs ] ", remCD)
    local rollBg = isReady and "green" or "gray"
    registerButton("BTN_ROLL", rollBtnX, 19, rollBtnW, 2, rollLbl, "yellow", rollBg)
    
    local autoLbl = state.autoRoll and " [AUTO: ON] " or " [AUTO: OFF] "
    local autoBg = state.autoRoll and "green" or "blue"
    registerButton("TOGGLE_AUTO", rollBtnX + rollBtnW + 4, 19, 14, 2, autoLbl, "white", autoBg)
    
    -- Bottom Hint
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.lightBlue)
    display.write(" [SPACE/R] Roll | [A] Auto-Roll | [C] Collection | [S] Shop | [Q] Exit to Hub ")
    
    drawButtons()
end

-- Collection Screen
local function renderCollectionScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    display.setCursorPos(2, 1)
    display.write(" >> AURA COMPENDIUM & COLLECTION << ")
    registerButton("BTN_BACK", screenW - 12, 1, 10, 1, " [< BACK] ", "yellow", "gray")
    
    local startY = 4
    for idx, a in ipairs(AURAS) do
        local isUnlocked = state.unlocked[a.odds]
        local isEquipped = (state.equippedAura == idx)
        local y = startY + (idx - 1)
        
        if y <= screenH - 2 then
            display.setCursorPos(2, y)
            display.setBackgroundColor((idx % 2 == 1) and colors.gray or colors.black)
            display.write(string.rep(" ", screenW - 2))
            
            display.setCursorPos(3, y)
            if isUnlocked then
                display.setTextColor(colors[a.col] or colors.white)
                display.write(string.format("[%2d] %-18s ", idx, a.name))
                display.setTextColor(colors.cyan)
                display.write(string.format(" 1 in %-10s ", tostring(a.odds)))
                display.setTextColor(colors.lightBlue)
                display.write(string.format(" %-12s ", a.tier))
                
                if isEquipped then
                    display.setTextColor(colors.lime)
                    display.write(" [EQUIPPED] ")
                else
                    registerButton("EQUIP_" .. idx, screenW - 14, y, 10, 1, " [EQUIP] ", "yellow", "blue")
                end
            else
                display.setTextColor(colors.lightGray)
                display.write(string.format("[%2d] ??? LOCKED ???       1 in %-10s ", idx, tostring(a.odds)))
            end
        end
    end
    
    drawButtons()
end

-- Shop Screen
local function renderShopScreen()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    display.setCursorPos(2, 1)
    display.write(string.format(" >> LUCK GAUNTLETS & SPEED POTION SHOP (COINS: $%d) << ", state.coins))
    registerButton("BTN_BACK", screenW - 12, 1, 10, 1, " [< BACK] ", "yellow", "gray")
    
    local startY = 4
    for idx, g in ipairs(GAUNTLETS) do
        local isOwned = (state.gauntletLevel >= idx)
        local isEquipped = (state.gauntletLevel == idx)
        local y = startY + (idx - 1) * 3
        
        display.setCursorPos(2, y)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", screenW - 2))
        
        display.setCursorPos(3, y)
        display.setTextColor(isEquipped and colors.yellow or colors.white)
        display.write(string.format("[%d] %-22s ", idx, g.name))
        display.setTextColor(colors.lime)
        display.write(string.format(" LUCK: %.1fx ", g.luckMult))
        display.setTextColor(colors.cyan)
        display.write(string.format(" CD: %.1fs ", g.cdSec))
        
        if isOwned then
            display.setCursorPos(screenW - 14, y)
            display.setTextColor(colors.lime)
            display.write(" [OWNED] ")
        else
            local canBuy = (state.coins >= g.cost)
            local buyBg = canBuy and "green" or "red"
            registerButton("BUY_G_" .. idx, screenW - 16, y, 14, 1, string.format(" [BUY $%d] ", g.cost), "white", buyBg)
        end
    end
    
    drawButtons()
end

-- ============================================================================
-- MAIN EVENT LOOP
-- ============================================================================
local function main()
    local needsRedraw = true
    local autoTimer = os.startTimer(0.1)
    
    while true do
        if needsRedraw then
            if currentView == "COLLECTION" then
                renderCollectionScreen()
            elseif currentView == "SHOP" then
                renderShopScreen()
            else
                renderMainRollScreen()
            end
            needsRedraw = false
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == autoTimer then
            if currentView == "ROLL" then
                if state.autoRoll and not isRolling and getRemainingCooldown() <= 0 then
                    executeRoll()
                end
                needsRedraw = true
            end
            autoTimer = os.startTimer(0.1)
            
        elseif event == "key" then
            needsRedraw = true
            if p1 == keys.q or p1 == keys.escape then
                if currentView == "COLLECTION" or currentView == "SHOP" then
                    currentView = "ROLL"
                else
                    break
                end
            elseif currentView == "ROLL" then
                if p1 == keys.space or p1 == keys.r or p1 == keys.enter then
                    executeRoll()
                elseif p1 == keys.a then
                    state.autoRoll = not state.autoRoll
                    saveState()
                elseif p1 == keys.c then
                    currentView = "COLLECTION"
                elseif p1 == keys.s then
                    currentView = "SHOP"
                end
            elseif currentView == "COLLECTION" or currentView == "SHOP" then
                if p1 == keys.b or p1 == keys.space or p1 == keys.enter then
                    currentView = "ROLL"
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            needsRedraw = true
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_QUIT" then
                break
            elseif cid == "BTN_BACK" then
                currentView = "ROLL"
            elseif cid == "TAB_ROLL" then
                currentView = "ROLL"
            elseif cid == "TAB_COLLECTION" then
                currentView = "COLLECTION"
            elseif cid == "TAB_SHOP" then
                currentView = "SHOP"
            elseif cid == "BTN_ROLL" then
                executeRoll()
            elseif cid == "TOGGLE_AUTO" then
                state.autoRoll = not state.autoRoll
                saveState()
            elseif currentView == "COLLECTION" and cid and string.sub(cid, 1, 6) == "EQUIP_" then
                local idx = tonumber(string.sub(cid, 7))
                if idx and state.unlocked[AURAS[idx].odds] then
                    state.equippedAura = idx
                    saveState()
                end
            elseif currentView == "SHOP" and cid and string.sub(cid, 1, 6) == "BUY_G_" then
                local idx = tonumber(string.sub(cid, 7))
                local g = GAUNTLETS[idx]
                if g and state.coins >= g.cost and state.gauntletLevel < idx then
                    state.coins = state.coins - g.cost
                    state.gauntletLevel = idx
                    saveState()
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Sols RNG closed.")
    else
        print("Sols RNG closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("RNG Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("RNG Error: " .. tostring(err))
end
