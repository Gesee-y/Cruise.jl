# Cruise engine v0.1.0: Windows creation

In this section, we will see how to open a window with Cruise.
First of all import Cruise (Don't make these manipulations in the REPL, at least you encapsulate it in a function)

```julia
using Cruise
```

Then we create a new app:

```julia
app = CruiseApp()
```

Now we have to make a window with the function `CreateWindow`:

```julia
win = CreateWindow(app, SDLStyle, SDLRender, "My First Window", 640, 480)
```

Okay, there are some important points explain now:
   
   - We pass our app to `CreateWindow` as first argument, this will store and instance of the window in the app for event management
   - The second argument `SDLStyle` indicate which style of window you want to use (in future release, you will be able to specify `GLFWStyle`)
   - The third argument `SDLRender` is the rendering backend we want to use, in our cas, we will use SDL rendering backend.
   - Then the remaining arguments are the title, width and heigth of our window.

But if you just launch this code like that, you will have a bad time trying to close the  window because it's not receiving inputs yet. That's where our game loop comes in handy. Just do:

```julia
@gameloop app begin end
```

And your window should be behaving normally. That's because the gameloop internally update the events of the windows.
The loop will stop when you will close the window.
You can create multiple windows, the loop will stop when all of them will be closed (at least you overrided this behavior, we will see more about that later).