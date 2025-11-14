using Cruise
using ODPlugin
using HZPlugin

app = CruiseApp()
Close = Ref(false)

merge_plugin!(app, ODPLUGIN, ODPlugin.PHASE)
merge_plugin!(app, HZPLUGIN, HZPlugin.PHASE)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)
winptr = GetStyle(win).window

RegisterBackend(SDLRender, winptr, 640, 480)

Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

@gameloop max_fps=60 begin
    backend = GetBackend(winptr)
    if !isnothing(backend)

        DrawPoint2D(backend, iRGBA(0, 50, 30, 8), Vec2f(50, 50))
        DrawLine2D(backend, iRGBA(0, 50, 30, 8), Vec2f(100, 100), Vec2f(150, 150))
    end
    Close[] && shutdown!()
end