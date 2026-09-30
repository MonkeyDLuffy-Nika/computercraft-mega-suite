-- ============================================================================
-- UNIVERSAL AE2 & ME NETWORK MONITOR PRO (FOLDER 10 EDITION)
-- Cyber OS 2077 Deluxe Industrial Edition
-- Supports: Advanced Peripherals ME Bridge, AE2 Interface / Controller, Wired Modems
-- ============================================================================

local display = term
local isMonitor = false

-- 1. Auto-detect External Multi-Block Monitor
local mon = peripheral.find("monitor")
if mon then
    display = mon
    isMonitor = true
    pcall(function() mon.setTextScale(0.5) end)
end

-- ============================================================================
-- FLUIX CYBERPUNK COLOR PALETTE
-- ============================================================================
local function applyAE2Palette()
    if display.setPaletteColor then
        display.setPaletteColor(colors.white, 0xFFFFFF)       -- Pure White
        display.setPaletteColor(colors.orange, 0xFF9100)      -- Amber Accent
        display.setPaletteColor(colors.magenta, 0xEB4BBE)     -- Fluix Crystal Pink
        display.setPaletteColor(colors.lightBlue, 0x64B4FF)   -- Fluix Glow Cyan
        display.setPaletteColor(colors.yellow, 0xFFD600)      -- Golden Metric
        display.setPaletteColor(colors.lime, 0x00E676)        -- Energy Green
        display.setPaletteColor(colors.pink, 0xFF80AB)        -- Certus Accent
        display.setPaletteColor(colors.gray, 0x182030)        -- Dark Fluix Glass
        display.setPaletteColor(colors.lightGray, 0x304058)   -- Slate Border
        display.setPaletteColor(colors.cyan, 0x18FFFF)        -- Neon Quantum Cyan
        display.setPaletteColor(colors.purple, 0x7C4DFF)      -- Pure Fluix Violet
        display.setPaletteColor(colors.blue, 0x0D1628)        -- Deep Space Navy
        display.setPaletteColor(colors.green, 0x1B4332)       -- Dark Emerald
        display.setPaletteColor(colors.brown, 0x5D4037)       -- Dark Bronze
        display.setPaletteColor(colors.red, 0xFF1744)         -- Alert Crimson
        display.setPaletteColor(colors.black, 0x080B12)       -- OLED Abyss Black
    end
end

applyAE2Palette()

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
-- UNIVERSAL PERIPHERAL ADAPTER ENGINE
-- ============================================================================
local mePeripheral = nil
local meType = "NONE"
local mePeripheralName = "NONE"
local workingApiMethod = "none"

local function findMEBridge()
    local allNames = peripheral.getNames()
    
    -- Priority 1: Advanced Peripherals ME Bridge
    for _, name in ipairs(allNames) do
        local pType = peripheral.getType(name) or ""
        local lowT = string.lower(pType)
        local lowN = string.lower(name)
        if string.find(lowT, "bridge") or string.find(lowN, "bridge") or lowT == "mebridge" or lowT == "me_bridge" then
            local p = peripheral.wrap(name)
            if p and (p.listItems or p.getItems or p.getItemList or p.listCraftableItems) then
                meType = "ME_BRIDGE"
                mePeripheralName = name
                return p
            end
        end
    end
    
    -- Priority 2: Applied Energistics 2 Interface / Controller / Storage
    for _, name in ipairs(allNames) do
        local pType = peripheral.getType(name) or ""
        local lowT = string.lower(pType)
        local lowN = string.lower(name)
        if string.find(lowT, "interface") or string.find(lowT, "controller") or string.find(lowN, "interface") or string.find(lowN, "controller") or string.find(lowT, "applied") or string.find(lowT, "ae2") then
            local p = peripheral.wrap(name)
            if p and (p.listItems or p.getItems or p.getItemList or p.listCraftableItems or p.list or p.getEnergyStorage or p.getStoredPower) then
                meType = pType
                mePeripheralName = name
                return p
            end
        end
    end
    
    -- Priority 3: Deep check any connected device with inventory/storage APIs
    for _, name in ipairs(allNames) do
        local pType = peripheral.getType(name) or ""
        if pType ~= "monitor" and name ~= "monitor" and pType ~= "modem" and pType ~= "speaker" and pType ~= "drive" then
            local p = peripheral.wrap(name)
            if p then
                if p.listItems or p.getItems or p.getItemList or p.listCraftableItems or (p.list and p.getItemDetail) then
                    meType = pType
                    mePeripheralName = name
                    return p
                end
            end
        end
    end
    
    meType = "NONE"
    mePeripheralName = "NONE"
    return nil
