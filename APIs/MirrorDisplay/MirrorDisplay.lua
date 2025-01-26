--[[
    Mirror Display Library
    Version: 2.0.0
    Created By: Xylopia
--]]

-- Border configuration
local BORDER_CHARS = {
    corner = "+",
    horizontal = "-",
    vertical = "|"
}

-- Core module
local MirrorDisplay = {
    VERSION = "2.0.0",
    DEBUG = false,
    active = false,
    monitor = nil,
    originalTerm = nil,
    window = nil
}

-- Create a framed window on the monitor
local function createFramedWindow(monitor, width, height, title)
    local monitorWidth, monitorHeight = monitor.getSize()

    local offsetX = math.floor((monitorWidth - width) / 2)
    local offsetY = math.floor((monitorHeight - height) / 2)

    local win = window.create(monitor, offsetX + 1, offsetY + 1, width, height, false)

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lightBlue)

    local borderTop = BORDER_CHARS.corner .. string.rep(BORDER_CHARS.horizontal, width-2) .. BORDER_CHARS.corner
    local borderBottom = borderTop

    if title then
        local titleStart = math.floor((width - #title) / 2)
        borderTop = BORDER_CHARS.corner ..
                   string.rep(BORDER_CHARS.horizontal, titleStart-1) ..
                   title ..
                   string.rep(BORDER_CHARS.horizontal, width - #title - titleStart) ..
                   BORDER_CHARS.corner
    end

    monitor.setCursorPos(offsetX, offsetY)
    monitor.write(borderTop)
    monitor.setCursorPos(offsetX, offsetY + height + 1)
    monitor.write(borderBottom)

    for y = 1, height do
        monitor.setCursorPos(offsetX, offsetY + y)
        monitor.write(BORDER_CHARS.vertical)
        monitor.setCursorPos(offsetX + width + 1, offsetY + y)
        monitor.write(BORDER_CHARS.vertical)
    end

    local win = window.create(monitor, offsetX + 2, offsetY + 1, width, height, false)

    win.setBackgroundColor(colors.black)
    win.setTextColor(colors.white)
    win.clear()

    win.getSize = function()
        return width, height
    end

    return win
end

-- Draw frame directly on monitor
local function drawFrame(monitor, width, height, title, offsetX, offsetY)
    local oldBg = monitor.getBackgroundColor()
    local oldFg = monitor.getTextColor()

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lightBlue)

    offsetX = offsetX + 1
    offsetY = offsetY + 1

    width = width + 1

    local borderTop = BORDER_CHARS.corner .. string.rep(BORDER_CHARS.horizontal, width) .. BORDER_CHARS.corner
    if title then
        local titleStart = math.floor((width - #title) / 2)
        borderTop = BORDER_CHARS.corner ..
                   string.rep(BORDER_CHARS.horizontal, titleStart-1) ..
                   title ..
                   string.rep(BORDER_CHARS.horizontal, width - #title - titleStart) ..
                   BORDER_CHARS.corner
    end

    monitor.setCursorPos(offsetX, offsetY)
    monitor.write(borderTop)
    monitor.setCursorPos(offsetX, offsetY + height + 1)
    monitor.write(BORDER_CHARS.corner .. string.rep(BORDER_CHARS.horizontal, width) .. BORDER_CHARS.corner)

    for y = 1, height do
        monitor.setCursorPos(offsetX, offsetY + y)
        monitor.write(BORDER_CHARS.vertical)
        monitor.setCursorPos(offsetX + width + 1, offsetY + y)
        monitor.write(BORDER_CHARS.vertical)
    end

    monitor.setBackgroundColor(oldBg)
    monitor.setTextColor(oldFg)
end

-- Create a multitable that mirrors terminal operations
local function createMultiTable(...)
    local terms = {...}
    local output = {}

    local function wrapFunction(func, name)
        return function(...)
            local results
            for _, term in ipairs(terms) do
                if term[name] then
                    results = term[name](...)
                end
            end
            return results
        end
    end

    for k, v in pairs(terms[1]) do
        if type(v) == "function" then
            output[k] = wrapFunction(v, k)
        end
    end

    output.write = function(text)
        for _, term in ipairs(terms) do
            pcall(function()
                local x, y = term.getCursorPos()
                term.write(text)
            end)
        end
    end

    output.blit = function(text, textColors, bgColors)
        for _, term in ipairs(terms) do
            pcall(function()
                local x, y = term.getCursorPos()
                term.blit(text, textColors, bgColors)
            end)
        end
    end

    output.getSize = function()
        return terms[1].getSize()
    end

    output.clear = function()
        terms[1].clear()

        if terms[2] then
            pcall(function()
                terms[2].setBackgroundColor(colors.black)
                terms[2].clear()
                MirrorDisplay.redrawFrame()
            end)
        end
    end

    return output
end

-- Initialize the display
function MirrorDisplay.initialize(monitorName, title)
    MirrorDisplay.originalTerm = term.current()

    local monitor = peripheral.wrap(monitorName)
    if not monitor then
        return false
    end

    local termW, termH = term.getSize()
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    local mw, mh = monitor.getSize()
    local ox = math.floor((mw - termW) / 2) - 1
    local oy = math.floor((mh - termH) / 2) - 1

    MirrorDisplay.window = window.create(monitor, ox + 2, oy + 2, termW, termH, true)
    MirrorDisplay.monitor = monitor
    MirrorDisplay.frameOffset = {x = ox, y = oy}

    drawFrame(monitor, termW, termH, title, ox, oy)

    return true
end

-- Add function to redraw frame
function MirrorDisplay.redrawFrame(title)
    if not MirrorDisplay.monitor or not MirrorDisplay.window then return false end

    local termW, termH = term.getSize()
    drawFrame(MirrorDisplay.monitor, termW, termH, title,
             MirrorDisplay.frameOffset.x, MirrorDisplay.frameOffset.y)
    return true
end

-- Start mirroring
function MirrorDisplay.start()
    if not MirrorDisplay.monitor or not MirrorDisplay.window then return false end

    local multiTerm = createMultiTable(term.current(), MirrorDisplay.window)

    MirrorDisplay.originalTerm = term.current()
    term.redirect(multiTerm)
    MirrorDisplay.active = true

    MirrorDisplay.window.setVisible(true)
    MirrorDisplay.window.redraw()

    return true
end

-- Stop mirroring
function MirrorDisplay.stop()
    if MirrorDisplay.originalTerm then
        term.redirect(MirrorDisplay.originalTerm)
    end
    MirrorDisplay.active = false
end

-- Clean up
function MirrorDisplay.cleanup()
    MirrorDisplay.stop()
    if MirrorDisplay.monitor then
        MirrorDisplay.monitor.setBackgroundColor(colors.black)
        MirrorDisplay.monitor.clear()
    end
    MirrorDisplay.monitor = nil
    MirrorDisplay.window = nil
end

return MirrorDisplay