## Some function for the Rects type ##

"""
	mutable struct Rect2D
		x :: Int
		y :: Int

		# The Rect dimension
		w :: Int
		h :: Int
"""
mutable struct Rect{T}
	origin::SVector{Int, T}
	dimensions::SVector{Int, T}
	
	# Constructors #
	
	Rect(v1::SVector{Int, T}, v2::SVector{Int, T}) where T = new{T}(v1, v2)
end

const Rect2D = Rect{2}

Rect2D() = Rect{2}(0,0,0,0)
Rect2D(x::Integer,y::Integer,w::Integer,h::Integer) = Rect{2}(x,y,w, h,)
Rect2D(v1::Vector2D,v2::Vector2D) = Rect{2}(v1, v2)

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

function get_center(r::Rect2D)
	return iVec2(r.x+r.w/2, r.y+r.h/2)
end

