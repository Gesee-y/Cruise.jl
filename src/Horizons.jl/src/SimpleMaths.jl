## Mathematics for Horizons

#############################################################################################
####################################### VECTORS #############################################
#############################################################################################

"""
	abstract type AbastractHVector{T<:Number}

An abstract typer representing all Horizon's vector
"""
abstract type AbstractHVector{T<:Number} end

"""
	struct HVec2{T<:Number} <: AbstractHVector{T}
		x::T
		y::T

A structure representing a 2D-Vector.

## Constructors ##

	`HVec2{T}(x,y) where T<:Number`

Create a new HVec2 of type `T` with the value `x` and `y`(they will be converted to type `T`)

	`HVec2{T}(A::AbstractArray) where T<:Number`

Create a new HVec2 from an array `A`, only his 2 first element will be taken to create the
HVec2.

	`HVec2{T}(t::Tuple) where T<:Number`

Create a new HVec2 from a Tuple `t`, only his 2 first element will be taken to create the
HVec2.
"""
struct HVec2{T<:Number} <: AbstractHVector{T}
	x::T
	y::T

	## Constructors ##

	HVec2{T}(x::T,y::T) where T<:Number = new{T}(x,y)
	HVec2{T}(x::Number, y::Number) where T<:Number = new{T}(convert(T,x), convert(T,y))

	HVec2{T}(A::Union{AbstractArray,AbstractVector}) where T<:Number = HVec2{T}(A[1], A[2])
	HVec2{T}(t::Tuple) where T<:Number = HVec2{T}(t[1], t[2])
end

"""
	struct HVec3{T<:Number} <: AbstractHVector{T}
		x::T
		y::T
		z::T

A structure representing a 3D-Vector.

## Constructors ##

	`HVec3{T}(x,y,z) where T<:Number`

Create a new HVec3 from `x`,`y` and `z`(they will be converted to type `T`)

	`HVec3{T}(A::Union{AbstractArray,AbstractVector}) where T<:Number`

Create a new HVec3 from an array `A`, only his 3 first element will be taken to create the
HVec3.

	`HVec3{T}(t::Tuple) where T<:Number`

Create a new HVec3 from a Tuple `t`, only his 3 first element will be taken to create the
HVec3.

	`HVec3{T}(v::HVec2,z::Number)`

Create a new HVec3 from the HVec2 `v` and the number `z` 

	`HVec3{T}(x::Number,v::HVec2)`

Create a new HVec3 from the HVec2 `v` and the number `x` 
"""
struct HVec3{T<:Number} <: AbstractHVector{T}
	x::T
	y::T
	z::T

	## Constructors ##

	HVec3{T}(x::T,y::T,z::T) where T<:Number = new{T}(x,y,z)
	HVec3{T}(x::Number, y::Number,z::Number) where T<:Number = new{T}(convert(T,x), convert(T,y), convert(T,z))

	HVec3{T}(A::Union{AbstractArray,AbstractVector}) where T<:Number = HVec3{T}(A[1], A[2], A[3])
	HVec3{T}(t::Tuple) where T<:Number = HVec3{T}(t[1], t[2], t[3])

	HVec3{T}(v::HVec2,z::Number) where T<:Number = HVec3{T}(v.x,v.y,z)
	HVec3{T}(x::Number,v::HVec2) where T<:Number = HVec3{T}(x,v.x,v.y)
end

