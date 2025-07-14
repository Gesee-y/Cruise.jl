######################################################################################################################
###################################################### WORLDS ########################################################
######################################################################################################################

export RigidBody2D,RigidBody3D

####################################################### CORE #########################################################

"""
    mutable struct RigidBody2D <: AbstractBody
		inverse_mass::IReal
		position::Vec2f
		velocity::Vec2f
		angle::IReal
		matrix::Mat4f

2D rigid body. Contrary to particles which simulate a body as an aggregation of mass, a rigid body process it as a
whole unique object.
- `inverse_mass`: 1/total mas of the body.
- `position`: The position of the body in world coordinate.
- `velocity`: The velocity of the body in world coordinate.
- `angle`: The current angle of the body.
- `matrix`: A cached trasformation useful if other systems need it.
"""
mutable struct RigidBody2D <: AbstractBody
	inverse_mass::IReal
	position::Vec2f
	velocity::Vec2f
	orientation::IReal
	inverse_inertia_tensor::Mat2f
	matrix::Mat4f
end

"""
    mutable struct RigidBody3D <: AbstractBody
		inverse_mass::IReal
		position::Vec3f
		velocity::Vec3f
		rotation::Vec3f
		orientation::Quatf
		matrix::Mat4f

3D rigid body. Contrary to particles which simulate a body as an aggregation of mass, a rigid body process it as a
whole unique object.
- `inverse_mass`: 1/total mas of the body.
- `position`: The position of the body in world coordinate.
- `velocity`: The velocity of the body in world coordinate.
- `rotation`: The angular velocity of the body in world coodinate.
- `orientation`: The current angle of the body, represented as a `Quaternion`.
- `matrix`: A cached trasformation useful if other systems need it.
"""
mutable struct RigidBody3D <: AbstractBody
	inverse_mass::IReal
	position::Vec3f
	velocity::Vec3f
	rotation::Vec3f
	orientation::Quatf
	inverse_inertia_tensor::Mat3f
	matrix::Mat4f
end

################################################# FUNCTIONS #########################################################

function calculateDerivedData(r::AbstractBody)
	r.matrix = _calculate_matrix(r.position, r.orientation)
end

function _to_global_basis(t::Mat4f,lm::Mat4f)
	tdata = t.data
	localdata = l.data
	t4 = tdata[1]*localdata[1]+tdata[2]*localdata[4]+tdata[3]*localdata[7]
	t9 = tdata[1]*localdata[2]+tdata[2]*localdata[5]+tdata[3]*localdata[8]
	t14 = tdata[1]*localdata[3]+tdata[2]*localdata[6]+tdata[3]*localdata[9]
	t28 = tdata[5]*localdata[1]+tdata[6]*localdata[4]+tdata[7]*localdata[7]
	t33 = tdata[5]*localdata[2]+tdata[6]*localdata[5]+tdata[7]*localdata[8]
	t38 = tdata[5]*localdata[3]+rotmat.data[6]*localdata[6]+rotmat.data[7]*localdata[9]
    t52 = rotmat.data[9]*localdata[1]+rotmat.data[10]*localdata[4]+rotmat.data[11]*localdata[7]
    t57 = rotmat.data[9]*localdata[2]+rotmat.data[10]*localdata[5]+rotmat.data[11]*localdata[8]
    t62 = rotmat.data[9]*localdata[3]+rotmat.data[10]*localdata[6]+rotmat.data[11]*localdata[9]

    return Mat4f(
    	t4*tdata[1]+t9*tdata[2]+t14*tdata[3],
		t4*tdata[5]+t9*tdata[6]+t14*tdata[7],
		t4*tdata[9]+t9*tdata[10]+t14*tdata[11],
		t28*tdata[1]+t33*tdata[2]+t38*tdata[3],
		
		t28*tdata[5]+t33*tdata[6]+t38*tdata[7],
		t28*tdata[9]+t33*tdata[10]+t38*tdata[11],
		t52*tdata[1]+t57*tdata[2]+t62*tdata[3],
		t52*tdata[5]+t57*tdata[6]+t62*tdata[7],
		
		t52*tdata[9]+t57*tdata[10]+t62*tdata[11]
    	0.0,
    	0.0,
    	0.0,
    	
    	0.0,
    	0.0,
    	0.0,
    	0.0)
end

"""
    setinvinertia(r::AbstractBody, inertia::SMatrix)

The the inverse inertia of a rigid body `r` given an inertia tensor,
"""
setinvinertia(r::AbstractBody, inertia::SMatrix) = setfield!(e, :inverse_inertia_tensor, vinvert_mat(inertia))
