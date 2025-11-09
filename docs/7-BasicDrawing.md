# Cruise Engine v0.3.0: Basic Drawings

This section covers how to draw basic shapes using Cruise.

---

## Setup

Start by initializing a window and application as usual:

```julia
using Cruise
using ODPlugin

app = CruiseApp()
merge_plugin!(app, ODPLUGIN)
win = CreateWindow(SDLStyle, "Drawing Window", 640, 480)
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
backend = CreateBackend(GetWindowPtr(GetStyle(win)), SDLRender, GetWindowSize(win)...)
```

---

## Setting Draw Color

Use `SetDrawColor` to define the current drawing color:

```julia
SetDrawColor(backend, (0, 5, 3, 8))  # RGBA format
```

> **Note:** The alpha channel only affects rendering if blending is enabled using `SetAlphaBlendMode(context, SDL_BLENDMODE_BLEND)`.

---

## Drawing Points

Use `DrawPoint` to draw a single point:

```julia
@gameloop app begin
    DrawPoint(backend, (50, 50))
end
```

To draw multiple points at once:

```julia
@gameloop app begin
    DrawPoints(backend, [(10, 50), (20, 55), (27, 62)])
end
```

Using a batch like this is more efficient than drawing points individually.

---

## Drawing Lines

Draw a single line:

```julia
@gameloop app begin
    DrawLine(backend, (50, 0), (70, 30))
end
```

To draw connected lines between multiple points:

```julia
@gameloop app begin
    DrawLines(backend, Vec2(1, 5), Vec2(5, 9), Vec2(78, 6))
end
```

You may also pass tuples like `(1, 5), (5, 9), ...` instead of `Vec2`.

---

## Drawing Rectangles

To draw a rectangle outline:

```julia
@gameloop app begin
    DrawRect(backend, Rect2Di(0, 0, 50, 50))
end
```

To draw a filled rectangle:

```julia
@gameloop app begin
    FillRect(backend, Rect2Di(10, 10, 30, 30))
end
```

Rectangles using floating-point coordinates should use the `*F` variants:

* `DrawRectF`
* `FillRectF`
* `DrawRectsF`
* `FillRectsF`

You can draw multiple rectangles at once:

```julia
@gameloop app begin
    FillRects(backend, [Rect2Di(10,10,30,30), Rect2Di(50,50,20,40)])
end
```

---