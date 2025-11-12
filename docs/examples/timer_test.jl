include(joinpath("..", "..", "src", "Cruise.jl"))

using .Cruise

include("timer.jl")

using .TimerPlugin

app = CruiseApp()

merge_plugin!(app, TIMERPLUGIN, :preupdate)

i = 0
@gameloop maxfps=60 begin
    if LOOP_VAR.frame_idx % 50 == 0
        timer = addtimer!(rand())
        j = i
        ontimeout(timer) do
            println("Timer $(j) dead.")
        end

        Main.i += 1
    end
end