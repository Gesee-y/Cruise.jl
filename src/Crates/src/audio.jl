#######################################################################################################################
################################################### AUDIO CRATE IMPORTER ##############################################
#######################################################################################################################

export SoundCrate, PlaySound, AudioCrate, AudioStreamCrate

######################################################### CORE ########################################################

"""
    struct SoundCrate <: AbstractCrate
        chunk::Ptr{Mix_Chunk}
        volume::Int
"""
struct SoundCrate <: AbstractCrate
    chunk::Ptr{Mix_Chunk}
    volume::Int
end

struct AudioCrate <: AbstractCrate
    data::Matrix{Float32}
    rate::Int
end

struct AudioStreamCrate <: AbstractCrate
    path::String
    samplerate::Int
    channels::Int
    frames::Int
end

###################################################### FUNCTIONS ######################################################

"""
    Load(::Type{SoundCrate}, path::String, args...)

Load a new sound crate at the given `path`. Supported formats are `.wav`, `.mp3`, and `.ogg`.
`args` can include `volume` (default 128) to set the initial volume (0 to 128).

Throws an error if the file extension is not supported.
"""
function Load(::Type{SoundCrate}, path::String, volume=128, args...)
    # Gotta make sure it's the good extension.
    valid_extensions = [".wav", ".mp3", ".ogg"]
    ext = lowercase(splitext(path)[2])
    if !(ext in valid_extensions)
        error("Unsupported audio format for $path. Supported formats are: $(join(valid_extensions, ", "))")
    end
    
    # Load the sound with SDL_mixer
    chunk = Mix_LoadWAV(path)
    if chunk == C_NULL
        err = ""#Mix_GetError()
        @warn "Failed to load sound at $path."
        return nothing
    end
    
    # initial volume
    Mix_VolumeChunk(chunk, clamp(volume, 0, 128))
    
    # Create and return SoundCrate
    SoundCrate(chunk, volume)
end

function Load(::Type{AudioCrate}, path::String, args...)
    # Gotta make sure it's the good extension.
    valid_extensions = [".wav", ".ogg"]
    ext = lowercase(splitext(path)[2])
    if !(ext in valid_extensions)
        error("Unsupported audio format for $path. Supported formats are: $(join(valid_extensions, ", "))")
    end
    
    audio = load(path)
    if size(audio, 2) > 8
        @warn "File with $(size(audio, 2)) channels, reduced to stereo"
        audio = audio[:, 1:min(2, size(audio, 2))]
    end
    data = convert(Matrix{Float32}, audio.data)#')

    max_val = maximum(abs.(data))

    if max_val > 1.0
        @warn "Clipped audio detected, normalization applied"
        data ./= max_val
    end
    return AudioCrate(data, audio.samplerate)
end

function Load(::Type{AudioStreamCrate}, path::String, args...)
    # Gotta make sure it's the good extension.
    valid_extensions = [".wav", ".ogg"]
    ext = lowercase(splitext(path)[2])
    if !(ext in valid_extensions)
        error("Unsupported audio format for $path. Supported formats are: $(join(valid_extensions, ", "))")
    end
    
    info = loadstreaming(path).sfinfo
    return AudioStreamCrate(path, info.samplerate, info.channels, info.frames)
end

"""
    Destroy(sound::SoundCrate)

Destroy the sound crate `sound`, freeing the associated SDL_mixer resources.
"""
function Destroy(sound::SoundCrate)
    Mix_FreeChunk(sound.chunk)
end

"""
    PlaySound(sound::SoundCrate; loops::Int=0, channel::Int=-1)

Play the sound crate with the specified number of `loops` (0 for single play, -1 for infinite).
`channel` specifies the channel to play on (-1 for first available).
"""
function PlaySound(sound::SoundCrate; loops::Int=0, channel::Int=-1)
    channel = Mix_PlayChannel(channel, sound.chunk, loops)
    if channel == -1
        @warn "Error while playing the sound: "#$(Mix_GetError())"
    end
    return channel
end

"""
    SetSoundVolume(sound::SoundCrate, volume::Int)

Set the volume of the sound crate (0 to 128).
"""
function SetSoundVolume(sound::SoundCrate, volume::Int)
    Mix_VolumeChunk(sound.chunk, clamp(volume, 0, 128))
    sound.volume = volume
end

"""
    SetPanning(sound::SoundCrate, channel::Int, left::Int, right::Int)

Set the stereo panning for the sound crate on the specified `channel` (0 to 255 for each side).
"""
function SetPanning(sound::SoundCrate, channel::Int, left::Int, right::Int)
    if channel != -1
        Mix_SetPanning(channel, clamp(left, 0, 255), clamp(right, 0, 255))
    else
        @warn "No channel assigned for the sound. Play it first."
    end
end

"""
    SetDistance(sound::SoundCrate, channel::Int, distance::Int, angle::Int)

Set the distance effect (0 to 255) and angle (0 to 360) for the sound crate on the specified `channel`.
"""
function SetDistance(sound::SoundCrate, channel::Int, distance::Int, angle::Int)
    if channel != -1
        Mix_SetPosition(channel, angle % 360, clamp(distance, 0, 255))
    else
        @warn "No channel assigned for the sound. Play it first."
    end
end
