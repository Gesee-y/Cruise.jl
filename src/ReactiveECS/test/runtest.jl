include(joinpath("..", "src", "ReactiveECS.jl"))

using .ReactiveECS
using BenchmarkTools
using LoopVectorization

ReactiveECS.debug_mode() = false
ON_ERROR = ReactiveECS.filter_level(ReactiveECS.ERROR)
connect(ON_ERROR) do e
	println(e)
end
sync_notif(ON_ERROR)

n = UInt(1)
l = UInt(0)

@component Health begin
	hp::Int
end

@component Transform begin
    x::Float32
    y::Float32
end

@component Physic begin
	velocity::Float32
end

@component Status begin
    dirty::Int
end

@system PhysicSystem begin
	dt::Float32
end

ecs = ECSManager()
register_component!(ecs, Health)
register_component!(ecs, Transform)
register_component!(ecs, Physic)
register_component!(ecs, Status)

components = (Health = Health(50), Physic = Physic(0.0), Transform = Transform(0,0))
components = (Health = Health(50), Physic = Physic(0.0), Transform = Transform(0,0))

key = (:Health, :Transform, :Physic, :Status)
e = create_entity!(ecs, components)
#@btime create_entity(ecs, key)
request_entity!(ecs, components, 100000)
#@btime remove_entity!(ecs,e)
#request_entity(ecs, key, 1_000)

#@btime @query(ecs, Transform & Physic & Status)
q = @query(ecs,Transform & ~Status)

ReactiveECS.run!(world::ECSManager, sys::AbstractSystem, ref::WeakRef) = run!(world, sys, ref.value)
function ReactiveECS.run!(world::ECSManager,sys::PhysicSystem,query::Query)
    transforms = get_component(world, :Transform)
    physics = get_component(world, :Physic)
    x = transforms.x
    velocities = physics.velocity
    dt = sys.dt
    #lck = @inline get_lock(transforms, (:x,))
    #lock(lck)

	@foreachrange query begin
	    @turbo for i in range
			x[i] += velocities[i] * dt
		end
	end

	#unlock(lck)
end

physic_sys = PhysicSystem(1/60)
subscribe!(ecs, physic_sys, @query(ecs, Transform & Physic))
run_system!(physic_sys)
q = @query(ecs, Transform & Physic)
@btime run!($ecs, $physic_sys, $q)

@btime begin
	dispatch_data($ecs)
	blocker($ecs)
end
#@btime process($ecs,$q)
#@btime get_tree($a)
#@btime add_child($a,$b)
#@btime get_children($a)
#@btime remove_child($a,$b)
#@btime get_nodeidx($a)
#@btime get_id($a)

#=

entity with 1 component: 753ns
entity with 2 component: 1.4us
entity with 3 components: 1.8us

entity with 4 uninitialiazed components: 602.9ns

=#