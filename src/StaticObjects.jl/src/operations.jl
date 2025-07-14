# Implement the operation for static array

vec_resulting() = SArray

function set_operators()
	vec_type = invokelatest(vec_resulting)

	for op in (:+,:-)
		eval(quote
				function Base.$op(v1::SArray{T1,D,N,L},v2::SArray{T2,D,N,L}) where{T1 <: Any,T2 <: Any,D <: Tuple,N,L}
					T = promote_type(T1,T2)
					SArray{T,D,N,L}( Base.$op.(v1.data,v2.data))
				end
				function Base.$op(v1::iSArray{T1,D,N,L},v2::iSArray{T2,D,N,L}) where{T1 <: Any,T2 <: Any,D <: Tuple,N,L}
					T = promote_type(T1,T2)
					iSArray{T,D,N,L}( Base.$op.(v1.data,v2.data))
				end

				function Base.$op(v1::SArray{T1,D,N,L},v2::iSArray{T2,D,N,L}) where{T1 <: Any,T2 <: Any,D <: Tuple,N,L}
					tup = Base.$op.(v1.data,v2.data)
					T = promote_type(T1,T2)
					return $(vec_type){T,D,N,L}(tup)
				end
				function Base.$op(v1::iSArray{T1,D,N,L},v2::SArray{T2,D,N,L}) where{T1 <: Any,T2 <: Any,D <: Tuple,N,L}
					tup = Base.$op.(v1.data,v2.data)
					T = promote_type(T1,T2)
					return $(vec_type){T,D,N,L}(tup)
				end
				
				Base.$op(v1::iSArray{T,D,N,L},v2::SArray{T,D,N,L}) where{T <: Any,D <: Tuple,N,L} = $(vec_type){T,D,N,L}(Base.$op.(v1.data,v2.data))
				Base.$op(v1::SArray{T,D,N,L},v2::iSArray{T,D,N,L}) where{T <: Any,D <: Tuple,N,L} = $(vec_type){T,D,N,L}(Base.$op.(v1.data,v2.data))
			end
			)
	end

	for op in (:*,)
		eval(quote 
				Base.$op(v::SArray{T,D,N,L},n::Number) where{T <: Any,D <: Tuple,N,L} = SArray{promote_type(T,typeof(n)),D,N,L}(Base.$op.(v.data, n))
				Base.$op(v::iSArray{T,D,N,L},n::Number) where{T <: Any,D <: Tuple,N,L} = iSArray{promote_type(T,typeof(n)),D,N,L}(Base.$op.(v.data, n))
			
				Base.$op(n::Number, v::AbstractSArray) = Base.$op(v,n)
			end)
	end
	for op in (:/,)
		eval(quote 
				Base.$op(v::SArray{T,D,N,L},n::Number) where{T <: Any,D <: Tuple,N,L} = SArray{Float64,D,N,L}(Base.$op.(v.data, n))
				Base.$op(v::iSArray{T,D,N,L},n::Number) where{T <: Any,D <: Tuple,N,L} = iSArray{Float64,D,N,L}(Base.$op.(v.data, n))
				
				Base.$op(n::Number, v::AbstractSArray) = Base.$op(v,n)
			end)
	end
end

set_operators()

Base.:*(m1::StaticMatrix{T1, N1, M1}, m2::StaticMatrix{T2, M2, N2}) where{T1<:Number,T2<:Number,M1,M2,N1,N2} = begin
	throw("Failed to multiply matrix A of size $(size(m1)) with matrix B of size $(size(m2))")
end

function Base.:*(m1::StaticMatrix{T1, N1, M}, m2::StaticMatrix{T2, M,N2}) where{T1<:Number,T2<:Number,M,N1,N2}
	
	# We get the type of the values of the new matrix
	T = promote_type(T1,T2)

	# We preallocate the static array
	arr = SMatrix{T, N1, N2, N1*N2}(undef)

	# We create the main loop for the multiplication
	@inbounds for i in Base.OneTo(N1)
		for j in Base.OneTo(N2)
			value = _compute_elt(m1,m2,i,j)
			arr[i,j] = value
		end
	end

	return arr
