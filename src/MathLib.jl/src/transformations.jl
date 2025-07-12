## Here we will manage transformations ##


"""
	mutable struct VectorSpace{N}
		matrix :: StaticMatrix{Real,N,N}

A struct representing a Vector space. useful for transformations

	VectorSpace{N}()

Create a new empty N dimensional vector space.
"""
mutable struct VectorSpace{N,T}
	matrix :: StaticMatrix{T,N,N}

	## Constructors ##

	@noinline VectorSpace{N,T}() where {N,T<:Number} = new{N,T}()
end

"""
	Space2D{T} = VectorSpace{2,T}

An alias for 2D spaces
"""
const Space2D{T} = VectorSpace{2,T}

"""
	Space3D{T} = VectorSpace{3,T}

An alias for 3D spaces
"""
const Space3D{T} = VectorSpace{3,T}

"""
	mutable struct Transform{N}
		space :: VectorSpace{N,Float64}
		position :: SVector{Float32,N}
		angle :: Float64
		rotation_axis::Vec3{Float32}
		scale :: SVector{Float32,N}
		matrix :: Mat4{Float32}

Structure representing transformations. `space` is the vector space in which the transformation
occur, `position` is the emplacement of the object relatively to his space

	Transform{N}()

Create a new N dimensional transformation.
"""
mutable struct Transform{N}
	space :: VectorSpace{N,Float64}
	position :: SVector{Float32,N}
	angle :: Float64
	rotation_axis::Vec3{Float32}
	scale :: SVector{Float32,N}
	matrix :: Union{Mat4{Float32},iMat4{Float32}}

	Transform{N}() where N = begin
		vs = VectorSpace{N,Float64}()
		pos = SVector{Float32,N}(Float32(0))
		angle = 0.0
		scale = SVector{Float32,N}(Float32(1))

		new{N}(vs, pos, angle, Vec3{Float32}(1,1,1), scale)
	end
end

function Transform2D()
	t = Transform{2}()
	t.rotation_axis = Vec3{Float32}(0,0,1)
	set_basis(t,Vec2(1,0),Vec2(0,1))

	return t
end

function Transform3D()
	t = Transform{3}()
	t.rotation_axis = Vec3{Float32}(1,1,1)
	set_basis(t,Vec3(1,0,0),Vec3(0,1,0),Vec3(0,0,1))

	return t
end

#precompile(Transform2D, ())

#const Transform3D = Transform{3}

@inline function set_basis(v::VectorSpace{N,T},args::Vararg{StaticVector{<:Number,N},N}) where {N,T}
	if N == 2
		v1 = args[1]
		v2 = args[2]

		mat = Mat2{T}(v1[1], v1[2], v2[1], v2[2])
		vdet(mat) != 0 && (v.matrix = Mat2{T}(v1[1], v1[2], v2[1], v2[2]))

		return
	else
		mat = SMatrix{T,N,N,N^2}((args...)...)

		if vdet(mat) != 0
			v.matrix = mat
		end
	end
end

@inline set_basis(t::Transform{N},args::Vararg{SVector{<:Number,N},N}) where N = set_basis(t.space,args...)

@inline Base.:*(vs::VectorSpace{N}, v::StaticVector{<:Number,N}) where N = vs.matrix * v
Base.:*(t::Transform{2}, v::StaticVector{T,2}) where{T<:Number} = begin
	re = get_transform_matrix(t) * iQuat{T}(v[1],v[2],0,1)
	return iVec2(re[1],re[2])
end
Base.:*(t::Transform{3}, v::StaticVector{T,3}) where{T<:Number} = begin
	re = get_transform_matrix(t) * iQuat{T}(v[1],v[2],v[3],1)
	return iVec3(re[1],re[2],re[3])
end
Base.:*(t::Transform{N}, v::StaticVector{T,N}) where{T<:Number,N} = get_transform_matrix(t) * iQuat{T}(v[1],v[2],v[3],v[4])

