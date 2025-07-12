## A mathematics library for the engine ##
include("..\\..\\StaticObjects.jl\\src\\StaticObjects.jl")

# using .StaticObjects

using LinearAlgebra

include("vectors.jl")
include("matrix.jl")
include("Coordinate/coordinate_system.jl")

include("colors.jl")
include("rays.jl")
include("rect.jl")

"""
	nroot(n)

compute the n root of n.
"""

function nroot(n::Real,a::Real)
	xi :: Float64 = 1
	for i in 1:20
		xi = (xi^(n-1) + a/(xi^(n-1)))/n
	end

	return xi
end

## ----------------- Number OP ----------------- ##

posmod(x::Number,m::Number) = if (x % m < 0) m + x % m else x % m end

Base.clamp(v1::SVector{<:Number, T}, v2::SVector{<:Number, T}, v3::SVector{<:Number, T}) where T = SVector{Number, T}(clamp.(v1, v2, v3))

wrap(x::Number,s::Number,e::Number) = s + posmod(x-s,e-s+1)
wrap(x::Number,r::AbstractUnitRange) = r.start + posmod(x-r.start,r.stop-r.start+1)

lerp(s::Number,e::Number,t::Number) = (s + t*(e-s))
inverse_lerp(s::Number,e::Number,x::Number) = (x-s)/(e-s)

include("transformations.jl")

## ----------- Test ------------ #
#using InteractiveUtils

function compute(n)

	a = Vec3(1,2,6)
	b = Vec3(6,7,4)

	for _ = 1:n
		a = (a + b) + b
	end

	return a[1],a[2]
end

function main()
	@time t = Transform2D()
	@time a = update_transform_matrix(t)
	t.angle = pi/2.0
	t.position[1] = 5
	t.position[2] = 5
	t.scale[1] = 2
	@time a = update_transform_matrix(t)
	println(a)
	@time t * Vec2(1,0)
	@time c = t * Vec2(1,0)
	println(c)
	println(t)
end

#main()