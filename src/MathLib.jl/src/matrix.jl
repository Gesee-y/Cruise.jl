## Matrix Types ##

const Mat2{T} = SMatrix{T,2,2,4}
const iMat2{T} = iSMatrix{T,2,2,4}
const Matrix2D{T} = Union{Mat2{T}, iMat2{T}}

const Mat3{T} = SMatrix{T,3,3,9}
const iMat3{T} = iSMatrix{T,3,3,9}
const Matrix3D{T} = Union{Mat3{T}, iMat3{T}}

const Mat4{T} = SMatrix{T,4,4,16}
const iMat4{T} = iSMatrix{T,4,4,16}
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
	
end

"""
	vinvert_mat(m::Matrix2D{T})

Get the inverse matrix of a matrix `m`. The precision is increased if `T` is an `Integer`
"""
vinvert_mat(m::Matrix2D{T}) where T <: Integer = Rational.(Mat2{T}(m[4], -m[2], -m[3], m[1]),vdet(m))
vinvert_mat(m::Matrix2D{T}) where T <: Number = Mat2{T}(m[4], -m[2], -m[3], m[1])/vdet(m)
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