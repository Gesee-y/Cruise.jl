

@enum LoopMode Once Loop PingPong

mutable struct Player{T}
    anim::RAnimation
    binding::AbstractBinding

    time::Float64          # position courante (en secondes)
    speed::Float64         # multiplicateur de vitesse (peut être négatif)
    state::PlayState       # Play / Pause
    loop::LoopMode         # Once / Loop / PingPong
    direction::Int         # +1 forward, -1 backward

    # callbacks
    on_finish::Union{Nothing,Function}
    on_loop::Union{Nothing,Function}

    duration::Float64
end

function Player(anim::RAnimation, obj, property;
                speed=1.0, loop::LoopMode=Loop,
                on_finish=nothing, on_loop=nothing)
    binding = AbstractBinding(obj, property)
    Player(anim, binding,
           0.0, speed, Pause,
           loop, +1,
           on_finish, on_loop,
           duration(anim))
end

# contrôle absolu / relatif
seek!(p::Player, t::Real)      = (p.time = clamp(t, 0.0, p.duration); update!(p))
seek_relative!(p, Δ::Real)     = seek!(p, p.time + Δ)

pause!(p::Player)              = (p.state = Pause)
resume!(p::Player)             = (p.state = Play)
reverse!(p::Player)            = (p.direction = -p.direction)
speed!(p::Player, s::Real)     = (p.speed = s * p.direction)

loop_mode!(p::Player, m::LoopMode) = (p.loop = m)

function update!(p::Player, dt::Real=0.0)
    dt == 0.0 || p.state == Pause && return p.time

    Δ = p.speed * p.direction * dt
    p.time += Δ

    # gestion des bords selon loop_mode
    if p.time < 0.0 || p.time > p.duration
        if p.loop == Once
            p.time = clamp(p.time, 0.0, p.duration)
            p.state = Pause
            isnothing(p.on_finish) || p.on_finish(p)
            return p.time
        elseif p.loop == Loop
            p.time = mod(p.time, p.duration)
            isnothing(p.on_loop) || p.on_loop(p)
        else # PingPong
            overshoot = p.time > p.duration ? p.time - p.duration : -p.time
            p.direction = -p.direction
            p.time = clamp(overshoot, 0.0, p.duration)
            isnothing(p.on_loop) || p.on_loop(p)
        end
    end

    val = at(p.anim, p.time)
    set!(p.binding, val)
    return p.time
end