end

local function formatNumber(n)
    if not n then return "0" end
    local left, num, right = string.match(tostring(n), "^([^%d]*%d)(%d*)(.-)$")
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local function formatCompact(n)
    if not n then return "0" end
    if n >= 1000000000 then
        return string.format("%.1fB", n / 1000000000)
    elseif n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 10000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

local function cleanItemName(rawName, displayName)
    if displayName and #displayName > 0 then
        return displayName
    end
    if not rawName then return "Unknown Item" end
    local parts = {}
    local colonIdx = string.find(rawName, ":")
    local str = colonIdx and string.sub(rawName, colonIdx + 1) or rawName
    for word in string.gmatch(str, "([^_]+)") do
        table.insert(parts, string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2)))
    end
    return table.concat(parts, " ")
end

-- ============================================================================
-- APP STATE & DATA ENGINE
-- ============================================================================
local searchQuery = ""
local sortMode = "COUNT_DESC"
local currentPage = 1
local itemsPerPage = 12
local totalPages = 1
local cachedItems = {}
local filteredItems = {}
local totalItemCount = 0
local totalUniqueCount = 0
local energyStored = 0
local energyMax = 0
local energyUsage = 0
local autoRefreshInterval = 2.5
local lastRefreshTime = 0

local function fetchItemsFromME()
    mePeripheral = findMEBridge()
    if not mePeripheral then
        cachedItems = {}
        totalItemCount = 0
        totalUniqueCount = 0
        return
    end
    
    local rawList = nil
    
    -- Universal API probes
    if mePeripheral.listItems then
        local ok, res = pcall(mePeripheral.listItems)
        if ok and type(res) == "table" then rawList = res; workingApiMethod = "listItems" end
    end
    if not rawList and mePeripheral.getItems then
        local ok, res = pcall(mePeripheral.getItems)
        if ok and type(res) == "table" then rawList = res; workingApiMethod = "getItems" end
    end
    if not rawList and mePeripheral.getItemList then
        local ok, res = pcall(mePeripheral.getItemList)
        if ok and type(res) == "table" then rawList = res; workingApiMethod = "getItemList" end
    end
    if not rawList and mePeripheral.list then
        local ok, genericList = pcall(mePeripheral.list)
        if ok and type(genericList) == "table" then
            rawList = {}
            for slot, it in pairs(genericList) do
                table.insert(rawList, {
                    name = it.name,
                    count = it.count,
                    displayName = cleanItemName(it.name)
                })
            end
            workingApiMethod = "list"
        end
    end
    
    -- Energy metrics
    pcall(function()
        if mePeripheral.getEnergyStorage then
            energyStored = mePeripheral.getEnergyStorage() or 0
            energyMax = mePeripheral.getMaxEnergyStorage() or 0
            energyUsage = mePeripheral.getEnergyUsage() or 0
        elseif mePeripheral.getStoredPower then
            energyStored = mePeripheral.getStoredPower() or 0
            energyMax = mePeripheral.getMaxStoredPower() or 0
            energyUsage = mePeripheral.getAvgPowerUsage() or 0
        end
    end)
    
    local itemMap = {}
    totalItemCount = 0
    
    if type(rawList) == "table" then
        for _, item in pairs(rawList) do
            local count = item.amount or item.count or 0
            local name = item.name or item.id or "unknown"
            local dName = item.displayName or cleanItemName(name, item.displayName)
            local isCraftable = item.isCraftable or false
            
            if count > 0 or isCraftable then
                if itemMap[name] then
                    itemMap[name].count = itemMap[name].count + count
                else
                    itemMap[name] = {
                        rawName = name,
                        displayName = dName,
                        count = count,
                        isCraftable = isCraftable,
                        fingerprint = item.fingerprint or ""
                    }
                end
                totalItemCount = totalItemCount + count
            end
        end
    end
    
    local parsed = {}
    for _, item in pairs(itemMap) do
        table.insert(parsed, item)
    end
    
    cachedItems = parsed
    totalUniqueCount = #cachedItems
    lastRefreshTime = os.clock()