function update_transform_matrix!(t;pos=true,rot=true,scale=true)
	position = t.space * t.position

	m1 = pos ? _get_translation_mat(position) : 1
	m2 = rot ? _get_rotation_matrix(t.angle,t.rotation_axis) : 1
	m3 = scale ? _get_scale_matrix(t.scale) : 1

	#t.matrix = m3 * m2 * m1
	t.matrix = m1 * m2 * m3
end

get_transform_matrix(t::Transform) = getfield(t,:matrix)

## --------- Tranformation Matrix ---------- ##
# i stand for "initial"
# f stand for "final"
# w stand for "width"
# h stand for "height"
# d stand for "depth"
##

function ortho_mat(iw::Real, fw::Real, ih::Real, fh::Real, id::Real, fd::Real)
	dW = fw-iw
	dH = fh-ih
	dD = fd-id

	return iMat4{Float32}(2/dW,0,0,-(fw+iw)/dW,
				0,2/dH,0,-(fh+ih)/dH,
				0,0,2/dD,-(fd+id)/dD,
				0,0,0,1)
end

function persp_mat(fov::Real,ratio::Real,near::Real,far::Real;degree=false)
	cal_cot = cot
	if (degree) cal_cot = cotd end

	d = cal_cot(fov/2)

	A = d/ratio
	B = (near+far)/(near-far)
	C = (2near*far)/(near-far)

	return iMat4{Float32}(A,0,0,0,
				0,d,0,0,
				0,0,B,-1,
				0,0,C,0)
end

function parallel_obl_mat(iw::Real, fw::Real, ih::Real, fh::Real, id::Real, fd::Real)
	dW = fw-iw
	dH = fh-ih
	dD = fd-id

	return iMat4{Float32}(2/dW,0,1/dW,-(fw+iw-id)/(dW),
				0,2/dH,1/dH,-(fh+ih-id)/(dH),
				0,0,-2/dD,-(id+fd)/dD,
				0,0,0,1)
end

function persp_obl_mat(iw::Real, fw::Real, ih::Real, fh::Real, id::Real, fd::Real)
	dW = fw-iw
	dH = fh-ih
	dD = fd-id

	return iMat4{Float32}(2id/dW,0,(iw+fw)/dW,0,
				0,2id/dH,(ih+fh)/dH,0,
				0,0,(id+fd)/dD,2(id*fd)/dD,
				0,0,-1,0)
end

_get_translation_mat(position::Vector2D) = iMat4{Float32}(1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			position[1],position[2],0,1)
_get_translation_mat(position::Vector3D) = iMat4{Float32}(1,0,0,0
			,0,1,0,0,
			0,0,1,0,
			position[1],position[2],position[3],1)

function _get_rotation_matrix(angle::Real,axis::Vector3D,deg=false)

	axis = vnormalize(axis)

	sin_fn = deg ? sind : sin
	cos_fn = deg ? cosd : cos

	si = sin_fn(angle)
	co = cos_fn(angle)

	cst = 1.0 - co
	
	x = axis.x
	y = axis.y
	z = axis.z

	return iMat4{Float32}(
			(co + (x ^ 2) * cst), (x * y * cst - z * si), (x * z * cst + y * si), 0.0,
			(x * y * cst + z * si), (co + (y ^ 2) * cst), (z * y * cst - x* si), 0.0,
			(x * z * cst - y * si), (z * y * cst + x * si), (co + (z ^ 2) * cst), 0.0,
			0.0,0.0,0.0,1.0
		)
end

@noinline function _get_scale_matrix(scale::Vec2)
	iMat4{Float32}(scale[1],0.0,0.0,0.0,
		0.0,scale[2],0.0,0.0,
		0.0,0.0,1.0,0.0,
		0.0,0.0,0.0,1.0)
end

function _get_scale_matrix(scale::Vec3)
	iMat4{Float32}(scale[1],0.0,0.0,0.0,
		0.0,scale[2],0.0,0.0,
		0.0,0.0,scale[3],0.0,
		0.0,0.0,0.0,1.0)
end