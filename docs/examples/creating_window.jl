using Cruise
using Cruise.ODPlugin
using SDLOutdoors

app = CruiseApp()

merge_plugin!(app, ODPLUGIN)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)

@gameloop max_fps=60 begin
   app.ShouldClose && shutdown!()
end