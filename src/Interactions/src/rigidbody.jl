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
    angular_velocity::IReal
    forceAccum::Vec2f
    torqueAccum::IReal
    linearDamping::IReal
    angularDamping::IReal
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
	inverse_inertia_tensorW::Mat3f
	matrix::Mat4f
end

################################################# FUNCTIONS #########################################################

function integrate!(r::RigidBody2D, Δ::Float32)
    inversemass = r.inverse_mass
    isfinite(inversemass) || return
    
    # Calculate linear acceleration
    lastFrameAcceleration = zero(Vec2f) # Add acceleration field if needed
    add_scaled(lastFrameAcceleration, r.forceAccum, inversemass)
    
    # Calculate angular acceleration
    angularAcceleration = r.inverse_inertia_tensor * r.torqueAccum # Scalar for 2D
    
    # Update velocities
    add_scaled(r.velocity, lastFrameAcceleration, Δ)
    r.orientation += angularAcceleration * Δ
    
    # Apply damping
    r.velocity *= r.linearDamping^Δ
    r.orientation *= r.angularDamping^Δ
    
    # Update position
    add_scaled(r.position, r.velocity, Δ)
    
    # Update derived data
    calculateDerivedData(r)
    
    # Clear accumulators
    clear_accumulate(r)
end

function integrate!(r::RigidBody3D, Δ::Float32)
    inversemass = r.inverse_mass
    isfinite(inversemass) || return
    
    # Calculate linear acceleration
    lastFrameAcceleration = r.acceleration
    add_scaled(lastFrameAcceleration, r.forceAccum, inversemass)
    
    # Calculate angular acceleration
    angularAcceleration = r.inverse_inertia_tensorW * r.torqueAccum
    
    # Update velocities
    add_scaled(r.velocity, lastFrameAcceleration, Δ)
    add_scaled(r.rotation, angularAcceleration, Δ)
    
    # Apply damping
    r.velocity *= r.linearDamping^Δ
    r.rotation *= r.angularDamping^Δ
    
    # Update position
    add_scaled(r.position, r.velocity, Δ)
    
    # Update orientation (quaternion)
    r.orientation = normalize_quat(r.orientation + 0.5f0 * Δ * quat_mul(iQuatf(r.rotation..., 0), r.orientation))
    
    # Update derived data
    calculateDerivedData(r)
    
    # Clear accumulators
    clear_accumulate(r)
end

function calculateDerivedData(r::RigidBody3D)
    r.matrix = _calculate_matrix(r.position, r.orientation)
    rotation_matrix = to_mat3(r.orientation) # Extract 3x3 rotation matrix
    r.inverse_inertia_tensorW = rotation_matrix * r.inverse_inertia_tensor * vinvert_mat(rotation_matrix)
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

function add_force(r::RigidBody2D, f::Vec2, p::Vec2)
    np = get_point_in_global_space(r.matrix, p)
    r.forceAccum += f
    r.torqueAccum += vcross(np, f) # Scalar cross product in 2D
end
add_force(r::RigidBody2D, f::Vec2) = (r.forceAccum += f)
function add_force(r::RigidBody3D, f::Vec3, p::Vec3)
	np = get_point_in_global_space(r.matrix, p)
	r.forceAccum += f
	r.torquAccum += np × f
end
add_force(r::RigidBody3D, f::Vec3) = (r.forceAccum += f)
clear_accumulate(r::RigidBody) = (r.forceAccum .= zero(IReal);r.torquAccum .= zero(IReal))