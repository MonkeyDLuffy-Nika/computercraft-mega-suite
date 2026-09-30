-- ============================================================================
-- BYBIT PRO CRYPTO EXCHANGE & FUTURES TERMINAL - CC: TWEAKED
-- Real-time Candlesticks, 100x Leverage, Long/Short, Orderbook & Bybit Earn
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
    [colors.orange]    = 0xFF961E,
    [colors.magenta]   = 0xEB4BBE,
    [colors.lightBlue] = 0x64B4FF,
    [colors.yellow]    = 0xFFD700, -- Bybit Gold / Brand Yellow
    [colors.lime]      = 0x00E676, -- Bullish Green (Long / Profit)
    [colors.pink]      = 0xFFB4B4,
    [colors.gray]      = 0x1E222D, -- Terminal Card Dark
    [colors.lightGray] = 0x8890A5, -- Muted Text
    [colors.cyan]      = 0x00E5FF,
    [colors.purple]    = 0x9D4EDD,
    [colors.blue]      = 0x182855,
    [colors.brown]     = 0x5C3A21,
    [colors.green]     = 0x00C853,
    [colors.red]       = 0xFF3B30, -- Bearish Red (Short / Loss)
    [colors.black]     = 0x0B0E14  -- Deep Bybit Background
}

if display.setPaletteColor then
    for col, hexVal in pairs(PALETTE) do
        pcall(function() display.setPaletteColor(col, hexVal) end)
    end
end

-- Sound Effects
local function playSound(snd)
    if not speaker then return end
    pcall(function()
        if snd == "buy" then
            speaker.playNote("chime", 0.8, 16)
            sleep(0.03)
            speaker.playNote("chime", 0.9, 22)
        elseif snd == "sell" then
            speaker.playNote("snare", 0.7, 10)
            sleep(0.03)
            speaker.playNote("bass", 0.8, 6)
        elseif snd == "liq" then
            for a = 1, 3 do
                speaker.playNote("bell", 1.0, 6)
                speaker.playNote("bass", 1.0, 4)
                sleep(0.04)
            end
        elseif snd == "win" then
            for p = 14, 24, 3 do
                speaker.playNote("chime", 0.9, p)
                sleep(0.03)
            end
        end
    end)
end

-- ============================================================================
-- TRADING ASSETS & STATE
-- ============================================================================
local SAVE_FILE = "bybit_save.json"

local ASSETS = {
    { symbol = "BTC/USDT", name = "Bitcoin", price = 65420.0, baseVol = 85.0, history = {}, change = 2.45, high = 66800.0, low = 64200.0 },
    { symbol = "ETH/USDT", name = "Ethereum", price = 3480.0, baseVol = 12.0, history = {}, change = -1.15, high = 3560.0, low = 3410.0 },
    { symbol = "SOL/USDT", name = "Solana", price = 152.5, baseVol = 1.8, history = {}, change = 5.80, high = 158.0, low = 142.0 },
    { symbol = "TON/USDT", name = "Toncoin", price = 6.85, baseVol = 0.12, history = {}, change = 8.20, high = 7.10, low = 6.25 },
    { symbol = "DOGE/USDT", name = "Dogecoin", price = 0.145, baseVol = 0.005, history = {}, change = 14.50, high = 0.165, low = 0.128 }
}

local selectedAssetIdx = 1
local selectedLeverage = 10 -- 1x, 5x, 10x, 25x, 50x, 100x
local orderAmountUSDT = 1000

local account = {
    balanceUSDT = 10000.0,
    stakedUSDT = 0.0,
    totalProfitUSDT = 0.0,
    tradesCount = 0,
    winsCount = 0,
    position = nil -- { assetIdx, type: "LONG"/"SHORT", entryPrice, sizeUSDT, leverage, margin, liqPrice }
}

