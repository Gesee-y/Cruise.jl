# Cruise v0.3.0 documentation: Making a pause plugin

In this tutorial we will make a little more complex plugin with **dependencies**. We will make a **PausePlugin** that will reuse our **TimerPlugin** and use the [ODPlugin](https://github.com/Gesee-y/ODPlugin) for input handling. This plugin will just pause the **TimerManager** when the pause button is pressed

Let's set up the foundations of our plugin:

```julia
module PausePlugin

using Cruise, ODPlugin, TimerPlugin

const PAUSEPLUGIN = CRPlugin()
```

We will create some simple input maps and just make a placeholder struct for the pause plugin:

```julia
@InputMap PAUSE("SPACE", "ESCAPE")

struct PauseManager end

const PM = PauseManager()
id = add_system!(PAUSEPLUGIN, PM)
```

We then need to add the dependencies of our pause Sysytem, else it won't be able to access them or to check their status.
So for that we will merge them in our plugin

```julia
merge_plugin!(PAUSEPLUGIN, ODPLUGIN)
merge_plugin!(PAUSEPLUGIN, TIMERPLUGIN)
add_dependency!(PAUSEPLUGIN, getnodeid(PAUSEPLUGIN, TimerManager), id)
add_dependency!(PAUSEPLUGIN, getnodeid(PAUSEPLUGIN, ODApp), id)
```

In Cruise, a dependecy link ensures that one system is updated after another and can access its instance safely.
Herer, `PauseManager` depends on both `TimerManager` and `ODApp`, so it can pause timers based on player input.
Now the interesting part, the lifecycle. For this plugin `awake!` and `shutdown!` are irrelevant so we will just implement `update!`:

```julia
function Cruise.update!(n::CRPluginNode{PauseManager})
    hasfaileddeps(n) && return
    tm = n.deps[TimerManager]
    od = n.deps[ODApp]

    tm.paused = IsKeyJustPressed(od, PAUSE) ? !tm.paused : tm.paused
end
```

Let's now finalize our plugin:

```julia
export PAUSEPLUGIN

end # module
```

Now in our main script we can do:

```julia
using Cruise, PausePlugin

app = CruiseApp()

merge_plugin!(app, PAUSEPLUGIN)
```

Now we can simply use the plugin in the game loop.
You don't have to worry about duplicates in the plugin graph, Cruise will automatically ignore them and just set the dependencies.