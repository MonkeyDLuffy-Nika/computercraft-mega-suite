-- ============================================================================
-- CYBER TELEVISION ULTRA HD (15 LIVE ANIMATED CHANNELS)
-- ComputerCraft / CC: Tweaked - Subpixel Teletext & 60FPS Animation Engine
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

-- TV State
local currentChannel = 1
local totalChannels = 15
local animTick = 0
local osdTimer = 0
local isMuted = false
local showGuide = false
local showSubtitles = true
local isStaticSwitch = 0
local volume = 1.0

-- Custom 16-Color TrueColor Palette for Vibrant TV
local TV_PALETTE = {
    [colors.white]     = 0xFFFFFF,
    [colors.orange]    = 0xFF961E,
    [colors.magenta]   = 0xEB4BBE,
    [colors.lightBlue] = 0x64B4FF,
    [colors.yellow]    = 0xFFEB28,
    [colors.lime]      = 0x5AEB28,
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x3C3C46,
    [colors.lightGray] = 0xAAAFB9,
    [colors.cyan]      = 0x1ED2DC,
    [colors.purple]    = 0xA03CEB,
    [colors.blue]      = 0x285FEB,
    [colors.brown]     = 0x8C552D,
    [colors.green]     = 0x2DA537,
    [colors.red]       = 0xEB2D2D,
    [colors.black]     = 0x08080C
}

local function applyPalette()
    if display.setPaletteColor then
        for col, hexVal in pairs(TV_PALETTE) do
            pcall(function() display.setPaletteColor(col, hexVal) end)
        end
    end
end
applyPalette()

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
        display.setCursorPos(btn.x1, btn.y1)
        display.setBackgroundColor(colors[btn.bg] or colors.gray)
        display.setTextColor(colors[btn.fg] or colors.white)
        display.write(btn.label)
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

-- Channel Metadata (15 Channels)
local CHANNELS = {
    [1] = {
        num = 1, code = "NNN", name = "Neon News 24/7", genre = "Live Cyber News",
        desc = "Breaking news, stock tickers, anchor broadcast",
        subtitles = { "BREAKING: Megacorp Cybernet reaches 10T market cap!", "TRAFFIC: Flying cars congestion on Skyway 9", "WEATHER: Acid rain expected in Sector 4", "SECURITY: AI firewall upgrade completed successfully" }
    },
    [2] = {
        num = 2, code = "WAVE", name = "Synthwave 90s Music", genre = "Retro Electro Hits",
        desc = "Horizon wireframe grid, sunset & spectrum audio bars",
        subtitles = { "[MUSIC] Playing: 'Midnight Cruiser' by Neon Drive", "[BEAT] 128 BPM // Synth Lead Solo", "[TRACK] Next: 'Cyber Sunset 1984'" }
    },
    [3] = {
        num = 3, code = "DISC", name = "Space Discovery 4K", genre = "Astronomy & Cosmos",
        desc = "Rotating 3D planet, orbiting satellite & starfields",
        subtitles = { "NARRATOR: Orbiting the ringed gas giant Kepler-452", "Telemetry: Orbit Altitude 42,000 km", "Solar flare detected at coordinates 14.2 // 89.0" }
    },
    [4] = {
        num = 4, code = "TOON", name = "Sakura Anime TV", genre = "Anime & Animation",
        desc = "Animated anime catgirl with falling cherry blossom petals",
        subtitles = { "NYA~ Welcome to Sakura City!", "Don't forget to like and subscribe senpai!", "Next episode: The Cyber Mage Academy starts soon!" }
    },
    [5] = {
        num = 5, code = "RACE", name = "Cyber Grand Prix", genre = "Formula Cyber Racing",
        desc = "High-speed highway scrolling road & passing race cars",
        subtitles = { "COMMENTATOR: Car #7 makes a daring overtake at 340 km/h!", "Lap 42/50 // Red Cyber-Fox leads by 1.2s!", "PIT STOP: Turbo battery swap in 2.1s" }
    },
    [6] = {
        num = 6, code = "MTRX", name = "Matrix Hacker TV", genre = "Cyberpunk / Tech",
        desc = "Cascading green digital rain code & cyber skull",
        subtitles = { "> INTRUSION DETECTED IN NODE 0x7FA", "> BYPASSING MAINFRAME ENCRYPTION...", "> ACCESS GRANTED. WELCOME TO THE MATRIX." }
    },
    [7] = {
        num = 7, code = "ARCD", name = "Retro Pixel Arcade", genre = "8-Bit Gaming Classics",
        desc = "Animated Pac-Man eating dots in a maze with ghosts",
        subtitles = { "[GAME] HIGH SCORE: 999,990", "[PAC-MAN] Waka waka waka!", "[BONUS] Cherry +100 PTS! Ghost Power-Pellet Active!" }
    },
    [8] = {
        num = 8, code = "AQUA", name = "Ocean Aquarium Relax", genre = "Deep Sea Ambient",
        desc = "Lush blue aquarium with swimming fish & rising bubbles",
        subtitles = { "Deep sea ambient sounds (120m depth)", "Tropical neon jellyfish drifting peacefully", "Coral reef bioluminescence active" }
    },
    [9] = {
        num = 9, code = "SHOP", name = "Cyber Shop 24", genre = "Tele-Shopping & Deals",
        desc = "Rotating 3D diamond sword & limited special offers",
        subtitles = { "ONLY 99.99 DIAMONDS! CALL NOW 555-CYBER!", "HOT DEAL: Quantum Blaster with Free Battery!", "LIMITED TIME: Only 4 items left in stock!" }
    },
    [10] = {
        num = 10, code = "TEST", name = "SMPTE Test & Emergency", genre = "Emergency Broadcast",
        desc = "SMPTE TV Color bars & continuous 1kHz tone",
        subtitles = { "THIS IS A TEST OF THE EMERGENCY BROADCAST SYSTEM", "STANDBY FOR REGULAR PROGRAMMING", "FREQUENCY: 104.5 MHz // SIGNAL STRENGTH: 99%" }
    },
    [11] = {
        num = 11, code = "HYPN", name = "Hypnotic Cyber Vortex", genre = "Visual Trips / Optical",
        desc = "Trippy rotating concentric 3D neon portal vortex",
        subtitles = { "FOCUS ON THE CENTER... RELAX YOUR MIND...", "Entering quantum hyperspace dimension...", "Visual frequency: 60 Hz alpha waves" }
    },
    [12] = {
        num = 12, code = "RAVE", name = "Cyber Rave 2077", genre = "Club & EDM Beats",
        desc = "Animated silhouette dancers, strobes & disco tiles",
        subtitles = { "[CLUB] DJ Cyber-Nova Live from Tokyo Dome!", "Drop in 3... 2... 1... BASS BOOST!", "Neon lasers firing at full power!" }
    },
    [13] = {
        num = 13, code = "CAMP", name = "Cozy Campfire 4K", genre = "Nature & Ambient Relax",
        desc = "Flickering burning wood fire with flying embers & stars",
        subtitles = { "Gentle wood crackling by the mountain lake", "Northern lights visible over the pine forest", "Temperature: 18C // Calm night breeze" }
    },
    [14] = {
        num = 14, code = "RAIN", name = "Neo-Tokyo Rainy Alley", genre = "Lo-Fi Aesthetic Mood",
        desc = "Animated rain drops, puddle ripples & glowing neon signs",
        subtitles = { "Midnight rain falling over Shibuya sector", "[LO-FI] Beats to study and hack to", "Ramen shop open 24 hours" }
    },
    [15] = {
        num = 15, code = "CAT",  name = "Bongo Cat Live TV", genre = "Cute Internet Memes",
        desc = "Animated Bongo Cat playing keyboard & bongos in sync",
        subtitles = { "*paw tap* *paw tap* Bongo time!", "Playing the synth solo with both paws!", "10,000,000 live viewers jamming together!" }
    }
}

