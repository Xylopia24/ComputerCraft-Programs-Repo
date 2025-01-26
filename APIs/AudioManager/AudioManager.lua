--[[
    AudioManager API
    Version: 2.1.0
    Created By: Xylopia
    
    A comprehensive audio management API for ComputerCraft speakers.
    
    Sound File Support:
    - Uses Minecraft's built-in sound system (.ogg files)
    - Supports vanilla, mod-added, and resource pack sounds
    - Sound format: "namespace:path.to.sound"
      Example: "minecraft:music.game" or "modid:custom.music"
]]

-- AudioManager module
local AudioManager = {
    VERSION = "2.1.0",
    DEBUG = false,
    config = {
        autoInitialize = true,
        defaultVolume = 1.0,
        defaultCrossfade = 2,
        leftSpeaker = "speaker_1",
        rightSpeaker = "speaker_2"
    }
}

-- Enhanced state management
local State = {
    speaker = nil,
    volume = 1.0,
    isLooping = true,
    isShuffle = false,
    isMuted = false,
    lastVolume = 1.0,  -- For mute/unmute functionality
    currentTrack = {
        song = nil,
        name = nil,
        duration = nil,
        startTime = nil,
        position = 0
    },
    playlist = {
        current = {},
        name = nil,
        index = 1,
        history = {},  -- For tracking played songs
        queue = {}     -- For custom song queue
    },
    fade = {
        timer = nil,
        target = nil,
        stepSize = 0.1,
        interval = 0.1
    },
    crossfade = {
        duration = 2,  -- Default crossfade duration in seconds
        isEnabled = false
    },
    playbackLock = false  -- Add this new state variable
}

-- Add after State declaration
local SpeakerSystem = {
    speakers = {},
    primary = nil,
    maxRange = 16,  -- Maximum range in blocks
    synchronized = true,
    balancing = {
        enabled = false,
        left = 1.0,
        right = 1.0
    }
}

-- Event system enhancement
local EventType = {
    SONG_START = "SONG_START",
    SONG_END = "SONG_END",
    PLAYLIST_START = "PLAYLIST_START",
    PLAYLIST_END = "PLAYLIST_END",
    VOLUME_CHANGE = "VOLUME_CHANGE",
    ERROR = "ERROR",
    -- New events
    MUTE_CHANGE = "MUTE_CHANGE",
    PLAYLIST_LOOP = "PLAYLIST_LOOP",
    CROSSFADE_START = "CROSSFADE_START",
    CROSSFADE_END = "CROSSFADE_END"
}

local eventCallbacks = {}

-- Example playlists with generic metadata
local playlists = {
    ["Example Playlist"] = {
        metadata = {
            description = "Example of various Minecraft sound types",
            tags = {"example", "minecraft"},
            defaultCrossfade = 2
        },
        tracks = {
            -- Vanilla Minecraft sounds
            { name = "Note Block Harp", song = "minecraft:block.note_block.harp", duration = 2 },
            { name = "Game Music", song = "minecraft:music.game", duration = 180 },
            -- Example mod sound format
            { name = "Custom Music", song = "modid:music.custom_track", duration = 120 },
            { name = "Resource Pack Music", song = "resourcepack:music.track1", duration = 180 }
        }
    }
}

