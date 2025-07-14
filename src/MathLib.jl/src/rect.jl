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
	dimensions::SVector{Int, N}
	
	# Constructors #
	
	Rect(v1::SVector{T1, N}, v2::SVector{T2, N}) where {T1,T2,N} = new{promote_type(T1,T2),N}(v1, v2)
	Rect{T}(v1::SVector{<:Number, N}, v2::SVector{<:Number, N}) where {T,N} = new{T,N}(convert.(T,v1), v2)
end

const Rect2D{T} = Rect{T,2}
const Rect2Di = Rect2D{Int}
const Rect2Df = Rect2D{Float32}

Rect2Di() = Rect2Di(0,0,0,0)
Rect2Di(x::Integer,y::Integer,w::Integer,h::Integer) = Rect{Int}(Vec2(x,y),Vec2(w, h))
Rect2Di(v1::Vector2D,v2::Vector2D) = Rect{2}(v1, v2)

Rect2Df() = Rect{2}(0,0,0,0)
Rect2Df(x::Real,y::Real,w::Real,h::Real) = Rect{Float32}(Vec2(x,y),Vec2(w, h))
Rect2Df(v1::Vector2D,v2::Vector2D) = Rect2D{Float32}(v1, v2)


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

