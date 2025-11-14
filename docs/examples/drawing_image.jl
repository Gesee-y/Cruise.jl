using Cruise
using ODPlugin
using HZPlugin

app = CruiseApp()
Close = Ref(false)

merge_plugin!(app, ODPLUGIN, ODPlugin.PHASE)
merge_plugin!(app, HZPLUGIN, HZPlugin.PHASE)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)
winptr = GetStyle(win).window

backend = CreateBackend(SDLRender, winptr, 640, 480)

Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

img = @crate "assets|001.png"::ImageCrate

added = false
pos = Vec2f(0,0)
texture = Texture(backend, img)

@gameloop max_fps=60 begin
    
    Main.pos.x += IsKeyPressed(win, "RIGHT") - IsKeyPressed(win, "LEFT")
    Main.pos.y += IsKeyPressed(win, "DOWN") - IsKeyPressed(win, "UP")

    DrawTexture2D(backend, Main.texture, Rect2Df(pos...,1,1))
    Close[] && shutdown!()
end