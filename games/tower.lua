-- ============================================================================
-- CYBER TOWER DEFENSE 2077 PRO - MULTI-LEVEL & DECORATED ARENA EDITION
-- 3 Mission Maps, Smooth Rounded Turns, Cyber Decor, Boss Fights & Synth Audio
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
    [colors.orange]    = 0xFF8C00, -- Missile Turret
    [colors.magenta]   = 0xE91E63, -- Laser Cannon
    [colors.lightBlue] = 0x00E5FF, -- Cryo Freeze Turret
    [colors.yellow]    = 0xFFEB3B, -- Gatling Gun / Credits
    [colors.lime]      = 0x00E676, -- Base Core Health
    [colors.pink]      = 0xFF80AB,
    [colors.gray]      = 0x1E222D, -- Grid Terrain Base
    [colors.lightGray] = 0x37474F, -- Wide Road Asphalt
    [colors.cyan]      = 0x18FFFF, -- Direction Arrows / Conduits
    [colors.purple]    = 0x7B1FA2,
    [colors.blue]      = 0x0D1B3E, -- Header Bar
    [colors.brown]     = 0x4E342E,
    [colors.green]     = 0x1B4332, -- Power Generators
    [colors.red]       = 0xFF1744, -- Enemies & Bosses
    [colors.black]     = 0x080B11
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
        if snd == "place" then
            speaker.playNote("snare", 0.6, 18)
        elseif snd == "shoot_gatling" then
            speaker.playNote("snare", 0.3, 22)
        elseif snd == "shoot_laser" then
            speaker.playNote("chime", 0.4, 24)
        elseif snd == "shoot_missile" then
            speaker.playNote("bass", 0.7, 12)
        elseif snd == "enemy_hit" then
            speaker.playNote("bass", 0.4, 6)
        elseif snd == "kill" then
            speaker.playNote("bell", 0.6, 20)
            speaker.playNote("chime", 0.6, 24)
        elseif snd == "wave_win" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.7, p)
                sleep(0.04)
            end
        elseif snd == "core_hit" then
            speaker.playNote("bass", 1.0, 4)
        end
    end)
end

-- ============================================================================
-- ============================================================================
-- ENEMY MOB CLASSES & STATS (SIGNIFICANTLY BOOSTED HP & VARIETY)
-- ============================================================================
local ENEMY_CLASSES = {
    [1] = { name = "SCOUT", tag = "SCOUT", icon = "<o>", col = "orange", baseHp = 65, perWave = 28, speed = 1.15, reward = 7 },
    [2] = { name = "TROOPER", tag = "TROOPER", icon = "<[#]>", col = "yellow", baseHp = 120, perWave = 48, speed = 0.75, reward = 10 },
    [3] = { name = "HEAVY TANK", tag = "TANK", icon = "[#TANK#]", col = "lightGray", baseHp = 280, perWave = 95, speed = 0.45, reward = 18, armor = 0.25 },
    [4] = { name = "STEALTH MECH", tag = "STEALTH", icon = "~|#|~", col = "cyan", baseHp = 160, perWave = 65, speed = 0.95, reward = 15, isFast = true },
    [5] = { name = "MEGA TITAN", tag = "BOSS", icon = "[#TITAN-X#]", col = "magenta", baseHp = 750, perWave = 350, speed = 0.35, reward = 100, isBoss = true }
}

-- TURRET TYPES DATA
-- ============================================================================
local TURRET_TYPES = {
    [1] = {
        name = "GATLING", tag = "GATLING", icon = "[G]", col = "yellow",
        cost = 100, dmg = 14, range = 7.5, fireRate = 2, desc = "Rapid Vulcan bullets"
    },
    [2] = {
        name = "LASER", tag = "LASER", icon = "[L]", col = "magenta",
        cost = 175, dmg = 28, range = 9.0, fireRate = 4, desc = "Pierce beam cannon"
    },
    [3] = {
        name = "MISSILE", tag = "MISSILE", icon = "[M]", col = "orange",
        cost = 250, dmg = 65, range = 11.5, fireRate = 10, desc = "AoE rocket silo"
    },
    [4] = {
        name = "CRYO", tag = "CRYO", icon = "[F]", col = "lightBlue",
        cost = 150, dmg = 8, range = 7.0, fireRate = 3, slow = 0.5, desc = "Slows target 50%"
    }
}

