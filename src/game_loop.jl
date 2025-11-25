#########################################################################################################################
#################################################### GAME LOOP ##########################################################
#########################################################################################################################

export GameLoop, GameCode
export @gameloop, @gamelogic, LOOP_VAR_REF
export enable_system, disable_system

## Inspired from B+ engine by William Manning
"""
    mutable struct GameLoop
        # Game stuff:

        # Timing stuff:
        last_frame_time_ns::UInt64 = 0
        frame_idx::Int128 = 0
        delta_seconds::Float32 = 0


        ##################################
        #   Below are fields you can set!

        # The maximum framerate.
        # The game loop will wait at the end of each frame if the game is running faster than this.
        max_fps::Int = 60

        # The maximum frame duration.
        # 'delta_seconds' will be capped at this value, even if the frame took longer.
        # This stops the game from significantly jumping after one hang.
        max_frame_duration::Float32 = 0.5

Metadata for our gameloop.
Can be modified anytime in the loop by accessing `LOOP_VAR`.
"""
Base.@kwdef mutable struct GameLoop
    # Game stuff:

    # Timing stuff:
    last_frame_time_ns::UInt64 = 0
    frame_idx::Int128 = 0
    delta_seconds::Float32 = 0


    ##################################
    #   Below are fields you can set!

    # The maximum framerate.
    # The game loop will wait at the end of each frame if the game is running faster than this.
    max_fps::Int = 60

    # The maximum frame duration.
    # 'delta_seconds' will be capped at this value, even if the frame took longer.
    # This stops the game from significantly jumping after one hang.
    max_frame_duration::Float32 = 0.5
end

const LOOP_VAR_REF = Ref{GameLoop}(GameLoop())

"""
This struct represent the code you passed on to the game loop object.
That code will be used to generate a new system that will be used to execute your code
"""
mutable struct GameCode{N}
    expr::Expr
    code::Function
end

function reset!(l::GameLoop)
    l.last_frame_time_ns = 0
    l.frame_idx = 0
    l.max_fps = 60
    l.max_frame_duration = 0.5
end

"""
This macro helps you define your game logic more easily, without thinking about plugins or anything.

## Example

```julia
app = CruiseApp()

# This will create a new system in the main plugin and automatically set his update logic to your code.
ai_id = @gamelogic AILogic begin
    # My logics
end
```
"""
macro gamelogic(args...)
    length(args) < 2 && error("@gamelogic should take at least 2 argument.")
    args[1] isa Symbol || error("@gamelogic should take as first argument the logic name.")
    args[end] isa Expr || error("@gamelogic should take as last argument the logic body.")
    name = QuoteNode(args[1])
    code = args[end]
    rawcode = QuoteNode(code)
    
    cap = ()
    plugin = CruiseApp().plugins
    mainthread = false
    for i in 2:length(args)-1
        args[i] isa Symbol && error("@gamelogic should take keyword arguments not `$(args[i])")
        arg = args[i].args
        if arg[1] == :capability
            cap = (arg[2],)
        elseif arg[1] == :plugin
            plugin = arg[2]
        elseif arg[1] == :mainthread
            mainthread = arg[2]
        else
            error("Unknow keyword $(arg[1])")
        end
    end
    cap = __module__.eval.(cap)

    __module__.eval( quote
        # Adding the user code as a system in the plugin
        logic = Cruise.GameCode{$name}($rawcode, (self) -> $code)
        LOGICID = add_system!($plugin, logic, $cap...; mainthread=$mainthread)

        return LOGICID
    end)
end

