using Cruise

include("timer.jl")
include("pauser.jl")

using .PausePlugin

app = CruiseApp()

merge_plugin!(app, PAUSEPLUGIN, :preupdate)
win = PausePlugin.CreateWindow(PausePlugin.SDLStyle, "Pauser", 320, 240)

i = 0
@gameloop maxfps=60 begin
    if LOOP_VAR.frame_idx % 50 == 0
        timer = PausePlugin.addtimer!(rand())
        j = i
        PausePlugin.ontimeout(timer) do
            println("Timer $(j) dead.")
        end

        Main.i += 1
    end

    LOOP_VAR.frame_idx > 1000 && shutdown!()
end