local function stopAllAudio()
    local spList = { peripheral.find("speaker") }
    for _, sp in ipairs(spList) do
        if sp and sp.stop then
            pcall(function() sp.stop() end)
        end
    end
end

-- ============================================================================
-- CYBER OS 2077: DELUXE HD LAUNCHER (SEAMLESS FULL-SCREEN LAUNCH & HOME FX)
-- Full-Screen Launch Terminal, Glowing Home Dashboard HUD, 3x4 Grid & Easter Egg
-- ============================================================================

local display = term
local isMonitor = false

-- Auto-detect external multi-block monitor
local mon = peripheral.find("monitor")
if mon then
    display = mon
    isMonitor = true
    pcall(function() mon.setTextScale(0.5) end)
end

local speaker = peripheral.find("speaker")

-- ============================================================================
-- THEMES & CONFIGURATION ENGINE
-- ============================================================================
local CONFIG_FILE = ".hub_config"
local config = {
    theme = "NEON",
    soundEnabled = false,
    instantLaunch = false,
    clock24h = true,
    textScale = 0.5,
    favorites = { ["SUPER MARIO"] = true, ["SOLS RNG"] = true, ["MINESWEEPER"] = true, ["CYBER TETRIS"] = true }
}

local function loadConfig()
    if fs.exists(CONFIG_FILE) then
        local f = fs.open(CONFIG_FILE, "r")
        if f then
            local data = textutils.unserialize(f.readAll())
            f.close()
            if type(data) == "table" then
                for k, v in pairs(data) do config[k] = v end
            end
        end
    end
end

local function saveConfig()
    local f = fs.open(CONFIG_FILE, "w")
    if f then
        f.write(textutils.serialize(config))
        f.close()
    end
end

loadConfig()

-- 6 Curated Themes
local THEMES = {
    ["NEON"] = {
        name = "Cyber Neon",
        bg = colors.black, cardBg = colors.gray, cardSel = colors.blue,
        borderSel = colors.yellow, barBg = colors.blue, barFg = colors.yellow, accent = colors.lightBlue
    },
    ["EMERALD"] = {
        name = "Matrix Green",
        bg = colors.black, cardBg = colors.green, cardSel = colors.lime,
        borderSel = colors.lime, barBg = colors.green, barFg = colors.lime, accent = colors.lime
    },
    ["SOLAR"] = {
        name = "Solar Amber",
        bg = colors.black, cardBg = colors.brown, cardSel = colors.orange,
        borderSel = colors.yellow, barBg = colors.brown, barFg = colors.yellow, accent = colors.orange
    },
    ["ICE"] = {
        name = "Deep Space",
        bg = colors.black, cardBg = colors.gray, cardSel = colors.cyan,
        borderSel = colors.white, barBg = colors.blue, barFg = colors.cyan, accent = colors.lightBlue
    },
    ["SYNTH"] = {
        name = "Synthwave",
        bg = colors.black, cardBg = colors.purple, cardSel = colors.magenta,
        borderSel = colors.yellow, barBg = colors.purple, barFg = colors.yellow, accent = colors.pink
    },
    ["OLED"] = {
        name = "OLED Minimal",
        bg = colors.black, cardBg = colors.gray, cardSel = colors.lightGray,
        borderSel = colors.white, barBg = colors.gray, barFg = colors.white, accent = colors.white
    }
}

local function applyPalette()
    if display.setPaletteColor then
        display.setPaletteColor(colors.white, 0xFFFFFF)
        display.setPaletteColor(colors.orange, 0xFF9100)
        display.setPaletteColor(colors.magenta, 0xFF1776)
        display.setPaletteColor(colors.lightBlue, 0x00E5FF)
        display.setPaletteColor(colors.yellow, 0xFFD600)
        display.setPaletteColor(colors.lime, 0x00E676)
        display.setPaletteColor(colors.pink, 0xFF80AB)
        display.setPaletteColor(colors.gray, 0x181F2C)
        display.setPaletteColor(colors.lightGray, 0x303E55)
        display.setPaletteColor(colors.cyan, 0x18FFFF)
        display.setPaletteColor(colors.purple, 0x7C4DFF)
        display.setPaletteColor(colors.blue, 0x0D1628)
        display.setPaletteColor(colors.green, 0x1B4332)
        display.setPaletteColor(colors.brown, 0x5D4037)
        display.setPaletteColor(colors.red, 0xFF1744)
        display.setPaletteColor(colors.black, 0x080B11)
    end
end

applyPalette()

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

local function playSound(snd)
    if not speaker or not config.soundEnabled then return end
end

-- ============================================================================
-- SECRET CREATOR EASTER EGG SCREEN ART & PALETTE
-- ============================================================================
local function applyEasterEggPalette()
    if display.setPaletteColor then
        display.setPaletteColor(colors.white,     0xFFFCFA) -- White BG & Eye Sparkles
        display.setPaletteColor(colors.orange,    0xCAB4A0) -- Ash Blonde Hair Base
        display.setPaletteColor(colors.magenta,   0xF28AA2) -- Cute Rose Blush & Mouth
        display.setPaletteColor(colors.lightBlue, 0xBEC4DA) -- Pastel Hoodie & Ears
        display.setPaletteColor(colors.yellow,    0xEEE2D6) -- Hair Highlights
        display.setPaletteColor(colors.lime,      0x00E676)
        display.setPaletteColor(colors.pink,      0xFFE6DE) -- Soft Creamy Peach Skin
        display.setPaletteColor(colors.gray,      0x44343C) -- Eyelashes & Linework
        display.setPaletteColor(colors.lightGray, 0xF4CCBE) -- Warm Skin Shadow
        display.setPaletteColor(colors.cyan,      0x8744BA) -- Vibrant Purple Anime Eyes
        display.setPaletteColor(colors.purple,    0xC06CEE) -- Bright Electric Eye Sparkle
        display.setPaletteColor(colors.blue,      0x261038) -- Midnight Dark Pupil
        display.setPaletteColor(colors.brown,     0x9A826E) -- Deep Blonde Hair Shadow
        display.setPaletteColor(colors.green,     0x1B4332)
        display.setPaletteColor(colors.red,       0xDC3C5C) -- Deep Lip/Cheek Accent
        display.setPaletteColor(colors.black,     0x695244) -- Deepest Hair Shadow
    end
end

local AHAREN_ART = {
    [1] = { ch = "                         \140\140\140\140      ", fg = "00000000000000000000000000044000000", bg = "00000000000000000000000004111000000" },
    [2] = { ch = "                       \140\140   \140      ", fg = "00000000000000000000000440001000000", bg = "00000000000000000000000811c18000000" },
    [3] = { ch = "              \140\140\140  \140\140\140\140  \140         ", fg = "00000000000000041004008001000000000", bg = "000000000000008ccc1c111113118000000" },
    [4] = { ch = "     \140\140\140\140\140  \140 \140    \140    \140 \140\140\140      ", fg = "00000000000000c0000c000010488000000", bg = "0000064446008111c111111134644000000" },
    [5] = { ch = "         \140\140\140            \140          ", fg = "00000000048800000000000080000000000", bg = "00008888881111111111111114644000000" },
    [6] = { ch = "    \140 \140    \140         \140\140\140 \140\140        ", fg = "00004080000100000000011808400000000", bg = "00006118811881111111188411814000000" },
    [7] = { ch = "     \140\140\140      \140 \140\140   \140             ", fg = "00000111000000101100080000000000000", bg = "00000884818881818888118481114000000" },
    [8] = { ch = "      \140    \140\140\140        \140\140    \140      ", fg = "00000040000881000000008400006000000", bg = "00000406418418888888811881118000000" },
    [9] = { ch = "      \140\140\140 \140 \140        \140       \140     ", fg = "00000006808010000000080000000000000", bg = "00000048114488888888861881111600000" },
    [10] = { ch = "       \140  \140       \140 \140\140\140      \140     ", fg = "00000001004000000080841000000600000", bg = "0000004cc18884488818188181111400000" },
    [11] = { ch = "      \140\140      \140              \140\140    ", fg = "0000004c000000400000000000000800000", bg = "00000001c18184888811188111111160000" },
    [12] = { ch = "      \140 \140 \140     \140     \140            ", fg = "00000000c08000008000008000000000000", bg = "00000061111184881811111111111166000" },
    [13] = { ch = "      \140            \140 \140 \140  \140    \140   ", fg = "00000060000000000001010100100006000", bg = "000000081111881111188818118c1140000" },
    [14] = { ch = "      \140    \140    \140      \140 \140    \140    ", fg = "00000000000100001000000801000080000", bg = "00000061c11c111181188811188c1110000" },
    [15] = { ch = "           \140\140  \140  \140 \140\140\140\140      \140\140   ", fg = "00000000000c100100801ffc00000016000", bg = "00000061c11188188844c7bf188c11c4000" },
    [16] = { ch = "            \140\140\140  \140\140 \140\140\140 \140      \140   ", fg = "00000000000088800860cc7010000004000", bg = "0000004cc1111fc844048a9c881c11c8000" },
    [17] = { ch = "      \140   \140  \140\140 \140\140  \140\140\140\140           ", fg = "000000800010077046004a9300000000000", bg = "0000001cc18c1c9160006886481cc1c8600" },
    [18] = { ch = "           \140  \140\140      \140 \140    \140 \140   ", fg = "00000000000c00910000004040000108000", bg = "0000061cc1814aa800000666881cccc1600" },
    [19] = { ch = "    \140        \140\140         \140      \140   ", fg = "00000000000008800000000080000001000", bg = "0000661cc188666600000666111ccccc400" },
    [20] = { ch = "     \140   \140 \140\140                   \140  ", fg = "00000400010860000000000000000000800", bg = "000068cccc81466600000064111ccccc160" },
    [21] = { ch = "          \140 \140  \140   \140            \140\140 ", fg = "00000000008010060006000000000000160", bg = "000061cccc11866006140064111ccccc840" },
    [22] = { ch = "         \140\140\140 \140\140  \140\140\140  \140\140  \140\140\140\140     ", fg = "000000000c140460068400480081cc00000", bg = "000641ccc34681400066008c146611cc840" },
    [23] = { ch = "  \140   \140\140   \140\140  \140    \140\140\140  \140    \140\140  \140", fg = "0000001c00068000000004100800001c000", bg = "006648c134446118000061c116606481846" },
    [24] = { ch = "      \140        \140\140\140\140\140  \140        \140\140  ", fg = "00000030000000021600002000000003800", bg = "00664844444461112188811216604444344" },
    [25] = { ch = "    \140     \140 \140           \140\140\140\140       ", fg = "00008000004040000000000018480000000", bg = "00663444443481188888888121818444344" },
    [26] = { ch = "           \140 \140            \140  \140\140    ", fg = "00000000000302000000000000800880000", bg = "0064344444311c18888888812ccc1134444" },
    [27] = { ch = "          \140\140     \140\140     \140          ", fg = "00000000003100000880000020000000000", bg = "00641444441ccc1866688881cccccc34444" },
    [28] = { ch = "  \140       \140     \140   \140              ", fg = "00600000001000006000600000000000000", bg = "0044344434cccc1180000681ccccc144444" },
    [29] = { ch = "         \140   \140    \140\140     \140\140\140 \140     ", fg = "0000000004000c0000000000011c0300000", bg = "0044444443ccc111166606811331c444443" },
    [30] = { ch = "   \140    \140  \140\140\140\140  \140 \140 \140             ", fg = "00040000400c38800406060000000000000", bg = "0043444433c14441186004881341c444443" },
    [31] = { ch = "  \140     \140\140  \140     \140 \140    \140\140  \140     ", fg = "00400000310040000060600003300400000", bg = "008344441c13344888404488111cc844443" },
    [32] = { ch = "  \140     \140\140 \140\140 \140      \140 \140     \140    \140", fg = "008000001c0330400000080400000300008", bg = "00444444c1388433884443331131c144443" },
    [33] = { ch = " \140        \140   \140       \140\140\140 \140        ", fg = "06000000003000800000001330300000000", bg = "04444443c1448448884443848881c144443" },
    [34] = { ch = "\140             \140   \140   \140   \140        ", fg = "40000000000000300040008000800000000", bg = "83444443c1444418888444344811c144443" }
}