"""
    @gameloop app begin
        ...
    end

This macro create a new game loop which will stop when `on(app)` will return false.
This loop handle events and the boilerplates of rendering for you.

You can pass it keyword arguments like `max_fps` and `max_duration` but you will always be able to modify them afterward

## Example

```julia
using Cruise

app = CruiseApp()
cnt::Int = 0

@gameloop max_fps=60 begin
    global cnt
    println("In loop")
    cnt += 1
    
    # Will simulate 10s waiting then stop the loop
    cnt > 600 && shutdown!()
end
```
"""
macro gameloop(args...)
    length(args) < 1 && error("@gameloop should take at least 1 argument.")
    code = args[end]
    rawcode = QuoteNode(code)
    
    max_fps = 60
    max_duration = 0.3
    for i in 1:length(args)-1
        args[i] isa Symbol && error("@gameloop should take keyword arguments not `$(args[i])")
        arg = args[i].args
        if arg[1] == :max_fps
            max_fps = arg[2]
        elseif arg[1] == :max_duration
            max_duration = arg[2]
        else
            error("Unknow keyword $(arg[1])")
        end
    end

    body = esc(quote
        Cruise.off(app) && Cruise.awake!()
        
        # Adding the user code as a system in the plugin

        tolerance = 0.02
        LOOP_VAR = LOOP_VAR_REF[]
        Cruise.reset!(LOOP_VAR)
        LOOP_VAR.max_fps = $max_fps
        LOOP_VAR.max_frame_duration = $max_duration

        func = (self) -> $code
        logic = Cruise.GameCode{:gameloop}($rawcode, func)
        LOGICID = Cruise.add_system!(app.plugins, logic, LOOP_VAR; mainthread=true)

        while Cruise.on(app)

            Cruise.update!() # Traverse the graph and execute each node

            # Advance the timer.
            LOOP_VAR.frame_idx += 1
            new_time::UInt = time_ns()
            elapsed_seconds = Float32((new_time - LOOP_VAR.last_frame_time_ns) / 1e9)

            # Cap the framerate, by waiting if necessary.
            if LOOP_VAR.max_fps > 0
                target_frame_time = 1/LOOP_VAR.max_fps
                
                # Time snapping: If we are near from the target time then we just act as we are there
                ratio = (elapsed_seconds / target_frame_time)
                fratio = round(ratio)
                if (ratio - fratio <= tolerance) && (fratio >= 1)
                    LOOP_VAR.delta_seconds = target_frame_time * fratio
                    # No need to sleep if we are already at the correct time
                else
                    wait_time = target_frame_time*(fratio+1) - elapsed_seconds
                    if wait_time > 0
                        EventNotifiers.sleep_ns(wait_time; sec=true)
                        # Update the timestamp again after waiting.
                        new_time = time_ns()
                    end
                    LOOP_VAR.delta_seconds = Float32((new_time - LOOP_VAR.last_frame_time_ns) / 1e9)
                end
            else
                LOOP_VAR.delta_seconds = elapsed_seconds
            end

            LOOP_VAR.last_frame_time_ns = new_time
            # Cap the length of the next frame.
            LOOP_VAR.delta_seconds = min(LOOP_VAR.max_frame_duration, LOOP_VAR.delta_seconds)
        end

        on(app) && shutdown!()
        remove_system!(app.plugins, LOGICID)
    end)
    
    # As noted by William, global code is slow in julia, better wrap it in an anonymous function
    return :(((app) -> $body)(Cruise.CruiseApp()))
end

"""
Activate a logic and make it able to be executed.
This is preferrable to adding/removing system because this doesn't need to recompute the topological order.
You add the optional argument `awake` to say if the `awake!` function of the system should also be called.

## Example

```julia

ai_id = @gamelogic AIUpdate begin
    # hard stuffs
end

enable_system(id) # Now your game logic will be able to run
```
"""
function enable_system(id::Integer, awake=true)
    app = CruiseApp()
    idtonode = app.plugins.idtonode

    !haskey(idtonode, id) && return
    node = idtonode[id]
    node.enabled = true
    awake && awake!(node)
end

"""
Desactivate a logic and make it able to be executed.
This is preferrable to adding/removing system because this doesn't need to recompute the topological order.

## Example

```julia

ai_id = @gamelogic AIUpdate begin
    # hard stuffs
end

disable_system(id) # Now your game logic will no more run
```
"""
function disable_system(id::Integer, shut=false)
    app = CruiseApp()
    idtonode = app.plugins.idtonode

    !haskey(idtonode, id) && return
    node = idtonode[id]
    node.enabled = false

    shut && shutdown!(node)
end

function Cruise.update!(n::CRPluginNode{<:GameCode})
    gamelogic = n.obj
    gamelogic.code(n)
end