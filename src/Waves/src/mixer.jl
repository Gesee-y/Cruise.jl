

function process_fade!(target::Union{AbstractAudioSource, AudioGroup, AudioBus})
    if target.fade_counter < target.fade_samples
        progress = target.fade_counter / target.fade_samples
        t = 0.5 * (1 - cos(π * progress))  # Cosine interpolation
        target.volume = target.volume * (1 - t) + target.target_volume * t
        target.fade_counter += 1
        if target.fade_counter >= target.fade_samples
            target.volume = target.target_volume
            if target isa AbstractAudioSource && target.target_volume == 0.0
                lock(target.lock)
                try
                    target.state = target.state == PAUSED ? PAUSED : STOPPED
                    target.position = target.start_offset
                finally
                    unlock(target.lock)
                end
            end
        end
    end
end

function process_modulable_effect!(effect::ModulableEffect)
    if effect.interp_counter < effect.interp_samples
        progress = effect.interp_counter / effect.interp_samples
        t = 0.5 * (1 - cos(π * progress))  # Cosine interpolation
        for (key, target_val) in effect.target_params
            effect.params[key] = effect.params[key] * (1 - t) + target_val * t
        end
        effect.interp_counter += 1
    end
end

function mix_sources!(system::WavesSystem)
    N = system.buffer_size
    output = system.pre_allocated_buffers["master"]
    bus_buffer = system.pre_allocated_buffers["bus_temp"]
    group_buffer = system.pre_allocated_buffers["group_temp"]
    aux_buffer = system.pre_allocated_buffers["aux_temp"]

    fill!(output, 0.0f0)

    has_solo_bus = any(bus -> bus.solo, system.buses)

    # Process main buses
    @inbounds for bus in system.buses
        if bus.mute || (has_solo_bus && !bus.solo)
            continue
        end

        fill!(bus_buffer, 0.0f0)
        process_fade!(bus)

        has_solo_group = any(group -> group.solo, bus.groups)

        for group in bus.groups
            if group.mute || (has_solo_group && !group.solo)
                continue
            end

            fill!(group_buffer, 0.0f0)
            process_fade!(group)

            for src in group.sources
                if src.state != PLAYING
                    continue
                end

                process_fade!(src)
                channels = src isa AudioSource ? size(src.data, 1) : src.channels
                total_samples = src isa AudioSource ? size(src.data, 2) : src.total_samples

                for i in 1:N
                    if src.position >= src.end_offset
                        if src.loop
                            src.position = src.start_offset
                        else
                            lock(src.lock)
                            try
                                src.state = STOPPED
                            finally
                                unlock(src.lock)
                            end
                            break
                        end
                    end

                    for ch in 1:min(channels, 2)
                        sample = src isa AudioSource ?
                            interpolate_sample(src.data, src.position, ch) :
                            get_streaming_sample(src, src.position, ch)
                        group_buffer[ch, i] += sample * src.volume
                    end

                    src.position += src.speed
                end
            end

            for effect in group.effects
                if effect isa ModulableEffect
                    process_modulable_effect!(effect)
                end
                for ch in 1:2
                    @views group_buffer[ch, :] = effect(group_buffer[ch, :])
                end
            end

            @views bus_buffer .+= group_buffer .* group.volume
        end

        for effect in bus.effects
            if effect isa ModulableEffect
                process_modulable_effect!(effect)
            end
            for ch in 1:2
                @views bus_buffer[ch, :] = effect(bus_buffer[ch, :])
            end
        end

        for (aux_id, send_level) in bus.sends
            if haskey(system.auxiliary_buses, aux_id)
                aux_bus = system.auxiliary_buses[aux_id]
                if !aux_bus.mute
                    fill!(aux_buffer, 0.0f0)
                    aux_buffer .+= bus_buffer .* send_level
                    for effect in aux_bus.effects
                        if effect isa ModulableEffect
                            process_modulable_effect!(effect)
                        end
                        for ch in 1:2
                            @views aux_buffer[ch, :] = effect(aux_buffer[ch, :])
                        end
                    end
                    output .+= aux_buffer .* aux_bus.volume
                end
            end
        end

        @views output .+= bus_buffer .* bus.volume
    end

    output .*= system.master_volume

    if system.limiter_enabled
        apply_limiter!(output, system.limiter_threshold)
    end

    update_metrics!(system.metrics, output)

    try
        write(system.stream, permutedims(output))
    catch e
        system.metrics.underrun_count += 1
        @warn "Underrun audio détecté"
    end
end