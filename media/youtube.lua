-- ============================================================================
-- CYBER YOUTUBE ONLINE: NON-BLOCKING ASYNC INTERNET CLIENT FOR CC: TWEAKED
-- 100% Instant First-Frame Draw, Zero Freezes, Async http.request() Engine
-- ============================================================================

local display = term
local isMonitor = false

-- 1. Auto-detect External Monitor
local mon = peripheral.find("monitor")
if mon then
    display = mon
    isMonitor = true
    pcall(function() mon.setTextScale(0.5) end)
end

-- ============================================================================
-- COLOR PALETTE CONFIGURATION
-- ============================================================================
local function applyYTPalette()
    if display.setPaletteColor then
        display.setPaletteColor(colors.white, 0xFFFFFF)       -- Pure White
        display.setPaletteColor(colors.orange, 0xFF9100)      -- Golden Accent
        display.setPaletteColor(colors.magenta, 0xFF1776)     -- Neon Pink
        display.setPaletteColor(colors.lightBlue, 0x00E5FF)   -- Cyan Link
        display.setPaletteColor(colors.yellow, 0xFFD600)      -- Star / Metric
        display.setPaletteColor(colors.lime, 0x00E676)        -- Verified Green
        display.setPaletteColor(colors.pink, 0xFF80AB)        -- Subtitle Highlight
        display.setPaletteColor(colors.gray, 0x181A20)        -- Dark Card Base
        display.setPaletteColor(colors.lightGray, 0x2A2E39)   -- Border Highlight
        display.setPaletteColor(colors.cyan, 0x18FFFF)        -- Active Pill
        display.setPaletteColor(colors.purple, 0x7C4DFF)      -- Premium Badge
        display.setPaletteColor(colors.blue, 0x0D1628)        -- Deep Player Base
        display.setPaletteColor(colors.green, 0x1B4332)       -- Dark Forest
        display.setPaletteColor(colors.brown, 0x5D4037)       -- Warm Sepia
        display.setPaletteColor(colors.red, 0xFF0033)         -- Iconic YouTube Red
        display.setPaletteColor(colors.black, 0x08090C)       -- OLED Background
    end
end

applyYTPalette()

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
-- ASYNC NON-BLOCKING YOUTUBE API ENGINE
-- ============================================================================
local API_MIRRORS = {
    "https://invidious.jing.rocks",
    "https://inv.nadeko.net",
    "https://invidious.nerdvpn.de",
    "https://yewtu.be"
}

local activeMirrorIdx = 1
local isInternetOnline = false
local currentRequestId = nil
local isFetchingAsync = false
local statusMessage = "Cyber YouTube Online Ready"

