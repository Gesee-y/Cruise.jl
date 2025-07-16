# Cruise Engine v0.1.0 – Input Handling

Input management is critical for interactive applications. Cruise provides a simple yet powerful API to track keyboard and mouse input with ease.

---

## Setup

Start by initializing your application and opening a window:

```julia
using Cruise

app = CruiseApp()
win = CreateWindow(app, SDLStyle, SDLRender, "Inputs Receiver", 640, 480)
```

---

## Keyboard Input

Cruise offers several functions to track the state of keys. These must be called within an **active game loop**, otherwise no input will be registered.

### Key State Functions

All functions take the `win.inst` as first argument, followed by a string key name:

* `IsKeyPressed(win.inst, "A")`
  → Returns `true` if key **A** is currently held down.

* `IsKeyJustPressed(win.inst, "LEFT")`
  → Returns `true` if the **Left Arrow** was pressed **this frame**.

* `IsKeyReleased(win.inst, "R")`
  → Returns `true` if key **R** is currently **not pressed**.

* `IsKeyJustReleased(win.inst, "A")`
  → Returns `true` if key **A** was released **this frame**.

---

## 🖱 Mouse Input

Mouse buttons are handled in a similar way:

* `IsMouseButtonPressed(win.inst, "LEFT_BUTTON")`
* `IsMouseButtonJustPressed(win.inst, "RIGHT_BUTTON")`
* `IsMouseButtonReleased(win.inst, "MIDDLE_BUTTON")`
* `IsMouseButtonJustReleased(win.inst, "LEFT_BUTTON")`

Mouse constants include:
`"LEFT_BUTTON"`, `"RIGHT_BUTTON"`, `"MIDDLE_BUTTON"`

---

## Input Maps

To avoid hardcoding keys throughout your codebase, you can define **input maps** using the `@InputMap` macro:

```julia
@InputMap Up("UP", "W")  # Map the "Up" action to UP arrow or W key
```

Once declared, `Up` can be passed directly to the input functions:

```julia
if IsKeyPressed(win.inst, Up)
    println("Moving Up!")
end
```

You can define multiple actions this way to keep your input layer clean and maintainable.

---

## Important

Cruise processes inputs **only during the game loop**. If you skip the loop, input polling will freeze, and the window may appear unresponsive.

Make sure to wrap your logic in a loop like this:

```julia
@gameloop app begin
    if IsKeyPressed(win.inst, "Q")
        shutdown!(app)
    end
end
```

---

## Summary

You now know how to:

* Track keyboard and mouse input
* Detect input states per frame
* Use input maps for better abstraction

In the next section, we’ll explore rendering within the game loop and how to use `@frame` for visual output.