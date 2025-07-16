## Matrix Types ##

const Mat2{T} = SMatrix{T,2,2,4}
const iMat2{T} = iSMatrix{T,2,2,4}
const Mat2i = Mat2{Int}
const Mat2f = Mat2{Float32}
const iMat2i = iMat2{Int}
const iMat2f = iMat2{Float32}
const Matrix2D{T} = Union{Mat2{T}, iMat2{T}}

const Mat3{T} = SMatrix{T,3,3,9}
const iMat3{T} = iSMatrix{T,3,3,9}
const Mat3i = Mat3{Int}
const Mat3f = Mat3{Float32}
const iMat3i = iMat3{Int}
const iMat3f = iMat3{Float32}
const Matrix3D{T} = Union{Mat3{T}, iMat3{T}}

const Mat4{T} = SMatrix{T,4,4,16}
const iMat4{T} = iSMatrix{T,4,4,16}
const Mat4i = Mat4{Int}
const Mat4f = Mat4{Float32}
const iMat4i = iMat4{Int}
const iMat4f = iMat4{Float32}
const Matrix4D{T} = Union{Mat4{T}, iMat4{T}}

const MatrixType{T} = Union{Matrix2D{T}, Matrix3D{T}, Matrix4D{T}}

"""
	vdet(m::Matrix2D)

compute the determinant of a 2x2 matrix

	vdet(m::Matrix3D)

compute the determinant of a 3x3 matrix
"""
vdet(m::StaticMatrix{T,1,1}) where T<:Number = m[1]
vdet(m::Matrix2D) = m[1] * m[4] - m[2] * m[3]
vdet(m::Matrix3D) = begin
	d1 = m[5] * m[9] - m[6] * m[8]
	d2 = m[4] * m[9] - m[7] * m[6]
	d3 = m[4] * m[8] - m[5] * m[7]

	return m[1] * d1 - m[2] * d2 + m[3] * d3
end
function vdet(m::Matrix4D)
    data = m.data
    return data[1] * data[6] * data[11] * data[16] -
           data[1] * data[6] * data[12] * data[15] -
           data[1] * data[10] * data[7] * data[16] +
           data[1] * data[10] * data[8] * data[15] +
           data[1] * data[14] * data[7] * data[12] -
           data[1] * data[14] * data[8] * data[11] -
           data[5] * data[2] * data[11] * data[16] +
           data[5] * data[2] * data[12] * data[15] +
           data[5] * data[10] * data[3] * data[16] -
           data[5] * data[10] * data[4] * data[15] -
           data[5] * data[14] * data[3] * data[12] +
           data[5] * data[14] * data[4] * data[11] +
           data[9] * data[2] * data[7] * data[16] -
           data[9] * data[2] * data[8] * data[15] -
           data[9] * data[6] * data[3] * data[16] +
           data[9] * data[6] * data[4] * data[15] +
           data[9] * data[14] * data[3] * data[8] -
           data[9] * data[14] * data[4] * data[7] -
           data[13] * data[2] * data[7] * data[12] +
           data[13] * data[2] * data[8] * data[11] +
           data[13] * data[6] * data[3] * data[12] -
           data[13] * data[6] * data[4] * data[11] -
           data[13] * data[10] * data[3] * data[8] +
           data[13] * data[10] * data[4] * data[7]
end

"""
	vinvert_mat(m::Matrix2D{T})

Get the inverse matrix of a matrix `m`. The precision is increased if `T` is an `Integer`
"""
Base.@propagate_inbounds vinvert_mat(m::Matrix2D{T}) where T <: Integer = (Mat2{T}(m[4], -m[2], -m[3], m[1])/vdet(m))
Base.@propagate_inbounds vinvert_mat(m::Matrix2D{T}) where T <: Number = Mat2{T}(m[4], -m[2], -m[3], m[1])/vdet(m)
Base.@propagate_inbounds function vinvert_mat(m::Matrix3D)
	d = vdet(m)
	d==0 && error("The matrice is not invertible.")
	det = 1/d
	data = m.data

	t4 = data[1]*data[5]
	t6 = data[1]*data[6]
	t8 = data[2]*data[4]
	t10 = data[3]*data[4]
	t12 = data[2]*data[7]
	t14 = data[3]*data[7]

	return Mat3{Float32}(
		(data[5]*data[9]-data[6]*data[8])*det,
		-(data[2]*data[9]-data[3]*data[8])*det,
		(data[2]*data[6]-data[3]*data[5])*det,
		-(data[4]*data[9]-data[6]*data[7])*det,
		(data[1]*data[9]-t14)*det,
		-(t6-t10)*det,
		(data[4]*data[8]-data[5]*data[7])*det,
		-(data[1]*data[8]-t12)*det,
		(t4-t8)*det
		)