"""
	struct HVec4{T<:Number} <: AbstractHVector{T}
		x::T
		y::T
		z::T
		w::T

A structure representing a 4D-Vector.

## Constructors ##

	`HVec4{T}(x,y,z) where T<:Number`

Create a new HVec4 from `x`,`y`,`z` and `w`(they will be converted to type `T`)

	`HVec4{T}(A::Union{AbstractArray,AbstractVector}) where T<:Number`

Create a new HVec4 from an array `A`, only his 4 first element will be taken to create the
HVec4.

	`HVec4{T}(t::Tuple) where T<:Number`

Create a new HVec4 from a Tuple `t`, only his 4 first element will be taken to create the
HVec4.

	`HVec4{T}(v::HVec2,z::Number,w::Number)`

Create a new HVec4 from the HVec2 `v` and the numbers `z` and `w` 

	`HVec4{T}(x::Number,v::HVec2,w::Number)`

Create a new HVec4 from the HVec2 `v` and the numbers `x` and `w`

	`HVec4{T}(x::Number,y::Number,v::HVec2)`

Create a new HVec4 from the HVec2 `v` and the numbers `x` and `y`

	`HVec4{T}(v::HVec3,w::Number)`

Create a new HVec4 from the HVec3 `v` and the number `w` 

	`HVec4{T}(x::Number,v::HVec3)`

Create a new HVec4 from the HVec3 `v` and the number `x`
"""
struct HVec4{T<:Number} <: AbstractHVector{T}
	x::T
	y::T
	z::T
	w::T

	## Constructors ##

	HVec4{T}(x::T,y::T,z::T,w::T) where T<:Number = new{T}(x,y,z,w)
	HVec4{T}(x::Number, y::Number,z::Number,w::Number) where T<:Number = new{T}(convert(T,x), convert(T,y), convert(T,z),convert(T,w))

	HVec4{T}(A::Union{AbstractArray,AbstractVector}) where T<:Number = HVec4{T}(A[1], A[2], A[3], A[4])
	HVec4{T}(t::Tuple) where T<:Number = HVec4{T}(t[1], t[2], t[3], t[4])

	HVec4{T}(v::HVec2,z::Number,w::Number) where T<:Number = HVec4{T}(v.x,v.y,z,w)
	HVec4{T}(x::Number,v::HVec2,w::Number) where T<:Number = HVec4{T}(x,v.x,v.y,w)
	HVec4{T}(x::Number,y::Number,v::HVec2) where T<:Number = HVec4{T}(x,y,v.x,v.y)
	HVec4{T}(v1::HVec2,v2::HVec2) where T<:Number = HVec4{T}(v1.x,v1.y,v2.x,v2.y)

	HVec4{T}(v::HVec3,w::Number) where T<:Number = HVec4{T}(v.x,v.y,v.z,z)
	HVec4{T}(x::Number,v::HVec3) where T<:Number = HVec4{T}(x,v.x,v.y,v.z)
end

## Outer Constructors ##

HVec2(x::Number,y::Number) = HVec2{promote_type(typeof(x),typeof(y))}(x,y)
HVec2(A::Union{AbstractArray{T},AbstractVector{T}}) where T<:Number = HVec2{T}(A[1], A[2])
HVec2(t::NTuple{N,T}) where{N,T<:Number} = HVec2{T}(t[1],t[2])
HVec2(t::Tuple) = HVec2{promote_type(typeof(t[1]),typeof(t[2]))}(t[1], t[2])

HVec3(x::Number,y::Number,z::Number) = HVec3{promote_type(typeof(x),typeof(y),typeof(z))}(x,y,z)
HVec3(A::Union{AbstractArray{T},AbstractVector{T}}) where T<:Number = HVec3{T}(A[1], A[2], A[3])
HVec3(t::NTuple{N,T}) where{N,T<:Number} = HVec3{T}(t[1],t[2],t[3])
HVec3(t::Tuple) = HVec3{promote_type(typeof(t[1]),typeof(t[2]),typeof(t[3]))}(t[1], t[2], t[3])
HVec3(v::HVec2,z::Number) = HVec3(v.x,v.y,z)
HVec3(x::Number,v::HVec2) = HVec3(x,v.x,v.y)

HVec4(x::Number,y::Number,z::Number,w::Number) = HVec4{promote_type(typeof(x),typeof(y),typeof(z),typeof(w))}(x,y,z,w)
HVec4(A::Union{AbstractArray{T},AbstractVector{T}}) where T<:Number = HVec4{T}(A[1], A[2], A[3], A[4])
HVec4(t::NTuple{N,T}) where{N,T<:Number} = HVec4{T}(t[1],t[2],t[3],t[4])
HVec4(t::Tuple) = HVec4{promote_type(typeof(t[1]),typeof(t[2]),typeof(t[3]),typeof(t[4]))}(t[1], t[2], t[3], t[4])
HVec4(v::HVec2,z::Number,w::Number) = HVec4(v.x,v.y,z,w)
HVec4(x::Number,v::HVec2,w::Number) = HVec4(x,v.x,v.y,w)
HVec4(x::Number,y::Number,v::HVec2) = HVec4(x,y,v.x,v.y)
HVec4(v1::HVec2,v2::HVec2) = HVec4(v1.x,v1.y,v2.x,v2.y)
HVec4(v::HVec3,w::Number) = HVec4(v.x,v.y,v.z,z)
HVec4(x::Number,v::HVec3) = HVec4(x,v.x,v.y,v.z)

