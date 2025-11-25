# Cruise v0.3.0: Game Architecture

A game architecture is the foundations of your game. It determines how logics are handled, how code will be written and how systems will communicate.

Cruise itself is built as a minimal core, allowing you to add plugin (which is a graph of execution) into the game lifecycle to add new features.  

But how does the system communicate?
Using the DAG.

Each plugin can access the data of his dependencies, their states and more.
This itself form dataflow based architecture when each plugin passes data to the dependent ones.
For example, when the Physics plugin updates object positions,
the Renderer plugin automatically gets the new data through the DAG.

But that's not everything about it.
You can make plugins for different types of architectures.
For example make an ECSPlugin and other plugins and logics requiring an ECS will work smoothly
Same with SceneTree or any crazy game architecture you have always dreamed of.

The DAG has been choosen for Cruise because it's a more fundamental architecture that allows greater flexibility than locking the user in something like a SceneTree or an ECS in the sense that it allows the other architecture to be added on top of it with a clear separation of concerns simply by making them as plugins.

There are already comes with 2 architectures plugins: ECS (RECSPlugin) and SceneTree ( 
SceneTreePlugin).
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

## Then magic will happen in the game 
```