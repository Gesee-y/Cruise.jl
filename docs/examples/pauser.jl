module PausePlugin

using Cruise
using Cruise.ODPlugin, ..TimerPlugin

const PAUSEPLUGIN = CRPlugin()

@InputMap PAUSE("SPACE", "ESCAPE")

struct PauseManager end

const PM = PauseManager()
id = add_system!(PAUSEPLUGIN, PM)

merge_plugin!(PAUSEPLUGIN, ODPLUGIN)
merge_plugin!(PAUSEPLUGIN, TIMERPLUGIN)

add_dependency!(PAUSEPLUGIN, getnodeid(PAUSEPLUGIN, TimerManager), id)
add_dependency!(PAUSEPLUGIN, getnodeid(PAUSEPLUGIN, ODApp), id)

function Cruise.update!(n::CRPluginNode{PauseManager})
    tm = n.deps[TimerManager]
    od = n.deps[ODApp]

    tm.paused = IsKeyJustPressed(od, PausePlugin.PAUSE) ? !tm.paused : tm.paused
end

export PAUSEPLUGIN

end # module