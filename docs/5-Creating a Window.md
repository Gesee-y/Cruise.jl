# Cruise Engine v0.3.0: Window Creation

This section explains how to create and manage windows using Cruise. Windows are at the core of any graphical application, and Cruise makes it easy to open and control them.

> **Note:** Do **not** run these commands directly in the REPL unless they are wrapped in a function. Window creation and the game loop are better handled in a structured environment (script or function).

---

## Step 1: Import Cruise

```julia
using Cruise
```

---

## Step 2: Create a Cruise Application

Every Cruise-based project begins with creating a central application instance:

```julia
app = CruiseApp()
```

This instance acts as a container for all windows, events, and state handling.

---

## Step 3: Use the windowing plugin

In order to create a window, you need a dedicated plugin for that. We recommend you the [ODPlugin](https://github.com/Gesee-y/ODPlugin.jl) which allows you to use [Outdoors.jl](https://github.com/Gesee-y/Outdoors.jl) into Cruise. To add it, you can use the REPL and just do:

```julia-repl
julia> ]add ODPlugin
```

Then in your script you just do:

```julia
using ODPlugin 

merge_plugin!(app, ODPLUGIN)
```

## Step 4: Create a Window

Use `CreateWindow` to initialize a new window:

```julia
win = CreateWindow(app, SDLStyle, SDLRender, "My First Window", 640, 480)
```

### Explanation of Parameters:

| Parameter           | Description                                                                                         |
| ------------------- | --------------------------------------------------------------------------------------------------- |
| `app`               | The application instance that will manage the window. Required for event handling.                  |
| `SDLStyle`          | The windowing backend. Currently, only `SDLStyle` is available. Support for `GLFWStyle` is planned. |
| `SDLRender`         | The rendering backend to use. Here, we use SDL's 2D renderer.                                       |
| `"My First Window"` | The window title (displayed in the title bar).                                                      |
| `640`, `480`        | The width and height of the window, in pixels.                                                      |

---

## Step 4 – Run the Game Loop

Creating the window isn’t enough. It won’t respond to input or update properly unless a **game loop** is running. Here's how to start it:

```julia
@gameloop app begin
end
```

The `@gameloop` macro will:

* Poll and dispatch window events
* Refresh each window
* Keep the app running until all windows are closed

> **By default**, the loop exits when **all windows are closed**. You can override this behavior (covered in a later section).

---

## Multiple Windows

Cruise allows you to create multiple windows by calling `CreateWindow` multiple times. All windows are managed by the same `CruiseApp` instance. The game loop automatically keeps track of them.

Example:

```julia
win1 = CreateWindow(app, SDLStyle, SDLRender, "Main", 800, 600)
win2 = CreateWindow(app, SDLStyle, SDLRender, "Debug", 400, 300)

@gameloop app begin
end
```

Closing **both** windows will stop the loop, unless configured otherwise.

---