## Vector Types ##

AnyVector{T,N} = Union{iSArray{T, Tuple{N}, 1, N},SArray{T, Tuple{N}, 1, N}}

"""
	Vec2{T} alias for SVector{T,2}

A type to define static vector with 2 element.
"""
const Vec2{T} = SVector{T,2}
Vec2(args::T...) where{T <: Any} = Vec2{T}(args...)
Vec2(x,y) = Vec2{promote_type(typeof(x),typeof(y))}(x,y)

"""
	iVec2{T} alias for iSVector{T,2}

The immutable counter part of Vec2.
"""
const iVec2{T} = iSVector{T,2}
iVec2(args::T...) where{T <: Any} = iVec2{T}(args...)
iVec2(x,y) = iVec2{promote_type(typeof(x),typeof(y))}(x,y)

"""
	Vec3{T} alias for SVector{T,3}

A type to define static vector with 3 element.
"""
const Vec3{T} = SVector{T,3}
Vec3(args::T...) where{T <: Any} = Vec3{T}(args...)
Vec3(x,y,z) = Vec3{promote_type(typeof(x),typeof(y),typeof(z))}(x,y,z)

"""
	iVec3{T} alias for iSVector{T,3}

The immutable counter part of Vec3.
"""
const iVec3{T} = iSVector{T,3}
iVec3(args::T...) where{T <: Any} = iVec3{T}(args...)
iVec3(x,y,z) = iVec3{promote_type(typeof(x),typeof(y),typeof(z))}(x,y,z)

"""
	Quat{T} alias for SVector{T,4}

A type to define static vector with 4 element.
"""
const Quat{T} = SVector{T,4}
Quat(args::T...) where{T <: Any} = Quat{T}(args...)
Quat(x,y,z,w) = Quat{promote_type(typeof(x),typeof(y),typeof(z),typeof(w))}(x,y,z,w)

"""
	iQuat{T} alias for iSVector{T,4}

The immutable counter part of Quat.
"""
const iQuat{T} = iSVector{T,4}
iQuat(args::T...) where{T <: Any} = iQuat{T}(args...)
iQuat(x,y,z,w) = Quat{promote_type(typeof(x),typeof(y),typeof(z),typeof(w))}(x,y,z,w)

"""
	Vector2D{T}

The Union of all static 2D vector(mutable and immutable included)
"""
const Vector2D{T} = Union{Vec2{T},iVec2{T}}

"""
	Vector3D{T}

The Union of all static 3D vector(mutable and immutable included)
"""
const Vector3D{T} = Union{Vec3{T},iVec3{T}}

"""
	Quaternion{T}

The Union of all static 4D vector(mutable and immutable included)
"""
const Quaternion{T} = Union{Quat{T},iQuat{T}}

"""
	VectorType{T}

The Union of all static vector for the cruise engine to use. (mutable and immutable included)
"""
const VectorType{T} = Union{Vector2D{T},Vector3D{T},Quaternion{T}}
const iVectorType{T} = Union{iVec2{T},iVec3{T},iQuat{T}}

function Base.getproperty(v::VectorType{<:Number},s::Symbol)
	if s === :x
		return getfield(v,:data)[1]
	elseif s === :y
		return getfield(v,:data)[2]
	elseif s === :z
		return getfield(v,:data)[3]
	elseif s === :w
		return getfield(v,:data)[4]
	elseif s == :data
		return getfield(v,:data)
	else
		throw(ArgumentError("VectorType don't have a $s field."))
	end
end

"""
	vangle(v::VectorType{<:Number})

Return the angle formed by the vector `v` and the x-axis.
"""
vangle(v::VectorType{<:Number}) = acos(v[1]/norm(v))

"""
	v_is_normalized(v::SVector)

Return true is the norm of `v` is 1.

# Example

```julia-repl

julia> v = Vec2(0.6,0.8)
[0.6,0.8]

julia> v_is_normalized(v)
true

```
"""
v_is_normalized(v::SVector{<:Number}) = (vnorm(v) == 1)

"""
	vdot(v1::SVector{<:Number,N},v2::SVector{<:Number,N})

Return the dot product of 2 SVector with N elements. You can also use the syntax v1 ⋅ v2 to 
compute the dot product ('⋅' is typed \\cdot and tab).

# Example

```julia-repl

julia> v1 = Vec2(3,4)
[3,4]

julia> v2 = Vec2(6,8)
[6,8]

julia> vdot(v1,v2)
50

```
"""
function vdot(v1::SVector{<:Number,N},v2::SVector{<:Number,N}) where N
	result = 0
	ax = axes(v1,1)

	for i in ax
		result += v1[i] * v2[i]
	end

	return result
