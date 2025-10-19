#######################################################################################################################
################################################# OPERATIONS ##########################################################
#######################################################################################################################

export add_system!, remove_system!, add_dependency!, remove_dependency!, merge_graphs!, pmap!, smap!
export isinitialized, isuninitialized, isdeprecated, hasfailed, getstatus, setstatus, setresult
export hasfaileddeps, hasuninitializeddeps, hasalldepsinitialized

isinitialized(s::CRPluginNode) = getstatus(s) == PLUGIN_OK
isuninitialized(s::CRPluginNode) = getstatus(s) == PLUGIN_OFF
isdeprecated(s::CRPluginNode) = getstatus(s) == PLUGIN_DEPRECATED
hasfailed(s::CRPluginNode) = getstatus(s) == PLUGIN_ERR
getstatus(s::CRPluginNode) = s.status[]
setstatus(s::CRPluginNode, st::CRPluginStatus) = (s.status[] = st)
getresult(s::CRPluginNode) = s.result
setresult(s::CRPluginNode, r) = (s.result = r)
hasfaileddeps(s::CRPluginNode) = any(p -> getstatus(p) == PLUGIN_ERR, values(s.deps))
hasuninitializeddeps(s::CRPluginNode) = any(p -> getstatus(p) == PLUGIN_OFF, values(s.deps))
hasalldepsinitialized(s::CRPluginNode) = any(p -> getstatus(p) == PLUGIN_OK, values(s.deps))
hasdeaddeps(s::CRPluginNode) = any(isnothing, values(s.deps))

add_status_callback(f, p::CRPluginNode) = connect(f, p.status)
serialize(::CRPluginNode) = ""

function getnodeid(p::CRPluginNode, s::Symbol)
    for (i, n) in p.idtonode
        if Symbol(typeof(n.obj)) == s
            return i
        end
    end

    return -1
end

"""
    get_available_id(sg::CRPlugin)

Return an available id for a new system to take.
This will update the internal data of the CRPlugin so between 2 calls it may not return the same value.
"""
function get_available_id(sg::CRPlugin)
    if isempty(sg.free_ids)
        sg.current_max += 1
        return sg.current_max
    else
        return pop!(sg.free_ids)
    end
end

"""
    add_node!(sg::CRPlugin, id::Int, node::CRPluginNode)

Will map the given node to the id and add it in the graph.
"""
function add_node!(sg::CRPlugin, id::Int, node::CRPluginNode)
    sg.idtonode[id] = node
end

"""
    remove_node!(sg::CRPlugin, id::Int)

Will remove the system corresponding to the given id from the graph
"""
function remove_node!(sg::CRPlugin, id::Int)
    delete!(sg.idtonode, id)
    push!(sg.free_ids, id)
end

"""
    get_graph(sg::CRPlugin)

Return the DiGraph of the system graph
"""
get_graph(sg::CRPlugin) = sg.graph

"""
    add_system!(sg::CRPlugin, obj)

Add the given obj to the system graph.
"""
function add_system!(sg::CRPlugin, obj; sort=true)
    id = get_available_id(sg)
    node = CRPluginNode(obj)
    add_node!(sg, id, node)
    add_vertex!(sg.graph)
    node.id = id
    sort && (sg.sort_cache = topological_sort(get_graph(sg)))
    return id
end

"""
    remove_system!(sg::CRPlugin, id::Int)

Removes the system corresponding to id from the system graph.
"""
function remove_system!(sg::CRPlugin, id::Int; sort=true)
    remove_node!(sg, id)
    rem_vertex!(sg.graph, id)
    sort && (sg.sort_cache = topological_sort(get_graph(sg)))
end

"""
    add_dependency!(sg::CRPlugin, from::Int, to::Int)

Add a dependency between the system with the ids from and to.
This also set the execution order.
If creating the dependency would create a cycle, then the function returns false and nothing is done.
"""
function add_dependency!(sg::CRPlugin, from::Int, to::Int; sort=true)
    if add_edge_checked!(IncrementalCycleTracker(sg.graph), from, to)
        p = sg.idtonode[from]
        c = sg.idtonode[to]
        c.deps[typeof(p.obj)] = WeakRef(p)
        push!(p.children, c)
        sort && (sg.sort_cache = topological_sort(get_graph(sg)))
    end
end

"""
    remove_dependency!(sg::CRPlugin, from::Int, to::Int; sort=true)

Removes a dependency between the system with the ids from and to.
"""
function remove_dependency!(sg::CRPlugin, from::Int, to::Int; sort=true)
    rem_edge!(sg.graph, from, to)
    p = sg.idtonode[from]
    c = sg.idtonode[to]
    delete!(c.deps,typeof(p.obj))
    idx = findfirst(p.children, c)
    if idx != -1
        p.children[end], p.children[idx] = p.children[idx], p.children[end]
        pop!(p.children)
    end
    sort && (sg.sort_cache = topological_sort(get_graph(sg)))
end

"""
    merge_graphs!(sg1::CRPlugin, sg2::CRPlugin)

Merges 2 CRPlugin together. The node of the second one will be added to the first one.
If both graph have the samem system, one will be kept and the other will connect on it.
"""
function merge_graphs!(sg1::CRPlugin, sg2::CRPlugin; sort=true)
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

    sort && (sg.sort_cache = topological_sort(get_graph(sg)))

    return sg1
end

"""
    smap!(f, sg::CRPlugin)

Iterate topologically on the graph and apply the function f on it sequentially.
"""
function smap!(f, sg::CRPlugin)
    for id in sg.sort_cache
        node = sg.idtonode[id]
        f(node)
    end
end

"""
    pmap!(f, sg::CRPlugin)

Iterate topologically on the graph and apply the function f on it concurrently.
"""
function pmap!(f, sg::CRPlugin)
    indeg = indegree(sg.graph)
    ready = [v for v in vertices(sg.graph) if indeg[v] == 0]

    @sync while !isempty(ready)
        next_ready = Int[]

        @sync for v in ready
            @spawn begin
                node = sg.idtonode[v]
                f(node)

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