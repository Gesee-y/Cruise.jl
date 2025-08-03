######################################################################################################################
##################################################### TRANSITIONS ####################################################
######################################################################################################################

export AbstractTransition, AbstractEase, NonCurvedTransition, CurvedTransition
export LinearTransition, ExponentialTransition, StepTransition, CubicCurveTransition
export BezierTransition, HermiteTransition, CatmullRomTransition
export QuadraticTransition, CubicTransition
export ElasticTransition, BounceTransition, BackTransition, SmoothstepN, Smoothstep, Smootherstep, Quinticstep,
export SpringTransition,

export EaseIn, EaseOut, EaseInOut, ElasticEase, BounceEase, BackEase, SineEase, CircEase, ExponentialEase
export QuinticEase

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

"""
    ElasticTransition{T} <: CurvedTransition
Elastic easing with configurable amplitude `amp` (≥ 0) and period `period` (> 0).
"""
struct ElasticTransition{T} <: CurvedTransition
    amp::T
    period::T
end
# constructeur par défaut
ElasticTransition() = ElasticTransition(0.3, 0.3)

"""
    BounceTransition <: CurvedTransition
Classic bounce effect (configurable via `bounces`, default = 4).
"""
struct BounceTransition{T} <: CurvedTransition
    bounces::T
end
BounceTransition() = BounceTransition(4)

"""
    BackTransition{T} <: CurvedTransition
Goes slightly « back » then forward.  `s` controls overshoot.
"""
struct BackTransition{T} <: CurvedTransition
    s::T
end
BackTransition() = BackTransition(1.70158)

"""
    SmoothstepN{N} <: CurvedTransition
Generic smoothstep of degree N (2,3,4,5…).
"""
struct SmoothstepN{N} <: CurvedTransition end
const Smoothstep  = SmoothstepN{2}
const Smootherstep = SmoothstepN{3}
const Quinticstep  = SmoothstepN{5}

"""
    SpringTransition{T} <: CurvedTransition
Damped spring motion. `damping` ∈ ]0,1], `freq` > 0.
"""
struct SpringTransition{T} <: CurvedTransition
    damping::T
    freq::T
end
SpringTransition() = SpringTransition(0.25, 6.28)

struct EaseIn{N} <: AbstractEase{N} end
struct EaseOut{N} <: AbstractEase{N} end
struct EaseInOut{N} <: AbstractEase{N} end

struct ElasticEase{T} <: AbstractEase{0}
    amp::T
    period::T
end
ElasticEase() = ElasticEase(1, 0.3)

struct BounceEase <: AbstractEase{0} end

struct BackEase{T} <: AbstractEase{0}
    s::T
end
BackEase() = BackEase(1.70158)

struct SineEase <: AbstractEase{0} end

struct CircEase <: AbstractEase{0} end

struct ExponentialEase{T} <: AbstractEase{0}
    base::T
end
ExponentialEase() = ExponentialEase(2)

struct QuinticEase <: AbstractEase{0} end

###################################################### FUNCTIONS #####################################################

(trans::LinearTransition)(a,b,t) = lerp(a,b,clamp(t, zero(t), one(t)))
(trans::StepTransition)(a,b,t) = trans.time < t ? a : b
(trans::SmoothstepTransition)(a,b,t) = trans.time < t ? a : trans.trans(a,b,(t - trans.time)/(1 - trans.time))
(trans::CubicCurveTransition)(a,b,t) = cubic(a,b,trans.tan_out, trans.tan_in, clamp(t, zero(t), one(t)))
(trans::BezierTransition)(a,b,t) = bezier(a, trans.cp1, trans.cp2, b, clamp(t, zero(t), one(t)))
(trans::HermiteTransition)(a,b,t) = cubic(a,b,trans.tan_in, trans.tan_out, clamp(t, zero(t), one(t)))
(trans::CatmullRomTransition)(a,b,c,d,t) = catmull_rom(a,b,c,d,clamp(t, zero(t), one(t)))

function (tr::ElasticTransition)(a, b, t)
    t = clamp(t, zero(t), one(t))
    t ≈ zero(t) && return a
    t ≈ one(t)  && return b
    c = b - a
    s = tr.period / (oftype(t, 2)*oftype(t, π)) * asin(c / (tr.amp + c))
    -(tr.amp + c) * expm1(-10t) * sin((t - s)*(oftype(t, 2)*oftype(t, π))/tr.period) + c + a
end

function (tr::BounceTransition)(a, b, t)
    t = clamp(t, zero(t), one(t))
    t ≈ one(t) && return b
    c = b - a
    n = tr.bounces
    k = one(t) - t
    # formule classique
    d = k^(2n) * (sin(π * k * n) / sin(π/n)) * c
    b - d
end

function (tr::BackTransition)(a, b, t)
    t = clamp(t, zero(t), one(t))
    c = b - a
    s = tr.s
    t2 = t * t
    c * t * t2 * ((s + one(t)) * t - s) + a
end

function (tr::SmoothstepN{N})(a, b, t) where N
    t = clamp(t, zero(t), one(t))
    tN = t^N
    c = b - a
    c * (tN * (tN * (oftype(t, 6)*tN - oftype(t, 15)*tN) + oftype(t, 10)*tN)) + a
end

function (tr::SpringTransition)(a, b, t)
    t = clamp(t, zero(t), one(t))
    c = b - a
    ω = tr.freq * oftype(t, 2π)
    d = tr.damping
    (one(t) - exp(-d * ω * t) * cos(ω * t * sqrt(one(t) - d^2))) * c + a
end

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

function (e::ElasticEase)(t)
    t = clamp(t, zero(t), one(t))
    t ≈ zero(t) && return zero(t)
    t ≈ one(t)  && return one(t)
    s = e.period / (oftype(t, 2)*oftype(t, π)) * asin(one(t)/(e.amp + one(t)))
    -(e.amp + one(t)) * expm1(-10t) * sin((t - s)*(oftype(t, 2)*oftype(t, π))/e.period) + one(t)
end

function (::BounceEase)(t)
    t = clamp(t, zero(t), one(t))
    t ≈ one(t) && return one(t)
    k = one(t) - t
    one(t) - k^(2*4) * (sin(π * k * 4) / sin(π/4))
end

function (e::BackEase)(t)
    t = clamp(t, zero(t), one(t))
    s = e.s
    t * t * ((s + one(t)) * t - s)
end

(::SineEase)(t) = one(t) - cos(t * oftype(t, π)/2)
(::CircEase)(t) = one(t) - sqrt(one(t) - t*t)
(::QuinticEase)(t) = t < 0.5 ? 16t^5 : 1 - 16(1-t)^5

function (e::ExponentialEase)(t)
    t = clamp(t, zero(t), one(t))
    t ≈ zero(t) && return zero(t)
    t ≈ one(t)  && return one(t)
    (e.base^(t) - one(t)) / (e.base - one(t))
end


(ease::AbstractEase)(a,b,t) = lerp(a,b, ease(t))