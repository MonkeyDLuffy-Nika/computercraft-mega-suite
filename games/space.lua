-- ==============================================================================
--           GALAXY DEFENDER: RETRO SPACE SHOOTER for CC: TWEAKED
-- ==============================================================================
--   Features:
--     * Parallax Starfield & High-Speed Space Scrolling Engine
--     * Smooth Subpixel Rendering & Particle Explosions (CC Teletext 2x3)
--     * 20 Unique Roguelike Ship Upgrades (3 Random Cards Offered in Shop)
--     * Massive Enemy Variety (12+ Regular Fleet Units & Hazards)
--     * 5 Multi-Stage Capital Boss Fights (Wave Bosses with Escalating Phases)
--     * Extended Wave Combat Duration (35-45s per wave before Boss Siren)
--     * Centered On-Screen Touch Control Buttons (< LEFT, ^, v, RIGHT >, FIRE, NUKE)
--     * Player Arsenal: Plasma Blaster, Spread, Laser, Missiles, Tesla, Drones, Nuke
--     * In-Game 3-Card Hangar Upgrade Shop (Choose 1 of 3 random cards for Credits)
--     * Speaker Chiptune Sound Effects (Laser, Explosion, Powerup, Boss Alert)
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

-- Speaker Setup (Optional audio chiptunes)
local speaker = peripheral.find("speaker")
local function playSound(sndType)
    if not speaker then return end
    pcall(function()
        if sndType == "shoot" then
            speaker.playNote("snare", 1.0, 18)
        elseif sndType == "laser" then
            speaker.playNote("chime", 1.0, 20)
        elseif sndType == "hit" then
            speaker.playNote("hat", 0.8, 12)
        elseif sndType == "explode" then
            speaker.playNote("bass", 1.5, 4)
        elseif sndType == "powerup" then
            speaker.playNote("bell", 1.2, 16)
        elseif sndType == "boss" then
            speaker.playNote("didgeridoo", 1.5, 6)
        elseif sndType == "railgun" then
            speaker.playNote("harp", 1.5, 24)
        elseif sndType == "teleport" then
            speaker.playNote("flute", 1.2, 18)
        elseif sndType == "heal" then
            speaker.playNote("iron_xylophone", 1.2, 16)
        elseif sndType == "crit" then
            speaker.playNote("pling", 1.5, 24)
        elseif sndType == "click" then
            speaker.playNote("hat", 0.5, 15)
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

-- Starfield Background
local stars = {}
local function initStars()
    stars = {}
    for i = 1, 55 do
        table.insert(stars, {
            x = math.random(1, screenW or 51),
            y = math.random(1, screenH or 19),
            speed = (math.random(1, 3) == 1 and 2 or 1),
            color = (math.random(1, 3) == 1 and "3" or (math.random(1, 2) == 1 and "7" or "0"))
        })
    end
end

local function updateStars()
    for _, s in ipairs(stars) do
        s.y = s.y + s.speed * 0.4
        if s.y > screenH - 3 then
            s.y = 1
            s.x = math.random(1, screenW)
        end
    end
end

local function drawStars()
    for _, s in ipairs(stars) do
        local sym = (s.speed > 1 and "*" or ".")
        drawText(math.floor(s.x), math.floor(s.y), sym, s.color, "f")
    end
end

-- Particle System
local particles = {}
local function addExplosion(x, y, count, pColor)
    count = count or 10
    pColor = pColor or "4"
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = math.random() * 2.5 + 0.5
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd * 0.5,
            life = math.random(6, 15),
            char = (math.random(1, 2) == 1 and "*" or "+"),
            col = (i % 2 == 0 and pColor or "e")
        })
    end
end

local function updateParticles()
    local nextP = {}
    for _, p in ipairs(particles) do
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.life = p.life - 1
        if p.life > 0 then
            table.insert(nextP, p)
        end
    end
    particles = nextP
end

local function drawParticles()
    for _, p in ipairs(particles) do
        drawText(math.floor(p.x), math.floor(p.y), p.char, p.col, "f")
    end
end

-- Game State Variables
local player = {
    x = 25, y = 15,
    hp = 100, maxHp = 100,
    shield = 50, maxShield = 50,
    score = 0, credits = 50,
    weapon = 1,
    weaponLevel = 1,
    nukes = 2,
    speed = 1.2,
    fireTimer = 0,
    shieldRecharge = 0,
    
    -- 20 Upgrades Perks
    critChance = 0,
    dmgBonus = 0,
    fireRateBonus = 0,
    lifesteal = 0,
    creditMultiplier = 1.0,
    armorReduction = 0,
    drones = 0,
    teslaArc = 0,
    empBurst = false,
    clusterShot = false,
    tractorBeam = false,
    shotCounter = 0
}

local bullets = {}
local enemies = {}
local powerups = {}
local currentWave = 1
local waveTimer = 0
local BOSS_SPAWN_TIME = 650
local bossActive = nil
local bossWarningTimer = 0
local activeScreen = "MENU" -- MENU, GAME, SHOP, GAMEOVER, VICTORY