end

function Base.:*(a::iSMatrix{T,2,2,4}, b::iSMatrix{T,2,2,4}) where T
    return iSMatrix{T,2,2,4}((
        a[1,1]*b[1,1] + a[1,2]*b[2,1],
        a[1,1]*b[1,2] + a[1,2]*b[2,2],
        a[2,1]*b[1,1] + a[2,2]*b[2,1],
        a[2,1]*b[1,2] + a[2,2]*b[2,2],
    ))
end

function Base.:*(a::iSMatrix{T,2,2}, v::iSVector{T,2}) where T
	return iSVector{T,2}(
		v[1]*a[1,1] + v[2]*a[1,2],
		v[1]*a[1,1] + v[2]*a[1,2]
		)
end

function Base.:*(a::iSMatrix{T,3,3}, v::iSVector{T,3}) where T
	return iSVector{T,3}(
		v[1]*a[1,1] + v[2]*a[1,2] + v[3]*a[1,3],
		v[1]*a[2,1] + v[2]*a[2,2] + v[3]*a[2,3],
		v[1]*a[3,1] + v[2]*a[3,2] + v[3]*a[3,3]
		)
end

function Base.:*(a::iSMatrix{T,3,3}, b::iSMatrix{T,3,3}) where T
    return iSMatrix{T,3,3,9}((
        a[1,1]*b[1,1] + a[1,2]*b[2,1] + a[1,3]*b[3,1],
        a[1,1]*b[1,2] + a[1,2]*b[2,2] + a[1,3]*b[3,2],
        a[1,1]*b[1,3] + a[1,2]*b[2,3] + a[1,3]*b[3,3],

        a[2,1]*b[1,1] + a[2,2]*b[2,1] + a[2,3]*b[3,1],
        a[2,1]*b[1,2] + a[2,2]*b[2,2] + a[2,3]*b[3,2],
        a[2,1]*b[1,3] + a[2,2]*b[2,3] + a[2,3]*b[3,3],

        a[3,1]*b[1,1] + a[3,2]*b[2,1] + a[3,3]*b[3,1],
        a[3,1]*b[1,2] + a[3,2]*b[2,2] + a[3,3]*b[3,2],
        a[3,1]*b[1,3] + a[3,2]*b[2,3] + a[3,3]*b[3,3],
    ))
end

function Base.:*(a::iSMatrix{T,4,4}, b::iSMatrix{T,4,4}) where T
    return iSMatrix{T,4,4,16}((
        a[1,1]*b[1,1] + a[1,2]*b[2,1] + a[1,3]*b[3,1] + a[1,4]*b[4,1],
        a[1,1]*b[1,2] + a[1,2]*b[2,2] + a[1,3]*b[3,2] + a[1,4]*b[4,2],
        a[1,1]*b[1,3] + a[1,2]*b[2,3] + a[1,3]*b[3,3] + a[1,4]*b[4,3],
        a[1,1]*b[1,4] + a[1,2]*b[2,4] + a[1,3]*b[3,4] + a[1,4]*b[4,4],

        a[2,1]*b[1,1] + a[2,2]*b[2,1] + a[2,3]*b[3,1] + a[2,4]*b[4,1],
        a[2,1]*b[1,2] + a[2,2]*b[2,2] + a[2,3]*b[3,2] + a[2,4]*b[4,2],
        a[2,1]*b[1,3] + a[2,2]*b[2,3] + a[2,3]*b[3,3] + a[2,4]*b[4,3],
        a[2,1]*b[1,4] + a[2,2]*b[2,4] + a[2,3]*b[3,4] + a[2,4]*b[4,4],

        a[3,1]*b[1,1] + a[3,2]*b[2,1] + a[3,3]*b[3,1] + a[3,4]*b[4,1],
        a[3,1]*b[1,2] + a[3,2]*b[2,2] + a[3,3]*b[3,2] + a[3,4]*b[4,2],
        a[3,1]*b[1,3] + a[3,2]*b[2,3] + a[3,3]*b[3,3] + a[3,4]*b[4,3],
        a[3,1]*b[1,4] + a[3,2]*b[2,4] + a[3,3]*b[3,4] + a[3,4]*b[4,4],

        a[4,1]*b[1,1] + a[4,2]*b[2,1] + a[4,3]*b[3,1] + a[4,4]*b[4,1],
        a[4,1]*b[1,2] + a[4,2]*b[2,2] + a[4,3]*b[3,2] + a[4,4]*b[4,2],
        a[4,1]*b[1,3] + a[4,2]*b[2,3] + a[4,3]*b[3,3] + a[4,4]*b[4,3],
        a[4,1]*b[1,4] + a[4,2]*b[2,4] + a[4,3]*b[3,4] + a[4,4]*b[4,4],
    ))
