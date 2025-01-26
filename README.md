# ComputerCraft Programs Repository
*Created by Xylopia*

A collection of useful ComputerCraft/CC:Tweaked programs and APIs for Minecraft automation and enhancement.

## Featured APIs

### MirrorDisplay API
A simple yet powerful API for mirroring terminal output to connected monitors in ComputerCraft.

#### 📌 Features
- Easy terminal mirroring to any connected monitor
- Automatic screen scaling
- Custom header support
- Built-in error handling
- Lightweight implementation

#### 🚀 Quick Start
```lua
local mirror = require("MirrorDisplay")

-- Initialize with monitor on right side and custom header
mirror.initialize("right", "=[ My Program ]=")

-- Start mirroring
mirror.start()

-- Your program code here...
-- Everything written to the terminal will be mirrored!

-- When done, cleanup
mirror.cleanup()
```

#### 📖 API Reference
```lua
MirrorDisplay.initialize(monitorSide, headerText)  -- Set up mirroring
MirrorDisplay.start()                             -- Begin mirroring
MirrorDisplay.stop()                              -- Stop mirroring
MirrorDisplay.cleanup()                           -- Clean up resources
MirrorDisplay.isActive()                          -- Check if mirroring is active
```

#### ⚙️ Configuration
- Default monitor scale: 0.5
- Supports any monitor size
- Automatically adapts to terminal content

## Installation

1. Clone this repository or download desired programs
2. Place files in your ComputerCraft computer's directory
3. Require the APIs in your programs

```lua
local mirror = require("MirrorDisplay")
```

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

MIT License - Feel free to use in your own projects!

## Author

Created by Xylopia (Vinyl)
- GitHub: [Your GitHub]
- Discord: [Your Discord if you want to share]

---
*More programs and documentation coming soon!*