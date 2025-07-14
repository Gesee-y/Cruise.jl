######################################################################################################################
##################################################### CONTACTS #######################################################
######################################################################################################################

export IContact, IContactResolver
export resolve_contacts!, resolve!

####################################################### CORE #########################################################

abstract type ContactGenerator end

"""
    mutable struct IContact{N}
		obj::NTuple{2, WeakRef}
		restitution::Float32
		normal::iSVector{Float32, N}

A `IContact` represent 2 object in contact (particle contacts).
Resolving a contact removes their interpenetration, and applies sufficient impulse to keep them apart.
Colliding bodies may also rebound.
- `obj`: The 2 object colliding. If the object collided with the scenery, the 2nd element is `WeakRef(nothing)`.
- `restitution`: The normal restitution coefficient of the contact.
- `normal`: The direction of contact in world coordinate.
"""
mutable struct IContact{N}
	obj::NTuple{2, WeakRef}
	restitution::Float32
	penetration::Float32
	normal::iSVector{Float32, N}
end
const IContact2D = IContact{2}
const IContact3D = IContact{3}

"""
	mutable struct IContactResolver
		max_iter::Int=10
		iterUsed::Int=0

Contact resolver.
- `max_iter`: The maximum number of iteration to resolve collision. Higher is better resolution but less perfomances.
- `iterUsed`: Internal counter of iteration.
"""
Base.@kwdef mutable struct IContactResolver
	max_iter::Int=10
	iterUsed::Int=0
end

#################################################### FUNCTIONS #######################################################

"""
    resolve_contacts!(resolver::IContactResolver, contacts::Vector{IContact{N}}, Δ::Float32) where N

For a given set of contact, this will resolve collision for each of them given their severity.
"""
function resolve_contacts!(resolver::IContactResolver, contacts::Vector{IContact{N}}, Δ::Float32) where N
	resolver.iterUsed = 0

    maxsep = 0.0f0
    maxIndex = length(contacts)
	while (resolver.iterUsed <= resolver.max_iter)

		@inbounds for i in eachindex(contacts)
			contact = contacts[i]
		    sepVel = _calculate_separating_velocity(contact.obj[1].value,contact.obj[2].value,Δ)

		    if sepVel < maxsep
		    	maxsep = sepVel
		    	maxIndex = i
		    end
		end

		resolve!(contacts[maxIndex],Δ)
		resolver.iterUsed += 1
	end
end

function resolve!(c::IContact, Δ::Float32)
	resolve_velocity!(c,Δ)
	resolve_interpenetration!(c,Δ)
end

function resolve_interpenetration!(c::IContact,Δ::Float32)
	penetration = c.penetration
	penetration <= 0 && return

    p1,p2 = c.obj[1].value, c.obj[2].value
	total_invmass = getinvmass(p1)+getinvmass(p2)
	total_invmass <= 0 && return

	move_per_mass = c.normal*(-penetration/total_invmass)
	add_scaled(p.position, move_per_mass, p1.inverse_mass)
	!isnothing(p2) && add_scaled(p2.position, move_per_mass, p2.inverse_mass)
end

function resolve_velocity!(c::IContact{N},Δ::Float32) where N
	p1,p2 = c.obj[1].value, c.obj[2].value
	separating_velocity = _calculate_separating_velocity(p1,p2,n)

	separating_velocity > 0 && return

	newSepVel = -separating_velocity*c.restitution
	accCause = p1.acceleration
	!isnothing(p2) && (accCause -= p2.acceleration)

	accCauseSepVel = vdot(accCause, c.normal)*Δ

	if accCauseSepVel < 0
		newSepVel += c.restitution*accCauseSepVel
		newSepVel < 0 && (newSepVel = 0)
	end
	Δvelocity = newSepVel - separating_velocity

	total_invmass = getinvmass(p1)+getinvmass(p2)
	total_invmass <= 0 && return

	impulse = Δvelocity/total_invmass
	impulse_per_mass = impulse*c.normal

	add_scaled(p1.velocity, impulse_per_mass,p1.inverse_mass)
	!isnothing(p2) && add_scaled(p2.velocity, impulse_per_mass,-p2.inverse_mass)
end

"""
    add_contact(::ContactGenerator,contacts::Vector{IContact}, start=1, limit=10)

This will override the first existing contact in `contacts` given the logic of the contact generator.
`start` is from which position the generator should start modifying contacts.
`limit` is the maximum number of contact a generator is allowed to modify.
"""
add_contact(::ContactGenerator,contacts::Vector{IContact}, start=1, limit=10) = 0

_calculate_separating_velocity(p1::Particle{N},p2::Particle{N},n::iSVector{Float32, N}) where N = vdot(p1.velocity-p2.velocity, n)
_calculate_separating_velocity(p::Particle{N},::Nothing,n::iSVector{Float32, N}) where N = vdot(p.velocity, n)