######################################################################################################################
###################################################### WORLDS ########################################################
######################################################################################################################

export IWorld
export start_frame, run_physics!

####################################################### CORE #########################################################

mutable struct IWorld{N}
	particles::Vector{Particle{N}}
	contact_gen::Vector{ContactGenerator}
	contacts::Vector{IContact{N}}
	max_contact::Int
	fregistry::ForceRegistry
	resolver::IContactResolver
	calc_iterations::Bool
end

#################################################### FUNCTIONS #######################################################

function start_frame(w::IWorld)
    foreach(clear_accumulate_force, w.particles)
end

function run_physics!(w::IWorld, Δ::Float32)
	update_forces(w.fregistry, Δ)
	integrate!(w, Δ)
	usedContacts = generate_contacts(w)

	(w.calc_iterations) && (w.resolver.max_iter = usedContacts*2)
	resolve_contacts(w.resolver, w.contacts, Δ)
end

function integrate!(w::IWorld, Δ::Float32)
	for p in w.particles
		integrate!(p, Δ)
	end
end

function generate_contacts(w::IWorld)
	contacts = w.contacts
	limit = w.max_contact
	next = 1
	while next <= length(contacts)
		used = add_contact(c, contacts, next, limit)
		limit -= used
		next += used

		limit <= 0 && break
	end

	return w.max_contact - limit
end