-- Map Levels / Sectors
local MAP_SECTORS = {
    [1] = { name = "SECTOR ALPHA: NEON VALLEY", desc = "Classic S-Curve Highway" },
    [2] = { name = "SECTOR BETA: SPIRAL CORE", desc = "Central Vortex Chokepoints" },
    [3] = { name = "SECTOR GAMMA: CYBER ZIGZAG", desc = "High-Intensity Multi-Pass" }
}
local currentMapIdx = 1

-- Game State Variables
local gameState = "TITLE" -- "TITLE", "BUILDING", "WAVE_ACTIVE", "VICTORY", "GAMEOVER"
local cash = 220
local score = 0
local coreHP = 20
local maxCoreHP = 20
local currentWave = 1
local maxWaves = 15

local selectedTurretType = 1
local selectedTurretOnMap = nil
local waveInProgress = false
local waveEnemiesToSpawn = 0
local spawnDelay = 0

-- Dynamic Map & Waypoints
local waypoints = {}
local pathCells = {}
local decors = {}
local turrets = {}
local enemies = {}
local bullets = {}
local laserBeams = {}
local explosions = {}
local deathEffects = {}
local tracerBullets = {}

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
-- DYNAMIC SMOOTHED PATH GENERATOR (Rounded Turns & 3 Map Layouts)
-- ============================================================================
local function initPath()
    local screenW, screenH = display.getSize()
    pathCells = {}
    decors = {}
    
    local topY = 3
    local botY = screenH - 3
    local arenaH = botY - topY
    
    if currentMapIdx == 1 then
        -- Map 1: Smooth S-Curve
        local y1 = topY + 1
        local y2 = topY + math.floor(arenaH * 0.35)
        local y3 = topY + math.floor(arenaH * 0.70)
        local y4 = botY - 1
        
        waypoints = {
            { x = 3, y = y1 },
            { x = math.floor(screenW * 0.35), y = y1 },
            { x = math.floor(screenW * 0.35), y = y2 },
            { x = math.floor(screenW * 0.70), y = y2 },
            { x = math.floor(screenW * 0.70), y = y1 },
            { x = screenW - 4, y = y1 },
            { x = screenW - 4, y = y3 },
            { x = math.floor(screenW * 0.35), y = y3 },
            { x = math.floor(screenW * 0.35), y = y4 },
            { x = 3, y = y4 }
        }
    elseif currentMapIdx == 2 then
        -- Map 2: Spiral Vortex
        local y1 = topY + 1
        local y2 = botY - 1
        local y3 = topY + math.floor(arenaH * 0.5)
        
        waypoints = {
            { x = 3, y = y1 },
            { x = screenW - 4, y = y1 },
            { x = screenW - 4, y = y2 },
            { x = math.floor(screenW * 0.22), y = y2 },
            { x = math.floor(screenW * 0.22), y = y3 },
            { x = math.floor(screenW * 0.65), y = y3 }
        }
    else
        -- Map 3: Cyber ZigZag
        local y1 = topY + 1
        local y2 = topY + math.floor(arenaH * 0.33)
        local y3 = topY + math.floor(arenaH * 0.66)
        local y4 = botY - 1
        
        waypoints = {
            { x = 3, y = y1 },
            { x = screenW - 4, y = y1 },
            { x = screenW - 4, y = y2 },
            { x = 3, y = y2 },
            { x = 3, y = y3 },
            { x = screenW - 4, y = y3 },
            { x = screenW - 4, y = y4 },
            { x = 3, y = y4 }
        }
    end
    
    -- Draw 2-Cell Wide Smooth Corridors
    for i = 1, #waypoints - 1 do
        local wp1 = waypoints[i]
        local wp2 = waypoints[i + 1]
        
        local minX = math.min(wp1.x, wp2.x)
        local maxX = math.max(wp1.x, wp2.x)
        local minY = math.min(wp1.y, wp2.y)
        local maxY = math.max(wp1.y, wp2.y)
        
        for y = minY, maxY do
            for x = minX, maxX do
                for dy = 0, 1 do
                    for dx = 0, 1 do
                        local cx = x + dx
                        local cy = y + dy
                        if cy >= 2 and cy <= botY and cx >= 1 and cx <= screenW then
                            pathCells[cy .. "_" .. cx] = true
                        end
                    end
                end
            end
        end
    end
    
    -- Add Sci-Fi Base Decor (Power generators & Shield Conduits on empty spots)
    local decorCandidates = {
        { x = math.floor(screenW * 0.20), y = math.floor(arenaH * 0.25) + topY, type = "GEN" },
        { x = math.floor(screenW * 0.50), y = math.floor(arenaH * 0.50) + topY, type = "PYLON" },
        { x = math.floor(screenW * 0.82), y = math.floor(arenaH * 0.75) + topY, type = "RADAR" }
    }
    
    for _, d in ipairs(decorCandidates) do
        if not pathCells[d.y .. "_" .. d.x] and not pathCells[d.y .. "_" .. (d.x + 1)] then
            table.insert(decors, d)
        end
    end