## Basic Operations

# Vector 2D
Base.:+(v1::HVec2{T},v2::HVec2{T}) where T<:Number = HVec2{T}(v1.x+v2.x,v1.y+v2.y)
Base.:+(v1::HVec2{T1},v2::HVec2{T2}) where {T1<:Number,T2<:Number} = HVec2{promote_type(T1,T2)}(v1.x+v2.x,v1.y+v2.y)

Base.:-(v::HVec2{T}) where T<:Number = HVec2{T}(-v.x,-v.y)
Base.:-(v1::HVec2,v2::HVec2) = v1 + (-v2)

Base.:*(v::HVec2{T1},n::T2) where {T1<:Number,T2<:Number} = HVec2{promote_type(T1,T2)}(v.x*n,v.y*n)
Base.:*(n::Number,v::HVec2) = v * n

Base.:/(v::HVec2,n::Number) = v * (1/n)

# Vector 3D
Base.:+(v1::HVec3{T},v2::HVec3{T}) where T<:Number = HVec3{T}(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z)
Base.:+(v1::HVec3{T1},v2::HVec3{T2}) where {T1<:Number,T2<:Number} = HVec3{promote_type(T1,T2)}(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z)

Base.:-(v::HVec3{T}) where T<:Number = HVec2{T}(-v.x,-v.y,-v.z)
Base.:-(v1::HVec3,v2::HVec3) = v1 + (-v2)

Base.:*(v::HVec3{T1},n::T2) where {T1<:Number,T2<:Number} = HVec3{promote_type(T1,T2)}(v.x*n,v.y*n,v.z*n)
Base.:*(n::Number,v::HVec3) = v * n

Base.:/(v::HVec3,n::Number) = v * (1/n)

# Vector 4D
Base.:+(v1::HVec4{T},v2::HVec4{T}) where T<:Number = HVec4{T}(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z,v1.w+v2.w)
Base.:+(v1::HVec4{T1},v2::HVec4{T2}) where {T1<:Number,T2<:Number} = HVec4{promote_type(T1,T2)}(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z,v1.w+v2.w)

Base.:-(v::HVec4{T}) where T<:Number = HVec2{T}(-v.x,-v.y,-v.z,-v.w)
Base.:-(v1::HVec4,v2::HVec4) = v1 + (-v2)

Base.:*(v::HVec4{T1},n::T2) where {T1<:Number,T2<:Number} = HVec4{promote_type(T1,T2)}(v.x*n,v.y*n,v.z*n,v.w*n)
Base.:*(n::Number,v::HVec4) = v * n

Base.:/(v::HVec4,n::Number) = v * (1/n)

Base.:+(v::AbstractHVector) = v

## Some functions

norm(vec::HVec2) = sqrt(vec.x^2 + vec.y^2)
norm_squared(vec::HVec2) = vec.x^2 + vec.y^2

norm(vec::HVec3) = sqrt(vec.x^2 + vec.y^2 + vec.z^2)
norm_squared(vec::HVec3) = vec.x^2 + vec.y^2 + vec.z^2

norm(vec::HVec4) = sqrt(vec.x^2 + vec.y^2 + vec.z^2 + vec.w^2)
norm_squared(vec::HVec4) = vec.x^2 + vec.y^2 + vec.z^2 + vec.w^2

normalize(vec::HVec2) = HVec2(vec.x/norm(vec),vec.y/norm(vec))
normalize(vec::HVec3) = HVec3(vec.x/norm(vec),vec.y/norm(vec),vec.z/norm(vec))
normalize(vec::HVec4) = HVec4(vec.x/norm(vec),vec.y/norm(vec),vec.z/norm(vec),vec.w/norm(vec))

cross(v1::HVec3,v2::HVec3) = HVec3(v1.y*v2.z-v1.z*v2.y, v1.z*v2.x-v1.x*v2.z, v1.x*v2.y-v1.y*v2.x)
cross(v1::HVec2,v2::HVec2) = v1.x*v2.y-v1.y*v2.x

dot(v1::HVec2,v2::HVec2) = v1.x*v2.x + v1.y*v2.y
dot(v1::HVec3,v2::HVec3) = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
dot(v1::HVec4,v2::HVec4) = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z + v1.w*v2.w

Base.getindex(v::HVec2,i::Int) = getfield(v,(:x,:y)[i])
Base.getindex(v::HVec3,i::Int) = getfield(v,(:x,:y,:z)[i])
Base.getindex(v::HVec4,i::Int) = getfield(v,(:x,:y,:z,:w)[i])