-- Enhanced initialization
function AudioManager.initialize(options)
    options = options or {}

    -- Update config with any provided speaker names
    if options.leftSpeaker then
        AudioManager.config.leftSpeaker = options.leftSpeaker
    end
    if options.rightSpeaker then
        AudioManager.config.rightSpeaker = options.rightSpeaker
    end

    -- Reset all state on initialization
    State = {
        speaker = nil,
        volume = options.volume or 1.0,
        isLooping = options.isLooping ~= false,
        isShuffle = false,
        isMuted = false,
        lastVolume = 1.0,
        playbackLock = false,
        currentTrack = {
            song = nil,
            name = nil,
            duration = nil,
            startTime = nil,
            position = 0
        },
        playlist = {
            current = {},
            name = nil,
            index = 1,
            history = {},
            queue = {}
        },
        fade = {
            timer = nil,
            target = nil,
            stepSize = 0.1,
            interval = 0.1
        },
        crossfade = {
            duration = options.crossfadeDuration or 2,
            isEnabled = options.crossfade ~= false
        }
    }

    -- Find and initialize speaker
    State.speaker = peripheral.find("speaker")
    if not State.speaker then
        return false
    end

    -- Initialize speaker system
    SpeakerSystem.speakers = {}
    SpeakerSystem.primary = nil

    -- Find all available speakers with specific names
    local speakerList = {peripheral.find("speaker")}

    -- Map speakers to their positions using config names
    for _, speaker in ipairs(speakerList) do
        local name = peripheral.getName(speaker)

        -- Store speaker with position info based on name
        SpeakerSystem.speakers[name] = {
            device = speaker,
            position = {x=0, y=0, z=0},
            volume = 1.0,
            isLeft = name == AudioManager.config.leftSpeaker,
            isRight = name == AudioManager.config.rightSpeaker
        }

        -- Set primary speaker if not set
        if not SpeakerSystem.primary then
            SpeakerSystem.primary = name
        end
    end

    -- Enable stereo if we have both configured speakers
    local hasLeft = SpeakerSystem.speakers[AudioManager.config.leftSpeaker] ~= nil
    local hasRight = SpeakerSystem.speakers[AudioManager.config.rightSpeaker] ~= nil
    SpeakerSystem.balancing.enabled = hasLeft and hasRight

    -- Initialize main state speaker reference
    State.speaker = speakerList[1]

    return #speakerList > 0
end

-- New debug function
function AudioManager.debugState()
    if not AudioManager.DEBUG then return end

    local debug = {
        "AudioManager Debug State:",
        string.format("Volume: %.2f (Muted: %s)", State.volume, tostring(State.isMuted)),
        string.format("Current Song: %s", State.currentTrack.name or "None"),
        string.format("Playlist: %s (%d/%d)",
            State.playlist.name or "None",
            State.playlist.index,
            #State.playlist.current
        ),
        string.format("Looping: %s, Shuffle: %s",
            tostring(State.isLooping),
            tostring(State.isShuffle)
        )
    }

    for _, msg in ipairs(debug) do
        -- Keep debug functionality but without using log()
    end
end

-- Enhanced playlist management
function AudioManager.setCurrentPlaylist(playlist, name)
    if type(playlist) ~= "table" or #playlist == 0 then
        return false
    end

    State.playlist.current = playlist
    State.playlist.name = name
    State.playlist.index = 1
    State.playlist.history = {}

    if State.isShuffle then
        AudioManager.shufflePlaylist()
    end

    AudioManager.triggerEvent(EventType.PLAYLIST_START, {
        name = name,
        trackCount = #playlist
    })

    return true
end

-- Add new helper function to get track name
function AudioManager.getTrackName(songName)
    -- First try to find the song in the current playlist
    if State.playlist.current then
        for _, track in ipairs(State.playlist.current) do
            if track.song == songName then
                return track.name
            end
        end
    end

    -- If not found in playlist, try to find in all playlists
    for _, playlist in pairs(playlists) do
        for _, track in ipairs(playlist.tracks) do
            if track.song == songName then
                return track.name
            end
        end
    end

    -- Fallback to the raw song name with namespace handling
    local namespace, sound = songName:match("([^:]+):(.+)")
    if namespace and sound then
        return sound:gsub("%.", " "):gsub("_", " "):gsub("^%l", string.upper)
    end
    return songName
end