-- ============================================================================

-- ============================================================================
-- 2x2 CINEMA & VIDEO SHOWCASE DATABASE (WITH HD TELETEXT KEYFRAME PREVIEWS)
-- ============================================================================
local VIDEOS_LIST = {
    [1] = {
        name = "UTA - NEW GENESIS",
        file = "uta.lua",
        tag = "16-COLOR HD",
        author = "One Piece Film: Red",
        dur = "2:00 min",
        desc = "Vibrant CIELAB 16-Color RGB Animation + 48kHz Digital Sound",
        preview = {
            [1] = { ch = "\133\131\129\128\128\128\128\128\128\130\143\131\128\128", fg = "888eeeeee889ee", bg = "33333333333899" },
            [2] = { ch = "\139\129\128\128\128\128\128\148\151\139\144\138\143\139", fg = "36eeeee8636389", bg = "80000006003600" },
            [3] = { ch = "\128\138\135\139\144\128\128\143\133\148\138\144\130\129", fg = "e0603ee8886600", bg = "88860000000388" },
            [4] = { ch = "\131\129\135\143\143\131\132\131\131\139\131\143\139\143", fg = "98988070060038", bg = "79777c87cc8866" },
            [5] = { ch = "\128\129\143\143\143\137\131\130\130\131\141\130\138\143", fg = "ec77778cc77766", bg = "77999999989999" },
            [6] = { ch = "\128\128\130\131\131\131\131\131\131\131\131\131\129\128", fg = "eec999999999ce", bg = "77777777777777" },
            [7] = { ch = "\128\128\128\128\128\128\128\128\128\128\128\128\128\128", fg = "eeeeeeeeeeeeee", bg = "77777777777777" }
        }
    },
    [2] = {
        name = "BAD APPLE!!",
        file = "bad_apple.lua",
        tag = "SHADOW HD",
        author = "Touhou Project",
        dur = "3:39 min",
        desc = "Legendary 60FPS Shadow Art Subpixel Teletext + 48kHz Sound",
        preview = {
            [1] = { ch = "\128\128\128\128\128\128\140\140\128\128\128\128\128\128", fg = "000000eeee0000", bg = "ffffffffff0fff" },
            [2] = { ch = "\128\128\128\128\140\140\140\140\140\140\128\128\128\128", fg = "0000eeeeeeee0000", bg = "ffffffffffffff" },
            [3] = { ch = "\128\128\140\140\140\140\140\140\140\140\140\140\128\128", fg = "00eeeeeeeeeeee00", bg = "ffffffffffffff" },
            [4] = { ch = "\128\140\140\140\140\140\140\140\140\140\140\140\140\128", fg = "0eeeeeeeeeeeee0", bg = "ffffffffffffff" },
            [5] = { ch = "\128\140\140\140\140\140\140\140\140\140\140\140\140\128", fg = "0eeeeeeeeeeeee0", bg = "ffffffffffffff" },
            [6] = { ch = "\128\128\140\140\140\140\140\140\140\140\140\140\128\128", fg = "00eeeeeeeeeeee00", bg = "ffffffffffffff" },
            [7] = { ch = "\128\128\128\140\140\140\128\128\140\140\140\128\128\128", fg = "000eeee00eeee000", bg = "ffffffffffffff" }
        }
    },
    [3] = {
        name = "DECO*27 - MONITORING",
        file = "miku.lua",
        tag = "VOCALOID HD",
        author = "feat. Hatsune Miku",
        dur = "3:01 min",
        desc = "Official MV Animation with 16-Color CIELAB + 48kHz Digital Audio",
        preview = {
            [1] = { ch = "\128\128\128\128\137\131\128\129\133\144\138\128\128\129", fg = "ccccf7e7f37cc7", bg = "ffff7bbfb88fff" },
            [2] = { ch = "\128\128\135\156\140\135\139\128\138\143\143\133\143\132", fg = "ccf77ffc838977", bg = "ff7ff77ffff7ff" },
            [3] = { ch = "\128\130\131\149\128\149\149\128\128\130\128\133\128\128", fg = "c77bc88ccbcbcc", bg = "fff7f7ffffffff" },
            [4] = { ch = "\128\128\128\128\128\142\143\143\144\128\128\128\128\128", fg = "cccccfffbccccc", bg = "fffff7eaffffff" },
            [5] = { ch = "\128\128\128\128\151\144\151\148\128\129\143\143\144\128", fg = "ccccffb9cfff7c", bg = "ffff7b3ffbb7ff" },
            [6] = { ch = "\128\128\139\131\128\128\130\129\151\128\142\131\128\128", fg = "ccffcc97fc7bcc", bg = "ff77ffffbfffff" },
            [7] = { ch = "\159\128\131\133\128\159\143\144\156\128\128\128\128\144", fg = "fc77cff7fcccc7", bg = "7ffff77f7fffff" }
        }
    },
    [4] = {
        name = "JOJO - MISTA'S PAST",
        file = "mista.lua",
        tag = "GOLDEN WIND HD",
        author = "Guido Mista & Stand",
        dur = "3:42 min",
        desc = "Action-Packed JoJo Anime Scene with 16-Color CIELAB + 48kHz Audio",
        preview = {
            [1] = { ch = "\144\128\151\159\149\129\129\151\129\149\128\128\128\128", fg = "ce8898c7efcccc", bg = "88cc6c7e77ffff" },
            [2] = { ch = "\158\130\138\133\149\143\128\134\128\159\132\128\143\144", fg = "88987ceee77cf7", bg = "cccc877c7bff7f" },
            [3] = { ch = "\149\128\149\148\149\128\151\131\152\136\155\141\149\128", fg = "8ec87e77fe77cc", bg = "c77787ff77cc7f" },
            [4] = { ch = "\148\135\159\157\149\128\138\128\128\144\149\128\149\128", fg = "77c87efeef7e8c", bg = "ce87877777c8cf" },
            [5] = { ch = "\128\144\149\149\149\128\149\131\143\128\138\159\159\128", fg = "e7e87e7f7e887c", bg = "7e8787f7ffccff" },
            [6] = { ch = "\143\138\135\128\149\128\138\151\135\150\159\133\128\128", fg = "7cce7ef7ffcccc", bg = "f777877f7777ff" },
            [7] = { ch = "\129\151\128\128\149\128\159\144\144\129\129\149\140\128", fg = "f7ee7e7f7fc77c", bg = "cc7787c7cc7fff" }
        }
    },
    [5] = {
        name = "MADE IN HEAVEN",
        file = "heaven.lua",
        tag = "CRUCIFIED HD",
        author = "Enrico Pucci AMV",
        dur = "0:59 min",
        desc = "Fast-Paced Stone Ocean AMV with 16-Color CIELAB + 48kHz Sound",
        preview = {
            [1] = { ch = "\128\159\135\129\128\159\159\138\149\159\129\129\149\128", fg = "cfffebdd7ffb8e", bg = "fbbbb777fbb877" },
            [2] = { ch = "\148\130\128\128\143\133\149\148\151\158\135\135\135\130", fg = "bbeebb89f33877", bg = "ffbb38777bb7bb" },
            [3] = { ch = "\140\130\130\131\149\141\148\148\144\149\128\128\128\128", fg = "3733bb0788eeee", bg = "bbbb38887bbbbb" },
            [4] = { ch = "\149\130\133\128\129\130\151\129\148\129\128\128\128\128", fg = "f88eb069f3eeee", bg = "bbbb6677bbbbbb" },
            [5] = { ch = "\157\128\159\134\148\159\138\128\128\139\144\128\128\128", fg = "feb3b87ccbfeee", bg = "bbab6b8fffbbbb" },
            [6] = { ch = "\128\128\150\128\149\155\129\128\128\128\128\144\128\128", fg = "ce3eb89ccccfee", bg = "fbbb8b7ffffbbb" },
            [7] = { ch = "\128\138\128\128\133\148\128\128\128\159\128\138\128\128", fg = "c3eebdcccfcbee", bg = "fbbb97fffbffbb" }
        }
    },
    [6] = {
        name = "JOJO - TORTURE DANCE",
        file = "dance.lua",
        tag = "GOLDEN WIND HD",
        author = "Passione Gang Trio",
        dur = "0:59 min",
        desc = "Legendary Boat Dance Scene with 16-Color CIELAB + 48kHz Digital Audio",
        preview = {
            [1] = { ch = "\128\128\128\128\128\128\128\128\128\128\135\143\151\130", fg = "eeeeeeeeee9338", bg = "999999999900c7" },
            [2] = { ch = "\143\143\143\143\143\143\143\143\143\130\138\151\148\137", fg = "99999999933379", bg = "777777777997bb" },
            [3] = { ch = "\128\131\149\149\128\128\128\131\131\131\156\145\138\143", fg = "e39feee9990bbb", bg = "00760000009777" },
            [4] = { ch = "\151\151\149\130\148\144\143\143\148\128\149\149\138\148", fg = "098c70898e0b79", bg = "90c7880000b7fb" },
            [5] = { ch = "\151\151\149\128\149\133\143\149\149\159\138\149\158\143", fg = "998cf83393bbbb", bg = "b87f9999399977" },
            [6] = { ch = "\138\142\159\131\149\128\129\138\149\130\129\158\149\151", fg = "b99fcec09999be", bg = "9bcc338333bbc8" },
            [7] = { ch = "\128\136\149\141\130\143\130\129\138\135\150\131\149\128", fg = "e391930033b3bc", bg = "bbcec933bb9bce" }
        }
    },
    [7] = {
        name = "ZACEPILA - PARODY",
        file = "zacepila.lua",
        tag = "PARODY HD",
        author = "Arthur Pirozhkov Clip",
        dur = "2:13 min",
        desc = "Funny Minecraft Parody MV with 16-Color CIELAB + 48kHz Audio",
        preview = {
            [1] = { ch = "\128\128\128\128\128\128\128\128\128\128\128\128\128\128", fg = "cccccccccccccc", bg = "ffffffffffffff" },
            [2] = { ch = "\128\128\128\128\128\128\135\139\128\128\128\140\132\128", fg = "ccccccffccc77c", bg = "ffffff77ffffff" },
            [3] = { ch = "\128\132\128\128\128\159\146\136\143\128\128\128\128\128", fg = "c7cccfcffccccc", bg = "fffff7777fffff" },
            [4] = { ch = "\128\128\133\159\143\140\130\135\131\131\132\128\128\128", fg = "ccf7ffec777ccc", bg = "ff7887c7ffffff" },
            [5] = { ch = "\128\128\131\130\129\143\144\149\128\128\128\128\128\128", fg = "cc70670ccccccc", bg = "ffffc8cfffffff" },
            [6] = { ch = "\128\128\128\128\151\132\131\128\128\128\128\128\128\128", fg = "ccccf88ccccccc", bg = "ffff7c7fffffff" },
            [7] = { ch = "\128\128\128\128\130\131\129\128\128\128\128\128\128\128", fg = "cccc777ccccccc", bg = "ffffffffffffff" }
        }
    },
    [8] = {
        name = "TF2 - POOTIS ENGAGE",
        file = "pootis.lua",
        tag = "ACTION HD",
        author = "ceno0 / Dub",
        dur = "8:35 min",
        desc = "Epic Heavy Anime Action Movie with 16-Color CIELAB + 48kHz Audio",
        preview = {
            [1] = { ch = "\128\128\131\139\131\131\131\131\136\135\136\136\159\131", fg = "ee777777cfcf77", bg = "4448cccc7c77cc" },
            [2] = { ch = "\131\129\128\131\144\128\144\128\128\151\131\144\130\135", fg = "44e41d7dec7ecc", bg = "1111cccc78e777" },
            [3] = { ch = "\135\148\149\147\144\132\129\128\132\130\135\128\157\150", fg = "141e777dc4eeff", bg = "41c7eccc777777" },
            [4] = { ch = "\128\149\144\128\130\142\131\129\136\130\141\135\128\128", fg = "e47c7cccffffee", bg = "4eeee777777777" },
            [5] = { ch = "\138\149\144\128\135\128\128\128\128\128\128\128\128\128", fg = "441ceeeeeeeeee", bg = "11eec777777777" },
            [6] = { ch = "\130\143\149\128\149\140\147\131\135\131\131\131\131\129", fg = "111ccf77777777", bg = "ccee77ffffffff" },
            [7] = { ch = "\135\131\139\143\143\128\131\131\131\143\141\140\140\132", fg = "ccce7c7cc77777", bg = "7777ffffffffff" }
        }
    },
    [9] = {
        name = "POOTIS // EXTREME",
        file = "extreme.lua",
        tag = "ANIME HD",
        author = "ceno0 / Dub",
        dur = "12:04 min",
        desc = "Full-Length 12-Min Pootis Engage Extreme with 16-Color CIELAB + 48kHz Audio",
        preview = {
            [1] = { ch = "\128\159\135\148\128\128\128\128\128\158\148\128\128\159", fg = "cf7eccccceeccf", bg = "f78ffffff7fff7" },
            [2] = { ch = "\130\130\131\129\128\128\128\128\149\159\130\128\128\131", fg = "fcc7ccccf77cc8", bg = "efffffff7ffff7" },
            [3] = { ch = "\151\128\147\128\151\131\131\151\129\129\128\128\128\128", fg = "ecfcfffc77cccc", bg = "ff7f000fffffff" },
            [4] = { ch = "\138\143\128\128\149\128\128\131\149\148\133\128\128\159", fg = "ffcc8ee87f7ccf", bg = "eeff0000f7fff8" },
            [5] = { ch = "\143\143\133\128\130\143\143\143\133\128\128\128\128\138", fg = "eeec80008cccc8", bg = "77ff7fffffffff" },
            [6] = { ch = "\128\138\139\139\135\133\128\128\128\128\128\128\128\128", fg = "c77777eccccccc", bg = "ffffffffffffff" },
            [7] = { ch = "\128\128\128\128\128\128\128\128\128\128\128\128\128\128", fg = "cccccccccccccc", bg = "ffffffffffffff" }
        }
    },
    [10] = {
        name = "LIVE TV / TWITCH",
        file = "twitch.lua",
        tag = "ONLINE TV",
        author = "Twitch & PC Stream",
        dur = "Real-Time",
        desc = "Watch Live Twitch, YouTube & PC Desktop Screen directly in Minecraft!",
        preview = {
            [1] = { ch = "\128\128\148\128\128\128\128\128\128\128\144\128\128\128", fg = "ee777777777777", bg = "ffffffffffffff" },
            [2] = { ch = "\128\128\128\130\128\128\128\128\128\129\128\128\128\128", fg = "77777777777777", bg = "ffffffffffffff" },
            [3] = { ch = "\136\131\131\131\131\131\131\131\131\131\131\131\131\132", fg = "77777777777777", bg = "88888888888888" },
            [4] = { ch = "\149\159\128\128\128\128\128\128\128\128\128\128\128\149", fg = "7e777777777777", bg = "8f888888888888" },
            [5] = { ch = "\149\128\128\128\128\128\128\128\128\128\128\128\128\149", fg = "77777777777777", bg = "88888888888888" },
            [6] = { ch = "\133\143\143\143\143\143\143\143\143\143\143\143\143\134", fg = "77777777777777", bg = "88888888888888" },
            [7] = { ch = "\128\128\130\128\128\128\128\128\128\128\128\129\128\128", fg = "77777777777777", bg = "ffffffffffffff" }
        }
    }
}

