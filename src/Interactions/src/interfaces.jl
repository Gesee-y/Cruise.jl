######################################################################################################################
#################################################### INTERFACES ######################################################
######################################################################################################################

export AbstractForce, AbstractConstraint
export ForceRegistry
export add_pair, remove_pair, update_force, update_forces, make_contact, fill_contact!

####################################################### CORE #########################################################

"""
    abstract type AbstractForce

Supertype for every force type. Once you create a new force type, just overload the interface and you are good.
"""
abstract type AbstractForce end

"""
    abstract type AbstractConstraint

Supertype of every constraint type. Once you create a new constraint type, just overload the interface and you are good
"""
abstract type AbstractConstraint end

"""
    mutable struct ForceRegistry
		registry::Vector{Pair{Particle, AbstractForce}}
		dt::Float32

Record of particles and the force they subscribed for.
`dt` is the elapsed time between 2 frames.
"""
mutable struct ForceRegistry
	registry::Vector{Pair{Particle, AbstractForce}}
	dt::Float32
end

#################################################### FUNCTIONS #######################################################

"""
    add_pair(fr::ForceRegistry, p::Particle, f::AbstractForce)

Register the given force `f` to apply to the given particule `p`.
"""
add_pair(fr::ForceRegistry, p::Pair{Particle, AbstractForce}) = (push!(fr.registry, p); return p)
add_pair(fr::ForceRegistry, p::Particle, f::AbstractForce) = add_pair(fr, p => f)

"""
    remove_pair(fr::ForceRegistry, p::Particle, f::AbstractForce)

Remove the register pair from the registry of `fr`.
If the pair doesn't exist, it will have no effect.    
"""
remove_pair(fr::ForceRegistry, p::Pair{Particle, AbstractForce}) = filter!(f -> f == p, fr.registry)
remove_pair(fr::ForceRegistry, p::Particle, f::AbstractForce) = remove_pair(fr, p => f)

"""
    reset(fr::ForceRegistry)

Empty `fr`'s registry.
"""
reset(fr::ForceRegistry) = empty!(fr.registry)

function update_forces(fr::ForceRegistry)
	registry = fr.registry
	Δ = fr.dt
    for i in eachindex(registry)
    	p,f = registry[i]
    	update_force(p, f, Δ)
    end
end

update_force(::Particle, ::AbstractForce, ::Float32) = nothing

make_contact(::AbstractConstraint) = nothing
fill_contact!(::AbstractConstraint, c) = nothing