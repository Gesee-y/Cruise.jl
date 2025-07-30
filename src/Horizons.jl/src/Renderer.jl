#######################################################################################################################
####################################################### RENDERER ######################################################
#######################################################################################################################

export HRenderer, RendererData, ResourcePool

abstract type RendererData end

mutable struct ResourcePool{T}
	pool::Vector{T}
	range::UnitRange{Int}

	## Constructor

	ResourcePool{T}() where T <: AbstractResource = new(T[], 0:0)
end

struct HRenderer{R,T,N}
	data::R
	cmdbuffer::CommandBuffer
	resources::Dict{Symbol, ResourcePool}
	viewport::HViewport{T,N}

	## Constructors

	HRenderer{R,T,N}(data::R) where {R <: RendererData, T <: ObjectData, N} = new{R,T,N}(data, CommandBuffer(), 
		Dict{Symbol, ResourcePool}(), HViewport{T,N}())
end

const HRenderer2D{R,T} = HRenderer{R,T,2}
const HRenderer3D{R,T} = HRenderer{R,T,3}

####################################################### FUNCTIONS #####################################################

get_commandbuffer(h::HRenderer) = getfield(h, :cmdbuffer)
get_resourcetypenum(h::HRenderer) = 3
get_viewport(h::HRenderer) = getfield(h, :viewport)
get_resourcenames(::Type{<:RendererData}) = (:texture,)
get_resourcenames(h::HRenderer{R}) where R <: RendererData = get_resourcenames(R)
get_currenttarget(h::HRenderer) = nothing
get_name(res::T) where T <: AbstractResource = get_name(T)
get_name(::Type{T}) where T <: AbstractResource = error("get_name not defined for resource of type $T")
function get_resourcenamefromid(ren::HRenderer{R}, id) where R <: RendererData
    names = get_resourcenames(R)
	steps = typemax(UInt32)÷length(names)
	i = (id÷steps) + 1
	@assert (0 < i <= length(names)) "$id is too small or too big. It doesn't match any name."

	return @inbounds names[i]
end
function get_resourcefromid(ren::HRenderer{R}, id) where R <: RendererData
	names = get_resourcenames(R)
	steps = typemax(UInt32)÷length(names)
	i = (id÷steps) + 1
	name = names[i]
    resources = ren.resources
	if haskey(resources, name)
		return resources[name].pool[i]
	end

	error("resources $name is not registered yet in the renderer.")
end
function register_resource(ren::HRenderer, res::T) where T <: AbstractResource
	name = get_name(res)
	resources = ren.resources
	if fast_haskey(resources, name)
		addtopool!(resources[name], res)
		return
	end

	resources[name] = ResourcePool{T}()
	addtopool!(resources[name], res)
	return
end
function addtopool!(pool::ResourcePool{T}, res::T) where T
	vec = pool.pool
	L = length(vec)
	if length(pool.range) < length(vec)
		id = pool.range[end]+1
		res.id = id
		vec[id] = res
		pool.range = 1:id

	    return
	end

    id = L+1
    res.id = id
	push!(vec, res)
	pool.range = 1:id
    
    return
end