-- Enhanced playback control
function AudioManager.playSong(songName, duration)
    if next(SpeakerSystem.speakers) == nil then
        return false
    end

    -- Stop all speakers first
    for name, speaker in pairs(SpeakerSystem.speakers) do
        speaker.device.stop()
    end

    -- Small delay for synchronization
    os.sleep(0.05)

    -- Play on all speakers with proper balancing
    local success = true
    for name, speaker in pairs(SpeakerSystem.speakers) do
        local volume = State.volume

        -- Apply stereo balancing if enabled
        if SpeakerSystem.balancing.enabled then
            if speaker.isLeft then
                volume = volume * SpeakerSystem.balancing.left
            elseif speaker.isRight then
                volume = volume * SpeakerSystem.balancing.right
            end
        end

        local ok = pcall(function()
            speaker.device.playSound(songName, volume)
        end)

        success = success and ok
    end

    if not success then
        return false
    end

    -- Update state
    State.currentTrack = {
        song = songName,
        name = AudioManager.getTrackName(songName),
        duration = duration,
        startTime = os.epoch("local") / 1000,
        position = 0
    }

    return true
end

-- New crossfade implementation
function AudioManager.crossfade(newSong, duration)
    local startVolume = State.volume
    local steps = math.floor(State.crossfade.duration / State.fade.interval)
    local volumeStep = startVolume / steps

    -- Start fading out current song
    AudioManager.triggerEvent(EventType.CROSSFADE_START, {
        from = State.currentTrack.song,
        to = newSong
    })

    parallel.waitForAll(
        -- Fade out current song
        function()
            local currentVolume = startVolume
            for i = 1, steps do
                currentVolume = currentVolume - volumeStep
                if currentVolume < 0 then currentVolume = 0 end
                State.speaker.playSound(State.currentTrack.song, currentVolume)
                os.sleep(State.fade.interval)
            end
            State.speaker.stop()
        end,
        -- Fade in new song
        function()
            local currentVolume = 0
            State.speaker.playSound(newSong, 0)
            os.sleep(State.fade.interval * 2) -- Small delay for smoother transition

            for i = 1, steps do
                currentVolume = currentVolume + volumeStep
                if currentVolume > startVolume then currentVolume = startVolume end
                State.speaker.playSound(newSong, currentVolume)
                os.sleep(State.fade.interval)
            end
        end
    )

    -- Update state after crossfade
    State.currentTrack = {
        song = newSong,
        name = AudioManager.getTrackName(newSong),
        duration = duration,
        startTime = os.epoch("local") / 1000,
        position = 0
    }

    AudioManager.triggerEvent(EventType.CROSSFADE_END, {
        song = newSong,
        name = State.currentTrack.name
    })
end

-- New volume control functions
function AudioManager.toggleMute()
    State.isMuted = not State.isMuted
    if State.isMuted then
        State.lastVolume = State.volume
        AudioManager.setVolume(0)
    else
        AudioManager.setVolume(State.lastVolume)
    end

    AudioManager.triggerEvent(EventType.MUTE_CHANGE, {
        isMuted = State.isMuted
    })

    return State.isMuted
end

-- The rest of the existing functions remain largely unchanged, just updated
-- to use the new State management system:

function AudioManager.setLooping(shouldLoop)
    State.isLooping = shouldLoop
end

function AudioManager.isLooping()
    return State.isLooping
end

-- Grab Song and Playlist information
function AudioManager.getCurrentSong()
    return State.currentTrack.song
end

function AudioManager.getCurrentPlaylist()
    return State.playlist.current
end

function AudioManager.getCurrentSongName()
    return State.currentTrack.name
end

function AudioManager.getCurrentPlaylistName()
    return State.playlist.name
end

function AudioManager.getPlaylistByName(name)
    if playlists[name] then
        return playlists[name], name
    end
    return nil
end

function AudioManager.getCurrentTime()
    if not State.currentTrack.startTime then return 0 end
    State.currentTrack.position = os.epoch("local") / 1000 - State.currentTrack.startTime
    return math.floor(State.currentTrack.position)
