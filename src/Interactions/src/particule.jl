######################################################################################################################
################################################## PARTICULE SYSTEM ##################################################
######################################################################################################################

export GRAVITY2D, GRAVITY3D
export Particle, Particle2D
export integrate!, setmass!, setinvmass!

######################################################## CORE ########################################################

const GRAVITY2D = Vec2{IReal}(0, 9.8)
const GRAVITY3D = Vec3{IReal}(0, 9.8, 0)

"""
    mutable struct Particle{T} <: AbstractBody
    	inverse_mass::Float32
		position::Vec3{T}
		velocity::Vec3{T}
	    acceleration::Vec3{T}
	    forceAccum::Vec3{Float32}
	    damping::Float32

This represent a point mass.
- `inverse_mass`: inverse of the mass of the particule, useful to avoid checking zero division errors.
- `position`: The instant position of the particle.
- `velocity`: the instant linear velocity of the particle in the world space.
- `acceleration`: The instant acceleration of the particle. Use this to set some constant accelerations
    such as gravity.
- `forceAccum`: Represent an accumulation of all the forces exerced on the particule. 
- `damping`: amount of damping applied to the linear movement. Damping is required to remove energy added
    through numerical instability of the integrator.
"""
mutable struct Particle{N} <: AbstractBody{N}
	inverse_mass::IReal
	position::SVector{IReal,N}
	velocity::SVector{IReal,N}
    acceleration::SVector{IReal,N}
    forceAccum::SVector{IReal,N}
    damping::IReal
end

const Particle2D = Particle{2}

#################################################### FUNCTIONS #######################################################

"""
    integrate!(p::Particle, Δ::IReal)

Update the internal data of `p` but doing integrations.
"""
function integrate!(p::Particle, Δ::IReal)
	position = p.position
	velocity = p.velocity
	acceleration = p.acceleration
	forceAccum = p.forceAccum
	inverse_mass = p.inverse_mass
	add_scaled(position, velocity,Δ)
	add_scaled(acceleration, forceAccum, inverse_mass)
	add_scaled(velocity, acceleration, Δ)
	velocity *= p.damping ^ Δ

	clear_accumulate_force(p)
end

add_force(p::Particle{N}, f::SVector{<:IReal, N}) where N = (p.forceAccum += f)

"""
    getmass(p::Particle)

Return the mass of the particle `p`
"""
getmass(p::Particle) = 1/p.inverse_mass
getmass(n) = 0.0f0

"""
    getinvmass(p::Particle)

Return the inverse mass of the particle. It's faster than using `1/getmass(p)`.
"""
getinvmass(p::Particle) = p.inverse_mass
getinvmass(n) = 0.0f0

"""
    setmass!(p::Particle, m::IReal)

Use this to set the mass of the particle `p`. If you directly want to set the inverse mass, use `setinvmass`.
"""
setmass!(p::Particle, m::IReal) = setfield!(p.inverse_mass, 1/m)

"""
    setinvmass!(p::Particle, invm::IReal)

Set the inverse mass of the particle `p`. Useful to make infinite mass object.
"""
setinvmass!(p::Particle, invm::IReal) = setfield(p.inverse_mass, invm)

clear_accumulate_force(p::Particle) = (p.forceAccum .= zero(IReal))