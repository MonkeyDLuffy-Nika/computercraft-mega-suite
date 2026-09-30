-- ============================================================================
-- SUPER MARIO BROS NES ULTRA HD - CC: TWEAKED EDITION
-- 2x3 Subpixel Teletext Pixel-Art Engine, Responsive Physics & Chiptunes
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
-- HIGH VIBRANCE NES COLOR PALETTE
-- ============================================================================
local NES_PALETTE = {
    [colors.white]     = 0xFFFFFF, -- 0: White (Clouds/Eyes)
    [colors.orange]    = 0xFF961E, -- 1: Mystery Block Gold
    [colors.magenta]   = 0xEB4BBE, -- 2: Fire Flower Pink
    [colors.lightBlue] = 0x5C94FC, -- 3: NES Sky Blue
    [colors.yellow]    = 0xFCE428, -- 4: Coin / Star Yellow
    [colors.lime]      = 0x80D010, -- 5: Bright Grass Green
    [colors.pink]      = 0xFCA044, -- 6: Mario Peach Skin
    [colors.gray]      = 0x747474, -- 7: Castle Stone
    [colors.lightGray] = 0xBCBCBC, -- 8: Cloud Highlight
    [colors.cyan]      = 0x00E8D8, -- 9: Ice / Water
    [colors.purple]    = 0x940084, -- a: Underground Purple
    [colors.blue]      = 0x0000BC, -- b: Mario Blue Overalls
    [colors.brown]     = 0xC84C0C, -- c: NES Ground/Brick Brown
    [colors.green]     = 0x00A800, -- d: Pipe & Bush Dark Green
    [colors.red]       = 0xE40058, -- e: Mario Red Hat/Shirt
    [colors.black]     = 0x000000  -- f: Pitch Black (Outlines/Mustache)
}

