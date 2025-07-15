## Some function for the Rects type ##

"""
	mutable struct Rect2D
		x :: Int
		y :: Int

		# The Rect dimension
		w :: Int
		h :: Int
"""
mutable struct Rect{T, N}
	origin::SVector{T, N}
	dimensions::SVector{T, N}
	
	# Constructors #
	
	Rect(v1::SVector{T1, N}, v2::SVector{T2, N}) where {T1,T2,N} = new{promote_type(T1,T2),N}(v1, v2)
	Rect{T}(v1::SVector{<:Number, N}, v2::SVector{<:Number, N}) where {T,N} = new{T,N}(convert.(T,v1), v2)
	Rect{T,N}(v1::SVector{T, N}, v2::SVector{T, N}) where {T,N} = new{T,N}(convert.(T,v1), v2)
end

const Rect2D{T} = Rect{T,2}
const Rect2Di = Rect2D{Int}
const Rect2Df = Rect2D{Float32}

Rect2Di() = Rect2Di(0,0,0,0)
Rect2Di(x::Integer,y::Integer,w::Integer,h::Integer) = Rect{Int}(Vec2i(x,y),Vec2i(w, h))

Rect2Df() = Rect{2}(0,0,0,0)
Rect2Df(x::Real,y::Real,w::Real,h::Real) = Rect{Float32}(Vec2f(x,y),Vec2f(w, h))

const Rect3D{T} = Rect{T,3}
const Rect3Di = Rect3D{Int}
const Rect3Df = Rect3D{Float32}

Rect3Di() = Rect3Di(0,0,0,0)
Rect3Di(x::Integer,y::Integer,w::Integer,h::Integer) = Rect{Int}(Vec3i(x,y),Vec3i(w, h))
Rect3Di(v1::Vector3D,v2::Vector3D) = Rect{3}(v1, v2)

Rect3Df() = Rect{3}(0,0,0,0)
Rect3Df(x::Real,y::Real,z::Real,w::Real,h::Real,d::Real) = Rect{Float32}(Vec3f(x,y,z),Vec3f(w,h,d))
Rect3Df(v1::Vector3D,v2::Vector3D) = Rect3D{Float32}(v1, v2)


function Base.getproperty(r::Rect2D, s::Symbol)
	if s === :x
		return r.origin.x
	elseif s === :y
		return r.origin.y
	elseif s === :w
		return r.dimensions.x
	elseif s === :h
		return r.dimensions.y
	elseif s === :origin
		return getfield(r, :origin)
	elseif s === :dimensions
		return getfield(r, :dimensions)
	else
		error("Rect2D doesn't have a field $s.")
	end
end
Base.getindex(r::Rect2D, i::Int) = getproperty(r, (:x,:y,:w,:h)[i])

function get_center(r::Rect2D)
	return iVec2(r.x+r.w/2, r.y+r.h/2)
end