end

local function initGame()
    cash = 220
    score = 0
    coreHP = 20
    currentWave = 1
    selectedTurretType = 1
    selectedTurretOnMap = nil
    waveInProgress = false
    waveEnemiesToSpawn = 0
    turrets = {}
    enemies = {}
    bullets = {}
    laserBeams = {}
    explosions = {}
    deathEffects = {}
    tracerBullets = {}
    initPath()
    gameState = "BUILDING"
end

-- ============================================================================
-- SPAWN WAVE
-- ============================================================================
local function startWave()
    if waveInProgress then return end
    waveInProgress = true
    gameState = "WAVE_ACTIVE"
    selectedTurretOnMap = nil
    waveEnemiesToSpawn = 6 + currentWave * 2
    spawnDelay = 0
    playSound("place")
end

local function spawnEnemy()
    local isBossWave = (currentWave % 5 == 0 and waveEnemiesToSpawn == 1)
    local mobClass = nil
    
    if isBossWave then
        mobClass = ENEMY_CLASSES[5] -- Mega Titan Boss
    else
        -- Unlock new enemy types as waves advance
        local maxPool = 2
        if currentWave >= 3 then maxPool = 3 end
        if currentWave >= 6 then maxPool = 4 end
        mobClass = ENEMY_CLASSES[math.random(1, maxPool)]
    end
    
    local hp = mobClass.baseHp + currentWave * mobClass.perWave
    local spd = mobClass.speed * (0.9 + math.random() * 0.2)
    local rew = mobClass.reward + math.floor(currentWave * 1.5)
    
    table.insert(enemies, {
        x = waypoints[1].x,
        y = waypoints[1].y,
        wpIdx = 1,
        hp = hp,
        maxHp = hp,
        speed = spd,
        baseSpeed = spd,
        armor = mobClass.armor or 0,
        isBoss = mobClass.isBoss or false,
        classData = mobClass,
        reward = rew,
        col = mobClass.col
    })
end

