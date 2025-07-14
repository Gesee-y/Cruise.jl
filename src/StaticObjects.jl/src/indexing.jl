# All the necessary for indexing Static arrays

"""
	struct StaticIndex

A struct to contain index for static array.

	StaticIndex(i::Int)

Construct a static index 
"""
struct StaticIndex
	L :: Int
end



IndexStyle(::Type{<:AbstractSArray}) = IndexCartesian()
IndexStyle(::Type{<:StaticVector}) = IndexLinear()

"""
	eltype(A::AbstractSArray)

Return the type of the element of the static array.
"""

Base.eltype(::AbstractSArray{T}) where{T <: Any} = T

"""
	size(A::AbstractSArray,[dim])

Return the dimensions of a static array A, optionally, you can pass the parameter dim to get the a single
dimension.
"""
Base.size(::AbstractSArray{T,D,N}) where{T <: Any ,D <: Tuple ,N} = to_tuple(D.parameters)
Base.size(::AbstractSArray{T,D,N},dim::Int) where{T <: Any ,D <: Tuple ,N} = to_tuple(D.parameters)[dim]

"""
	length(A::AbstractSArray)

Return the number of element in a static array, it equivalent to prod(size(A)) but is more efficient.
"""
Base.length(::SArray{T,D,N,L}) where{T <: Any ,D <: Tuple ,N,L} = L
Base.length(::iSArray{T,D,N,L}) where{T <: Any ,D <: Tuple ,N,L} = L

"""
	ndims(A::AbstractSArray)

Return the number of dimension of the Static array A. Equivalent to length(size(A)) but is more efficient.
"""
Base.ndims(::AbstractSArray{T,D,N}) where{T <: Any ,D <: Tuple ,N} = N

"""
	firstindex(A::AbstractSArray)

the first index of the static array A, 1 by default.
"""
Base.firstindex(::AbstractSArray) = 1

"""
	lastindex(A::AbstractSArray)

the last index of the static array A, length(A) by default.
"""
Base.lastindex(array::AbstractSArray) = length(array)

"""
	getindex(A::AbstractSArray,i::Int)

Get the element at the index i in the static array A.

	getindex(A::AbstractSArray{T,D,N},idxs::Vararg{Int,N})

Get the element at the set of index idxs in the N-dimensional static array A.
"""
function Base.getindex(array::AbstractSArray,i::Int)
	@boundscheck 1 <= i <= length(array) || throw(BoundsError(array,i))
	return array.data[i]
end

function Base.getindex(array::AbstractSArray{T,D,N},idxs::Vararg{Int,N}) where{T <: Any ,D <: Tuple ,N}
	@boundscheck if (any(i -> !(1 <= i <= length(array)),idxs)) throw(BoundsError(array,i)) end
	
	i = _compute_coordinate(size(array),idxs)
	return array.data[i]
end

"""
	setindex!(A::AbstractSArray,val,i::Int)

Set the index i of the static array A with the value val.

	setindex!(A::AbstractSArray{T,D,N},idxs::Vararg{Int,N})

Set the set of index idxs of the N-dimensional static array A with the value val.
"""
#=function Base.setindex!(array::AbstractSArray{T,D,N},val::T,i::Int) where{T <: Any ,D <: Tuple,N}
	L = length(array)
	1 <= i <= L || throw(BoundsError(array,i))
	
	AD = getfield(array,:data)
    data = ()

	if i == 1
		data = append_tuple((val,), (AD[begin+1:end]))
	elseif i == L
		append_tuple(AD[begin:end-1], (val,))
	else
		append_tuple(AD[begin:i-1], (val,), (AD[i+1:end]))
	end
	
	#indexs = flatten_range(eachindex(AD))
	#data = map(x -> (x == i) ? convert(T,val) : AD[x],indexs)
	
	setfield!(array,:data,data)
end=#
function Base.setindex!(array::AbstractSArray{T,D,N},v,idxs::Vararg{Int,N}) where{T <: Any ,D <: Tuple ,N}
    val = convert(T, v)
    L = length(array)
	i = _compute_coordinate(size(array),idxs)
	
	@boundscheck 1 <= i <= L || throw(BoundsError(array,i))

	AD = getfield(array,:data)

	data = replace_tuple(AD,val,i)

	#indexs = flatten_range(eachindex(AD))
	#data = map(x -> (x == i) ? convert(T,val) : AD[x],indexs)
	
	setfield!(array,:data,data)
end

"""
	similar(A::AbstractSArray{T,D,N}, ::Type{S},dim::Dims{N})

Return a static array with the dimension and type specified in arguments.
"""
@inline Base.similar(A::SArray,::Type{S},dim::Dims) where{S<:Any} = SArray{S,Tuple{dim...},length(dim),prod(dim)}(undef)
@inline Base.similar(A::iSArray,::Type{S},dim::Dims) where{S<:Any} = iSArray{S,Tuple{dim...},length(dim),prod(dim)}(undef)

"""
	eachindex(A::AbstractSArray)

return an iterator of the index of the static array A.
"""
Base.eachindex(A::SArray{T,D,N,L}) where{T <: Any,D <: Tuple,N,L} = Base.OneTo(L)
Base.eachindex(A::iSArray{T,D,N,L}) where{T <: Any,D <: Tuple,N,L} = Base.OneTo(L)

_compute_coordinate(dimension,coord) = begin
	#coord = (matrix_ordering() == ROW_MAJOR) ? reverse(coord) : coord
	elt = coord[1]

	for i in 2:length(coord)
		c = (coord[i]-1) * (dimension[i-1])
		
		elt += c
	end
	elt == 0 ? elt = 1 : nothing

	return elt
end