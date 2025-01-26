# MirrorDisplay API Documentation
A lightweight terminal mirroring API for ComputerCraft monitors.

## 📋 Overview
MirrorDisplay provides easy-to-use functions for mirroring terminal output to connected monitors with custom styling and automatic scaling.

## ⚙️ Installation
```lua
-- Copy MirrorDisplay.lua to your computer
-- Then require it in your program:
local mirror = require("MirrorDisplay")
```

## 🚀 Quick Start
```lua
-- Basic usage
local mirror = require("MirrorDisplay")
mirror.initialize("right", "=[ My Program ]=")
mirror.start()

-- Your program code here...
print("This will show on both terminal and monitor!")

-- Cleanup when done
mirror.cleanup()
```

## 📖 API Reference

### Core Functions
```lua
MirrorDisplay.initialize(monitorSide, headerText)
-- Sets up mirroring for specified monitor
-- monitorSide: string (e.g., "right", "left", "top", etc.)
-- headerText: string (optional header text)

MirrorDisplay.start()
-- Begins mirroring terminal output

MirrorDisplay.stop()
-- Temporarily stops mirroring

MirrorDisplay.cleanup()
-- Cleans up resources and stops mirroring

MirrorDisplay.isActive()
-- Returns whether mirroring is currently active
```

### Configuration
- Default scale: 0.5
- Automatic terminal size detection
- Custom header styling
- Error handling included

## ⚡ Performance
- Minimal performance impact
- Efficient screen updates
- Low memory footprint

## 🔍 Examples

### Basic Terminal Mirroring
```lua
local mirror = require("MirrorDisplay")

mirror.initialize("right", "=[ Status Display ]=")
mirror.start()

while true do
  print("Current time: " .. os.time())
  sleep(1)
end
```

### Advanced Usage
```lua
local mirror = require("MirrorDisplay")

-- Custom error handling
if not mirror.initialize("top") then
  print("Failed to initialize mirror display")
  return
end

-- Start mirroring with error check
if mirror.start() then
  print("Mirror display active!")
else
  print("Failed to start mirroring")
end

-- Your code here...

mirror.cleanup()
```

## 🐛 Troubleshooting
- Ensure monitor is connected and accessible
- Check monitor side specification
- Verify terminal size compatibility

## 🤝 Contributing
Feel free to submit issues or pull requests to improve the API.
