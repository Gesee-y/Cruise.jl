#########################################################################################################################
######################################################## CORE ###########################################################
#########################################################################################################################

export CRPluginNode, CRPlugin, CRPluginStatus

struct StopExec end

@enum CRPluginStatus begin
    PLUGIN_OFF
    PLUGIN_DEPRECATED
    PLUGIN_OK
    PLUGIN_ERR
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

    CRPluginNode(obj)

Returns a new CRPlugin from the given obj
"""
mutable struct CRPluginNode{T,S}
    id::Int
    obj::T
    deps::Dict{DataType, WeakRef}
    children::Vector{CRPluginNode}
    status::CRSubject{CRPluginStatus}
    result::S
    lasterr::Exception

    ## Constructors

    CRPluginNode(obj::T) where T = new{T,Any}(-1, obj, Dict{DataType, WeakRef}(), CRPluginNode[], CRSubject(PLUGIN_OFF))
    CRPluginNode{S}(obj::T) where {T, S<:Any} = new{T,S}(-1, obj, Dict{DataType, WeakRef}(), CRPluginNode[], CRSubject(PLUGIN_OFF))
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
    idtonode::Dict{Int, CRPluginNode}
    graph::SimpleDiGraph{Int}
    free_ids::Vector{Int}
    current_max::Int
    sort_cache::Vector{Int}

    ## Constructors

    CRPlugin() = begin
        G = SimpleDiGraph{Int}()
        new(Dict{Int, CRPlugin}(), G, Int[], 0, Int[])
    end
end
