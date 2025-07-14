######################################################################################################################
############################################## INTERACTION PHYSIC ENGINE #############################################
######################################################################################################################

module Interactions

include(joinpath("..","..","MathLib.jl","src","MathLib.jl"))

const IReal = Float32

# `i` stands for "immutable" not "int" but `f` stands for `float`
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
export vnorm, vnormalize, vnarmalize_and_norm, add_scaled, quat_mul, rotateby, vreflect
export vdet, vinvert_mat, adjoint_mat, Stranspose, to_mat3, to_mat4, invtransform, invtransformdir, transformdir
export set_basis, update_transform_matrix!, get_transform_matrix, ortho_mat, persp_mat, parrallel_obl_mat, persp_obl_mat
export get_center, get_as_range
export bipolar_distance, ToCartesian
# TODO: Migrate this to the physic engine
export point_in_rect, overlapping
export AbstractBody

"""
    abstract type AbstractBody

Supertype for every type of body.
"""
abstract type AbstractBody end

include("particule.jl")
include("interfaces.jl")
include("forces.jl")
include("contacts.jl")
include("constraints.jl")

end # module