end

v1::SVector{<:Number} ⋅ v2::SVector{<:Number} = vdot(v1,v2)

"""
	v_isorthogonal(v1::SVector{<:Number,N},v2::SVector{<:Number,N})

Return true if the two vector `v1` and `v2` are orthogonal else it return false.
"""
function v_isorthogonal(v1::SVector{<:Number,N},v2::SVector{<:Number,N}) where N
	return vdot(v1,v2) == 0
end

"""
	v_getproj(v1::SVector{<:Number,N},v2::SVector{<:Number,N},normalized=false)

Return the projection of `v1` on `v2`, if `normalized` is true, then the function will assume that
`v2` is normalized. You can check that a Vector is normalized with `v_is_normalized`
"""
function v_getproj(v1::SVector{<:Number,N},v2::SVector{<:Number,N}) where N
	return (vdot(v1,v2)/vnorm(v2)) * vnormalize(v2)
end

"""
	vget_angle(v1::SVector{<:Number,N},v2::SVector{<:Number,N},normalized=false)

return the angle between 2 SVector with N elements. If `normalized` is true, then the
function will assume that `v1` and `v2` are already normalized.
You can check that a Vector is normalized with `v_is_normalized`.

# Example
```julia-repl
julia> v1 = Vec3(1,-2,3)
[1,-2,3]

julia> v2 = Vec3(0,-1,2)
[0,-1,2]

julia> vget_angle(v1,v2)
0.2971225163471023
```
"""
function vget_angle(v1::SVector{<:Number,N},v2::SVector{<:Number,N},normalized=false) where N
	if !normalized
		v1 = vnormalize(v1)
		v2 = vnormalize(v2)
	end

	return acos(vdot(v1,v2))
end

"""
	vcross(v1::Vector3D{<:Number},v2::Vector3D{<:Number})

Compute the cross product of 2 vector3D.

# Example

```julia-repl

julia> v1 = Vec3(1,-2,3)
[1,-2,3]

julia> v2 = Vec3(0,-1,2)
[0,-1,2]

julia> vcross(v1,v2)
[-1, 2, -1]

```

	vcross(v1::Vector2D{<:Number},v2::Vector2D{<:Number})

# Example

```julia-repl

julia> v1 = Vec2(-1,1)
[-1,1]

julia> v2 = Vec2(0,1)
[0,1]

julia> vcross(v1,v2)
-1

```
Compute the cross product of 2 vector2D.

	v1 × v2

Can be used as shortcut for `vcross`.
"""
function vcross(v1::Vector3D{<:Number},v2::Vector3D{<:Number})
	return iVec3(v1.y * v2.z - v1.z * v2.y,
				v1.z * v2.x - v1.x * v2.z,
				v1.x * v2.y - v1.y * v2.x)
end
vcross(v1::Vector2D{<:Number},v2::Vector2D{<:Number}) = v1.x*v2.y - v1.y * v2.x
v1::VectorType{<:Number} × v2::VectorType{<:Number} = vcross(v1,v2)

vrotate(v::Vector2D,ang::Real) = Vec2{Float64}(v[1]*cos(ang) - v[2]*sin(ang), v[1]*sin(ang) + v[2]*cos(ang))
vrotated(v::Vector2D,ang::Real) = Vec2{Float64}(v[1]*cosd(ang) - v[2]*sind(ang), v[1]*sind(ang) + v[2]*cosd(ang))

"""
	vnorm_squared(v::VectorType)

Return the squared norm of a vector
"""
vnorm_squared(v::AbstractSArray{T}) where T <: Number = sum(Tuple(v) .^ 2)

"""
	vnorm(v::Vectortype)

compute the norm of a vector type.

# Example

```julia-repl

julia> a = Vec2(3,4)
[3,4]

julia> vnorm(a)
5

"""
vnorm(v::AbstractSArray{T}) where T <: Number = sqrt(sum(Tuple(v) .^ 2))

"""
	vnormalize(v::VectorType)

return the normalized vector from v.

# Example

```julia-repl

julia> v = Vec2(3,4)
[3,4]

julia> vnormalize(v)
[0.6,0.8]

```
"""
vnormalize(v::AbstractSArray{T}) where T <: Number = v/vnorm(v)