-- ============================================================================
-- TURRET PLACEMENT & UPGRADE
-- ============================================================================
local function placeTurret(gridX, gridY)
    local screenW, screenH = display.getSize()
    local botY = screenH - 3
    if gridX < 2 or gridX > screenW - 2 or gridY < 2 or gridY > botY then return end
    
    -- Check if clicking existing turret to select/upgrade
    for _, t in ipairs(turrets) do
        if math.abs(t.x - gridX) < 2 and math.abs(t.y - gridY) < 2 then
            selectedTurretOnMap = t
            return
        end
    end
    
    -- Cannot place on road
    if pathCells[gridY .. "_" .. gridX] then
        selectedTurretOnMap = nil
        return
    end
    
    local tType = TURRET_TYPES[selectedTurretType]
    if cash >= tType.cost then
        cash = cash - tType.cost
        table.insert(turrets, {
            x = gridX,
            y = gridY,
            type = tType,
            lvl = 1,
            cooldown = 0,
            kills = 0
        })
        selectedTurretOnMap = turrets[#turrets]
        playSound("place")
    end
end

local function upgradeSelectedTurret()
    if not selectedTurretOnMap or selectedTurretOnMap.lvl >= 3 then return end
    local upCost = math.floor(selectedTurretOnMap.type.cost * 0.8 * selectedTurretOnMap.lvl)
    if cash >= upCost then
        cash = cash - upCost
        selectedTurretOnMap.lvl = selectedTurretOnMap.lvl + 1
        playSound("wave_win")
    end
end

local function sellSelectedTurret()
    if not selectedTurretOnMap then return end
    local refund = math.floor(selectedTurretOnMap.type.cost * 0.7 * selectedTurretOnMap.lvl)
    cash = cash + refund
    for i, t in ipairs(turrets) do
        if t == selectedTurretOnMap then
            table.remove(turrets, i)
            break
        end
    end
    selectedTurretOnMap = nil
    playSound("place")
end

-- ============================================================================
-- PHYSICS & COMBAT UPDATE LOOP
-- ============================================================================
local function updateGame()
    if gameState ~= "WAVE_ACTIVE" and gameState ~= "BUILDING" then return end
    
    laserBeams = {}
    
    -- 1. Wave Spawner
    if waveInProgress and waveEnemiesToSpawn > 0 then
        spawnDelay = spawnDelay - 1
        if spawnDelay <= 0 then
            spawnDelay = 8
            waveEnemiesToSpawn = waveEnemiesToSpawn - 1
            spawnEnemy()
        end
    end
    
    -- 2. Update Enemies Pathfinding
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local targetWp = waypoints[e.wpIdx + 1]
        
        if targetWp then
            local dx = targetWp.x - e.x
            local dy = targetWp.y - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < 0.6 then
                e.wpIdx = e.wpIdx + 1
            else
                e.x = e.x + (dx / dist) * (e.speed * 0.35)
                e.y = e.y + (dy / dist) * (e.speed * 0.35)
            end
        else
            -- Reached Core Base!
            coreHP = coreHP - (e.isBoss and 5 or 1)
            table.remove(enemies, i)
            playSound("core_hit")
            
            if coreHP <= 0 then
                coreHP = 0
                gameState = "GAMEOVER"
                return
            end
        end
    end
    
    -- 3. Update Turrets Targeting & Firing
    for _, t in ipairs(turrets) do
        t.cooldown = math.max(0, t.cooldown - 1)
        local effRange = t.type.range + (t.lvl - 1) * 2.0
        local effDmg = t.type.dmg * (1 + (t.lvl - 1) * 0.75)
        
        if t.cooldown <= 0 then
            local bestTarget = nil
            local bestDist = 999
            for _, e in ipairs(enemies) do
                local dist = math.sqrt((e.x - t.x)^2 + (e.y - t.y)^2)
                if dist <= effRange and dist < bestDist then
                    bestDist = dist
                    bestTarget = e
                end
            end
            
            if bestTarget then
                t.cooldown = t.type.fireRate
                
                if t.type.tag == "GATLING" then
                    local finalDmg = effDmg * (1 - (bestTarget.armor or 0)); bestTarget.hp = bestTarget.hp - finalDmg
                    table.insert(tracerBullets, {
                        x = t.x, y = t.y, tx = bestTarget.x, ty = bestTarget.y, timer = 3, col = "yellow"
                    })
                    playSound("shoot_gatling")
                elseif t.type.tag == "LASER" then
                    local finalDmg = effDmg * (1 - (bestTarget.armor or 0)); bestTarget.hp = bestTarget.hp - finalDmg
                    table.insert(laserBeams, { x1 = t.x, y1 = t.y, x2 = bestTarget.x, y2 = bestTarget.y, col = t.type.col })
                    playSound("shoot_laser")
                elseif t.type.tag == "MISSILE" then
                    table.insert(bullets, {
                        x = t.x, y = t.y, target = bestTarget, dmg = effDmg,
                        speed = 1.4, splash = 3.5, trail = {}
                    })
                    playSound("shoot_missile")
                elseif t.type.tag == "CRYO" then
                    local finalDmg = effDmg * (1 - (bestTarget.armor or 0)); bestTarget.hp = bestTarget.hp - finalDmg
                    bestTarget.speed = bestTarget.baseSpeed * (t.type.slow or 0.5)
                    table.insert(laserBeams, { x1 = t.x, y1 = t.y, x2 = bestTarget.x, y2 = bestTarget.y, col = "cyan" })
                    playSound("shoot_laser")
                end
            end
        end
    end
    
    -- 4. Update Missiles & Splash Damage
    for bIdx = #bullets, 1, -1 do
        local b = bullets[bIdx]
        local tx = b.target.x or b.x
        local ty = b.target.y or b.y
        local dx = tx - b.x
        local dy = ty - b.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 1.2 then
            for _, e in ipairs(enemies) do
                local splashDist = math.sqrt((e.x - b.x)^2 + (e.y - b.y)^2)
                if splashDist <= b.splash then
                    e.hp = e.hp - b.dmg * (1 - (splashDist / b.splash) * 0.5)
                end
            end
            table.insert(explosions, { x = b.x, y = b.y, timer = 4 })
            table.remove(bullets, bIdx)
            playSound("enemy_hit")
        else
            b.x = b.x + (dx / dist) * b.speed
            b.y = b.y + (dy / dist) * b.speed
        end
    end
    
    -- 5. Update Tracers & Death Effects
    for i = #tracerBullets, 1, -1 do
        local tr = tracerBullets[i]
        tr.timer = tr.timer - 1
        if tr.timer <= 0 then table.remove(tracerBullets, i) end
    end
    
    for i = #explosions, 1, -1 do
        local ex = explosions[i]
        ex.timer = ex.timer - 1
        if ex.timer <= 0 then table.remove(explosions, i) end
    end
    
    for i = #deathEffects, 1, -1 do
        local df = deathEffects[i]
        df.timer = df.timer - 1
        df.y = df.y - 0.2 -- Floating upward
        if df.timer <= 0 then table.remove(deathEffects, i) end
    end
    
    -- 6. Clean Defeated Enemies with Explosions
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if e.hp <= 0 then
            cash = cash + e.reward
            score = score + e.reward * 10
            table.insert(deathEffects, {
                x = e.x, y = e.y, timer = 6, reward = e.reward, isBoss = e.isBoss
            })
            table.remove(enemies, i)
            playSound("kill")
        end
    end
    
    -- Check if Wave Completed
    if waveInProgress and waveEnemiesToSpawn == 0 and #enemies == 0 then
        waveInProgress = false
        gameState = "BUILDING"
        cash = cash + 25 + currentWave * 8
        playSound("wave_win")
        
        if currentWave >= maxWaves then
            gameState = "VICTORY"
        else
            currentWave = currentWave + 1
        end
    end
end

-- ============================================================================
-- FULL-SCREEN DECORATED RENDERER
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local arenaBottom = screenH - 3
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top HUD Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" [M%d] WAVE:%d/%d  CASH:$%-3d  CORE:[%d/%d]  SCORE:%06d ", 
        currentMapIdx, currentWave, maxWaves, cash, coreHP, maxCoreHP, score)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.write(hud)
    
    -- 2. Tactical Battlefield Grid & Rounded Roads (Lines 2 to arenaBottom)
    for y = 2, arenaBottom do
        display.setCursorPos(1, y)
        for x = 1, screenW do
            if pathCells[y .. "_" .. x] then
                display.setBackgroundColor(colors.lightGray)
                if (x + y) % 6 == 0 then
                    display.setTextColor(colors.cyan)
                    display.write(">")
                else
                    display.setTextColor(colors.gray)
                    display.write(".")
                end
            else
                display.setBackgroundColor(colors.gray)
                if (x % 4 == 0 and y % 2 == 0) then
                    display.setTextColor(colors.black)
                    display.write("+")
                else
                    display.write(" ")
                end
            end
        end
    end
    
    -- 3. Render Sci-Fi Base Decor (Power Generators, Pylons & Radars)
    for _, d in ipairs(decors) do
        display.setCursorPos(d.x, d.y)
        if d.type == "GEN" then
            display.setBackgroundColor(colors.green)
            display.setTextColor(colors.lime)
            display.write("[GEN]")
        elseif d.type == "PYLON" then
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.cyan)
            display.write("<|#|>")
        else
            display.setBackgroundColor(colors.purple)
            display.setTextColor(colors.yellow)
            display.write("(RAD)")
        end
    end
    
    -- Spawn & Core Base Markers
    if #waypoints > 0 then
        local spWp = waypoints[1]
        display.setCursorPos(math.max(1, spWp.x - 2), spWp.y)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write("[SPAWN]")
        
        local coreWp = waypoints[#waypoints]
        display.setCursorPos(math.max(1, coreWp.x - 2), coreWp.y)
        display.setBackgroundColor(colors.lime)
        display.setTextColor(colors.black)
        display.write("[CORE]")
    end
    
    -- 4. Range Indicator for Selected Turret
    if selectedTurretOnMap then
        local t = selectedTurretOnMap
        local effRange = t.type.range + (t.lvl - 1) * 2.0
        for ang = 0, 360, 20 do
            local rad = math.rad(ang)
            local rx = math.floor(t.x + math.cos(rad) * effRange)
            local ry = math.floor(t.y + math.sin(rad) * (effRange * 0.5))
            if ry >= 2 and ry <= arenaBottom and rx >= 1 and rx <= screenW then
                display.setCursorPos(rx, ry)
                display.setBackgroundColor(colors.gray)
                display.setTextColor(colors.yellow)
                display.write("*")
            end
        end
    end
    
    -- 5. Laser Beams
    for _, l in ipairs(laserBeams) do
        local steps = 8
        for s = 0, steps do
            local lx = math.floor(l.x1 + (l.x2 - l.x1) * (s / steps))
            local ly = math.floor(l.y1 + (l.y2 - l.y1) * (s / steps))
            if ly >= 2 and ly <= arenaBottom and lx >= 1 and lx <= screenW then
                display.setCursorPos(lx, ly)
                display.setBackgroundColor(colors[l.col] or colors.magenta)
                display.setTextColor(colors.white)
                display.write("=")
            end
        end
    end
    
    -- 6. Bullets
    for _, b in ipairs(bullets) do
        display.setCursorPos(math.floor(b.x), math.floor(b.y))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.orange)
        display.write("*")
    end
    
    -- 7. Turrets
    for _, t in ipairs(turrets) do
        display.setCursorPos(math.max(1, t.x - 1), t.y)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors[t.type.col])
        display.write(t.type.icon)
        
        display.setCursorPos(math.max(1, t.x + 1), t.y - 1)
        display.setTextColor(colors.yellow)
        display.write("L" .. t.lvl)
    end
    
    -- 6. Render Explosions & Death Effects
    for _, ex in ipairs(explosions) do
        if ex.y >= 2 and ex.y <= arenaBottom and ex.x >= 1 and ex.x <= screenW then
            display.setCursorPos(math.max(1, math.floor(ex.x) - 2), math.floor(ex.y))
            display.setBackgroundColor(colors.orange)
            display.setTextColor(colors.white)
            if ex.timer > 2 then
                display.write("(*#*)")
            else
                display.write(" ... ")
            end
        end
    end
    
    for _, df in ipairs(deathEffects) do
        local dy = math.floor(df.y)
        local dx = math.floor(df.x)
        if dy >= 2 and dy <= arenaBottom and dx >= 1 and dx <= screenW then
            if df.timer > 3 then
                -- Death Explosion Flash
                display.setCursorPos(math.max(1, dx - 2), dy)
                display.setBackgroundColor(colors.red)
                display.setTextColor(colors.yellow)
                display.write(df.isBoss and "[*BOOM*]" or "[*X*]")
            else
                -- Floating Cash Reward
                display.setCursorPos(math.max(1, dx - 2), dy)
                display.setBackgroundColor(colors.black)
                display.setTextColor(colors.lime)
                display.write(string.format("+$%d", df.reward))
            end
        end
    end
    
    -- 7. Render Tracer Bullets
    for _, tr in ipairs(tracerBullets) do
        local midX = math.floor((tr.x + tr.tx) / 2)
        local midY = math.floor((tr.y + tr.ty) / 2)
        if midY >= 2 and midY <= arenaBottom and midX >= 1 and midX <= screenW then
            display.setCursorPos(midX, midY)
            display.setBackgroundColor(colors.gray)
            display.setTextColor(colors.yellow)
            display.write("*")
        end
    end
    
    -- 8. Render Diverse Enemies & Dynamic Multi-Bar Health Indicators
    for _, e in ipairs(enemies) do
        local ex = math.floor(e.x)
        local ey = math.floor(e.y)
        
        if ey >= 2 and ey <= arenaBottom and ex >= 1 and ex <= screenW then
            local icon = e.classData and e.classData.icon or "<O>"
            local halfLen = math.floor(#icon / 2)
            
            -- Enemy Body Sprite
            display.setCursorPos(math.max(1, ex - halfLen), ey)
            display.setBackgroundColor(colors.lightGray)
            display.setTextColor(colors[e.col] or colors.red)
            display.write(icon)
            
            -- Dynamic Health Bar Directly Above Enemy
            if ey > 2 then
                display.setCursorPos(math.max(1, ex - halfLen), ey - 1)
                display.setBackgroundColor(colors.black)
                local hpRatio = math.max(0, math.min(1, e.hp / e.maxHp))
                local barCol = (hpRatio > 0.6) and colors.lime or ((hpRatio > 0.3) and colors.yellow or colors.red)
                display.setTextColor(barCol)
                
                if e.isBoss then
                    local bars = math.max(1, math.floor(hpRatio * 7))
                    display.write("[" .. string.rep("=", bars) .. string.rep("-", 7 - bars) .. "]")
                else
                    local bars = math.max(1, math.floor(hpRatio * 3))
                    display.write("[" .. string.rep("#", bars) .. string.rep("-", 3 - bars) .. "]")
                end
            end
        end
    end
    
    -- 9. Dynamic Bottom Controls Bar (Lines screenH - 2 to screenH)
    local shopY = screenH - 2
    local btnW = math.max(7, math.floor(screenW / 6))
    
    registerButton("BTN_TUR_1", 2, shopY, btnW, 2, "[1:GAT]", (selectedTurretType == 1) and "yellow" or "white", (selectedTurretType == 1) and "blue" or "gray")
    registerButton("BTN_TUR_2", 2 + btnW + 1, shopY, btnW, 2, "[2:LAS]", (selectedTurretType == 2) and "magenta" or "white", (selectedTurretType == 2) and "purple" or "gray")
    registerButton("BTN_TUR_3", 2 + (btnW + 1) * 2, shopY, btnW, 2, "[3:MSL]", (selectedTurretType == 3) and "orange" or "white", (selectedTurretType == 3) and "brown" or "gray")
    registerButton("BTN_TUR_4", 2 + (btnW + 1) * 3, shopY, btnW, 2, "[4:CRY]", (selectedTurretType == 4) and "cyan" or "white", (selectedTurretType == 4) and "blue" or "gray")
    
    local startBtnX = 2 + (btnW + 1) * 4
    local startBtnW = math.max(12, screenW - startBtnX - 1)
    if not waveInProgress then
        registerButton("BTN_START_WAVE", startBtnX, shopY, startBtnW, 2, "[ > START ]", "yellow", "green")
    else
        registerButton("BTN_START_WAVE", startBtnX, shopY, startBtnW, 2, "[ COMBAT ]", "red", "gray")
    end
    
    -- Bottom Info Line (Line screenH)
    if selectedTurretOnMap then
        local t = selectedTurretOnMap
        local upCost = math.floor(t.type.cost * 0.8 * t.lvl)
        local refund = math.floor(t.type.cost * 0.7 * t.lvl)
        
        display.setCursorPos(2, screenH)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        display.setCursorPos(2, screenH)
        display.write(string.format("SELECTED: %s LVL%d  ", t.type.name, t.lvl))
        
        if t.lvl < 3 then
            registerButton("BTN_UPGRADE", 24, screenH, 14, 1, string.format("[UPGRADE:$%d]", upCost), (cash >= upCost) and "yellow" or "lightGray", "blue")
        else
            registerButton("BTN_UPGRADE", 24, screenH, 14, 1, "[MAX LEVEL 3]", "lightGray", "gray")
        end
        registerButton("BTN_SELL", 40, screenH, 12, 1, string.format("[SELL:+$%d]", refund), "red", "gray")
    else
        local selT = TURRET_TYPES[selectedTurretType]
        display.setCursorPos(2, screenH)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        display.setCursorPos(2, screenH)
        display.write(string.format("%s ($%d): %s | Tap grid to place", selT.name, selT.cost, selT.desc))
    end
    
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- Game Over / Victory Overlay
    if gameState == "GAMEOVER" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 16, midY - 3)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 2)
        display.write("     CORE DESTROYED / DEFEAT!     ")
        display.setCursorPos(midX - 16, midY - 1)
        display.write(string.format("  SURVIVED WAVES: %d | SCORE: %06d ", currentWave, score))
        display.setCursorPos(midX - 16, midY)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 16, midY + 2, 32, 2, " [ TRY AGAIN (TAP) ] ", "yellow", "blue")
        
    elseif gameState == "VICTORY" then
        local midX = math.floor(screenW / 2)
        local midY = math.floor(screenH / 2)
        display.setCursorPos(midX - 16, midY - 3)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.blue)
        display.write(" ================================ ")
        display.setCursorPos(midX - 16, midY - 2)
        display.write("   *** SECTOR DEFENDED / WIN! *** ")
        display.setCursorPos(midX - 16, midY - 1)
        display.write(string.format("  FINAL SCORE: %06d | CASH: $%d  ", score, cash))
        display.setCursorPos(midX - 16, midY)
        display.write(" ================================ ")
        
        registerButton("BTN_RETRY", midX - 16, midY + 2, 32, 2, " [ NEW CAMPAIGN (TAP) ] ", "yellow", "green")
    end
    
    drawButtons()
