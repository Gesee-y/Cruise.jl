include(joinpath("..","..", "src", "Cruise.jl"))

using .Cruise

const window_size = Vec2(600,400)

const app = CruiseApp()
const win = CreateWindow(app, SDLStyle, SDLRender, "Load Image",window_size...)

img = @crate "assets|001.png"::ImageCrate

texture = Texture(context(win),img)
obj = Object(Vec2f(0,0),Vec2f(1,1),texture)
pos = obj.rect.origin

AddObject(win, obj)

@gameloop app begin
	pos.x += IsKeyPressed(instance(win),"RIGHT") - IsKeyPressed(instance(win),"LEFT")
	pos.y += IsKeyPressed(instance(win),"DOWN") - IsKeyPressed(instance(win),"UP")
end
