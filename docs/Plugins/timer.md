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
mutable struct Timer
    duration::Float32 # in seconds
    signal::CRSubject{Nothing}
end

mutable struct TimerManager
    timers::Vector{Timer}
    paused::Bool
end

TM = TimerManager(Timer[], false)
``` 

Now let's define some utility functions to save us time:

```julia
addtimer!(dur) = addtimer!(TM, dur)
addtimer!(tm::TimerManager, dur) = begin
    timer = Timer(dur, CRSubject(nothing))
    addtimer!(tm, timer)
    return timer
end
addtimer!(tm::TimerManager, t::Timer) = push!(tm.timers, t)

ontimeout(f, t::Timer) = connect(f, t.signal)
```

Now we can create a new plugin node for our timer

```julia
id = add_system!(TIMERPLUGIN, tm)
```

Let's now define our timer lifecyle. Since there is nothing much to do at boot time, we will omit `awake!`

```julia
function Cruise.update!(n::CRPluginNode{TimerManager}, lvar::GameLoop)
    tm = n.obj
    tm.paused && return
    
    timers = tm.timers
    start, stop = 1, length(timers)
    dt = lvar.delta_seconds

    while start <= stop
        timer = timers[start]
        timer.duration -= dt

        if timer.duration <= 0
            notify!(timer.signal, nothing)
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
export addtimer!, ontimeout, Timer, TIMERPLUGIN

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
        ontimeout(timer) do
            println("Timer $i dead.")
        end

        i += 1
    end
end
```