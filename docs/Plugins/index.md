# Cruise 0.3.0 documentation: Plugins

This documentation provides the informations and steos necessary for anyone to make a plugin.

In order to extend itself, Cruise rely on a **plugin system** built on top of a dependency graph.
A **plugin** is basically a subgraph of that dependency graph.

## Maing a plugin

To mae a plugin, it's relatively simple, first of all let's setup Cruise.

```julia
using Cruise

app = CruiseApp()
```

Then we need to define our structures.

```julia
struct Sys1
	x::Int
end

struct Sys2
	y::Int
end

s1, s2 = Sys1(1), Sys2(0)
```

Now we have an instance of our 2 systems, we need not to create a new empty plugin.

```julia
plugin = CRPlugin()
```

Then to that plugin we will just add our structs to it.

```julia
id1 = add_system!(plugin, s1)
id2 = add_system!(plugin, s2)
``` 

`add_system!` return the id of the new system in the plugin.

Now we can try adding a dependency between these 2 systems

```julia
add_dependency!(plugin, id1, id2)
```

Now all you have to do is defining your plugin lifecycle

```julia
Cruise.awake!(node::CRPluginNode{Sys1}) = setstatus(node, PLUGIN_OK)
Cruise.awake!(node::CRPluginNode{Sys2}) = setstatus(node, PLUGIN_OK)
Cruise.update!(node::CRPluginNode{Sys1}) = println(node.obj.x)
Cruise.update!(node::CRPluginNode{Sys2}) = println(node.obj.y + node.deps[Sys1].value.obj.x)
Cruise.shutdown!(node::CRPluginNode{Sys1}) = setstatus(node, PLUGIN_OFF)
Cruise.shutdown!(node::CRPluginNode{Sys2}) = setstatus(node, PLUGIN_OFF)
```

Finally you need to merge your plugin into Cruise at the correct phase.

```julia
merge_plugin!(app, plugin, :preupdate)
```

You are done, just run Cruise's gameloop.

```julia
@gameloop app begin
    println(LOOP_VAR.delta_seconds)
end
```

You should be seeing our plugin merrily doing it's job and printing numbers

## Advanced Features

### Querying a node

You can use `getnodeid(plugin, symbol)` to get the id of a given node type. `symbol` is the node tpe as a Symbol.

### Dependencies

Each plugin node store a `WeakRef` to its dependencies. WeakRef are used because a plugin isn't supposed to keep his dependencies alive, if they are deleted, the plugin should see that his deps is no more there. You can access them like this:

```julia
node.deps[TYPE] # Will return a weakref to the dependency of type `TYPE`
```

From there you can access the status of the dependency (`getstatus(node.deps[TYPE].value)`), the last result it returned (`getresult(node.deps[TYPE].value)`), it's instance (`node.deps[TYPE].value.obj`), etc.

* `isinitialized(s::CRPluginNode)`
* `isuninitialized(s::CRPluginNode)`
* `isdeprecated(s::CRPluginNode)`
* `hasfailed(s::CRPluginNode)`
* `getstatus(s::CRPluginNode)`
* `setstatus(s::CRPluginNode, st::CRPluginStatus)`
* `getresult(s::CRPluginNode)`
* `setresult(s::CRPluginNode, r)`
* `hasfaileddeps(s::CRPluginNode)`
* `hasuninitializeddeps(s::CRPluginNode)`
* `hasalldepsinitialized(s::CRPluginNode)`

### Plugins Status

Plugins status gives informations about the current state of a plugin. It's in fact an enumeration:

```julia
@enum CRPluginStatus begin
    PLUGIN_OFF # The plugin is not initialized
    PLUGIN_DEPRECATED # The plugin result are deprecated
    PLUGIN_OK # The plugin is inited
    PLUGIN_ERR # The plugin encountered an error
end
```

Each time a plugin node change status, an event is sent. you can use `add_status_callback(f, node)` to call the function `f` each time the node changes its status.