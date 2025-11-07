# Cruise 0.3.0 Documentation: Plugins & Capabilities

This documentation provides the information and steps necessary for anyone to create a plugin in Cruise.

Cruise extends itself via a **plugin system** built on top of a dependency graph. A plugin is essentially a **subgraph of that dependency graph**. To control interactions between plugins, Cruise uses a **capabilities system**: each plugin can expose a limited interface (a capability) to dependent plugins.


---

## Making a Plugin

To create a plugin, first set up Cruise:

```julia
using Cruise

app = CruiseApp()
```

Then define your system structures. Any type can be a node for a plugin; there is no special supertype required.

```julia
struct Sys1
    x::Int
end

struct Sys2
    y::Int
end

s1, s2 = Sys1(1), Sys2(0)
```

Create a new empty plugin:

```julia
plugin = CRPlugin()
```

---

## Capabilities

A **capability** is an interface a node expose for his dependencies to use, this is used to restrict what a node allows its dependencies to modify. This make the program safer.

### Adding capabilities

Each plugin node must expose a **capability**, which restricts what dependent nodes can access.

```julia
# Define concrete capabilities
struct Sys1Cap <: AbstractCapability
    max_value::Int
end

struct Sys2Cap <: AbstractCapability
    allowed_increment::Int
end

# Create nodes with capabilities
id1 = add_system!(plugin, s1, Sys1Cap(100))
id2 = add_system!(plugin, s2, Sys2Cap(10))
```

> The capability is the **only interface** other plugins will receive when they depend on this node.

You should also set some utilities functions so that any we can still get informations about the node from the capability.
For example:

```julia
Cruise.getstatus(c::Sys1Cap) = iszero(c.max_value) ? PLUGIN_ERR : PLUGIN_OK 
```

---

## Adding Dependencies with Capabilities

Dependencies only expose the capability of the parent to the child:

```julia
add_dependency!(plugin, id1, id2)
```

If adding a dependency will introduce a cor ulsr dependency, then this function will do nothing and return `false`, otherwise it returns `true`

Now Sys2 can access Sys1 only via its capability and cannot modify the internal state of Sys1 directly.

---

## Defining the Plugin Lifecycle

Define the lifecycle methods (awake!, update!, shutdown!) for your plugin nodes:

```julia
Cruise.awake!(node::CRPluginNode{Sys1}) = setstatus(node, PLUGIN_OK)
Cruise.awake!(node::CRPluginNode{Sys2}) = setstatus(node, PLUGIN_OK)

Cruise.update!(node::CRPluginNode{Sys1}) = println(node.obj.x)

Cruise.update!(node::CRPluginNode{Sys2}) = begin
    cap = getdep(node, Sys1)  # access only Sys1's capability
    println(node.obj.y + cap.max_value)
end

Cruise.shutdown!(node::CRPluginNode{Sys1}) = setstatus(node, PLUGIN_OFF)
Cruise.shutdown!(node::CRPluginNode{Sys2}) = setstatus(node, PLUGIN_OFF)
```

---

## Merging and Running

Merge the plugin into Cruise at the correct phase:

```julia
merge_plugin!(app, plugin, :preupdate)
```

> Even after merging, you can still manage the plugin from the CRPlugin instance you created.


Run Cruise’s gameloop:

```julia
@gameloop app begin
    println(LOOP_VAR.delta_seconds)
end
```

Errors during update! are caught automatically and set the node status to PLUGIN_ERR.


---

## Workflow

It is recommended to package your plugin as a Julia package. This allows users to install it easily and manage binary size. Dependencies on other plugins can be declared in Project.toml.


---

## Advanced Features

### Querying a Node

Use `getnodeid(plugin, symbol)` to get the ID of a given node type.

You can also use:

- `remove_system!(sg::CRPlugin, id::Int; sort=true)` : Remove a system by ID.

- `remove_dependency!(sg::CRPlugin, from::Int, to::Int; sort=true)` : Remove a dependency.


---

## Dependencies & Capabilities

Each plugin node stores a WeakRef to its dependencies. These references contain only the capability exposed by the dependency, not the full node object.

```julia
node.deps[TYPE]  # Returns a WeakRef to the capability of the dependency of type TYPE
```

**`WeakRef`s** are used here so that when a given plugin node is removed or deleted, his dependencies should not prevent the GC to take it nor should continue using a dead node.


Use these utility functions:

- `isinitialized(s::CRPluginNode)`

- `isuninitialized(s::CRPluginNode)`

- `isdeprecated(s::CRPluginNode)`

- `hasfailed(s::CRPluginNode)`

- `getstatus(s::CRPluginNode)`

- `setstatus(s::CRPluginNode, st::CRPluginStatus)`

- `getlasterror(s::CRPluginNode)`

- `setlasterr(s::CRPluginNode, e::Exception)`

- `getresult(s::CRPluginNode)`

- `setresult(s::CRPluginNode, r)`

- `hasfaileddeps(s::CRPluginNode)`

- `hasuninitializeddeps(s::CRPluginNode)`

- `hasalldepsinitialized(s::CRPluginNode)`

- `hasdeaddeps(s::CRPluginNode)`


> Important: You should **never** modify a node manually; doing so would break the separation of concerns and violate graph integrity.


---

### Plugin Status

Plugin status indicates the current state of a plugin node:

```julia
@enum CRPluginStatus begin
    PLUGIN_OFF         # Plugin not initialized
    PLUGIN_DEPRECATED  # Plugin results are deprecated
    PLUGIN_OK          # Plugin is initialized and running
    PLUGIN_ERR         # Plugin encountered an error
end
```

Status change events can be tracked using `add_status_callback(f, node)`.


---

### Applying a Function on a Plugin

Cruise provides two methods to apply a function to all nodes:

- `smap!(f, plugin)` : Apply f sequentially in topological order.

- `pmap!(f, plugin)` : Apply f topologically and concurrently for nodes on the same level, ensuring thread safety.
