## Some function for the Ray type ##

"""
	mutable struct Ray{N}
		data :: NTuple{2,SVector{Real,N}}

A structure representing an N-dimensional ray.
They use 2 vector (one for the start of the ray, one for the end.)
"""
mutable struct Ray{T<:Real,N}
	data :: NTuple{2,AnyVector{T,N}}

	# Constructors #

	Ray{T,N}(v1::AnyVector{T,N},v2::AnyVector{T,N}) where {T<:Real,N} = new{T,N}((v1,v2))
	Ray{T}(v1::AnyVector{T,N},v2::AnyVector{T,N}) where {T<:Real,N} = new{T,N}((v1,v2))
end

@nospecialize
Base.@nospecializeinfer @inline function get_as_range(ray::Ray{T,N};precision=1) where {T,N}
	rangeType = ifelse(precision isa Integer && T <: Integer, StepRange,StepRangeLen)

	ranges = Vector{rangeType}(undef,N)
	v1 =ray.data[1]
	v2 = ray.data[2]
	
	@inbounds for i in Base.OneTo(N)
		start, stop = v1[i], v2[i]
		step = start <= stop ? precision : -precision

		r = range(start,stop;step=step)
		ranges[i] = r
	end

	return ranges
end
@specialize

precompile(get_as_range,(Ray{Int,2},))
precompile(get_as_range,(Ray{Int,3},))