local selectedVideoIdx = 1
local currentVideoPage = 1

-- 3x4 APPS DATABASE (31 APPS WITH IN-GAME HELP & METADATA)
-- ============================================================================
local PAGES = {
    [1] = {
        title = "GAMES & SIMS",
        apps = {
            [1] = {
                name = "SUPER MARIO", file = "mario.lua", tag = "GAME", desc = "8-Bit Jump Pro",
                help = "Controls: [A/D] Move, [W/Space] Jump. Collect coins & reach flag!",
                icon = { { ch = "[ M]", fg = "0e00", bg = "eeff" }, { ch = "(oo)", fg = "4444", bg = "bbbb" } }
            },
            [2] = {
                name = "DRAGON PET", file = "dragon.lua", tag = "SIM", desc = "Dragon Realm",
                help = "Feed, train, pet, and evolve your cyber dragon into elder rank!",
                icon = { { ch = "^/\\^", fg = "dddd", bg = "5555" }, { ch = ">o.o<", fg = "45454", bg = "ddddd" } }
            },
            [3] = {
                name = "CYBER TETRIS", file = "tetris.lua", tag = "PUZZLE", desc = "Classic Blocks",
                help = "Controls: [A/D] Move, [W] Rotate, [S] Drop, [Space] Hard drop.",
                icon = { { ch = " [#] ", fg = "aaaa", bg = "2222" }, { ch = "[###]", fg = "9999", bg = "4444" } }
            },
            [4] = {
                name = "CYBER SNAKE", file = "snake.lua", tag = "ARCADE", desc = "Neon Serpent",
                help = "Controls: [W/A/S/D] or Arrows. Eat glowing food, avoid walls/tail.",
                icon = { { ch = "~~:O", fg = "dddd", bg = "5555" }, { ch = "(*)~", fg = "eeee", bg = "dddd" } }
            },
            [5] = {
                name = "CYBER CASINO", file = "casino.lua", tag = "SLOTS", desc = "777 Jackpot",
                help = "Bet cyber credits on 777 Slots, Roulette, and High-Low dice.",
                icon = { { ch = "[777]", fg = "44444", bg = "fffff" }, { ch = "[$ $]", fg = "45544", bg = "44444" } }
            },
            [6] = {
                name = "COOKIE CLICK", file = "cookie.lua", tag = "IDLE", desc = "Bakery Empire",
                help = "Click giant cookie, buy grandmas, factories, and portals for CPS!",
                icon = { { ch = "(*.*)", fg = "44444", bg = "ccccc" }, { ch = "( * )", fg = "11111", bg = "ccccc" } }
            },
            [7] = {
                name = "CYBER TYCOON", file = "tycoon.lua", tag = "FACTORY", desc = "Mining Corp",
                help = "Build automated ore miners, smelters, and quantum generators.",
                icon = { { ch = ">---<", fg = "11111", bg = "77777" }, { ch = "|[_]|", fg = "44444", bg = "88888" } }
            },
            [8] = {
                name = "CYBER TV", file = "tv.lua", tag = "MEDIA", desc = "15 Live Feeds",
                help = "15 Animated retro TV channels: Matrix, News, Anime, Space, etc.",
                icon = { { ch = " \\ / ", fg = "99999", bg = "00000" }, { ch = "[=O=]", fg = "99999", bg = "bbbbb" } }
            },
            [9] = {
                name = "SOLAR SYSTEM", file = "solar.lua", tag = "3D MAP", desc = "Planet Orrery",
                help = "Interactive real-time 3D planetary model with zoom and orbits.",
                icon = { { ch = "\\(O)/", fg = "44444", bg = "11111" }, { ch = " * o ", fg = "99999", bg = "00000" } }
            },
            [10] = {
                name = "SPACE VOYAGE", file = "space.lua", tag = "GALAXY", desc = "Starship Flight",
                help = "Fly starship across solar system, dodge asteroids, dock at stations.",
                icon = { { ch = " /|\\ ", fg = "00000", bg = "bbbbb" }, { ch = "<!|!>", fg = "eeeee", bg = "99999" } }
            },
            [11] = {
                name = "ART GALLERY", file = "art.lua", tag = "HD ART", desc = "12 Canvas Art",
                help = "Gallery of high-definition pixel artwork and animated scenery.",
                icon = { { ch = "(RGB)", fg = "e5be5", bg = "88888" }, { ch = "( * )", fg = "aaaaa", bg = "00000" } }
            },
            [12] = {
                name = "WIRELESS HUB", file = "wireless.lua", tag = "CONTROL", desc = "Redstone Link",
                help = "Wireless remote control for redstone doors, lamps, and devices.",
                icon = { { ch = "((|))", fg = "ddddd", bg = "55555" }, { ch = " / \\ ", fg = "99999", bg = "bbbbb" } }
            }
        }
    },
    [2] = {
        title = "ARCADE & ACTION",
        apps = {
            [1] = {
                name = "PAINT STUDIO", file = "paint.lua", tag = "DRAW", desc = "Pixel Canvas",
                help = "Full-featured pixel art drawing app with 16 colors and export.",
                icon = { { ch = " //  ", fg = "44444", bg = "ccccc" }, { ch = "[===]", fg = "22222", bg = "00000" } }
            },
            [2] = {
                name = "CHESS 3D", file = "chess.lua", tag = "CHESS", desc = "VS AI & 2-Player",
                help = "Full Chess engine with legal move validation, AI and local 2P.",
                icon = { { ch = " +++ ", fg = "44444", bg = "bbbbb" }, { ch = "(###)", fg = "00000", bg = "77777" } }
            },
            [3] = {
                name = "CHESS 4P", file = "chess4.lua", tag = "4-WAY", desc = "4 Armies War",
                help = "4-Player simultaneous chess battle on 14x14 expanded board.",
                icon = { { ch = "> X <", fg = "eeeee", bg = "bbbbb" }, { ch = "[4-P]", fg = "44444", bg = "55555" } }
            },
            [4] = {
                name = "BATTLESHIP", file = "naval.lua", tag = "WAR", desc = "10x10 Sea War",
                help = "Classic naval warfare 10x10 grid with radar, sonar, and smart AI.",
                icon = { { ch = " _|_ ", fg = "88888", bg = "00000" }, { ch = "<===>", fg = "00000", bg = "bbbbb" } }
            },
            [5] = {
                name = "BYBIT CRYPTO", file = "bybit.lua", tag = "FUTURES", desc = "100x Leverage",
                help = "Real-time BTC/ETH/SOL candlestick trading simulator with leverage!",
                icon = { { ch = "[BTC]", fg = "44444", bg = "11111" }, { ch = "/\\/\\", fg = "deede", bg = "00000" } }
            },
            [6] = {
                name = "PAC-MAN", file = "pacman.lua", tag = "RETRO", desc = "Ghost Maze",
                help = "Eat all dots and energizers, avoid Blinky, Pinky, Inky & Clyde!",
                icon = { { ch = " C . ", fg = "44444", bg = "00000" }, { ch = " C . ", fg = "44444", bg = "00000" } }
            },
            [7] = {
                name = "NEON RACER", file = "race.lua", tag = "RACING", desc = "320km/h Nitro",
                help = "Controls: [A/D] Steer, [W] Accelerate, [Space] Nitro Boost.",
                icon = { { ch = "_==_", fg = "4444", bg = "eeee" }, { ch = "O--O", fg = "9999", bg = "0000" } }
            },
            [8] = {
                name = "FLAPPY BIRD", file = "flappy.lua", tag = "ARCADE", desc = "Flapping Pro",
                help = "Controls: [Space/Tap] Flap wings to fly between green pipes.",
                icon = { { ch = "(o_>", fg = "1111", bg = "4444" }, { ch = "(__)", fg = "0000", bg = "4444" } }
            },
            [9] = {
                name = "CYBER PONG", file = "pong.lua", tag = "RETRO", desc = "Paddle VS AI",
                help = "Controls: [W/S] Move left paddle, bounce ball past AI opponent.",
                icon = { { ch = "| * ", fg = "0000", bg = "9999" }, { ch = "  | ", fg = "0000", bg = "2222" } }
            },
            [10] = {
                name = "DOODLE JUMP", file = "doodle.lua", tag = "ARCADE", desc = "Sky Climber",
                help = "Controls: [A/D] Steer doodler, jump on platforms to climb sky.",
                icon = { { ch = "^o_o^", fg = "ddddd", bg = "55555" }, { ch = " |==|", fg = "55555", bg = "ccccc" } }
            },
            [11] = {
                name = "SUBWAY RUN", file = "runner.lua", tag = "ARCADE", desc = "3-Lane Parkour",
                help = "Controls: [A/D] Switch lanes, [W] Jump, [S] Slide under trains.",
                icon = { { ch = "| | |", fg = "44444", bg = "bbbbb" }, { ch = ">_=_<", fg = "11111", bg = "99999" } }
            },
            [12] = {
                name = "TOWER DEFENSE", file = "tower.lua", tag = "TACTIC", desc = "Turret Warfare",
                help = "Place Gatling, Laser & Tesla towers to destroy waves of enemies.",
                icon = { { ch = "|| ||", fg = "eeeee", bg = "88888" }, { ch = "[===]", fg = "99999", bg = "77777" } }
            }
        }
    },
    [3] = {
        title = "PUZZLE, TACTICS & RNG",
        apps = {
            [1] = {
                name = "AMONG US 2077", file = "amongus.lua", tag = "SUS", desc = "The Skeld Impostor",
                help = "Complete spaceship tasks or hunt crewmates without getting caught.",
                icon = { { ch = ".[=].", fg = "99999", bg = "eeeee" }, { ch = " | | ", fg = "00000", bg = "eeeee" } }
            },
            [2] = {
                name = "CYBER 2048", file = "2048.lua", tag = "PUZZLE", desc = "Tile Merge Pro",
                help = "Controls: [W/A/S/D] Merge identical number tiles to reach 2048!",
                icon = { { ch = "[20]", fg = "4444", bg = "1111" }, { ch = "[48]", fg = "0000", bg = "4444" } }
            },
            [3] = {
                name = "CYBER SUDOKU", file = "sudoku.lua", tag = "LOGIC", desc = "9x9 Matrix Solver",
                help = "Fill 9x9 board with numbers 1-9 so rows, columns and 3x3s match.",
                icon = { { ch = "1|2|3", fg = "99999", bg = "77777" }, { ch = "4|5|6", fg = "ddddd", bg = "77777" } }
            },
            [4] = {
                name = "MINESWEEPER", file = "mines.lua", tag = "RETRO", desc = "Demining Ops",
                help = "Click to reveal numbers indicating nearby mines. Flag mines with [F]!",
                icon = { { ch = " >|> ", fg = "eeeee", bg = "44444" }, { ch = " (*)", fg = "eeeee", bg = "77777" } }
            },
            [5] = {
                name = "CONNECT 4", file = "connect4.lua", tag = "VS AI", desc = "4-In-A-Row Arena",
                help = "Drop colored discs into 7 columns to connect 4 in a line before AI.",
                icon = { { ch = "(R)(Y)", fg = "e4e4e4", bg = "bbbbbb" }, { ch = "(Y)(R)", fg = "4e4e4e", bg = "bbbbbb" } }
            },
            [6] = {
                name = "SOLS RNG", file = "rng.lua", tag = "GACHA", desc = "1/10M Mythic Auras",
                help = "Roll rare cosmic auras up to 1/10,000,000 Chronos Lord!",
                icon = { { ch = "<* *>", fg = "22222", bg = "aaaaa" }, { ch = " {O} ", fg = "44444", bg = "99999" } }
            },
            [7] = {
                name = "BAD APPLE!!", file = "bad_apple.lua", tag = "ANIME", desc = "Shadow Art 60FPS",
                help = "Full Touhou Project Bad Apple shadow art silhouette video with synced chiptune music.",
                icon = { { ch = "(Apple)", fg = "eeee", bg = "0000" }, { ch = " === ", fg = "0000", bg = "eeee" } }
            },
            [8] = {
                name = "SYSTEM ABOUT", file = "settings", tag = "INFO", desc = "OS Diagnostics",
                help = "View system specs, theme preferences, and hardware diagnostics.",
                icon = { { ch = " *|* ", fg = "33333", bg = "bbbbb" }, { ch = "[=O=]", fg = "99999", bg = "77777" } }
            }
        }
    }
}

