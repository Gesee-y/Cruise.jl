#####################################################################################################################
################################################# ANIMATION LAYER ###################################################
#####################################################################################################################

export BlendMode
export Layer
export LayerStack

####################################################### CORE ########################################################

abstract type BlendMode end
struct BlendAdd <: BlendMode end
struct BlendOverride <: BlendMode end
struct BlendMask <: BlendMode end

struct Layer
    anim::RAnimation
    weight::Float64
    mode::BlendMode
end
struct LayerStack
    layers::Vector{Layer}
end
LayerStack() where T = LayerStack(Layer[])

####################################################### FUNCTIONS ###################################################

push_layer!(s::LayerStack,l::Layer) = push!(s.layers,l)

function at(s::LayerStack, t, start)
    isempty(s.layers) && return start
    out = start
    for l in s.layers
        v = at(l.anim,t)
        out = if l.mode isa BlendOverride
            v
        elseif l.mode isa BlendAdd
            out + v*l.weight
        else # Mask
            l.weight*v + (1-l.weight)*out
        end
    end
    
    return out
end

function animate!(stack::LayerStack, obj, property, value_at_start;
                  start=0.0, speed=1/60, delay=speed, loop=1, value_at_start)
    binding = AbstractBinding(obj, property)
    d = maximum(duration(l.anim) for l in stack.layers; init=0.0)
    return @async begin
        for _ in 1:(loop == 0 ? typemax(Int) : loop)
            for t in range(start, start+d, step=speed)
                set!(binding, at(stack, t, value_at_start))
                sleep(delay)
            end
        end
    end
end