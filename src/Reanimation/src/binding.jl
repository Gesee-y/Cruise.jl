#####################################################################################################################
####################################################### BINDINGS ####################################################
#####################################################################################################################

######################################################### CORE ######################################################

abstract type AbstractBinding end

struct ObjectBinding{T} <: AbstractBinding
	obj::T
	property::Symbol

	## Constructor

	function ObjectBinding(obj, p::Symbol)
		isimmutable(obj) && error("Can't bind properties of immutable objects.")
		return new{typeof(obj)}(obj,p)
	end
end

struct ArrayBinding{T} <: AbstractBinding
	array::AbstractArray{T}
	pos::Int
end

struct DictBinding{K,V} <: AbstractBinding
	dict::AbstractDict{K,V}
	key::K
end

####################################################### FUNCTIONS ###################################################

AbstractBinding(obj, p::Symbol) = ObjectBinding(obj, p)
AbstractBinding(obj::AbstractArray{T}, i::Int) where T = ArrayBinding{T}(obj, i)
AbstractBinding(obj::AbstractDict{K,V}, key::K) where {K,V} = DictBinding{K,V}(obj, key)

set!(b::AbstractBinding, ::Any) = error("set! isn't defined for binding of type $(typeof(b))")
set!(b::ObjectBinding, v) = setproperty!(b.obj, b.property, v)
set!(b::ArrayBinding, v) = (b.array[b.pos] = v)
set!(b::DictBinding, v) = (b.dict[b.key] = v)
