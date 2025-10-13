#########################################################################################################################
######################################################## CORE ###########################################################
#########################################################################################################################

struct StopExec end

@enum CRPluginStatus begin
    OFF
    DEPRECATED
    OK
    ERR
end

"""
    abstract type AbstractPlugin

Supertype of any kind of system graph.
"""
abstract type AbstractPlugin end

"""
    mutable struct CRPlugin{T}
        obj::T

Represent a node in the system graph.
'obj' represent a system that support the functions awake!, run! and shutdown!.

## Constructor

    CRPlugin(obj)

Returns a new CRPlugin from the given obj
"""
mutable struct CRPlugin{T,S}
    id::Int
    obj::T
    deps::Dict{DataType, WeakRef}
    children::Vector{CRPlugin}
    status::CRSubject{CRPluginStatus}
    result::S

    ## Constructors

    CRPlugin(obj::T) where T = new{T,Any}(-1, obj, Dict{DataType, WeakRef}(), CRPlugin[], CRSubject(CRPluginStatus.OFF))
    CRPlugin{S}(obj::T) where {T, S<:Any} = new{T,S}(-1, obj, Dict{DataType, WeakRef}(), CRPlugin[], CRSubject(CRPluginStatus.OFF))
end

"""
    mutable struct CRPlugin <: AbstractPlugin
	    idtonode::Dict{Int, CRPlugin}
	    graph::DiGraph
	    free_ids::Vector{Int}
	    current_max::Int

Represent the systems graph. It represent the depencies and execution order of the systems.
- idtonode map an id to a given CRPlugin
- graph is a Directed graph representing the dependencies and execution order between the systems
- free_ids is the set of available id for new systems to take
- current_max is the value of the node with the highest id

## Constructor

    CRPlugin()

This will return a new empty system graph.
"""
mutable struct CRPlugin <: AbstractPlugin
    idtonode::Dict{Int, CRPlugin}
    graph::DiGraph
    free_ids::Vector{Int}
    current_max::Int
    sort_cache::Vector{Int}

    ## Constructors

    CRPlugin() = new(Dict{Int, CRPlugin}(), DiGraph(), Int[], 0, Int[])
end