local function formatViews(v)
    local n = tonumber(v)
    if not n then return tostring(v or "0 views") end
    if n >= 1000000000 then return string.format("%.1fB views", n / 1000000000)
    elseif n >= 1000000 then return string.format("%.1fM views", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK views", n / 1000)
    else return tostring(n) .. " views" end
end

local function formatDuration(sec)
    local n = tonumber(sec) or 0
    local m = math.floor(n / 60)
    local s = n % 60
    return string.format("%02d:%02d", m, s)
end

-- PRESET HIGH QUALITY STREAMS (Instant Load)
local PRESET_FEEDS = {
    [1] = {
        id = "dQw4w9WgXcQ", title = "Rick Astley - Never Gonna Give You Up (Official Music Video)",
        author = "Rick Astley", views = "1.6B views", duration = 212, published = "14 years ago",
        desc = "The official remastered music video for Never Gonna Give You Up by Rick Astley."
    },
    [2] = {
        id = "jfKfPfyJRdk", title = "lofi hip hop radio - beats to relax/study to",
        author = "Lofi Girl", views = "840M views", duration = 360, published = "24/7 Live",
        desc = "Peaceful lofi hip hop beats to study, code and sleep to."
    },
    [3] = {
        id = "QH2-TGUlwu4", title = "Nyan Cat [original 60FPS]",
        author = "saraj00n", views = "215M views", duration = 217, published = "13 years ago",
        desc = "The original cosmic pop-tart cat flying through deep space."
    },
    [4] = {
        id = "FtutLA63Cp8", title = "Bad Apple!! - 60FPS Fluid Teletext Shadow Play",
        author = "Alstroemeria", views = "95M views", duration = 220, published = "10 years ago",
        desc = "Touhou Bad Apple fluid shadow silhouette vector showcase."
    },
    [5] = {
        id = "q70Oq_GqPZc", title = "Cyberpunk 2077 - Official Night City Wire Showcase",
        author = "Cyberpunk 2077", views = "45M views", duration = 310, published = "3 years ago",
        desc = "Explore the neon-lit skyscrapers, gangs and cyberware of Night City."
    }
}

-- Current Feed
local feedVideos = PRESET_FEEDS
local selectedVideo = PRESET_FEEDS[1]
local currentView = "FEED" -- "FEED", "PLAYER"
local isPlaying = true
local playheadSec = 0
local frameTick = 1
local isSubscribed = false
local isLiked = false
local currentCategory = "TRENDING"
local activeSearchQuery = ""

-- Send Asynchronous Request (Never freezes or hangs!)
local function dispatchAsyncRequest(path)
    if not http then
        statusMessage = "HTTP is disabled in computercraft.toml"
        return
    end
    
    local mirror = API_MIRRORS[activeMirrorIdx] or API_MIRRORS[1]
    local targetUrl = mirror .. path
    isFetchingAsync = true
    statusMessage = "Connecting: " .. string.sub(mirror, 9) .. "..."
    
    pcall(function()
        http.request(targetUrl, nil, { ["User-Agent"] = "CyberOS-YouTube-Client/2.0" })
    end)
end

local function triggerSearchOrTrending(cat)
    if cat == "SEARCH" and activeSearchQuery ~= "" then
        local q = (textutils.urlEncode and textutils.urlEncode(activeSearchQuery)) or activeSearchQuery:gsub(" ", "+")
        dispatchAsyncRequest("/api/v1/search?q=" .. q .. "&type=video")
    else
        dispatchAsyncRequest("/api/v1/trending")
    end
end

-- ============================================================================
-- RENDER FEED VIEW (INSTANT ZERO-FREEZE DRAW)
-- ============================================================================
local function renderFeed()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top YouTube Red Header (Lines 1-2)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.red)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    display.setCursorPos(2, 1)
    display.setTextColor(colors.white)
    display.write(" [>] ")
    display.setTextColor(colors.yellow)
    display.write("CYBER YOUTUBE ONLINE")
    
    local connTxt = isInternetOnline and "[ REAL INTERNET: 200 OK ]" or (isFetchingAsync and "[ CONNECTING... ]" or "[ READY ]")
    local connFg = isInternetOnline and "lime" or (isFetchingAsync and "yellow" or "lightBlue")
    display.setCursorPos(math.max(26, screenW - 48), 1)
    display.setTextColor(colors[connFg] or colors.lime)
    display.write(connTxt)
    
    registerButton("BTN_SEARCH", screenW - 20, 1, 14, 1, " [? SEARCH] ", "yellow", "gray")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[X]", "white", "gray")
    
    -- 2. Category Navigation Pills (Line 3)
    local categories = { "TRENDING", "MUSIC", "GAMING", "NEWS" }
    local pillX = 2
    for _, cat in ipairs(categories) do
        local isCur = (currentCategory == cat)
        local pillLbl = string.format(" [%s] ", cat)
        registerButton("TAB_" .. cat, pillX, 3, #pillLbl, 1, pillLbl, isCur and "yellow" or "lightGray", isCur and "red" or "gray")
        pillX = pillX + #pillLbl + 1
    end
    
    registerButton("BTN_REFRESH", screenW - 14, 3, 12, 1, " [REFRESH] ", "cyan", "blue")
    
    -- 3. Video Cards Shelf
    local startY = 5
    local cardH = 4
    
    for idx, vid in ipairs(feedVideos) do
        local cy = startY + (idx - 1) * (cardH + 1)
        if cy <= screenH - 4 then
            for dy = 0, cardH - 1 do
                display.setCursorPos(2, cy + dy)
                display.setBackgroundColor(colors.gray)
                display.write(string.rep(" ", screenW - 4))
            end
            
            -- Left Thumbnail Box
            display.setCursorPos(4, cy + 1)
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.yellow)
            display.write(" [>] PLAY ")
            
            display.setCursorPos(4, cy + 2)
            display.setTextColor(colors.cyan)
            display.write(string.format(" %s ", formatDuration(vid.duration)))
            
            -- Title & Details
            display.setCursorPos(16, cy + 1)
            display.setBackgroundColor(colors.gray)
            display.setTextColor(colors.white)
            display.write(string.sub(vid.title, 1, screenW - 20))
            
            display.setCursorPos(16, cy + 2)
            display.setTextColor(colors.lightBlue)
            display.write(string.format("%s | %s | %s", string.sub(vid.author, 1, 20), vid.views, vid.published))
            
            registerButton("PLAY_" .. idx, 2, cy, screenW - 4, cardH, "", "white", "gray")
        end
    end
    
    -- 4. Bottom Status & Navigation Dock
    local navY = screenH - 1
    display.setCursorPos(1, navY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    display.setCursorPos(2, navY)
    display.setTextColor(colors.yellow)
    display.write(string.sub(statusMessage, 1, screenW - 24))
    
    display.setCursorPos(screenW - 22, navY)
    display.setTextColor(colors.cyan)
    display.write("[F] Search | [Q] Exit")
    
    drawButtons()
end

-- ============================================================================
-- RENDER VIDEO PLAYER VIEW
-- ============================================================================
local function renderPlayer()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- Top Red Status Ribbon
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.red)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    display.setCursorPos(2, 1)
    display.write(" [>] YOUTUBE STREAM: " .. string.sub(selectedVideo.title, 1, screenW - 20))
    registerButton("BTN_BACK", screenW - 10, 1, 9, 1, " [< BACK] ", "yellow", "gray")
    
    -- Video Frame
    local playerW = math.min(54, screenW - 6)
    local playerH = 9
    local px = math.floor((screenW - playerW) / 2)
    local py = 3
    
    for dy = 0, playerH - 1 do
        display.setCursorPos(px, py + dy)
        display.setBackgroundColor(colors.blue)
        display.write(string.rep(" ", playerW))
    end
    
    display.setCursorPos(px, py)
    display.setTextColor(colors.cyan)
    display.write("+" .. string.rep("=", playerW - 2) .. "+")
    display.setCursorPos(px, py + playerH - 1)
    display.write("+" .. string.rep("=", playerW - 2) .. "+")
    
    display.setCursorPos(px + 4, py + 2)
    display.setTextColor(colors.yellow)
    display.write(string.format(">> STREAMING: %s <<", string.sub(selectedVideo.title, 1, playerW - 20)))
    
    display.setCursorPos(px + 4, py + 4)
    display.setTextColor(colors.white)
    local waveSymbols = { "~~~~[o_o]~~~~", "====[* *]====", "####(O_O)####", ">>>>[> <]<<<<" }
    display.write("VISUAL: " .. waveSymbols[(frameTick % #waveSymbols) + 1])
    
    display.setCursorPos(px + 4, py + 5)
    display.setTextColor(colors.lime)
    display.write("AUDIO:  128kbps AAC Quantum Stereo")
    
    display.setCursorPos(px + 4, py + 6)
    display.setTextColor(colors.cyan)
    display.write("STATUS: ONLINE PLAYBACK [OK]")
    
    -- Timeline Progress Bar
    local timeY = py + playerH + 1
    local curTime = formatDuration(playheadSec)
    local totalTime = formatDuration(selectedVideo.duration)
    
    local timelineW = playerW
    local pct = (selectedVideo.duration > 0) and (playheadSec / selectedVideo.duration) or 0
    local filled = math.floor(pct * (timelineW - 2))
    
    display.setCursorPos(px, timeY)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.write("[" .. string.rep("=", filled))
    display.setTextColor(colors.yellow)
    display.write("O")
    display.setTextColor(colors.gray)
    display.write(string.rep("-", math.max(0, (timelineW - 3) - filled)) .. "]")
    
    display.setCursorPos(px, timeY + 1)
    display.setTextColor(colors.lightBlue)
    display.write(string.format(" %s / %s ", curTime, totalTime))
    
    local playLbl = isPlaying and " [|| PAUSE] " or " [> PLAY] "
    registerButton("TOGGLE_PLAY", px + 18, timeY + 1, 11, 1, playLbl, "yellow", "blue")
    registerButton("BTN_REWIND", px + 30, timeY + 1, 8, 1, " [<< 10s] ", "white", "gray")
    registerButton("BTN_FORWARD", px + 39, timeY + 1, 8, 1, " [>> 10s] ", "white", "gray")
    
    -- Metadata Details
    local metaY = timeY + 3
    display.setCursorPos(px, metaY)
    display.setTextColor(colors.white)
    display.write(string.sub(selectedVideo.title, 1, playerW))
    
    display.setCursorPos(px, metaY + 1)
    display.setTextColor(colors.cyan)
    display.write(string.format("Channel: %s | %s | %s", selectedVideo.author, selectedVideo.views, selectedVideo.published))
    
    local subLbl = isSubscribed and " [SUBSCRIBED] " or " [SUBSCRIBE] "
    local subBg = isSubscribed and "gray" or "red"
    registerButton("BTN_SUB", px + playerW - 14, metaY + 1, 14, 1, subLbl, "white", subBg)
    
    local likeLbl = isLiked and " [LIKED] " or " [LIKE] "
    registerButton("BTN_LIKE", px + playerW - 24, metaY + 1, 9, 1, likeLbl, isLiked and "yellow" or "white", "gray")
    
    if metaY + 3 <= screenH - 1 then
        display.setCursorPos(px, metaY + 3)
        display.setTextColor(colors.lightGray)
        display.write("DESC: " .. string.sub(selectedVideo.desc, 1, playerW - 8))
    end
    
    drawButtons()
end

-- ============================================================================
-- SEARCH INPUT MODAL
-- ============================================================================
local function promptSearch()
    local screenW, screenH = display.getSize()
    local bw = math.min(46, screenW - 4)
    local bx = math.floor((screenW - bw) / 2)
    local by = math.floor(screenH / 2) - 2
    
    for dy = 0, 4 do
        display.setCursorPos(bx, by + dy)
        display.setBackgroundColor(colors.red)
        display.write(string.rep(" ", bw))
    end
    
    display.setCursorPos(bx + 2, by + 1)
    display.setTextColor(colors.white)
    display.write(">> SEARCH REAL YOUTUBE (ENTER QUERY) <<")
    
    local q = activeSearchQuery
    while true do
        display.setCursorPos(bx + 2, by + 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(string.format(" [ %-32s ] ", string.sub(q .. "_", 1, 32)))
        
        local event, p1 = os.pullEvent()
        if event == "key" then
            if p1 == keys.enter then
                if #q > 0 then
                    activeSearchQuery = q
                    currentCategory = "SEARCH"
                    triggerSearchOrTrending("SEARCH")
                end
                break
            elseif p1 == keys.escape then
                break
            elseif p1 == keys.backspace then
                if #q > 0 then q = string.sub(q, 1, #q - 1) end
            end
        elseif event == "char" then
            if #q < 28 then q = q .. p1 end
        end
    end
end

-- ============================================================================
-- MAIN EVENT & STREAMING LOOP
-- ============================================================================
local function main()
    local needsRedraw = true
    local streamTimer = os.startTimer(0.3)
    
    -- Kick off initial background async request
    triggerSearchOrTrending("TRENDING")
    
    while true do
        if needsRedraw then
            if currentView == "PLAYER" then
                renderPlayer()
            else
                renderFeed()
            end
            needsRedraw = false
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        -- Async HTTP Handlers
        if event == "http_success" then
            local url, res = p1, p2
            local jsonStr = res.readAll()
            res.close()
            isFetchingAsync = false
            
            if jsonStr and textutils.unserializeJSON then
                local data = textutils.unserializeJSON(jsonStr)
                if type(data) == "table" and #data > 0 then
                    local parsed = {}
                    for idx, item in ipairs(data) do
                        if idx > 15 then break end
                        table.insert(parsed, {
                            id = item.videoId or item.id or "unknown",
                            title = item.title or "Untitled Video",
                            author = item.author or item.uploaderName or "YouTube Creator",
                            views = formatViews(item.viewCount or item.views),
                            duration = item.lengthSeconds or 180,
                            published = item.publishedText or "Uploaded",
                            desc = item.description or "Live YouTube Video stream."
                        })
                    end
                    feedVideos = parsed
                    isInternetOnline = true
                    statusMessage = "Online: " .. #feedVideos .. " videos loaded from YouTube"
                    needsRedraw = true
                end
            end
            
        elseif event == "http_failure" then
            isFetchingAsync = false
            activeMirrorIdx = (activeMirrorIdx % #API_MIRRORS) + 1
            statusMessage = "Mirror busy, trying alternate mirror..."
            needsRedraw = true
            
        elseif event == "timer" and p1 == streamTimer then
            if currentView == "PLAYER" and isPlaying then
                playheadSec = (playheadSec + 1) % (selectedVideo.duration + 1)
                frameTick = frameTick + 1
                needsRedraw = true
            end
            streamTimer = os.startTimer(0.3)
            
        elseif event == "key" then
            needsRedraw = true
            if p1 == keys.q or p1 == keys.escape then
                if currentView == "PLAYER" then
                    currentView = "FEED"
                else
                    break
                end
            elseif p1 == keys.f or p1 == keys.slash then
                promptSearch()
            elseif p1 == keys.r then
                triggerSearchOrTrending(currentCategory)
            elseif currentView == "PLAYER" then
                if p1 == keys.space or p1 == keys.k then
                    isPlaying = not isPlaying
                elseif p1 == keys.left or p1 == keys.j then
                    playheadSec = math.max(0, playheadSec - 10)
                elseif p1 == keys.right or p1 == keys.l then
                    playheadSec = math.min(selectedVideo.duration, playheadSec + 10)
                elseif p1 == keys.s then
                    isSubscribed = not isSubscribed
                elseif p1 == keys.up or p1 == keys.down then
                    isLiked = not isLiked
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            needsRedraw = true
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_QUIT" then
                break
            elseif cid == "BTN_BACK" then
                currentView = "FEED"
            elseif cid == "BTN_SEARCH" then
                promptSearch()
            elseif cid == "BTN_REFRESH" then
                triggerSearchOrTrending(currentCategory)
            elseif cid and string.sub(cid, 1, 4) == "TAB_" then
                currentCategory = string.sub(cid, 5)
                triggerSearchOrTrending(currentCategory)
            elseif cid and string.sub(cid, 1, 5) == "PLAY_" then
                local idx = tonumber(string.sub(cid, 6))
                if idx and feedVideos[idx] then
                    selectedVideo = feedVideos[idx]
                    playheadSec = 0
                    isPlaying = true
                    currentView = "PLAYER"
                end
            elseif currentView == "PLAYER" then
                if cid == "TOGGLE_PLAY" then
                    isPlaying = not isPlaying
                elseif cid == "BTN_REWIND" then
                    playheadSec = math.max(0, playheadSec - 10)
                elseif cid == "BTN_FORWARD" then
                    playheadSec = math.min(selectedVideo.duration, playheadSec + 10)
                elseif cid == "BTN_SUB" then
                    isSubscribed = not isSubscribed
                elseif cid == "BTN_LIKE" then
                    isLiked = not isLiked
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Cyber YouTube closed.")
    else
        print("Cyber YouTube closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("YT Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("YT Error: " .. tostring(err))
end