Base.convert(::Type{HVec2{T}},m::HVec2) where T<:Number = HVec2{T}(m.x,m.y)
Base.convert(::Type{HVec3{T}},m::HVec3) where T<:Number = HVec3{T}(m.x,m.y)
Base.convert(::Type{HVec4{T}},m::HVec4) where T<:Number = HVec4{T}(m.x,m.y)

Base.length(v::HVec2) = 2
Base.length(v::HVec3) = 3
Base.length(v::HVec4) = 4

Tuple(v::HVec2) = (v.x,v.y)
Tuple(v::HVec3) = (v.x,v.y,v.z)
Tuple(v::HVec4) = (v.x,v.y,v.z,v.w)

Array(v::HVec2{T}) where T<:Number = T[v.x,v.y]
Array(v::HVec3{T}) where T<:Number = T[v.x,v.y,v.z]
Array(v::HVec4{T}) where T<:Number = T[v.x,v.y,v.z,v.w]

#############################################################################################
####################################### MATRIX ##############################################
#############################################################################################

abstract type AbstractHMatrix{T<:Number} end

struct HMat2{T<:Number} <: AbstractHMatrix{T}
	data::NTuple{4,T}

	## Constructors ##

	HMat2{T}(a::T,b::T,c::T,d::T) where T<:Number = new{T}((a,b, c,d))
	HMat2{T}(a::Number,b::Number,c::Number,d::Number) where T<:Number = new{T}(convert.(T,(a,b,c,d)))
	HMat2{T}(a::Number) where T<:Number = HMat2{T}(a,0, 0,a)
	HMat2{T}(t::NTuple{4,T}) where T<:Number = new{T}(t)
	HMat2{T}(t::NTuple{4,<:Any}) where T<:Number = new{T}(convert.(T,t))

	HMat2{T}(v::HVec4) where T<:Number = HMat2{T}(v.x,v.y, v.z,v.w)
	HMat2{T}(v::HVec2) where T<:Number = HMat2{T}(v.x,0, 0,v.y)
	HMat2{T}(v1::HVec2,v2::HVec2) where T<:Number = HMat2{T}(v1.x,v1.y, v2.x,v2.y)
end

struct HMat3{T<:Number} <: AbstractHMatrix{T}
	data::NTuple{9,T}

	## Constructors ##

	HMat3{T}(a::T,b::T,c::T,d::T,e::T,f::T,g::T,h::T,i::T) where T<:Number = new{T}((a,b,c,d,e,f,g,h,i))
	HMat3{T}(a::Number,b::Number,c::Number,d::Number,e::Number,f::Number,g::Number,
				h::Number,i::Number) where T<:Number = new{T}(convert.(T,(a,b,c,d,e,f,g,h,i)))
	HMat3{T}(a::Number) where T<:Number = HMat3{T}(a,0,0, 0,a,0, 0,0,a)
	HMat3{T}(t::NTuple{9,T}) where T<:Number = new{T}(t)
	HMat3{T}(t::NTuple{9,<:Any}) where T<:Number = new{T}(convert.(T,t))

	HMat3{T}(v::HVec3) where T<:Number = HMat3{T}(v.x,0,0, 0,v.y,0, 0,0,v.z)
	HMat3{T}(v1::HVec3,v2::HVec3,v3::HVec3) where T<:Number = HMat3{T}(v1.x,v1.y,v1.z ,v2.x,v2.y,v2.z ,v3.x,v3.y,v3.z)
end

struct HMat4{T<:Number} <: AbstractHMatrix{T}
	data::NTuple{16,T}

	## Constructors ##

	HMat4{T}(a::T,b::T,c::T,d::T ,e::T,f::T,g::T,h::T ,i::T,j::T,k::T,l::T, 
				m::T,n::T,o::T,p::T) where T<:Number = new{T}((a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p))
	HMat4{T}(a::Number,b::Number,c::Number,d::Number,e::Number,f::Number,g::Number,
				h::Number,i::Number,j::Number,k::Number,l::Number,m::Number,n::Number,
				o::Number,p::Number) where T<:Number = new{T}(convert.(T,(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p)))
	HMat4{T}(a::Number) where T<:Number = HMat4{T}(a,0,0,0, 0,a,0,0, 0,0,a,0, 0,0,0,a)
	HMat4{T}(t::NTuple{16,T}) where T<:Number = new{T}(t)
	HMat4{T}(t::NTuple{16,<:Any}) where T<:Number = new{T}(convert.(T,t))

	HMat4{T}(v::HVec4) where T<:Number = HMat4{T}(v.x,0,0,0, 0,v.y,0,0, 0,0,v.z,0, 0,0,0,v.w)
	HMat4{T}(v1::HVec4,v2::HVec4,v3::HVec4,v4::HVec4) where T<:Number = HMat4{T}(v1.x,v1.y,v1.z,v1.w ,v2.x,v2.y,v2.z,v2.w ,v3.x,v3.y,v3.z,v3.w, v4.x,v4.y,v4.z,v4.w)