end

-- ============================================================================
-- TITLE SCREEN WITH LEVEL / MAP SELECTOR
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
    display.write("     CYBER TOWER DEFENSE 2077 PRO     ")
    display.setCursorPos(midX - 18, titleY + 2)
    display.write(" ==================================== ")
    
    display.setCursorPos(midX - 18, titleY + 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write("  BUILD TURRETS & DEFEND THE CORE     ")
    
    -- Map Level Selector
    local mapData = MAP_SECTORS[currentMapIdx]
    display.setCursorPos(midX - 18, titleY + 6)
    display.setTextColor(colors.yellow)
    display.write("  SELECT MISSION MAP LEVEL:           ")
    
    registerButton("BTN_MAP_PREV", midX - 18, titleY + 8, 5, 2, "[ < ]", "yellow", "blue")
    display.setCursorPos(midX - 12, titleY + 8)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lime)
    display.write(string.format(" %-24s ", mapData.name))
    registerButton("BTN_MAP_NEXT", midX + 14, titleY + 8, 5, 2, "[ > ]", "yellow", "blue")
    
    display.setCursorPos(midX - 18, titleY + 11)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightGray)
    display.write("  " .. mapData.desc)
    
    registerButton("BTN_START", midX - 16, titleY + 13, 32, 2, " [ TAP / SPACE TO START MISSION ] ", "yellow", "green")
    
    drawButtons()
