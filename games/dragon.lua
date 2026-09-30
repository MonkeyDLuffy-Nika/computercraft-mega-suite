-- ============================================================================
-- DRAGON SANCTUARY - VIRTUAL PET SIMULATOR - CC: TWEAKED
-- Raise, Feed, Groom, Train, Play & Evolve Your Ancient Mythical Dragon
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
-- VIBRANT DRAGON PALETTE
-- ============================================================================
local DRAGON_PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF8C14, -- Fire Orange
    [colors.magenta]   = 0xEB4BBE, -- Magic Purple
    [colors.lightBlue] = 0x64B4FF, -- Sky Blue
    [colors.yellow]    = 0xFFE628, -- Gold Coins & Eyes
    [colors.lime]      = 0x5AEB28, -- Health Green
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x3C3C46, -- Stone Cave
    [colors.lightGray] = 0xAAAFB9,
    [colors.cyan]      = 0x1ED2DC, -- Ice / Sparkles
    [colors.purple]    = 0x7828C8, -- Dragon Scales
    [colors.blue]      = 0x285FEB,
    [colors.brown]     = 0x8C4B23, -- Meat / Nest
    [colors.green]     = 0x249B30,
    [colors.red]       = 0xEB2D2D, -- Flame Red
    [colors.black]     = 0x08080C
}