end

## Outer Constructors

HMat2(t::NTuple{4,T}) where T<:Number = HMat2{T}(t)
HMat3(t::NTuple{9,T}) where T<:Number = HMat3{T}(t)
HMat4(t::NTuple{16,T}) where T<:Number = HMat4{T}(t)

## Basic Operations

# Matrix 2x2
Base.:+(m1::HMat2,m2::HMat2) = HMat2(map(+,m1.data,m2.data))

Base.:-(m1::HMat2,m2::HMat2) = HMat2(map(-,m1.data,m2.data))
Base.:-(m1::HMat2) = HMat2(map(-,m.data))

Base.:*(m::HMat2,n::Number) = HMat2(map(*,m.data,n))
Base.:*(n::Number,m::HMat2) = HMat2(map(*,m.data,n))

Base.:/(m::HMat2,n::Number) = HMat2(map(/,m.data,n))

function Base.:*(m1::HMat2,m2::HMat2)
	d1 = m1.data
	d2 = m2.data

	a = _compute_elt(2,d1,d2,1,1)
	b = _compute_elt(2,d1,d2,2,1)
	c = _compute_elt(2,d1,d2,1,2)
	d = _compute_elt(2,d1,d2,2,2)

	return HMat2((a,b,c,d))
end

function Base.:*(m::HMat2,v::HVec2)
	d1 = m.data
	d2 = Tuple(v)

	a = _compute_elt(2,d1,d2,1,1)
	b = _compute_elt(2,d1,d2,2,1)

	return HVec2(a,b)
end

# Matrix 3x3
Base.:+(m1::HMat3,m2::HMat3) = HMat3(map(+,m1.data,m2.data))

Base.:-(m1::HMat3,m2::HMat3) = HMat3(map(-,m1.data,m2.data))
Base.:-(m1::HMat3) = HMat3(map(-,m.data))

Base.:*(m::HMat3,n::Number) = HMat3(map(*,m.data,n))
Base.:*(n::Number,m::HMat3) = HMat3(map(*,m.data,n))

Base.:/(m::HMat3,n::Number) = HMat3(map(/,m.data,n))

function Base.:*(m1::HMat3,m2::HMat3)
	d1 = m1.data
	d2 = m2.data

	a = _compute_elt(3,d1,d2,1,1)
	b = _compute_elt(3,d1,d2,2,1)
	c = _compute_elt(3,d1,d2,3,1)

	d = _compute_elt(3,d1,d2,1,2)
	e = _compute_elt(3,d1,d2,2,2)
	f = _compute_elt(3,d1,d2,3,2)

	g = _compute_elt(3,d1,d2,1,3)
	h = _compute_elt(3,d1,d2,2,3)
	i = _compute_elt(3,d1,d2,3,3)

	return HMat3((a,b,c,d,e,f,g,h,i))
end

function Base.:*(m::HMat3,v::HVec3)
	d1 = m.data
	d2 = Tuple(v)

	a = _compute_elt(3,d1,d2,1,1)
	b = _compute_elt(3,d1,d2,2,1)
	c = _compute_elt(3,d1,d2,3,1)

	return HVec3(a,b,c)
end

# Matrix 4x4
Base.:+(m1::HMat4,m2::HMat4) = HMat4(map(+,m1.data,m2.data))

Base.:-(m1::HMat4,m2::HMat4) = HMat4(map(-,m1.data,m2.data))
Base.:-(m1::HMat4) = HMat4(map(-,m.data))

Base.:*(m::HMat4,n::Number) = HMat4(map(*,m.data,n))
Base.:*(n::Number,m::HMat4) = HMat4(map(*,m.data,n))

Base.:/(m::HMat4,n::Number) = HMat4(map(/,m.data,n))