if display.setPaletteColor then
    for col, hexVal in pairs(NES_PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- ============================================================================
-- SOUND FX SYNTHESIZER
-- ============================================================================
local isMuted = false
local function playSound(snd)
    if isMuted or not speaker then return end
    pcall(function()
        if snd == "jump" then
            speaker.playNote("chime", 0.7, 12)
            speaker.playNote("chime", 0.7, 18)
        elseif snd == "coin" then
            speaker.playNote("bell", 0.9, 17)
            speaker.playNote("bell", 0.9, 22)
        elseif snd == "stomp" then
            speaker.playNote("bass", 0.9, 8)
        elseif snd == "bump" then
            speaker.playNote("snare", 0.6, 6)
        elseif snd == "powerup" then
            speaker.playNote("chime", 0.8, 10)
            speaker.playNote("chime", 0.8, 14)
            speaker.playNote("chime", 0.8, 18)
            speaker.playNote("chime", 0.8, 22)
        elseif snd == "die" then
            speaker.playNote("bass", 0.8, 14)
            sleep(0.05)
            speaker.playNote("bass", 0.8, 9)
            sleep(0.05)
            speaker.playNote("bass", 0.8, 4)
        elseif snd == "win" then
            speaker.playNote("iron_xylophone", 0.8, 12)
            speaker.playNote("iron_xylophone", 0.8, 16)
            speaker.playNote("iron_xylophone", 0.8, 19)
            speaker.playNote("iron_xylophone", 0.9, 24)
        end
    end)
end

-- ============================================================================
-- SPRITES (2x3 TELETEXT SUBPIXEL BLIT STRINGS)
-- ============================================================================
-- Mario Sprites (2 characters wide x 2 characters tall = 4x6 subpixels)
-- Stand Right:
local SPRITE_MARIO_STAND_R = {
    { ch = "\139\140", fg = "ee", bg = "66" }, -- Hat & Face
    { ch = "\159\159", fg = "bb", bg = "ee" }  -- Shirt & Overalls
}
local SPRITE_MARIO_STAND_L = {
    { ch = "\140\139", fg = "ee", bg = "66" },
    { ch = "\159\159", fg = "bb", bg = "ee" }
}
local SPRITE_MARIO_WALK_R = {
    { ch = "\139\140", fg = "ee", bg = "66" },
    { ch = "\154\149", fg = "bb", bg = "ee" }
}
local SPRITE_MARIO_WALK_L = {
    { ch = "\140\139", fg = "ee", bg = "66" },
    { ch = "\149\154", fg = "bb", bg = "ee" }
}
local SPRITE_MARIO_JUMP_R = {
    { ch = "\143\140", fg = "ee", bg = "66" },
    { ch = "\150\153", fg = "bb", bg = "ee" }
}
local SPRITE_MARIO_JUMP_L = {
    { ch = "\140\143", fg = "ee", bg = "66" },
    { ch = "\153\150", fg = "bb", bg = "ee" }
}

-- Goomba Sprite (2x2 chars)
local SPRITE_GOOMBA_1 = {
    { ch = "\159\159", fg = "cc", bg = "00" }, -- Brown Cap & Eyes
    { ch = "\149\154", fg = "ff", bg = "cc" }  -- Feet 1
}
local SPRITE_GOOMBA_2 = {
    { ch = "\159\159", fg = "cc", bg = "00" },
    { ch = "\154\149", fg = "ff", bg = "cc" }  -- Feet 2
}
local SPRITE_GOOMBA_FLAT = {
    { ch = "  ",         fg = "33", bg = "33" },
    { ch = "\131\131", fg = "cc", bg = "33" }
}

-- Koopa Troopa Sprite (2x2 chars)
local SPRITE_KOOPA = {
    { ch = "\159\140", fg = "55", bg = "66" }, -- Green Head
    { ch = "\159\159", fg = "dd", bg = "44" }  -- Green Shell & Yellow belly
}
local SPRITE_KOOPA_SHELL = {
    { ch = "\131\131", fg = "dd", bg = "33" },
    { ch = "\159\159", fg = "dd", bg = "00" }
}

-- Super Mushroom Sprite (2x2 chars)
local SPRITE_MUSHROOM = {
    { ch = "\159\159", fg = "ee", bg = "00" }, -- Red Cap with White Dots
    { ch = "\142\141", fg = "66", bg = "00" }  -- Stem
}

-- ============================================================================
-- GAME STATE & CONSTANTS
-- ============================================================================
local LEVEL_WIDTH = 220
local LEVEL_HEIGHT = 16
local GROUND_Y = 14 -- Ground starts at line 14

local score = 0
local coins = 0
local lives = 3
local gameTime = 300
local gameTick = 0
local isGameOver = false
local isGameWon = false
local isPaused = false

-- Mario Physics
local mario = {
    x = 4, y = 12,      -- x in tiles, y in tiles (1..16)
    vx = 0, vy = 0,
    isGrounded = true,
    facing = 1,         -- 1: right, -1: left
    walkFrame = 0,
    power = 1,          -- 1: Small, 2: Super
    invincibleTimer = 0,
    isDead = false,
    deathTimer = 0
}

-- Input State (Keys currently held)
local keysHeld = { left = false, right = false, jump = false, run = false }

-- Camera
local cameraX = 0

-- World Grid
local levelGrid = {}
local enemies = {}
local items = {}
local particles = {}

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
-- WORLD 1-1 GENERATION
-- ============================================================================
local function initLevel()
    levelGrid = {}
    for y = 1, LEVEL_HEIGHT do
        levelGrid[y] = {}
        for x = 1, LEVEL_WIDTH do
            levelGrid[y][x] = " " -- Sky
        end
    end
    
    -- Ground (Lines 14, 15, 16) with Pits
    for x = 1, LEVEL_WIDTH do
        local isPit = (x >= 69 and x <= 71) or (x >= 86 and x <= 88) or (x >= 153 and x <= 155)
        if not isPit then
            levelGrid[14][x] = "G" -- Top grass ground
            levelGrid[15][x] = "#" -- Dirt under
            levelGrid[16][x] = "#" -- Dirt under
        end
    end
    
    -- Decorative Clouds
    for x = 6, LEVEL_WIDTH, 20 do
        levelGrid[2][x] = "W"; levelGrid[2][x+1] = "W"; levelGrid[2][x+2] = "W"
        levelGrid[3][x-1] = "W"; levelGrid[3][x] = "W"; levelGrid[3][x+1] = "W"; levelGrid[3][x+2] = "W"; levelGrid[3][x+3] = "W"
    end
    
    -- Question block [?] at x=16, y=10
    levelGrid[10][16] = "?"
    
    -- Brick structure [B][?][B][?][B] at x=20..24, y=10
    levelGrid[10][20] = "B"
    levelGrid[10][21] = "?"
    levelGrid[10][22] = "B"
    levelGrid[10][23] = "?"
    levelGrid[10][24] = "B"
    
    -- Super Mushroom block [?] high at x=22, y=6
    levelGrid[6][22] = "M"
    
    -- Warp Pipes: [P]=left, [Q]=right
    -- Pipe 1 (height 2) at x=28
    levelGrid[12][28] = "p"; levelGrid[12][29] = "q"
    levelGrid[13][28] = "P"; levelGrid[13][29] = "Q"
    
    -- Pipe 2 (height 3) at x=38
    levelGrid[11][38] = "p"; levelGrid[11][39] = "q"
    levelGrid[12][38] = "P"; levelGrid[12][39] = "Q"
    levelGrid[13][38] = "P"; levelGrid[13][39] = "Q"
    
    -- Pipe 3 (height 4) at x=46
    levelGrid[10][46] = "p"; levelGrid[10][47] = "q"
    levelGrid[11][46] = "P"; levelGrid[11][47] = "Q"
    levelGrid[12][46] = "P"; levelGrid[12][47] = "Q"
    levelGrid[13][46] = "P"; levelGrid[13][47] = "Q"
    
    -- Pipe 4 at x=57
    levelGrid[10][57] = "p"; levelGrid[10][58] = "q"
    levelGrid[11][57] = "P"; levelGrid[11][58] = "Q"
    levelGrid[12][57] = "P"; levelGrid[12][58] = "Q"
    levelGrid[13][57] = "P"; levelGrid[13][58] = "Q"
    
    -- Brick row at x=77..83, y=10
    for bx = 77, 83 do
        levelGrid[10][bx] = (bx == 78) and "?" or "B"
    end
    -- High Bricks at x=80..87, y=6
    for bx = 80, 87 do levelGrid[6][bx] = "B" end
    
    -- Double row bricks at x=91..98
    for bx = 91, 98 do
        levelGrid[10][bx] = "B"
        levelGrid[6][bx] = (bx == 94) and "?" or "B"
    end
    
    -- Stairs at x=134..137
    for st = 1, 4 do
        for sy = 1, st do levelGrid[14 - sy][133 + st] = "B" end
    end
    -- Reverse Stairs at x=140..143
    for st = 1, 4 do
        for sy = 1, (5 - st) do levelGrid[14 - sy][139 + st] = "B" end
    end
    
    -- Final Giant Staircase at x=181..188
    for st = 1, 8 do
        for sy = 1, st do levelGrid[14 - sy][180 + st] = "B" end
    end
    
    -- Flagpole at x=198
    for fy = 3, 13 do levelGrid[fy][198] = "F" end
    levelGrid[3][198] = "f" -- Gold Top
    levelGrid[13][197] = "B"; levelGrid[13][198] = "B"
    
    -- Castle at x=202..208
    for cy = 9, 13 do
        for cx = 202, 208 do levelGrid[cy][cx] = "C" end
    end
    levelGrid[12][205] = "D"; levelGrid[13][205] = "D" -- Castle Door
    
    -- Enemies (Goombas & Koopas)
    enemies = {
        { type = "goomba", x = 22, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "goomba", x = 41, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "goomba", x = 51, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "goomba", x = 53, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "koopa",  x = 82, y = 12, vx = -0.10, vy = 0, isAlive = true, isShell = false },
        { type = "goomba", x = 97, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "goomba", x = 99, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "goomba", x = 115, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 },
        { type = "koopa",  x = 124, y = 12, vx = -0.10, vy = 0, isAlive = true, isShell = false },
        { type = "goomba", x = 174, y = 12, vx = -0.08, vy = 0, isAlive = true, flatTimer = 0 }
    }
    
    items = {}
    particles = {}
end

local function resetMario(fullReset)
    mario.x = 4
    mario.y = 12
    mario.vx = 0
    mario.vy = 0
    mario.isGrounded = true
    mario.isDead = false
    mario.deathTimer = 0
    mario.invincibleTimer = 30
    cameraX = 0
    if fullReset then
        mario.power = 1
    end
end

-- ============================================================================
-- COLLISION & BLOCK HIT
-- ============================================================================
local function isSolid(tx, ty)
    tx = math.floor(tx)
    ty = math.floor(ty)
    if tx < 1 or tx > LEVEL_WIDTH or ty < 1 or ty > LEVEL_HEIGHT then return false end
    local t = levelGrid[ty][tx]
    return (t == "G" or t == "#" or t == "B" or t == "?" or t == "M" or t == "X" or t == "P" or t == "Q" or t == "p" or t == "q" or t == "C")
end

local function hitBlock(tx, ty)
    tx = math.floor(tx)
    ty = math.floor(ty)
    if tx < 1 or tx > LEVEL_WIDTH or ty < 1 or ty > LEVEL_HEIGHT then return end
    local t = levelGrid[ty][tx]
    
    if t == "?" then
        levelGrid[ty][tx] = "X"
        coins = coins + 1
        score = score + 200
        table.insert(particles, { x = tx, y = ty - 1, text = "+200", color = "yellow", vy = -0.4, life = 12 })
        playSound("coin")
    elseif t == "M" then
        levelGrid[ty][tx] = "X"
        table.insert(items, { type = "mushroom", x = tx, y = ty - 1, vx = 0.12, vy = -0.2 })
        playSound("powerup")
    elseif t == "B" then
        if mario.power > 1 then
            levelGrid[ty][tx] = " "
            score = score + 50
            table.insert(particles, { x = tx, y = ty, text = "#", color = "brown", vy = -0.5, life = 10 })
            playSound("bump")
        else
            playSound("bump")
        end
    end
end

-- ============================================================================
-- RESPONSIVE GAME UPDATE LOOP
-- ============================================================================
local function updateGame()
    if isPaused or isGameOver or isGameWon then return end
    
    gameTick = gameTick + 1
    if gameTick % 20 == 0 and gameTime > 0 then
        gameTime = gameTime - 1
        if gameTime == 0 then mario.isDead = true end
    end
    
    -- Mario Death Animation
    if mario.isDead then
        mario.deathTimer = mario.deathTimer + 1
        mario.y = mario.y + mario.vy
        mario.vy = mario.vy + 0.15
        if mario.deathTimer == 1 then
            mario.vy = -0.9
            playSound("die")
        end
        if mario.deathTimer > 35 then
            lives = lives - 1
            if lives <= 0 then
                isGameOver = true
            else
                initLevel()
                resetMario(true)
            end
        end
        return
    end
    
    if mario.invincibleTimer > 0 then
        mario.invincibleTimer = mario.invincibleTimer - 1
    end
    
    -- Direct & Responsive Horizontal Movement
    local moveSpeed = (keysHeld.run) and 0.45 or 0.30
    if keysHeld.left then
        mario.vx = -moveSpeed
        mario.facing = -1
        mario.walkFrame = mario.walkFrame + 1
    elseif keysHeld.right then
        mario.vx = moveSpeed
        mario.facing = 1
        mario.walkFrame = mario.walkFrame + 1
    else
        mario.vx = 0
    end
    
    -- Apply Horizontal Velocity & Collision
    local nextX = mario.x + mario.vx
    if not isSolid(nextX + (mario.vx > 0 and 1.2 or 0.2), mario.y + 0.5) and
       not isSolid(nextX + (mario.vx > 0 and 1.2 or 0.2), mario.y + 1.5) then
        mario.x = math.max(1, nextX)
    else
        mario.vx = 0
    end
    
    -- Gravity & Vertical Movement
    mario.vy = math.min(0.85, mario.vy + 0.12) -- Smooth gravity
    local nextY = mario.y + mario.vy
    
    -- Floor / Ground Collision
    if mario.vy > 0 and (isSolid(mario.x + 0.3, nextY + 1.9) or isSolid(mario.x + 1.1, nextY + 1.9)) then
        mario.y = math.floor(nextY + 1.9) - 2
        mario.vy = 0
        mario.isGrounded = true
    else
        mario.isGrounded = false
        mario.y = nextY
    end
    
    -- Jump Trigger
    if keysHeld.jump and mario.isGrounded then
        mario.vy = -0.92
        mario.isGrounded = false
        playSound("jump")
        keysHeld.jump = false -- Instant trigger
    end
    
    -- Ceiling Collision (Head hitting blocks)
    if mario.vy < 0 and (isSolid(mario.x + 0.4, mario.y - 0.2) or isSolid(mario.x + 1.0, mario.y - 0.2)) then
        local hitBlockX = math.floor(mario.x + 0.7)
        local hitBlockY = math.floor(mario.y - 0.2)
        hitBlock(hitBlockX, hitBlockY)
        mario.vy = 0.1
    end
    
    -- Pit Fall Death
    if mario.y > LEVEL_HEIGHT + 1 then
        mario.isDead = true
        mario.deathTimer = 0
    end
    
    -- Flagpole Win
    if mario.x >= 197 and not isGameWon then
        isGameWon = true
        score = score + 5000 + (gameTime * 50)
        playSound("win")
    end
    
    -- Camera Follows Mario
    cameraX = math.max(0, math.min(LEVEL_WIDTH - 50, math.floor(mario.x - 14)))
    
    -- Update Enemies
    for _, e in ipairs(enemies) do
        if e.isAlive and math.abs(e.x - mario.x) < 45 then
            if e.flatTimer and e.flatTimer > 0 then
                e.flatTimer = e.flatTimer - 1
                if e.flatTimer <= 0 then e.isAlive = false end
            else
                e.x = e.x + e.vx
                if isSolid(e.x + (e.vx > 0 and 1.5 or 0.1), e.y + 0.5) then
                    e.vx = -e.vx
                end
                
                -- Mario vs Enemy Collision
                if not mario.isDead and math.abs(mario.x - e.x) < 1.4 and math.abs(mario.y - e.y) < 1.4 then
                    if mario.vy > 0 and (mario.y < e.y) then
                        -- Stomp enemy!
                        playSound("stomp")
                        mario.vy = -0.7 -- Bounce
                        score = score + 100
                        table.insert(particles, { x = e.x, y = e.y, text = "+100", color = "yellow", vy = -0.4, life = 12 })
                        if e.type == "koopa" and not e.isShell then
                            e.isShell = true
                            e.vx = 0
                        else
                            e.flatTimer = 15 -- Flatten goomba
                        end
                    elseif e.isShell and e.vx == 0 then
                        -- Kick shell
                        e.vx = (mario.facing == 1) and 0.5 or -0.5
                        playSound("stomp")
                    elseif mario.invincibleTimer == 0 then
                        -- Mario hurt
                        if mario.power > 1 then
                            mario.power = 1
                            mario.invincibleTimer = 40
                            playSound("stomp")
                        else
                            mario.isDead = true
                            mario.deathTimer = 0
                        end
                    end
                end
            end
        end
    end
    
    -- Update Items (Mushrooms)
    for idx = #items, 1, -1 do
        local it = items[idx]
        it.x = it.x + it.vx
        it.y = it.y + it.vy
        it.vy = math.min(0.6, it.vy + 0.1)
        if isSolid(it.x + 0.5, it.y + 1.8) then
            it.y = math.floor(it.y + 1.8) - 2
            it.vy = 0
        end
        if isSolid(it.x + (it.vx > 0 and 1.5 or 0.1), it.y + 0.5) then
            it.vx = -it.vx
        end
        if math.abs(mario.x - it.x) < 1.4 and math.abs(mario.y - it.y) < 1.4 then
            mario.power = 2
            score = score + 1000
            table.insert(particles, { x = it.x, y = it.y, text = "SUPER!", color = "yellow", vy = -0.4, life = 15 })
            playSound("powerup")
            table.remove(items, idx)
        end
    end
    
    -- Update Particles
    for idx = #particles, 1, -1 do
        local p = particles[idx]
        p.y = p.y + p.vy
        p.life = p.life - 1
        if p.life <= 0 then table.remove(particles, idx) end
    end
end

-- ============================================================================
-- 2x3 SUBPIXEL TELETEXT RENDERER
-- ============================================================================
local function renderGame()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.lightBlue)
    display.clear()
    
    -- 1. Top Retro Header HUD
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    local hud = string.format(" MARIO %06d   COINS x%02d   WORLD 1-1   TIME %03d   LIVES x%d ", score, coins, gameTime, lives)
    display.setCursorPos(math.max(1, math.floor((screenW - #hud) / 2)), 1)
    display.setTextColor(colors.yellow)
    display.write(hud)
    
    -- 2. Draw World Background & Tiles (Extended Ground)
    local startX = cameraX + 1
    local endX = math.min(LEVEL_WIDTH, startX + screenW - 1)
    local groundFillTo = math.max(LEVEL_HEIGHT, screenH - 4)
    
    for y = 2, groundFillTo do
        local chStr = ""
        local fgStr = ""
        local bgStr = ""
        
        for x = startX, endX do
            local t = " "
            if y <= LEVEL_HEIGHT then
                t = levelGrid[y][x]
            else
                -- Extend dirt downwards unless it's a pit
                local isPit = (x >= 69 and x <= 71) or (x >= 86 and x <= 88) or (x >= 153 and x <= 155)
                t = isPit and " " or "#"
            end
            
            if t == "G" then
                -- Green grass top layer
                chStr = chStr .. "\140"
                fgStr = fgStr .. "5"
                bgStr = bgStr .. "c"
            elseif t == "#" then
                -- Brown dirt ground
                chStr = chStr .. "\159"
                fgStr = fgStr .. "c"
                bgStr = bgStr .. "f"
            elseif t == "B" then
                -- Brick block
                chStr = chStr .. "\149"
                fgStr = fgStr .. "0"
                bgStr = bgStr .. "c"
            elseif t == "?" or t == "M" then
                -- Glowing Question Mark Mystery Block
                local glow = (math.floor(gameTick / 4) % 2 == 0)
                chStr = chStr .. "?"
                fgStr = fgStr .. (glow and "0" or "e")
                bgStr = bgStr .. "1"
            elseif t == "X" then
                -- Empty Block
                chStr = chStr .. "\131"
                fgStr = fgStr .. "7"
                bgStr = bgStr .. "8"
            elseif t == "P" or t == "Q" then
                -- Green Pipe Stem
                chStr = chStr .. "|"
                fgStr = fgStr .. "5"
                bgStr = bgStr .. "d"
            elseif t == "p" or t == "q" then
                -- Green Pipe Lip Top
                chStr = chStr .. "="
                fgStr = fgStr .. "0"
                bgStr = bgStr .. "5"
            elseif t == "F" or t == "f" then
                -- Flagpole
                chStr = chStr .. "|"
                fgStr = fgStr .. "4"
                bgStr = bgStr .. "3"
            elseif t == "C" then
                -- Castle stone
                chStr = chStr .. "\159"
                fgStr = fgStr .. "7"
                bgStr = bgStr .. "8"
            elseif t == "D" then
                -- Castle door
                chStr = chStr .. " "
                fgStr = fgStr .. "f"
                bgStr = bgStr .. "f"
            elseif t == "W" then
                -- Cloud
                chStr = chStr .. "@"
                fgStr = fgStr .. "0"
                bgStr = bgStr .. "3"
            else
                -- Sky
                chStr = chStr .. " "
                fgStr = fgStr .. "3"
                bgStr = bgStr .. "3"
            end
        end
        
        display.setCursorPos(1, y)
        pcall(function() display.blit(chStr, fgStr, bgStr) end)
    end
    
    -- 3. Draw Items (Mushrooms)
    for _, it in ipairs(items) do
        local sx = math.floor(it.x - cameraX)
        local sy = math.floor(it.y)
        if sx >= 1 and sx <= screenW - 1 and sy >= 2 and sy <= screenH - 5 then
            for row = 1, 2 do
                display.setCursorPos(sx, sy + row - 1)
                pcall(function() display.blit(SPRITE_MUSHROOM[row].ch, SPRITE_MUSHROOM[row].fg, SPRITE_MUSHROOM[row].bg) end)
            end
        end
    end
    
    -- 4. Draw Enemies (Goombas & Koopas)
    for _, e in ipairs(enemies) do
        if e.isAlive then
            local sx = math.floor(e.x - cameraX)
            local sy = math.floor(e.y)
            if sx >= 1 and sx <= screenW - 1 and sy >= 2 and sy <= screenH - 5 then
                local spr = SPRITE_GOOMBA_1
                if e.flatTimer and e.flatTimer > 0 then
                    spr = SPRITE_GOOMBA_FLAT
                elseif e.type == "goomba" then
                    spr = (math.floor(gameTick / 4) % 2 == 0) and SPRITE_GOOMBA_1 or SPRITE_GOOMBA_2
                elseif e.isShell then
                    spr = SPRITE_KOOPA_SHELL
                else
                    spr = SPRITE_KOOPA
                end
                for row = 1, 2 do
                    display.setCursorPos(sx, sy + row - 1)
                    pcall(function() display.blit(spr[row].ch, spr[row].fg, spr[row].bg) end)
                end
            end
        end
    end
    
    -- 5. Draw Mario (Pixel-Art Subpixel Sprite)
    if not mario.isDead or (mario.isDead and mario.deathTimer % 4 < 2) then
        local sx = math.floor(mario.x - cameraX)
        local sy = math.floor(mario.y)
        local isFlicker = (mario.invincibleTimer > 0 and (gameTick % 4 < 2))
        
        if not isFlicker and sx >= 1 and sx <= screenW - 1 and sy >= 2 and sy <= screenH - 5 then
            local spr = SPRITE_MARIO_STAND_R
            if not mario.isGrounded then
                spr = (mario.facing == 1) and SPRITE_MARIO_JUMP_R or SPRITE_MARIO_JUMP_L
            elseif math.abs(mario.vx) > 0.05 then
                local frame = (math.floor(mario.walkFrame / 2) % 2)
                if mario.facing == 1 then
                    spr = (frame == 0) and SPRITE_MARIO_WALK_R or SPRITE_MARIO_STAND_R
                else
                    spr = (frame == 0) and SPRITE_MARIO_WALK_L or SPRITE_MARIO_STAND_L
                end
            else
                spr = (mario.facing == 1) and SPRITE_MARIO_STAND_R or SPRITE_MARIO_STAND_L
            end
            
            for row = 1, 2 do
                display.setCursorPos(sx, sy + row - 1)
                pcall(function() display.blit(spr[row].ch, spr[row].fg, spr[row].bg) end)
            end
        end
    end
    
    -- 6. Draw Score Particles
    for _, p in ipairs(particles) do
        local sx = math.floor(p.x - cameraX)
        local sy = math.floor(p.y)
        if sx >= 1 and sx <= screenW and sy >= 2 and sy <= screenH - 4 then
            display.setCursorPos(sx, sy)
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors[p.color] or colors.yellow)
            display.write(p.text)
        end
    end
    
    -- 7. Centered Higher Arcade Touch Control Panel
    local ctrlY = screenH - 2
    
    -- Control Bar Background Frame
    for cy = ctrlY - 1, screenH do
        display.setCursorPos(1, cy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", screenW))
    end
    
    local btnW_Left = 12
    local btnW_Right = 12
    local btnW_Jump = 16
    local btnW_Run = 13
    local btnW_Pause = 9
    local btnW_Quit = 8
    local gap = 2
    
    local totalW = btnW_Left + gap + btnW_Right + gap + btnW_Jump + gap + btnW_Run + gap + btnW_Pause + gap + btnW_Quit
    local startBtnX = math.max(2, math.floor((screenW - totalW) / 2))
    
    local curX = startBtnX
    registerButton("BTN_LEFT", curX, ctrlY, btnW_Left, 2, " [ < LEFT ] ", keysHeld.left and "yellow" or "white", keysHeld.left and "blue" or "black")
    curX = curX + btnW_Left + gap
    
    registerButton("BTN_RIGHT", curX, ctrlY, btnW_Right, 2, " [ RIGHT > ] ", keysHeld.right and "yellow" or "white", keysHeld.right and "blue" or "black")
    curX = curX + btnW_Right + gap
    
    registerButton("BTN_JUMP", curX, ctrlY, btnW_Jump, 2, " [ JUMP / W ] ", "yellow", "red")
    curX = curX + btnW_Jump + gap
    
    registerButton("BTN_RUN", curX, ctrlY, btnW_Run, 2, " [ RUN / F ] ", keysHeld.run and "lime" or "white", keysHeld.run and "green" or "black")
    curX = curX + btnW_Run + gap
    
    registerButton("BTN_PAUSE", curX, ctrlY, btnW_Pause, 2, isPaused and " [ > ] " or " [ || ] ", "yellow", "black")
    curX = curX + btnW_Pause + gap
    
    registerButton("BTN_EXIT", curX, ctrlY, btnW_Quit, 2, " [ Q ] ", "white", "red")
    
    -- Overlays for Game Over / Win
    if isGameWon then
        display.setCursorPos(math.floor(screenW / 2) - 11, math.floor(screenH / 2) - 1)
        display.setBackgroundColor(colors.yellow)
        display.setTextColor(colors.red)
        display.write(" *** STAGE CLEAR! *** ")
        display.setCursorPos(math.floor(screenW / 2) - 11, math.floor(screenH / 2))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        display.write(" THANK YOU MARIO! [R] ")
    elseif isGameOver then
        display.setCursorPos(math.floor(screenW / 2) - 9, math.floor(screenH / 2) - 1)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" === GAME OVER === ")
        display.setCursorPos(math.floor(screenW / 2) - 9, math.floor(screenH / 2))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(" PRESS [R] TO RETRY ")
    elseif isPaused then
        display.setCursorPos(math.floor(screenW / 2) - 6, math.floor(screenH / 2))
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(" [ PAUSED ] ")
    end
    
    drawButtons()
end

local function main()
    initLevel()
    resetMario(true)
    
    local timerId = os.startTimer(0.05) -- Fast 20 FPS Game Engine
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.05)
            updateGame()
            renderGame()
            
        -- Keyboard Down
        elseif event == "key" then
            if p1 == keys.left or p1 == keys.a then
                keysHeld.left = true
            elseif p1 == keys.right or p1 == keys.d then
                keysHeld.right = true
            elseif p1 == keys.up or p1 == keys.w or p1 == keys.space then
                keysHeld.jump = true
            elseif p1 == keys.f or p1 == keys.leftShift then
                keysHeld.run = true
            elseif p1 == keys.r then
                score = 0; coins = 0; lives = 3; gameTime = 300
                isGameOver = false; isGameWon = false
                initLevel(); resetMario(true)
            elseif p1 == keys.p then
                isPaused = not isPaused
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        -- Keyboard Up (Release key)
        elseif event == "key_up" then
            if p1 == keys.left or p1 == keys.a then
                keysHeld.left = false
            elseif p1 == keys.right or p1 == keys.d then
                keysHeld.right = false
            elseif p1 == keys.up or p1 == keys.w or p1 == keys.space then
                keysHeld.jump = false
            elseif p1 == keys.f or p1 == keys.leftShift then
                keysHeld.run = false
            end
            
        -- Monitor Touch or Mouse Click
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_LEFT" then
                keysHeld.left = true
                keysHeld.right = false
            elseif cid == "BTN_RIGHT" then
                keysHeld.right = true
                keysHeld.left = false
            elseif cid == "BTN_JUMP" then
                keysHeld.jump = true
            elseif cid == "BTN_RUN" then
                keysHeld.run = not keysHeld.run
            elseif cid == "BTN_PAUSE" then
                isPaused = not isPaused
            elseif cid == "BTN_EXIT" then
                break
            else
                -- Screen Tap Controls: Left Half = Walk Left, Right Half = Walk Right, Top Half = Jump
                local screenW, screenH = display.getSize()
                if my < screenH - 4 then
                    if my < math.floor(screenH * 0.4) then
                        keysHeld.jump = true
                    elseif mx < math.floor(screenW / 2) then
                        keysHeld.left = true
                        keysHeld.right = false
                    else
                        keysHeld.right = true
                        keysHeld.left = false
                    end
                end
            end
            
        elseif event == "mouse_up" then
            keysHeld.left = false
            keysHeld.right = false
            keysHeld.jump = false
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Super Mario closed.")
    else
        print("Super Mario closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Mario Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Mario Error: " .. tostring(err))
end
