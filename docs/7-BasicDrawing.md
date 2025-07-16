# Cruise Engine v0.1.5 – Basic Drawings

This section covers how to draw basic shapes using Cruise.

---

## Setup

Start by initializing a window and application as usual:

```julia
using Cruise

app = CruiseApp()
win = CreateWindow(app, SDLStyle, SDLRender, "Drawing Window", 640, 480)
```

---

## Setting Draw Color

Use `SetDrawColor` to define the current drawing color:

```julia
SetDrawColor(context(win), (0, 5, 3, 8))  # RGBA format
```

> **Note:** The alpha channel only affects rendering if blending is enabled using `SetAlphaBlendMode(context, SDL_BLENDMODE_BLEND)`.

---

## Drawing Points

Use `DrawPoint` to draw a single point:

```julia
@gameloop app begin
    DrawPoint(context(win), (50, 50))
end
```

To draw multiple points at once:

```julia
@gameloop app begin
    DrawPoints(context(win), [(10, 50), (20, 55), (27, 62)])
end
```

Using a batch like this is more efficient than drawing points individually.

---

## Drawing Lines

Draw a single line:

```julia
@gameloop app begin
    DrawLine(context(win), (50, 0), (70, 30))
end
```

To draw connected lines between multiple points:

```julia
@gameloop app begin
    DrawLines(context(win), Vec2(1, 5), Vec2(5, 9), Vec2(78, 6))
end
```

You may also pass tuples like `(1, 5), (5, 9), ...` instead of `Vec2`.

---

## Drawing Rectangles

To draw a rectangle outline:

```julia
@gameloop app begin
    DrawRect(context(win), Rect2Di(0, 0, 50, 50))
end
```

To draw a filled rectangle:

```julia
@gameloop app begin
    FillRect(context(win), Rect2Di(10, 10, 30, 30))
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
    FillRects(context(win), [Rect2Di(10,10,30,30), Rect2Di(50,50,20,40)])
end
```

---

## Summary

You now know how to:

* Set draw colors (with or without alpha)
* Draw points, lines, and rectangles (filled or outlined)
* Use batched drawing for performance

In the next section, we’ll cover how to draw **images and textures**.
