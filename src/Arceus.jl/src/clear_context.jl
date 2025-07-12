"""
    @clear_context

Use this macro to reset the current entity world.
This will remove all the existing instances of a traits
"""
macro clear_context()
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES =  Dict{Symbol, Type{<:TraitPool}}()))
    eval(:(($module_name).SUB_POOL_TYPES =  Dict{Symbol, Type{<:SubPool}}()))
end