if display.setPaletteColor then
    for col, hexVal in pairs(DRAGON_PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- SOUND SYNTHESIZER
-- ============================================================================
local isMuted = false
local function playSound(snd)
    if isMuted or not speaker then return end
    pcall(function()
        if snd == "feed" then
            speaker.playNote("snare", 0.7, 8)
            sleep(0.04)
            speaker.playNote("snare", 0.7, 12)
        elseif snd == "pet" then
            speaker.playNote("chime", 0.8, 16)
            sleep(0.04)
            speaker.playNote("chime", 0.8, 20)
        elseif snd == "fire" then
            speaker.playNote("snare", 0.9, 14)
            speaker.playNote("bass", 0.9, 8)
        elseif snd == "evolve" then
            for p = 10, 24, 3 do
                speaker.playNote("chime", 0.9, p)
                sleep(0.03)
            end
        elseif snd == "clean" then
            speaker.playNote("bell", 0.7, 18)
            speaker.playNote("bell", 0.7, 22)
        elseif snd == "coin" then
            speaker.playNote("bell", 0.8, 20)
        elseif snd == "roar" then
            speaker.playNote("bass", 1.0, 4)
            sleep(0.06)
            speaker.playNote("bass", 1.0, 6)
            sleep(0.06)
            speaker.playNote("bass", 1.0, 8)
        end
    end)
end

-- ============================================================================
-- DRAGON STATE & PERSISTENCE
-- ============================================================================
local SAVE_FILE = "dragon_save.json"

local dragon = {
    name = "Ignis",
    element = "Fire",    -- "Fire", "Ice", "Thunder", "Void"
    stage = 1,          -- 1: Egg, 2: Baby, 3: Drake, 4: Elder Dragon
    xp = 0,
    maxXp = 100,
    level = 1,
    coins = 50,
    
    -- Needs (0..100)
    hunger = 80,
    energy = 90,
    happiness = 85,
    hygiene = 90,
    firePower = 20,
    
    isSleeping = false,
    eggWarmth = 40,      -- for stage 1
    lastActionMsg = "Welcome to your Dragon Sanctuary!",
    actionTimer = 0
}

-- Load Game
local function loadGame()
    if fs.exists(SAVE_FILE) then
        local f = fs.open(SAVE_FILE, "r")
        if f then
            local data = textutils.unserializeJSON(f.readAll())
            f.close()
            if data and type(data) == "table" then
                for k, v in pairs(data) do dragon[k] = v end
            end
        end
    end
end

-- Save Game
local function saveGame()
    local f = fs.open(SAVE_FILE, "w")
    if f then
        f.write(textutils.serializeJSON(dragon))
        f.close()
    end
end

loadGame()

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

-- ============================================================================
-- GAME ANIMATION TICKS & LOGIC
-- ============================================================================
local animTick = 0
local activeTab = "MAIN" -- "MAIN", "MINIGAME", "SHOP", "STATS"

-- Mini-game (Fire Target Shooting)
local minigame = {
    active = false,
    score = 0,
    targetX = 10,
    targetSpeed = 1,
    fireballX = -1,
    fireballY = -1,
    timeLeft = 30
}

local function setStatus(msg, sound)
    dragon.lastActionMsg = msg
    dragon.actionTimer = 40
    if sound then playSound(sound) end
    saveGame()
end

local function addXP(amount)
    dragon.xp = dragon.xp + amount
    if dragon.xp >= dragon.maxXp then
        dragon.xp = dragon.xp - dragon.maxXp
        dragon.level = dragon.level + 1
        dragon.maxXp = math.floor(dragon.maxXp * 1.5)
        
        -- Stage Evolution Check
        if dragon.level == 3 and dragon.stage == 1 then
            dragon.stage = 2
            setStatus("CONGRATULATIONS! Your Dragon Egg hatched into a Baby Hatchling!", "evolve")
        elseif dragon.level == 6 and dragon.stage == 2 then
            dragon.stage = 3
            setStatus("EVOLUTION! Your Dragon grew wings and evolved into a Drake!", "evolve")
        elseif dragon.level == 10 and dragon.stage == 3 then
            dragon.stage = 4
            setStatus("LEGENDARY EVOLUTION! Your Dragon is now an Ancient Sky Leviathan!", "evolve")
        else
            setStatus(string.format("Level Up! %s reached Level %d!", dragon.name, dragon.level), "evolve")
        end
    end
end

-- Care Actions
local function actionFeed()
    if dragon.stage == 1 then
        setStatus("An egg cannot eat food yet! Keep it warm to hatch.", "clean")
        return
    end
    if dragon.isSleeping then
        setStatus(dragon.name .. " is sleeping. Wake them up first.", "clean")
        return
    end
    if dragon.hunger >= 100 then
        setStatus(dragon.name .. " is completely full and happy!", "pet")
        return
    end
    dragon.hunger = math.min(100, dragon.hunger + 25)
    dragon.happiness = math.min(100, dragon.happiness + 10)
    dragon.hygiene = math.max(0, dragon.hygiene - 5)
    addXP(15)
    setStatus(dragon.name .. " munched on tasty roasted meat! (+Hunger, +XP)", "feed")
end

local function actionPet()
    if dragon.stage == 1 then
        dragon.eggWarmth = math.min(100, dragon.eggWarmth + 15)
        addXP(10)
        setStatus("You gently warm and stroke the magical egg! (+Warmth)", "pet")
        return
    end
    dragon.happiness = math.min(100, dragon.happiness + 20)
    addXP(10)
    setStatus(dragon.name .. " purrs happily and leans into your hand! (+Happiness)", "pet")
end

local function actionClean()
    if dragon.stage == 1 then
        setStatus("Polished the shell of the dragon egg until it shines!", "clean")
        return
    end
    dragon.hygiene = 100
    dragon.happiness = math.min(100, dragon.happiness + 10)
    addXP(15)
    setStatus("You washed and brushed " .. dragon.name .. "'s shiny scales! (+Cleanliness)", "clean")
end

local function actionSleep()
    dragon.isSleeping = not dragon.isSleeping
    if dragon.isSleeping then
        setStatus(dragon.name .. " curled up in the warm nest to sleep (Zzz...)", "pet")
    else
        dragon.energy = 100
        setStatus(dragon.name .. " woke up full of energy!", "pet")
    end
end

local function actionRoar()
    if dragon.stage == 1 then return end
    dragon.firePower = math.min(100, dragon.firePower + 10)
    addXP(20)
    setStatus(dragon.name .. " unleashed a mighty fiery roar into the sky!", "roar")
end

-- ============================================================================
-- DRAW DRAGON SPRITES (SUBPIXEL / PROCEDURAL)
-- ============================================================================
local function drawDragon(midX, midY)
    local breathe = (math.floor(animTick / 4) % 2)
    local dy = midY + breathe
    
    if dragon.stage == 1 then
        -- STAGE 1: MAGICAL DRAGON EGG
        display.setCursorPos(midX - 4, dy - 3)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.purple)
        display.write("   /\\   ")
        display.setCursorPos(midX - 4, dy - 2)
        display.write("  /  \\  ")
        display.setCursorPos(midX - 4, dy - 1)
        display.setTextColor((animTick % 6 < 3) and colors.magenta or colors.yellow)
        display.write(" ( <@> )") -- Glowing core
        display.setCursorPos(midX - 4, dy)
        display.setTextColor(colors.purple)
        display.write("  \\  /  ")
        display.setCursorPos(midX - 4, dy + 1)
        display.write("   \\/   ")
        
        -- Nest
        display.setCursorPos(midX - 6, dy + 2)
        display.setBackgroundColor(colors.brown)
        display.setTextColor(colors.orange)
        display.write("[=== WARM NEST ===]")
        
    elseif dragon.stage == 2 then
        -- STAGE 2: BABY HATCHLING
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.purple)
        display.setCursorPos(midX - 4, dy - 2)
        display.write("  /\\_/\\  ") -- Cute Horns
        display.setCursorPos(midX - 4, dy - 1)
        display.setTextColor(colors.yellow)
        display.write(" ( o.o ) ") -- Big Baby Eyes
        display.setCursorPos(midX - 5, dy)
        display.setTextColor(colors.purple)
        display.write(" /( \\_./ )\\") -- Tiny Wings & Body
        display.setCursorPos(midX - 4, dy + 1)
        display.write("  (vv vv) ") -- Feet
        
        if dragon.isSleeping then
            display.setCursorPos(midX + 4, dy - 3)
            display.setTextColor(colors.lightBlue)
            display.write("Zzz...")
        end
        
    elseif dragon.stage == 3 then
        -- STAGE 3: YOUNG DRAKE
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.red)
        display.setCursorPos(midX - 8, dy - 4)
        display.write("      /\\__/\\     ")
        display.setCursorPos(midX - 8, dy - 3)
        display.setTextColor(colors.yellow)
        display.write("  <\\ ( O_O ) />  ") -- Medium Wings
        display.setCursorPos(midX - 8, dy - 2)
        display.setTextColor(colors.purple)
        display.write("   \\/  _  \//   ")
        display.setCursorPos(midX - 8, dy - 1)
        display.write("    (  /_\\  )    ")
        display.setCursorPos(midX - 8, dy)
        display.write("    //VV VV\\    ")
        display.setCursorPos(midX - 8, dy + 1)
        display.write("   ((       ))   ")
        
        -- Flame breath particle
        if animTick % 8 < 3 and not dragon.isSleeping then
            display.setCursorPos(midX + 7, dy - 3)
            display.setTextColor(colors.orange)
            display.write(">>*~")
        end
        
    else
        -- STAGE 4: ANCIENT SKY LEVIATHAN (ELDER DRAGON)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.red)
        display.setCursorPos(midX - 12, dy - 5)
        display.write("         /\\___/\\        ")
        display.setCursorPos(midX - 12, dy - 4)
        display.setTextColor(colors.yellow)
        display.write("  <\\\\ (  *_*  ) ////> ") -- Massive Wings
        display.setCursorPos(midX - 12, dy - 3)
        display.setTextColor(colors.purple)
        display.write("   \\\\/  ===  \////  ")
        display.setCursorPos(midX - 12, dy - 2)
        display.write("    \\(  /===/  )//   ")
        display.setCursorPos(midX - 12, dy - 1)
        display.write("     ((  \\===/  ))    ")
        display.setCursorPos(midX - 12, dy)
        display.write("     //  V   V  \\    ")
        display.setCursorPos(midX - 12, dy + 1)
        display.write("    ((===========))   ")
        
        -- Roar Flashing Flames
        if animTick % 6 < 3 and not dragon.isSleeping then
            display.setCursorPos(midX + 11, dy - 4)
            display.setTextColor(colors.orange)
            display.write(">>>[FLAME]<<<")
        end
    end