end

function AudioManager.getCurrentSongDuration()
    if State.playlist.current and State.playlist.current[State.playlist.index] then
        return State.playlist.current[State.playlist.index].duration
    end
    return 0
end

-- Volume Control
function AudioManager.setVolume(newVolume)
    if newVolume < 0 then newVolume = 0 end
    if newVolume > 1 then newVolume = 1 end

    State.volume = newVolume
    if State.speaker and State.currentTrack.song then
        State.speaker.stop()
        State.speaker.playSound(State.currentTrack.song, State.volume)
    end

    AudioManager.triggerEvent(EventType.VOLUME_CHANGE, {volume = State.volume})
end

function AudioManager.getVolume()
    return State.volume
end

function AudioManager.fadeVolume(target, duration)
    if State.fade.timer then
        os.cancelTimer(State.fade.timer)
    end

    State.fade.target = math.max(0, math.min(1, target))
    local steps = math.ceil(duration / State.fade.interval)
    State.fade.stepSize = (State.fade.target - State.volume) / steps

    local function fade()
        State.volume = State.volume + State.fade.stepSize
        if (State.fade.stepSize > 0 and State.volume >= State.fade.target) or
           (State.fade.stepSize < 0 and State.volume <= State.fade.target) then
            State.volume = State.fade.target
            os.cancelTimer(State.fade.timer)
            State.fade.timer = nil
        end

        if State.speaker and State.currentTrack.song then
            State.speaker.stop()
            State.speaker.playSound(State.currentTrack.song, State.volume)
        end
    end

    State.fade.timer = os.startTimer(State.fade.interval)
    parallel.waitForAll(function()
        while State.fade.timer do
            local _, timerID = os.pullEvent("timer")
            if timerID == State.fade.timer then
                fade()
                if State.fade.timer then
                    State.fade.timer = os.startTimer(State.fade.interval)
                end
            end
        end
    end)
end

-- Playlist Management
function AudioManager.shufflePlaylist()
    if #State.playlist.current <= 1 then return end

    local shuffled = {}
    local indices = {}
    for i = 1, #State.playlist.current do
        indices[i] = i
    end

    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    for i, index in ipairs(indices) do
        shuffled[i] = State.playlist.current[index]
    end

    State.playlist.current = shuffled
    State.playlist.index = 1
end

function AudioManager.toggleShuffle()
    State.isShuffle = not State.isShuffle
    if State.isShuffle then
        AudioManager.shufflePlaylist()
    end
    return State.isShuffle
end

-- Add a new function to update the current track index
function AudioManager.setCurrentTrackIndex(index)
    if State.playlist.current and index >= 1 and index <= #State.playlist.current then
        State.playlist.index = index
    end
end

-- Event System
function AudioManager.addEventListener(eventType, callback)
    if not eventCallbacks[eventType] then
        eventCallbacks[eventType] = {}
    end
    table.insert(eventCallbacks[eventType], callback)
end

function AudioManager.removeEventListener(eventType, callback)
    if eventCallbacks[eventType] then
        for i, cb in ipairs(eventCallbacks[eventType]) do
            if cb == callback then
                table.remove(eventCallbacks[eventType], i)
                break
            end
        end
    end
end

function AudioManager.triggerEvent(eventType, data)
    if eventCallbacks[eventType] then
        for _, callback in ipairs(eventCallbacks[eventType]) do
            pcall(callback, data)
        end
    end
end

