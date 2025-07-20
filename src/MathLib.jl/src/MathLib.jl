module MathLib

# `i` stands for "immutable" not "int" but `f` stands for `float`
export StaticVector, SMatrix, iSMatrix, SVector, iSVector
export iVec2, Vec2, iVec3, Vec3, iQuat, Quat, Vector2D, Vector3D, Quaternion, VectorType, iVectorType
export iVec2i, iVec2f, Vec2i, Vec2f, iVec3i, iVec3f, Vec3i, Vec3f, iQuati, iQuatf, Quati, Quatf
export iMat2, Mat2, Mat2i, Mat2f, iMat2i, iMat2f, iMat3, Mat3, Mat3i, Mat3f, iMat3i, iMat3f
export iMat4, Mat4, Mat4i, Mat4f, iMat4i, iMat4f, Matrix2D, Matrix3D, Matrix4D, MatrixType
export VectorSpace, Space2D, Space3D, Transform, Transform2D, Transform3D
export Rect, Rect2D, Rect2Di, Rect2Df, Circle
export Ray
export RGB, iRGB, fRGB, ifRGB, RGBA, iRGBA, fRGBA, ifRGBA
export RED, GREEN, BLUE, WHITE, BLACK, GRAY
export CoordinateSystem, ColorSpace, CartesianCoord, PolarCoord, BipolarCoord, CylindricalCoord, SphericalCoord
export vangle, v_is_normalized, vdot, v_isorthogonal, v_getproj, v_get_angle, vcross, vrotate, vrotated, vnorm_squared
export vnorm, vnormalize, vnormalize_and_norm, add_scaled, quat_mul, rotateby, vreflect
export vdet, vinvert_mat, adjoint_mat, Stranspose, to_mat3, to_mat4, invtransform, invtransformdir, transformdir
export set_basis, update_transform_matrix!, get_transform_matrix, ortho_mat, persp_mat, parrallel_obl_mat, persp_obl_mat
export get_center, get_as_range, to_global_basis
export bipolar_distance, ToCartesian
# TODO: Migrate this to the physic engine
export point_in_rect, overlapping
export wrap, posmod, lerp, inverse_lerp


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
include("circle.jl")
include("collision.jl")

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

end # module