end

-- ============================================================================
-- MAIN GAME LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.1)
    
    while true do
        if gameState == "TITLE" then
            renderTitleScreen()
        else
            renderGame()
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.1)
            updateGame()
            
        elseif event == "key" then
            if gameState == "TITLE" then
                if p1 == keys.space or p1 == keys.enter then
                    initGame()
                elseif p1 == keys.left or p1 == keys.a then
                    currentMapIdx = (currentMapIdx == 1) and #MAP_SECTORS or (currentMapIdx - 1)
                elseif p1 == keys.right or p1 == keys.d then
                    currentMapIdx = (currentMapIdx == #MAP_SECTORS) and 1 or (currentMapIdx + 1)
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            else
                if p1 == keys.one then selectedTurretType = 1
                elseif p1 == keys.two then selectedTurretType = 2
                elseif p1 == keys.three then selectedTurretType = 3
                elseif p1 == keys.four then selectedTurretType = 4
                elseif p1 == keys.space then startWave()
                elseif p1 == keys.u then upgradeSelectedTurret()
                elseif p1 == keys.s then sellSelectedTurret()
                elseif p1 == keys.r then initGame()
                elseif p1 == keys.q or p1 == keys.escape then
                    break
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if gameState == "TITLE" then
                if cid == "BTN_MAP_PREV" then
                    currentMapIdx = (currentMapIdx == 1) and #MAP_SECTORS or (currentMapIdx - 1)
                elseif cid == "BTN_MAP_NEXT" then
                    currentMapIdx = (currentMapIdx == #MAP_SECTORS) and 1 or (currentMapIdx + 1)
                else
                    initGame()
                end
            else
                if cid == "BTN_RETRY" then
                    initGame()
                elseif cid == "BTN_TUR_1" then
                    selectedTurretType = 1
                elseif cid == "BTN_TUR_2" then
                    selectedTurretType = 2
                elseif cid == "BTN_TUR_3" then
                    selectedTurretType = 3
                elseif cid == "BTN_TUR_4" then
                    selectedTurretType = 4
                elseif cid == "BTN_START_WAVE" then
                    startWave()
                elseif cid == "BTN_UPGRADE" then
                    upgradeSelectedTurret()
                elseif cid == "BTN_SELL" then
                    sellSelectedTurret()
                elseif cid == "BTN_QUIT" then
                    break
                else
                    placeTurret(mx, my)
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Tower Defense closed.")
    else
        print("Tower Defense closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("TD Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("TD Error: " .. tostring(err))
end
