######################################################################################################################
###################################################### FORCES ########################################################
######################################################################################################################

export GravityForce, GravityForce2D, GravityForce3D, DragForce
export AbstractSpringForce, SpringForce, SpringForce2D, SpringForce3D, AnchoredSpringForce
export AnchoredSpringForce2D, AnchoredSpringForce3D, BungeeSpringForce, BungeeSpringForce2D, BungeeSpringForce3D
export AnchoredBungeeSpringForce, AnchoredBungeeSpringForce2D, AnchoredBungeeSpringForce3D
export BuoyancySpringForce, FakeSpringForce, FakeSpringForce2D, FakeSpringForce3D

####################################################### CORE #########################################################

abstract type AbstractSpringForce <: AbstractForce end

"""
    mutable struct GravityForce <: AbstractForce
		gravity::Vec3f

Represent the force applied by the gravity.
`gravity` if the vector representing the gravity.
"""
mutable struct GravityForce{N} <: AbstractForce
	gravity::SVector{Float32, N}
end
const GravityForce2D = GravityForce{2}
const GravityForce3D = GravityForce{3}

"""
    mutable struct DragForce <: AbstractForce
		k1::Float32
		k2::Float32

A force representing a drag.
- `k1`: The coefficient of the velocity
- `k2`: The coefficient of the velocity squared.
"""
mutable struct DragForce <: AbstractForce
	k1::Float32
	k2::Float32
end

"""
    mutable struct SpringForce{N} <: AbstractSpringForce
		other::Particle{N}
		rest_length::Float32
		spring_constant::Float32

Represent a `N` dimensional spring force lying the particule `other`.
- `rest_length`: is the base length of the spring.
- `spring_constant`: is the stiffness of the spring.
"""
mutable struct SpringForce{N} <: AbstractSpringForce
	other::Union{Particle{N}, RigidBody{N}}
	rest_length::Float32
	spring_constant::Float32
	connections::NTuple{2, SVector{Float32,N}}
end
const SpringForce2D = SpringForce{2}
const SpringForce3D = SpringForce{3}

"""
    mutable struct AnchoredSpringForce{N} <: AbstractSpringForce
		anchor::SVector{Float32,N}
		rest_length::Float32
		spring_constant::Float32

Represent a `N` dimensional spring force anchored at the fixed point `anchor`.
- `rest_length`: is the base length of the spring.
- `spring_constant`: is the stiffness of the spring.
"""
mutable struct AnchoredSpringForce{N} <: AbstractSpringForce
	anchor::SVector{Float32,N}
	rest_length::Float32
	spring_constant::Float32
end
const AnchoredSpringForce2D = AnchoredSpringForce{2}
const AnchoredSpringForce3D = AnchoredSpringForce{3}

"""
    mutable struct BungeeSpringForce{N} <: AbstractSpringForce
		other::Particle{N}
		rest_length::Float32
		spring_constant::Float32

Represent a `N` dimensional spring force lying the particule `other`.
It only apply when extended.
- `rest_length`: is the base length of the spring.
- `spring_constant`: is the stiffness of the spring.
"""
mutable struct BungeeSpringForce{N} <: AbstractSpringForce
	other::Particle{N}
	rest_length::Float32
	spring_constant::Float32
end
const BungeeSpringForce2D = BungeeSpringForce{2}
const BungeeSpringForce3D = BungeeSpringForce{3}

"""
    mutable struct AnchoredBungeeSpringForce{N} <: AbstractSpringForce
		anchor::SVector{Float32,N}
		rest_length::Float32
		spring_constant::Float32

Represent a `N` dimensional spring force anchored at the fixed point `anchor`.
This only apply when extended.
- `rest_length`: is the base length of the spring.
- `spring_constant`: is the stiffness of the spring.
"""
mutable struct AnchoredBungeeSpringForce{N} <: AbstractSpringForce
	anchor::SVector{Float32,N}
	rest_length::Float32
	spring_constant::Float32
end
const AnchoredBungeeSpringForce2D = AnchoredBungeeSpringForce{2}
const AnchoredBungeeSpringForce3D = AnchoredBungeeSpringForce{3}

"""
    mutable struct BuoyancySpringForce <: AbstractSpringForce
		depth::Float32
		volume::Float32
		liquidHeight::Float32
		density::Float32 = 1000.0f0

Represent a buoyance force in a spring like way.
- `depth` is the maximum depth before the particule is considered entirely immerged.
- `volume` is the volume of the object.
- `liquidHeigth` is the height of the liquid in the world.
- `density` is the density of the liquid.
"""
Base.@kwdef mutable struct BuoyancySpringForce <: AbstractSpringForce
	depth::Float32
	volume::Float32
	liquidHeight::Float32
	density::Float32 = 1000.0f0
end

"""
    mutable struct FakeSpringForce{N} <: AbstractSpringForce
		anchor::SVector{Float32, N}
		spring_constant::Float32
		damping::Float32

Roughly simulate a stiff spring. This may not be accurate.
- `anchor` is the position of the spring.
- `spring_constant` is the stiffness of the spring.
- `damping` is the drag coefficient of the spring.
"""
mutable struct FakeSpringForce{N} <: AbstractSpringForce
	anchor::SVector{Float32, N}
	spring_constant::Float32
	damping::Float32
