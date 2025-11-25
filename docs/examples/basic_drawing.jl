using Cruise
using Cruise.ODPlugin
using Cruise.HZPlugin

using SDLOutdoors, SDLHorizons

app = CruiseApp()

merge_plugin!(app, ODPLUGIN)
merge_plugin!(app, HZPLUGIN)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)
backend = InitBackend(SDLRender, GetStyle(win).window, 640, 480)

@gameloop max_fps=60 begin
    DrawPoint2D(backend, iRGBA(0, 50, 30, 8), Vec2f(50, 50))
    DrawLine2D(backend, iRGBA(0, 50, 30, 8), Vec2f(100, 100), Vec2f(150, 150))
    app.ShouldClose && shutdown!()
end