end

-- ============================================================================
-- DRAW STAT BARS
-- ============================================================================
local function drawStatBar(x, y, label, val, maxVal, col)
    display.setCursorPos(x, y)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write(string.format("%-11s: ", label))
    
    local barW = 14
    local fillW = math.floor((val / (maxVal or 100)) * barW)
    fillW = math.min(barW, math.max(0, fillW))
    
    display.setBackgroundColor(colors[col] or colors.lime)
    display.write(string.rep(" ", fillW))
    display.setBackgroundColor(colors.gray)
    display.write(string.rep(" ", barW - fillW))
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(string.format(" %3d%%", val))
end

-- ============================================================================
-- MAIN DASHBOARD RENDER
-- ============================================================================
local function renderSanctuary()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top Header Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local stageNames = { "DRAGON EGG", "BABY HATCHLING", "YOUNG DRAKE", "ELDER DRAGON" }
    local titleStr = string.format(" [ %s: '%s' ] - %s (LVL %d)   GOLD: %d G ", string.upper(dragon.element), dragon.name, stageNames[dragon.stage], dragon.level, dragon.coins)
    display.setCursorPos(math.max(1, math.floor((screenW - #titleStr) / 2)), 1)
    display.write(titleStr)
    
    -- Top Tabs: [ SANCTUARY ] [ MINIGAME ] [ SHOP ]
    local tabY = 2
    registerButton("TAB_MAIN", 2, tabY, 13, 1, "[ SANCTUARY ]", (activeTab == "MAIN") and "yellow" or "white", (activeTab == "MAIN") and "blue" or "gray")
    registerButton("TAB_MINI", 16, tabY, 13, 1, "[ MINIGAME ]", (activeTab == "MINIGAME") and "yellow" or "white", (activeTab == "MINIGAME") and "blue" or "gray")
    registerButton("TAB_SHOP", 30, tabY, 10, 1, "[ SHOP ]", (activeTab == "SHOP") and "yellow" or "white", (activeTab == "SHOP") and "blue" or "gray")
    
    if activeTab == "MAIN" then
        -- 2. Left Side: Dragon Avatar Sanctuary Enclosure
        local midX = math.floor(screenW * 0.28)
        local midY = math.floor(screenH * 0.45)
        
        -- Cavern / Sky Backdrop Frame
        display.setTextColor(colors.gray)
        for cy = 4, screenH - 5 do
            display.setCursorPos(2, cy)
            display.write("|")
            display.setCursorPos(math.floor(screenW * 0.52), cy)
            display.write("|")
        end
        display.setCursorPos(2, 4)
        display.write("+" .. string.rep("=", math.floor(screenW * 0.52) - 3) .. "+")
        display.setCursorPos(2, screenH - 5)
        display.write("+" .. string.rep("=", math.floor(screenW * 0.52) - 3) .. "+")
        
        drawDragon(midX, midY)
        
        -- 3. Right Side: Vital Needs Stat Bars
        local barX = math.floor(screenW * 0.55)
        display.setCursorPos(barX, 4)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" [ DRAGON VITALS & STATS ] ")
        
        -- XP Bar
        drawStatBar(barX, 6, "LEVEL XP", math.floor((dragon.xp / dragon.maxXp) * 100), 100, "magenta")
        if dragon.stage == 1 then
            drawStatBar(barX, 8, "EGG WARMTH", dragon.eggWarmth, 100, "orange")
        else
            drawStatBar(barX, 8, "HUNGER", dragon.hunger, 100, "brown")
            drawStatBar(barX, 10, "ENERGY", dragon.energy, 100, "lightBlue")
            drawStatBar(barX, 12, "HAPPINESS", dragon.happiness, 100, "yellow")
            drawStatBar(barX, 14, "CLEANLINESS", dragon.hygiene, 100, "cyan")
            drawStatBar(barX, 16, "FIRE POWER", dragon.firePower, 100, "red")
        end
        
        -- 4. Bottom Action Message Status Box
        display.setCursorPos(2, screenH - 4)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW - 2))
        display.setCursorPos(4, screenH - 4)
        display.write("LOG: " .. string.sub(dragon.lastActionMsg, 1, screenW - 8))
        
        -- 5. Bottom Interactive Care Action Buttons (Centered)
        local btnY = screenH - 2
        local bW = 12
        local gap = 2
        local startBx = math.max(2, math.floor((screenW - (bW * 5 + gap * 4)) / 2))
        
        registerButton("ACT_FEED", startBx, btnY, bW, 2, " [ 1: FEED ] ", "white", "brown")
        registerButton("ACT_PET", startBx + (bW + gap), btnY, bW, 2, " [ 2: PET ] ", "yellow", "blue")
        registerButton("ACT_CLEAN", startBx + (bW + gap) * 2, btnY, bW, 2, " [ 3: CLEAN ] ", "white", "cyan")
        registerButton("ACT_SLEEP", startBx + (bW + gap) * 3, btnY, bW, 2, dragon.isSleeping and "[ 4: WAKE ]" or "[ 4: SLEEP ]", "white", dragon.isSleeping and "lime" or "purple")
        registerButton("ACT_ROAR", startBx + (bW + gap) * 4, btnY, bW, 2, " [ 5: ROAR ] ", "yellow", "red")
        
    elseif activeTab == "MINIGAME" then
        -- FIRE TARGET SHOOTING MINI-GAME
        display.setCursorPos(3, 4)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(" [ MINI-GAME: TARGET FIRE BREATH ]   SCORE: " .. minigame.score .. " PTS   TIME: " .. minigame.timeLeft .. "s ")
        
        -- Shooting Range
        local midY = math.floor(screenH * 0.5)
        display.setCursorPos(4, midY)
        display.setTextColor(colors.purple)
        display.write("DRAGON [>>>]")
        
        -- Target Monster moving up/down or left/right
        local targetX = math.floor(screenW * 0.75)
        local targetY = 6 + (math.floor(animTick / 2) % (screenH - 12))
        display.setCursorPos(targetX, targetY)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.yellow)
        display.write(" [ TARGET ] ")
        
        -- Fireball
        if minigame.fireballX > 0 then
            display.setCursorPos(minigame.fireballX, midY)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.orange)
            display.write("==*=>")
            
            -- Hit check
            if math.abs(minigame.fireballX - targetX) < 4 and math.abs(midY - targetY) < 2 then
                minigame.score = minigame.score + 100
                dragon.coins = dragon.coins + 15
                addXP(20)
                playSound("coin")
                minigame.fireballX = -1
                setStatus("DIRECT HIT! +100 PTS, +15 Gold Coins!", "coin")
            end
        end
        
        registerButton("MINI_SHOOT", math.floor(screenW / 2) - 10, screenH - 3, 20, 2, " [ SHOOT FIRE (SPACE) ] ", "yellow", "red")
        
    elseif activeTab == "SHOP" then
        -- SANCTUARY SHOP
        display.setCursorPos(3, 4)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(" [ SANCTUARY SHOP - GOLD: " .. dragon.coins .. " G ] ")
        
        local shopItems = {
            { id = "BUY_MEAT", name = "Prime Roast Meat (+30 Hunger)", cost = 15, fn = function() dragon.hunger = 100; dragon.coins = dragon.coins - 15; setStatus("Bought Prime Roast Meat!", "feed") end },
            { id = "BUY_POTION", name = "Energy Elixir (+100 Energy)", cost = 25, fn = function() dragon.energy = 100; dragon.coins = dragon.coins - 25; setStatus("Drank Energy Elixir!", "powerup") end },
            { id = "BUY_XP", name = "Dragon Magic Tome (+50 XP)", cost = 40, fn = function() addXP(50); dragon.coins = dragon.coins - 40; setStatus("Read Dragon Magic Tome!", "evolve") end },
            { id = "BUY_SCALES", name = "Golden Scale Polish (+Clean & Power)", cost = 30, fn = function() dragon.hygiene = 100; dragon.firePower = 100; dragon.coins = dragon.coins - 30; setStatus("Polished with Golden Wax!", "clean") end }
        }
        
        for idx, item in ipairs(shopItems) do
            local sy = 6 + (idx - 1) * 2
            display.setCursorPos(4, sy)
            display.setTextColor(colors.white)
            display.write(string.format("%d. %-38s (COST: %2d G) ", idx, item.name, item.cost))
            local canBuy = (dragon.coins >= item.cost)
            registerButton(item.id, screenW - 14, sy, 10, 1, "[ BUY ]", canBuy and "yellow" or "gray", canBuy and "blue" or "black")
        end
    end
    
    registerButton("BTN_QUIT", screenW - 6, 2, 5, 1, "[ Q ]", "white", "red")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.1) -- 10 FPS Game Loop
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.1)
            animTick = animTick + 1
            
            -- Passive needs depletion (slow)
            if animTick % 100 == 0 then
                if not dragon.isSleeping then
                    dragon.hunger = math.max(0, dragon.hunger - 1)
                    dragon.energy = math.max(0, dragon.energy - 1)
                    dragon.hygiene = math.max(0, dragon.hygiene - 1)
                    if dragon.hunger < 20 or dragon.hygiene < 20 then
                        dragon.happiness = math.max(0, dragon.happiness - 2)
                    end
                else
                    dragon.energy = math.min(100, dragon.energy + 2)
                end
                saveGame()
            end
            
            -- Minigame fireball update
            if activeTab == "MINIGAME" and minigame.fireballX > 0 then
                minigame.fireballX = minigame.fireballX + 2
                local screenW, _ = display.getSize()
                if minigame.fireballX > screenW then minigame.fireballX = -1 end
            end
            
            renderSanctuary()
            
        elseif event == "key" then
            if p1 == keys.one then actionFeed()
            elseif p1 == keys.two then actionPet()
            elseif p1 == keys.three then actionClean()
            elseif p1 == keys.four then actionSleep()
            elseif p1 == keys.five then actionRoar()
            elseif p1 == keys.space and activeTab == "MINIGAME" then
                minigame.fireballX = 18
                playSound("fire")
            elseif p1 == keys.q or p1 == keys.escape then
                saveGame()
                break
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "TAB_MAIN" then activeTab = "MAIN"
            elseif cid == "TAB_MINI" then activeTab = "MINIGAME"
            elseif cid == "TAB_SHOP" then activeTab = "SHOP"
            elseif cid == "ACT_FEED" then actionFeed()
            elseif cid == "ACT_PET" then actionPet()
            elseif cid == "ACT_CLEAN" then actionClean()
            elseif cid == "ACT_SLEEP" then actionSleep()
            elseif cid == "ACT_ROAR" then actionRoar()
            elseif cid == "MINI_SHOOT" then
                minigame.fireballX = 18
                playSound("fire")
            elseif cid == "BUY_MEAT" and dragon.coins >= 15 then
                dragon.hunger = 100; dragon.coins = dragon.coins - 15; setStatus("Bought Prime Roast Meat!", "feed")
            elseif cid == "BUY_POTION" and dragon.coins >= 25 then
                dragon.energy = 100; dragon.coins = dragon.coins - 25; setStatus("Drank Energy Elixir!", "evolve")
            elseif cid == "BUY_XP" and dragon.coins >= 40 then
                addXP(50); dragon.coins = dragon.coins - 40; setStatus("Read Dragon Magic Tome!", "evolve")
            elseif cid == "BUY_SCALES" and dragon.coins >= 30 then
                dragon.hygiene = 100; dragon.firePower = 100; dragon.coins = dragon.coins - 30; setStatus("Polished with Golden Wax!", "clean")
            elseif cid == "BTN_QUIT" then
                saveGame()
                break
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Dragon Sanctuary saved and closed.")
    else
        print("Dragon Sanctuary saved and closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Dragon Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Dragon Error: " .. tostring(err))
end
