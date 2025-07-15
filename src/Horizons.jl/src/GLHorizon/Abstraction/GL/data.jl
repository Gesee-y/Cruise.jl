# Defines simple data types used by GL

# GLFW Vsync settings
@bp_enum(VsyncModes,
    off = 0,
    on = 1,
    adaptive = -1
)
export VsyncModes, E_VsyncModes

#=
Whether to ignore polygon faces that are pointing away from the camera
    (or towards the camera, in "Backwards" mode).
=#
@bp_gl_enum(FaceCullModes::GLenum,
    off       = GL_INVALID_ENUM,
    on        = GL_BACK,
    backwards = GL_FRONT,
    all       = GL_FRONT_AND_BACK
)
export FaceCullModes, E_FaceCullModes


# Define conversions from ImageIO pixels to data that GL understands.

"Converts an incoming pixel of an `ImageIO` image into GPU-friendly pixel data of the given type"
convert_pixel(input, Output::Type)::Output = error("Can't convert a ", typeof(input), " into a ", Output)

# Identity conversion:
convert_pixel(u::U, ::Type{U}) where {U} = u

# Convert unsigned into signed by effectively subtracting half the range.
convert_pixel(u::U, I::Type{<:Signed}) where {U<:Unsigned} = (I == signed(U)) ?
                                                                 typemax(signed(U)) + reinterpret(signed(U), u) + one(signed(U)) :
                                                                 error(I, " isn't the signed version of ", U)
# Fixed-point already is an unsigned format, just need to reinterpret it.
convert_pixel(u::N0f8, I::Type{<:Union{Int8, UInt8}}) = convert_pixel(reinterpret(u), I)

# Take whatever subset of color channels the user desires.
convert_pixel(p_in::Colorant, T::Type{<:Union{Int8, UInt8}}) = convert_pixel(red(p_in), T)
convert_pixel(p_in::Colorant, T::Type{<:Vec2{I}}) where {I<:Union{Int8, UInt8}} = T(convert_pixel(red(p_in), I),
                                                                                    convert_pixel(green(p_in), I))
convert_pixel(p_in::Colorant, T::Type{<:Vec3{I}}) where {I<:Union{Int8, UInt8}} = T(convert_pixel(red(p_in), I),
                                                                                    convert_pixel(green(p_in), I),
                                                                                    convert_pixel(blue(p_in), I))
convert_pixel(p_in::Colorant, T::Type{<:Vec4{I}}) where {I<:Union{Int8, UInt8}} = T(convert_pixel(red(p_in), I),
                                                                                    convert_pixel(green(p_in), I),
                                                                                    convert_pixel(blue(p_in), I),
                                                                                    convert_pixel(alpha(p_in), I))
export convert_pixel