-- Audio Synthesizer for all 15 channels
local function playChannelSound()
    if isMuted or not speaker then return end
    pcall(function()
        if currentChannel == 1 then
            if animTick % 20 == 0 then speaker.playNote("snare", 0.3 * volume, 10) end
        elseif currentChannel == 2 then
            local notes = { 8, 10, 12, 15, 12, 10, 8, 5 }
            local n = notes[(animTick % #notes) + 1]
            speaker.playNote("bit", 0.4 * volume, n)
        elseif currentChannel == 3 then
            if animTick % 30 == 0 then speaker.playNote("flute", 0.3 * volume, 14) end
        elseif currentChannel == 4 then
            if animTick % 12 == 0 then speaker.playNote("chime", 0.4 * volume, (animTick % 2 == 0) and 18 or 22) end
        elseif currentChannel == 5 then
            if animTick % 6 == 0 then speaker.playNote("bass", 0.4 * volume, (animTick % 4) + 1) end
        elseif currentChannel == 6 then
            if animTick % 10 == 0 then speaker.playNote("hat", 0.3 * volume, 20) end
        elseif currentChannel == 7 then
            local arcadeNotes = { 12, 16, 19, 24, 19, 16 }
            local an = arcadeNotes[(animTick % #arcadeNotes) + 1]
            speaker.playNote("bit", 0.5 * volume, an)
        elseif currentChannel == 8 then
            if animTick % 25 == 0 then speaker.playNote("bell", 0.3 * volume, 12) end
        elseif currentChannel == 9 then
            if animTick % 16 == 0 then speaker.playNote("harp", 0.4 * volume, 16) end
        elseif currentChannel == 10 then
            if animTick % 15 == 0 then speaker.playNote("iron_xylophone", 0.2 * volume, 10) end
        elseif currentChannel == 11 then
            local hypnoNotes = { 4, 7, 11, 14, 18, 21, 18, 14, 11, 7 }
            speaker.playNote("chime", 0.3 * volume, hypnoNotes[(animTick % #hypnoNotes) + 1])
        elseif currentChannel == 12 then
            if animTick % 4 == 0 then speaker.playNote("bass", 0.6 * volume, 1) end
            if animTick % 8 == 4 then speaker.playNote("snare", 0.4 * volume, 12) end
            if animTick % 2 == 1 then speaker.playNote("hat", 0.2 * volume, 18) end
        elseif currentChannel == 13 then
            if animTick % 18 == 0 then speaker.playNote("hat", 0.2 * volume, math.random(8, 14)) end
        elseif currentChannel == 14 then
            if animTick % 14 == 0 then speaker.playNote("flute", 0.2 * volume, 8) end
        elseif currentChannel == 15 then
            local bongoPitch = (animTick % 2 == 0) and 14 or 18
            speaker.playNote("bit", 0.5 * volume, bongoPitch)
        end
    end)
end

local function switchChannel(newCh)
    if newCh < 1 then newCh = totalChannels end
    if newCh > totalChannels then newCh = 1 end
    currentChannel = newCh
    isStaticSwitch = 3
    osdTimer = 25
    showGuide = false
    if speaker and not isMuted then
        pcall(function()
            speaker.playNote("hat", 0.6 * volume, 12)
            speaker.playNote("snare", 0.4 * volume, 8)
        end)
    end
end

-- ============================================================================
-- CHANNEL ANIMATION ENGINES (15 CHANNELS)
-- ============================================================================

-- Channel 1: Neon News Network (Anchor + Moving News Ticker)
local function drawChannel1(w, h)
    display.setBackgroundColor(colors.blue)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local winW = math.floor((w - 4) / 2)
    for y = 3, math.floor(h * 0.6) do
        display.setCursorPos(3, y)
        display.setBackgroundColor(colors.black)
        local winRow = ""
        for x = 1, winW do
            if (x + y + animTick) % 4 == 0 then winRow = winRow .. "." else winRow = winRow .. " " end
        end
        display.setTextColor(colors.cyan)
        display.write(winRow)
    end
    
    local deskY = math.floor(h * 0.65)
    local midX = math.floor(w / 2)
    
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.pink)
    display.setCursorPos(midX - 2, deskY - 3)
    display.write(" (o.o) ")
    display.setCursorPos(midX - 3, deskY - 2)
    display.setTextColor(colors.white)
    display.write(" [===] ")
    display.setCursorPos(midX - 4, deskY - 1)
    display.setTextColor(colors.lightGray)
    display.write("  /| |\\  ")
    
    display.setCursorPos(midX + 4, deskY - 1)
    display.setTextColor(colors.yellow)
    display.write("8-o")
    
    for dy = deskY, h - 3 do
        display.setCursorPos(4, dy)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.cyan)
        display.write("=" .. string.rep("#", w - 10) .. "=")
    end
    display.setCursorPos(midX - 8, deskY)
    display.setTextColor(colors.yellow)
    display.write(" [ NNN NEWS 24 ] ")
    
    display.setCursorPos(w - 12, 3)
    display.setBackgroundColor((animTick % 10 < 5) and colors.red or colors.gray)
    display.setTextColor(colors.white)
    display.write(" * LIVE * ")
    
    local tickerMsg = "  +++ BREAKING: Cyberpunk Metropolis inaugurates new Skyway-9 +++ Global stock market surges +3.4% +++ Weather: Clean skies in Sector 7 +++ Neon Network 24/7 +++  "
    local offset = (animTick * 2) % #tickerMsg
    local tickerStr = string.sub(tickerMsg, offset + 1) .. string.sub(tickerMsg, 1, offset)
    display.setCursorPos(2, h - 2)
    display.setBackgroundColor(colors.red)
    display.setTextColor(colors.yellow)
    display.write("NEWS| " .. string.sub(tickerStr, 1, w - 8))
end

-- Channel 2: Synthwave 90s Music
local function drawChannel2(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local horizonY = math.floor(h * 0.55)
    local midX = math.floor(w / 2)
    
    local sunRadius = math.min(5, math.floor(h * 0.25))
    for sy = -sunRadius, 0 do
        local rWidth = math.floor(math.sqrt(sunRadius*sunRadius - sy*sy) * 2.2)
        local sx = midX - math.floor(rWidth / 2)
        local drawY = horizonY + sy - 1
        if drawY >= 3 and (sy % 2 == 0 or sy == -sunRadius) then
            display.setCursorPos(sx, drawY)
            display.setBackgroundColor((sy < -2) and colors.yellow or colors.orange)
            display.write(string.rep(" ", rWidth))
        end
    end
    
    local scrollFloor = (animTick % 3)
    for y = horizonY, h - 3 do
        display.setCursorPos(2, y)
        display.setBackgroundColor(colors.black)
        local depth = (y - horizonY + 1)
        local isLine = ((y + scrollFloor) % 2 == 0)
        display.setTextColor(isLine and colors.magenta or colors.purple)
        
        local gridRow = ""
        for x = 2, w - 2 do
            local dx = x - midX
            if dx % math.max(2, math.floor(8 - depth * 0.8)) == 0 or isLine then
                gridRow = gridRow .. (isLine and "=" or "|")
            else
                gridRow = gridRow .. " "
            end
        end
        display.write(gridRow)
    end
    
    local numBars = math.min(14, math.floor((w - 8) / 3))
    local bStartX = midX - math.floor(numBars * 1.5)
    for b = 1, numBars do
        local freq = math.abs(math.sin((b * 0.6) + (animTick * 0.4))) * 5 + 1
        local barHeight = math.floor(freq)
        local bx = bStartX + (b - 1) * 3
        for bh = 1, barHeight do
            local by = horizonY - 1 - bh
            if by >= 3 then
                display.setCursorPos(bx, by)
                display.setBackgroundColor((bh > 4) and colors.cyan or ((bh > 2) and colors.lime or colors.magenta))
                display.write("  ")
            end
        end
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.purple)
    display.setTextColor(colors.yellow)
    display.write(" SYNTHWAVE MTV ")
end

-- Channel 3: Space Discovery 4K
local function drawChannel3(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    display.setTextColor(colors.white)
    for s = 1, 20 do
        local sx = 2 + ((s * 17 + animTick * 2) % (w - 4))
        local sy = 2 + ((s * 23) % (h - 4))
        display.setCursorPos(sx, sy)
        display.write((s % 3 == 0) and "+" or ".")
    end
    
    local pr = math.min(6, math.floor(h * 0.35))
    for py = -pr, pr do
        local rW = math.floor(math.sqrt(math.max(0, pr*pr - py*py)) * 2.2)
        local px = midX - math.floor(rW / 2)
        local dy = midY + py
        if dy >= 2 and dy <= h - 2 and rW > 0 then
            display.setCursorPos(px, dy)
            local pStr = ""
            for x = 1, rW do
                local globX = (x + animTick) % 10
                if globX < 4 and py > -pr + 1 and py < pr - 1 then
                    pStr = pStr .. "G"
                else
                    pStr = pStr .. "B"
                end
            end
            for i = 1, #pStr do
                local c = string.sub(pStr, i, i)
                if c == "G" then
                    display.setBackgroundColor(colors.green)
                    display.setTextColor(colors.lime)
                    display.write("~")
                else
                    display.setBackgroundColor(colors.blue)
                    display.setTextColor(colors.lightBlue)
                    display.write(" ")
                end
            end
        end
    end
    
    local satAngle = (animTick * 0.2)
    local satX = midX + math.floor(math.cos(satAngle) * (pr * 2.8))
    local satY = midY + math.floor(math.sin(satAngle) * (pr * 0.8))
    if satX >= 3 and satX <= w - 6 and satY >= 2 and satY <= h - 2 then
        display.setCursorPos(satX, satY)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write("[-o-]")
    end
    
    display.setCursorPos(3, h - 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(" SPACE DISCOVERY 4K | ORBIT ALT: 42,800 KM ")
end

-- Channel 4: Sakura Anime TV
local function drawChannel4(w, h)
    display.setBackgroundColor(colors.pink)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    
    display.setCursorPos(midX - 5, midY - 4)
    display.setBackgroundColor(colors.pink)
    display.setTextColor(colors.white)
    display.write("/\\____/\\")
    
    display.setCursorPos(midX - 5, midY - 3)
    display.write("(  =^.^= )")
    
    local isBlink = (animTick % 20 < 2)
    display.setCursorPos(midX - 5, midY - 2)
    display.setTextColor(colors.purple)
    if isBlink then
        display.write("(  > w <  )")
    else
        display.write("(  (o.o)  )")
    end
    
    display.setCursorPos(midX - 4, midY - 1)
    display.setTextColor(colors.red)
    display.write(' ( ")(") ) ')
    
    display.setCursorPos(midX - 6, midY + 1)
    display.setTextColor(colors.magenta)
    local blush = (animTick % 6 < 3) and "* * * *" or " * * * "
    display.write(" " .. blush .. " ")
    
    display.setTextColor(colors.magenta)
    for p = 1, 15 do
        local px = 2 + ((p * 13 + animTick) % (w - 4))
        local py = 2 + ((p * 7 + animTick * 2) % (h - 4))
        display.setCursorPos(px, py)
        display.write((p % 2 == 0) and "@" or "*")
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.magenta)
    display.setTextColor(colors.white)
    display.write(" SAKURA ANIME TOON ")
end

-- Channel 5: Cyber Grand Prix F1
local function drawChannel5(w, h)
    display.setBackgroundColor(colors.green)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local roadW = math.floor(w * 0.6)
    local rLeft = midX - math.floor(roadW / 2)
    
    for y = 2, h - 2 do
        display.setCursorPos(rLeft, y)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", roadW))
        
        local curbCol = ((y + animTick * 2) % 2 == 0) and colors.red or colors.white
        display.setCursorPos(rLeft, y)
        display.setBackgroundColor(curbCol)
        display.write("||")
        display.setCursorPos(rLeft + roadW - 2, y)
        display.write("||")
        
        if (y + animTick * 3) % 4 < 2 then
            display.setCursorPos(midX, y)
            display.setBackgroundColor(colors.yellow)
            display.write(" ")
        end
    end
    
    local carX = midX - 4 + math.floor(math.sin(animTick * 0.3) * 6)
    local carY = h - 6
    display.setCursorPos(carX, carY)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.red)
    display.write("/---\\")
    display.setCursorPos(carX, carY + 1)
    display.setTextColor(colors.yellow)
    display.write("| #7|")
    display.setCursorPos(carX, carY + 2)
    display.setTextColor(colors.black)
    display.write("0---0")
    
    local rivalX = midX + 3 - math.floor(math.sin(animTick * 0.3) * 4)
    local rivalY = 5 + (animTick % 6)
    display.setCursorPos(rivalX, rivalY)
    display.setTextColor(colors.blue)
    display.write("/---\\")
    display.setCursorPos(rivalX, rivalY + 1)
    display.setTextColor(colors.cyan)
    display.write("| #2|")
    display.setCursorPos(rivalX, rivalY + 2)
    display.setTextColor(colors.black)
    display.write("0---0")
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(string.format(" F1 SPEED: %d KM/H | LAP 48/50 ", 320 + (animTick % 25)))
end

-- Channel 6: Matrix Hacker TV
local function drawChannel6(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local chars = "0123456789ABCDEF$#@*<>~{}[]"
    for col = 2, w - 2, 2 do
        local speed = (col % 3) + 1
        local dropY = (animTick * speed + col * 7) % (h + 10) - 5
        for len = 0, 8 do
            local py = dropY - len
            if py >= 2 and py <= h - 2 then
                display.setCursorPos(col, py)
                local randChar = string.sub(chars, ((col + py + animTick) % #chars) + 1, ((col + py + animTick) % #chars) + 1)
                display.setBackgroundColor(colors.black)
                if len == 0 then
                    display.setTextColor(colors.white)
                elseif len < 3 then
                    display.setTextColor(colors.lime)
                else
                    display.setTextColor(colors.green)
                end
                display.write(randChar)
            end
        end
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lime)
    display.setCursorPos(midX - 6, midY - 2)
    display.write(" [0_0] [0_0] ")
    display.setCursorPos(midX - 7, midY - 1)
    display.write(" /===========/ ")
    display.setCursorPos(midX - 6, midY)
    display.write(" || 1 0 1 || ")
    display.setCursorPos(midX - 5, midY + 1)
    display.write(" \\=======/ ")
    
    display.setCursorPos(3, h - 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lime)
    display.write(" MATRIX SEC-NET // ACCESS GRANTED ")
end

-- Channel 7: Retro Pixel Arcade
local function drawChannel7(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midY = math.floor(h / 2)
    
    display.setTextColor(colors.blue)
    display.setCursorPos(2, midY - 4)
    display.write(string.rep("=", w - 4))
    display.setCursorPos(2, midY + 4)
    display.write(string.rep("=", w - 4))
    
    display.setTextColor(colors.yellow)
    for x = 4, w - 4, 3 do
        display.setCursorPos(x, midY)
        display.write(".")
    end
    
    local pacX = 4 + (animTick * 2) % (w - 12)
    local mouthOpen = (animTick % 4 < 2)
    display.setCursorPos(pacX, midY)
    display.setTextColor(colors.yellow)
    display.setBackgroundColor(colors.black)
    display.write(mouthOpen and "<" or "C")
    
    local ghostX = (pacX - 6)
    if ghostX < 3 then ghostX = ghostX + (w - 8) end
    display.setCursorPos(ghostX, midY)
    display.setTextColor(colors.red)
    display.write("&")
    
    local ghost2X = (pacX - 10)
    if ghost2X < 3 then ghost2X = ghost2X + (w - 8) end
    display.setCursorPos(ghost2X, midY)
    display.setTextColor(colors.cyan)
    display.write("&")
    
    display.setCursorPos(3, 3)
    display.setTextColor(colors.white)
    display.write(string.format(" 1UP: %06d   HIGH SCORE: 999990 ", animTick * 100))
end

-- Channel 8: Deep Sea Ocean Aquarium
local function drawChannel8(w, h)
    display.setBackgroundColor(colors.blue)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    for x = 2, w - 2 do
        display.setCursorPos(x, h - 2)
        display.setBackgroundColor(colors.brown)
        display.write("~")
        
        if x % 6 == 0 then
            for sw = 1, 4 do
                display.setCursorPos(x, h - 2 - sw)
                display.setBackgroundColor(colors.blue)
                display.setTextColor(colors.green)
                display.write((sw % 2 == 0) and "(" or ")")
            end
        end
    end
    
    local f1X = (animTick * 2) % (w - 8) + 2
    local f1Y = math.floor(h * 0.4) + math.floor(math.sin(animTick * 0.5) * 2)
    display.setCursorPos(f1X, f1Y)
    display.setTextColor(colors.orange)
    display.setBackgroundColor(colors.blue)
    display.write("><((('>")
    
    local f2X = (w - 8) - ((animTick * 1) % (w - 8))
    local f2Y = math.floor(h * 0.6) + math.floor(math.cos(animTick * 0.4) * 2)
    display.setCursorPos(f2X, f2Y)
    display.setTextColor(colors.yellow)
    display.write("<'))><")
    
    display.setTextColor(colors.white)
    for b = 1, 10 do
        local bx = 4 + (b * 5) % (w - 8)
        local by = (h - 3) - ((animTick * 2 + b * 3) % (h - 4))
        display.setCursorPos(bx, by)
        display.write("o")
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.lightBlue)
    display.setTextColor(colors.blue)
    display.write(" AQUA RELAX 4K ")
end

-- Channel 9: Cyber Tele-Shopping
local function drawChannel9(w, h)
    display.setBackgroundColor(colors.purple)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    
    display.setCursorPos(midX - 8, midY + 3)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(" [=== PEDESTAL ===] ")
    
    local swordFrame = (animTick % 4)
    display.setBackgroundColor(colors.purple)
    display.setTextColor(colors.cyan)
    display.setCursorPos(midX - 3, midY - 3)
    if swordFrame == 0 then
        display.write("   /|  ")
        display.setCursorPos(midX - 3, midY - 2)
        display.write("  / |  ")
        display.setCursorPos(midX - 3, midY - 1)
        display.write(" [===] ")
        display.setCursorPos(midX - 3, midY)
        display.write("   |   ")
    else
        display.write("  |\\   ")
        display.setCursorPos(midX - 3, midY - 2)
        display.write("  | \\  ")
        display.setCursorPos(midX - 3, midY - 1)
        display.write(" [===] ")
        display.setCursorPos(midX - 3, midY)
        display.write("   |   ")
    end
    
    local discountColor = (animTick % 8 < 4) and colors.red or colors.yellow
    display.setCursorPos(3, 4)
    display.setBackgroundColor(discountColor)
    display.setTextColor(colors.white)
    display.write(" -70% OFF MEGA SALE! ")
    
    display.setCursorPos(w - 20, 4)
    display.setBackgroundColor(colors.green)
    display.setTextColor(colors.yellow)
    display.write(" ONLY 99.99$ DIA ")
    
    display.setCursorPos(3, h - 3)
    display.setBackgroundColor(colors.yellow)
    display.setTextColor(colors.red)
    display.write(" CALL NOW: 555-CYBER-SHOP ")
end

-- Channel 10: SMPTE Color Bars & Test Signal
local function drawChannel10(w, h)
    local testCols = { colors.lightGray, colors.yellow, colors.cyan, colors.green, colors.magenta, colors.red, colors.blue }
    local segW = math.max(1, math.floor((w - 2) / #testCols))
    
    for idx, col in ipairs(testCols) do
        local sx = 2 + (idx - 1) * segW
        local ex = (idx == #testCols) and (w - 2) or (sx + segW - 1)
        for y = 2, math.floor(h * 0.7) do
            display.setCursorPos(sx, y)
            display.setBackgroundColor(col)
            display.write(string.rep(" ", ex - sx + 1))
        end
    end
    
    for y = math.floor(h * 0.7) + 1, h - 2 do
        display.setCursorPos(2, y)
        display.setBackgroundColor(colors.black)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    display.setCursorPos(midX - 11, midY - 1)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.write("+---------------------+")
    display.setCursorPos(midX - 11, midY)
    display.setTextColor((animTick % 10 < 5) and colors.yellow or colors.red)
    display.write("|  EBS NO SIGNAL TEST |")
    display.setCursorPos(midX - 11, midY + 1)
    display.setTextColor(colors.white)
    display.write("+---------------------+")
end

-- Channel 11: Hypnotic Cyber Vortex / Rainbow Spiral
local function drawChannel11(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    local maxR = math.floor(h * 0.45)
    local paletteColors = { colors.cyan, colors.purple, colors.magenta, colors.pink, colors.yellow, colors.lime, colors.lightBlue }
    
    for r = maxR, 1, -1 do
        local angleOffset = (animTick * 0.3) + (r * 0.4)
        local col = paletteColors[((math.floor(r + animTick * 0.5)) % #paletteColors) + 1]
        display.setTextColor(col)
        display.setBackgroundColor(colors.black)
        
        for step = 0, 7 do
            local a = angleOffset + (step * (math.pi / 4))
            local px = midX + math.floor(math.cos(a) * r * 2.2)
            local py = midY + math.floor(math.sin(a) * r)
            if px >= 3 and px <= w - 3 and py >= 3 and py <= h - 3 then
                display.setCursorPos(px, py)
                display.write("@")
            end
        end
    end
    
    display.setCursorPos(midX - 1, midY)
    display.setTextColor(colors.white)
    display.write("(*)")
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.purple)
    display.setTextColor(colors.yellow)
    display.write(" HYPNOTIC VORTEX 60HZ ")
end

-- Channel 12: Cyber Rave 2077 (Club Dancers + Disco Floor)
local function drawChannel12(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local floorY = math.floor(h * 0.7)
    local midX = math.floor(w / 2)
    
    -- Disco Floor Tiles with Flashing Neon
    local discoCols = { colors.magenta, colors.cyan, colors.yellow, colors.lime, colors.purple, colors.pink }
    for y = floorY, h - 2 do
        for x = 2, w - 2, 4 do
            local col = discoCols[((math.floor(x/4) + y + animTick) % #discoCols) + 1]
            display.setCursorPos(x, y)
            display.setBackgroundColor(col)
            display.write("    ")
        end
    end
    
    -- Overhead Moving Spotlights
    local spot1X = midX + math.floor(math.sin(animTick * 0.4) * (w * 0.35))
    local spot2X = midX - math.floor(math.sin(animTick * 0.4) * (w * 0.35))
    display.setTextColor(colors.white)
    display.setBackgroundColor(colors.black)
    for ly = 3, floorY - 1 do
        local spread = math.floor((ly - 3) * 0.6)
        if spot1X - spread >= 2 and spot1X + spread <= w - 2 then
            display.setCursorPos(spot1X - spread, ly)
            display.write("/")
            display.setCursorPos(spot1X + spread, ly)
            display.write("\\")
        end
    end
    
    -- Animated Dancers (3 Silhouettes)
    local dancerOffsets = { -12, 0, 12 }
    for idx, dOff in ipairs(dancerOffsets) do
        local dx = midX + dOff
        local beatPose = (animTick + idx * 2) % 4
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        
        display.setCursorPos(dx - 1, floorY - 4)
        display.write(" (o) ") -- Head
        
        display.setCursorPos(dx - 2, floorY - 3)
        if beatPose == 0 then
            display.write(" \\|_|/ ")
        elseif beatPose == 1 then
            display.write(" _|_|  ")
        elseif beatPose == 2 then
            display.write("  |_|_ ")
        else
            display.write(" /|_|\\ ")
        end
        
        display.setCursorPos(dx - 2, floorY - 2)
        display.write("  | |  ")
        display.setCursorPos(dx - 2, floorY - 1)
        if beatPose % 2 == 0 then
            display.write(" /   \\ ")
        else
            display.write(" |   | ")
        end
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.magenta)
    display.setTextColor(colors.white)
    display.write(" CYBER RAVE 2077 [LIVE CLUB] ")
end

-- Channel 13: Cozy Campfire & Starlit Mountain Night
local function drawChannel13(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local groundY = math.floor(h * 0.75)
    
    -- Mountain Silhouette
    display.setTextColor(colors.gray)
    display.setBackgroundColor(colors.black)
    for x = 2, w - 2 do
        local mH = math.floor(math.abs(math.sin(x * 0.15)) * 4) + 2
        for my = groundY - mH, groundY do
            display.setCursorPos(x, my)
            display.write("^")
        end
    end
    
    -- Starlit Sky
    display.setTextColor(colors.white)
    for s = 1, 12 do
        local sx = 3 + (s * 9) % (w - 6)
        local sy = 3 + (s * 3) % (groundY - 5)
        display.setCursorPos(sx, sy)
        display.write(".")
    end
    
    -- Ground Pine Trees
    display.setTextColor(colors.green)
    for x = 4, w - 4, 8 do
        display.setCursorPos(x, groundY)
        display.write(" | ")
        display.setCursorPos(x, groundY - 1)
        display.write("/|\\")
        display.setCursorPos(x, groundY - 2)
        display.write("/*\\")
    end
    
    -- Animated Campfire Logs
    display.setCursorPos(midX - 3, groundY + 1)
    display.setBackgroundColor(colors.brown)
    display.setTextColor(colors.gray)
    display.write("[XXXXX]")
    
    -- Flickering Fire Particles (Red, Orange, Yellow)
    local fireChars = { "^", "*", "#", "!", "o" }
    local fireColors = { colors.yellow, colors.orange, colors.red }
    for fy = 0, 3 do
        local fw = 3 - fy
        for fx = -fw, fw do
            if math.random() > 0.3 then
                display.setCursorPos(midX + fx, groundY - fy)
                display.setBackgroundColor(colors.black)
                display.setTextColor(fireColors[math.min(3, fy + 1)])
                display.write(fireChars[math.random(1, #fireChars)])
            end
        end
    end
    
    -- Floating Sparks / Embers
    for e = 1, 4 do
        local ex = midX + math.random(-4, 4)
        local ey = groundY - 4 - (animTick + e * 2) % 4
        display.setCursorPos(ex, ey)
        display.setTextColor(colors.yellow)
        display.write(".")
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.brown)
    display.setTextColor(colors.yellow)
    display.write(" COZY CAMPFIRE 4K ")
end

-- Channel 14: Neo-Tokyo Rainy Street
local function drawChannel14(w, h)
    display.setBackgroundColor(colors.black)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local streetY = math.floor(h * 0.7)
    
    -- Glowing Neon Shop Signs in the distance
    display.setCursorPos(4, 4)
    display.setBackgroundColor(colors.red)
    display.setTextColor(colors.white)
    display.write(" RAMEN ")
    
    display.setCursorPos(w - 14, 5)
    display.setBackgroundColor(colors.cyan)
    display.setTextColor(colors.black)
    display.write(" CYBER BAR ")
    
    -- Rain Drops (Slanted animation)
    display.setTextColor(colors.lightBlue)
    display.setBackgroundColor(colors.black)
    for col = 2, w - 2, 3 do
        local ry = (animTick * 3 + col * 4) % (streetY - 2) + 2
        display.setCursorPos(col, ry)
        display.write("/")
    end
    
    -- Wet Asphalt Street with Reflection Rings (Puddles)
    for y = streetY, h - 2 do
        display.setCursorPos(2, y)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", w - 2))
    end
    
    -- Water Ripple Rings
    display.setTextColor(colors.cyan)
    display.setBackgroundColor(colors.gray)
    for p = 1, 3 do
        local px = 8 + (p * 14) % (w - 16)
        local py = streetY + (p % 3)
        local rSize = (animTick + p) % 3
        display.setCursorPos(px - rSize, py)
        display.write("(" .. string.rep("~", rSize * 2) .. ")")
    end
    
    -- Silhouette Person Walking with Umbrella
    local walkerX = (animTick * 1) % (w - 12) + 4
    display.setCursorPos(walkerX - 2, streetY - 3)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.magenta)
    display.write(" (===) ") -- Umbrella
    display.setCursorPos(walkerX - 1, streetY - 2)
    display.setTextColor(colors.white)
    display.write("  |  ")
    display.setCursorPos(walkerX - 1, streetY - 1)
    display.write(" / \\ ")
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.cyan)
    display.write(" NEO-TOKYO RAIN [LO-FI] ")
end

-- Channel 15: Bongo Cat Live (Interactive Meme Channel)
local function drawChannel15(w, h)
    display.setBackgroundColor(colors.lightBlue)
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.write(string.rep(" ", w - 2))
    end
    
    local midX = math.floor(w / 2)
    local midY = math.floor(h / 2)
    
    -- Music Notes Floating
    display.setTextColor(colors.magenta)
    display.setBackgroundColor(colors.lightBlue)
    for n = 1, 6 do
        local nx = 4 + (n * 9 + animTick * 2) % (w - 8)
        local ny = 3 + (n * 3) % (midY - 2)
        display.setCursorPos(nx, ny)
        display.write((n % 2 == 0) and "#" or "@")
    end
    
    -- Bongo Cat Body
    display.setCursorPos(midX - 6, midY - 4)
    display.setBackgroundColor(colors.lightBlue)
    display.setTextColor(colors.white)
    display.write(" /\\_____/\\ ")
    
    display.setCursorPos(midX - 6, midY - 3)
    display.write(" |  o.o  | ")
    
    display.setCursorPos(midX - 6, midY - 2)
    display.write(" |  >w<  | ")
    
    display.setCursorPos(midX - 7, midY - 1)
    display.write(" /|       |\\ ")
    
    -- Desk & Bongos
    display.setCursorPos(midX - 10, midY + 1)
    display.setBackgroundColor(colors.brown)
    display.setTextColor(colors.yellow)
    display.write(" [= BONGO =]   [= SYNTH =] ")
    
    for dy = midY + 2, h - 2 do
        display.setCursorPos(midX - 12, dy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", 24))
    end
    
    -- Animated Paws hitting bongos alternatively!
    local pawLeftDown = (animTick % 2 == 0)
    display.setBackgroundColor(colors.lightBlue)
    display.setTextColor(colors.pink)
    
    if pawLeftDown then
        display.setCursorPos(midX - 6, midY)
        display.write(" (O)") -- Left paw DOWN hitting bongo
        display.setCursorPos(midX + 2, midY - 1)
        display.write(" (O)") -- Right paw UP
    else
        display.setCursorPos(midX - 6, midY - 1)
        display.write(" (O)") -- Left paw UP
        display.setCursorPos(midX + 2, midY)
        display.write(" (O)") -- Right paw DOWN hitting synth
    end
    
    display.setCursorPos(3, 3)
    display.setBackgroundColor(colors.yellow)
    display.setTextColor(colors.red)
    display.write(" BONGO CAT LIVE 24/7 ")
end

-- Draw TV Static Noise (When switching channels)
local function drawStatic(w, h)
    local staticChars = { ".", ":", "*", "#", "%", "@", " " }
    local staticColors = { colors.black, colors.gray, colors.lightGray, colors.white }
    for y = 2, h - 2 do
        display.setCursorPos(2, y)
        display.setBackgroundColor(colors.black)
        local lineStr = ""
        for x = 2, w - 2 do
            local ch = staticChars[math.random(1, #staticChars)]
            lineStr = lineStr .. ch
        end
        display.setTextColor(staticColors[math.random(1, #staticColors)])
        display.write(lineStr)
    end
end

-- Draw TV Guide (EPG)
local function drawTVGuide(w, h)
    display.setBackgroundColor(colors.gray)
    display.clear()
    
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write("  [ TV GUIDE & EPG ] - ALL 15 CHANNELS                         [ CLOSE X ] ")
    registerButton("BTN_CLOSE_GUIDE", w - 12, 1, 11, 1, "[ CLOSE X ]", "yellow", "blue")
    
    for i = 1, totalChannels do
        local ch = CHANNELS[i]
        local y = 2 + (i - 1)
        if y < h then
            local isCur = (i == currentChannel)
            display.setCursorPos(2, y)
            display.setBackgroundColor(isCur and colors.blue or colors.gray)
            display.setTextColor(isCur and colors.yellow or colors.white)
            local rowText = string.format("CH %02d [%-4s] %-22s | %s", ch.num, ch.code, ch.name, ch.genre)
            display.write(string.sub(rowText, 1, w - 4))
            registerButton("BTN_CH_" .. i, 2, y, w - 4, 1, "", "white", "gray")
        end
    end
    
    display.setCursorPos(2, h)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightBlue)
    display.write(" Click any channel to switch | [ G ] Close Guide ")
end

-- ============================================================================
-- MAIN RENDER PIPELINE
-- ============================================================================
local function renderTV()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    if showGuide then
        drawTVGuide(screenW, screenH)
        drawButtons()
        return
    end
    
    -- 1. Outer TV Casing Frame (Cyber Metallic)
    display.setBackgroundColor(colors.gray)
    display.clear()
    
    -- Top Bezel Bar with Buttons
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    -- Interactive Top Remote Buttons
    registerButton("BTN_PREV", 2, 1, 9, 1, "[ < CH ]", "white", "blue")
    registerButton("BTN_GUIDE", 12, 1, 9, 1, "[ GUIDE ]", "yellow", "gray")
    registerButton("BTN_MUTE", 22, 1, 8, 1, isMuted and "[ MUTED ]" or "[ VOL+ ]", isMuted and "red" or "lime", "gray")
    registerButton("BTN_SUB", 31, 1, 8, 1, showSubtitles and "[ CC:ON ]" or "[ CC:OFF ]", "cyan", "gray")
    registerButton("BTN_NEXT", screenW - 9, 1, 9, 1, "[ CH > ]", "white", "blue")
    
    -- 2. Draw Active Channel Content or Static Noise
    if isStaticSwitch > 0 then
        drawStatic(screenW, screenH)
        isStaticSwitch = isStaticSwitch - 1
    else
        if currentChannel == 1 then drawChannel1(screenW, screenH)
        elseif currentChannel == 2 then drawChannel2(screenW, screenH)
        elseif currentChannel == 3 then drawChannel3(screenW, screenH)
        elseif currentChannel == 4 then drawChannel4(screenW, screenH)
        elseif currentChannel == 5 then drawChannel5(screenW, screenH)
        elseif currentChannel == 6 then drawChannel6(screenW, screenH)
        elseif currentChannel == 7 then drawChannel7(screenW, screenH)
        elseif currentChannel == 8 then drawChannel8(screenW, screenH)
        elseif currentChannel == 9 then drawChannel9(screenW, screenH)
        elseif currentChannel == 10 then drawChannel10(screenW, screenH)
        elseif currentChannel == 11 then drawChannel11(screenW, screenH)
        elseif currentChannel == 12 then drawChannel12(screenW, screenH)
        elseif currentChannel == 13 then drawChannel13(screenW, screenH)
        elseif currentChannel == 14 then drawChannel14(screenW, screenH)
        elseif currentChannel == 15 then drawChannel15(screenW, screenH)
        end
    end
    
    -- 3. Screen Bezel Border Frame (Cyber Neon Frame around screen)
    display.setTextColor(colors.cyan)
    display.setBackgroundColor(colors.gray)
    for y = 2, screenH - 1 do
        display.setCursorPos(1, y)
        display.write("|")
        display.setCursorPos(screenW, y)
        display.write("|")
    end
    display.setCursorPos(1, 2)
    display.write("+" .. string.rep("=", screenW - 2) .. "+")
    display.setCursorPos(1, screenH - 1)
    display.write("+" .. string.rep("=", screenW - 2) .. "+")
    
    -- 4. Channel OSD Banner (Appears on switch, fades after timer)
    local chInfo = CHANNELS[currentChannel]
    if osdTimer > 0 then
        osdTimer = osdTimer - 1
        local osdText = string.format(" CH %02d/%02d: %s [%s] ", chInfo.num, totalChannels, chInfo.name, chInfo.genre)
        display.setCursorPos(4, 3)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(osdText)
    end
    
    -- 5. Subtitles / Teletext Bar
    if showSubtitles and chInfo.subtitles and #chInfo.subtitles > 0 then
        local subIdx = (math.floor(animTick / 35) % #chInfo.subtitles) + 1
        local subText = " " .. chInfo.subtitles[subIdx] .. " "
        local subX = math.max(3, math.floor((screenW - #subText) / 2))
        display.setCursorPos(subX, screenH - 3)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.yellow)
        display.write(string.sub(subText, 1, screenW - 6))
    end
    
    -- 6. Bottom TV Bezel & Controls Hint
    display.setCursorPos(1, screenH)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightBlue)
    display.write(string.rep(" ", screenW))
    
    local bottomHint = " [ < / > ] CH (1-15)    [ G ] Guide    [ M ] Mute    [ C ] Subs    [ Q ] Exit "
    display.setCursorPos(math.max(2, math.floor((screenW - #bottomHint) / 2)), screenH)
    display.write(bottomHint)
    
    drawButtons()
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.06) -- Smooth 16 FPS subpixel loop
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.06)
            animTick = animTick + 1
            playChannelSound()
            renderTV()
            
        elseif event == "key" then
            -- Channel Navigation
            if p1 == keys.right or p1 == keys.d or p1 == keys.n or p1 == keys.space then
                switchChannel(currentChannel + 1)
            elseif p1 == keys.left or p1 == keys.a or p1 == keys.p then
                switchChannel(currentChannel - 1)
            -- Direct Numbers 1..9, 0 for 10
            elseif p1 == keys.one then switchChannel(1)
            elseif p1 == keys.two then switchChannel(2)
            elseif p1 == keys.three then switchChannel(3)
            elseif p1 == keys.four then switchChannel(4)
            elseif p1 == keys.five then switchChannel(5)
            elseif p1 == keys.six then switchChannel(6)
            elseif p1 == keys.seven then switchChannel(7)
            elseif p1 == keys.eight then switchChannel(8)
            elseif p1 == keys.nine then switchChannel(9)
            elseif p1 == keys.zero then switchChannel(10)
            -- F1-F5 for 11..15
            elseif p1 == keys.f1 then switchChannel(11)
            elseif p1 == keys.f2 then switchChannel(12)
            elseif p1 == keys.f3 then switchChannel(13)
            elseif p1 == keys.f4 then switchChannel(14)
            elseif p1 == keys.f5 then switchChannel(15)
            -- Toggle TV Guide
            elseif p1 == keys.g then
                showGuide = not showGuide
            -- Toggle Mute
            elseif p1 == keys.m then
                isMuted = not isMuted
            -- Toggle Subtitles
            elseif p1 == keys.c then
                showSubtitles = not showSubtitles
            -- Exit
            elseif p1 == keys.q or p1 == keys.escape then
                break
            end
            
        elseif event == "mouse_scroll" then
            if p1 > 0 then switchChannel(currentChannel + 1) else switchChannel(currentChannel - 1) end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_PREV" then
                switchChannel(currentChannel - 1)
            elseif cid == "BTN_NEXT" then
                switchChannel(currentChannel + 1)
            elseif cid == "BTN_GUIDE" then
                showGuide = not showGuide
            elseif cid == "BTN_CLOSE_GUIDE" then
                showGuide = false
            elseif cid == "BTN_MUTE" then
                isMuted = not isMuted
            elseif cid == "BTN_SUB" then
                showSubtitles = not showSubtitles
            elseif cid and string.find(cid, "BTN_CH_") then
                local chNum = tonumber(string.sub(cid, 8))
                if chNum then switchChannel(chNum) end
            else
                local screenW, _ = display.getSize()
                if my > 1 and my < display.getSize() then
                    if mx < math.floor(screenW / 2) then
                        switchChannel(currentChannel - 1)
                    else
                        switchChannel(currentChannel + 1)
                    end
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Cyber Television closed.")
    else
        print("Cyber Television closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("TV Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("TV Error: " .. tostring(err))
end
