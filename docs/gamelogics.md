# Cruise v0.3.0 documentation: Game Logics

A **game logic** is a self-contained block of code that performs a specific task in your game.
In most engines these are called *scripts*, and they’re attached to game objects: if the object is active, its script runs; if not, it doesn’t.

Cruise doesn’t follow that model.
Here, a game logic is **not tied to any object**.
It can be enabled or disabled at any time, connected to other logics, and integrated directly into the main execution graph.
Its only responsibility is to perform a clearly defined operation inside your game.

---

## Declaring a Game Logic

```julia
app = CruiseApp()  # Must be called at least once

logic_id = @gamelogic logic_name begin
    # Logic code
end
```

`@gamelogic` creates the logic, registers it inside the plugin graph, and returns its **ID**.
Why an ID?
Because a game logic is essentially a **system node in the main plugin graph**, with all the same features as any plugin node:

* capabilities
* dependencies
* enable/disable
* ordered execution

By default, the logic is added to the main plugin, but you can place it elsewhere:

```julia
@gamelogic logic_name plugin=myplugin begin
    ...
end
```

---

## Identity and Access

Each logic is an instance of:

```
GameCode{Name}
```

where `Name` is your logic’s name as a `Symbol`.

Example: accessing it from a dependency list:

```julia
pluginnode.deps[GameCode{:logic_name}]
```

---

## The `self` Variable

Inside every game logic, Cruise injects a variable called `self`.
This is the actual node in the plugin graph that represents your system.

```julia
@gamelogic logic begin
    println(self)  # The node itself
    # You can use it exactly like any other graph node
end
```

`self` gives you:

* access to your capability
* access to your dependencies
* node state information
* full interaction with the graph

---

## Keyword Arguments

Game logics accept several optional keywords:

### `mainthread=false`

Forces the system to always run on the main thread.

### `plugin=<plugin>`

Places the logic inside a specific plugin instead of the main one.

### `capability=<obj>`

Associates a capability to the logic.
Other systems depending on this logic can query that capability.

Example:

```julia
@gamelogic movement capability=MovementCap() begin
    # ...
end
```

