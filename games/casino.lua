--[[
================================================================================
                   CASINO ROYALE DELUXE for CC: Tweaked
             The Ultimate 4-in-1 Vegas Casino Arcade Suite
================================================================================
  Games Included:
    1. 🎰 SLOTS 777: 3-Reel Animated Jackpot Slot Machine
    2. 🃏 BLACKJACK 21: Vegas Rules with Double Down & Realistic Cards
    3. 🎡 ROULETTE: Full European Wheel with Animated Ball & Multi-Betting
    4. 🔼 HIGHER / LOWER: Escalating Streak Multiplier Card Ladder
    5. 🎁 LUCKY WHEEL / FREE ATM: Daily bonus chips & emergency loan

  Features:
    * Interactive Touchscreen & Mouse clicks + Keyboard controls
    * Output: External Monitor on the LEFT ("left") or Computer Terminal
    * Dynamic Sound FX via ComputerCraft Speaker peripheral
    * Persistent Auto-Save (Balance, VIP Tier, High Score, Win Streaks)
    * 100% Clean ASCII English UI (Zero font / encoding glitches)
================================================================================
]]

-- 1. Display Setup: Left Monitor ("left") or Terminal
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

if not display or not display.isColor or not display.isColor() then
    printError("CASINO ROYALE requires an Advanced Computer or Color Monitor!")
    return
end

local screenW, screenH = display.getSize()

-- Sound FX via CC Speaker
local speaker = peripheral and peripheral.find and peripheral.find("speaker")

local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "click" then
            speaker.playNote("hat", 0.5, 16)
        elseif snd == "chip" then
            speaker.playNote("snare", 0.6, 18)
        elseif snd == "spin_tick" then
            speaker.playNote("hat", 0.4, 12)
        elseif snd == "reel_stop" then
            speaker.playNote("bass", 0.8, 14)
        elseif snd == "card_deal" then
            speaker.playNote("snare", 0.3, 16)
        elseif snd == "win_small" then
            speaker.playNote("bell", 0.8, 14)
            sleep(0.04)
            speaker.playNote("bell", 0.8, 18)
        elseif snd == "win_big" then
            speaker.playNote("chime", 1.0, 12)
            speaker.playNote("flute", 0.8, 16)
            sleep(0.05)
            speaker.playNote("chime", 1.0, 16)
            speaker.playNote("flute", 0.8, 20)
            sleep(0.05)
            speaker.playNote("chime", 1.0, 24)
        elseif snd == "jackpot" then
            for note = 12, 24, 3 do
                speaker.playNote("chime", 1.0, note)
                speaker.playNote("bell", 1.0, note)
                sleep(0.04)
            end
        elseif snd == "lose" then
            speaker.playNote("didgeridoo", 0.8, 4)
        elseif snd == "bonus" then
            speaker.playNote("harp", 0.9, 14)
            sleep(0.04)
            speaker.playNote("harp", 0.9, 18)
            sleep(0.04)
            speaker.playNote("harp", 0.9, 22)
        end
    end)
end

-- Double Buffering Graphics System
local Buffer = { chars = {}, fg = {}, bg = {} }

local function initBuffer()
    screenW, screenH = display.getSize()
    Buffer.chars = {}
    Buffer.fg = {}
    Buffer.bg = {}
    for y = 1, screenH do
        Buffer.chars[y] = string.rep(" ", screenW)
        Buffer.fg[y] = string.rep("0", screenW)
        Buffer.bg[y] = string.rep("f", screenW)
    end
end

