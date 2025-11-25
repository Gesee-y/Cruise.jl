# Cruise v0.3.0 documentation: Game logics

A game logic is a chunk of code that execute a specific task in your code.
In regular game engines they are often called **scripts**. These scripts are then tied to an object. when the object is active, his script execute, when it's not, the script isn't executed.

With Cruise, it's a little bit different. Scripts are called **game logics** and are independent of objects. They can be activated/desactivated at will. Their purpose is to accomplish a specific task in your game.

One can create a new game logic like this

```julia
app = CruiseApp() # Make sure to have called this at least once

logic_id = @gamelogic logic_name begin
    # My code
end
```

So here we made a new game logic that we named `logic_name`. The `@gamelogic` macro will return the id of our new logic.
Why an id ?
Because a game logic is in fact a system in the main plugin graph. This means that all your logic benefits from all the features a regular plugin node have (capabilities, dependencies, enabling/disabling, etc). Your logic is automatically added to the main plugin, but you can optionnaly pas the keyword argument `plugin=myplugin` so the logic is added to your custom plugin instead.

Each game logic is an intace of the object `GameCode{Name}` where `Name` is the name of your logic as a `Symbol`.
So when getting it from adependency for example, you will just do

```julia
pluginnode.deps[GameCode{:name}]
```

In your logics, the internal representation of your logic (the node of the graph) is called `self`. for example

```julia
@gamelogic logic begin
    println(self) # self are is a variable specific to the logic that is the node containing the logic
    # You can use it as with any other node
end
```
