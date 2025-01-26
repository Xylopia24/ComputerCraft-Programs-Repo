# AudioManager API

A comprehensive audio management API for ComputerCraft/CC: Tweaked speakers with support for playlists, crossfading, and stereo output.

## Features

- Multi-speaker support with stereo balancing
- Playlist management with shuffle and loop options
- Volume control with fade effects
- Crossfading between tracks
- Event system for audio state changes
- Comprehensive error handling
- Debug capabilities

## Sound File Support

The AudioManager uses Minecraft's built-in sound system and supports:
- Resource pack sound files (.ogg format)
- Mod-added sounds
- Built-in Minecraft sounds

Sound files are referenced using Minecraft's namespace format:
- `minecraft:block.note_block.harp` - Vanilla Minecraft sounds
- `modid:path.to.sound` - Mod-added sounds
- `resourcepack:custom.sound` - Resource pack sounds

### Sound File Examples
```lua
-- Vanilla Minecraft sounds
"minecraft:block.note_block.harp"      -- Note block sounds
"minecraft:music.game"                 -- Background music
"minecraft:music.creative"             -- Creative mode music
"minecraft:block.bell.use"            -- Bell sound

-- Common mod sound format
"kubejs:custom.music.track1"          -- KubeJS added sounds
"mymod:music/custom_track"            -- Mod music
```

## Installation

1. Place `AudioManager.lua` in your computer's APIs directory or whereever you'd like to store external APIs
2. Require the API in your program:
```lua
local AudioManager = require("AudioManager")
```

## Basic Usage

```lua
-- Initialize the API with specific speaker configuration
AudioManager.initialize({
    volume = 0.8,           -- Initial volume (0.0-1.0)
    leftSpeaker = "speaker_4",   -- Specific speaker peripheral names
    rightSpeaker = "speaker_5"
})

-- Create a playlist using Minecraft sound files
local playlist = AudioManager.createPlaylist("Background Music", {
    {
        name = "Minecraft Menu",
        song = "minecraft:music.menu",     -- Original Minecraft music
        duration = 600                     -- Duration in seconds
    },
    {
        name = "Custom Mod Track",
        song = "mymod:music.custom_track", -- Mod-added music
        duration = 180
    }
})

-- Set and play the playlist
AudioManager.setCurrentPlaylist(playlist, "Background Music")
AudioManager.playSong(playlist.tracks[1].song, playlist.tracks[1].duration)
```

## Speaker Configuration

### Single Speaker Setup
```lua
AudioManager.initialize()  -- Uses first available speaker
```

### Stereo Setup
```lua
-- Configure specific speakers
AudioManager.configureSpeakers("speaker_1", "speaker_2")

-- Adjust balance
AudioManager.setSpeakerBalance(0.8, 1.0)  -- Left: 80%, Right: 100%
```

## Playlist Management

### Creating Playlists
```lua
local playlist = AudioManager.createPlaylist("Example", {
    {
        name = "Custom Name",     -- Optional, defaults to song ID
        song = "namespace:path",   -- Required
        duration = 10             -- Optional, defaults to 0
    }
})
```

### Playlist Controls
```lua
AudioManager.setLooping(true)      -- Enable playlist loop
AudioManager.toggleShuffle()       -- Toggle shuffle mode
AudioManager.setCurrentTrackIndex(2)  -- Jump to specific track
```

## Volume Control

```lua
AudioManager.setVolume(0.5)        -- Set volume (0.0-1.0)
AudioManager.fadeVolume(0.8, 2)    -- Fade to volume over duration
AudioManager.toggleMute()          -- Toggle mute
```

## Event System

```lua
-- Add event listener
AudioManager.addEventListener(AudioManager.EventType.SONG_END, function(data)
    print("Song ended:", data.song)
end)

-- Available events:
-- SONG_START, SONG_END, PLAYLIST_START, PLAYLIST_END
-- VOLUME_CHANGE, ERROR, MUTE_CHANGE, PLAYLIST_LOOP
-- CROSSFADE_START, CROSSFADE_END
```

## API Reference

### Initialization
- `initialize(options)` - Initialize the API
- `configureSpeakers(leftName, rightName)` - Configure stereo speakers
- `getSpeakerConfig()` - Get current speaker configuration

### Playback Control
- `playSong(songName, duration)` - Play a single song
- `stopAll()` - Stop all playback
- `crossfade(newSong, duration)` - Crossfade to new song

### Volume Control
- `setVolume(volume)` - Set volume (0.0-1.0)
- `getVolume()` - Get current volume
- `fadeVolume(target, duration)` - Fade volume
- `toggleMute()` - Toggle mute state

### Playlist Management
- `createPlaylist(name, tracks)` - Create new playlist
- `setCurrentPlaylist(playlist, name)` - Set active playlist
- `shufflePlaylist()` - Shuffle current playlist
- `setLooping(shouldLoop)` - Set playlist loop
- `toggleShuffle()` - Toggle shuffle mode

### Status & Information
- `getStatus()` - Get comprehensive status
- `getCurrentSong()` - Get current song ID
- `getCurrentSongName()` - Get current song name
- `getCurrentTime()` - Get current track position
- `getSpeakerStatus()` - Get speaker status

### Event System
- `addEventListener(eventType, callback)` - Add event listener
- `removeEventListener(eventType, callback)` - Remove event listener

## Examples

### Advanced Playlist with Crossfading
```lua
-- Create and configure playlist
local playlist = AudioManager.createPlaylist("Background Music", {
    { name = "Track 1", song = "minecraft:music.menu" },
    { name = "Track 2", song = "minecraft:music.game" }
})

-- Set up event handling
AudioManager.addEventListener(AudioManager.EventType.SONG_END, function(data)
    local nextTrack = playlist.tracks[AudioManager.getCurrentTrackIndex() + 1]
    if nextTrack then
        AudioManager.crossfade(nextTrack.song, 2)
    end
end)

-- Start playback
AudioManager.setCurrentPlaylist(playlist)
AudioManager.playSong(playlist.tracks[1].song)
```

### Volume Automation
```lua
-- Fade volume based on time of day
parallel.waitForAll(function()
    while true do
        local time = os.time()
        if time > 0.8 then  -- Evening
            AudioManager.fadeVolume(0.3, 5)  -- Fade to 30% over 5 seconds
        elseif time > 0.2 then  -- Day
            AudioManager.fadeVolume(0.8, 5)  -- Fade to 80% over 5 seconds
        end
        os.sleep(30)
    end
end)
```

## Version History

- 2.1.0
    - Added stereo support and speaker configuration
- 2.0.0
    - Initial public release
    - Removed all Reference to the Previous Program Locked method of this API

## Credits

Created by Xylopia