local function clearBuffer(fgChar, bgChar)
    screenW, screenH = display.getSize()
    fgChar = (fgChar and #fgChar > 0) and string.sub(fgChar, 1, 1) or "0"
    bgChar = (bgChar and #bgChar > 0) and string.sub(bgChar, 1, 1) or "f"
    for y = 1, screenH do
        Buffer.chars[y] = string.rep(" ", screenW)
        Buffer.fg[y] = string.rep(fgChar, screenW)
        Buffer.bg[y] = string.rep(bgChar, screenW)
    end
end

local function drawText(x, y, text, fg, bg)
    if y < 1 or y > screenH or x > screenW then return end
    if not text or #text == 0 then return end
    local len = #text
    if x + len - 1 < 1 then return end
    
    local startIdx = 1
    local drawX = x
    if drawX < 1 then
        startIdx = 2 - drawX
        drawX = 1
    end
    local drawLen = math.min(len - startIdx + 1, screenW - drawX + 1)
    if drawLen <= 0 then return end
    
    local subText = string.sub(text, startIdx, startIdx + drawLen - 1)
    local fillFg = (fg and #fg > 0) and string.sub(fg, 1, 1) or "0"
    local fillBg = (bg and #bg > 0) and string.sub(bg, 1, 1) or "f"
    local subFg = string.rep(fillFg, drawLen)
    local subBg = string.rep(fillBg, drawLen)
    
    Buffer.chars[y] = Buffer.chars[y] or string.rep(" ", screenW)
    Buffer.fg[y] = Buffer.fg[y] or string.rep("0", screenW)
    Buffer.bg[y] = Buffer.bg[y] or string.rep("f", screenW)
    
    local leftChars = string.sub(Buffer.chars[y], 1, drawX - 1)
    local rightChars = string.sub(Buffer.chars[y], drawX + drawLen)
    Buffer.chars[y] = leftChars .. subText .. rightChars
    
    local leftFg = string.sub(Buffer.fg[y], 1, drawX - 1)
    local rightFg = string.sub(Buffer.fg[y], drawX + drawLen)
    Buffer.fg[y] = leftFg .. subFg .. rightFg
    
    local leftBg = string.sub(Buffer.bg[y], 1, drawX - 1)
    local rightBg = string.sub(Buffer.bg[y], drawX + drawLen)
    Buffer.bg[y] = leftBg .. subBg .. rightBg
end

local function drawCenteredText(y, text, fg, bg)
    local x = math.floor((screenW - #text) / 2) + 1
    drawText(x, y, text, fg, bg)
end

local function flushBuffer()
    screenW, screenH = display.getSize()
    for y = 1, screenH do
        local c = Buffer.chars[y] or string.rep(" ", screenW)
        local f = Buffer.fg[y] or string.rep("0", screenW)
        local b = Buffer.bg[y] or string.rep("f", screenW)
        
        if #c < screenW then c = c .. string.rep(" ", screenW - #c)
        elseif #c > screenW then c = string.sub(c, 1, screenW) end
        
        if #f < screenW then f = f .. string.rep("0", screenW - #f)
        elseif #f > screenW then f = string.sub(f, 1, screenW) end
        
        if #b < screenW then b = b .. string.rep("f", screenW - #b)
        elseif #b > screenW then b = string.sub(b, 1, screenW) end
        
        display.setCursorPos(1, y)
        pcall(function()
            display.blit(c, f, b)
        end)
    end
end

-- Interactive Button System
local TouchButtons = {}
local activePressedId = nil
local activePressedTimer = 0

local function clearButtons()
    TouchButtons = {}
end

local function registerButton(id, x, y, w, h, label, fg, bg, activeBg, hotkey)
    table.insert(TouchButtons, {
        id = id,
        x1 = x,
        y1 = y,
        x2 = x + w - 1,
        y2 = y + h - 1,
        w = w,
        h = h,
        label = label,
        fg = fg or "0",
        bg = bg or "8",
        activeBg = activeBg or "e",
        hotkey = hotkey
    })
end

local function drawRegisteredButtons()
    for _, btn in ipairs(TouchButtons) do
        local isPressed = (activePressedId == btn.id)
        local curBg = isPressed and btn.activeBg or btn.bg
        local curFg = isPressed and "f" or btn.fg
        
        for by = btn.y1, btn.y2 do
            drawText(btn.x1, by, string.rep(" ", btn.w), curFg, curBg)
        end
        
        local lblX = btn.x1 + math.floor((btn.w - #btn.label) / 2)
        local lblY = btn.y1 + math.floor((btn.h - 1) / 2)
        drawText(lblX, lblY, btn.label, curFg, curBg)
    end
end

local function checkButtonClicked(clickX, clickY)
    for _, btn in ipairs(TouchButtons) do
        if clickX >= btn.x1 and clickX <= btn.x2 and clickY >= btn.y1 and clickY <= btn.y2 then
            activePressedId = btn.id
            activePressedTimer = 0.1
            return btn.id
        end
    end
    return nil
end

-- Persistent Player Account & Stats
local Player = {
    balance = 1000,
    totalWon = 0,
    totalLost = 0,
    gamesPlayed = 0,
    biggestWin = 0,
    vipTier = "BRONZE",
    selectedBet = 50,
    freeClaimTime = 0
}

local SAVE_PATH = "casino_save.txt"

local function loadPlayerData()
    if fs.exists(SAVE_PATH) then
        local f = fs.open(SAVE_PATH, "r")
        if f then
            local str = f.readAll()
            f.close()
            local bal, won, lost, played, big = string.match(str, "(%d+):(%d+):(%d+):(%d+):(%d+)")
            if bal then
                Player.balance = tonumber(bal) or 1000
                Player.totalWon = tonumber(won) or 0
                Player.totalLost = tonumber(lost) or 0
                Player.gamesPlayed = tonumber(played) or 0
                Player.biggestWin = tonumber(big) or 0
            end
        end
    end
    -- Recalculate VIP Tier
    if Player.balance >= 50000 then Player.vipTier = "DIAMOND"
    elseif Player.balance >= 15000 then Player.vipTier = "PLATINUM"
    elseif Player.balance >= 5000 then Player.vipTier = "GOLD"
    elseif Player.balance >= 2000 then Player.vipTier = "SILVER"
    else Player.vipTier = "BRONZE" end
end

local function savePlayerData()
    local f = fs.open(SAVE_PATH, "w")
    if f then
        f.write(string.format("%d:%d:%d:%d:%d", Player.balance, Player.totalWon, Player.totalLost, Player.gamesPlayed, Player.biggestWin))
        f.close()
    end
end

-- Shared Header Bar
local function drawCasinoHeader(title)
    drawText(1, 1, string.rep(" ", screenW), "0", "7")
    drawText(2, 1, "CASINO ROYALE", "4", "7")
    drawText(18, 1, "| " .. (title or "LOBBY"), "0", "7")
    
    local vipColors = { BRONZE = "c", SILVER = "8", GOLD = "4", PLATINUM = "3", DIAMOND = "9" }
    local vipCol = vipColors[Player.vipTier] or "e"
    local vipStr = "[" .. Player.vipTier .. " VIP]"
    drawText(screenW - #vipStr - 22, 1, vipStr, vipCol, "7")
    
    local balStr = string.format("BANK: $%d", Player.balance)
    drawText(screenW - #balStr - 1, 1, balStr, "5", "7")
end

-- =============================================================================
--                             1. SLOTS 777
-- =============================================================================

local SLOT_SYMBOLS = {
    { id = "SEVEN",  icon = "[ 7 ]", color = "e", val = 7,  mult = 100, name = "Triple Sevens" },
    { id = "DIAMOND",icon = "[DIA]", color = "9", val = 6,  mult = 50,  name = "Diamonds" },
    { id = "CROWN",  icon = "[CRW]", color = "4", val = 5,  mult = 30,  name = "Royal Crowns" },
    { id = "BELL",   icon = "[BEL]", color = "1", val = 4,  mult = 20,  name = "Golden Bells" },
    { id = "CHERRY", icon = "[CHE]", color = "e", val = 3,  mult = 10,  name = "Sweet Cherries" },
    { id = "CLOVER", icon = "[CLO]", color = "5", val = 2,  mult = 6,   name = "Lucky Clovers" },
    { id = "BAR",    icon = "[BAR]", color = "0", val = 1,  mult = 4,   name = "Classic Bars" }
}

local function runSlotsGame()
    local reel1, reel2, reel3 = 1, 1, 1
    local isSpinning = false
    local resultMsg = "Press [SPIN] or [SPACE] to try your luck!"
    local resultColor = "e"
    local winAmount = 0
    
    local betValues = { 10, 25, 50, 100, 250, 500, 1000 }
    local currentBetIdx = 3
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawCasinoHeader("MEGA SLOTS 777")
        
        local curBet = betValues[currentBetIdx]
        
        -- Slots Cabinet Frame
        local cabinetW = 44
        local cabinetH = 12
        local startX = math.floor((screenW - cabinetW) / 2) + 1
        local startY = 3
        
        for y = startY, startY + cabinetH do
            drawText(startX, y, string.rep(" ", cabinetW), "0", "8")
        end
        drawText(startX + 1, startY + 1, "+============== [ LUCKY 777 SLOTS ] ==============+", "4", "8")
        
        -- 3 Reels Display
        local sym1 = SLOT_SYMBOLS[reel1]
        local sym2 = SLOT_SYMBOLS[reel2]
        local sym3 = SLOT_SYMBOLS[reel3]
        
        local reelY = startY + 3
        local r1X = startX + 6
        local r2X = startX + 18
        local r3X = startX + 30
        
        -- Reel 1
        drawText(r1X, reelY,     "+-------+", "7", "8")
        drawText(r1X, reelY + 1, "|       |", "7", "0")
        drawText(r1X + 2, reelY + 1, sym1.icon, sym1.color, "0")
        drawText(r1X, reelY + 2, "+-------+", "7", "8")
        
        -- Reel 2
        drawText(r2X, reelY,     "+-------+", "7", "8")
        drawText(r2X + 2, reelY + 1, sym2.icon, sym2.color, "0")
        drawText(r2X, reelY + 1, "|       |", "7", "0")
        drawText(r2X + 2, reelY + 1, sym2.icon, sym2.color, "0")
        drawText(r2X, reelY + 2, "+-------+", "7", "8")
        
        -- Reel 3
        drawText(r3X, reelY,     "+-------+", "7", "8")
        drawText(r3X + 2, reelY + 1, sym3.icon, sym3.color, "0")
        drawText(r3X, reelY + 1, "|       |", "7", "0")
        drawText(r3X + 2, reelY + 1, sym3.icon, sym3.color, "0")
        drawText(r3X, reelY + 2, "+-------+", "7", "8")
        
        -- Payline Indicator
        drawText(startX + 2, reelY + 1, "->", "e", "8")
        drawText(startX + cabinetW - 4, reelY + 1, "<-", "e", "8")
        
        -- Result Message
        drawText(startX + 2, startY + 7, string.rep(" ", cabinetW - 4), "0", "7")
        local msgX = startX + math.floor((cabinetW - #resultMsg) / 2)
        drawText(msgX, startY + 7, resultMsg, resultColor, "7")
        
        if winAmount > 0 then
            local winStr = string.format("WIN: +$%d", winAmount)
            drawCenteredText(startY + 9, winStr, "5", "8")
        else
            drawCenteredText(startY + 9, string.format("CURRENT BET: $%d", curBet), "e", "8")
        end
        
        -- Betting Buttons
        local btnY = startY + cabinetH + 2
        registerButton("SLOT_BET_MINUS", startX, btnY, 6, 2, "[-]", "0", "7", "e")
        registerButton("SLOT_BET_PLUS", startX + 7, btnY, 6, 2, "[+]", "0", "7", "e")
        registerButton("SLOT_BET_MAX", startX + 14, btnY, 8, 2, "MAX BET", "0", "4", "e")
        
        -- Spin Button
        registerButton("SLOT_SPIN", startX + 23, btnY, 12, 2, "[ SPIN! ]", isSpinning and "8" or "0", isSpinning and "7" or "5", "4")
        
        -- Back Button
        registerButton("SLOT_BACK", startX + 36, btnY, 8, 2, "LOBBY", "0", "e", "4")
        
        -- Payout Table on Right / Bottom
        drawText(2, screenH - 1, "PAYOUTS: [7]=100x | [DIA]=50x | [CRW]=30x | [BEL]=20x | [CHE]=10x | [CLO]=6x | [BAR]=4x", "7", "f")
        
        drawRegisteredButtons()
        flushBuffer()
        
        -- Event Handling
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            if p1 == keys.space or p1 == keys.enter then
                p1 = "BTN_SPIN"
            elseif p1 == keys.up or p1 == keys.right then
                currentBetIdx = math.min(#betValues, currentBetIdx + 1)
                playSound("chip")
            elseif p1 == keys.down or p1 == keys.left then
                currentBetIdx = math.max(1, currentBetIdx - 1)
                playSound("chip")
            elseif p1 == keys.m then
                currentBetIdx = #betValues
                playSound("chip")
            elseif p1 == keys.q or p1 == keys.escape then
                return "LOBBY"
            end
        end
        
        local clickedId = nil
        if event == "mouse_click" or event == "monitor_touch" then
            clickedId = checkButtonClicked(p2, p3)
        elseif p1 == "BTN_SPIN" then
            clickedId = "SLOT_SPIN"
        end
        
        if clickedId == "SLOT_BACK" then
            playSound("click")
            return "LOBBY"
        elseif clickedId == "SLOT_BET_MINUS" then
            currentBetIdx = math.max(1, currentBetIdx - 1)
            playSound("chip")
        elseif clickedId == "SLOT_BET_PLUS" then
            currentBetIdx = math.min(#betValues, currentBetIdx + 1)
            playSound("chip")
        elseif clickedId == "SLOT_BET_MAX" then
            currentBetIdx = #betValues
            playSound("chip")
        elseif clickedId == "SLOT_SPIN" and not isSpinning then
            if Player.balance < curBet then
                resultMsg = "INSUFFICIENT FUNDS! Claim Free ATM in Lobby."
                resultColor = "e"
                playSound("lose")
            else
                Player.balance = Player.balance - curBet
                Player.totalLost = Player.totalLost + curBet
                Player.gamesPlayed = Player.gamesPlayed + 1
                winAmount = 0
                isSpinning = true
                resultMsg = "SPINNING REELS..."
                resultColor = "4"
                
                -- Animated Reel Spin
                local totalTicks = 22
                for tick = 1, totalTicks do
                    if tick <= 12 then reel1 = math.random(1, #SLOT_SYMBOLS) end
                    if tick <= 17 then reel2 = math.random(1, #SLOT_SYMBOLS) end
                    reel3 = math.random(1, #SLOT_SYMBOLS)
                    
                    playSound("spin_tick")
                    
                    clearBuffer("0", "f")
                    clearButtons()
                    drawCasinoHeader("MEGA SLOTS 777")
                    
                    local s1 = SLOT_SYMBOLS[reel1]
                    local s2 = SLOT_SYMBOLS[reel2]
                    local s3 = SLOT_SYMBOLS[reel3]
                    
                    for y = startY, startY + cabinetH do drawText(startX, y, string.rep(" ", cabinetW), "0", "8") end
                    drawText(startX + 1, startY + 1, "+============== [ LUCKY 777 SLOTS ] ==============+", "4", "8")
                    
                    drawText(r1X, reelY, "+-------+", "7", "8"); drawText(r1X, reelY + 1, "|       |", "7", "0"); drawText(r1X + 2, reelY + 1, s1.icon, s1.color, "0"); drawText(r1X, reelY + 2, "+-------+", "7", "8")
                    drawText(r2X, reelY, "+-------+", "7", "8"); drawText(r2X, reelY + 1, "|       |", "7", "0"); drawText(r2X + 2, reelY + 1, s2.icon, s2.color, "0"); drawText(r2X, reelY + 2, "+-------+", "7", "8")
                    drawText(r3X, reelY, "+-------+", "7", "8"); drawText(r3X, reelY + 1, "|       |", "7", "0"); drawText(r3X + 2, reelY + 1, s3.icon, s3.color, "0"); drawText(r3X, reelY + 2, "+-------+", "7", "8")
                    
                    drawText(startX + 2, startY + 7, string.rep(" ", cabinetW - 4), "0", "7")
                    drawText(startX + 12, startY + 7, ">>> ROLLING... <<<", "e", "7")
                    flushBuffer()
                    sleep(0.06)
                end
                
                playSound("reel_stop")
                isSpinning = false
                
                -- Check Payout
                if reel1 == reel2 and reel2 == reel3 then
                    local winSym = SLOT_SYMBOLS[reel1]
                    winAmount = curBet * winSym.mult
                    Player.balance = Player.balance + winAmount
                    Player.totalWon = Player.totalWon + winAmount
                    if winAmount > Player.biggestWin then Player.biggestWin = winAmount end
                    
                    if winSym.id == "SEVEN" then
                        resultMsg = "*** JACKPOT! 777 MEGA WIN! (100x) ***"
                        resultColor = "e"
                        playSound("jackpot")
                    else
                        resultMsg = string.format("JACKPOT! 3x %s! (%dx Payout)", winSym.name, winSym.mult)
                        resultColor = "5"
                        playSound("win_big")
                    end
                elseif reel1 == reel2 or reel2 == reel3 or reel1 == reel3 then
                    local matchIdx = (reel1 == reel2 or reel1 == reel3) and reel1 or reel2
                    local matchSym = SLOT_SYMBOLS[matchIdx]
                    winAmount = math.floor(curBet * (matchSym.mult * 0.25))
                    if winAmount < curBet then winAmount = curBet end
                    Player.balance = Player.balance + winAmount
                    Player.totalWon = Player.totalWon + winAmount
                    resultMsg = string.format("NICE! Double %s! (+$%d)", matchSym.name, winAmount)
                    resultColor = "e"
                    playSound("win_small")
                else
                    resultMsg = "NO MATCH. Spin again to win!"
                    resultColor = "7"
                    playSound("lose")
                end
                savePlayerData()
            end
        end
    end
end

-- =============================================================================
--                             2. BLACKJACK 21
-- =============================================================================

local SUITS = { { sym = "S", name = "Spades", col = "0" }, { sym = "H", name = "Hearts", col = "e" }, { sym = "D", name = "Diamonds", col = "e" }, { sym = "C", name = "Clubs", col = "0" } }
local RANKS = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" }

local function createDeck()
    local deck = {}
    for _, s in ipairs(SUITS) do
        for _, r in ipairs(RANKS) do
            local val = tonumber(r) or (r == "A" and 11 or 10)
            table.insert(deck, { rank = r, suit = s.sym, col = s.col, val = val })
        end
    end
    -- Shuffle
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

local function calculateHand(hand)
    local total = 0
    local aces = 0
    for _, card in ipairs(hand) do
        total = total + card.val
        if card.rank == "A" then aces = aces + 1 end
    end
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end
    return total
end

local function drawCard(startX, startY, card, hidden)
    drawText(startX, startY,     "+---+", "7", "f")
    if hidden then
        drawText(startX, startY + 1, "|###|", "3", "b")
        drawText(startX, startY + 2, "|###|", "3", "b")
    else
        local rStr = string.format("%-2s", card.rank)
        drawText(startX, startY + 1, "|" .. rStr .. "|", card.col, "f")
        drawText(startX, startY + 2, "| " .. card.suit .. " |", card.col, "f")
    end
    drawText(startX, startY + 3, "+---+", "7", "f")
end

local function runBlackjackGame()
    local deck = createDeck()
    local playerHand = {}
    local dealerHand = {}
    local gameState = "BETTING" -- BETTING, PLAYER_TURN, DEALER_TURN, ROUND_OVER
    local bet = 50
    local message = "Place your bet and click [DEAL]!"
    local messageColor = "e"
    local winAmount = 0
    
    local function dealInitialCards()
        if #deck < 10 then deck = createDeck() end
        playerHand = { table.remove(deck, 1), table.remove(deck, 1) }
        dealerHand = { table.remove(deck, 1), table.remove(deck, 1) }
        playSound("card_deal")
        
        Player.balance = Player.balance - bet
        Player.totalLost = Player.totalLost + bet
        Player.gamesPlayed = Player.gamesPlayed + 1
        
        local pScore = calculateHand(playerHand)
        local dScore = calculateHand(dealerHand)
        
        if pScore == 21 then
            if dScore == 21 then
                gameState = "ROUND_OVER"
                winAmount = bet
                Player.balance = Player.balance + winAmount
                message = "PUSH! Both have Natural Blackjack."
                messageColor = "e"
                playSound("win_small")
            else
                gameState = "ROUND_OVER"
                winAmount = math.floor(bet * 2.5) -- 3:2 payout
                Player.balance = Player.balance + winAmount
                Player.totalWon = Player.totalWon + winAmount
                if winAmount > Player.biggestWin then Player.biggestWin = winAmount end
                message = "BLACKJACK! 3:2 Payout!"
                messageColor = "5"
                playSound("win_big")
            end
        else
            gameState = "PLAYER_TURN"
            message = "Your turn: [HIT], [STAND], or [DOUBLE]!"
            messageColor = "e"
        end
        savePlayerData()
    end
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawCasinoHeader("VEGAS BLACKJACK 21")
        
        -- Table Mat
        local tableW = 46
        local tableH = 14
        local startX = math.floor((screenW - tableW) / 2) + 1
        local startY = 3
        
        for y = startY, startY + tableH do drawText(startX, y, string.rep(" ", tableW), "0", "d") end
        drawText(startX + 1, startY + 1, "==== DEALER HAND ====", "0", "d")
        
        -- Draw Dealer Cards
        local dScore = calculateHand(dealerHand)
        for i, card in ipairs(dealerHand) do
            local cx = startX + 3 + (i - 1) * 6
            local isHidden = (i == 2 and gameState == "PLAYER_TURN")
            drawCard(cx, startY + 2, card, isHidden)
        end
        if gameState == "PLAYER_TURN" and #dealerHand > 0 then
            drawText(startX + 28, startY + 3, "SHOWING: " .. dealerHand[1].val, "e", "d")
        elseif #dealerHand > 0 then
            drawText(startX + 28, startY + 3, "TOTAL: " .. dScore, (dScore > 21 and "e" or "f"), "d")
        end
        
        -- Draw Player Cards
        drawText(startX + 1, startY + 7, "==== YOUR HAND ====", "0", "d")
        local pScore = calculateHand(playerHand)
        for i, card in ipairs(playerHand) do
            local cx = startX + 3 + (i - 1) * 6
            drawCard(cx, startY + 8, card, false)
        end
        if #playerHand > 0 then
            local scoreCol = (pScore > 21 and "e" or (pScore == 21 and "5" or "e"))
            drawText(startX + 28, startY + 9, "YOUR SCORE: " .. pScore, scoreCol, "d")
        end
        
        -- Message Banner
        drawText(startX + 2, startY + tableH - 1, string.rep(" ", tableW - 4), "0", "7")
        drawCenteredText(startY + tableH - 1, message, messageColor, "7")
        
        -- Control Buttons
        local btnY = startY + tableH + 1
        if gameState == "BETTING" or gameState == "ROUND_OVER" then
            registerButton("BJ_BET_MINUS", startX, btnY, 6, 2, "[-$25]", "0", "7", "e")
            registerButton("BJ_BET_PLUS", startX + 7, btnY, 6, 2, "[+$25]", "0", "7", "e")
            registerButton("BJ_DEAL", startX + 14, btnY, 10, 2, "[ DEAL ]", "0", "5", "4")
            registerButton("BJ_ALL_IN", startX + 25, btnY, 10, 2, "ALL IN", "0", "4", "e")
            registerButton("BJ_LOBBY", startX + 36, btnY, 8, 2, "LOBBY", "0", "e", "4")
            drawCenteredText(btnY + 2, string.format("BET AMOUNT: $%d", bet), "e", "f")
        elseif gameState == "PLAYER_TURN" then
            registerButton("BJ_HIT", startX + 2, btnY, 10, 2, "[ HIT ]", "0", "5", "4", "h")
            registerButton("BJ_STAND", startX + 13, btnY, 10, 2, "[ STAND ]", "0", "e", "4", "s")
            registerButton("BJ_DOUBLE", startX + 24, btnY, 10, 2, "[ DOUBLE ]", (Player.balance >= bet and "0" or "8"), (Player.balance >= bet and "4" or "7"), "e", "d")
            registerButton("BJ_LOBBY", startX + 35, btnY, 8, 2, "LOBBY", "0", "e", "4")
        end
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local clickedId = nil
        
        if event == "key" then
            if p1 == keys.h and gameState == "PLAYER_TURN" then clickedId = "BJ_HIT"
            elseif p1 == keys.s and gameState == "PLAYER_TURN" then clickedId = "BJ_STAND"
            elseif p1 == keys.d and gameState == "PLAYER_TURN" then clickedId = "BJ_DOUBLE"
            elseif p1 == keys.space or p1 == keys.enter then
                if gameState == "BETTING" or gameState == "ROUND_OVER" then clickedId = "BJ_DEAL" end
            elseif p1 == keys.q or p1 == keys.escape then return "LOBBY" end
        elseif event == "mouse_click" or event == "monitor_touch" then
            clickedId = checkButtonClicked(p2, p3)
        end
        
        if clickedId == "BJ_LOBBY" then
            playSound("click")
            return "LOBBY"
        elseif clickedId == "BJ_BET_MINUS" then
            bet = math.max(10, bet - 25)
            playSound("chip")
        elseif clickedId == "BJ_BET_PLUS" then
            bet = math.min(Player.balance, bet + 25)
            playSound("chip")
        elseif clickedId == "BJ_ALL_IN" then
            bet = Player.balance
            playSound("chip")
        elseif clickedId == "BJ_DEAL" then
            if Player.balance < bet then
                message = "INSUFFICIENT FUNDS! Claim Free ATM in Lobby."
                messageColor = "e"
                playSound("lose")
            else
                dealInitialCards()
            end
        elseif clickedId == "BJ_HIT" and gameState == "PLAYER_TURN" then
            table.insert(playerHand, table.remove(deck, 1))
            playSound("card_deal")
            local score = calculateHand(playerHand)
            if score > 21 then
                gameState = "ROUND_OVER"
                message = "BUST! Over 21. Dealer Wins."
                messageColor = "e"
                playSound("lose")
                savePlayerData()
            elseif score == 21 then
                clickedId = "BJ_STAND"
            end
        elseif clickedId == "BJ_DOUBLE" and gameState == "PLAYER_TURN" and Player.balance >= bet then
            Player.balance = Player.balance - bet
            Player.totalLost = Player.totalLost + bet
            bet = bet * 2
            table.insert(playerHand, table.remove(deck, 1))
            playSound("card_deal")
            local score = calculateHand(playerHand)
            if score > 21 then
                gameState = "ROUND_OVER"
                message = "BUST ON DOUBLE! Over 21."
                messageColor = "e"
                playSound("lose")
                savePlayerData()
            else
                clickedId = "BJ_STAND"
            end
        end
        
        if clickedId == "BJ_STAND" and gameState == "PLAYER_TURN" then
            gameState = "DEALER_TURN"
            -- Dealer AI: hits until 17+
            while calculateHand(dealerHand) < 17 do
                table.insert(dealerHand, table.remove(deck, 1))
                playSound("card_deal")
                sleep(0.3)
            end
            
            local finalP = calculateHand(playerHand)
            local finalD = calculateHand(dealerHand)
            gameState = "ROUND_OVER"
            
            if finalD > 21 then
                winAmount = bet * 2
                Player.balance = Player.balance + winAmount
                Player.totalWon = Player.totalWon + winAmount
                message = string.format("DEALER BUSTS (%d)! YOU WIN +$%d!", finalD, winAmount)
                messageColor = "5"
                playSound("win_big")
            elseif finalP > finalD then
                winAmount = bet * 2
                Player.balance = Player.balance + winAmount
                Player.totalWon = Player.totalWon + winAmount
                message = string.format("YOU WIN! %d vs %d (+$%d)", finalP, finalD, winAmount)
                messageColor = "5"
                playSound("win_small")
            elseif finalP == finalD then
                winAmount = bet
                Player.balance = Player.balance + winAmount
                message = string.format("PUSH! %d vs %d (Bet Returned)", finalP, finalD)
                messageColor = "e"
                playSound("win_small")
            else
                message = string.format("DEALER WINS! %d vs %d", finalD, finalP)
                messageColor = "e"
                playSound("lose")
            end
            savePlayerData()
        end
    end
end

-- =============================================================================
--                             3. EUROPEAN ROULETTE
-- =============================================================================

local ROULETTE_NUMBERS = {
    0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
}

local RED_NUMBERS = { [1]=true, [3]=true, [5]=true, [7]=true, [9]=true, [12]=true, [14]=true, [16]=true, [18]=true, [19]=true, [21]=true, [23]=true, [25]=true, [27]=true, [30]=true, [32]=true, [34]=true, [36]=true }

local function getNumberColor(num)
    if num == 0 then return "d", "Green"
    elseif RED_NUMBERS[num] then return "e", "Red"
    else return "0", "Black" end
end

local function runRouletteGame()
    local selectedBetType = "RED"
    local selectedNumber = 7
    local betAmount = 50
    local lastLanded = 0
    local resultMessage = "Choose your bet category and click [SPIN]!"
    local isSpinning = false
    
    local betCategories = {
        { id = "RED", label = "RED (2x)", mult = 2 },
        { id = "BLACK", label = "BLACK (2x)", mult = 2 },
        { id = "EVEN", label = "EVEN (2x)", mult = 2 },
        { id = "ODD", label = "ODD (2x)", mult = 2 },
        { id = "LOW", label = "1-18 (2x)", mult = 2 },
        { id = "HIGH", label = "19-36 (2x)", mult = 2 },
        { id = "NUMBER", label = "STRAIGHT (36x)", mult = 36 }
    }
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawCasinoHeader("EUROPEAN ROULETTE")
        
        local startX = 4
        local startY = 3
        
        -- Wheel Display
        drawText(startX, startY, "+================ [ ROULETTE WHEEL ] ================+", "4", "8")
        drawText(startX, startY + 1, "|", "4", "8"); drawText(startX + 52, startY + 1, "|", "4", "8")
        
        local colHex, colName = getNumberColor(lastLanded)
        local ballStr = string.format("WINNING NUMBER: [ %02d %s ]", lastLanded, string.upper(colName))
        drawCenteredText(startY + 2, ballStr, (colHex == "0" and "f" or colHex), (colHex == "d" and "5" or (colHex == "e" and "e" or "0")))
        
        drawText(startX, startY + 3, "+====================================================+", "4", "8")
        
        -- Betting Options Grid
        local optY = startY + 5
        drawText(startX, optY, "SELECT BET TYPE:", "e", "f")
        for i, cat in ipairs(betCategories) do
            local bx = startX + ((i - 1) % 4) * 13
            local by = optY + 1 + math.floor((i - 1) / 4) * 2
            local isSel = (selectedBetType == cat.id)
            registerButton("ROUL_CAT_" .. cat.id, bx, by, 12, 2, cat.label, isSel and "0" or "f", isSel and "e" or "7", "4")
        end
        
        if selectedBetType == "NUMBER" then
            drawText(startX, optY + 5, string.format("PICKED NUMBER: [%02d] (Use [-] [+] buttons)", selectedNumber), "4", "f")
            registerButton("ROUL_NUM_MINUS", startX + 38, optY + 5, 4, 1, "[-]", "0", "7", "e")
            registerButton("ROUL_NUM_PLUS", startX + 43, optY + 5, 4, 1, "[+]", "0", "7", "e")
        end
        
        -- Action Buttons
        local actY = startY + 11
        registerButton("ROUL_BET_MINUS", startX, actY, 6, 2, "[-$25]", "0", "7", "e")
        registerButton("ROUL_BET_PLUS", startX + 7, actY, 6, 2, "[+$25]", "0", "7", "e")
        registerButton("ROUL_SPIN", startX + 14, actY, 14, 2, "[ SPIN WHEEL ]", isSpinning and "8" or "0", isSpinning and "7" or "5", "4")
        registerButton("ROUL_LOBBY", startX + 30, actY, 8, 2, "LOBBY", "0", "e", "4")
        
        drawText(startX + 39, actY, string.format("BET: $%d", betAmount), "e", "f")
        drawText(startX + 39, actY + 1, string.format("ON: %s", selectedBetType), "3", "f")
        
        -- Result Message Banner
        drawCenteredText(screenH - 1, resultMessage, "e", "f")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local clickedId = nil
        
        if event == "key" then
            if p1 == keys.space or p1 == keys.enter then clickedId = "ROUL_SPIN"
            elseif p1 == keys.q or p1 == keys.escape then return "LOBBY" end
        elseif event == "mouse_click" or event == "monitor_touch" then
            clickedId = checkButtonClicked(p2, p3)
        end
        
        if clickedId == "ROUL_LOBBY" then
            playSound("click")
            return "LOBBY"
        elseif clickedId == "ROUL_BET_MINUS" then
            betAmount = math.max(10, betAmount - 25)
            playSound("chip")
        elseif clickedId == "ROUL_BET_PLUS" then
            betAmount = math.min(Player.balance, betAmount + 25)
            playSound("chip")
        elseif clickedId == "ROUL_NUM_MINUS" then
            selectedNumber = math.max(0, selectedNumber - 1)
            playSound("chip")
        elseif clickedId == "ROUL_NUM_PLUS" then
            selectedNumber = math.min(36, selectedNumber + 1)
            playSound("chip")
        elseif string.sub(clickedId or "", 1, 9) == "ROUL_CAT_" then
            selectedBetType = string.sub(clickedId, 10)
            playSound("chip")
        elseif clickedId == "ROUL_SPIN" and not isSpinning then
            if Player.balance < betAmount then
                resultMessage = "INSUFFICIENT FUNDS! Claim Free ATM in Lobby."
                playSound("lose")
            else
                Player.balance = Player.balance - betAmount
                Player.totalLost = Player.totalLost + betAmount
                Player.gamesPlayed = Player.gamesPlayed + 1
                isSpinning = true
                
                -- Animated Ball Spin
                local wheelIdx = math.random(1, #ROULETTE_NUMBERS)
                local totalSpins = 25
                for s = 1, totalSpins do
                    wheelIdx = (wheelIdx % #ROULETTE_NUMBERS) + 1
                    lastLanded = ROULETTE_NUMBERS[wheelIdx]
                    playSound("spin_tick")
                    
                    clearBuffer("0", "f")
                    clearButtons()
                    drawCasinoHeader("EUROPEAN ROULETTE")
                    drawText(startX, startY, "+================ [ ROULETTE WHEEL ] ================+", "4", "8")
                    local cHex, cName = getNumberColor(lastLanded)
                    drawCenteredText(startY + 2, string.format("SPINNING... [ %02d %s ]", lastLanded, string.upper(cName)), "4", "0")
                    drawText(startX, startY + 3, "+====================================================+", "4", "8")
                    flushBuffer()
                    sleep(0.04 + (s * 0.005))
                end
                
                isSpinning = false
                playSound("reel_stop")
                
                -- Check Win
                local won = false
                local mult = 2
                local isRed = RED_NUMBERS[lastLanded]
                
                if selectedBetType == "RED" and isRed then won = true; mult = 2
                elseif selectedBetType == "BLACK" and (not isRed and lastLanded ~= 0) then won = true; mult = 2
                elseif selectedBetType == "EVEN" and (lastLanded % 2 == 0 and lastLanded ~= 0) then won = true; mult = 2
                elseif selectedBetType == "ODD" and (lastLanded % 2 == 1) then won = true; mult = 2
                elseif selectedBetType == "LOW" and (lastLanded >= 1 and lastLanded <= 18) then won = true; mult = 2
                elseif selectedBetType == "HIGH" and (lastLanded >= 19 and lastLanded <= 36) then won = true; mult = 2
                elseif selectedBetType == "NUMBER" and (lastLanded == selectedNumber) then won = true; mult = 36 end
                
                if won then
                    local winPayout = betAmount * mult
                    Player.balance = Player.balance + winPayout
                    Player.totalWon = Player.totalWon + winPayout
                    if winPayout > Player.biggestWin then Player.biggestWin = winPayout end
                    resultMessage = string.format("WINNER! Landed on %d %s! (+$%d)", lastLanded, colName, winPayout)
                    playSound(mult >= 10 and "win_big" or "win_small")
                else
                    resultMessage = string.format("Landed on %d %s. Better luck next spin!", lastLanded, colName)
                    playSound("lose")
                end
                savePlayerData()
            end
        end
    end
end

-- =============================================================================
--                             4. HIGHER / LOWER
-- =============================================================================

local function runHigherLowerGame()
    local deck = createDeck()
    local currentCard = table.remove(deck, 1)
    local nextCard = nil
    local streak = 0
    local bet = 50
    local isPlaying = false
    local message = "Place your bet and start your streak!"
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        drawCasinoHeader("HIGHER OR LOWER")
        
        local startX = math.floor((screenW - 40) / 2) + 1
        local startY = 3
        
        drawText(startX, startY, "+======== [ CARD STREAK LADDER ] ========+", "4", "8")
        
        -- Draw Current Card
        drawText(startX + 4, startY + 2, "CURRENT CARD:", "e", "f")
        drawCard(startX + 6, startY + 3, currentCard, false)
        
        -- Draw Next Card
        drawText(startX + 24, startY + 2, "NEXT CARD:", "e", "f")
        if nextCard then
            drawCard(startX + 26, startY + 3, nextCard, false)
        else
            drawCard(startX + 26, startY + 3, nil, true)
        end
        
        -- Multiplier Ladder
        local mult = 1.0 + (streak * 0.5)
        drawText(startX + 2, startY + 8, string.format("STREAK: %d Wins | MULTIPLIER: %.1fx", streak, mult), "5", "f")
        
        if isPlaying then
            local cashoutVal = math.floor(bet * mult)
            drawText(startX + 2, startY + 9, string.format("CASHOUT VALUE: +$%d", cashoutVal), "4", "f")
            
            -- Guess Buttons
            registerButton("HL_HIGHER", startX + 2, startY + 11, 11, 2, "[ HIGHER ^ ]", "0", "5", "4")
            registerButton("HL_LOWER", startX + 14, startY + 11, 11, 2, "[ LOWER v ]", "0", "e", "4")
            registerButton("HL_CASHOUT", startX + 26, startY + 11, 12, 2, "[ CASH OUT ]", "0", "4", "5")
        else
            registerButton("HL_BET_MINUS", startX + 2, startY + 11, 6, 2, "[-$25]", "0", "7", "e")
            registerButton("HL_BET_PLUS", startX + 9, startY + 11, 6, 2, "[+$25]", "0", "7", "e")
            registerButton("HL_START", startX + 16, startY + 11, 12, 2, "[ START! ]", "0", "5", "4")
            registerButton("HL_LOBBY", startX + 29, startY + 11, 8, 2, "LOBBY", "0", "e", "4")
            drawCenteredText(startY + 14, string.format("STARTING BET: $%d", bet), "e", "f")
        end
        
        drawCenteredText(screenH - 1, message, "e", "f")
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local clickedId = nil
        
        if event == "key" then
            if p1 == keys.up and isPlaying then clickedId = "HL_HIGHER"
            elseif p1 == keys.down and isPlaying then clickedId = "HL_LOWER"
            elseif p1 == keys.space and isPlaying then clickedId = "HL_CASHOUT"
            elseif p1 == keys.space and not isPlaying then clickedId = "HL_START"
            elseif p1 == keys.q or p1 == keys.escape then return "LOBBY" end
        elseif event == "mouse_click" or event == "monitor_touch" then
            clickedId = checkButtonClicked(p2, p3)
        end
        
        if clickedId == "HL_LOBBY" then
            playSound("click")
            return "LOBBY"
        elseif clickedId == "HL_BET_MINUS" then
            bet = math.max(10, bet - 25)
            playSound("chip")
        elseif clickedId == "HL_BET_PLUS" then
            bet = math.min(Player.balance, bet + 25)
            playSound("chip")
        elseif clickedId == "HL_START" and not isPlaying then
            if Player.balance < bet then
                message = "INSUFFICIENT FUNDS! Claim Free ATM in Lobby."
                playSound("lose")
            else
                Player.balance = Player.balance - bet
                Player.totalLost = Player.totalLost + bet
                Player.gamesPlayed = Player.gamesPlayed + 1
                if #deck < 5 then deck = createDeck() end
                currentCard = table.remove(deck, 1)
                nextCard = nil
                streak = 0
                isPlaying = true
                message = "Is the next card HIGHER or LOWER?"
                playSound("card_deal")
                savePlayerData()
            end
        elseif (clickedId == "HL_HIGHER" or clickedId == "HL_LOWER") and isPlaying then
            if #deck < 3 then deck = createDeck() end
            nextCard = table.remove(deck, 1)
            playSound("card_deal")
            
            local isHigher = (nextCard.val > currentCard.val)
            local isLower = (nextCard.val < currentCard.val)
            local isTie = (nextCard.val == currentCard.val)
            
            local correct = (clickedId == "HL_HIGHER" and isHigher) or (clickedId == "HL_LOWER" and isLower) or isTie
            
            if correct then
                streak = streak + 1
                currentCard = nextCard
                nextCard = nil
                message = string.format("CORRECT! Streak: %d (Multiplier: %.1fx)", streak, 1.0 + (streak * 0.5))
                playSound("win_small")
            else
                isPlaying = false
                message = string.format("WRONG! Lost $%d. Try again!", bet)
                playSound("lose")
            end
            savePlayerData()
        elseif clickedId == "HL_CASHOUT" and isPlaying then
            local winVal = math.floor(bet * (1.0 + (streak * 0.5)))
            Player.balance = Player.balance + winVal
            Player.totalWon = Player.totalWon + winVal
            if winVal > Player.biggestWin then Player.biggestWin = winVal end
            isPlaying = false
            message = string.format("CASHED OUT! Won +$%d!", winVal)
            playSound("win_big")
            savePlayerData()
        end
    end
end

-- =============================================================================
--                             5. FREE CHIPS ATM
-- =============================================================================

local function runFreeAtm()
    clearBuffer("0", "f")
    clearButtons()
    drawCasinoHeader("FREE CHIPS ATM")
    
    local boxW = 40
    local boxH = 10
    local startX = math.floor((screenW - boxW) / 2) + 1
    local startY = 4
    
    for y = startY, startY + boxH do drawText(startX, y, string.rep(" ", boxW), "0", "8") end
    drawText(startX + 1, startY + 1, "=== VEGAS EMERGENCY CHIP DISPENSER ===", "4", "8")
    
    local freeAmount = 250
    if Player.balance < 100 then
        Player.balance = Player.balance + freeAmount
        drawCenteredText(startY + 4, string.format("FREE GRANT: +$%d CHIPS ADDED!", freeAmount), "5", "8")
        drawCenteredText(startY + 6, "Good luck! Rebuild your bankroll!", "e", "8")
        playSound("bonus")
        savePlayerData()
    else
        drawCenteredText(startY + 4, "ATM AVAILABLE WHEN BALANCE < $100.", "e", "8")
        drawCenteredText(startY + 6, string.format("Current Balance: $%d", Player.balance), "f", "8")
    end
    
    registerButton("ATM_OK", startX + 12, startY + 8, 16, 2, "[ BACK TO LOBBY ]", "0", "e", "4")
    drawRegisteredButtons()
    flushBuffer()
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            playSound("click")
            return "LOBBY"
        end
    end
end

-- =============================================================================
--                             MAIN CASINO LOBBY
-- =============================================================================

local function runCasinoLobby()
    local selectedMenuIdx = 1
    local menuItems = {
        { id = "GAME_SLOTS", label = "1. [SLOTS] Mega Slots 777", desc = "3-Reel Animated Jackpot Slot Machine" },
        { id = "GAME_BJ",    label = "2. [CARDS] Blackjack 21", desc = "Classic 21 vs Dealer with Double Down" },
        { id = "GAME_ROUL",  label = "3. [WHEEL] European Roulette", desc = "Wheel of Fortune with Multi-Betting" },
        { id = "GAME_HL",    label = "4. [HI/LO] Higher or Lower", desc = "Escalating Streak Multiplier Ladder" },
        { id = "GAME_ATM",   label = "5. [ATM] Free Bonus Chips", desc = "Emergency chip dispenser ($250 bonus)" },
        { id = "GAME_QUIT",  label = "6. [EXIT] Exit Casino", desc = "Save progress and return to computer" }
    }
    
    local animTick = 0
    local menuTimer = os.startTimer(0.1)
    local jackpotCounter = 1485920
    local floatingSymbols = {
        { x = 3, y = 4, ch = "[7]", fg = "e" },
        { x = 4, y = 10, ch = "[*]", fg = "4" },
        { x = 3, y = 16, ch = "[$]", fg = "5" },
        { x = screenW - 6, y = 6, ch = "[#]", fg = "9" },
        { x = screenW - 5, y = 12, ch = "[7]", fg = "e" },
        { x = screenW - 6, y = 17, ch = "[*]", fg = "4" }
    }
    
    local neonColors = { "4", "e", "1", "d", "5", "9", "2" }
    
    while true do
        clearBuffer("0", "f")
        clearButtons()
        
        animTick = animTick + 1
        jackpotCounter = jackpotCounter + math.random(3, 15)
        local neonCol = neonColors[(math.floor(animTick / 2) % #neonColors) + 1]
        
        drawCasinoHeader("ROYALE LOBBY")
        
        -- 1. Floating Casino Sparkles in gutters
        for _, fs in ipairs(floatingSymbols) do
            drawText(fs.x, fs.y, fs.ch, fs.fg, "0")
        end
        
        -- 2. Grand Vegas Casino Animated Marquee
        local bulb1 = (animTick % 2 == 0) and "* * * *" or " o o o "
        local bulb2 = (animTick % 2 == 1) and "* * * *" or " o o o "
        drawCenteredText(3, "==============================================", neonCol, "f")
        drawCenteredText(4, bulb1 .. "  C A S I N O   R O Y A L E  " .. bulb2, "e", "f")
        drawCenteredText(5, "==============================================", neonCol, "f")
        
        -- 3. Live Progressive Jackpot Ticker
        local jkStr = string.format(">>> MEGA JACKPOT: $%s <<<", tostring(jackpotCounter))
        local jkCol = (animTick % 4 < 2) and "4" or "e"
        drawCenteredText(6, jkStr, jkCol, "0")
        
        -- 4. Game Selection Buttons
        local btnW = 34
        local startX = math.floor((screenW - btnW) / 2) + 1
        local startY = 8
        
        for i, item in ipairs(menuItems) do
            local by = startY + (i - 1) * 2
            local isSel = (i == selectedMenuIdx)
            local fg = isSel and "0" or "f"
            local bg = isSel and "4" or (i == 5 and "5" or (i == 6 and "e" or "7"))
            registerButton(item.id, startX, by, btnW, 2, item.label, fg, bg, "e")
        end
        
        -- 5. Animated Footer Info
        local pulseInd = (animTick % 4 < 2) and ">> [CLICK TO PLAY] <<" or "-- [CLICK TO PLAY] --"
        drawCenteredText(screenH - 1, pulseInd .. " or Use Numbers 1-6 / Arrow Keys", "8", "f")
        
        drawRegisteredButtons()
        flushBuffer()
        
        local event, p1, p2, p3 = os.pullEvent()
        local chosen = nil
        
        if event == "timer" and p1 == menuTimer then
            menuTimer = os.startTimer(0.1)
            
            -- Float symbols up/down
            for _, fs in ipairs(floatingSymbols) do
                if math.random(1, 4) == 1 then
                    fs.y = fs.y + (math.random(1, 2) == 1 and 1 or -1)
                    if fs.y < 3 then fs.y = screenH - 2 elseif fs.y > screenH - 2 then fs.y = 3 end
                end
            end
            
        elseif event == "key" then
            if p1 == keys.one then chosen = "GAME_SLOTS"
            elseif p1 == keys.two then chosen = "GAME_BJ"
            elseif p1 == keys.three then chosen = "GAME_ROUL"
            elseif p1 == keys.four then chosen = "GAME_HL"
            elseif p1 == keys.five then chosen = "GAME_ATM"
            elseif p1 == keys.six or p1 == keys.q or p1 == keys.escape then chosen = "GAME_QUIT"
            elseif p1 == keys.up or p1 == keys.w then
                selectedMenuIdx = math.max(1, selectedMenuIdx - 1)
                playSound("click")
            elseif p1 == keys.down or p1 == keys.s then
                selectedMenuIdx = math.min(#menuItems, selectedMenuIdx + 1)
                playSound("click")
            elseif p1 == keys.enter or p1 == keys.space then
                chosen = menuItems[selectedMenuIdx].id
                playSound("click")
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            chosen = checkButtonClicked(p2, p3)
            if chosen then playSound("click") end
        end
        
        if chosen == "GAME_SLOTS" then
            runSlotsGame()
            menuTimer = os.startTimer(0.1)
        elseif chosen == "GAME_BJ" then
            runBlackjackGame()
            menuTimer = os.startTimer(0.1)
        elseif chosen == "GAME_ROUL" then
            runRouletteGame()
            menuTimer = os.startTimer(0.1)
        elseif chosen == "GAME_HL" then
            runHigherLowerGame()
            menuTimer = os.startTimer(0.1)
        elseif chosen == "GAME_ATM" then
            runFreeAtm()
            menuTimer = os.startTimer(0.1)
        elseif chosen == "GAME_QUIT" then
            savePlayerData()
            return
        end
    end
end

-- =============================================================================
--                             APPLICATION ENTRY
-- =============================================================================

local function main()
    loadPlayerData()
    initBuffer()
    runCasinoLobby()
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Casino Royale closed. Progress saved!")
    else
        print("Thanks for playing CASINO ROYALE Deluxe! Progress saved.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Casino Error: " .. tostring(err))
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.setCursorPos(1, 1)
    print("Casino Error: " .. tostring(err))
end