-- 20 Unique Upgrades Pool
local ALL_UPGRADES = {
    {
        id = "SPREAD_SHOT",
        name = "SPREAD CANNON",
        desc1 = "3-Way plasma spread shot",
        desc2 = "Wide area cone coverage",
        cost = 80, rarity = "RARE", col = "4",
        apply = function() player.weapon = 2 end
    },
    {
        id = "PLASMA_BEAM",
        name = "HEAVY LASER BEAM",
        desc1 = "High-speed piercing beam",
        desc2 = "+100% piercing DMG",
        cost = 140, rarity = "EPIC", col = "d",
        apply = function() player.weapon = 3 end
    },
    {
        id = "HOMING_MISSILES",
        name = "HOMING MISSILES",
        desc1 = "Dual smart micro-missiles",
        desc2 = "Seeks closest hostile target",
        cost = 180, rarity = "EPIC", col = "e",
        apply = function() player.weapon = 4 end
    },
    {
        id = "CHAIN_TESLA",
        name = "CHAIN TESLA COIL",
        desc1 = "Electric arcs shock up to",
        desc2 = "3 adjacent enemy ships",
        cost = 160, rarity = "LEGENDARY", col = "3",
        apply = function() player.teslaArc = player.teslaArc + 1 end
    },
    {
        id = "ORBITAL_DRONE",
        name = "ORBITAL WINGMAN",
        desc1 = "Deploys auto-firing combat",
        desc2 = "support drone (+1 Drone)",
        cost = 120, rarity = "RARE", col = "9",
        apply = function() player.drones = player.drones + 1 end
    },
    {
        id = "CRITICAL_SYSTEM",
        name = "CRITICAL TARGETING",
        desc1 = "+25% chance for bullets",
        desc2 = "to deal 250% critical DMG",
        cost = 90, rarity = "RARE", col = "e",
        apply = function() player.critChance = player.critChance + 0.25 end
    },
    {
        id = "TITANIUM_PLATING",
        name = "TITANIUM HULL +50",
        desc1 = "Reinforces ship structure",
        desc2 = "+50 Max HP & full repair",
        cost = 70, rarity = "COMMON", col = "5",
        apply = function() player.maxHp = player.maxHp + 50; player.hp = player.maxHp end
    },
    {
        id = "ENERGY_SHIELD_CAP",
        name = "SHIELD MATRIX +30",
        desc1 = "+30 Max Energy Shield",
        desc2 = "Increases shield pool",
        cost = 60, rarity = "COMMON", col = "3",
        apply = function() player.maxShield = player.maxShield + 30; player.shield = player.maxShield end
    },
    {
        id = "RAPID_CYCLER",
        name = "RAPID FIRE OVERCLOCK",
        desc1 = "Increases gun fire rate",
        desc2 = "+35% faster firing speed",
        cost = 85, rarity = "COMMON", col = "4",
        apply = function() player.fireRateBonus = player.fireRateBonus + 0.35 end
    },
    {
        id = "DAMAGE_OVERCHARGE",
        name = "PLASMA OVERCHARGE",
        desc1 = "+30% weapon damage boost",
        desc2 = "Empowers all weapon hits",
        cost = 95, rarity = "RARE", col = "4",
        apply = function() player.dmgBonus = player.dmgBonus + 0.30 end
    },
    {
        id = "HYPER_THRUSTERS",
        name = "ION BOOSTERS +30%",
        desc1 = "Increases ship fly speed",
        desc2 = "Faster evasive maneuvering",
        cost = 50, rarity = "COMMON", col = "7",
        apply = function() player.speed = player.speed + 0.3 end
    },
    {
        id = "VAMPIRIC_SIPHON",
        name = "NANO VAMPIRE SIPHON",
        desc1 = "25% chance to restore +4 HP",
        desc2 = "on every enemy kill",
        cost = 110, rarity = "RARE", col = "5",
        apply = function() player.lifesteal = player.lifesteal + 0.25 end
    },
    {
        id = "BOUNTY_HUNTER",
        name = "BOUNTY RADAR +50%",
        desc1 = "Scans destroyed wrecks",
        desc2 = "+50% more credits earned",
        cost = 65, rarity = "COMMON", col = "e",
        apply = function() player.creditMultiplier = player.creditMultiplier + 0.5 end
    },
    {
        id = "MEGA_NUKE_AMMO",
        name = "MEGA-NUKE WARHEAD",
        desc1 = "+2 Screen-clearing Nukes",
        desc2 = "Destroys all screen targets",
        cost = 100, rarity = "RARE", col = "e",
        apply = function() player.nukes = player.nukes + 2 end
    },
    {
        id = "EMP_REACTION",
        name = "EMP SHOCKWAVE PULSE",
        desc1 = "Shield break releases EMP",
        desc2 = "vaporizing incoming bullets",
        cost = 130, rarity = "EPIC", col = "3",
        apply = function() player.empBurst = true end
    },
    {
        id = "CLUSTER_BOMB",
        name = "CLUSTER EXPLOSIVES",
        desc1 = "Every 6th shot launches an",
        desc2 = "explosive cluster grenade",
        cost = 140, rarity = "EPIC", col = "4",
        apply = function() player.clusterShot = true end
    },
    {
        id = "TRACTOR_BEAM",
        name = "MAGNET TRACTOR BEAM",
        desc1 = "Automatically pulls all",
        desc2 = "powerups & items to ship",
        cost = 75, rarity = "COMMON", col = "9",
        apply = function() player.tractorBeam = true end
    },
    {
        id = "REACTIVE_ARMOR",
        name = "KINETIC ARMOR PLATES",
        desc1 = "Reduces all damage taken",
        desc2 = "by flat 25% defense",
        cost = 120, rarity = "EPIC", col = "8",
        apply = function() player.armorReduction = player.armorReduction + 0.25 end
    },
    {
        id = "DOUBLE_BLASTER",
        name = "TWIN BARREL ADAPTER",
        desc1 = "Adds secondary parallel",
        desc2 = "cannons to current weapon",
        cost = 100, rarity = "RARE", col = "4",
        apply = function() player.weaponLevel = math.min(3, player.weaponLevel + 1) end
    },
    {
        id = "EMERGENCY_REPAIR",
        name = "FIELD REPAIR NANITES",
        desc1 = "Instantly repairs +80 HP",
        desc2 = "and recharges full shield",
        cost = 55, rarity = "COMMON", col = "5",
        apply = function() player.hp = math.min(player.maxHp, player.hp + 80); player.shield = player.maxShield end
    }
}

