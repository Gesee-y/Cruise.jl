######################################################################################################################
##################################################### TRANSITIONS ####################################################
######################################################################################################################

export AbstractTransition, AbstractEase, NonCurvedTransition, CurvedTransition
export LinearTransition, ExponentialTransition, StepTransition, CubicCurveTransition
export BezierTransition, HermiteTransition, CatmullRomTransition
export QuadraticTransition, CubicTransition
export EaseIn, EaseOut, EaseInOut

######################################################## CORE ########################################################

"""
    abstract type AbstractTransition

Supertype for all transition type.
If you create your own transition, it should be a subtype of this and should be a functor callable with
`(trans::YourTransitionType)(a,b,t) = # Your transition code`
"""
abstract type AbstractTransition end

"""
    abstract type AbstractEase{N} <: AbstractTransition

Supertype of all ease type.
If you create you own ease, it should be a subtype of this and should be a functor matchin transition functors and
`(ease::YourEaseType)(t) = # Your easing code`
"""
abstract type AbstractEase{N} <: AbstractTransition end

"""
    abstract type NonCurvedTransition <: AbstractTransition

Supertype of all transition that doesn't use parameter to describe a curve.
"""
abstract type NonCurvedTransition <: AbstractTransition end

"""
    abstract type CurvedTransition <: AbstractTransition

Supertype of all transition requiring extra configurations for their curves.
"""
abstract type CurvedTransition <: AbstractTransition end

"""
    struct LinearTransition <: NonCurvedTransition

A simple linear transition. Equivalent to a linear interpolation.
"""
struct LinearTransition <: NonCurvedTransition end

"""
    struct ExponentialTransition{N} <: NonCurvedTransition end

A polynomial transition. `N` is the degree of the polynomial.
"""
struct ExponentialTransition{N} <: NonCurvedTransition end

"""
    struct StepTransition <: CurvedTransition
		time::Float32

A step transition, return the starting value if the time is less than `time`, else it return the end time.
"""
struct StepTransition <: CurvedTransition
	time::Float32
end

"""
    struct SmoothstepTransition{T} <: CurvedTransition
		time::Float32
		trans::T

A smoothstep transition, return the starting value if the time is less than `time`, else it does a transition
from the starting point to the endpoint with `trans`.
"""
struct SmoothstepTransition{T} <: CurvedTransition
	time::Float32
	trans::T
end

struct CubicCurveTransition{T} <: CurvedTransition
    tan_in::T
    tan_out::T
end
struct BezierTransition{T} <: CurvedTransition
    cp1::T
    cp2::T
end
struct HermiteTransition{T} <: CurvedTransition
    tan_in::T
    tan_out::T
end
struct CatmullRomTransition <: CurvedTransition end

const QuadraticTransition = ExponentialTransition{2}
const CubicTransition = ExponentialTransition{3}

struct EaseIn{N} <: AbstractEase{N} end
struct EaseOut{N} <: AbstractEase{N} end
struct EaseInOut{N} <: AbstractEase{N} end

###################################################### FUNCTIONS #####################################################

(trans::LinearTransition)(a,b,t) = lerp(a,b,clamp(t, zero(t), one(t)))
(trans::StepTransition)(a,b,t) = trans.time < t ? a : b
(trans::SmoothstepTransition)(a,b,t) = trans.time < t ? a : trans.trans(a,b,(t - trans.time)/(1 - trans.time))
(trans::CubicCurveTransition)(a,b,t) = cubic(a,b,trans.tan_out, trans.tan_in, clamp(t, zero(t), one(t)))
(trans::BezierTransition)(a,b,t) = bezier(a, trans.cp1, trans.cp2, b, clamp(t, zero(t), one(t)))
(trans::HermiteTransition)(a,b,t) = cubic(a,b,trans.tan_in, trans.tan_out, clamp(t, zero(t), one(t)))
(trans::CatmullRomTransition)(a,b,c,d,t) = catmull_rom(a,b,c,d,clamp(t, zero(t), one(t)))

(::AbstractEase{1})(t) = t
(::EaseIn{n})(t) where n <: Integer = (1 << (n-1))*t^n
(::EaseIn{n})(t) where n <: AbstractFloat = (2^(n-1))*t^n
(::EaseIn{2})(t) = 2t*t
(::EaseIn{3})(t) = 4t*t*t
(::EaseOut{n})(t) where n <: Integer = 1 - (1 << (n-1))*(1-t)^n
(::EaseOut{n})(t) where n <: AbstractFloat = 1 - 2^(n-1)*(1-t)^n
(::EaseOut{2})(t) = 1 - 2(1-t)*(1-t)
(::EaseOut{3})(t) = 1 - 4(1-t)*(1-t)*(1-t)
(::EaseInOut{n})(t) where n <: Integer = t <= 0.5 ? (1 << (n-1))*t^n : 1 - (1 << (n-1))*(1-t)^n
(::EaseInOut{n})(t) where n <: AbstractFloat = t <= 0.5 ? (2^(n-1))*t^n : 1 - 2^(n-1)*(1-t)^n
(::EaseInOut{2})(t) = t <= 0.5 ? 2t*t : 1 - 2(1-t)*(1-t)
(::EaseInOut{3})(t) = t <= 0.5 ? 4t*t*t : 1 - 4(1-t)*(1-t)*(1-t)

(ease::AbstractEase)(a,b,t) = lerp(a,b, ease(t))