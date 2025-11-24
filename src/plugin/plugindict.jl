#####################################################################################################################################
############################################################# PLUGINS DICT ##########################################################
####################################################################################################################################

struct PluginDict
	_data::Dict{UInt64, Any}

	## Constructor

	PluginDict() = new(Dict{UInt64, Any}())
end

Base.getindex(p::PluginDict, s::Type) = _unwrap(getindex(_getdata(p), hash(s)))

Base.setindex!(p::PluginDict, v, s::Type) = setindex!(_getdata(p), v, hash(s))

Base.delete!(p::PluginDict, s::Type) = delete!(_getdata(p), hash(s))

Base.haskey(p::PluginDict, s::Type) = haskey(_getdata(p), hash(s))

Base.keys(p::PluginDict) = keys(_getdata(p))
Base.values(p::PluginDict) = _unwrap.(values(_getdata(p)))

_getdata(d::PluginDict) = getfield(d, :_data)
_unwrap(w::WeakRef) = begin 
    v = w.value
    return isdefined(v, :capability) ? v.capability : v.obj
end
_unwrap(w::Ref) = w[]
_unwrap(x) = x