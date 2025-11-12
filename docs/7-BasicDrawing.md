# Cruise Engine v0.3.0: Basic Drawings

This section covers how to draw basic shapes using Cruise.

---

## Setup

Start by initializing a window and application as usual:

```julia
using Cruise
using ODPlugin

app = CruiseApp()
Close = Ref(false)

merge_plugin!(app, ODPLUGIN)
win = CreateWindow(SDLStyle, "Drawing Window", 640, 480)

Outdoors.connect(NOTIF_QUIT_EVENT) do
    Close[] = true
end
```

---

## Setting a renderer 

For this you need a plugin for rendering. For now we recommend you to use [HZPlugin.jl](https://github.com/Gesee-y/HZPlugin.jl) which allows you to use [Horizons.jl](https://github.com/Gesee-y/Horizons.jl) into Cruise.
To add it, just do:

```julia-repl
julia> ]add HZPlugin 
```

Then in your script you just do:

```julia

using HZPlugin 

merge_plugin!(app, HZPLUGIN)
```

Now to create a new backend you do:

```julia
backend = CreateBackend(SDLRender, GetStyle(win).style, 640, 480)
```

---

## Drawing Points

Use `DrawPoint2D` to draw a single point:

```julia
@gameloop app begin
    DrawPoint2D(backend, iRGBA(0, 50, 30, 8), Vec2f(50, 50))
    Close[] && shutdown!()
end
```
> **Note:** For the `SDLRender` backend the alpha channel only affects rendering if blending is enabled using `SetAlphaBlendMode(context, SDL_BLENDMODE_BLEND)`.

---

## Drawing Lines

Draw a single line:

```julia
@gameloop app begin
    DrawLine2D(backend, BLUE,(50, 0), (70, 30))
    Close[] && shutdown!()
end
```

---

## Drawing Rectangles

To draw a rectangle:

```julia
@gameloop app begin
    DrawRect2D(backend, PURPLE, Rect2Df(0, 0, 50, 50), true) # filled = true, meaning the rectangle should be filled, not just the outlines
    Close[] && shutdown!()
end
```

---