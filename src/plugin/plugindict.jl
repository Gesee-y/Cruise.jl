#####################################################################################################################################
############################################################# PLUGINS DICT ##########################################################
####################################################################################################################################

struct PluginDict
	_data::Dict{Symbol, Any}

	## Constructor

	PluginDict() = new(Dict{Symbol, Any}())
end

Base.getindex(p::PluginDict, s::Symbol) = _unwrap(getindex(_getdata(p), s))
Base.getindex(p::PluginDict, T::Type) = getindex(p, Symbol(T))

Base.setindex!(p::PluginDict, v, s::Symbol) = setindex!(_getdata(p), v, s)
Base.setindex!(p::PluginDict, v, T::Type) = setindex!(p, v, Symbol(T))

Base.delete!(p::PluginDict, s::Symbol) = delete!(_getdata(p), s)
Base.delete!(p::PluginDict, T::Type) = delete!(p, Symbol(T))

Base.haskey(p::PluginDict, s::Symbol) = haskey(_getdata(p), s)
Base.haskey(p::PluginDict, T::Type) = haskey(p, Symbol(T))

Base.keys(p::PluginDict) = keys(_getdata(p))
Base.values(p::PluginDict) = _unwrap.(values(_getdata(p)))

_getdata(d::PluginDict) = getfield(d, :_data)
_unwrap(w::WeakRef) = begin 
    v = w.value
    return isdefined(v, :cap) ? v.cap : v.obj
end