include(joinpath("..","..", "Cruise.jl"))

using .Cruise

mutable struct Firework
	particle::Particle2D
	age::Float32
end

mutable struct FireworkManager
	type::Int
	min_age::Float32
	max_age::Float32
	min_velocity::Vec2f
	max_velocity::Vec2f
	damping::Float32
	particles::Vector{Firework}
end

const fm1 = FireworkManager(1, 3, 5, Vec2f(-5,-5), Vec2f(3,3), 0.1, Firework[])

ArtilleryShot() = Particle2D(0.005,Vec2f(1.5,0),Vec2f(-30,40), Vec2f(20,0),Vec2f(0,0), 0.99)
FireballShot() = Particle2D(1,Vec2f(1.5,400),Vec2f(0,-10), Vec2f(0.6,0.0),Vec2f(0,0.0), 0.9)
PistolShot() = Particle2D(0.5,Vec2f(1.5,400),Vec2f(0,-35), Vec2f(0,1.0),Vec2f(0,0), 0.99)
LaserShot() = Particle2D(10,Vec2f(1.5,0),Vec2f(0,100), Vec2f(0,0.0),Vec2f(0,0), 0.99)

const window_size = Vec2(600,400)
const app = CruiseApp()
const win = CreateWindow(app, SDLStyle, SDLRender, "Pong GS",window_size...)

funcs = [ArtilleryShot, FireballShot, PistolShot, LaserShot]
const particles = [funcs[rand(1:length(funcs))]() for _ in 1:10]
for p in particles
	p.position.x = rand(1:600)
end

get_color(p::Particle2D) = begin
	invm = p.inverse_mass
	if invm == Float32(0.005)
		return BLACK
	elseif invm == 1
		return RED
	elseif invm == 0.5
		return BLUE
	else
		return GREEN
	end
end

function update_particule(p::Particle2D, Δ::Float32)
	integrate!(p, Δ)
	SetDrawColor(win.backend, get_color(p))
	DrawRectF(win.backend, Rect2Df(p.position..., 5,5))
end

function update!(f::Firework, Δ::Float32)
	p = f.particle
	integrate!(p, Δ)
	f.age -= Δ
	SetDrawColor(win.backend, BLACK)
	DrawRectF(win.backend, Rect2Df(p.position..., 5,5))

	return f.age < 0
end

function update!(f::FireworkManager, Δ::Float32)
	for p in f.particles
		p.age > 0 && update!(p, Δ)
	end
end

function create!(fm::FireworkManager, parent=nothing)
	type = fm.type
	age = rand(fm.min_age:fm.max_age)
    miv = fm.min_velocity
    mav = fm.max_velocity
    vel = Vec2f(rand(miv.x:mav.x), rand(miv.y:mav.y))
    
    f = Firework(Particle2D(1,Vec2f(300,0),vel, GRAVITY2D,Vec2f(0,0), fm.damping), age)
    !isnothing(parent) && (f.particle.position = parent.particle.position)
    
    push!(fm.particles, f)
end

#@gameloop max_fps=60 app begin
#    if LOOP_VAR.frame_idx % 10 == 0
#        p = funcs[rand(1:length(funcs))]()
#    	p.position.x = rand(1:600)
#    	push!(particles, p)
#    end
#
#    for p in particles
#        update_particule(p, LOOP_VAR.delta_seconds)
#    end
#    # Will simulate 10s waiting then stop the loop
#    #cnt > 600 && shutdown!(app)
#end

@gameloop max_fps=60 app begin
    if LOOP_VAR.frame_idx % 10 == 0
        create!(fm1)
    end

    update!(fm1, LOOP_VAR.delta_seconds)
    # Will simulate 10s waiting then stop the loop
    #cnt > 600 && shutdown!(app)
end