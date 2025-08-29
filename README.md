# Cruise.jl v0.2.0 — A 2D/3D Game Engine for Julia

Julia has proven itself in fields like scientific computing, machine learning, and data visualization. But for game development, its ecosystem has remained... timid.

**Cruise.jl** fills that gap.

It’s not just a wrapper or a framework — Cruise is a modular, performant, and backend-agnostic game engine written entirely in Julia. With Cruise, Julia isn't just a language for science anymore — it becomes a serious tool for building games.

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

> Most Julia game libraries doesn't provide all the tools you need in order to make a games.

Cruise gives you **complete control** with modular pieces that fit together naturally. It’s designed for developers who want **performance**, **clarity**, and **power** — without being locked into a monolithic architecture.

If you’ve ever wanted to build a game engine, experiment with rendering pipelines, or just explore real-time systems in Julia...

Cruise isn’t just a tool — it’s a playground.

---

## Architecture Overview

Cruise is a **composable game engine** built on a set of specialized modules. Each one can be used independently, but Cruise connects them into a coherent system.

| Module                                                                           | Purpose                                                                    |
| -------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [`Outdoors`](https://github.com/Gesee-y/Outdoors.jl)                             | Backend-agnostic window management using a microkernel pattern             |
| [`Notifyers`](https://github.com/Gesee-y/Notifyers.jl)                           | Reactive event system with states and signal-like behavior                 |
| [`ReactiveECS`](https://github.com/Gesee-y/ReactiveECS.jl)                       | High-performance ECS with reactive pipelines and runtime system injection  |
| [`MathLib`](https://github.com/Gesee-y/GDMathLib.jl)       | Vector/matrix math library tailored for game development                   |
| [`NodeTree`](https://github.com/Gesee-y/NodeTree.jl)                             | Generic scene/tree graph manager, used for scene traversal and hierarchies |
| [`Crates`](https://github.com/Gesee-y/Cruise.jl/blob/main/src/Crates)            | Asset/resource loader and lifecycle manager                                |
| [`Arceus`](https://github.com/Gesee-y/Arceus.jl)                                 | Bitboard-based behavioral logic system (static decision graphs)            |
| [`Interactions`](https://github.com/Gesee-y/Interactions.jl) | 2D/3D physics engine: particles, collisions, resolution                    |
| [`Horizons`](https://github.com/Gesee-y/Horizons.jl)     | Multi-backend renderer (SDL implemented, OpenGL coming)                    |
| [`Waves`](https://github.com/Gesee-y/WavesFlow.jl)              | Full audio system supporting mixing, effects and more                      |
| [`Reanimation`](https://github.com/Gesee-y/ReAnimation.jl)  | Animation module with interpolations, easing and more                      |

---

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

> I’m not a physicist nor a rendering expert, so any contribution from people with deep experience in those areas would be highly valuable to push Cruise further.

---

## License

Cruise is released under the **GNU GPL v3.0**.
See [LICENSE](https://github.com/Gesee-y/Cruise.jl/blob/main/LICENSE) for details.

---
