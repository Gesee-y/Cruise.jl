#######################################################################################################################
################################################### AUDIO CRATE IMPORTER ##############################################
#######################################################################################################################

export SoundCrate, MusicCrate, InitAudioCrates

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
    InitAudioCrates()
Initialize SDL_mixer with support for WAV, MP3, and OGG formats.
Warns if MP3 or OGG support is not available.
"""
function InitAudioCrates()
    SDL_Init(SDL_INIT_AUDIO)
    flags = Mix_Init(MIX_INIT_MP3 | MIX_INIT_OGG)
    if (flags & MIX_INIT_MP3) == 0
        @warn "MP3 support not available: $(Mix_GetError())"
    end
    if (flags & MIX_INIT_OGG) == 0
        @warn "OGG support not available: $(Mix_GetError())"
    end
    if Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) != 0
        error("Erreur lors de l'initialisation de SDL_mixer: $(Mix_GetError())")
    end
end

"""
    Load(::Type{MusicCrate}, path::String, args...)

Load a new music crate at the given `path`. Supported formats are `.mp3` and `.ogg`.
`args` can include `volume` (default 128) to set the initial volume (0 to 128).

Throws an error if the file extension is not supported.
"""
function Load(::Type{MusicCrate}, path::String, args...)
    valid_extensions = [".mp3", ".ogg"]
    ext = lowercase(splitext(path)[2])
    if !(ext in valid_extensions)
        error("Unsupported music format for $path. Supported formats are: $(join(valid_extensions, ", "))")
    end
    
    volume = get(args, :volume, 128)
    music = Mix_LoadMUS(path)
    if music == C_NULL
        err = Mix_GetError()
        HORIZON_WARNING.emit = ("Failed to load music at $path.", err)
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

end # module