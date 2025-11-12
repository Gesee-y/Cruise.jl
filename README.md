# Cruise.jl v0.3.0 : A Powerful Game Engine Kernel for Julia

![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()
[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://gesee-y.github.io/Cruise.jl)

**Cruise.jl**, a game engine kernel with a powerful plugin system to allows you to build complex systems without too much overhead.

---

## Installation

**Stable release:**

```julia
julia> ] add Cruise
````

**Development version:**

```julia
julia> ] add https://github.com/Gesee-y/Cruise.jl
```

---

## Features

- **Plugin system**: Built around a DAG (Direct Acyclic Graph), it allows you to extend Cruise, share your own plugin and collaborate without too much hassle.

- **Assets Loading and Management**: Cruise can load a wide variety of files (Images, sounds and soon meshes) and manage/reuse them during the game lifecycle.

- **JIT compiled**: Which means you can dynamically add code to your program while it's running, allowing you to do hot reloading or live coding.

- **Event System**: Cruise provides you 2 event system, a lightweight synchronous one that can be use for simple cases, and a complex one leveraging the full powers of reactive programming such as merging, filtering, delays, throttling,  etc.

- **Temporary storage**: To easily share data among your systems, it also support TTL (Time To Live) for data and provides events and serialization support

- **Make your own structure**: Cruise doesn't enforce any architecture, build your game as you feel

- **Build your own engine**: Since Cruise is just a minimal core, you can just choose the set of plugins (or build your own) that perfectly match your use case.

---

## Exisitin Tools and Plugins

### Core

> These modules are included into Cruise when you add it with the package manager
- [GDMathLib.jl](https://github.com/Gesee-y/GDMathLib.jl): The mathematics toolbox. It contains game-dev functions (lerp, slerp, etc.), stack-allocated structures for optimized performance, vector and quaternion manipulation, optimized matrix operations, boxes and circles, an extensible coordinate system, colors, and more.

- [NodeTree.jl](https://github.com/Gesee-y/NodeTree.jl): Tree manipulation to create `SceneTree`s and any parent–child relationship.

- [EventNotifiers.jl](https://github.com/Gesee-y/EventNotifiers.jl): A reactive module. It allows you to create events with a Godot-like syntax (`@Notifyer MY_EVENT(x::Int)`) and manipulate them by modifying their states in an OpenGL-like manner. Features include easy traceability, support for synchronous and asynchronous callbacks, parent–child relationships, state serialization/deserialization, and more.

- [Crates.jl](https://github.com/Gesee-y/Crates.jl): An asset loader and manager. It offers an easy-to-extend interface to load any type of file and manage their lifecycle. Hot reloading is in progress.

- **Cruise.jl**: The package itself offers several tools and utilities, such as a plugin system to add your own plugins and manage their lifecycle in the game loop, a `@gameloop` macro. Provides utilities like do while loops, temporary storage, dynamic structs and more.

### Modules

> Should be added when needed into Cruise. They don't depend on the game lifecycle

- [Arceus.jl](https://github.com/Gesee-y/Arceus.jl): A decision-making system based on `trait`s and relying on bitboards. It's designed to get the behavior corresponding to a given combination of traits in less than 20 ns (for the slowest backend; the fastest one can reach 2–3 ns), avoiding endless branching.

- [ReAnimation.jl](https://github.com/Gesee-y/ReAnimation.jl): An animation system built with a layered architecture where low-level structures compose into high-level ones (from simple keyframes to multi-track players). This offers tons of interpolations and easing with an easy-to-extend structure, animation frames, async/parallel animation, bindings (to bind a mutable object to an animation), animation players, tracks, and soon blend trees, animation graphs, and more.

- [WavesFlow.jl](https://github.com/Gesee-y/WavesFlow.jl): An audio engine. It offers audio streaming, effects, audio groups and buses, mixing, and soon spatial audio.

### Plugins

- [Outdoors.jl](https://github.com/Gesee-y/Outdoors.jl): A backend-agnostic window manager. Based on a microkernel architecture, it offers a clear interface to define window and event management backends. SDL and GLFW are already supported with a unified way to manage inputs.

- [Horizons.jl](https://github.com/Gesee-y/Horizons.jl): A backend-agnostic rendering engine. Based on command buffers, you just need to define your own commands or use the existing ones and create new actions for them to build your own rendering backend. The SDL backend is available with optimized post processing, upscaling/downscaling and logging.

- [Interactions.jl](https://github.com/Gesee-y/Interactions.jl): A 2D/3D physics engine. It supports particles, collision detection, forces, contact resolution, integration using a Verlet integrator, constraints, and more.

- [ReactiveECS.jl](https://github.com/Gesee-y/ReactiveECS.jl): A modular and high-performance reactive ECS. It's based on a reactive pipeline where systems register to a given query, and at each tick, the manager dispatches data to the systems. Using a database-like storage system plus partitioning, this ECS can deliver industry-grade performance (even the fastest ECS on some operations) while offering extreme flexibility with system chaining, runtime system injection (even in chains), and `HierarchicalLock` for manual but granular concurrency safety.

## Example: Moving an Image with Input

```julia
using Cruise
using ODPlugin
using HZPlugin

# We create a new app
app = CruiseApp()

merge_plugin!(app, ODPLUGIN; phase=:preupdate)
merge_plugin!(app, HZPLUGIN)

# Initialise SDL style window with a SDL renderer
win = CreateWindow(app, SDLStyle, "Example", 640, 480)


# We import our resource as an ImageCrate
img = @crate "docs|example|assets|001.png"::ImageCrate

# Then we define our bindings
@InputMap UP("UP", "W")
@InputMap LEFT("LEFT", "A")
@InputMap DOWN("DOWN", "S")
@InputMap RIGHT("RIGHT", "D")

# We create a new renderable object
obj = Object(Vec2f(0, 0), Vec2f(1, 1), Texture(context(win), img))
AddObject(win, obj) # And we add it to the render tree

pos = obj.rect.origin

# Our game loop. It update events and render for us. Once the window will be closed, it will stop.
@gameloop app begin
    pos.x += IsKeyPressed(instance(win), RIGHT) - IsKeyPressed(instance(win), LEFT)
    pos.y += IsKeyPressed(instance(win), DOWN) - IsKeyPressed(instance(win), UP)
    println(LOOP_VAR.delta_seconds) # LOOP_VAR contain the internal data of our loop
end
```

---

## Example games

More game examples are available in [there](https://github.com/Gesee-y/Cruise-examples)

---

## Games made with Cruise

- **[Insane Pong](https://github.com/Gesee-y/Pong-GS)**: Which is an insane and rythmic version of pong with tons of shaders, events triggered by music, complex mechanics (gameplay change with the music) and more. All that with just the SDL backend.

---

## Contribution

Core Cruise's modules and plugins are self-contained, meaning they use their own interfaces to implement their functionality. This allows any contributor to do the same and stay aligned with the engine's design. Whether you're fixing bugs, writing documentation, or improving performance, you're welcome to contribute.

* Choose the module you want to improve.
* Fork, hack, PR. Simple.

---

## License

Cruise is released under the **MIT License**.
See [LICENSE](https://github.com/Gesee-y/Cruise.jl/blob/main/LICENSE) for details.

---