end

local function applyFiltersAndSort()
    filteredItems = {}
    local q = string.lower(searchQuery)
    
    for _, item in ipairs(cachedItems) do
        if q == "" or string.find(string.lower(item.displayName), q, 1, true) or string.find(string.lower(item.rawName), q, 1, true) then
            table.insert(filteredItems, item)
        end
    end
    
    if sortMode == "COUNT_DESC" then
        table.sort(filteredItems, function(a, b) return a.count > b.count end)
    elseif sortMode == "COUNT_ASC" then
        table.sort(filteredItems, function(a, b) return a.count < b.count end)
    elseif sortMode == "NAME_ASC" then
        table.sort(filteredItems, function(a, b) return string.lower(a.displayName) < string.lower(b.displayName) end)
    elseif sortMode == "NAME_DESC" then
        table.sort(filteredItems, function(a, b) return string.lower(a.displayName) > string.lower(b.displayName) end)
    end
    
    totalPages = math.max(1, math.ceil(#filteredItems / itemsPerPage))
    if currentPage > totalPages then currentPage = totalPages end
    if currentPage < 1 then currentPage = 1 end
end

-- ============================================================================
-- RENDER DETAIL POPUP MODAL
-- ============================================================================
local function renderDetailModal(item)
    local screenW, screenH = display.getSize()
    local bw = math.min(48, screenW - 4)
    local bh = 11
    local bx = math.floor((screenW - bw) / 2)
    local by = math.floor((screenH - bh) / 2)
    
    for dy = 0, bh do
        display.setCursorPos(bx, by + dy)
        display.setBackgroundColor(colors.blue)
        display.write(string.rep(" ", bw))
    end
    
    display.setCursorPos(bx, by)
    display.setTextColor(colors.cyan)
    display.write("+" .. string.rep("=", bw - 2) .. "+")
    display.setCursorPos(bx, by + bh)
    display.write("+" .. string.rep("=", bw - 2) .. "+")
    
    display.setCursorPos(bx + 2, by + 1)
    display.setTextColor(colors.yellow)
    display.write(">> ITEM SPECIFICATION BREAKDOWN <<")
    
    display.setCursorPos(bx + 2, by + 3)
    display.setTextColor(colors.white)
    display.write("NAME:    " .. string.sub(item.displayName, 1, bw - 12))
    
    display.setCursorPos(bx + 2, by + 4)
    display.setTextColor(colors.lightBlue)
    display.write("ID:      " .. string.sub(item.rawName, 1, bw - 12))
    
    display.setCursorPos(bx + 2, by + 6)
    display.setTextColor(colors.lime)
    display.write("TOTAL:   " .. formatNumber(item.count) .. " units")
    
    display.setCursorPos(bx + 2, by + 7)
    display.setTextColor(colors.cyan)
    display.write("STACKS:  " .. string.format("%d stacks + %d", math.floor(item.count / 64), item.count % 64))
    
    display.setCursorPos(bx + 2, by + 8)
    display.setTextColor(colors.orange)
    display.write("AUTOCRAFT: " .. (item.isCraftable and "[AVAILABLE]" or "[NO PATTERN]"))
    
    display.setCursorPos(bx + 2, by + 10)
    display.setTextColor(colors.yellow)
    display.write("[ Press ANY KEY or CLICK to Close ]")
    
    while true do
        local event = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            break
        end
    end
end

-- ============================================================================
-- MAIN UI RENDERER
-- ============================================================================
local function renderUI()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    -- 1. Top Glass Status Bar (Line 1)
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    local titleHdr = " >> AE2 QUANTUM ME MONITOR PRO <<"
    display.setCursorPos(2, 1)
    display.write(titleHdr)
    
    -- ME Online Status Indicator
    local statusText = mePeripheral and ("[ ME: " .. string.sub(mePeripheralName, 1, 10) .. " ]") or "[ ME: DISCONNECTED ]"
    local statusFg = mePeripheral and "lime" or "red"
    registerButton("BTN_REFRESH", screenW - 32, 1, 18, 1, statusText, statusFg, "gray")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    -- 2. Line 2: Telemetry Metrics Ribbon
    display.setCursorPos(1, 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.lightGray)
    display.write(string.rep(" ", screenW))
    
    display.setCursorPos(2, 2)
    display.setTextColor(colors.cyan)
    display.write("TOTAL ITEMS: ")
    display.setTextColor(colors.yellow)
    display.write(string.format("%-11s", formatCompact(totalItemCount)))
    
    display.setTextColor(colors.cyan)
    display.write(" | UNIQUE: ")
    display.setTextColor(colors.lime)
    display.write(string.format("%-6s", formatNumber(totalUniqueCount)))
    
    if energyMax > 0 then
        display.setTextColor(colors.cyan)
        display.write(" | ENERGY: ")
        display.setTextColor(colors.magenta)
        display.write(string.format("%s/%s AE", formatCompact(energyStored), formatCompact(energyMax)))
    else
        display.setTextColor(colors.cyan)
        display.write(" | ADAPTER: ")
        display.setTextColor(colors.white)
        display.write(string.sub(meType, 1, 16))
    end
    
    -- 3. Line 4: Search & Sort Control Bar
    display.setCursorPos(2, 4)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write("SEARCH: ")
    
    local searchBoxW = math.min(22, math.floor(screenW / 3))
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.white)
    local qShow = (searchQuery == "") and "< Click to Search >" or (searchQuery .. "_")
    display.write(string.format(" %-" .. (searchBoxW - 2) .. "s ", string.sub(qShow, 1, searchBoxW - 2)))
    registerButton("BTN_SEARCH", 10, 4, searchBoxW, 1, "", "white", "gray")
    
    if searchQuery ~= "" then
        registerButton("BTN_CLEAR_SEARCH", 10 + searchBoxW + 1, 4, 3, 1, "[X]", "white", "red")
    end
    
    local sortStartX = math.max(10 + searchBoxW + 6, screenW - 28)
    local sortLabel = " [SORT: COUNT v] "
    if sortMode == "COUNT_ASC" then sortLabel = " [SORT: COUNT ^] "
    elseif sortMode == "NAME_ASC" then sortLabel = " [SORT: NAME A-Z] "
    elseif sortMode == "NAME_DESC" then sortLabel = " [SORT: NAME Z-A] "
    end
    registerButton("TOGGLE_SORT", sortStartX, 4, #sortLabel, 1, sortLabel, "yellow", "blue")
    
    -- 4. Items Table (Lines 6 to screenH - 3)
    local tableStartY = 6
    local tableEndY = screenH - 3
    local tableH = tableEndY - tableStartY + 1
    itemsPerPage = tableH
    
    display.setCursorPos(2, tableStartY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.cyan)
    display.write(" " .. string.format("%-4s", "#") .. string.format("%-" .. (screenW - 22) .. "s", "ITEM NAME") .. string.format("%14s", "QUANTITY ") .. " ")
    
    local startIdx = (currentPage - 1) * itemsPerPage + 1
    local endIdx = math.min(#filteredItems, startIdx + itemsPerPage - 1)
    
    for row = 1, tableH - 1 do
        local cy = tableStartY + row
        local itemIdx = startIdx + row - 1
        local item = filteredItems[itemIdx]
        
        display.setCursorPos(2, cy)
        local rowBg = (row % 2 == 1) and colors.gray or colors.black
        display.setBackgroundColor(rowBg)
        display.write(string.rep(" ", screenW - 2))
        
        if item then
            display.setCursorPos(3, cy)
            display.setTextColor(colors.lightGray)
            display.write(string.format("%-4d", itemIdx))
            
            display.setTextColor(colors.white)
            local maxNameLen = screenW - 23
            display.write(string.sub(item.displayName, 1, maxNameLen))
            
            display.setCursorPos(screenW - 16, cy)
            if item.count >= 1000000 then
                display.setTextColor(colors.magenta)
            elseif item.count >= 10000 then
                display.setTextColor(colors.yellow)
            elseif item.count >= 1000 then
                display.setTextColor(colors.lime)
            else
                display.setTextColor(colors.lightBlue)
            end
            display.write(string.format("%14s", formatNumber(item.count) .. " "))
            
            registerButton("ITEM_" .. itemIdx, 2, cy, screenW - 2, 1, "", "white", "gray")
        else
            if not mePeripheral and row == 2 then
                display.setCursorPos(4, cy)
                display.setTextColor(colors.red)
                display.write(">> NO ME PERIPHERAL DETECTED!")
            elseif not mePeripheral and row == 3 then
                display.setCursorPos(4, cy)
                display.setTextColor(colors.yellow)
                display.write(">> Run 'test_me' in computer shell to see all attached blocks & APIs.")
            elseif not mePeripheral and row == 4 then
                display.setCursorPos(4, cy)
                display.setTextColor(colors.lightBlue)
                display.write(">> Ensure Wired Modems on network cables are right-clicked (glowing red).")
            elseif #filteredItems == 0 and row == 2 then
                display.setCursorPos(4, cy)
                display.setTextColor(colors.orange)
                display.write(">> No items found in ME storage (or matching filter '" .. searchQuery .. "').")
            end
        end
    end
    
    -- 5. Bottom Navigation Dock
    local navY = screenH - 1
    display.setCursorPos(1, navY)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    
    registerButton("PAGE_PREV", 2, navY, 10, 1, " [< PREV] ", "white", "gray")
    
    local pageStr = string.format(" PAGE %d / %d (%d items) ", currentPage, totalPages, #filteredItems)
    display.setCursorPos(math.max(14, math.floor((screenW - #pageStr) / 2)), navY)
    display.setTextColor(colors.yellow)
    display.write(pageStr)
    
    registerButton("PAGE_NEXT", screenW - 11, navY, 10, 1, " [NEXT >] ", "white", "gray")
    
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.lightBlue)
    display.write(" [ARROWS] Scroll | [F] Search | [S] Sort | [R] Refresh | [CLICK] Inspect | [Q] Exit ")
    
    drawButtons()
end

-- ============================================================================
-- SEARCH INPUT MODAL
-- ============================================================================
local function promptSearchInput()
    local screenW, screenH = display.getSize()
    local bw = math.min(42, screenW - 4)
    local bx = math.floor((screenW - bw) / 2)
    local by = math.floor(screenH / 2) - 2
    
    for dy = 0, 4 do
        display.setCursorPos(bx, by + dy)
        display.setBackgroundColor(colors.blue)
        display.write(string.rep(" ", bw))
    end
    
    display.setCursorPos(bx + 2, by + 1)
    display.setTextColor(colors.yellow)
    display.write(">> ENTER SEARCH QUERY <<")
    
    display.setCursorPos(bx + 2, by + 2)
    display.setTextColor(colors.lightBlue)
    display.write("(Press ENTER to search, ESC to cancel)")
    
    local q = searchQuery
    while true do
        display.setCursorPos(bx + 2, by + 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.white)
        display.write(string.format(" %-30s ", string.sub(q .. "_", 1, 30)))
        
        local event, p1 = os.pullEvent()
        if event == "key" then
            if p1 == keys.enter then
                searchQuery = q
                currentPage = 1
                break
            elseif p1 == keys.escape then
                break
            elseif p1 == keys.backspace then
                if #q > 0 then q = string.sub(q, 1, #q - 1) end
            end
        elseif event == "char" then
            if #q < 24 then q = q .. p1 end
        end
    end
end

-- ============================================================================
-- MAIN EVENT LOOP
-- ============================================================================
local function main()
    fetchItemsFromME()
    applyFiltersAndSort()
    
    local autoTimer = os.startTimer(autoRefreshInterval)
    local needsRedraw = true
    
    while true do
        if needsRedraw then
            renderUI()
            needsRedraw = false
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == autoTimer then
            fetchItemsFromME()
            applyFiltersAndSort()
            needsRedraw = true
            autoTimer = os.startTimer(autoRefreshInterval)
            
        elseif event == "key" then
            needsRedraw = true
            if p1 == keys.q or p1 == keys.escape then
                break
            elseif p1 == keys.f or p1 == keys.slash then
                promptSearchInput()
                applyFiltersAndSort()
            elseif p1 == keys.r then
                fetchItemsFromME()
                applyFiltersAndSort()
            elseif p1 == keys.s then
                if sortMode == "COUNT_DESC" then sortMode = "COUNT_ASC"
                elseif sortMode == "COUNT_ASC" then sortMode = "NAME_ASC"
                elseif sortMode == "NAME_ASC" then sortMode = "NAME_DESC"
                else sortMode = "COUNT_DESC" end
                applyFiltersAndSort()
            elseif p1 == keys.right or p1 == keys.pageDown or p1 == keys.n or p1 == keys.d then
                currentPage = (currentPage % totalPages) + 1
            elseif p1 == keys.left or p1 == keys.pageUp or p1 == keys.p or p1 == keys.a then
                currentPage = (currentPage == 1) and totalPages or (currentPage - 1)
            elseif p1 == keys.home then
                currentPage = 1
            elseif p1 == keys.endKey then
                currentPage = totalPages
            end
            
        elseif event == "mouse_scroll" then
            needsRedraw = true
            local dir = p1
            if dir > 0 then
                currentPage = math.min(totalPages, currentPage + 1)
            else
                currentPage = math.max(1, currentPage - 1)
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            needsRedraw = true
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_QUIT" then
                break
            elseif cid == "BTN_REFRESH" then
                fetchItemsFromME()
                applyFiltersAndSort()
            elseif cid == "BTN_SEARCH" then
                promptSearchInput()
                applyFiltersAndSort()
            elseif cid == "BTN_CLEAR_SEARCH" then
                searchQuery = ""
                applyFiltersAndSort()
            elseif cid == "TOGGLE_SORT" then
                if sortMode == "COUNT_DESC" then sortMode = "COUNT_ASC"
                elseif sortMode == "COUNT_ASC" then sortMode = "NAME_ASC"
                elseif sortMode == "NAME_ASC" then sortMode = "NAME_DESC"
                else sortMode = "COUNT_DESC" end
                applyFiltersAndSort()
            elseif cid == "PAGE_PREV" then
                currentPage = (currentPage == 1) and totalPages or (currentPage - 1)
            elseif cid == "PAGE_NEXT" then
                currentPage = (currentPage % totalPages) + 1
            elseif cid and string.sub(cid, 1, 5) == "ITEM_" then
                local itemIdx = tonumber(string.sub(cid, 6))
                if itemIdx and filteredItems[itemIdx] then
                    renderDetailModal(filteredItems[itemIdx])
                end
            end
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    if isMonitor then
        display.write("AE2 Monitor closed.")
    else
        print("AE2 Monitor closed.")
    end
end

local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("AE2 Monitor Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("AE2 Monitor Error: " .. tostring(err))
end
