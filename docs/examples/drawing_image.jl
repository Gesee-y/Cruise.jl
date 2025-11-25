using Cruise
using Cruise.ODPlugin
using Cruise.HZPlugin

using SDLOutdoors, SDLHorizons

app = CruiseApp()

merge_plugin!(app, ODPLUGIN)
merge_plugin!(app, HZPLUGIN)

win = CreateWindow(SDLStyle, "My First Window", 640, 480)
winptr = GetStyle(win).window
backend = CreateBackend(SDLRender, winptr, 640, 480)

img = @crate "assets|001.png"::ImageCrate

pos = Vec2f(0,0)
texture = Texture(backend, img)

@gameloop max_fps=60 begin
    
    pos.x += IsKeyPressed(win, "RIGHT") - IsKeyPressed(win, "LEFT")
    pos.y += IsKeyPressed(win, "DOWN") - IsKeyPressed(win, "UP")

    DrawTexture2D(backend, Main.texture, Rect2Df(pos...,1,1))
    app.ShouldClose && shutdown!()
end