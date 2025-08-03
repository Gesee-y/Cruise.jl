#####################################################################################################################
##################################################### KEYFRAMING ####################################################
#####################################################################################################################

export AbstractKeyframe
export Keyframe
export @keyframe
export value, keytime

######################################################## CORE #######################################################

abstract type AbstractKeyframe{T} end

"""
    struct Keyframe{T}
	    time::Float64
	    value::T

This struct represent a keyframe.
A keyframe is an intant of an animation. Something like the `value` of the animation at the given `time`.
"""
struct Keyframe{T} <: AbstractKeyframe{T}
    time::Float64
    value::T
end

macro keyframe(expr)
    # pattern : t => value
    if expr isa Expr && expr.head == :call && expr.args[1] == :(=>)
        t, v = expr.args[2], expr.args[3]
        return :(Keyframe($(esc(t)), $(esc(v))))
    else
        error("Invalid syntax. Use `@keyframe t => value`.")
    end
end

###################################################### FUNCTIONS #####################################################

"""
    value(k::Keyframe)

Return the value of a given keyframe
"""
value(k::AbstractKeyframe) = error("Function `value` isn't implemented for keyframe of type $(typeof(k))")
value(k::Keyframe) = getfield(k, :value)

"""
    keytime(k::Keyframe)

Return the time of a key frame.
"""
keytime(k::AbstractKeyframe) = error("Function `keytime` isn't implemented for keyframe of type $(typeof(k))")
keytime(k::Keyframe) = getfield(k, :time)