end

function Base.:*(a::iSMatrix{T,4,4}, v::iSVector{T,4}) where T
	return iSVector{T,4}(
		v[1]*a[1,1] + v[2]*a[1,2] + v[3]*a[1,3] + v[4]*a[1,4],
		v[1]*a[2,1] + v[2]*a[2,2] + v[3]*a[2,3] + v[4]*a[2,4],
		v[1]*a[3,1] + v[2]*a[3,2] + v[3]*a[3,3] + v[4]*a[3,4],
		v[1]*a[4,1] + v[2]*a[4,2] + v[3]*a[4,3] + v[4]*a[4,4]
		)
end

function Base.:*(m::StaticMatrix{T1, N, M}, v::StaticVector{T2, M}) where{T1<:Number,T2<:Number,M,N}
	
	# We get the type of the values of the new vector
	T = promote_type(T1,T2)

	# We preallocate the static array
	arr = SVector{T, M}(undef)

	# We create the main loop for the multiplication
	@inbounds @simd for i in Base.OneTo(M)
		value = _compute_elt(m,v,i)
		arr[i] = value
	end

	return arr
end

function Stranspose(m::StaticMatrix{T, N, M}) where{T,N,M}
	mat = SMatrix{T, M, N, N*M}(undef)

	@inbounds @simd for i in Base.OneTo(M)
		@simd for j in Base.OneTo(N)
			mat[i,j] = m[j,i]
		end
	end

	return mat
end

Stranspose(v::SVector{T, N}) where{T,N} = SMatrix{T, 1, N, N}(Tuple(v))
Stranspose(v::iSVector{T, N}) where{T,N} = iSMatrix{T, 1, N, N}(Tuple(v))

function _compute_elt(m1::StaticMatrix{T1,N1, M}, m2::StaticMatrix{T2,M ,N2}, 
			i::Integer, j::Integer) where{T1<:Number,T2<:Number,M,N1,N2} 
	
	# We get the type of the value of the new matrix
	T = promote_type(T1,T2)

	# We initialize the value to the zero of T
	value :: T = zero(T)

	# Then we loop over the elements to do the multiplication
	@inbounds for i2 in Base.OneTo(M)
		value += m1[i, i2] * m2[i2, j]
	end

	return value
end

function _compute_elt(m::StaticMatrix{T1,N, M}, v::StaticVector{T2,M}, 
			i::Integer) where{T1<:Number,T2<:Number,M,N} 
	
	# We get the type of the value of the new vector
	T = promote_type(T1,T2)

	# We initialize the value to the zero of T
	value :: T = zero(T)

	# Then we loop over the elements to do the multiplication
	@inbounds @simd for i2 in Base.OneTo(M)
		value += m[i, i2] * v[i2]
	end

	return value
end

Base.reinterpret(::Type{Out},A::SArray{Any,D,N,L}) where {Out,D,N,L} = SArray{Out,D,N,L}(A.data)
Base.reinterpret(::Type{Out},A::iSArray{Any,D,N,L}) where {Out,D,N,L} = iSArray{Out,D,N,L}(A.data)

Base.reshape(A::SArray{T,D,N,L},shape::Int...) where{T,D,N,L} = SArray{T,Tuple{shape...},length(shape),L}(A.data)
Base.reshape(A::iSArray{T,D,N,L},shape::Int...) where{T,D,N,L} = iSArray{T,Tuple{shape...},length(shape),L}(A.data)
