#########################################################################################################################
#################################################### GAME LOOP ##########################################################
#########################################################################################################################

export GameLoop
export @gameloop, LOOP_VAR_REF

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

function reset!(l::GameLoop)
    l.last_frame_time_ns = 0
    l.frame_idx = 0
    l.max_fps = 60
    l.max_frame_duration = 0.5
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

@gameloop max_fps=60 app begin
    global cnt
    println("In loop")
    cnt += 1
    
    # Will simulate 10s waiting then stop the loop
    cnt > 600 && shutdown!(app)
end
```
"""
macro gameloop(args...)
    length(args) < 2 && error("@gameloop should take at least 2 argument.")
    code = args[end]
    main = args[end-1]
    
    max_fps = 60
    max_duration = 0.3
    for i in 1:length(args)-2
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
        app = Cruise.CruiseApp()
        Cruise.off(app) && Cruise.awake!()
        tolerance = 0.02
        LOOP_VAR = LOOP_VAR_REF[]
        Cruise.reset!(LOOP_VAR)
        LOOP_VAR.max_fps = $max_fps
        LOOP_VAR.max_frame_duration = $max_duration
        while Cruise.on(app)

            # First pump events and initialize every windows
            Cruise.update!(app.app)
            Cruise.update!(app, :preupdate)

            # Then execute the loop code
            $code

            Cruise.update!(app, :postupdate)
            Cruise.update!(app.render)

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
    end)
    
    # A noted by William, global code is slow in julia, better wrap it in an anonymous function
    return :(((app) -> $body)($main))
end