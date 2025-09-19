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

There are some interesting game engine being made in Julia like [B+ engine]() by William Mannings, [Julgame]() by Kyjor or even [GameZero]().
So why making another engine instead of contributing to them?

Well if I put the aside the learning treasure that is the construction of an engine, I would say that none of them matched my vision.

Cruise is a game engine build for compatibility, modularity and performances. It's build in a way the users is not bounded to any given library or rendering backend. This way, game are made only one time with Cruise and can be run EVERYWHERE (julia can run), from your old computer to a brand new one on every plateform (except mobile and consoles for now).

## Modules

> The following structure is just abstract, Cruise.jl isn't really structured in such set of tools. It's just a way to illustrate it's internal.

### Core

- [GDMathLib.jl](https://github.com/Gesee-y/GDMathLib.jl): The mathematics toolbox. It contains gamedev functions (lerp, slerp, etc), stack-allocated structure for optimized performances, vectors and quaternions manipulation, optimized matrix manipulation, box and circles, extensible coordinate system, colors and more.

- [NodeTree.jl](https://github.com/Gesee-y/NodeTree.jl): Trees manipulation to create `SceneTree`s and any parent-child relationship.

- [EventNotifiers.jl](https://github.com/Gesee-y/EventNotifiers.jl): A reactive module. It allow you to create events with a Godot like syntax (`@Notifyer MY_EVENT(x::int)`) and manipulate them by modifying their states in an OpenGL like manner, allowing easy traceability, support for synchronous and asynchronous callbacks, patent-child relationships,  states serialization/deserialization and more.

### Swappable Modules

- [Arceus.jl](https://github.com/Gesee-y/Arceus.jl): A decision making system based on `trait`s and relying on bitboard. It's made to get the behavior corresponding to a given combination of traits in less than 20ns (for the slowest backend, the best one can reach 2-3 ns), saving us from endless branching.

- [ReAnimation.jl](https://github.com/Gesee-y/ReAnimation.jl): An animation system. It's built with a layer architecture where low level structures compose themselves to form high level structures (from mere keyframes to multitracks player). This offers tons of interpolations and easing with and easy to extend structure, animation frame, async/parallel animation, bindings (to bound a mutable object to an animation), animation player, tracks and soon blend tree, animation graphs and more.

- [WavesFlow.jl](https://github.com/Gesee-y/WavesFlow.jl]: This is an audio engine. It offers audio streaming, effects, audio groups and bus, mixing and soon spatial audio.

- [Interactions.jl](https://github.com/Gesee-y/Interactions.jl): A 2D/3D physics engine. It support particles, collisions detection, forces, contacts resolution, integration using Verlet Integrator, constraints and more.

- [ReactiveECS.jl](https://github.com/Gesee-y/ReactiveECS.jl): A modular and high performance reactive ECS. It's based on a reactive pipeline where systems register to a given query and at each tick, the manager dispatch the data to the systems. Using a database like storage system + partitioning, this ECS can produce industry grade performance (even the fastest ECS on some operations) while offering extreme flexibility with systems chaining, runtime system injection (even in chains) and `HierarchicalLock` for manual but granular concurrency safety.

### Core Systems

> This doesn't mean that Cruise.jl is too much bounded to these system, it just mean that the best way to interact with Cruise.jl is through them.

- [Outdoors.jl]()

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