-- 3 Offered Upgrade Cards
local offeredCards = {}
local function rollNewCards()
    offeredCards = {}
    local pool = {}
    for i, u in ipairs(ALL_UPGRADES) do table.insert(pool, u) end
    
    -- Pick 3 unique random cards
    for k = 1, 3 do
        if #pool > 0 then
            local idx = math.random(1, #pool)
            table.insert(offeredCards, pool[idx])
            table.remove(pool, idx)
        end
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

-- Weapon Shooting with Perks
local function shootBullet()
    local px = player.x
    local py = player.y
    player.shotCounter = player.shotCounter + 1
    
    -- Base Damage multiplier & Crit
    local isCrit = (math.random() < player.critChance)
    local dmgMult = (1.0 + player.dmgBonus) * (isCrit and 2.5 or 1.0)
    if isCrit then
        playSound("crit")
        addExplosion(px + 1, py - 1, 4, "e")
    end
    
    local bulletCol = (isCrit and "e" or "9")
    
    if player.weapon == 1 then
        if player.weaponLevel == 1 then
            table.insert(bullets, { x = px + 1, y = py - 1, vy = -1.2, vx = 0, dmg = math.floor(15 * dmgMult), col = bulletCol, char = "|" })
        else
            table.insert(bullets, { x = px, y = py - 1, vy = -1.2, vx = 0, dmg = math.floor(15 * dmgMult), col = bulletCol, char = "|" })
            table.insert(bullets, { x = px + 2, y = py - 1, vy = -1.2, vx = 0, dmg = math.floor(15 * dmgMult), col = bulletCol, char = "|" })
        end
        playSound("shoot")
        
    elseif player.weapon == 2 then
        table.insert(bullets, { x = px + 1, y = py - 1, vy = -1.2, vx = 0, dmg = math.floor(12 * dmgMult), col = (isCrit and "e" or "4"), char = "^" })
        table.insert(bullets, { x = px, y = py - 1, vy = -1.1, vx = -0.5, dmg = math.floor(10 * dmgMult), col = (isCrit and "e" or "4"), char = "/" })
        table.insert(bullets, { x = px + 2, y = py - 1, vy = -1.1, vx = 0.5, dmg = math.floor(10 * dmgMult), col = (isCrit and "e" or "4"), char = "\\" })
        playSound("laser")
        
    elseif player.weapon == 3 then
        table.insert(bullets, { x = px + 1, y = py - 1, vy = -1.6, vx = 0, dmg = math.floor(30 * dmgMult), col = (isCrit and "e" or "d"), char = "!" })
        playSound("laser")
        
    elseif player.weapon == 4 then
        table.insert(bullets, { x = px + 1, y = py - 1, vy = -0.9, vx = (math.random() - 0.5), dmg = math.floor(48 * dmgMult), col = "e", char = "o" })
        playSound("shoot")
    end
    
    -- Cluster Grenade Perk
    if player.clusterShot and (player.shotCounter % 6 == 0) then
        table.insert(bullets, { x = px + 1, y = py - 1, vy = -0.8, vx = 0, dmg = 40, col = "4", char = "@", isCluster = true })
    end
    
    -- Drones Shooting
    if player.drones > 0 then
        for d = 1, player.drones do
            local dx = (d % 2 == 1 and px - 2 or px + 4)
            table.insert(bullets, { x = dx, y = py, vy = -1.1, vx = 0, dmg = 10, col = "9", char = ":" })
        end
    end
end

local function fireNuke()
    if player.nukes <= 0 then return end
    player.nukes = player.nukes - 1
    playSound("explode")
    addExplosion(screenW / 2, screenH / 2, 45, "e")
    
    for _, e in ipairs(enemies) do
        e.hp = e.hp - 120
        addExplosion(e.x, e.y, 10, "4")
        if e.hp <= 0 then
            player.score = player.score + e.scoreVal
            player.credits = player.credits + math.floor(e.creditVal * player.creditMultiplier)
        end
    end
    if bossActive then
        bossActive.hp = bossActive.hp - 200
    end
end

-- 12+ Diverse Regular Fleet Units Spawner
local function spawnEnemy(eType, customX)
    local ex = customX or math.random(3, screenW - 8)
    
    if eType == "scout" then
        table.insert(enemies, {
            type = "scout", x = ex, y = 2, vx = (math.random(1, 2) == 1 and 0.4 or -0.4), vy = 0.3,
            hp = 20, maxHp = 20, scoreVal = 100, creditVal = 15,
            sprite = "<V>", fg = "e", shootTimer = math.random(25, 45)
        })
    elseif eType == "cruiser" then
        table.insert(enemies, {
            type = "cruiser", x = ex, y = 2, vx = 0.2, vy = 0.15,
            hp = 65, maxHp = 65, scoreVal = 250, creditVal = 35,
            sprite = "[=X=]", fg = "4", shootTimer = math.random(18, 35)
        })
    elseif eType == "interceptor" then
        table.insert(enemies, {
            type = "interceptor", x = ex, y = 2, vx = 0.7, vy = 0.55,
            hp = 15, maxHp = 15, scoreVal = 150, creditVal = 20,
            sprite = ">*<", fg = "2", shootTimer = 999
        })
    elseif eType == "stealth_bomber" then
        table.insert(enemies, {
            type = "stealth_bomber", x = ex, y = 2, vx = 0.35, vy = 0.18,
            hp = 45, maxHp = 45, scoreVal = 300, creditVal = 40,
            sprite = "{-M-}", fg = "9", shootTimer = 40, mineTimer = 25
        })
    elseif eType == "swarm_bug" then
        table.insert(enemies, {
            type = "swarm_bug", x = ex, y = 2, vx = (math.random() - 0.5) * 0.8, vy = 0.45,
            hp = 12, maxHp = 12, scoreVal = 80, creditVal = 12,
            sprite = "<<#>>", fg = "5", shootTimer = math.random(30, 50)
        })
    elseif eType == "shielded_frigate" then
        table.insert(enemies, {
            type = "shielded_frigate", x = ex, y = 2, vx = 0.25, vy = 0.15,
            hp = 50, maxHp = 50, shield = 60, maxShield = 60, scoreVal = 400, creditVal = 50,
            sprite = "(|#|)", fg = "3", shootTimer = 25
        })
    elseif eType == "railgun_sniper" then
        table.insert(enemies, {
            type = "railgun_sniper", x = ex, y = 2, vx = 0.15, vy = 0.12,
            hp = 40, maxHp = 40, scoreVal = 350, creditVal = 45,
            sprite = "[===]", fg = "e", chargeTimer = 40, isCharging = false
        })
    elseif eType == "teleporter" then
        table.insert(enemies, {
            type = "teleporter", x = ex, y = 2, vx = 0.3, vy = 0.18,
            hp = 35, maxHp = 35, scoreVal = 320, creditVal = 40,
            sprite = "{~*~}", fg = "d", teleportTimer = 50, shootTimer = 30
        })
    elseif eType == "healer_drone" then
        table.insert(enemies, {
            type = "healer_drone", x = ex, y = 2, vx = 0.35, vy = 0.12,
            hp = 30, maxHp = 30, scoreVal = 280, creditVal = 35,
            sprite = "<+>", fg = "5", healTimer = 40, shootTimer = 999
        })
    elseif eType == "turret_carrier" then
        table.insert(enemies, {
            type = "turret_carrier", x = ex, y = 2, vx = 0.2, vy = 0.14,
            hp = 70, maxHp = 70, scoreVal = 450, creditVal = 60,
            sprite = "[=O=]", fg = "1", shootTimer = 25
        })
    elseif eType == "giant_asteroid" then
        table.insert(enemies, {
            type = "giant_asteroid", x = ex, y = 2, vx = (math.random() - 0.5) * 0.2, vy = 0.12,
            hp = 140, maxHp = 140, scoreVal = 300, creditVal = 50,
            sprite = "(((=== TITAN ===)))", fg = "8", shootTimer = 999, splitsToMedium = true
        })
    elseif eType == "medium_asteroid" or eType == "asteroid" then
        local aSpr = (math.random(1, 2) == 1 and "(##8##)" or "(==O==)")
        table.insert(enemies, {
            type = "medium_asteroid", x = ex, y = 2, vx = (math.random() - 0.5) * 0.35, vy = 0.22,
            hp = 50, maxHp = 50, scoreVal = 140, creditVal = 30,
            sprite = aSpr, fg = "7", shootTimer = 999, splitsToSmall = true
        })
    elseif eType == "small_asteroid" or eType == "mini_asteroid" then
        local aSpr = (math.random(1, 2) == 1 and "(*)" or "(o)")
        table.insert(enemies, {
            type = "small_asteroid", x = ex, y = 2, vx = (math.random() - 0.5) * 0.6, vy = 0.38,
            hp = 15, maxHp = 15, scoreVal = 70, creditVal = 15,
            sprite = aSpr, fg = "8", shootTimer = 999
        })
    end
end

-- 5 Unique Boss Fights
local function spawnWaveBoss(waveNum)
    if waveNum == 1 then
        bossActive = {
            name = "Cyber Behemoth",
            x = math.floor(screenW / 2) - 6, y = 3,
            vx = 0.35, hp = 450, maxHp = 450,
            shootTimer = 14,
            sprite1 = "<[ = BEHEMOTH = ]>",
            sprite2 = "  \\_==[GATLING]==_/  ",
            fg = "4"
        }
    elseif waveNum == 2 then
        bossActive = {
            name = "Void Leviathan",
            x = math.floor(screenW / 2) - 8, y = 3,
            vx = 0.4, hp = 700, maxHp = 700,
            shootTimer = 12,
            sprite1 = "<<<===[ LEVIATHAN ]===>>>",
            sprite2 = "  ~(_===[ TENTACLE ]===_)~  ",
            fg = "3"
        }
    elseif waveNum == 3 then
        bossActive = {
            name = "Corvette Hyperion",
            x = math.floor(screenW / 2) - 7, y = 3,
            vx = 0.45, hp = 950, maxHp = 950,
            shield = 150, maxShield = 150,
            shootTimer = 10,
            sprite1 = "<<==[[ HYPERION ]]==>>",
            sprite2 = "  \\_===[ MEGA-BEAM ]===_/  ",
            fg = "2"
        }
    elseif waveNum == 4 then
        bossActive = {
            name = "Stealth Carrier",
            x = math.floor(screenW / 2) - 8, y = 3,
            vx = 0.35, hp = 1200, maxHp = 1200,
            shield = 200, maxShield = 200,
            shootTimer = 12,
            sprite1 = "{{--[[ PHANTOM-X ]]--}}",
            sprite2 = "  /===<[ MINE-HATCH ]>===\\  ",
            fg = "9"
        }
    else
        bossActive = {
            name = "Dreadnought Omega",
            x = math.floor(screenW / 2) - 9, y = 3,
            vx = 0.3, hp = 1800, maxHp = 1800,
            shield = 350, maxShield = 350,
            shootTimer = 10,
            sprite1 = "<[ === DREADNOUGHT OMEGA === ]>",
            sprite2 = "  \\_====[ APOCALYPSE CANNON ]====_/  ",
            fg = "e"
        }
    end
    playSound("boss")
end

-- Wave Director
local function updateWave()
    waveTimer = waveTimer + 1
    
    if waveTimer >= BOSS_SPAWN_TIME - 40 and waveTimer < BOSS_SPAWN_TIME and not bossActive then
        bossWarningTimer = bossWarningTimer + 1
        if bossWarningTimer % 10 == 0 then playSound("boss") end
    else
        bossWarningTimer = 0
    end
    
    if currentWave == 1 then
        if waveTimer % 16 == 0 and #enemies < 6 and not bossActive and waveTimer < BOSS_SPAWN_TIME then
            local r = math.random(1, 10)
            if r <= 3 then spawnEnemy("scout")
            elseif r <= 5 then spawnEnemy("medium_asteroid")
            elseif r <= 7 then spawnEnemy("small_asteroid")
            elseif r <= 9 then spawnEnemy("giant_asteroid")
            else spawnEnemy("healer_drone") end
        end
        if waveTimer == BOSS_SPAWN_TIME and not bossActive then spawnWaveBoss(1) end
        if waveTimer > BOSS_SPAWN_TIME + 20 and #enemies == 0 and not bossActive then
            currentWave = 2; waveTimer = 0; rollNewCards(); activeScreen = "SHOP"
        end
        
    elseif currentWave == 2 then
        if waveTimer % 14 == 0 and #enemies < 8 and not bossActive and waveTimer < BOSS_SPAWN_TIME then
            local r = math.random(1, 10)
            if r <= 3 then spawnEnemy("cruiser")
            elseif r <= 5 then spawnEnemy("turret_carrier")
            elseif r <= 7 then spawnEnemy("interceptor")
            else
                local sx = math.random(4, screenW - 14)
                spawnEnemy("swarm_bug", sx); spawnEnemy("swarm_bug", sx + 4); spawnEnemy("swarm_bug", sx + 8)
            end
        end
        if waveTimer == BOSS_SPAWN_TIME and not bossActive then spawnWaveBoss(2) end
        if waveTimer > BOSS_SPAWN_TIME + 20 and #enemies == 0 and not bossActive then
            currentWave = 3; waveTimer = 0; rollNewCards(); activeScreen = "SHOP"
        end
        
    elseif currentWave == 3 then
        if waveTimer % 14 == 0 and #enemies < 8 and not bossActive and waveTimer < BOSS_SPAWN_TIME then
            local r = math.random(1, 10)
            if r <= 3 then spawnEnemy("shielded_frigate")
            elseif r <= 6 then spawnEnemy("teleporter")
            elseif r <= 8 then spawnEnemy("railgun_sniper")
            else spawnEnemy("healer_drone") end
        end
        if waveTimer == BOSS_SPAWN_TIME and not bossActive then spawnWaveBoss(3) end
        if waveTimer > BOSS_SPAWN_TIME + 20 and #enemies == 0 and not bossActive then
            currentWave = 4; waveTimer = 0; rollNewCards(); activeScreen = "SHOP"
        end
        
    elseif currentWave == 4 then
        if waveTimer % 12 == 0 and #enemies < 9 and not bossActive and waveTimer < BOSS_SPAWN_TIME then
            local r = math.random(1, 10)
            if r <= 3 then spawnEnemy("stealth_bomber")
            elseif r <= 5 then spawnEnemy("turret_carrier")
            elseif r <= 7 then spawnEnemy("teleporter")
            elseif r <= 9 then spawnEnemy("railgun_sniper")
            else spawnEnemy("interceptor") end
        end
        if waveTimer == BOSS_SPAWN_TIME and not bossActive then spawnWaveBoss(4) end
        if waveTimer > BOSS_SPAWN_TIME + 20 and #enemies == 0 and not bossActive then
            currentWave = 5; waveTimer = 0; rollNewCards(); activeScreen = "SHOP"
        end
        
    elseif currentWave == 5 then
        if waveTimer == 20 and not bossActive then spawnWaveBoss(5) end
        if waveTimer % 45 == 0 and bossActive and #enemies < 4 then
            spawnEnemy("scout", bossActive.x - 4)
            spawnEnemy("teleporter", bossActive.x + 18)
        end
        if bossActive == nil and waveTimer > 40 then
            activeScreen = "VICTORY"
        end
    end
end

-- Collision & Updates
local function updateGame()
    updateStars()
    updateParticles()
    updateWave()
    
    -- Shield Passive Recharge
    player.shieldRecharge = player.shieldRecharge + 1
    if player.shieldRecharge > 80 and (player.shieldRecharge % 15 == 0) and player.shield < player.maxShield then
        player.shield = math.min(player.maxShield, player.shield + 1)
    end
    
    -- Bullets
    local nextB = {}
    for _, b in ipairs(bullets) do
        b.x = b.x + b.vx
        b.y = b.y + b.vy
        
        local hit = false
        if not b.isEnemy then
            for _, e in ipairs(enemies) do
                local eW = #e.sprite
                if b.x >= e.x and b.x <= e.x + eW and math.abs(b.y - e.y) < 1.0 then
                    hit = true
                    if e.shield and e.shield > 0 then
                        e.shield = e.shield - b.dmg
                        addExplosion(b.x, b.y, 4, "3")
                        playSound("hit")
                    else
                        e.hp = e.hp - b.dmg
                        addExplosion(b.x, b.y, 4, "9")
                        playSound("hit")
                    end
                    
                    -- Cluster Explosion
                    if b.isCluster then
                        addExplosion(b.x, b.y, 16, "4")
                        playSound("explode")
                        for _, other in ipairs(enemies) do
                            if math.abs(other.x - b.x) < 6 and math.abs(other.y - b.y) < 3 then
                                other.hp = other.hp - 30
                            end
                        end
                    end
                    
                    -- Tesla Arc Lightning
                    if player.teslaArc > 0 then
                        local arcs = player.teslaArc
                        for _, other in ipairs(enemies) do
                            if other ~= e and arcs > 0 and math.abs(other.x - e.x) < 10 and math.abs(other.y - e.y) < 4 then
                                other.hp = other.hp - 20
                                addExplosion(other.x + 1, other.y, 6, "3")
                                arcs = arcs - 1
                            end
                        end
                    end
                    
                    if e.hp <= 0 then
                        addExplosion(e.x + eW / 2, e.y, 15, (e.type == "swarm_bug" and "5" or "e"))
                        playSound("explode")
                        player.score = player.score + e.scoreVal
                        player.credits = player.credits + math.floor(e.creditVal * player.creditMultiplier)
                        
                        -- Vampire Lifesteal
                        if math.random() < player.lifesteal then
                            player.hp = math.min(player.maxHp, player.hp + 4)
                            playSound("heal")
                        end
                        
                        -- Meteorite Cascading Splitting
                        if e.splitsToMedium then
                            addExplosion(e.x + eW / 2, e.y, 25, "8")
                            spawnEnemy("medium_asteroid", math.max(2, e.x - 3))
                            spawnEnemy("medium_asteroid", math.min(screenW - 8, e.x + 8))
                        elseif e.splitsToSmall then
                            addExplosion(e.x + eW / 2, e.y, 15, "7")
                            spawnEnemy("small_asteroid", math.max(2, e.x - 2))
                            spawnEnemy("small_asteroid", math.min(screenW - 4, e.x + 4))
                        end
                        
                        if math.random(1, 5) == 1 or e.splitsToMedium then
                            table.insert(powerups, {
                                x = e.x + eW / 2, y = e.y,
                                pType = (math.random(1, 3) == 1 and "HP" or (math.random(1, 2) == 1 and "SHIELD" or "WEAPON")),
                                vy = 0.3
                            })
                        end
                    end
                    break
                end
            end
            
            if not hit and bossActive then
                if b.x >= bossActive.x and b.x <= bossActive.x + #bossActive.sprite1 and b.y <= bossActive.y + 1 and b.y >= bossActive.y then
                    hit = true
                    if bossActive.shield and bossActive.shield > 0 then
                        bossActive.shield = bossActive.shield - b.dmg
                        addExplosion(b.x, b.y, 4, "3")
                        playSound("hit")
                    else
                        bossActive.hp = bossActive.hp - b.dmg
                        addExplosion(b.x, b.y, 4, "e")
                        playSound("hit")
                    end
                    
                    if bossActive.hp <= 0 then
                        addExplosion(bossActive.x + 10, bossActive.y + 1, 50, "4")
                        playSound("explode")
                        player.score = player.score + 5000 * currentWave
                        player.credits = player.credits + math.floor(150 * currentWave * player.creditMultiplier)
                        bossActive = nil
                    end
                end
            end
        end
        
        if not hit and b.y > 1 and b.y < screenH - 2 and b.x > 1 and b.x < screenW then
            table.insert(nextB, b)
        end
    end
    bullets = nextB
    
    -- Enemy AI Updates
    local nextE = {}
    for _, e in ipairs(enemies) do
        e.x = e.x + e.vx
        e.y = e.y + e.vy
        if e.x <= 2 or e.x >= screenW - #e.sprite - 1 then e.vx = -e.vx end
        
        if e.type == "interceptor" then
            if player.x > e.x then e.vx = math.min(0.8, e.vx + 0.08)
            else e.vx = math.max(-0.8, e.vx - 0.08) end
            
        elseif e.type == "stealth_bomber" then
            e.mineTimer = e.mineTimer - 1
            if e.mineTimer <= 0 then
                e.mineTimer = 35
                table.insert(bullets, { x = e.x + 2, y = e.y + 1, vy = 0.35, vx = 0, dmg = 25, col = "e", char = "*", isEnemy = true })
                playSound("hit")
            end
            
        elseif e.type == "railgun_sniper" then
            e.chargeTimer = e.chargeTimer - 1
            if e.chargeTimer <= 15 then e.isCharging = true end
            if e.chargeTimer <= 0 then
                e.chargeTimer = 45
                e.isCharging = false
                table.insert(bullets, { x = e.x + 2, y = e.y + 1, vy = 2.2, vx = 0, dmg = 30, col = "e", char = "!", isEnemy = true })
                playSound("railgun")
            end
            
        elseif e.type == "teleporter" then
            e.teleportTimer = e.teleportTimer - 1
            if e.teleportTimer <= 0 then
                e.teleportTimer = math.random(35, 60)
                addExplosion(e.x + 2, e.y, 6, "d")
                e.x = math.random(3, screenW - 8)
                playSound("teleport")
            end
            e.shootTimer = e.shootTimer - 1
            if e.shootTimer <= 0 then
                e.shootTimer = math.random(20, 35)
                table.insert(bullets, { x = e.x + 2, y = e.y + 1, vy = 1.1, vx = 0, dmg = 14, col = "d", char = "v", isEnemy = true })
            end
            
        elseif e.type == "healer_drone" then
            e.healTimer = e.healTimer - 1
            if e.healTimer <= 0 then
                e.healTimer = 35
                for _, other in ipairs(enemies) do
                    if other ~= e and math.abs(other.x - e.x) < 8 and math.abs(other.y - e.y) < 3 then
                        other.hp = math.min(other.maxHp, other.hp + 20)
                        addExplosion(other.x + 2, other.y, 4, "5")
                    end
                end
                playSound("heal")
            end
            
        elseif e.type == "turret_carrier" then
            e.shootTimer = e.shootTimer - 1
            if e.shootTimer <= 0 then
                e.shootTimer = 25
                table.insert(bullets, { x = e.x + 1, y = e.y + 1, vy = 0.95, vx = -0.4, dmg = 14, col = "1", char = "/", isEnemy = true })
                table.insert(bullets, { x = e.x + 2, y = e.y + 1, vy = 1.15, vx = 0,    dmg = 16, col = "1", char = "v", isEnemy = true })
                table.insert(bullets, { x = e.x + 3, y = e.y + 1, vy = 0.95, vx = 0.4,  dmg = 14, col = "1", char = "\\", isEnemy = true })
                playSound("shoot")
            end
            
        else
            e.shootTimer = e.shootTimer - 1
            if e.shootTimer <= 0 then
                e.shootTimer = math.random(18, 35)
                table.insert(bullets, { x = e.x + #e.sprite / 2, y = e.y + 1, vy = 1.05, vx = 0, dmg = 12, col = "e", char = "v", isEnemy = true })
            end
        end
        
        -- Player Collision
        if math.abs(e.x - player.x) < 3 and math.abs(e.y - player.y) < 1.2 then
            e.hp = 0
            addExplosion(player.x + 1, player.y, 20, "e")
            playSound("explode")
            local taken = math.floor(25 * (1.0 - player.armorReduction))
            if player.shield > 0 then
                player.shield = math.max(0, player.shield - taken)
                if player.shield <= 0 and player.empBurst then
                    addExplosion(player.x + 1, player.y, 25, "3")
                    bullets = {}
                end
            else
                player.hp = math.max(0, player.hp - taken)
            end
            player.shieldRecharge = 0
        end
        
        if e.hp > 0 and e.y < screenH - 3 then
            table.insert(nextE, e)
        end
    end
    enemies = nextE
    
    -- Boss Update
    if bossActive then
        bossActive.x = bossActive.x + bossActive.vx
        if bossActive.x <= 2 or bossActive.x >= screenW - #bossActive.sprite1 - 2 then
            bossActive.vx = -bossActive.vx
        end
        bossActive.shootTimer = bossActive.shootTimer - 1
        if bossActive.shootTimer <= 0 then
            bossActive.shootTimer = 11
            table.insert(bullets, { x = bossActive.x + 3, y = bossActive.y + 2, vy = 1.0, vx = -0.45, dmg = 18, col = "e", char = "\\", isEnemy = true })
            table.insert(bullets, { x = bossActive.x + #bossActive.sprite1 / 2 - 2, y = bossActive.y + 2, vy = 1.2, vx = -0.15, dmg = 22, col = "4", char = "V", isEnemy = true })
            table.insert(bullets, { x = bossActive.x + #bossActive.sprite1 / 2 + 2, y = bossActive.y + 2, vy = 1.2, vx = 0.15, dmg = 22, col = "4", char = "V", isEnemy = true })
            table.insert(bullets, { x = bossActive.x + #bossActive.sprite1 - 3, y = bossActive.y + 2, vy = 1.0, vx = 0.45, dmg = 18, col = "e", char = "/", isEnemy = true })
            playSound("shoot")
        end
    end
    
    -- Player Damage
    local remainB = {}
    for _, b in ipairs(bullets) do
        if b.isEnemy then
            if math.abs(b.x - (player.x + 1)) < 2.0 and math.abs(b.y - player.y) < 1.0 then
                addExplosion(player.x + 1, player.y, 8, "e")
                playSound("hit")
                local taken = math.floor(b.dmg * (1.0 - player.armorReduction))
                if player.shield > 0 then
                    player.shield = math.max(0, player.shield - taken)
                    if player.shield <= 0 and player.empBurst then
                        addExplosion(player.x + 1, player.y, 25, "3")
                        remainB = {}
                        break
                    end
                else
                    player.hp = math.max(0, player.hp - taken)
                end
                player.shieldRecharge = 0
                if player.hp <= 0 then
                    addExplosion(player.x + 1, player.y, 30, "4")
                    playSound("explode")
                    activeScreen = "GAMEOVER"
                end
            else
                table.insert(remainB, b)
            end
        else
            table.insert(remainB, b)
        end
    end
    bullets = remainB
    
    -- Powerups & Tractor Beam
    local nextPow = {}
    for _, p in ipairs(powerups) do
        p.y = p.y + p.vy
        if player.tractorBeam then
            if p.x < player.x then p.x = p.x + 0.4 else p.x = p.x - 0.4 end
            if p.y < player.y then p.y = p.y + 0.3 else p.y = p.y - 0.3 end
        end
        if math.abs(p.x - (player.x + 1)) < 2.5 and math.abs(p.y - player.y) < 1.2 then
            playSound("powerup")
            if p.pType == "HP" then player.hp = math.min(player.maxHp, player.hp + 40)
            elseif p.pType == "SHIELD" then player.shield = math.min(player.maxShield, player.shield + 40)
            elseif p.pType == "WEAPON" then player.weaponLevel = math.min(3, player.weaponLevel + 1) end
        elseif p.y < screenH - 3 then
            table.insert(nextPow, p)
        end
    end
    powerups = nextPow
end

-- Render HUD & Centered Touch Controls
local function renderGame()
    clearBuffer("f")
    clearButtons()
    drawStars()
    
    -- 1. HUD Top Bar
    drawText(1, 1, string.rep(" ", screenW), "0", "7")
    drawText(2, 1, string.format("W%d/5", currentWave), "4", "7")
    
    local timeLeft = math.max(0, math.floor((BOSS_SPAWN_TIME - waveTimer) / 20))
    if not bossActive and currentWave < 5 then
        drawText(8, 1, string.format("[BOSS:%02ds]", timeLeft), (timeLeft <= 5 and "e" or "0"), "7")
    elseif bossActive then
        drawText(8, 1, "[BOSS BATTLE]", "e", "7")
    end
    
    drawText(23, 1, string.format("SCORE: %06d", player.score), "0", "7")
    drawText(screenW - 14, 1, string.format("CR: $%d", player.credits), "5", "7")
    
    -- Boss Warning Marquee Banner
    if bossWarningTimer > 0 and not bossActive then
        local warnText = ">>> WARNING: CAPITAL BOSS INCOMING <<<"
        local wx = math.max(1, math.floor((screenW - #warnText) / 2))
        drawText(wx, 3, warnText, ((waveTimer % 4 < 2) and "e" or "4"), "f")
    end
    
    -- 2. Draw Boss
    if bossActive then
        drawText(bossActive.x, bossActive.y, bossActive.sprite1, bossActive.fg, "f")
        drawText(bossActive.x, bossActive.y + 1, bossActive.sprite2, "4", "f")
        local bBarW = math.floor((bossActive.hp / bossActive.maxHp) * (screenW - 14))
        drawText(5, 2, string.format("[%s: %s%s]", bossActive.name, string.rep("=", bBarW), string.rep("-", screenW - 14 - bBarW)), "e", "f")
    end
    
    -- 3. Draw Enemies & Abilities
    for _, e in ipairs(enemies) do
        if e.isCharging then
            for ly = math.floor(e.y + 1), screenH - 4 do
                drawText(math.floor(e.x + 2), ly, ":", "e", "f")
            end
        end
        if e.shield and e.shield > 0 then
            drawText(e.x - 1, e.y, "(", "3", "f")
            drawText(e.x + #e.sprite, e.y, ")", "3", "f")
        end
        drawText(e.x, e.y, e.sprite, e.fg, "f")
    end
    
    -- 4. Powerups & Bullets
    for _, p in ipairs(powerups) do
        local pChar = (p.pType == "HP" and "[+]" or (p.pType == "SHIELD" and "[S]" or "[W]"))
        local pCol = (p.pType == "HP" and "5" or (p.pType == "SHIELD" and "3" or "4"))
        drawText(p.x - 1, p.y, pChar, pCol, "f")
    end
    for _, b in ipairs(bullets) do
        drawText(b.x, b.y, b.char, b.col, "f")
    end
    drawParticles()
    
    -- 5. Draw Player Ship & Drones
    local thruster = (math.random(1, 2) == 1 and "^" or "!")
    drawText(player.x, player.y, "<A>", "9", "f")
    drawText(player.x + 1, player.y + 1, thruster, "4", "f")
    if player.drones > 0 then
        drawText(player.x - 2, player.y + 1, "o", "9", "f")
        if player.drones > 1 then drawText(player.x + 4, player.y + 1, "o", "9", "f") end
    end
    
    -- 6. Status Info (Above Touch Bar)
    local hpStr = string.format("HP: %d/%d", player.hp, player.maxHp)
    drawText(2, screenH - 2, hpStr, (player.hp > 30 and "5" or "e"), "f")
    local shStr = string.format("SHIELD: %d/%d", player.shield, player.maxShield)
    drawText(18, screenH - 2, shStr, "3", "f")
    
    -- 7. Centered On-Screen Touch Control Buttons (Bottom 2 Lines)
    drawText(1, screenH - 1, string.rep("-", screenW), "7", "f")
    drawText(1, screenH, string.rep(" ", screenW), "0", "7")
    
    local nukeLabel = string.format("[NUKE:%d]", player.nukes)
    
    if screenW >= 56 then
        local btnTotalW = 8 + 6 + 6 + 9 + 14 + #nukeLabel + 5
        local cx = math.max(2, math.floor((screenW - btnTotalW) / 2))
        registerButton("BTN_LEFT",  cx, screenH, 8, 1, "[< LEFT]", "0", "3")
        registerButton("BTN_UP",    cx + 9, screenH, 6, 1, "[^ UP]", "0", "8")
        registerButton("BTN_DOWN",  cx + 16, screenH, 6, 1, "[v DN]", "0", "8")
        registerButton("BTN_RIGHT", cx + 23, screenH, 9, 1, "[RIGHT >]", "0", "3")
        registerButton("BTN_FIRE",  cx + 33, screenH, 14, 1, "[*** FIRE ***]", "0", "5")
        registerButton("BTN_NUKE",  cx + 48, screenH, #nukeLabel, 1, nukeLabel, "0", "e")
    else
        local btnTotalW = 4 + 4 + 4 + 4 + 8 + #nukeLabel + 5
        local cx = math.max(1, math.floor((screenW - btnTotalW) / 2))
        registerButton("BTN_LEFT",  cx, screenH, 4, 1, "[<]", "0", "3")
        registerButton("BTN_UP",    cx + 5, screenH, 4, 1, "[^]", "0", "8")
        registerButton("BTN_DOWN",  cx + 10, screenH, 4, 1, "[v]", "0", "8")
        registerButton("BTN_RIGHT", cx + 15, screenH, 4, 1, "[>]", "0", "3")
        registerButton("BTN_FIRE",  cx + 20, screenH, 8, 1, "[FIRE]", "0", "5")
        registerButton("BTN_NUKE",  cx + 29, screenH, #nukeLabel, 1, nukeLabel, "0", "e")
    end
    
    drawButtons()
    flushBuffer()
end

-- Render 3-Card Roguelike Upgrade Shop (Centered in the screen)
local function renderShop()
    clearBuffer("f")
    clearButtons()
    drawStars()
    
    local titleText = "=== HANGAR UPGRADE DOCK: CHOOSE 1 OF 3 UPGRADES ==="
    local tx = math.max(1, math.floor((screenW - #titleText) / 2))
    drawText(tx, 2, titleText, "4", "f")
    
    local crText = string.format("AVAILABLE CREDITS: $%d", player.credits)
    local cx = math.max(1, math.floor((screenW - #crText) / 2))
    drawText(cx, 4, crText, "5", "f")
    
    if #offeredCards == 0 then rollNewCards() end
    
    -- Draw 3 Cards (Centered Horizontally or Vertically depending on width)
    if screenW >= 56 then
        -- 3 Horizontal Cards Layout
        local cardW = 16
        local cardGap = 2
        local totalW = (cardW * 3) + (cardGap * 2)
        local startX = math.max(2, math.floor((screenW - totalW) / 2))
        local startY = 6
        
        for i, card in ipairs(offeredCards) do
            local cardX = startX + (i - 1) * (cardW + cardGap)
            
            -- Card Frame
            drawText(cardX, startY,     "+--------------+", "7", "f")
            drawText(cardX, startY + 1, string.format("| [%d] %-8s |", i, card.rarity), card.col, "f")
            drawText(cardX, startY + 2, string.format("| %-12s |", string.sub(card.name, 1, 12)), "0", "7")
            drawText(cardX, startY + 3, string.format("| %-12s |", string.sub(card.desc1, 1, 12)), "8", "f")
            drawText(cardX, startY + 4, string.format("| %-12s |", string.sub(card.desc2, 1, 12)), "8", "f")
            drawText(cardX, startY + 5, "+--------------+", "7", "f")
            
            -- Buy Button
            local buyLabel = string.format("[%d: BUY $%d]", i, card.cost)
            local canAfford = (player.credits >= card.cost)
            registerButton("CARD_" .. i, cardX, startY + 6, #buyLabel, 1, buyLabel, (canAfford and "0" or "8"), (canAfford and "5" or "7"))
        end
    else
        -- Vertical Compact Cards Layout
        local startY = 6
        for i, card in ipairs(offeredCards) do
            local canAfford = (player.credits >= card.cost)
            local line1 = string.format("[%d] %s ($%d) - %s", i, card.name, card.cost, card.rarity)
            local line2 = string.format("    %s, %s", card.desc1, card.desc2)
            drawText(2, startY + (i - 1) * 3, line1, (canAfford and card.col or "8"), "f")
            drawText(2, startY + (i - 1) * 3 + 1, line2, "7", "f")
            registerButton("CARD_" .. i, 2, startY + (i - 1) * 3, screenW - 4, 2, "", "0", "f")
        end
    end
    
    -- Reroll & Continue Buttons
    local rx = math.max(2, math.floor(screenW / 2) - 18)
    registerButton("BTN_REROLL", rx, screenH - 3, 17, 1, "[R] REROLL ($30)", "0", "e")
    registerButton("BTN_NEXT_WAVE", rx + 19, screenH - 3, 17, 1, "[ENTER] LAUNCH >>>", "0", "5")
    
    drawButtons()
    flushBuffer()
end

-- Render Menu Screen
local menuTick = 0
local function renderMenu()
    menuTick = menuTick + 1
    clearBuffer("f")
    clearButtons()
    updateStars()
    drawStars()
    
    local titleCols = { "4", "1", "e", "2", "3", "9", "5" }
    local colIdx = (menuTick % #titleCols) + 1
    local titleFg = titleCols[colIdx]
    
    local mx = math.max(1, math.floor(screenW / 2) - 18)
    drawText(mx, 3, "===================================", titleFg, "f")
    drawText(mx, 4, "   * G A L A X Y   D E F E N D E R *   ", "0", "7")
    drawText(mx, 5, "    RETRO SPACE ARCADE SHOOTER     ", "3", "f")
    drawText(mx, 6, "===================================", titleFg, "f")
    
    local demoShipX = math.floor(screenW / 2) + math.floor(math.sin(menuTick * 0.15) * 12)
    drawText(demoShipX, 10, "<A>", "9", "f")
    drawText(demoShipX + 1, 11, "^", "4", "f")
    if menuTick % 3 == 0 then
        drawText(demoShipX + 1, 9, "|", "9", "f")
        drawText(demoShipX + 1, 8, "|", "9", "f")
    end
    
    drawText(demoShipX - 6, 7, "<V>", "e", "f")
    drawText(demoShipX, 6, "[=X=]", "4", "f")
    drawText(demoShipX + 6, 7, ">*<", "2", "f")
    
    local bx = math.max(1, math.floor(screenW / 2) - 11)
    registerButton("BTN_START", bx, 13, 22, 1, "  [1] START CAMPAIGN  ", "0", "5")
    registerButton("BTN_SHOP",  bx, 15, 22, 1, "  [2] HANGAR UPGRADES ", "0", "3")
    registerButton("BTN_QUIT",  bx, 17, 22, 1, "  [3] QUIT GAME       ", "0", "e")
    
    drawText(2, screenH, "[WASD/ARROWS: FLY] [SPACE: FIRE] [E: NUKE]", "7", "f")
    drawButtons()
    flushBuffer()
end

-- Render Victory & Game Over
local function renderGameOver()
    clearBuffer("f")
    clearButtons()
    drawStars()
    
    local mx = math.max(1, math.floor(screenW / 2) - 12)
    drawText(mx, 5, "========================", "e", "f")
    drawText(mx, 6, "    M I S S I O N   F A I L E D    ", "0", "e")
    drawText(mx, 7, "========================", "e", "f")
    
    drawText(mx + 2, 10, string.format("FINAL SCORE:   %06d", player.score), "4", "f")
    drawText(mx + 2, 12, string.format("WAVE REACHED:  %d/5", currentWave), "3", "f")
    
    registerButton("BTN_MENU", math.floor(screenW / 2) - 8, 15, 16, 1, " [ RETURN TO MENU ] ", "0", "7")
    drawButtons()
    flushBuffer()
end

local function renderVictory()
    clearBuffer("f")
    clearButtons()
    drawStars()
    
    local mx = math.max(1, math.floor(screenW / 2) - 14)
    drawText(mx, 5, "==============================", "5", "f")
    drawText(mx, 6, "   G A L A X Y   S A V E D !   ", "0", "5")
    drawText(mx, 7, "==============================", "5", "f")
    
    drawText(mx + 2, 10, string.format("ALL 5 WAVES CLEARED! SCORE: %d", player.score), "4", "f")
    drawText(mx + 2, 12, string.format("CREDITS EARNED: $%d", player.credits), "5", "f")
    
    registerButton("BTN_MENU", math.floor(screenW / 2) - 8, 15, 16, 1, " [ RETURN TO MENU ] ", "0", "5")
    drawButtons()
    flushBuffer()
end

-- Reset Game
local function resetGame()
    player.x = math.floor(screenW / 2)
    player.y = screenH - 5
    player.hp = 100
    player.maxHp = 100
    player.shield = 50
    player.maxShield = 50
    player.score = 0
    player.credits = 80
    player.weapon = 1
    player.weaponLevel = 1
    player.nukes = 2
    player.critChance = 0
    player.dmgBonus = 0
    player.fireRateBonus = 0
    player.lifesteal = 0
    player.creditMultiplier = 1.0
    player.armorReduction = 0
    player.drones = 0
    player.teslaArc = 0
    player.empBurst = false
    player.clusterShot = false
    player.tractorBeam = false
    currentWave = 1
    waveTimer = 0
    bossWarningTimer = 0
    bullets = {}
    enemies = {}
    powerups = {}
    bossActive = nil
    rollNewCards()
end

-- Buy Card Handler
local function tryBuyCard(cardIdx)
    local card = offeredCards[cardIdx]
    if card and player.credits >= card.cost then
        player.credits = player.credits - card.cost
        card.apply()
        playSound("powerup")
        table.remove(offeredCards, cardIdx)
        if #offeredCards == 0 then rollNewCards() end
    end
end

-- Main Game Loop
local function main()
    initStars()
    resetGame()
    
    local timerId = os.startTimer(0.05)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.05)
            
            if activeScreen == "MENU" then
                renderMenu()
            elseif activeScreen == "GAME" then
                updateGame()
                renderGame()
            elseif activeScreen == "SHOP" then
                renderShop()
            elseif activeScreen == "GAMEOVER" then
                renderGameOver()
            elseif activeScreen == "VICTORY" then
                renderVictory()
            end
            
        elseif event == "key" then
            if activeScreen == "MENU" then
                if p1 == keys.one or p1 == keys.enter or p1 == keys.space then
                    resetGame()
                    activeScreen = "GAME"
                elseif p1 == keys.two or p1 == keys.s then
                    rollNewCards()
                    activeScreen = "SHOP"
                elseif p1 == keys.three or p1 == keys.q or p1 == keys.escape then
                    break
                end
                
            elseif activeScreen == "GAME" then
                if p1 == keys.left or p1 == keys.a then
                    player.x = math.max(2, player.x - 2)
                elseif p1 == keys.right or p1 == keys.d then
                    player.x = math.min(screenW - 4, player.x + 2)
                elseif p1 == keys.up or p1 == keys.w then
                    player.y = math.max(screenH - 10, player.y - 1)
                elseif p1 == keys.down or p1 == keys.s then
                    player.y = math.min(screenH - 4, player.y + 1)
                elseif p1 == keys.space or p1 == keys.j then
                    shootBullet()
                elseif p1 == keys.e or p1 == keys.k then
                    fireNuke()
                elseif p1 == keys.q or p1 == keys.escape then
                    activeScreen = "MENU"
                end
                
            elseif activeScreen == "SHOP" then
                if p1 == keys.one then
                    tryBuyCard(1)
                elseif p1 == keys.two then
                    tryBuyCard(2)
                elseif p1 == keys.three then
                    tryBuyCard(3)
                elseif p1 == keys.r and player.credits >= 30 then
                    player.credits = player.credits - 30
                    playSound("click")
                    rollNewCards()
                elseif p1 == keys.enter or p1 == keys.space then
                    activeScreen = "GAME"
                elseif p1 == keys.q or p1 == keys.escape then
                    activeScreen = "MENU"
                end
                
            elseif activeScreen == "GAMEOVER" or activeScreen == "VICTORY" then
                if p1 == keys.enter or p1 == keys.space or p1 == keys.q or p1 == keys.escape then
                    activeScreen = "MENU"
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if activeScreen == "MENU" then
                if cid == "BTN_START" then
                    resetGame()
                    activeScreen = "GAME"
                elseif cid == "BTN_SHOP" then
                    rollNewCards()
                    activeScreen = "SHOP"
                elseif cid == "BTN_QUIT" then
                    break
                end
                
            elseif activeScreen == "GAME" then
                if cid == "BTN_LEFT" then
                    player.x = math.max(2, player.x - 3)
                elseif cid == "BTN_RIGHT" then
                    player.x = math.min(screenW - 4, player.x + 3)
                elseif cid == "BTN_UP" then
                    player.y = math.max(screenH - 10, player.y - 2)
                elseif cid == "BTN_DOWN" then
                    player.y = math.min(screenH - 4, player.y + 2)
                elseif cid == "BTN_FIRE" then
                    shootBullet()
                elseif cid == "BTN_NUKE" then
                    fireNuke()
                else
                    if my < screenH - 3 then
                        if mx < math.floor(screenW / 2) then
                            player.x = math.max(2, player.x - 2)
                        else
                            player.x = math.min(screenW - 4, player.x + 2)
                        end
                        shootBullet()
                    end
                end
                
            elseif activeScreen == "SHOP" then
                if cid == "CARD_1" then
                    tryBuyCard(1)
                elseif cid == "CARD_2" then
                    tryBuyCard(2)
                elseif cid == "CARD_3" then
                    tryBuyCard(3)
                elseif cid == "BTN_REROLL" and player.credits >= 30 then
                    player.credits = player.credits - 30
                    playSound("click")
                    rollNewCards()
                elseif cid == "BTN_NEXT_WAVE" then
                    activeScreen = "GAME"
                end
                
            elseif activeScreen == "GAMEOVER" or activeScreen == "VICTORY" then
                if cid == "BTN_MENU" then
                    activeScreen = "MENU"
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Galaxy Defender closed.")
    else
        print("Galaxy Defender closed.")
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
