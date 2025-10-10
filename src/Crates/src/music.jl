#######################################################################################################################
################################################### AUDIO CRATE IMPORTER ##############################################
#######################################################################################################################

export MusicCrate, PlayMusic, PauseMusic

######################################################### CORE ########################################################

"""
    struct MusicCrate <: AbstractCrate
        music::Ptr{Mix_Music}
        volume::Int
"""
struct MusicCrate <: AbstractCrate
    music::Ptr{Mix_Music}
    volume::Int
end

###################################################### FUNCTIONS ######################################################

"""
    Load(::Type{MusicCrate}, path::String, args...)

Load a new music crate at the given `path`. Supported formats are `.mp3` and `.ogg`.
`args` can include `volume` (default 128) to set the initial volume (0 to 128).

Throws an error if the file extension is not supported.
"""
function Load(::Type{MusicCrate}, path::String, volume=128, args...)
    valid_extensions = [".mp3", ".ogg"]
    ext = lowercase(splitext(path)[2])
    if !(ext in valid_extensions)
        error("Unsupported music format for $path. Supported formats are: $(join(valid_extensions, ", "))")
    end
    
    music = Mix_LoadMUS(path)
    if music == C_NULL
        err = ""#Mix_GetError()
        @warn "Failed to load music at $path."
        return nothing
    end
    
    Mix_VolumeMusic(clamp(volume, 0, 128))
    MusicCrate(music, volume)
end

"""
    Destroy(music::MusicCrate)

Destroy the music crate `music`, freeing the associated SDL_mixer resources.
"""
function Destroy(music::MusicCrate)
    Mix_FreeMusic(music.music)
end

"""
    PlayMusic(music::MusicCrate; loops::Int=-1)

Play the music crate with the specified number of `loops` (-1 for infinite, 0 for single play).
"""
function PlayMusic(music::MusicCrate; loops::Int=-1)
    if Mix_PlayMusic(music.music, loops) != 0
        @warn "Error while playing the music: $(Mix_GetError())"
    end
end

"""
    PauseMusic()

Pause the currently playing music.
"""
function PauseMusic()
    Mix_PauseMusic()
end

"""
    ResumeMusic()

Resume the paused music.
"""
function ResumeMusic()
    Mix_ResumeMusic()
end

"""
    StopMusic()

Stop the currently playing music.
"""
function StopMusic()
    Mix_HaltMusic()
end

"""
    SetMusicVolume(music::MusicCrate, volume::Int)

Set the volume of the music crate (0 to 128).
"""
function SetMusicVolume(music::MusicCrate, volume::Int)
    Mix_VolumeMusic(clamp(volume, 0, 128))
    music.volume = volume
end