-- Stopping Functions
function AudioManager.stopAll()
    for name, speaker in pairs(SpeakerSystem.speakers) do
        pcall(function()
            speaker.device.stop()
        end)
    end

    if State.fade.timer then
        os.cancelTimer(State.fade.timer)
        State.fade.timer = nil
    end

    if State.speaker and (State.currentTrack.song or #State.playlist.current > 0) then
        shouldPlay = false
        pcall(function()
            State.speaker.stop()
        end)
        State.speaker.stop()
        State.currentTrack.song = nil
        State.currentTrack.duration = nil
        State.currentTrack.name = nil
        State.currentTrack.position = 0
        State.currentTrack.startTime = nil
        State.playlist.name = nil
        State.playlist.current = {}
        State.playlist.index = 1
        AudioManager.triggerEvent(EventType.SONG_END, {
            song = State.currentTrack.song,
            completed = false
        })
    end
end

-- Add new speaker management functions
function AudioManager.addSpeaker(name, position)
    local speaker = peripheral.wrap(name)
    if not speaker then
        return false
    end

    SpeakerSystem.speakers[name] = {
        device = speaker,
        position = position or {x=0, y=0, z=0},
        volume = 1.0
    }

    if not SpeakerSystem.primary then
        SpeakerSystem.primary = name
    end

    return true
end

function AudioManager.setSpeakerBalance(left, right)
    SpeakerSystem.balancing.enabled = true
    SpeakerSystem.balancing.left = math.max(0, math.min(1, left))
    SpeakerSystem.balancing.right = math.max(0, math.min(1, right))
end

-- Add speaker status function
function AudioManager.getSpeakerStatus()
    local status = {
        total = 0,
        active = 0,
        speakers = {}
    }

    for name, speaker in pairs(SpeakerSystem.speakers) do
        status.total = status.total + 1
        local isActive = true -- speakers don't have a direct way to check if they're playing
        if isActive then status.active = status.active + 1 end

        status.speakers[name] = {
            position = speaker.position,
            volume = speaker.volume,
            active = isActive
        }
    end

    return status
end

-- Add new playlist management that doesn't rely on predefined playlists
function AudioManager.createPlaylist(name, tracks)
    if type(tracks) ~= "table" or #tracks == 0 then
        return false
    end

    -- Validate track format
    for i, track in ipairs(tracks) do
        if type(track) ~= "table" or not track.song then
            return false
        end
        -- Ensure required fields exist
        track.name = track.name or track.song
        track.duration = track.duration or 0
    end

    return {
        metadata = {
            name = name,
            created = os.epoch("local")
        },
        tracks = tracks
    }
end

-- Add API utility functions
function AudioManager.getVersion()
    return AudioManager.VERSION
end

function AudioManager.setDebug(enabled)
    AudioManager.DEBUG = enabled
end

function AudioManager.getStatus()
    return {
        initialized = State.speaker ~= nil,
        playing = State.currentTrack.song ~= nil,
        volume = State.volume,
        muted = State.isMuted,
        currentTrack = {
            name = State.currentTrack.name,
            position = AudioManager.getCurrentTime(),
            duration = State.currentTrack.duration
        },
        speakers = AudioManager.getSpeakerStatus()
    }
end

-- Add speaker configuration functions
function AudioManager.configureSpeakers(leftName, rightName)
    AudioManager.config.leftSpeaker = leftName
    AudioManager.config.rightSpeaker = rightName
    
    -- Update existing speakers if already initialized
    if next(SpeakerSystem.speakers) then
        for name, speaker in pairs(SpeakerSystem.speakers) do
            speaker.isLeft = name == leftName
            speaker.isRight = name == rightName
        end
        
        -- Update stereo balancing
        local hasLeft = SpeakerSystem.speakers[leftName] ~= nil
        local hasRight = SpeakerSystem.speakers[rightName] ~= nil
        SpeakerSystem.balancing.enabled = hasLeft and hasRight
    end
end

-- Add function to get current speaker configuration
function AudioManager.getSpeakerConfig()
    return {
        left = AudioManager.config.leftSpeaker,
        right = AudioManager.config.rightSpeaker,
        stereoEnabled = SpeakerSystem.balancing.enabled
    }
end

-- Export public interface
AudioManager.EventType = EventType

return AudioManager