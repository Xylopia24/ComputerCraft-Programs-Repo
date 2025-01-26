--[[
    Character Map Utility
    Shows all available characters (0-255) in a formatted grid
    Created by: Xylopia
]]

local config = {
    CHARS_PER_ROW = 16,
    ROWS_TOTAL = 16,    -- Show all 256 characters (16x16 grid)
    USE_HEX = false     -- Toggle between decimal and hex display
}

local function drawHeader()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    term.clear()
    term.setCursorPos(1, 1)
    print("Character Map - All Characters (0-255)")
    print(config.USE_HEX and "Showing Hex Codes" or "Showing Decimal Codes")
    print("Controls: Space=Toggle Hex/Dec | Q=Quit")
    print(string.rep("-", 80))
end

local function getCharacterCode(index, useHex)
    if useHex then
        return string.format("\\%02X", index)
    else
        return string.format("\\%03d", index)
    end
end

local function drawCharacterMap()
    drawHeader()

    -- Draw column headers
    term.setCursorPos(6, 5)
    for col = 0, config.CHARS_PER_ROW - 1 do
        term.setTextColor(colors.cyan)
        term.write(string.format("%2X", col))
        term.write(" ")
    end

    -- Draw characters
    for row = 0, config.ROWS_TOTAL - 1 do
        local y = row + 6
        -- Draw row header
        term.setCursorPos(1, y)
        term.setTextColor(colors.cyan)
        term.write(string.format("%2X:", row))

        -- Draw characters for this row
        term.setCursorPos(6, y)
        for col = 0, config.CHARS_PER_ROW - 1 do
            local charIndex = row * config.CHARS_PER_ROW + col
            term.setTextColor(colors.white)
            term.write(string.format(" %s ", string.char(charIndex)))
        end

        -- Show character codes on the right
        term.setCursorPos(55, y)
        term.setTextColor(colors.lightGray)
        local firstChar = row * config.CHARS_PER_ROW
        local lastChar = firstChar + config.CHARS_PER_ROW - 1
        term.write(string.format("%s-%s",
            getCharacterCode(firstChar, config.USE_HEX),
            getCharacterCode(lastChar, config.USE_HEX)))
    end
end

-- Main program
term.clear()

while true do
    drawCharacterMap()
    local event, key = os.pullEvent()

    if event == "key" then
        if key == keys.space then
            config.USE_HEX = not config.USE_HEX
        elseif key == keys.q then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            break
        end
    end
end
