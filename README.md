# Project is paused
Until I get a new computer.

# Cruise.jl v0.2.0 : A 2D/3D Game Engine for Julia

Julia has proven itself in fields like scientific computing, machine learning, and data visualization. But for game development, its ecosystem has remained... timid.

**Cruise.jl** fills that gap.

It’s not just a wrapper or a framework — Cruise is a modular, performant, and backend-agnostic game engine written entirely in Julia. With Cruise, Julia isn't just a language for science anymore, it becomes a serious tool for building games.

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

## Why Cruise?

There are some interesting game engines being made in Julia, like [B+ engine]() by William Mannings, [Julgame]() by Kyjor, or even [GameZero]().  
So why create another engine instead of contributing to them?

Well, if I put aside the learning treasure that is building an engine, I would say that none of them matched my vision.

Cruise is a game engine built for compatibility, modularity, and performance. It's designed so that users are not bound to any given library or rendering backend. This way, games are made only once with Cruise and can be run EVERYWHERE Julia can run — from your old computer to a brand-new one — on every platform (except mobile and consoles for now).

## Modules

> The following structure is just abstract. Cruise.jl isn't really structured as such a set of tools. It's just a way to illustrate its internals.

### Core

- [GDMathLib.jl](https://github.com/Gesee-y/GDMathLib.jl): The mathematics toolbox. It contains game-dev functions (lerp, slerp, etc.), stack-allocated structures for optimized performance, vector and quaternion manipulation, optimized matrix operations, boxes and circles, an extensible coordinate system, colors, and more.

- [NodeTree.jl](https://github.com/Gesee-y/NodeTree.jl): Tree manipulation to create `SceneTree`s and any parent–child relationship.

- [EventNotifiers.jl](https://github.com/Gesee-y/EventNotifiers.jl): A reactive module. It allows you to create events with a Godot-like syntax (`@Notifyer MY_EVENT(x::Int)`) and manipulate them by modifying their states in an OpenGL-like manner. Features include easy traceability, support for synchronous and asynchronous callbacks, parent–child relationships, state serialization/deserialization, and more.

### Swappable Modules

- [Arceus.jl](https://github.com/Gesee-y/Arceus.jl): A decision-making system based on `trait`s and relying on bitboards. It's designed to get the behavior corresponding to a given combination of traits in less than 20 ns (for the slowest backend; the fastest one can reach 2–3 ns), avoiding endless branching.

- [ReAnimation.jl](https://github.com/Gesee-y/ReAnimation.jl): An animation system built with a layered architecture where low-level structures compose into high-level ones (from simple keyframes to multi-track players). This offers tons of interpolations and easing with an easy-to-extend structure, animation frames, async/parallel animation, bindings (to bind a mutable object to an animation), animation players, tracks, and soon blend trees, animation graphs, and more.

- [WavesFlow.jl](https://github.com/Gesee-y/WavesFlow.jl): An audio engine. It offers audio streaming, effects, audio groups and buses, mixing, and soon spatial audio.

- [Interactions.jl](https://github.com/Gesee-y/Interactions.jl): A 2D/3D physics engine. It supports particles, collision detection, forces, contact resolution, integration using a Verlet integrator, constraints, and more.

- [ReactiveECS.jl](https://github.com/Gesee-y/ReactiveECS.jl): A modular and high-performance reactive ECS. It's based on a reactive pipeline where systems register to a given query, and at each tick, the manager dispatches data to the systems. Using a database-like storage system plus partitioning, this ECS can deliver industry-grade performance (even the fastest ECS on some operations) while offering extreme flexibility with system chaining, runtime system injection (even in chains), and `HierarchicalLock` for manual but granular concurrency safety.

### Core Systems

> This doesn't mean that Cruise.jl is strictly bound to these systems — it just means that the best way to interact with Cruise.jl is through them.

- [Outdoors.jl](https://github.com/Gesee-y/Outdoors.jl): A backend-agnostic window manager. Based on a microkernel architecture, it offers a clear interface to define window and event management backends. SDL and GLFW are already supported with a unified way to manage inputs.

- [Horizons.jl](https://github.com/Gesee-y/Horizons.jl): A backend-agnostic rendering engine. Based on command buffers, you just need to define your own commands or create new actions for them to build your own rendering backend. The SDL backend is available with optimized post processing,  upscaling/downscaling, object hierarchy and logging.

- [Crates.jl](https://github.com/Gesee-y/Crates.jl): An asset loader and manager. It offers an easy-to-extend interface to load any type of file and manage their lifecycle. Hot reloading is in progress.

- **Cruise.jl**: The package itself offers several tools and utilities, such as a plugin system to add your own modules and manage their lifecycle in the game loop, a `@gameloop` macro, linking modules together, and managing their processing order.

## Example: Moving an Image with Input

```julia
using Cruise

# We create a new app
app = CruiseApp()

# Initialise SDL style window with a SDL renderer
win = CreateWindow(app, SDLStyle, SDLRender, "Example", 640, 480)

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

## Roadmap

From now on, I will focus on testing, documenting and patching. But here is a list of the incoming features:

- [] Animation Graph
- [] Sprites, AnimatedSprite, Skeletal animations
- [] Spatial sound
- [] 3D Physics
- [] 3D Render

## Contribution

Each Cruise module is **self-contained** and can be developed in isolation. Whether you're fixing bugs, writing documentation, or improving performance — you're welcome to contribute.

* Choose the module you want to improve.
* Fork, hack, PR. Simple.

---

## License

Cruise is released under the **GNU GPL v3.0**.
See [LICENSE](https://github.com/Gesee-y/Cruise.jl/blob/main/LICENSE) for details.

---
