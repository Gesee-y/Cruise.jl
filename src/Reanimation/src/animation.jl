#####################################################################################################################
###################################################### ANIMATIONS ###################################################
#####################################################################################################################

export RAnimation
export animate!

######################################################### CORE ######################################################

struct RAnimation
    animation::Vector{KFAnimationFrame}
    loop::Int

    function RAnimation(animation::Vector{KFAnimationFrame}, loop::Int=1)
        loop < 0 && error("Loop count must be ≥ 0")
        new(animation, loop)
    end
end

####################################################### FUNCTIONS ###################################################

"""
    duration(anim::RAnimation) -> Float64

Total duration of the animation.
"""
function duration(anim::RAnimation)
    isempty(anim.animation) && return 0.0
    sum(duration, anim.animation)
end

"""
    at(anim::RAnimation, t::Real)

Return the interpolated value at the instant `t`.
Manage loops and transitions.
"""
function at(anim::RAnimation, t::Real)
    isempty(anim.animation) && error("Empty animation")
    total = duration(anim)
    total == 0 && return value(first(anim.animation).k1)  # cas dégénéré

    t_eff = anim.loop == 0 ? t : mod(t, total * anim.loop)
    t_eff = clamp(t_eff, 0.0, total * anim.loop)

    acc = 0.0
    for frame in anim.animation
        d = duration(frame)
        if t_eff < acc + d
            local_t = t_eff - acc
            return at(frame, local_t)
        end
        acc += d
    end

    # If the animation has already ended, we clamp
    return value(last(anim.animation).k2)
end

"""
    animate!(anim::RAnimation, obj, property;
             start=0.0, speed=1/60, delay=speed, loop=1)

Run the animation in a task.
"""
function animate!(anim::RAnimation, obj, property;
                  start=0.0, speed=1/60, delay=speed, loop=1)
    loop < 0 && error("Loop count must be ≥ 0")
    binding = AbstractBinding(obj, property)
    d = duration(anim)

    return @async begin
        for _ in 1:(loop == 0 ? typemax(Int) : loop)  # loop==0 → infinite
            for t in range(start, start+d, step=speed)
                set!(binding, at(anim, t))
                sleep(delay)
            end
        end
    end
end