end
function vinvert_mat(m::Matrix4D)
    data = m.data
    inv = zeros(Float32, 16)

    inv[1] = data[6]*data[11]*data[16] - data[6]*data[12]*data[15] - data[10]*data[7]*data[16] + data[10]*data[8]*data[15] + data[14]*data[7]*data[12] - data[14]*data[8]*data[11]
    inv[2] = -data[2]*data[11]*data[16] + data[2]*data[12]*data[15] + data[10]*data[3]*data[16] - data[10]*data[4]*data[15] - data[14]*data[3]*data[12] + data[14]*data[4]*data[11]
    inv[3] = data[2]*data[7]*data[16] - data[2]*data[8]*data[15] - data[6]*data[3]*data[16] + data[6]*data[4]*data[15] + data[14]*data[3]*data[8] - data[14]*data[4]*data[7]
    inv[4] = -data[2]*data[7]*data[12] + data[2]*data[8]*data[11] + data[6]*data[3]*data[12] - data[6]*data[4]*data[11] - data[10]*data[3]*data[8] + data[10]*data[4]*data[7]

    inv[5] = -data[5]*data[11]*data[16] + data[5]*data[12]*data[15] + data[9]*data[7]*data[16] - data[9]*data[8]*data[15] - data[13]*data[7]*data[12] + data[13]*data[8]*data[11]
    inv[6] = data[1]*data[11]*data[16] - data[1]*data[12]*data[15] - data[9]*data[3]*data[16] + data[9]*data[4]*data[15] + data[13]*data[3]*data[12] - data[13]*data[4]*data[11]
    inv[7] = -data[1]*data[7]*data[16] + data[1]*data[8]*data[15] + data[5]*data[3]*data[16] - data[5]*data[4]*data[15] - data[13]*data[3]*data[8] + data[13]*data[4]*data[7]
    inv[8] = data[1]*data[7]*data[12] - data[1]*data[8]*data[11] - data[5]*data[3]*data[12] + data[5]*data[4]*data[11] + data[9]*data[3]*data[8] - data[9]*data[4]*data[7]

    inv[9] = data[5]*data[10]*data[16] - data[5]*data[12]*data[14] - data[9]*data[6]*data[16] + data[9]*data[8]*data[14] + data[13]*data[6]*data[12] - data[13]*data[8]*data[10]
    inv[10] = -data[1]*data[10]*data[16] + data[1]*data[12]*data[14] + data[9]*data[2]*data[16] - data[9]*data[4]*data[14] - data[13]*data[2]*data[12] + data[13]*data[4]*data[10]
    inv[11] = data[1]*data[6]*data[16] - data[1]*data[8]*data[14] - data[5]*data[2]*data[16] + data[5]*data[4]*data[14] + data[13]*data[2]*data[8] - data[13]*data[4]*data[6]
    inv[12] = -data[1]*data[6]*data[12] + data[1]*data[8]*data[10] + data[5]*data[2]*data[12] - data[5]*data[4]*data[10] - data[9]*data[2]*data[8] + data[9]*data[4]*data[6]

    inv[13] = -data[5]*data[10]*data[15] + data[5]*data[11]*data[14] + data[9]*data[6]*data[15] - data[9]*data[7]*data[14] - data[13]*data[6]*data[11] + data[13]*data[7]*data[10]
    inv[14] = data[1]*data[10]*data[15] - data[1]*data[11]*data[14] - data[9]*data[2]*data[15] + data[9]*data[3]*data[14] + data[13]*data[2]*data[11] - data[13]*data[3]*data[10]
    inv[15] = -data[1]*data[6]*data[15] + data[1]*data[7]*data[14] + data[5]*data[2]*data[15] - data[5]*data[3]*data[14] - data[13]*data[2]*data[7] + data[13]*data[3]*data[6]
    inv[16] = data[1]*data[6]*data[11] - data[1]*data[7]*data[10] - data[5]*data[2]*data[11] + data[5]*data[3]*data[10] + data[9]*data[2]*data[7] - data[9]*data[3]*data[6]

    det = data[1]*inv[1] + data[2]*inv[5] + data[3]*inv[9] + data[4]*inv[13]
    det == 0 && error("Matrix is not invertible")

    inv = inv ./ det
    return Mat4{Float32}(Tuple(inv))
end

vinvert_mat(m::MatrixType{T}) where T <: Integer = Rational.(Stranspose(adjoint_mat(m)),vdet(m))
vinvert_mat(m::MatrixType{T}) where T <: Number = Stranspose(adjoint_mat(m))/vdet(m)

