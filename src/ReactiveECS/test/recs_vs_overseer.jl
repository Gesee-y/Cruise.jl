include(joinpath("..", "src", "ReactiveECS.jl"))

using .ReactiveECS
using BenchmarkTools
using GeometryTypes
using LoopVectorization
using InteractiveUtils

ReactiveECS.debug_mode() = false
ON_ERROR = ReactiveECS.filter_level(ReactiveECS.ERROR)
connect(ON_ERROR) do e
	println(e)
end
sync_notif(ON_ERROR)

@inline ReactiveECS.run!(world,sys::AbstractSystem,w::WeakRef) = ReactiveECS.run!(world, sys, w.value)
@inline ReactiveECS.run!(world,sys::AbstractSystem,::SysToken) = ReactiveECS.run!(world, sys, world.queries[sys])

ReactiveECS.@component RSpatial begin
    position::Main.GeometryTypes.Point3{Float64}
    velocity::Main.GeometryTypes.Vec3{Float64}
end

ReactiveECS.@component RSpring begin
    center::Main.GeometryTypes.Point3{Float64}
    spring_constant::Float64
end
   
ReactiveECS.@component RRotation begin
	omega::Float64
	center::Main.GeometryTypes.Point3{Float64}
	axis::Main.GeometryTypes.Vec3{Float64}
end

function move_process(positions::Vector{Point3{Float64}}, velocities::Vector{Vec3{Float64}}, query::Query, dt::Float64)
    @foreachrange query begin
        @inbounds for i in range
	    	velocity = velocities[i]
	        positions[i] += velocity*dt
	    end
	end
end

@system ROscillator

function ReactiveECS.run!(ecs::ECSManager, sys::ROscillator, query::Query)
	spatials = get_component(sys, :RSpatial)
	springs = get_component(sys, :RSpring)
	positions = spatials.position
	velocities = spatials.velocity
	centers = springs.center
	consts = springs.spring_constant

    for partition in query
    	zones::Vector{TableRange} = partition.zones

    	for zone in zones
    		range = get_range(zone)
			@inbounds for i in range
				position = positions[i]
				new_v      = velocities[i] - (position - centers[i]) * consts[i]
				velocities[i]             = new_v
			end
		end
	end
end

@system RRotator

function ReactiveECS.run!(ecs::ECSManager, sys::RRotator, query::Query)
	dt = 0.01
	spatials                           = get_component(ecs, :RSpatial)
	rotations                          = get_component(ecs, :RRotation)
	centers                            = rotations.center
	axis                               = rotations.axis
	positions                          = spatials.position
	omegas                             = rotations.omega
	velocities                         = spatials.velocity
    
    for partition in query
    	zones::Vector{TableRange} = partition.zones

    	for zone in zones
    		range = get_range(zone)

		    @inbounds for i in range
		    	center  = centers[i]
				n         = axis[i]
				r       = - center + positions[i]
				theta           = omegas[i] * dt
				nnd       = n * GeometryTypes.dot(n, r)
				positions[i]             = Point3f0(center + nnd + (r - nnd) * cos(theta) + GeometryTypes.cross(r, n) * sin(theta))
			end
        end
	end
end

@system RMover

function ReactiveECS.run!(ecs::ECSManager, sys::RMover, query::Query)
    spatials = get_component(ecs, :RSpatial)
    move_process(spatials.position, spatials.velocity, query, 0.01)
end

world = ECSManager()

register_component!(world, RSpatial)
register_component!(world, RRotation)
register_component!(world, RSpring)

osc_sys = ROscillator()
rot_sys = RRotator()
move_sys = RMover()

sys = (osc_sys, rot_sys, move_sys)

e1 = create_entity!(world; 
            RSpatial = RSpatial(Point3(1.0, 1.0, 1.0), Vec3(0.0, 0.0, 0.0)), 
            RSpring = RSpring(Point3(0.0, 0.0, 0.0), 0.01))
            
e2 = create_entity!(world; 
            RSpatial = RSpatial(Point3(-1.0, 0.0, 0.0), Vec3(0.0, 0.0, 0.0)), 
            RRotation = RRotation(1.0, Point3(0.0, 0.0, 0.0), Vec3(1.0, 1.0, 1.0)))

e3 = create_entity!(world; 
            RSpatial = RSpatial(Point3(0.0, 0.0, -1.0), Vec3(0.0, 0.0, 0.0)), 
            RRotation = RRotation(1.0, Point3(0.0, 0.0, 0.0), Vec3(1.0, 1.0, 1.0)), 
            RSpring = RSpring(Point3(0.0, 0.0, 0.0), 0.01))
e4 = create_entity!(world; 
            RSpatial = RSpatial(Point3(0.0, 0.0, 0.0), Vec3(1.0, 0.0, 0.0)))

request_entity!(world, (
	RSpatial = RSpatial(Point3(0.0, 0.0, -1.0), Vec3(0.0, 0.0, 0.0)), 
    RRotation = RRotation(1.0, Point3(0.0, 0.0, 0.0), Vec3(1.0, 1.0, 1.0)), 
    RSpring = RSpring(Point3(0.0, 0.0, 0.0), 0.01))
, 100_000)

q1 = @query(world, RSpatial & RSpring)
q2 = @query(world, RSpatial & RRotation)
q3 = @query(world, RSpatial)

subscribe!(world, osc_sys, @query(world, RSpatial & RSpring))
subscribe!(world, rot_sys, @query(world, RSpatial & RRotation))
subscribe!(world, move_sys, @query(world, RSpatial))

run_system!(osc_sys)
run_system!(rot_sys)
run_system!(move_sys)

dt = 0.01
spatials = get_component(world, :RSpatial)
positions = spatials.position
velocities = spatials.velocity
  

#@btime run!($world, $osc_sys, WeakRef($q1))
#@btime run!($world, $rot_sys, $q2)
#@code_warntype run!(world, move_sys, q3)
#@code_lowered run!(world, move_sys, q3)
#@btime run!($world, $move_sys, $q3)

c = Threads.Atomic{Int}(0)

sss = collect(world.queries)

@btime for s in keys($world.queries)
	run!($world, s, $world.queries[s])    
end

#for _ in 1:3
	@btime begin
        dispatch_data($world)
        blocker($world)
    end
#end
