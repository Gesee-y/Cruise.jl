include(joinpath("..", "..", "src", "Cruise.jl"))

using .Cruise

app = CruiseApp()

@gameloop max_fps=60 app begin
   println("delta seconds: $(LOOP_VAR.delta_seconds)")
   # Simulate a 10-second delay before shutting down
   LOOP_VAR.frame_idx > 600 && shutdown!()
end