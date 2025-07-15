#######################################################################################################################
#################################################### CRATE INTERFACE ##################################################
#######################################################################################################################

export Load, Destroy

#######################################################################################################################

"""
    Load(T::Type{AbstractCrate}, args...)

Generic function to load a crate.
If this method doesn't exist for a given crate type then it will throw an error.
When adding a new crate type, you should overload this function.
"""
Load(T::Type{AbstractCrate}, args...) = error("Load not defined for crate of type $T. Could not load the crate.")

"""
    Destroy(crate::AbstractCrate)

Generic function to destroy a crate.
If this function doesn't exist for a given crate type then nothing happen and we will let the Julia's GC collect it.
When adding a new crate type, you should overload this function.
"""
Destroy(crate::AbstractCrate) = nothing