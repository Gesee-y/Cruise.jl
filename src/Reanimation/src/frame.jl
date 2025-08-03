#####################################################################################################################
################################################### ANIMATION FRAMES ################################################
#####################################################################################################################

export AbstractFrame
export KFAnimationFrame
export at, get_animation_array, duration

######################################################### CORE ########################################################

abstract type AbstractFrame

mutable struct KFAnimationFrame{T} <: AbstractFrame
	k1::Keyframe{T}
	k2::Keyframe{T}
	transition::AbstractTransition
	loop::Int

	## Constructors

	function KFAnimationFrame(k1::Keyframe{T}, k2::Keyframe{T}, tr::AbstractTransition=LinearTransition(), loop=1) where T
		
		keytime(k1) < keytime(k2) && error("Keyframe 1 must be earlier than keyframe 2")
		loop < 0 && error("Can't take less than zero loops.")

		return new{T}(k1,k2,tr,loop)
	end
end

#################################################### FUNCTIONS #######################################################

duration(frame::KFAnimationFrame) = keytime(frame.k2) - keytime(frame.k1)
function at(frame::KFAnimationFrame{T}, t::Real)::T where T
    t_total = duration(frame)
    t_loop = t_total * frame.loop
    t_clamped = clamp(t, 0.0, t_loop)
    t_local = mod(t_clamped, t_total)
    t_norm = t_local / t_total
    frame.transition(value(frame.k1), value(frame.k2), t_norm)
end

function get_animation_array(frame::KFAnimationFrame{T}, len::Integer,
                             start::Real = 0.0,
                             current_loop::Integer = 1) where T
    len ≤ 0 && return T[]

    remaining_loops = max(frame.loop - current_loop + 1, 0)
    frames = Vector{T}(undef, len * remaining_loops)

    idx = 1
    for _ in 1:remaining_loops
        for t in range(0.0, 1.0, length=len)
            frames[idx] = at(frame, start + t * duration(frame))
            idx += 1
        end
    end
    return frames
end