-- Initialize Price History (Candles)
for _, ast in ipairs(ASSETS) do
    local p = ast.price
    for i = 1, 30 do
        local change = (math.random() - 0.49) * ast.baseVol
        p = math.max(0.001, p + change)
        table.insert(ast.history, {
            open = p,
            close = p + (math.random() - 0.49) * (ast.baseVol * 0.8),
            high = p + math.random() * ast.baseVol,
            low = p - math.random() * ast.baseVol
        })
    end
    ast.price = ast.history[#ast.history].close
end

-- Save / Load
local function loadSave()
    if fs.exists(SAVE_FILE) then
        local f = fs.open(SAVE_FILE, "r")
        if f then
            local data = textutils.unserializeJSON(f.readAll())
            f.close()
            if data and type(data) == "table" then
                for k, v in pairs(data) do account[k] = v end
            end
        end
    end
end

local function saveAccount()
    local f = fs.open(SAVE_FILE, "w")
    if f then
        f.write(textutils.serializeJSON(account))
        f.close()
    end
end

loadSave()

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
-- MARKET PRICE SIMULATION ENGINE
-- ============================================================================
local function updateMarket()
    for _, ast in ipairs(ASSETS) do
        local delta = (math.random() - 0.49) * ast.baseVol
        local newClose = math.max(0.0001, ast.price + delta)
        local curOpen = ast.price
        local curHigh = math.max(curOpen, newClose) + math.random() * (ast.baseVol * 0.4)
        local curLow = math.min(curOpen, newClose) - math.random() * (ast.baseVol * 0.4)
        
        ast.price = newClose
        ast.high = math.max(ast.high, curHigh)
        ast.low = math.min(ast.low, curLow)
        
        table.remove(ast.history, 1)
        table.insert(ast.history, { open = curOpen, close = newClose, high = curHigh, low = curLow })
    end
    
    -- Check Active Futures Position & Liquidation
    if account.position then
        local pos = account.position
        local curAsset = ASSETS[pos.assetIdx]
        local priceDiff = curAsset.price - pos.entryPrice
        local pnlRatio = priceDiff / pos.entryPrice
        if pos.posType == "SHORT" then pnlRatio = -pnlRatio end
        
        local rawPnl = pnlRatio * pos.sizeUSDT
        
        -- Liquidation Check (Loss exceeds margin)
        if rawPnl <= -pos.margin then
            -- LIQUIDATION!
            account.totalProfitUSDT = account.totalProfitUSDT - pos.margin
            account.tradesCount = account.tradesCount + 1
            account.position = nil
            playSound("liq")
            saveAccount()
        end
    end
    
    -- Staking yield interest
    if account.stakedUSDT > 0 and math.random(1, 20) == 1 then
        local yield = account.stakedUSDT * 0.0002
        account.balanceUSDT = account.balanceUSDT + yield
        saveAccount()
    end
end

-- ============================================================================
-- FUTURES TRADING ACTIONS
-- ============================================================================
local function openPosition(posType)
    if account.position then return end
    local marginRequired = orderAmountUSDT / selectedLeverage
    if account.balanceUSDT < marginRequired then return end
    
    local curAsset = ASSETS[selectedAssetIdx]
    account.balanceUSDT = account.balanceUSDT - marginRequired
    
    -- Calculate Liquidation Price
    local liqDistance = (1.0 / selectedLeverage) * 0.9 -- 90% maintenance margin
    local liqPrice = 0
    if posType == "LONG" then
        liqPrice = curAsset.price * (1 - liqDistance)
    else
        liqPrice = curAsset.price * (1 + liqDistance)
    end
    
    account.position = {
        assetIdx = selectedAssetIdx,
        posType = posType,
        entryPrice = curAsset.price,
        sizeUSDT = orderAmountUSDT,
        margin = marginRequired,
        leverage = selectedLeverage,
        liqPrice = liqPrice
    }
    
    playSound(posType == "LONG" and "buy" or "sell")
    saveAccount()
end

local function closePosition()
    if not account.position then return end
    local pos = account.position
    local curAsset = ASSETS[pos.assetIdx]
    local priceDiff = curAsset.price - pos.entryPrice
    local pnlRatio = priceDiff / pos.entryPrice
    if pos.posType == "SHORT" then pnlRatio = -pnlRatio end
    
    local pnl = pnlRatio * pos.sizeUSDT
    account.balanceUSDT = account.balanceUSDT + pos.margin + pnl
    account.totalProfitUSDT = account.totalProfitUSDT + pnl
    account.tradesCount = account.tradesCount + 1
    if pnl > 0 then
        account.winsCount = account.winsCount + 1
        playSound("win")
    else
        playSound("sell")
    end
    
    account.position = nil
    saveAccount()
end

-- ============================================================================
-- RENDER PIPELINE
-- ============================================================================
local function renderBybit()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top Bybit Header Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local brand = " [ BYBIT PRO FUTURES ] "
    display.setCursorPos(2, 1)
    display.setTextColor(colors.yellow)
    display.write(brand)
    
    local curAsset = ASSETS[selectedAssetIdx]
    local signChg = (curAsset.change >= 0 and "+" or "-")
    local tickerInfo = string.format(" %s: $%.2f (%s%.2f%%)   24h High: $%.2f   Low: $%.2f ", curAsset.symbol, curAsset.price, signChg, math.abs(curAsset.change), curAsset.high, curAsset.low)
    display.setCursorPos(#brand + 3, 1)
    display.setTextColor(curAsset.change >= 0 and colors.lime or colors.red)
    display.write(tickerInfo)
    
    -- 2. Asset Selector Tabs (BTC, ETH, SOL, TON, DOGE)
    local tabY = 2
    local curTx = 2
    for idx, ast in ipairs(ASSETS) do
        local isSel = (selectedAssetIdx == idx)
        local btnLbl = string.format(" %s ", string.sub(ast.symbol, 1, 4))
        registerButton("ASSET_" .. idx, curTx, tabY, #btnLbl, 1, btnLbl, isSel and "yellow" or "lightGray", isSel and "blue" or "black")
        curTx = curTx + #btnLbl + 1
    end
    
    -- Leverage Selector Tabs
    local levX = screenW - 32
    display.setCursorPos(levX, tabY)
    display.setTextColor(colors.yellow)
    display.write("LEV: ")
    local leverages = { 1, 10, 25, 50, 100 }
    local lx = levX + 5
    for _, lev in ipairs(leverages) do
        local isSel = (selectedLeverage == lev)
        local lbl = string.format("[%dx]", lev)
        registerButton("LEV_" .. lev, lx, tabY, #lbl, 1, lbl, isSel and "yellow" or "lightGray", isSel and "blue" or "black")
        lx = lx + #lbl + 1
    end
    
    -- 3. Left Candlestick Chart (Live ASCII / Subpixel Candles)
    local chartX = 2
    local chartY = 4
    local chartW = math.floor(screenW * 0.58)
    local chartH = screenH - 12
    
    display.setCursorPos(chartX, chartY)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    display.write(" [ LIVE CANDLESTICK CHART ] ")
    
    -- Find Min / Max price in history
    local minP = 99999999
    local maxP = -99999999
    for _, c in ipairs(curAsset.history) do
        minP = math.min(minP, c.low)
        maxP = math.max(maxP, c.high)
    end
    if maxP == minP then maxP = minP + 1 end
    
    -- Draw Candles
    local numCandles = math.min(#curAsset.history, math.floor((chartW - 8) / 2))
    local startIdx = #curAsset.history - numCandles + 1
    
    for ci = 1, numCandles do
        local c = curAsset.history[startIdx + ci - 1]
        local cx = chartX + 1 + (ci - 1) * 2
        local isGreen = (c.close >= c.open)
        local candleCol = isGreen and colors.lime or colors.red
        
        local openY = chartY + 1 + math.floor((1 - (c.open - minP) / (maxP - minP)) * (chartH - 2))
        local closeY = chartY + 1 + math.floor((1 - (c.close - minP) / (maxP - minP)) * (chartH - 2))
        local highY = chartY + 1 + math.floor((1 - (c.high - minP) / (maxP - minP)) * (chartH - 2))
        local lowY = chartY + 1 + math.floor((1 - (c.low - minP) / (maxP - minP)) * (chartH - 2))
        
        local topY = math.min(openY, closeY)
        local botY = math.max(openY, closeY)
        
        for cy = chartY + 1, chartY + chartH do
            display.setCursorPos(cx, cy)
            display.setBackgroundColor(colors.black)
            
            if cy >= highY and cy <= lowY then
                display.setTextColor(candleCol)
                if cy >= topY and cy <= botY then
                    display.write("[]") -- Solid Body
                else
                    display.write("||") -- Wick
                end
            else
                display.write("  ")
            end
        end
    end
    
    -- Price Axis (Right of chart)
    for py = 0, 4 do
        local priceAtY = maxP - (py / 4) * (maxP - minP)
        local yPos = chartY + 1 + math.floor((py / 4) * (chartH - 1))
        display.setCursorPos(chartX + chartW - 7, yPos)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.lightGray)
        display.write(string.format("%7.1f", priceAtY))
    end
    
    -- 4. Right Side: Order Book & Trading Panel
    local orderX = chartX + chartW + 2
    local orderW = screenW - orderX - 1
    
    display.setCursorPos(orderX, 3)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(" [ ORDER BOOK & MARKET DEPTH ] ")
    
    -- Asks (Red / Sell Orders)
    for i = 1, 3 do
        local p = curAsset.price + (4 - i) * (curAsset.baseVol * 0.4)
        local vol = math.random(10, 80) / 10
        display.setCursorPos(orderX, 3 + i)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.red)
        display.write(string.format(" ASK  $%-8.2f  Vol: %4.1f ", p, vol))
    end
    
    -- Mid Spread Price
    display.setCursorPos(orderX, 7)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.format(" SPREAD: $%-8.2f USD ", curAsset.price))
    
    -- Bids (Green / Buy Orders)
    for i = 1, 3 do
        local p = curAsset.price - i * (curAsset.baseVol * 0.4)
        local vol = math.random(10, 80) / 10
        display.setCursorPos(orderX, 7 + i)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.lime)
        display.write(string.format(" BID  $%-8.2f  Vol: %4.1f ", p, vol))
    end
    
    -- Wallet Balance & Order Size
    local walY = 12
    display.setCursorPos(orderX, walY)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    display.write(" [ ACCOUNT WALLET & MARGIN ] ")
    
    display.setCursorPos(orderX, walY + 1)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write(string.format(" USDT Balance: $%.2f ", account.balanceUSDT))
    
    display.setCursorPos(orderX, walY + 2)
    display.setTextColor(colors.white)
    display.write(string.format(" Order Size  : $%d USDT ", orderAmountUSDT))
    
    -- Size Presets
    local btnAmtY = walY + 3
    registerButton("AMT_500", orderX, btnAmtY, 8, 1, " [$500] ", "yellow", "gray")
    registerButton("AMT_1000", orderX + 9, btnAmtY, 9, 1, " [$1000] ", "yellow", "gray")
    registerButton("AMT_2500", orderX + 19, btnAmtY, 9, 1, " [$2500] ", "yellow", "gray")
    registerButton("AMT_5000", orderX + 29, btnAmtY, 9, 1, " [$5000] ", "yellow", "gray")
    
    -- 5. Open Long / Short Buttons
    local tradeBtnY = walY + 5
    if not account.position then
        registerButton("BTN_LONG", orderX, tradeBtnY, 18, 2, " [ OPEN LONG (BUY) ] ", "white", "green")
        registerButton("BTN_SHORT", orderX + 20, tradeBtnY, 18, 2, " [ OPEN SHORT(SELL) ] ", "white", "red")
    else
        registerButton("BTN_CLOSE", orderX, tradeBtnY, 38, 2, " [ MARKET CLOSE POSITION (TAKE PnL) ] ", "yellow", "blue")
    end
    
    -- 6. Bottom Positions & Trade Analytics Bar
    local posBarY = screenH - 4
    display.setCursorPos(1, posBarY)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    if account.position then
        local pos = account.position
        local pAsset = ASSETS[pos.assetIdx]
        local priceDiff = pAsset.price - pos.entryPrice
        local pnlRatio = priceDiff / pos.entryPrice
        if pos.posType == "SHORT" then pnlRatio = -pnlRatio end
        local pnlUSDT = pnlRatio * pos.sizeUSDT
        local roePercent = pnlRatio * pos.leverage * 100
        
        local pnlSign = (pnlUSDT >= 0 and "+" or "-")
        local roeSign = (roePercent >= 0 and "+" or "-")
        local posText = string.format(" ACTIVE: %s %s %dx | Entry: $%.2f | Mark: $%.2f | Liq: $%.2f | PnL: %s$%.2f (%s%.2f%%) ",
            pos.posType, pAsset.symbol, pos.leverage, pos.entryPrice, pAsset.price, pos.liqPrice, pnlSign, math.abs(pnlUSDT), roeSign, math.abs(roePercent))
        
        display.setCursorPos(2, posBarY)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(pnlUSDT >= 0 and colors.lime or colors.red)
        display.write(posText)
    else
        display.setCursorPos(2, posBarY)
        display.setTextColor(colors.lightGray)
        display.write(" No open positions. Select Asset & Leverage, then click [ OPEN LONG ] or [ OPEN SHORT ].")
    end
    
    -- Bottom OS Bar
    display.setCursorPos(1, screenH)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", screenW))
    
    local profitSign = (account.totalProfitUSDT >= 0 and "+" or "-")
    local statStr = string.format(" Trades: %d (Win: %d)   PnL: %s$%.2f USDT ", account.tradesCount, account.winsCount, profitSign, math.abs(account.totalProfitUSDT))
    display.setCursorPos(2, screenH)
    display.setTextColor(account.totalProfitUSDT >= 0 and colors.lime or colors.red)
    display.write(statStr)
    
    registerButton("BTN_EARN", screenW - 24, screenH, 14, 1, "[ BYBIT EARN ]", "yellow", "blue")
    registerButton("BTN_QUIT", screenW - 8, screenH, 7, 1, "[ EXIT ]", "white", "red")
    
    drawButtons()
end

-- ============================================================================
-- MAIN TRADING LOOP
-- ============================================================================
local function main()
    local timerId = os.startTimer(0.4) -- Fast Real-Time Market Feed
    
    while true do
        renderBybit()
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(0.4)
            updateMarket()
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid and string.find(cid, "ASSET_") then
                local aIdx = tonumber(string.sub(cid, 7))
                if aIdx then selectedAssetIdx = aIdx end
                
            elseif cid and string.find(cid, "LEV_") then
                local lVal = tonumber(string.sub(cid, 5))
                if lVal then selectedLeverage = lVal end
                
            elseif cid == "AMT_500" then orderAmountUSDT = 500
            elseif cid == "AMT_1000" then orderAmountUSDT = 1000
            elseif cid == "AMT_2500" then orderAmountUSDT = 2500
            elseif cid == "AMT_5000" then orderAmountUSDT = 5000
            
            elseif cid == "BTN_LONG" then
                openPosition("LONG")
            elseif cid == "BTN_SHORT" then
                openPosition("SHORT")
            elseif cid == "BTN_CLOSE" then
                closePosition()
                
            elseif cid == "BTN_EARN" then
                -- Toggle Staking 50% of balance
                if account.balanceUSDT >= 1000 then
                    local stakeAmt = math.floor(account.balanceUSDT * 0.5)
                    account.balanceUSDT = account.balanceUSDT - stakeAmt
                    account.stakedUSDT = account.stakedUSDT + stakeAmt
                    playSound("win")
                    saveAccount()
                end
                
            elseif cid == "BTN_QUIT" then
                saveAccount()
                break
            end
            
        elseif event == "key" then
            if p1 == keys.q or p1 == keys.escape then
                saveAccount()
                break
            elseif p1 == keys.b then
                openPosition("LONG")
            elseif p1 == keys.s then
                openPosition("SHORT")
            elseif p1 == keys.c or p1 == keys.space then
                closePosition()
            elseif p1 == keys.one then selectedAssetIdx = 1
            elseif p1 == keys.two then selectedAssetIdx = 2
            elseif p1 == keys.three then selectedAssetIdx = 3
            elseif p1 == keys.four then selectedAssetIdx = 4
            elseif p1 == keys.five then selectedAssetIdx = 5
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("Bybit Trading Terminal closed. Portfolio saved.")
    else
        print("Bybit Trading Terminal closed. Portfolio saved.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Bybit Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Bybit Error: " .. tostring(err))
end
