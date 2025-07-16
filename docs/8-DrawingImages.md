# Cruise Engine v0.1.5 – Drawing Images

This section explains how to load and render images in Cruise.

---

## Setup

As always, initialize the application and window:

```julia
using Cruise

app = CruiseApp()
win = CreateWindow(app, SDLStyle, SDLRender, "Image Example", 640, 480)
```

---

## Loading an Image

In Cruise, images are loaded as `Crates`. A `Crate` is any managed resource (image, sound, font, etc.) that is automatically tracked and released when the application shuts down.

Assuming you have an image at `assets/img.png`, load it like this:

```julia
img = @crate "assets|img.png"::ImageCrate
```

This registers the image with Cruise’s resource system.

---

## Creating a Texture

To render the image, convert the crate into a `Texture`:

```julia
texture = Texture(context(win), img)
```

---

## Creating a Drawable Object

To render anything on screen, you must create an `Object`. An `Object` represents something that can be drawn.

```julia
obj = Object(Vec2f(0, 0), Vec2f(1, 1), texture)
```

* The first argument is the position (`Vec2f(x, y)`)
* The second is the scale (`Vec2f(sx, sy)`)
* The third is the texture

> `Object` internally maintains a transformation matrix, but Cruise handles rendering directly via SDL’s batch system, so matrix calculations aren't required manually.

---

## Adding to the Render Tree

To make an object visible, add it to the render tree:

```julia
AddObject(win, obj)
```

You can build hierarchies of objects using:

```julia
AddChildObject(parent, child)
```

This allows one object to be rendered relative to another (e.g., for UI elements or skeletal animations).

To remove an object from the tree:

```julia
DestroyObject(obj)
```

---

## Interactive Example

Let’s control the image using arrow keys:

```julia
pos = obj.rect.origin

@gameloop app begin
    pos.x += IsKeyPressed(instance(win), "RIGHT") - IsKeyPressed(instance(win), "LEFT")
    pos.y += IsKeyPressed(instance(win), "DOWN") - IsKeyPressed(instance(win), "UP")
end
```

This will move the object based on arrow key input. Julia can treats booleans as `Int`s, so this works as expected (`true = 1`, `false = 0`).

---

## Summary

In this section, you've learned how to:

* Load images using `@crate`
* Convert them to textures
* Create drawable objects
* Add them to the scene
* Move them interactively

Next, we'll look at `Transform`s and how to manage object positioning and rotation more cleanly.
