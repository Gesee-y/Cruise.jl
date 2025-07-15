include(joinpath("..","..", "src", "Cruise.jl"))

using .Cruise

const window_size = Vec2(600,400)

@InputMap UP("UP", "W")
@InputMap LEFT("LEFT", "A")
@InputMap DOWN("DOWN", "S")
@InputMap RIGHT("RIGHT", "D")

@Notifyer WallTouched(pos::Float32)

connect(WallTouched) do x
	x >= window_size.x && println("Player 1 scored!")
	x <= 0 && println("Player 2 scored!")
end

const app = CruiseApp()
const win = CreateWindow(app, SDLStyle, SDLRender, "Pong GS",window_size...)
get_velocity() = IsKeyPressed(win.win, DOWN) - IsKeyPressed(win.win, UP)

mutable struct Paddle
	rect::Rect2D{Float32}
	velocity::Int
	color::iRGBA

	## Constructor

	Paddle(x=20,y=200) = new(Rect2Df(x,y,10,60), 0, BLACK)
end

mutable struct Ball
	rect::Rect2D{Float32}
	velocity::Vec2{Float32}
	speed::Float32
	color::iRGBA
	dir::Vec2{Int}
	cooldown::Int

	## Constructor

	Ball(x=300,y=200,initial_vel=Vec2{Float32}(2,3)) = new(Rect2Df(x,y,10,10),initial_vel, vnorm(initial_vel),BLACK, 
		Vec2{Int}(sign(initial_vel.x), sign(initial_vel.y)),0)
end

function draw!(p::Paddle)
	SetDrawColor(win.backend, p.color)
	DrawRect(win.backend, p.rect)
end
function draw!(b::Ball)
	r = b.rect
	SetDrawColor(win.backend, b.color)
	DrawRect(win.backend, (floor(r.x), floor(r.y), r.w, r.h))
end
function update_paddle(p::Paddle)
	p.rect.origin.y += get_velocity()*2
	draw!(p)
end
function update_ball(b::Ball, p::Paddle)
	b.rect.origin += b.velocity
	b.cooldown <= 0 && check_collision(b,p)
	draw!(b)
	b.cooldown >= 0 && (b.cooldown -= 1)
end

function check_collision(b, p)
    pos = b.rect.origin
	paddle_pos = p.rect.origin
	if pos.x > window_size.x || pos.x < 0
		pos.x = clamp(pos.x, 0, window_size.x)
		b.dir.x = -b.dir.x
		b.velocity = vreflect(b.velocity, iVec2{Int}(b.dir.x, 0))
		b.cooldown = 2

		WallTouched.emit = pos.x
	end
	if pos.y > window_size.y || pos.y < 0
		pos.y = clamp(pos.y, 0, window_size.y)
		b.dir.y = -b.dir.y
		b.velocity = vreflect(b.velocity, iVec2{Int}(0, -b.dir.y))
		b.cooldown = 2
	end
	if overlapping(b.rect, p.rect)
		dir = get_velocity()==0 ? 1 : -get_velocity()
		b.velocity = vreflect(b.velocity, iVec2{Int}(dir,0))
		b.cooldown = 2
    end
end

const paddle = Paddle()
const ball = Ball()

@gameloop max_fps=60 app begin
    
    update_paddle(paddle)
    update_ball(ball,paddle)
end