function linear3D_solve(m::StaticMatrix{T,4,3}) where T <: Number
	if m[1] <= 0
		if abs(m[2,1]) > 0
			
		end
	end
end

function _get_minor_matrix(m::StaticMatrix{T,M,M};k=1,i=1) where{T<:Number,M}
	mat = SMatrix{T, M-1, M-1, (M-1)^2}(undef)
	for i2 in 1:M
		if i2 != k
			col = (i2 > k) ? i2-1 : i2
			for j in 1:M
				if j != i
					row = (j > i) ? j-1 : j
					mat[col,row] = m[i2,j]
				end
			end
		end
	end

	return mat
end

function adjoint_mat(m::StaticMatrix{T,M,M}) where{T<:Number,M}
	mat = SMatrix{T, M, M, M^2}(undef)

	for i in 1:M
		for j in 1:M
			mat[i,j] = (-1)^(i+j) * vdet(_get_minor_matrix(m;k=i,i=j))
		end
	end

	return mat
end

function Stranspose(m::Matrix2D{T}) where T
	data = m.data
	return Mat2{T}((data[1],data[3],data[2],data[4]))
end
function Stranspose(m::Matrix3D{T}) where T
	data = m.data
	return Mat3{T}((data[1],data[4],data[7],data[2],data[5], data[8], data[3], data[6], data[9]))
end
function Stranspose(m::Matrix4D{T}) where T
    data = m.data
    return Mat4{T}((
        data[1], data[5], data[9],  data[13],
        data[2], data[6], data[10], data[14],
        data[3], data[7], data[11], data[15],
        data[4], data[8], data[12], data[16]
    ))
end

function to_mat3(q::Quaternion)
	return Mat3{Float32}(
		1 - (2*q.y*q.y + 2*q.z*q.z),
		2*q.x*q.y + 2*q.z*q.w,
		2*q.x*q.z - 2*q.y*q.w,
		2*q.x*q.y - 2*q.z*q.w,
		1 - (2*q.x*q.x + 2*q.z*q.z),
		2*q.y*q.z + 2*q.x*q.w,
		2*q.x*q.z + 2*q.y*q.w,
		2*q.y*q.z - 2*q.x*q.w,
		1 - (2*q.x*q.x + 2*q.y*q.y)
		)
end
function to_mat4(q::Quaternion,pos::Vector3D)
	return Mat4{Float32}(
		1 - (2*q.y*q.y + 2*q.z*q.z),
		2*q.x*q.y + 2*q.z*q.w,
		2*q.x*q.z - 2*q.y*q.w,
		pos.x,
		2*q.x*q.y - 2*q.z*q.w,
		1 - (2*q.x*q.x + 2*q.z*q.z),
		2*q.y*q.z + 2*q.x*q.w,
		pos.y,
		2*q.x*q.z + 2*q.y*q.w,
		2*q.y*q.z - 2*q.x*q.w,
		1 - (2*q.x*q.x + 2*q.y*q.y),
		pos.z,
		0,0,0,1
		)
end

function invtransform(m::Matrix2D, v::Vector2D)
	data = m.data
	vdata = v.data
	return iVec2f(vdata[1]*data[4]-vdata[2]*data[3], -vdata[1]*data[2]+vdata[2]*data[1])
end

function invtransform(m::Matrix4D, v::Vector3D)
	x,y,z = v.data
	data = m.data
	x -= data[4]
	y -= data[8]
	z -= data[12]
	return iVec3f(
		x * data[1] +
		y * data[5] +
		z * data[9],

		x * data[2] +
		y * data[6] +
		z * data[10],

		x * data[3] +
		y * data[7] +
		z * data[11]
	)
end
function invtransform(m::Matrix4D, v::Quaternion)
	x,y,z,w = v.data
	data = m.data
	x -= data[4]
	y -= data[8]
	z -= data[12]
	return iQuatf(
		x * data[1] +
		y * data[5] +
		z * data[9],

		x * data[2] +
		y * data[6] +
		z * data[10],

		x * data[3] +
		y * data[7] +
		z * data[11],
		w
	)
end

function invtransformdir(m::Matrix4D, v::Vector3D)
    x, y, z = v.data
    data = m.data
    return iVec3f(
        x * data[1] + y * data[5] + z * data[9],
        x * data[2] + y * data[6] + z * data[10],
        x * data[3] + y * data[7] + z * data[11]
    )
end

function transformdir(m::Matrix4D, v::Vector3D)
    x, y, z = v.data
    data = m.data
    return iVec3f(
        x * data[1] + y * data[2] + z * data[3],
        x * data[5] + y * data[6] + z * data[7],
        x * data[9] + y * data[10] + z * data[11]
    )
end
