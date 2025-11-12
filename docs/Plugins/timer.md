# Cruise v0.3.0 documentation: Making a simple Timer Plugin

In this tutorial, we will walk you through the creation of a simple timer plugin.
It will help you understand how you leverage Cruise's plugin system.

## Plugin setup

```julia
module TimerPlugin

using Cruise

const TIMERPLUGIN = CRPlugin()
```

## Time manager

Now we just need to create the object that will handle timers. It will be a simple object that will keep track of different timer and emit a signal on timeout.

```julia
mutable struct CRTimer
    duration::Float32 # in seconds
    signal::CRSubject{Nothing}
end

mutable struct TimerManager
    timers::Vector{CRTimer}
    paused::Bool
end

TM = TimerManager(CRTimer[], false)
``` 

Now let's define some utility functions to save us time:

```julia
addtimer!(dur) = addtimer!(TM, dur)
addtimer!(tm::TimerManager, dur) = begin
    timer = CRTimer(dur, CRSubject(nothing))
    addtimer!(tm, timer)
    return timer
end
addtimer!(tm::TimerManager, t::CRTimer) = push!(tm.timers, t)

ontimeout(f, t::CRTimer) = connect(f, t.signal)
```

Now we can create a new plugin node for our timer

```julia
id = add_system!(TIMERPLUGIN, TM)
```

Let's now define our timer lifecyle. Since there is nothing much to do at boot time, we will omit `awake!`

```julia
function Cruise.update!(n::CRPluginNode{TimerManager})
    tm = n.obj
    tm.paused && return
    
    timers = tm.timers
    start, stop = 1, length(timers)
    dt = LOOP_VAR_REF[].delta_seconds # LOOP_VAR_REF let us access the information about the current game loop

    while start <= stop
        timer = timers[start]
        timer.duration -= dt

        if timer.duration <= 0
            notify!(timer.signal)
            timers[start], timers[stop] = timers[stop], timers[start]
            stop -= 1
        else
            start += 1
        end
    end

    resize!(timers, stop)
end

Cruise.shutdown!(n::CRPluginNode{TimerManager}) = empty!(b.obj.timers)
```

Now just have to finalize the module:

```julia
export addtimer!, ontimeout, CRTimer, TIMERPLUGIN

end # module
```

## Using our plugin

Let's setup Cruise:

```julia
using Cruise
using TimerPlugin

app = CruiseApp()
```

We will use `merge_plugin!` to enable our plugin:

```julia
merge_plugin!(app, TIMERPLUGIN, :preupdate)
```

Now we can happily use our plugin:

```julia
i = 0
@gameloop maxfps=60 begin
    if LOOP_VAR.frame_idx % 50 == 0
        timer = addtimer!(rand())

        j = i # To avoid that the function keep a closure on `i` that will get modified 
        ontimeout(timer) do
            println("Timer $j dead.")
        end

        i += 1
    end

    LOOP_VAR.frame_idx > 1000 && shutdown!()
end
```