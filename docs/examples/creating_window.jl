include(joinpath("..", "..", "src", "Cruise.jl"))

using .Cruise
using .Cruise.ODPlugin

app = CruiseApp()
Close = Ref(false)

merge_plugin!(app, ODPLUGIN, ODPlugin.PHASE)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)

Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

@gameloop max_fps=60 begin
   Close[] && shutdown!()
end