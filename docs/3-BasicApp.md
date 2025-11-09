# Cruise Engine v0.3.0: Creating a Basic App

In this section, we’ll learn how to set up a minimal Cruise application **without opening a window**. This will help you understand the basic structure of a Cruise-based app and how the main loop is handled.

---

## Step 1: Import the Package

Assuming you’ve already installed Cruise:

```julia
julia> using Cruise
```

---

## Step 2: Create a New App

To create a new Cruise application instance:

```julia
julia> app = CruiseApp()
```

> `CruiseApp()` returns a **singleton**. This means subsequent calls will return the same `app` instance.

---

## Step 3: Define the Game Loop

You can now define a game loop using the `@gameloop` macro:

```julia
julia> @gameloop max_fps=60 app begin
           println("delta seconds: $(LOOP_VAR.delta_seconds)")
           # Simulate a 10-second delay before shutting down
           LOOP_VAR.frame_idx > 600 && shutdown!(app)
       end
```

---

## Explanation

Let’s break down what happens in this code:

* `@gameloop` is a macro that starts the main loop. It accepts the following keyword arguments:

  * `max_fps`: Maximum number of frames per second (default: `60`)
  * `max_duration`: Maximum allowed value for `delta_seconds` (default: `0.3`)

* The macro takes two arguments:

  * The `app` instance
  * A block of code to execute every frame

### `LOOP_VAR` Contents

Inside the loop, you can access loop-specific data via the `LOOP_VAR` struct:

| Field                | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `last_frame_time_ns` | Time in nanoseconds when the last frame was executed |
| `frame_idx`          | Current frame index (starts at 0)                    |
| `delta_seconds`      | Time elapsed between the current and last frame      |
| `max_fps`            | Current maximum FPS                                  |
| `max_duration`       | Cap for `delta_seconds` to avoid large jumps         |

### Shutdown Mechanism

```julia
shutdown!(app)
```

This function stops the app and cleans up all allocated resources.

---