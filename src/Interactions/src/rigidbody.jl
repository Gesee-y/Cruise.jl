######################################################################################################################
###################################################### WORLDS ########################################################
######################################################################################################################

export RigidBody2D,RigidBody3D

####################################################### CORE #########################################################

"""
    mutable struct RigidBody2D <: RigidBody{N}
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
mutable struct RigidBody2D <: RigidBody{2}
	inverse_mass::IReal
	position::Vec2f
	velocity::Vec2f
	orientation::IReal
	inverse_inertia_tensor::Mat2f
	matrix::Mat4f
end

"""
    mutable struct RigidBody3D <: RigidBody
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
mutable struct RigidBody3D <: RigidBody{3}
	inverse_mass::IReal
	position::Vec3f
	velocity::Vec3f
	rotation::Vec3f
	acceleration::Vec3f
	orientation::Quatf
	forceAccum::Vec3f
	torquAccum::Vec3f
	linearDamping::IReal
	angularDamping::IReal
	inverse_inertia_tensor::Mat3f
	inverse_inertia_tensorW::Mat4f
	matrix::Mat4f
end

################################################# FUNCTIONS #########################################################

function integrate!(r::RigidBody, Δ::Float32)
	rotation, velocity, orientation = r.rotation, r.velocity, r.orientation
	inversemass = r.inverse_mass
	# Calculate linear acceleration from force inputs.
	lastFrameAcceleration = r.acceleration
	add_scaled(lastFrameAcceleration,forceAccum, inverseMass)
	# Calculate angular acceleration from torque inputs.
	angularAcceleration = r.inverse_inertia_tensorW * torqueAccum
	# Adjust velocities
	# Update linear velocity from both acceleration and impulse.
	add_scaled(r.velocity, lastFrameAcceleration, duration)
	# Update angular velocity from both acceleration and impulse.
	add_scaled(r.rotation,angularAcceleration, duration)
	# Impose drag.
	r.velocity *= r.linearDamping^duration
	r,rotation *= r.angularDamping^ duration
	# Adjust positions
	# Update linear position.
	add_scaled(r.position,r.velocity, duration)
	# Update angular position.
	add_scaled(r.orientation,r.rotation, duration);
	# Impose drag.
	velocity *= r.linearDamping^duration;
	rotation *= r.angularDamping^duration;
	# Normalize the orientation, and update the matrices with the new
	# position and orientation.
	calculateDerivedData(r);
	# Clear accumulators.
	clear_accumulate(r);
end

function calculateDerivedData(r::RigidBody)
	r.matrix = _calculate_matrix(r.position, r.orientation)
	r.inverse_inertia_tensorW = to_global_basis(r.matrix, r.inverse_inertia_tensor)
end

function get_point_in_global_space(t::Mat4f, p::Vec3; glob=false)
	v = iQuatf(p.x,p.y,p.z,0)
	nq = glob ? vinvert_mat(t)*v : v

	return Vec3f(nq.x,nq.y, nq.z)
end
function get_point_in_global_space(t::Mat4f, p::Vec2)
	v = iQuatf(p.x,p.y,0,0)
	nq = vinvert_mat(t)*v

	return Vec2f(nq.x,nq.y)
end

"""
    setinvinertia(r::AbstractBody, inertia::SMatrix)

The the inverse inertia of a rigid body `r` given an inertia tensor,
"""
setinvinertia(r::RigidBody, inertia::SMatrix) = setfield!(e, :inverse_inertia_tensor, vinvert_mat(inertia))

function add_force(r::RigidBody3D, f::Vec3, p::Vec3)
	np = get_point_in_global_space(r.matrix, p)
	r.forceAccum += f
	r.torquAccum += np × f
end
add_force(r::RigidBody3D, f::Vec3) = (r.forceAccum += f)
clear_accumulate(r::RigidBody) = (r.forceAccum .= zero(IReal);r.torquAccum .= zero(IReal))