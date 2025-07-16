######################################################################################################################
############################################## INTERACTION PHYSIC ENGINE #############################################
######################################################################################################################

module Interactions

using ..MathLib
using ..Arceus

const IReal = Float32

export AbstractBody

"""
    abstract type AbstractBody{N}

Supertype for every type of body.
"""
abstract type AbstractBody{N} end

abstract type RigidBody{N} end

include("particule.jl")
include("interfaces.jl")
include("forces.jl")
include("contacts.jl")
include("constraints.jl")
include("rigidbody.jl")
include("grid.jl")
include("world.jl")

end # module