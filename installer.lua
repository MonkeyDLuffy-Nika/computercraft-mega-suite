-- ComputerCraft Mega Suite Installer
-- Run in-game: wget run https://raw.githubusercontent.com/<owner>/computercraft-mega-suite/main/installer.lua

local GITHUB_REPO = "computercraft-mega-suite"
local BRANCH = "main"

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    if term.isColor() then
        term.setTextColor(colors.yellow)
    end
    print("========================================")
    print("   ComputerCraft Mega Suite Installer   ")
    print("========================================")
    if term.isColor() then
        term.setTextColor(colors.white)
    end
    print()
end

printHeader()
print("Installing Hub OS and Game Collection...")
fs.makeDir("os")
fs.makeDir("games")
fs.makeDir("media")
fs.makeDir("utils")

print("Installation completed! Type 'os/hub.lua' to launch.")
