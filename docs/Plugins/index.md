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