local currentPage = 1
local totalPages = #PAGES
local selectedTileIdx = 1
local currentView = "HOME" -- "HOME", "GAMES", "SETTINGS", "EASTER_EGG"

-- ============================================================================
-- UNIFIED FULL-SCREEN SEAMLESS LAUNCH TERMINAL (SINGLE WINDOW, NO RESIZING SNAPS)
-- ============================================================================
local function launchAppWithAnimation(app)
    local screenW, screenH = display.getSize()
    local midX = math.floor(screenW / 2)
    local midY = math.floor(screenH / 2)
    
    if not config.instantLaunch then
        -- 1. Full-Screen Quantum Terminal Setup
        display.setBackgroundColor(colors.black)
        display.clear()
        
        -- Top Cyber Header
        display.setCursorPos(1, 2)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        local launchHdr = " >> QUANTUM RUNTIME EXECUTION MATRIX << "
        display.setCursorPos(math.max(1, math.floor((screenW - #launchHdr) / 2)), 2)
        display.write(launchHdr)
        
        -- Centered App Icon
        if app.icon and #app.icon >= 2 and display.blit then
            display.setCursorPos(midX - 2, midY - 6)
            display.blit(string.sub(app.icon[1].ch, 1, 4), string.sub(app.icon[1].fg, 1, 4), string.sub(app.icon[1].bg, 1, 4))
            display.setCursorPos(midX - 2, midY - 5)
            display.blit(string.sub(app.icon[2].ch, 1, 4), string.sub(app.icon[2].fg, 1, 4), string.sub(app.icon[2].bg, 1, 4))
        end
        
        -- Centered App Title & Meta
        display.setBackgroundColor(colors.black)
        display.setCursorPos(1, midY - 3)
        display.setTextColor(colors.yellow)
        local tStr = string.format(">> LAUNCHING: %s <<", app.name)
        display.setCursorPos(math.max(1, math.floor((screenW - #tStr) / 2)), midY - 3)
        display.write(tStr)
        
        display.setCursorPos(1, midY - 1)
        display.setTextColor(colors.lightBlue)
        local subStr = string.format("CATEGORY: %-8s | FILE: %-14s", app.tag, app.file)
        display.setCursorPos(math.max(1, math.floor((screenW - #subStr) / 2)), midY - 1)
        display.write(subStr)
        
        -- Full-Width Smooth Progress Bar
        local barW = math.min(42, screenW - 10)
        local barX = math.floor((screenW - barW) / 2)
        
        display.setCursorPos(barX, midY + 2)
        display.setTextColor(colors.cyan)
        display.write("+" .. string.rep("=", barW - 2) .. "+")
        display.setCursorPos(barX, midY + 4)
        display.write("+" .. string.rep("=", barW - 2) .. "+")
        
        -- Progress Filling
        for p = 1, barW - 2 do
            display.setCursorPos(barX + p, midY + 3)
            display.setBackgroundColor(colors.blue)
            display.setTextColor(colors.lime)
            display.write("=")
            sleep(0.015)
        end
        
        display.setCursorPos(1, midY + 6)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.lime)
        local rdyStr = ">> QUANTUM THREADS ALLOCATED (READY) <<"
        display.setCursorPos(math.max(1, math.floor((screenW - #rdyStr) / 2)), midY + 6)
        display.write(rdyStr)
        
        sleep(0.08)
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
    display.setCursorPos(1, 1)
    
    if fs.exists(app.file) or fs.exists(app.file .. ".lua") or app.file == "settings" then
        shell.run(app.file)
    else
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.setCursorPos(math.max(1, midX - 14), midY)
        display.write(string.format(" File not found: %s ", app.file))
        sleep(1.5)
    end
    
    -- FORCIBLY KILL ANY RESIDUAL / BUGGED AUDIO ON GAME/VIDEO EXIT
    stopAllAudio()
    
    -- RESTORE HUB PALETTE & TEXT SCALE ON GAME EXIT
    applyPalette()
    if isMonitor and mon then
        pcall(function() mon.setTextScale(config.textScale or 0.5) end)
    end
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    display.clear()
end

-- ============================================================================
-- HOLOGRAPHIC SWIPE ANIMATION
-- ============================================================================
local function animatePageSwipe(dir)
    local screenW, screenH = display.getSize()
    local steps = 6
    local delay = 0.02
    
    for s = 1, steps do
        local x = (dir == "RIGHT") and math.floor(screenW * (s / steps)) or math.floor(screenW * (1 - (s / steps)))
        if x >= 1 and x <= screenW then
            for y = 3, screenH - 3 do
                display.setCursorPos(math.max(1, x - 1), y)
                display.setBackgroundColor(colors.blue)
                display.setTextColor(colors.cyan)
                display.write("//")
            end
        end
        sleep(delay)
    end
end

-- ============================================================================
-- REAL-TIME SEARCH MODAL
-- ============================================================================
local function runSearchModal()
    local screenW, screenH = display.getSize()
    local allApps = {}
    for p = 1, #PAGES do
        for _, app in ipairs(PAGES[p].apps) do
            table.insert(allApps, { app = app, page = p })
        end
    end
    
    local query = ""
    
    while true do
        display.setBackgroundColor(colors.black)
        display.clear()
        
        display.setCursorPos(1, 1)
        display.setBackgroundColor(colors.blue)
        display.setTextColor(colors.yellow)
        display.write(string.rep(" ", screenW))
        local sHdr = " >> REAL-TIME CYBER APP SEARCH ENGINE << "
        display.setCursorPos(math.max(1, math.floor((screenW - #sHdr)/2)), 1)
        display.write(sHdr)
        
        display.setCursorPos(4, 3)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.yellow)
        display.write(" SEARCH: [ ")
        display.setTextColor(colors.white)
        display.write(query .. "_")
        display.setTextColor(colors.yellow)
        display.write(" ] (Type letters, [ENTER] Open, [ESC] Back)")
        
        local matches = {}
        for _, item in ipairs(allApps) do
            if query == "" or string.find(string.lower(item.app.name), string.lower(query), 1, true) or string.find(string.lower(item.app.tag), string.lower(query), 1, true) then
                table.insert(matches, item)
            end
        end
        
        display.setCursorPos(4, 5)
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.cyan)
        display.write(string.format("RESULTS FOUND (%d):", #matches))
        
        local startY = 7
        for idx = 1, math.min(10, #matches) do
            local it = matches[idx]
            display.setCursorPos(4, startY + (idx - 1) * 2)
            display.setBackgroundColor(colors.gray)
            display.setTextColor(colors.yellow)
            display.write(string.format(" [%d] %-18s ", idx, it.app.name))
            display.setTextColor(colors.lime)
            display.write(string.format(" TAG: %-8s ", it.app.tag))
            display.setTextColor(colors.lightBlue)
            display.write(string.format(" %-20s ", it.app.desc))
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.escape then
                break
            elseif p1 == keys.enter then
                if #matches > 0 then
                    currentPage = matches[1].page
                    launchAppWithAnimation(matches[1].app)
                    break
                end
            elseif p1 == keys.backspace then
                if #query > 0 then
                    query = string.sub(query, 1, #query - 1)
                end
            end
        elseif event == "char" then
            if #query < 18 then
                query = query .. p1
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local my = p3
            local clickedIdx = math.floor((my - startY) / 2) + 1
            if clickedIdx >= 1 and clickedIdx <= #matches then
                currentPage = matches[clickedIdx].page
                launchAppWithAnimation(matches[clickedIdx].app)
                break
            elseif my == 1 or my >= screenH - 2 then
                break
            end
        end
    end
    
    applyPalette()
end

-- ============================================================================
-- INSTANT RANDOM GAME ROULETTE
-- ============================================================================
local function runRandomRoulette()
    local allApps = {}
    for p = 1, #PAGES do
        for _, app in ipairs(PAGES[p].apps) do
            table.insert(allApps, { app = app, page = p })
        end
    end
    if #allApps == 0 then return end
    
    local screenW, screenH = display.getSize()
    local midY = math.floor(screenH / 2)
    local spins = 12
    local picked = 1
    
    for i = 1, spins do
        picked = math.random(1, #allApps)
        local cur = allApps[picked]
        
        local bw = 36
        local bx = math.floor((screenW - bw) / 2)
        local by = midY - 2
        
        for dy = 0, 4 do
            display.setCursorPos(bx, by + dy)
            display.setBackgroundColor(colors.blue)
            display.write(string.rep(" ", bw))
        end
        
        display.setCursorPos(bx + 2, by + 1)
        display.setTextColor(colors.cyan)
        display.write(">> * ROULETTE CHOOSING GAME * <<")
        
        display.setCursorPos(bx + 4, by + 3)
        display.setTextColor(colors.yellow)
        display.write(string.format(">>> %-20s <<<", cur.app.name))
        
        sleep(0.03 + (i / spins) * 0.05)
    end
    
    sleep(0.3)
    local chosen = allApps[picked]
    currentPage = chosen.page
    launchAppWithAnimation(chosen.app)
end

-- ============================================================================
-- INTERACTIVE MATRIX SCREENSAVER
-- ============================================================================
local function runMatrixScreenSaver()
    local screenW, screenH = display.getSize()
    display.setBackgroundColor(colors.black)
    display.clear()
    
    local drops = {}
    for c = 1, screenW do
        drops[c] = math.random(1, screenH)
    end
    
    local chars = "0123456789ABCDEF$#@*+=-~<>[]{}!?"
    local mTimer = os.startTimer(0.04)
    
    while true do
        local event, p1 = os.pullEvent()
        if event == "key" or event == "mouse_click" or event == "monitor_touch" then
            break
        elseif event == "timer" and p1 == mTimer then
            for c = 1, screenW, 2 do
                local y = drops[c]
                if y >= 1 and y <= screenH then
                    display.setCursorPos(c, y)
                    display.setBackgroundColor(colors.black)
                    display.setTextColor(colors.white)
                    display.write(string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
                    
                    if y > 1 then
                        display.setCursorPos(c, y - 1)
                        display.setTextColor(colors.lime)
                        display.write(string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
                    end
                    if y > 3 then
                        display.setCursorPos(c, y - 3)
                        display.setTextColor(colors.green)
                        display.write(string.sub(chars, math.random(1, #chars), math.random(1, #chars)))
                    end
                    if y > 6 then
                        display.setCursorPos(c, y - 6)
                        display.write(" ")
                    end
                end
                
                drops[c] = drops[c] + 1
                if drops[c] > screenH + 6 then
                    drops[c] = math.random(-4, 0)
                end
            end
            mTimer = os.startTimer(0.04)
        end
    end
    
    applyPalette()
end

-- ============================================================================
-- IN-GAME HELP & RULES INSPECTOR MODAL
-- ============================================================================
local function showGameHelpModal(app)
    local screenW, screenH = display.getSize()
    local bw = math.min(50, screenW - 6)
    local bh = 10
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
    display.write(string.format("GAME INFO: %-24s", app.name))
    
    display.setCursorPos(bx + 2, by + 3)
    display.setTextColor(colors.white)
    display.write(string.format("TAG: %-10s | FILE: %-14s", app.tag, app.file))
    
    display.setCursorPos(bx + 2, by + 5)
    display.setTextColor(colors.lime)
    display.write("RULES / CONTROLS:")
    
    display.setCursorPos(bx + 2, by + 6)
    display.setTextColor(colors.white)
    display.write(string.sub(app.help or app.desc, 1, bw - 4))
    
    display.setCursorPos(bx + 2, by + 8)
    display.setTextColor(colors.lightBlue)
    display.write("Press [SPACE/ENTER] Launch | [ESC/B] Back")
    
    while true do
        local event, p1 = os.pullEvent()
        if event == "key" then
            if p1 == keys.space or p1 == keys.enter then
                launchAppWithAnimation(app)
                break
            elseif p1 == keys.b or p1 == keys.escape or p1 == keys.q then
                break
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            break
        end
    end
    
    applyPalette()
end

-- ============================================================================
-- SECRET CREATOR EASTER EGG SCREEN
-- ============================================================================
local function renderEasterEgg()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    applyEasterEggPalette()
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    local hdr = " >> SECRET EASTER EGG: SYSTEM CREATOR & MASTER ARCHITECT << "
    display.setCursorPos(math.max(1, math.floor((screenW - #hdr) / 2)), 1)
    display.write(hdr)
    
    registerButton("BTN_BACK", 2, screenH - 2, 16, 2, " [< BACK TO HUB] ", "yellow", "blue")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    local artStartX = 2
    local artStartY = 3
    
    for rowIdx, blitLine in ipairs(AHAREN_ART) do
        local cy = artStartY + rowIdx - 1
        if cy <= screenH - 3 then
            display.setCursorPos(artStartX, cy)
            display.blit(blitLine.ch, blitLine.fg, blitLine.bg)
        end
    end
    
    local infoStartX = artStartX + 38
    local cardBoxW = math.max(28, screenW - infoStartX - 2)
    
    display.setCursorPos(infoStartX, 3)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write("+" .. string.rep("=", cardBoxW - 2) .. "+")
    
    display.setCursorPos(infoStartX, 4)
    display.write("|  *** SUPREME SYSTEM CREATOR ***  |")
    
    display.setCursorPos(infoStartX, 5)
    display.write("+" .. string.rep("=", cardBoxW - 2) .. "+")
    
    display.setCursorPos(infoStartX, 7)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write(">> LEAD ARCHITECT: ")
    display.setTextColor(colors.yellow)
    display.write("Aharen7san")
    
    display.setCursorPos(infoStartX, 9)
    display.setTextColor(colors.cyan)
    display.write(">> SYSTEM OS:      ")
    display.setTextColor(colors.white)
    display.write("Cyber OS 2077 v4.0 PRO")
    
    display.setCursorPos(infoStartX, 11)
    display.setTextColor(colors.cyan)
    display.write(">> TOTAL GAMES:    ")
    display.setTextColor(colors.lime)
    display.write("31 Built Masterpieces")
    
    display.setCursorPos(infoStartX, 13)
    display.setTextColor(colors.cyan)
    display.write(">> SIGNATURE:      ")
    display.setTextColor(colors.magenta)
    display.write('"myaa... enjoy the games!"')
    
    display.setCursorPos(infoStartX, 15)
    display.setTextColor(colors.cyan)
    display.write(">> SPECIAL THANKS: ")
    display.setTextColor(colors.orange)
    display.write("All Cyber OS Players")
    
    display.setCursorPos(infoStartX, 17)
    display.setTextColor(colors.lightGray)
    display.write(string.rep("-", cardBoxW))
    
    drawButtons()
end

-- ============================================================================
-- SETTINGS & THEMES MENU SCREEN
-- ============================================================================
local function renderSettings()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    display.setBackgroundColor(colors.black)
    display.clear()
    
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    local hdr = " >> CYBER OS SYSTEM CONFIGURATION & PREFERENCES << "
    display.setCursorPos(math.max(1, math.floor((screenW - #hdr) / 2)), 1)
    display.write(hdr)
    
    registerButton("BTN_BACK", 2, screenH - 2, 14, 2, " [< BACK (B)] ", "yellow", "blue")
    registerButton("BTN_QUIT", screenW - 4, 1, 4, 1, "[Q]", "white", "red")
    
    local startY = 4
    
    display.setCursorPos(4, startY)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.yellow)
    display.write("1. ACTIVE SYSTEM THEME:")
    
    local themesList = { "NEON", "EMERALD", "SOLAR", "ICE", "SYNTH", "OLED" }
    for idx, thKey in ipairs(themesList) do
        local isCur = (config.theme == thKey)
        local btnLabel = string.format(" [%s] ", THEMES[thKey].name)
        local btnCol = (idx <= 3) and (4 + (idx - 1) * 17) or (4 + (idx - 4) * 17)
        local btnRow = (idx <= 3) and (startY + 2) or (startY + 4)
        registerButton("THEME_" .. thKey, btnCol, btnRow, 15, 2, btnLabel, isCur and "yellow" or "lightGray", isCur and "green" or "gray")
    end
    
    display.setCursorPos(4, startY + 8)
    display.setTextColor(colors.yellow)
    display.write("2. SYSTEM PREFERENCES:")
    
    local clockLbl = config.clock24h and " [ CLOCK: 24H ] " or " [ CLOCK: 12H ] "
    registerButton("TOGGLE_CLOCK", 4, startY + 10, 16, 2, clockLbl, "white", "blue")
    
    local launchLbl = config.instantLaunch and " [ LAUNCH: INSTANT ] " or " [ LAUNCH: NORMAL ] "
    registerButton("TOGGLE_LAUNCH", 22, startY + 10, 18, 2, launchLbl, "yellow", "gray")
    
    if isMonitor then
        local scaleLbl = string.format(" [ SCALE: %.1fx ] ", config.textScale)
        registerButton("TOGGLE_SCALE", 42, startY + 10, 16, 2, scaleLbl, "cyan", "purple")
    end
    
    display.setCursorPos(4, startY + 14)
    display.setTextColor(colors.yellow)
    display.write("3. SYSTEM DIAGNOSTICS & STORAGE GAUGE:")
    
    local diagBoxW = screenW - 8
    for dy = 0, 4 do
        display.setCursorPos(4, startY + 16 + dy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", diagBoxW))
    end
    
    local freeBytes = fs.getFreeSpace("/")
    local freeKb = math.floor(freeBytes / 1024)
    local totalKb = 1024
    local usedKb = math.max(0, totalKb - freeKb)
    local usedPct = math.min(100, math.floor((usedKb / totalKb) * 100))
    
    display.setCursorPos(6, startY + 16)
    display.setTextColor(colors.white)
    display.write(string.format("Host ID: #%d | OS: CyberOS 2077 v4.0 Ultimate", os.getComputerID()))
    registerButton("BTN_CREATOR", screenW - 24, startY + 16, 18, 1, "[* CREATOR INFO]", "yellow", "purple")
    
    display.setCursorPos(6, startY + 17)
    display.setTextColor(colors.lightBlue)
    display.write(string.format("Storage: %dKB / %dKB (%d%% used) [", usedKb, totalKb, usedPct))
    local barSegments = 16
    local filledSegments = math.floor((usedPct / 100) * barSegments)
    display.setTextColor(colors.lime)
    display.write(string.rep("=", filledSegments))
    display.setTextColor(colors.gray)
    display.write(string.rep("-", barSegments - filledSegments))
    display.setTextColor(colors.lightBlue)
    display.write("]")
    
    display.setCursorPos(6, startY + 18)
    display.setTextColor(colors.lime)
    display.write(string.format("Display: %dx%d (%s) | Installed Apps: 31 registered", 
        select(1, display.getSize()), select(2, display.getSize()), 
        isMonitor and "Monitor" or "Terminal"))
    
    drawButtons()
end

-- ============================================================================
-- DEDICATED STARTING "HOME" SCREEN DASHBOARD (WITH GORGEOUS HUD EFFECTS)
-- ============================================================================
local function renderHome()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local curTheme = THEMES[config.theme] or THEMES["NEON"]
    display.setBackgroundColor(curTheme.bg)
    display.clear()
    
    -- 1. Top Status Glass Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    local freeSpaceKb = math.floor(fs.getFreeSpace("/") / 1024)
    local timeStr = textutils.formatTime(os.time(), config.clock24h)
    
    local leftHeader = " >> CYBER OS 2077 PRO <<"
    local rightHeader = string.format(" %dKB | %s ", freeSpaceKb, timeStr)
    
    display.setCursorPos(2, 1)
    display.setTextColor(curTheme.barFg)
    display.write(leftHeader)
    registerButton("BTN_SECRET", 2, 1, #leftHeader, 1, "", "yellow", "blue")
    
    display.setCursorPos(#leftHeader + 3, 1)
    display.setTextColor(curTheme.accent)
    display.write(rightHeader)
    
    registerButton("BTN_MUTE", screenW - 44, 1, 9, 1, "[! MUTE]", "red", "gray")
    registerButton("BTN_SEARCH", screenW - 34, 1, 8, 1, "[? FIND]", "yellow", "gray")
    registerButton("BTN_ROULETTE", screenW - 25, 1, 7, 1, "[* RND]", "lime", "gray")
    registerButton("BTN_MATRIX", screenW - 17, 1, 6, 1, "[~ FX]", "green", "gray")
    registerButton("BTN_SETTINGS", screenW - 10, 1, 7, 1, "[# SET]", "cyan", "gray")
    registerButton("BTN_QUIT", screenW - 2, 1, 3, 1, "[X]", "white", "red")
    
    -- Line 2: Home Welcome Banner with Shaded Cyber Accent
    display.setCursorPos(1, 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(string.rep(" ", screenW))
    local homeBanner = " [ HOME DASHBOARD ] - WELCOME TO CYBER OS 2077 PRO | USER: Aharen7san "
    display.setCursorPos(2, 2)
    display.setTextColor(curTheme.barFg)
    display.write(homeBanner)
    
    -- 2. Two Big Hero Cards (3D Bevel, Neon Frames)
    local heroW = math.floor((screenW - 6) / 2)
    local heroH = 6
    
    -- Hero Card 1: All Games Library (Cyan/Blue)
    display.setCursorPos(2, 4)
    for dy = 0, heroH - 1 do
        display.setCursorPos(2, 4 + dy)
        display.setBackgroundColor(colors.blue)
        display.write(string.rep(" ", heroW))
    end
    display.setCursorPos(2, 4)
    display.setTextColor(colors.cyan)
    display.write("+" .. string.rep("=", heroW - 2) .. "+")
    display.setCursorPos(2, 4 + heroH - 1)
    display.write("+" .. string.rep("=", heroW - 2) .. "+")
    
    display.setCursorPos(4, 5)
    display.setTextColor(colors.yellow)
    display.write(">> [+ GAMES LIBRARY (31 APPS)] <<")
    display.setCursorPos(4, 6)
    display.setTextColor(colors.white)
    display.write("Browse 3x4 Grid Across 3 Sectors")
    display.setCursorPos(4, 7)
    display.setTextColor(colors.lightBlue)
    display.write("Mario, Tetris, Sols RNG, Snake, Sudoku...")
    display.setCursorPos(4, 8)
    display.setTextColor(colors.lime)
    display.write("[ CLICK TO OPEN LIBRARY > ]")
    registerButton("GOTO_GAMES", 2, 4, heroW, heroH, "", "white", "blue")
    
    -- Hero Card 2: Creator & System Preferences (Magenta/Purple)
    local hero2X = 3 + heroW
    display.setCursorPos(hero2X, 4)
    for dy = 0, heroH - 1 do
        display.setCursorPos(hero2X, 4 + dy)
        display.setBackgroundColor(colors.gray)
        display.write(string.rep(" ", heroW))
    end
    display.setCursorPos(hero2X, 4)
    display.setTextColor(colors.magenta)
    display.write("+" .. string.rep("=", heroW - 2) .. "+")
    display.setCursorPos(hero2X, 4 + heroH - 1)
    display.write("+" .. string.rep("=", heroW - 2) .. "+")
    
    display.setCursorPos(hero2X + 2, 5)
    display.setTextColor(colors.pink)
    display.write(">> [* CREATOR PROFILE (Aharen7san)] <<")
    display.setCursorPos(hero2X + 2, 6)
    display.setTextColor(colors.white)
    display.write("HD Pixel Portrait, Easter Eggs & Credits")
    display.setCursorPos(hero2X + 2, 7)
    display.setTextColor(colors.yellow)
    display.write("Theme Engine, Storage Gauge & Diagnostics")
    display.setCursorPos(hero2X + 2, 8)
    display.setTextColor(colors.cyan)
    display.write("[ VIEW CREATOR PROFILE > ]")
    registerButton("GOTO_CREATOR", hero2X, 4, heroW, heroH, "", "white", "gray")
    
    -- 3. Live System Telemetry HUD Bar (Line 11)
    display.setCursorPos(2, 11)
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.cyan)
    display.write(">> STATUS: ")
    display.setTextColor(colors.lime)
    display.write("ONLINE ")
    display.setTextColor(colors.lightGray)
    display.write("| CPU: ")
    display.setTextColor(colors.yellow)
    display.write("3.2GHz [=====-----] ")
    display.setTextColor(colors.lightGray)
    display.write("| APPS: ")
    display.setTextColor(colors.white)
    display.write("31 INSTALLED ")
    display.setTextColor(colors.lightGray)
    display.write("| DISK: ")
    display.setTextColor(colors.lightBlue)
    display.write(string.format("%dKB FREE", freeSpaceKb))
    
    -- 4. Spotlight Top Favorites Shelf (Lines 13 to 20)
    display.setCursorPos(2, 13)
    display.setBackgroundColor(curTheme.bg)
    display.setTextColor(colors.yellow)
    display.write(">> * SPOTLIGHT & POPULAR GAMES (1-CLICK LAUNCH) <<")
    
    local spotApps = {
        PAGES[1].apps[1], -- Super Mario
        PAGES[3].apps[6], -- Sols RNG
        PAGES[2].apps[7], -- Neon Racer
        PAGES[3].apps[4]  -- Minesweeper
    }
    
    local spotCols = 4
    local spotCardW = math.floor((screenW - 6 - (spotCols - 1) * 2) / spotCols)
    local spotCardH = 7
    local spotStartY = 15
    
    for idx, app in ipairs(spotApps) do
        if app then
            local scx = 2 + (idx - 1) * (spotCardW + 2)
            local scy = spotStartY
            
            for dy = 0, spotCardH - 1 do
                display.setCursorPos(scx, scy + dy)
                display.setBackgroundColor(curTheme.cardBg)
                display.write(string.rep(" ", spotCardW))
            end
            
            display.setCursorPos(scx, scy)
            display.setTextColor(colors.lightGray)
            display.write("+" .. string.rep("-", spotCardW - 2) .. "+")
            
            -- Draw Icon
            if app.icon and #app.icon >= 2 and display.blit then
                display.setCursorPos(scx + 2, scy + 1)
                display.blit(string.sub(app.icon[1].ch, 1, 4), string.sub(app.icon[1].fg, 1, 4), string.sub(app.icon[1].bg, 1, 4))
                display.setCursorPos(scx + 2, scy + 2)
                display.blit(string.sub(app.icon[2].ch, 1, 4), string.sub(app.icon[2].fg, 1, 4), string.sub(app.icon[2].bg, 1, 4))
            end
            
            display.setCursorPos(scx + 7, scy + 1)
            display.setTextColor(colors.yellow)
            display.write(string.sub(app.name, 1, spotCardW - 8))
            
            display.setCursorPos(scx + 7, scy + 2)
            display.setTextColor(colors.lightBlue)
            display.write(string.sub(app.tag, 1, spotCardW - 8))
            
            display.setCursorPos(scx + 2, scy + 4)
            display.setTextColor(colors.white)
            display.write(string.sub(app.desc, 1, spotCardW - 4))
            
            -- Quick Play Button
            registerButton("SPOT_PLAY_" .. idx, scx + spotCardW - 11, scy + spotCardH - 2, 9, 1, " [PLAY] ", "yellow", "green")
            
            display.setCursorPos(scx, scy + spotCardH - 1)
            display.setTextColor(colors.lightGray)
            display.write("+" .. string.rep("-", spotCardW - 2) .. "+")
            
            registerButton("SPOT_PLAY_" .. idx, scx, scy, spotCardW, spotCardH, "", "white", "gray")
        end
    end
    
    -- Bottom Navigation Dock
    local navY = screenH - 2
    display.setCursorPos(1, navY)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    -- Home + Page Tabs
    registerButton("NAV_HOME", 2, navY, 10, 2, " [ HOME ] ", "yellow", "green")
    registerButton("NAV_PAGE1", 14, navY, 12, 2, " [ PAGE 1 ] ", "lightGray", "gray")
    registerButton("NAV_PAGE2", 28, navY, 12, 2, " [ PAGE 2 ] ", "lightGray", "gray")
    registerButton("NAV_PAGE3", 42, navY, 12, 2, " [ PAGE 3 ] ", "lightGray", "gray")
    registerButton("NAV_VIDEOS", 56, navY, 13, 2, " [ VIDEOS ] ", "yellow", "blue")
    
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.accent)
    display.write(" [TAB/ARROWS] Switch Screens | [ENTER] Select | [F] Find | [H] Creator | [Q] Exit ")
    
    drawButtons()
end

-- ============================================================================

-- ============================================================================
-- 2x2 CINEMA & VIDEO SHOWCASE PAGE RENDERER
-- ============================================================================
local function renderVideos()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local curTheme = THEMES[config.theme] or THEMES["NEON"]
    display.setBackgroundColor(curTheme.bg)
    display.clear()
    
    -- 1. Top Glass Status Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    local freeSpaceKb = math.floor(fs.getFreeSpace("/") / 1024)
    local timeStr = textutils.formatTime(os.time(), config.clock24h)
    
    local leftHeader = " >> CYBER OS CINEMA & VIDEO THEATRE <<"
    local rightHeader = string.format(" %dKB | %s ", freeSpaceKb, timeStr)
    
    display.setCursorPos(2, 1)
    display.setTextColor(curTheme.barFg)
    display.write(leftHeader)
    
    display.setCursorPos(#leftHeader + 3, 1)
    display.setTextColor(curTheme.accent)
    display.write(rightHeader)
    
    registerButton("BTN_MUTE", screenW - 44, 1, 9, 1, "[! MUTE]", "red", "gray")
    registerButton("BTN_SEARCH", screenW - 34, 1, 8, 1, "[? FIND]", "yellow", "gray")
    registerButton("GOTO_GAMES", screenW - 25, 1, 8, 1, "[+ GAMES]", "lime", "gray")
    registerButton("BTN_SETTINGS", screenW - 16, 1, 7, 1, "[# SET]", "cyan", "gray")
    registerButton("BTN_QUIT", screenW - 8, 1, 6, 1, "[Q ESC]", "white", "red")
    
    local totalVideoPages = math.max(1, math.ceil(#VIDEOS_LIST / 4))
    if currentVideoPage > totalVideoPages then currentVideoPage = totalVideoPages end
    if currentVideoPage < 1 then currentVideoPage = 1 end
    
    -- Line 2: Section Title Banner with Page Counter
    display.setCursorPos(1, 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.yellow)
    display.write(string.rep(" ", screenW))
    local videoBanner = string.format(" [ VIDEO THEATRE - PAGE %d/%d (2x2 GRID) ] - HD SUBPIXEL TELETEXT STREAMS ", currentVideoPage, totalVideoPages)
    display.setCursorPos(2, 2)
    display.setTextColor(curTheme.barFg)
    display.write(videoBanner)
    
    -- 2. 2x2 Large Video Cards Grid
    local topY = 4
    local bottomReserved = 4
    local availH = screenH - topY - bottomReserved
    local availW = screenW - 4
    
    local cols = 2
    local rows = 2
    local cardW = math.floor((availW - 2) / cols)
    local cardH = math.floor((availH - 1) / rows)
    local startX = 2
    
    for idx = 1, 4 do
        local r = math.floor((idx - 1) / cols) + 1
        local c = ((idx - 1) % cols) + 1
        local cx = startX + (c - 1) * (cardW + 2)
        local cy = topY + (r - 1) * (cardH + 1)
        
        local globalIdx = (currentVideoPage - 1) * 4 + idx
        local vid = VIDEOS_LIST[globalIdx]
        local isSelected = (idx == selectedVideoIdx)
        
        if vid then
            local bgCol = isSelected and curTheme.cardSel or curTheme.cardBg
            local borderCol = isSelected and curTheme.borderSel or colors.lightGray
            
            for dy = 0, cardH - 1 do
                display.setCursorPos(cx, cy + dy)
                display.setBackgroundColor(bgCol)
                display.write(string.rep(" ", cardW))
            end
            
            -- Beveled Highlight Border
            display.setCursorPos(cx, cy)
            display.setBackgroundColor(bgCol)
            display.setTextColor(borderCol)
            display.write("+" .. string.rep("=", cardW - 2) .. "+")
            
            -- Left Preview Art Box (14x7 Teletext Frame)
            local artStartX = cx + 2
            local artStartY = cy + 1
            local artW = 14
            local artH = 7
            
            if vid.preview and display.blit then
                for rowI = 1, math.min(artH, #vid.preview) do
                    local pRow = vid.preview[rowI]
                    if pRow then
                        display.setCursorPos(artStartX, artStartY + rowI - 1)
                        local chPart = string.sub(pRow.ch, 1, artW)
                        local fgPart = string.sub(pRow.fg, 1, #chPart)
                        local bgPart = string.sub(pRow.bg, 1, #chPart)
                        display.blit(chPart, fgPart, bgPart)
                    end
                end
            end
            
            -- Right Info Metadata
            local infoX = artStartX + artW + 2
            local maxInfoW = cardW - (infoX - cx) - 2
            
            -- Video Title
            display.setCursorPos(infoX, cy + 1)
            display.setBackgroundColor(bgCol)
            display.setTextColor(isSelected and colors.yellow or colors.white)
            display.write(string.format("[%d] %s", globalIdx, string.sub(vid.name, 1, maxInfoW)))
            
            -- Tag & Author
            display.setCursorPos(infoX, cy + 2)
            display.setTextColor(colors.pink)
            display.write(string.format("[%s] ", vid.tag))
            display.setTextColor(colors.lightBlue)
            display.write(string.sub(vid.author, 1, math.max(1, maxInfoW - #vid.tag - 4)))
            
            -- Duration & Audio Specs
            display.setCursorPos(infoX, cy + 3)
            display.setTextColor(colors.lime)
            display.write(string.format("Duration: %s | 48kHz", vid.dur))
            
            -- Description
            if cardH >= 7 then
                display.setCursorPos(infoX, cy + 5)
                display.setTextColor(colors.lightGray)
                display.write(string.sub(vid.desc, 1, maxInfoW))
            end
            
            -- [ > WATCH VIDEO ] Action Button
            local btnW = math.min(18, maxInfoW)
            local btnX = cx + cardW - btnW - 2
            local btnY = cy + cardH - 2
            local watchLbl = isSelected and " [> WATCH (ENTER)] " or " [ > WATCH VIDEO ] "
            registerButton("VIDEO_PLAY_" .. idx, btnX, btnY, btnW, 1, watchLbl, isSelected and "yellow" or "white", isSelected and "green" or "blue")
            
            display.setCursorPos(cx, cy + cardH - 1)
            display.setBackgroundColor(bgCol)
            display.setTextColor(borderCol)
            display.write("+" .. string.rep("=", cardW - 2) .. "+")
            
            registerButton("VIDEO_CARD_" .. idx, cx, cy, cardW, cardH, "", "white", "gray")
        else
            -- Empty Slot Placeholder
            for dy = 0, cardH - 1 do
                display.setCursorPos(cx, cy + dy)
                display.setBackgroundColor(colors.black)
                display.setTextColor(colors.gray)
                display.write(string.rep(" ", cardW))
            end
        end
    end
    
    -- 3. Bottom Glass Navigation Dock with Video Page Pills
    local navY = screenH - 2
    display.setCursorPos(1, navY)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    registerButton("NAV_HOME", 2, navY, 10, 2, " [ HOME ] ", "white", "gray")
    registerButton("NAV_GAMES", 14, navY, 12, 2, " [ GAMES ] ", "lightGray", "gray")
    
    local pillStartX = 28
    for p = 1, totalVideoPages do
        local pillLabel = string.format(" [ PAGE %d ] ", p)
        local isCur = (p == currentVideoPage)
        registerButton("VID_PILL_" .. p, pillStartX + (p - 1) * 14, navY, 12, 2, pillLabel, isCur and "yellow" or "lightGray", isCur and "green" or "gray")
    end
    
    local arrowStartX = pillStartX + totalVideoPages * 14 + 1
    registerButton("VID_PAGE_PREV", arrowStartX, navY, 5, 2, " [<] ", "cyan", "blue")
    registerButton("VID_PAGE_NEXT", arrowStartX + 6, navY, 5, 2, " [>] ", "cyan", "blue")
    
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.accent)
    display.write(" [ARROWS] Select | [ENTER] Play | [TAB/N/P] Flip Pages | [H] Home | [Q] Exit ")
    
    drawButtons()
end
-- 3x4 GAMES GRID RENDERER
-- ============================================================================
local function renderHub()
    local screenW, screenH = display.getSize()
    clearButtons()
    
    local curTheme = THEMES[config.theme] or THEMES["NEON"]
    display.setBackgroundColor(curTheme.bg)
    display.clear()
    
    -- 1. Top Status Glass Bar
    display.setCursorPos(1, 1)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    local freeSpaceKb = math.floor(fs.getFreeSpace("/") / 1024)
    local timeStr = textutils.formatTime(os.time(), config.clock24h)
    
    local leftHeader = " >> CYBER OS 2077 PRO <<"
    local rightHeader = string.format(" %dKB | %s ", freeSpaceKb, timeStr)
    
    display.setCursorPos(2, 1)
    display.setTextColor(curTheme.barFg)
    display.write(leftHeader)
    registerButton("BTN_SECRET", 2, 1, #leftHeader, 1, "", "yellow", "blue")
    
    display.setCursorPos(#leftHeader + 3, 1)
    display.setTextColor(curTheme.accent)
    display.write(rightHeader)
    
    registerButton("BTN_MUTE", screenW - 44, 1, 9, 1, "[! MUTE]", "red", "gray")
    registerButton("BTN_SEARCH", screenW - 34, 1, 8, 1, "[? FIND]", "yellow", "gray")
    registerButton("BTN_ROULETTE", screenW - 25, 1, 7, 1, "[* RND]", "lime", "gray")
    registerButton("BTN_MATRIX", screenW - 17, 1, 6, 1, "[~ FX]", "green", "gray")
    registerButton("BTN_SETTINGS", screenW - 10, 1, 7, 1, "[# SET]", "cyan", "gray")
    registerButton("BTN_QUIT", screenW - 2, 1, 3, 1, "[X]", "white", "red")
    
    -- Line 2: Simple Page Banner (PAGE 1, 2, 3)
    display.setCursorPos(1, 2)
    display.setBackgroundColor(colors.gray)
    display.setTextColor(colors.cyan)
    display.write(string.rep(" ", screenW))
    
    local pageInfo = PAGES[currentPage] or PAGES[1]
    local subHeader = string.format(" [ PAGE %d / %d ] - %s ", currentPage, totalPages, pageInfo.title)
    display.setCursorPos(2, 2)
    display.setTextColor(curTheme.barFg)
    display.write(subHeader)
    
    -- 2. 3x4 Dynamic App Grid (12 Cards Per Page: 4 Columns x 3 Rows)
    local topY = 4
    local bottomReserved = 4
    local availH = screenH - topY - bottomReserved
    local availW = screenW - 4
    
    local cols = 4
    local rows = 3
    
    local cardW = math.max(17, math.floor((availW - (cols - 1) * 2) / cols))
    local cardH = math.max(4, math.floor((availH - (rows - 1) * 1) / rows))
    
    local startX = math.max(2, math.floor((screenW - (cols * cardW + (cols - 1) * 2)) / 2))
    
    local currentApps = pageInfo.apps
    
    for idx = 1, 12 do
        local r = math.floor((idx - 1) / cols) + 1
        local c = ((idx - 1) % cols) + 1
        
        local cx = startX + (c - 1) * (cardW + 2)
        local cy = topY + (r - 1) * (cardH + 1)
        
        local app = currentApps[idx]
        local isSelected = (idx == selectedTileIdx)
        
        if app then
            local bgCol = isSelected and curTheme.cardSel or curTheme.cardBg
            local borderCol = isSelected and curTheme.borderSel or colors.lightGray
            
            for dy = 0, cardH - 1 do
                display.setCursorPos(cx, cy + dy)
                display.setBackgroundColor(bgCol)
                display.write(string.rep(" ", cardW))
            end
            
            -- Top Bevel Highlight
            display.setCursorPos(cx, cy)
            display.setBackgroundColor(bgCol)
            display.setTextColor(borderCol)
            display.write("+" .. string.rep("-", cardW - 2) .. "+")
            
            -- Draw Authentic 4x2 Graphical Icon
            local iconW = 4
            if app.icon and #app.icon >= 2 and cardW >= 18 and cardH >= 3 then
                local iconX = cx + 1
                local iconY = cy + 1
                for iRow = 1, 2 do
                    local ic = app.icon[iRow]
                    if ic and display.blit then
                        display.setCursorPos(iconX, iconY + iRow - 1)
                        local chStr = string.sub(ic.ch, 1, 4)
                        local fgStr = string.sub(ic.fg, 1, #chStr)
                        local bgStr = string.sub(ic.bg, 1, #chStr)
                        display.blit(chStr, fgStr, bgStr)
                    end
                end
            end
            
            -- Card Title & Favorite Star
            local isFav = config.favorites and config.favorites[app.name]
            local favMark = isFav and "*" or ""
            local titleOffsetX = (app.icon and cardW >= 18 and cardH >= 3) and (iconW + 2) or 1
            display.setCursorPos(cx + titleOffsetX, cy + 1)
            display.setBackgroundColor(bgCol)
            display.setTextColor(isSelected and colors.yellow or colors.white)
            local maxTitleLen = cardW - titleOffsetX - (isFav and 3 or 1)
            local titleText = string.format("[%d] %s%s", idx, string.sub(app.name, 1, maxTitleLen), favMark)
            display.write(titleText)
            
            -- Description on Line 2 of Card
            if cardH >= 3 then
                display.setCursorPos(cx + titleOffsetX, cy + 2)
                display.setBackgroundColor(bgCol)
                display.setTextColor(colors.lightBlue)
                local descText = string.sub(app.desc, 1, cardW - titleOffsetX - 1)
                display.write(descText)
            end
            
            -- Interactive [ > PLAY ] Button on Card
            if cardH >= 4 then
                local btnPlayW = math.min(12, cardW - 4)
                local btnPlayX = cx + cardW - btnPlayW - 1
                local btnPlayY = cy + cardH - 2
                local playLbl = isSelected and " [> PLAY] " or " [ PLAY ] "
                registerButton("APP_" .. idx, btnPlayX, btnPlayY, btnPlayW, 1, playLbl, isSelected and "yellow" or "white", isSelected and "green" or "blue")
            end
            
            -- Bottom Bevel
            display.setCursorPos(cx, cy + cardH - 1)
            display.setBackgroundColor(bgCol)
            display.setTextColor(borderCol)
            display.write("+" .. string.rep("-", cardW - 2) .. "+")
            
            registerButton("APP_" .. idx, cx, cy, cardW, cardH, "", "white", "gray")
        else
            for dy = 0, cardH - 1 do
                display.setCursorPos(cx, cy + dy)
                display.setBackgroundColor(colors.black)
                display.setTextColor(colors.gray)
                display.write(string.rep(".", cardW))
            end
        end
    end
    
    -- 3. Bottom Glass Navigation Dock with [ HOME ] and [ PAGE 1-3 ] Pills
    local navY = screenH - 2
    display.setCursorPos(1, navY)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.barFg)
    display.write(string.rep(" ", screenW))
    
    registerButton("NAV_HOME", 2, navY, 10, 2, " [ HOME ] ", "white", "gray")
    
    local pillStartX = 14
    for p = 1, totalPages do
        local pillLabel = string.format(" [ PAGE %d ] ", p)
        local isCur = (p == currentPage)
        registerButton("PILL_" .. p, pillStartX + (p - 1) * 14, navY, 12, 2, pillLabel, isCur and "yellow" or "lightGray", isCur and "green" or "gray")
    end
    registerButton("NAV_VIDEOS", pillStartX + totalPages * 14, navY, 13, 2, " [ VIDEOS ] ", "yellow", "blue")
    
    display.setCursorPos(2, screenH)
    display.setBackgroundColor(curTheme.barBg)
    display.setTextColor(curTheme.accent)
    display.write(" [ARROWS] Move | [ENTER] Play | [I] Info | [P] Fav | [F] Find | [R] Rnd | [ESC] Home ")
    
    drawButtons()
end

-- ============================================================================
-- ============================================================================
-- MAIN EVENT-DRIVEN INTERACTION LOOP (FLICKER-FREE)
-- ============================================================================
local function main()
    local screenW, screenH = display.getSize()
    local needsRedraw = true
    
    while true do
        if needsRedraw then
            if currentView == "HOME" then
                renderHome()
            elseif currentView == "VIDEOS" then
                renderVideos()
            elseif currentView == "SETTINGS" then
                renderSettings()
            elseif currentView == "EASTER_EGG" then
                renderEasterEgg()
            else
                renderHub()
            end
            needsRedraw = false
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            needsRedraw = true
            if p1 == keys.m then
                stopAllAudio()
                display.setBackgroundColor(colors.red)
                display.setTextColor(colors.white)
                local curW, _ = display.getSize()
                local mStr = " >> ALL AUDIO FORCIBLY TERMINATED << "
                display.setCursorPos(math.max(1, math.floor((curW - #mStr) / 2)), 1)
                display.write(mStr)
                sleep(0.6)
                needsRedraw = true
            elseif p1 == keys.q then
                if currentView == "SETTINGS" or currentView == "EASTER_EGG" or currentView == "GAMES" or currentView == "VIDEOS" then
                    currentView = "HOME"
                    applyPalette()
                else
                    break
                end
            elseif p1 == keys.escape then
                if currentView == "HOME" then
                    break
                else
                    currentView = "HOME"
                    applyPalette()
                end
            elseif currentView == "VIDEOS" then
                local totalVideoPages = math.max(1, math.ceil(#VIDEOS_LIST / 4))
                if p1 == keys.h or p1 == keys.b or p1 == keys.escape then
                    currentView = "HOME"
                    applyPalette()
                elseif p1 == keys.g then
                    animatePageSwipe("RIGHT")
                    currentView = "GAMES"
                elseif p1 == keys.s then
                    currentView = "SETTINGS"
                elseif p1 == keys.f or p1 == keys.slash then
                    runSearchModal()
                elseif p1 == keys.tab or p1 == keys.rightBracket or p1 == keys.n then
                    animatePageSwipe("RIGHT")
                    currentVideoPage = (currentVideoPage % totalVideoPages) + 1
                elseif p1 == keys.leftBracket or p1 == keys.p then
                    animatePageSwipe("LEFT")
                    currentVideoPage = (currentVideoPage == 1) and totalVideoPages or (currentVideoPage - 1)
                elseif p1 == keys.right or p1 == keys.d then
                    selectedVideoIdx = (selectedVideoIdx % 4) + 1
                elseif p1 == keys.left or p1 == keys.a then
                    selectedVideoIdx = (selectedVideoIdx == 1) and 4 or (selectedVideoIdx - 1)
                elseif p1 == keys.down or p1 == keys.s then
                    selectedVideoIdx = (selectedVideoIdx <= 2) and (selectedVideoIdx + 2) or (selectedVideoIdx - 2)
                elseif p1 == keys.up or p1 == keys.w then
                    selectedVideoIdx = (selectedVideoIdx > 2) and (selectedVideoIdx - 2) or (selectedVideoIdx + 2)
                elseif p1 == keys.space or p1 == keys.enter then
                    local globalIdx = (currentVideoPage - 1) * 4 + selectedVideoIdx
                    local vid = VIDEOS_LIST[globalIdx]
                    if vid then
                        launchAppWithAnimation(vid)
                    end
                end
            elseif currentView == "HOME" then
                if p1 == keys.v then
                    animatePageSwipe("RIGHT")
                    currentView = "VIDEOS"
                elseif p1 == keys.g or p1 == keys.space or p1 == keys.enter then
                    animatePageSwipe("RIGHT")
                    currentView = "GAMES"
                elseif p1 == keys.h or p1 == keys.a then
                    currentView = "EASTER_EGG"
                elseif p1 == keys.s or p1 == keys.o then
                    currentView = "SETTINGS"
                elseif p1 == keys.f or p1 == keys.slash then
                    runSearchModal()
                elseif p1 == keys.r then
                    runRandomRoulette()
                elseif p1 == keys.m then
                    runMatrixScreenSaver()
                elseif p1 == keys.one then
                    animatePageSwipe("RIGHT")
                    currentPage = 1; currentView = "GAMES"
                elseif p1 == keys.two then
                    animatePageSwipe("RIGHT")
                    currentPage = 2; currentView = "GAMES"
                elseif p1 == keys.three then
                    animatePageSwipe("RIGHT")
                    currentPage = 3; currentView = "GAMES"
                end
            elseif currentView == "SETTINGS" then
                if p1 == keys.b or p1 == keys.space or p1 == keys.enter then
                    currentView = "HOME"
                    applyPalette()
                end
            elseif currentView == "EASTER_EGG" then
                if p1 == keys.b or p1 == keys.space or p1 == keys.enter then
                    currentView = "HOME"
                    applyPalette()
                end
            elseif currentView == "GAMES" then
                if p1 == keys.v then
                    animatePageSwipe("RIGHT")
                    currentView = "VIDEOS"
                elseif p1 == keys.f or p1 == keys.slash then
                    runSearchModal()
                elseif p1 == keys.r then
                    runRandomRoulette()
                elseif p1 == keys.m then
                    runMatrixScreenSaver()
                elseif p1 == keys.i then
                    local app = PAGES[currentPage].apps[selectedTileIdx]
                    if app then showGameHelpModal(app) end
                elseif p1 == keys.p then
                    local app = PAGES[currentPage].apps[selectedTileIdx]
                    if app then
                        if not config.favorites then config.favorites = {} end
                        config.favorites[app.name] = not config.favorites[app.name]
                        saveConfig()
                    end
                elseif p1 == keys.h or p1 == keys.a then
                    currentView = "EASTER_EGG"
                elseif p1 == keys.s or p1 == keys.o then
                    currentView = "SETTINGS"
                elseif p1 == keys.right or p1 == keys.d then
                    selectedTileIdx = (selectedTileIdx % 12) + 1
                elseif p1 == keys.left or p1 == keys.a then
                    selectedTileIdx = (selectedTileIdx == 1) and 12 or (selectedTileIdx - 1)
                elseif p1 == keys.down or p1 == keys.s then
                    selectedTileIdx = (selectedTileIdx + 4 > 12) and ((selectedTileIdx + 4) % 12) or (selectedTileIdx + 4)
                elseif p1 == keys.up or p1 == keys.w then
                    selectedTileIdx = (selectedTileIdx - 4 < 1) and (selectedTileIdx + 8) or (selectedTileIdx - 4)
                elseif p1 == keys.tab or p1 == keys.rightBracket or p1 == keys.n then
                    animatePageSwipe("RIGHT")
                    currentPage = (currentPage % totalPages) + 1
                elseif p1 == keys.leftBracket or p1 == keys.p then
                    animatePageSwipe("LEFT")
                    currentPage = (currentPage == 1) and totalPages or (currentPage - 1)
                elseif p1 == keys.space or p1 == keys.enter then
                    local app = PAGES[currentPage].apps[selectedTileIdx]
                    if app then launchAppWithAnimation(app) end
                end
            end
            
        elseif event == "mouse_click" or event == "monitor_touch" then
            needsRedraw = true
            local mx, my = p2, p3
            local cid = checkButtonClicked(mx, my)
            
            if cid == "BTN_QUIT" then
                break
            elseif cid == "NAV_HOME" then
                animatePageSwipe("LEFT")
                currentView = "HOME"
                applyPalette()
            elseif cid == "NAV_GAMES" or cid == "GOTO_GAMES" then
                animatePageSwipe("RIGHT")
                currentView = "GAMES"
            elseif cid == "NAV_VIDEOS" or cid == "GOTO_VIDEOS" then
                animatePageSwipe("RIGHT")
                currentView = "VIDEOS"
            elseif cid == "NAV_SETTINGS" then
                currentView = "SETTINGS"
            elseif cid == "NAV_PAGE1" or cid == "PILL_1" then
                animatePageSwipe("RIGHT")
                currentPage = 1; currentView = "GAMES"
            elseif cid == "NAV_PAGE2" or cid == "PILL_2" then
                animatePageSwipe("RIGHT")
                currentPage = 2; currentView = "GAMES"
            elseif cid == "NAV_PAGE3" or cid == "PILL_3" then
                animatePageSwipe("RIGHT")
                currentPage = 3; currentView = "GAMES"
            elseif cid == "GOTO_CREATOR" or cid == "BTN_SECRET" or cid == "BTN_CREATOR" then
                currentView = "EASTER_EGG"
            elseif cid == "BTN_SETTINGS" then
                currentView = "SETTINGS"
            elseif cid == "BTN_MUTE" then
                stopAllAudio()
                display.setBackgroundColor(colors.red)
                display.setTextColor(colors.white)
                local curW, _ = display.getSize()
                local mStr = " >> ALL AUDIO FORCIBLY TERMINATED << "
                display.setCursorPos(math.max(1, math.floor((curW - #mStr) / 2)), 1)
                display.write(mStr)
                sleep(0.6)
                needsRedraw = true
            elseif cid == "BTN_SEARCH" then
                runSearchModal()
            elseif cid == "BTN_ROULETTE" then
                runRandomRoulette()
            elseif cid == "BTN_MATRIX" then
                runMatrixScreenSaver()
            elseif cid == "BTN_BACK" then
                animatePageSwipe("LEFT")
                currentView = "HOME"
                applyPalette()
            elseif currentView == "VIDEOS" then
                local totalVideoPages = math.max(1, math.ceil(#VIDEOS_LIST / 4))
                if cid == "VID_PAGE_PREV" then
                    animatePageSwipe("LEFT")
                    currentVideoPage = (currentVideoPage == 1) and totalVideoPages or (currentVideoPage - 1)
                elseif cid == "VID_PAGE_NEXT" then
                    animatePageSwipe("RIGHT")
                    currentVideoPage = (currentVideoPage % totalVideoPages) + 1
                elseif cid and string.sub(cid, 1, 9) == "VID_PILL_" then
                    local pNum = tonumber(string.sub(cid, 10))
                    if pNum and pNum ~= currentVideoPage then
                        if pNum > currentVideoPage then
                            animatePageSwipe("RIGHT")
                        else
                            animatePageSwipe("LEFT")
                        end
                        currentVideoPage = pNum
                    end
                elseif cid and (string.sub(cid, 1, 11) == "VIDEO_PLAY_" or string.sub(cid, 1, 11) == "VIDEO_CARD_") then
                    local num = tonumber(string.sub(cid, 12))
                    local globalIdx = (currentVideoPage - 1) * 4 + num
                    local vid = VIDEOS_LIST[globalIdx]
                    if vid then
                        selectedVideoIdx = num
                        launchAppWithAnimation(vid)
                    end
                end
            elseif currentView == "HOME" then
                if cid and string.sub(cid, 1, 10) == "SPOT_PLAY_" then
                    local spotIdx = tonumber(string.sub(cid, 11))
                    local spotList = { PAGES[1].apps[1], PAGES[3].apps[6], PAGES[2].apps[7], PAGES[3].apps[4] }
                    if spotList[spotIdx] then
                        launchAppWithAnimation(spotList[spotIdx])
                    end
                end
            elseif currentView == "SETTINGS" then
                if cid and string.sub(cid, 1, 6) == "THEME_" then
                    local th = string.sub(cid, 7)
                    config.theme = th
                    saveConfig()
                    applyPalette()
                elseif cid == "TOGGLE_CLOCK" then
                    config.clock24h = not config.clock24h
                    saveConfig()
                elseif cid == "TOGGLE_LAUNCH" then
                    config.instantLaunch = not config.instantLaunch
                    saveConfig()
                elseif cid == "TOGGLE_SCALE" and isMonitor then
                    config.textScale = (config.textScale == 0.5) and 1.0 or 0.5
                    pcall(function() mon.setTextScale(config.textScale) end)
                    saveConfig()
                end
            elseif currentView == "GAMES" then
                if cid == "PAGE_PREV" then
                    animatePageSwipe("LEFT")
                    currentPage = (currentPage == 1) and totalPages or (currentPage - 1)
                elseif cid == "PAGE_NEXT" then
                    animatePageSwipe("RIGHT")
                    currentPage = (currentPage % totalPages) + 1
                elseif cid and string.sub(cid, 1, 4) == "APP_" then
                    local num = tonumber(string.sub(cid, 5))
                    local app = PAGES[currentPage].apps[num]
                    if app then
                        selectedTileIdx = num
                        launchAppWithAnimation(app)
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
        display.write("Cyber OS Hub closed.")
    else
        print("Cyber OS Hub closed.")
    end
end


local ok, err = pcall(main)
if not ok then
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.red)
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Hub Error: " .. tostring(err))
    term.setCursorPos(1, 1)
    print("Hub Error: " .. tostring(err))
end
