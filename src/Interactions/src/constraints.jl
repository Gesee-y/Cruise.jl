######################################################################################################################
################################################### CONSTRAINTS ######################################################
######################################################################################################################

export AbstractLink
export LinkCable, LinkCable2D, LinkCable3D, RodCable, RodCable2D, RodCable3D

####################################################### CORE #########################################################

"""
    abstract type AbstractLink <: AbstractConstraint

Supertype for constraint type representing a link between particles.
"""
abstract type AbstractLink <: AbstractConstraint end

"""
    mutable struct LinkCable <: AbstractLink
		particles::NTuple{2,Particle}
		max_length::Float32
		restitution::Float32

A cable between the given `particles`. They can't go away more than `max_length` from each other.
`restitution` is the bounciness of the cable. 
"""
mutable struct LinkCable{N} <: AbstractLink
	particles::NTuple{2,Particle{N}}
	max_length::Float32
	restitution::Float32
end
const LinkCable2D = LinkCable{2}
const LinkCable3D = LinkCable{3}

"""
    mutable struct RodCable <: AbstractLink
		particles::NTuple{2,Particle}
		max_length::Float32
		restitution::Float32

A solid cable between the given `particles`. They can't go away/near more than `max_length` from each other.
"""
mutable struct RodCable{N} <: AbstractLink
	particles::NTuple{2,Particle{N}}
	max_length::Float32
end
const RodCable2D = RodCable{2}
const RodCable3D = RodCable{3}


#################################################### FUNCTIONS #######################################################

function make_contact(link::LinkCable{N}) where N
	l = _current_length(l)
	l < link.max_length && return

    normal = vnormalize(link.particles[2] - link.particles[1])
	return IContact{N}(WeakRef.(link.particles), link.restitution, l - link.max_length, normal)
end

function fill_contact!(link::LinkCable{N}, c::IContact{N}) where N
	l = _current_length(l)
	l < link.max_length && return 0

    c.normal = vnormalize(link.particles[2] - link.particles[1])
    c.obj = WeakRef.(link.particles)
    c.restitution = link.restitution
    c.penetration = l - link.max_length
	
	return 1
end
function make_contact(link::RodCable{N}) where N
	l = _current_length(l)
	l == link.max_length && return

	sgn = ifelse(l > max_length, 1, -1)
    normal = vnormalize(link.particles[2] - link.particles[1]) * sgn
	return IContact{N}(WeakRef.(link.particles), 0, (l - link.max_length)*sgn, normal)
end

function fill_contact!(link::RodCable{N}, c::IContact{N}) where N
	l = _current_length(l)
	l == link.max_length && return 0
    
    sgn = ifelse(l > max_length, 1, -1)
    c.normal = vnormalize(link.particles[2] - link.particles[1]) * sgn
    c.obj = WeakRef.(link.particles)
    c.restitution = 0
    c.penetration = (l - link.max_length) * sgn
	
	return 1
end
_current_length(l::LinkCable) = vnorm(l.particles[2].position - l.particles[1].position)
_current_length(l::RodCable) = vnorm(l.particles[2].position - l.particles[1].position)