function Base.:*(m1::HMat4,m2::HMat4)
	d1 = m1.data
	d2 = m2.data

	a = _compute_elt(4,d1,d2,1,1)
	b = _compute_elt(4,d1,d2,2,1)
	c = _compute_elt(4,d1,d2,3,1)
	d = _compute_elt(4,d1,d2,4,1)

	e = _compute_elt(4,d1,d2,1,2)
	f = _compute_elt(4,d1,d2,2,2)
	g = _compute_elt(4,d1,d2,3,2)
	h = _compute_elt(4,d1,d2,4,2)

	i = _compute_elt(4,d1,d2,1,3)
	j = _compute_elt(4,d1,d2,2,3)
	k = _compute_elt(4,d1,d2,3,3)
	l = _compute_elt(4,d1,d2,4,3)

	m = _compute_elt(4,d1,d2,1,4)
	n = _compute_elt(4,d1,d2,1,4)
	o = _compute_elt(4,d1,d2,3,4)
	p = _compute_elt(4,d1,d2,4,4)

	return HMat4((a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p))
end

function Base.:*(m::HMat4,v::HVec4)
	d1 = m.data
	d2 = Tuple(v)

	a = _compute_elt(4,d1,d2,1,1)
	b = _compute_elt(4,d1,d2,2,1)
	c = _compute_elt(4,d1,d2,3,1)
	d = _compute_elt(4,d1,d2,4,1)

	return HVec4(a,b,c,d)
end

## Some Functions

function Htranspose(m::HMat2{T}) where T<:Number
	d = Tuple(m)
	return HMat2{T}(d[1],d[3],d[2],d[4])
end

function Htranspose(m::HMat3{T}) where T<:Number
	d = Tuple(m)
	return HMat3{T}(d[1],d[4],d[7],d[2],d[5],d[8],d[3],d[6],d[9])
end

function Htranspose(m::HMat4{T}) where T<:Number
	d = Tuple(m)
	return HMat4{T}(d[1],d[5],d[9],d[13],d[2],d[6],d[10],d[14],d[3],d[7],d[11],d[15],d[4],d[8],d[12],d[16])
end

Base.getindex(m::AbstractHMatrix,i::Int) = getfield(m,:data)[i]

Base.convert(::Type{HMat2{T}},m::HMat2) where T<:Number = HMat2{T}(m.data)
Base.convert(::Type{HMat3{T}},m::HMat3) where T<:Number = HMat3{T}(m.data)
Base.convert(::Type{HMat4{T}},m::HMat4) where T<:Number = HMat4{T}(m.data)

Base.length(m::HMat2) = 4
Base.length(m::HMat3) = 9
Base.length(m::HMat4) = 16

Tuple(m::AbstractHMatrix) = getfield(m,:data)

Array(m::HMat2{T}) where T<:Number = T[m.data[1] m.data[3];m.data[2] m.data[4]]
Array(m::HMat3{T}) where T<:Number = T[m.data[1] m.data[4] m.data[7];m.data[2] m.data[5] m.data[8]; m.data[3] m.data[6] m.data[9]]
Array(m::HMat4{T}) where T<:Number = T[m.data[1] m.data[5] m.data[9] m.data[13];m.data[2] m.data[6] m.data[10] m.data[14];m.data[3] m.data[7] m.data[11] m.data[15];m.data[4] m.data[8] m.data[12] m.data[16]]

function _compute_elt(n::Int,d1::Tuple,d2::Tuple,i::Int,j::Int)
	res = 0

	for k in Base.OneTo(n)
		idx1 = i + (k-1)*n
		idx2 = k + (j-1)*n
		res += d1[idx1]*d2[idx2]
	end

	return res
end

function Test()
	@time a = HVec2((1,2))
	a2 = HVec2(5,7)
	@time b = HVec3(a,4)

	@time na = normalize(a) 

	@time ma = -a
	@time pa = a + ma
	@time pa2 = a - ma
	@time pa3 = a + a2
	@time pa4 = a - a2

	println(a)
	println(b)
	println(na)

	println(ma)
	println(pa)
	println(pa2)
	println(pa3)
	println(pa4)
end

function Test2()
	@time a = HMat2((1,2,3,4))
	b = HMat2{Int}(3,4,5,6)

	@time apb = a+b
	@time axb = a*b
	println(apb)
	println(axb)
	@time t = Htranspose(axb)
	println(t)
	println(t*axb)
end

#Test()
#Test2()