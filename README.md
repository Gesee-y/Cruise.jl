# Cruise.jl v0.3.0 : A 2D/3D Game Engine for Julia

[![Build Status](https://github.com/Gesee-y/Cruise.jl/actions/workflows/CI.yml/badge.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()
[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://gesee-y.github.io/Cruise.jl)

Julia has proven itself in fields like scientific computing, machine learning, and data visualization. But for game development, its ecosystem has remained... timid.

**Cruise.jl** fills that gap.

It’s not just a wrapper or a framework, Cruise is a modular, performant, and backend-agnostic game engine written entirely in Julia. With Cruise, Julia isn't just a language for science anymore, it becomes a serious tool for building games.

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

## Philosophy 

Cruise is built around a modular DAG (Directed Acyclic Graph) of plugins, this means you can easily extend or replace any part of the engine without breaking your project.
Want to swap your renderer from SDL to Vulkan? Just change a plugin.
Need a pure ECS game instead of SceneTree? Just load the ECS plugin.

Why this philosophy? Because I believe there are many excellent programmers out there, some far better than me, so I designed this engine in a way that ensures programmers won't feel constrained by my implementations.

## Why Julia

It's certainly the question most people ask themselves. And that's why I chose Julia, because it *“wasn't meant for games.”*  
Julia is a breath of fresh air, far from the thousands of C/C++ engines, finally allowing us to explore how a JIT-compiled language can perform in game development.  

Julia is fast and offers interesting features like multiple dispatch, a powerful macro system, and more, all with an easy-to-learn syntax.

Using a JIT-compiled language offers some interesting features, such as:

- **Live coding**: Write your game code and see the results instantly.  
- **Fast prototyping**: Thanks to Julia’s simple syntax and powerful code injection, you can build and tweak your games quickly.  

It also makes it possible to run your game and adjust it directly from an interactive REPL.

## Why Cruise?

There are some interesting game engines being made in Julia, like [B+ engine](https://github.com/heyx3/Bplus.jl) by William Mannings, [Julgame](https://github.com/Kyjor/JulGame.jl) by Kyjor, or even [GameZero](https://github.com/aviks/GameZero.jl).  
So why create another engine instead of contributing to them?

Well, if I put aside the learning treasure that is building an engine, I would say that none of them matched my vision.

Cruise is a game engine built for compatibility, modularity, and performance. It's designed so that users are not bound to any given architecture, library or rendering backend. This way, games are made with Cruise by choosing the optimal tools for every task. A SceneTree for UI, an ECS for the logics, Dataflow for processing, your own architecture for custom mechanics, etc.

What Cruise gives you

- **Modular Architecture**: Plug in only what you need. Swap systems without refactoring.
- **Customizable Workflow**: DataFlow, ECS or SceneTree? Or all of them. You choose what suits you or even build your dream architecture.
- **Hot Reloading**: Edit your code or assets while your game is running.
- **Event Systems**: Full reactive pipeline and event system with EventNotifiers
- **Backend Freedom**: SDL, GLFW, WGPU… pick your renderer and your style.
- **Full Julia Power**: REPL-driven dev, live code injection, and JIT-level speed.

## What does Cruise represent ?

I was kind of surprised when I realized that Cruise has a double impact:

- An ambitious Julia game engine.  
- An ambitious African game engine.  

Not only is it a big plus for the Julia ecosystem, but also a demonstration that Africa can produce massive and complex industry-grade tools.

Making a game is a long and tortuous journey with many ups and downs. Building a game engine is often a necessary step, but it's easy to lose the desire to make the actual game.  

So Cruise is your boat, helping you navigate the vast ocean of ideas and build your own journey.  

I built Cruise because game development has often made me feel intense emotions, and I want newcomers to be just as amazed as I was when I first started making games.

## Architecture 

> With Cruise, there is a difference between a module and a plugin. A plugin is added in the game lifecycle while a module is independent from that.

Cruise itself is built as a minimal core, allowing you to add plugin (which is a graph of execution) into the game lifecycle to add new features.  

But how does the system communicate?
Using the DAG.

Each plugin can access the data of his dependencies, their states and more.
This itself form dataflow based architecture when each plugin passes data to the dependent ones.
For example, when the Physics plugin updates object positions,
the Renderer plugin automatically gets the new data through the DAG.
No boilerplate. No manual sync. Just data flowing between systems.

But that's not everything about it.
You can make plugins for different types of architectures.
For example make an ECSPlugin and other plugins and logics requiring an ECS will work smoothly
Same with SceneTree or any crazy game architecture you have always dreamed of.

The DAG has been choosen for Cruise because it's a more fundamental architecture that allows greater flexibility than locking the user in something like a SceneTree or an ECS in the sense that it allows the other architecture to be added on top of it with a clear separation of concerns simply by making them as plugins.

Cruise already comes with 3 architectures: Dataflow, ECS and SceneTree.
Just waiting for you to add your own idea.

### ECS Architecture 

```julia
using Cruise
using RECSPlugin

# We create a new app
app = CruiseApp()

merge_plugin!(app, RECSPLUGIN)

@component Health begin hp::Int end
@system HPSystem

e1 = create_entity!(Health(10))

## Then we make the game loop, it will update the systems
```

### SceneTree Architecture 

```julia
using Cruise
using SceneTreePlugin

# We create a new app
app = CruiseApp()

merge_plugin!(app, SCENETREEPLUGIN)

mutable struct Player
    hp::Int
end
struct Weapon end

n1 = Node(Player(10))
n2 = Node(Weapon())
addchild(n1, n2)

ready!(n::Node{Player}) = (n[].hp = 10)
process!(n::Node{Player}) = println(n[].hp)

connect(_ON_READY) do n::Node{Player}
    add_child(n1, Node(Weapon))
end

## Then magic will happen in the game loop

```

### DataFlow Architecture 

```julia
using Cruise 

app = CruiseApp()

mutable struct Player
    hp::Int
end

p1 = Player(10)

game = CRPlugin()
add_system!(game, p1)

Cruise.awake!(n::CRPluginNode{Player}) = (n.obj.hp = 10)
Cruise.update!(n::CRPluginNode{Player}) = println(n.obj.hp)

merge_plugin!(app, game)

## Magic happens in the game loop
```

## Plugins

So in order to extend itself, Cruise relies on a **DAG-driven architecture**.  
So in Cruise, system (or plugin) execution is driven by a DAG (Directed Acyclic Graph) that represents dependencies between them and their execution order. Each graph is then assigned to a specific part of the game loop (before update, after update, etc.).

A **plugin** is essentially a subgraph that can be merged into the main graph at a specific point in the game loop to be used.  

This allows us to build a renderer plugin, an ECS plugin, a SceneTree plugin, a physics plugin, or even a bundle of plugins (like a visual editor plugin).

## Provided Tools

### Core

> These modules are included into Cruise when you add it with the package manager
- [GDMathLib.jl](https://github.com/Gesee-y/GDMathLib.jl): The mathematics toolbox. It contains game-dev functions (lerp, slerp, etc.), stack-allocated structures for optimized performance, vector and quaternion manipulation, optimized matrix operations, boxes and circles, an extensible coordinate system, colors, and more.

- [NodeTree.jl](https://github.com/Gesee-y/NodeTree.jl): Tree manipulation to create `SceneTree`s and any parent–child relationship.

- [EventNotifiers.jl](https://github.com/Gesee-y/EventNotifiers.jl): A reactive module. It allows you to create events with a Godot-like syntax (`@Notifyer MY_EVENT(x::Int)`) and manipulate them by modifying their states in an OpenGL-like manner. Features include easy traceability, support for synchronous and asynchronous callbacks, parent–child relationships, state serialization/deserialization, and more.

- [Crates.jl](https://github.com/Gesee-y/Crates.jl): An asset loader and manager. It offers an easy-to-extend interface to load any type of file and manage their lifecycle. Hot reloading is in progress.

- **Cruise.jl**: The package itself offers several tools and utilities, such as a plugin system to add your own plugins and manage their lifecycle in the game loop, a `@gameloop` macro. Provides utilities like do while loops, dynamic structs and more.

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

## Untested features

- **Complete modern OpenGL abstraction + bindless textures** backend from Bplus engine, inspired from Unreal engine rendering engine. Not yet linked to Horizons.jl.  

- **Skia 2D rendering backend** from Skia.jl. Just needs its interface implemented in Horizons.jl.  

- **3D physics**: Still needs to be tested on real-world cases.

## Common Concerns  

- **JIT startup latency**: Julia is already making great progress on this front, and packages like [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl) provide effective solutions.  

- **Performance**: Cruise is optimized for maximum speed (static structures, SIMD, multithreading, cache optimization, etc.) and aims to reach the level of industry-grade solutions (ReactiveECS plugin is a good example).

## Roadmap

From now on, I will focus on testing, documenting and patching. But here is a list of the incoming features:

- [ ] Animation Graph
- [ ] Sprites, AnimatedSprite, Skeletal animations
- [ ] Spatial sound
- [ ] 3D Physics
- [ ] 3D Render

## Contribution

Core Cruise's modules and plugins are self-contained, meaning they use their own interfaces to implement their functionality. This allows any contributor to do the same and stay aligned with the engine's design. Whether you're fixing bugs, writing documentation, or improving performance — you're welcome to contribute.

* Choose the module you want to improve.
* Fork, hack, PR. Simple.

---

## License

Cruise is released under the **MIT License**.
See [LICENSE](https://github.com/Gesee-y/Cruise.jl/blob/main/LICENSE) for details.

---
