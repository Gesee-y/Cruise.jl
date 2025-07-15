#######################################################################################################################
##################################################### CRATE MANAGER ###################################################
#######################################################################################################################

export CrateManager
export Load!, DestroyAllCrates!

#######################################################################################################################

mutable struct CrateManager
	crates::Dict{String,AbstractCrate}

	## Constructor

	CrateManager() = new(Dict{String,AbstractCrate}())
end

####################################################### FUNCTIONS #####################################################

"""
    Load!(manager::CrateManager, T::Type{<:AbstractCrate}, path::AbstractString,args...)

Will return the crate of type `T` at path. If the crate has already been loaded in the manager, then it return that 
crate, else it create a new one and store it.
"""
function Load!(manager::CrateManager, T::Type{<:AbstractCrate}, path::AbstractString,args...)
	if haskey(manager.crates,path)
		return manager.crates[path]
	end

	crate = Load(T,path,args...)
	manager.crates[string(path)] = crate
	return crate
end

function DestroyAllCrates!(m::CrateManager)
	for crate in values(m.crates)
		Destroy(crate)
	end

	empty!(m.crates)
end

####################################################### HELPERS #######################################################

_get_path(s::Symbol) = string(s)
_get_path(ex::Expr) = joinpath(_get_path(ex.args[2]),_get_path(ex.args[3]))