end
const FakeSpringForce2D = FakeSpringForce{2}
const FakeSpringForce3D = FakeSpringForce{3}

#################################################### FUNCTIONS #######################################################

"""
    update_force(p::Particle{N}, f::GravityForce{N}, Δ::Float32) where N

Apply the gravity `f` to the particle `p` during the time interval `Δ`.
If `f` has an infinite mass (`f.inverse_mass == 0`). Then nothing will happen.

    update_force(p::Particle{N}, f::DragForce, Δ::Float32) where N

Apply the drag force `f` to the particule `p` in the time interval `Δ`.

    update_force(p::Particle{N}, f::SpringForce{N}, Δ::Float32) where N

Apply a classic `N` dimensional spring force to a particle `p`.

    update_force(p::Particle{N}, f::AnchoredSpringForce{N}, Δ::Float32) where N

Apply a `N` dimensional spring force to the particle `p`.
This spring force is anchored to a specific position.

    update_force(p::Particle{N}, f::BungeeSpringForce{N}, Δ::Float32) where N

Apply a `N` dimensional spring force to the particle `p` from another particule.
This force only apply when the spring is extended.
    
    update_force(p::Particle{N}, f::AnchoredBungeeSpringForce{N}, Δ::Float32) where N

Apply a `N` dimensional spring force to the particule `p` anchored at a fixed position.
This force only apply when the spring is extended.

    update_force(p::Particle{N}, f::BuoyanceSpringForce, Δ::Float32) where N

Apply a `N` dimensional buoyance force simulated with a spring to the particule `p`.

    update_force(p::Particle{N}, f::FakeSpringForce{N}, Δ::Float32) where N

Apply a `N` dimensional fake stiff spring force to the particule `p` at the time interval `Δ`. 
"""
function update_force(p::AbstractBody{N}, f::GravityForce{N}, Δ::Float32) where N
    m = getmass(p)
	!isfinite(m) && return 
	add_force(p, f.gravity*m)
end
function update_force(p::AbstractBody{N}, f::DragForce, Δ::Float32) where N
	k1, k2 = f.k1, f.k2
	force, vel_norm = vnormalize_and_norm(p.velocity)
	dragCoef = k1*vel_norm + k2*vel_norm*vel_norm
    
    force = vnormalize(force)
    force *= -dragCoef

    add_force(p, force)
end
function update_force(p::Particle{N}, f::SpringForce{N}, Δ::Float32) where N
	force, magnitude = vnormalize_and_norm(p.position - f.other.position)
	magnitude = f.spring_constant * abs(magnitude - f.rest_length)

    force *= -magnitude
    add_force(p, force)
end
function update_force(p::RigidBody{N}, f::SpringForce{N}, Δ::Float32) where N
	lws, ows = get_point_in_global_space(p.matrix,f.connections[1]), 
               get_point_in_global_space(other.matrix,f.connections[2])
    
	force, magnitude = vnormalize_and_norm(lws - ows)
	magnitude = f.spring_constant * abs(magnitude - f.rest_length)

    force *= -magnitude
    add_force(p, force, lws;glob=true)
end
function update_force(p::Particle{N}, f::AnchoredSpringForce{N}, Δ::Float32) where N
	force, magnitude = vnormalize_and_norm(p.position - f.anchor)
	magnitude = f.spring_constant * abs(magnitude - f.rest_length)

    force *= -magnitude
    add_force(p, force)
end
function update_force(p::Particle{N}, f::BungeeSpringForce{N}, Δ::Float32) where N
	force, magnitude = vnormalize_and_norm(p.position - f.other.position)
	magnitude < f.rest_length && return
	magnitude = f.spring_constant * abs(magnitude - f.rest_length)

    force *= -magnitude
    add_force(p, force)
end
function update_force(p::Particle{N}, f::AnchoredBungeeSpringForce{N}, Δ::Float32) where N
	force, magnitude = vnormalize_and_norm(p.position - f.anchor)
	magnitude < f.rest_length && return
	magnitude = f.spring_constant * abs(magnitude - f.rest_length)

    force *= -magnitude
    add_force(p, force)
end

function update_force(p::Particle{N}, f::BuoyancySpringForce, Δ::Float32) where N
	depth = p.position.y
	(depth >= f.liquidHeight+f.depth) && return

	force = SVector{Float32, N}(0)

	if (depth < f.liquidHeight-f.depth)
		force.y = f.density*f.volume
		add_force(p, force)
		return
	end

	force.y = f.density*f.volume * (depth - f.liquidHeight-f.depth)/(2f.depth)
	add_force(p, force)
end
function update_force(p::Particle{N}, f::FakeSpringForce{N}, Δ::Float32) where N
	m = getmass(p)
	!isfinite(m) && return

    damping = f.damping
	position = p.position - f.anchor
	γ = 0.5f0 * √(4f.spring_constant - damping*damping)
	iszero(γ) && return
	c = position*(damping/(2γ)) + p.velocity*1/γ

	target = position*cos(γ*Δ) + c*sin(γ*Δ)
	target *= exp(-0.5f0*Δ*damping)

	accel = (target - position)*(1/(Δ*Δ)) - p.velocity*Δ
	add_force(p,accel*m)
end
