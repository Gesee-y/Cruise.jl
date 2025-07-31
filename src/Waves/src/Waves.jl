module Waves

using LibSndFile
using PortAudio
using DSP
using LinearAlgebra
using Base.Threads
using UUIDs

export WavesSystem, AbstractAudioSource, AudioSource, StreamingAudioSource, AudioGroup, AudioBus,
       AudioError, FileNotFoundError, UnsupportedFormatError, PlayState, STOPPED, PLAYING, PAUSED,
       ModulableEffect, init_waves, load_audio, generate_sine_wave, generate_white_noise,
       play!, pause!, stop!, reset!, seek!, set_speed!, set_volume!, set_loop!, fade_in!, fade_out!,
       create_group, add_to_group!, remove_from_group!, create_bus, add_to_bus!, remove_from_bus!,
       add_send!, remove_send!, solo!, mute!, add_effect!, remove_effect!, update_effect_params!,
       create_reverb, create_delay, create_compressor, create_eq_filter,
       start!, stop!, close!, get_metrics, reset_metrics!, find_source, list_all_sources


include("core.jl")
include("operations.jl")
include("effects.jl")
include("mixer.jl")
include("utils.jl")

"""
    init_waves(sample_rate=44100.0, buffer_size=1024)

Initialize the audio system.

# Arguments
- `sample_rate::Float64`: Sample rate in Hz (default: 44100.0).
- `buffer_size::Int`: Buffer size in samples (default: 1024).

# Returns
- `WavesSystem`: Initialized audio system.

# Throws
- `AudioError`: If initialization fails.

# Example
```julia
ws = init_waves(44100.0, 1024)
```
"""
function init_waves(sample_rate::Float64=44100.0, buffer_size::Int=1024)
    try
        return WavesSystem(sample_rate, buffer_size)
    catch e
        throw(AudioError("Impossible d'initialiser le système audio: $(e.msg)"))
    end
end

"""
    start!(system::WavesSystem)

Start the audio system.

# Arguments
- `system::WavesSystem`: The audio system to start.
"""
function start!(system::WavesSystem)
    if system.is_running
        @warn "Le système audio est déjà en cours d'exécution"
        return
    end

    system.is_running = true
    system.audio_thread = @async begin
        try
            sample_time = system.buffer_size / system.sample_rate

            while system.is_running
                start_time = time()

                mix_sources!(system)

                process_time = time() - start_time
                system.metrics.cpu_usage = process_time / sample_time * 100

                remaining_time = sample_time - process_time
                if remaining_time > 0
                    sleep(remaining_time)
                end
            end
        catch e
            @error "Erreur dans le thread audio: $e"
            system.is_running = false
        end
    end

    @info "Système audio démarré"
end

"""
    stop!(system::WavesSystem)

Stop the audio system.

# Arguments
- `system::WavesSystem`: The audio system to stop.
"""
function stop!(system::WavesSystem)
    system.is_running = false
    if system.audio_thread !== nothing
        wait(system.audio_thread)
        system.audio_thread = nothing
    end
    @info "Système audio arrêté"
end

"""
    close!(system::WavesSystem)

Close the audio system and release resources.

# Arguments
- `system::WavesSystem`: The audio system to close.
"""
function close!(system::WavesSystem)
    stop!(system)
    close(system.stream)
    @info "Système audio fermé"
end


end # module