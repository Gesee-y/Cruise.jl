# Cruise Engine v0.1.0: Input handling

In this section, we will see how to handle inputs in your games. You will see, it's quite easy.
First our basic setup:

```julia
using Cruise

app = CruiseApp()
win = CreateWindow(app, SDLStyle, SDLRender, "Inputs Receiver", 640, 480)
```

Now to get inputs, it's quite simple, just use one of the following functions:
   
   - `IsKeyPressed(win.inst, "A")`: This will check if the key A is pressed
   - `IsKeyJustPressed(win.inst, "LEFT")`: This will check if the key left arrow has been just pressed
   - `IsKeyReleased(win.inst, "R"):` This will check if the key R is released
   - `IsKeyJustReleased(win.inst, "A"):` This will check if the key A has been just released
   - The same goes for `IsMouseButtonPressed/JustPressed/...` but taking possible keys as LEFT_BUTTON, RIGHT_BUTTON

You can also create `InputMap`s to match some keys to an action using `@InputMap`

```julia
@InputMap Up("UP", "W") # Now we can do IsKeypressed(win.inst, Up) and the same with the othed
```

You can use these to make conditions in your game easily.
**Important**: You need an active game loop for events to be pooled, without it, you window will just be soft locked.