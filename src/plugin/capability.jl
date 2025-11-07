#########################################################################################################################
################################################### CAPABILITIES #######################################################
#########################################################################################################################

export add_capability!, get_capability, require_capability

"""
    add_capability!(node::CRPluginNode, cap::AbstractCapability)

Assigns a capability to the given plugin node. This capability will be exposed to dependent nodes.
"""
function add_capability!(node::CRPluginNode, cap::AbstractCapability)
    node.capability = cap
end

"""
    get_capability(node::CRPluginNode)::AbstractCapability

Returns the capability exposed by the plugin node.
"""
get_capability(node::CRPluginNode) = node.capability

"""
    require_capability(node::CRPluginNode, cap_type::Type{<:AbstractCapability})

Checks if the plugin node has a dependency exposing a capability of type `cap_type`.
Throws an error if the required capability is not found.
"""
function require_capability(node::CRPluginNode, cap_type::Type{<:AbstractCapability})
    for dep in values(node.deps)
        dep_val = dep.value
        if dep_val isa cap_type
            return dep_val
        end
    end
    error("Required capability $(cap_type) not found in dependencies of node $(node.id)")
end

