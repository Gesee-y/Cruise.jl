module TimerPlugin

using ..Cruise

const TIMERPLUGIN = CRPlugin()

mutable struct CRTimer
    duration::Float32 # in seconds
    signal::CRSubject{Nothing}
end

mutable struct TimerManager
    timers::Vector{CRTimer}
    paused::Bool
end

TM = TimerManager(CRTimer[], false)

addtimer!(dur) = addtimer!(TM, dur)
addtimer!(tm::TimerManager, dur) = begin
    timer = CRTimer(dur, CRSubject(nothing))
    addtimer!(tm, timer)
    return timer
end
addtimer!(tm::TimerManager, t::CRTimer) = push!(tm.timers, t)

ontimeout(f, t::CRTimer) = connect(f, t.signal)

id = add_system!(TIMERPLUGIN, TM)

function Cruise.update!(n::CRPluginNode{TimerManager})
    tm = n.obj
    tm.paused && return
    lvar = LOOP_VAR_REF[]
    
    timers = tm.timers
    start, stop = 1, length(timers)
    dt = lvar.delta_seconds

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

clear!(tm::TimerManager) = empty!(tm.timers)
Cruise.shutdown!(n::CRPluginNode{TimerManager}) = clear!(n.obj)

export addtimer!, ontimeout, CRTimer, TIMERPLUGIN, TimerManager, clear!

end # module