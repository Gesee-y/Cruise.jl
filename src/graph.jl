#########################################################################################################################
####################################################### GRAPH ###########################################################
#########################################################################################################################

struct StopExec end

@enum SysNodeStatus begin
    OFF
    DEPRECATED
    OK
    ERR
end

"""
    abstract type AbstractSysGraph

Supertype of any kind of system graph.
"""
abstract type AbstractSysGraph end

"""
    mutable struct SysNode{T}
        obj::T

Represent a node in the system graph.
'obj' represent a system that support the functions awake!, run! and shutdown!.

## Constructor

    SysNode(obj)

Returns a new SysNode from the given obj
"""
mutable struct SysNode{T,S}
    id::Int
    obj::T
    deps::Dict{DataType, WeakRef}
    children::Vector{SysNode}
    status::SysNodeStatus
    result::S

    ## Constructors

    SysNode(obj::T) where T = new{T,Any}(-1, obj, Dict{DataType, WeakRef}(), SysNode[], SysNodeStatus.OFF)
    SysNode{S}(obj::T) where {T, S<:Any} = new{T,S}(-1, obj, Dict{DataType, WeakRef}(), SysNode[], SysNodeStatus.OFF)
end

"""
    mutable struct SysGraph <: AbstractSysGraph
	    idtonode::Dict{Int, SysNode}
	    graph::DiGraph
	    free_ids::Vector{Int}
	    current_max::Int

Represent the systems graph. It represent the depencies and execution order of the systems.
- idtonode map an id to a given SysNode
- graph is a Directed graph representing the dependencies and execution order between the systems
- free_ids is the set of available id for new systems to take
- current_max is the value of the node with the highest id

## Constructor

    SysGraph()

This will return a new empty system graph.
"""
mutable struct SysGraph <: AbstractSysGraph
    idtonode::Dict{Int, SysNode}
    graph::DiGraph
    free_ids::Vector{Int}
    current_max::Int
    sort_cache::Vector{Int}

    ## Constructors

    SysGraph() = new(Dict{Int, SysNode}(), DiGraph(), Int[], 0, Int[])
end

#######################################################################################################################
################################################# OPERATIONS ##########################################################
#######################################################################################################################

isinitialized(s::SysNode) = s.status == SysNodeStatus.OK
isuninitialized(s::SysNode) = s.status == SysNodeStatus.OFF
isdeprecated(s::SysNode) = s.status == SysNodeStatus.DEPRECATED
hasfailed(s::SysNode) = s.status == SysNodeStatus.ERR

"""
    get_available_id(sg::SysGraph)

Return an available id for a new system to take.
This will update the internal data of the SysGraph so between 2 calls it may not return the same value.
"""
function get_available_id(sg::SysGraph)
    if isempty(sg.free_ids)
        sg.current_max += 1
        return sg.current_max
    else
        return pop!(sg.free_ids)
    end
end

"""
    add_node!(sg::SysGraph, id::Int, node::SysNode)

Will map the given node to the id and add it in the graph.
"""
function add_node!(sg::SysGraph, id::Int, node::SysNode)
    sg.idtonode[id] = node
end

"""
    remove_node!(sg::SysGraph, id::Int)

Will remove the system corresponding to the given id from the graph
"""
function remove_node!(sg::SysGraph, id::Int)
    delete!(sg.idtonode, id)
    push!(sg.free_ids, id)
end

"""
    get_graph(sg::SysGraph)

Return the DiGraph of the system graph
"""
get_graph(sg::SysGraph) = sg.graph

"""
    add_system!(sg::SysGraph, obj)

Add the given obj to the system graph.
"""
function add_system!(sg::SysGraph, obj; sort=true)
    id = get_available_id(sg)
    node = SysNode(obj)
    add_node!(sg, id, node)
    add_vertex!(sg.graph)
    node.id = id
    sort && (sg.sort_cache = topological_sort(sg))
    return id
end

"""
    remove_system!(sg::SysGraph, id::Int)

Removes the system corresponding to id from the system graph.
"""
function remove_system!(sg::SysGraph, id::Int; sort=true)
    remove_node!(sg, id)
    rem_vertex!(sg.graph, id)
    sort && (sg.sort_cache = topological_sort(sg))
end

"""
    add_dependency!(sg::SysGraph, from::Int, to::Int)

Add a dependency between the system with the ids from and to.
This also set the execution order.
If creating the dependency would create a cycle, then the function returns false and nothing is done.
"""
function add_dependency!(sg::SysGraph, from::Int, to::Int; sort=true)
    if add_edge_checked!(sg.graph, from, to)
        p = sg.idtonode[from]
        c = sg.idtonode[to]
        c.deps[typeof(p.obj)] = WeakRef(p)
        push!(p.children, c)
        sort && (sg.sort_cache = topological_sort(sg))
    end
end

"""
    remove_dependency!(sg::SysGraph, from::Int, to::Int; sort=true)

Removes a dependency between the system with the ids from and to.
"""
function remove_dependency!(sg::SysGraph, from::Int, to::Int; sort=true)
    rem_edge!(sg.graph, from, to)
    p = sg.idtonode[from]
    c = sg.idtonode[to]
    delete!(c.deps,typeof(p.obj))
    idx = findfirst(p.children, c)
    if idx != -1
        p.children[end], p.children[idx] = p.children[idx], p.children[end]
        pop!(p.children)
    end
    sort && (sg.sort_cache = topological_sort(sg))
end

"""
    merge_graphs!(sg1::SysGraph, sg2::SysGraph)

Merges 2 SysGraph together. The node of the second one will be added to the first one.
If both graph have the samem system, one will be kept and the other will connect on it.
"""
function merge_graphs!(sg1::SysGraph, sg2::SysGraph; sort=true)
    offset = sg1.current_max
    obj_to_id = Dict{DataType, Int}()

    for (id, node) in sg1.idtonode
        obj_to_id[typeof(node.obj)] = id
    end

    id_map = Dict{Int, Int}()
    for (id2, node2) in sg2.idtonode
        if haskey(obj_to_id, node2.obj)
            id_map[id2] = obj_to_id[typeof(node2.obj)]
        else
            new_id = id2 + offset
            sg1.idtonode[new_id] = node2
            add_vertex!(sg1.graph)
            sg1.current_max = max(sg1.current_max, new_id)
            id_map[id2] = new_id
            obj_to_id[typeof(node2.obj)] = new_id
        end
    end

    for e in edges(sg2.graph)
        from = id_map[src(e)]
        to = id_map[dst(e)]

        if from != to
            add_edge!(sg1.graph, from, to)
        end
    end

    sort && (sg.sort_cache = topological_sort(sg))

    return sg1
end

"""
    smap!(f, sg::SysGraph)

Iterate topologically on the graph and apply the function f on it sequentially.
"""
function smap!(f, sg::SysGraph)
    for id in sg.sort_cache
        node = sg.idtonode[id]
        f(node.obj)
    end
end

"""
    pmap!(f, sg::SysGraph)

Iterate topologically on the graph and apply the function f on it concurrently.
"""
function pmap!(f, sg::SysGraph)
    indeg = indegree(sg.graph)
    ready = [v for v in vertices(sg.graph) if indeg[v] == 0]

    @sync while !isempty(ready)
        next_ready = Int[]

        @sync for v in ready
            @spawn begin
                node = sg.idtonode[v]
                f(node.obj)

                for child in outneighbors(sg.graph, v)
                    indeg[child] -= 1
                    if indeg[child] == 0
                        push!(next_ready, child)
                    end
                end
            end
        end

        ready = next_ready
    end
end
