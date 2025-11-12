# Cruise Engine v0.3.0: Drawing Images

This section explains how to load and render images in Cruise.

---

## Setup

As always, initialize the application, window and renderer:

```julia
using Cruise
using ODPlugin, HZPlugin

app = CruiseApp()
Close = Ref(false)

merge_plugin!(app, ODPLUGIN)
merge_plugin!(app, HZPLUGIN)

win = CreateWindow(SDLStyle, "Image Example", 640, 480)
backend = CreateBackend(SDLRender, GetStyle(win).window)

Outdoors.connect(NOTIF_QUIT_EVENT) do
    Close[] = true
end
```

---

## Loading an Image

In Cruise, images are loaded as `Crate`. A `Crate` is any managed resource (image, sound, font, etc.) that is automatically tracked and released when the application shuts down.

Assuming you have an image at `assets/img.png`, load it like this:

```julia
img = @crate "assets|img.png"::ImageCrate
```

This registers the image with Cruise’s resource system.

---

## Creating a Texture

To render the image, convert the crate into a `Texture`:

```julia
texture = Texture(backend, img)
```

---

## Drawing the texture

To draw a texture, you just have to call `DrawTexture2D`

```julia
DrawTexture2D(backend, texture, Rect2Df(0,0,1,1))
```

The last argument define the position and the scale of the texture (`Rect2Df(x,y, scalex, scaley)`).

---

## Interactive Example

Let’s control the image using arrow keys:

```julia
pos = obj.rect.origin

@gameloop app begin
    pos.x += IsKeyPressed(win, "RIGHT") - IsKeyPressed(instance(win), "LEFT")
    pos.y += IsKeyPressed(win, "DOWN") - IsKeyPressed(win, "UP")

    DrawTexture2D(backend, texture, Rect2Df(pos...,1,1))
    Close[] && shutdown()
end
```

This will move the object based on arrow key input. Julia can treats booleans as `Int`s, so this works as expected (`true = 1`, `false = 0`).

---
