module ODPlugin

using Reexport
@reexport using Outdoors
using ..Cruise

export ODPLUGIN

const ODPLUGIN = CRPlugin()
const APP = ODApp()

const APP_ID = add_system!(ODPLUGIN, APP; mainthread=true)

function Outdoors.CreateWindow(style::Type{<:AbstractStyle}, args...)
	#InitOutdoor(style)
	return CreateWindow(APP, style, args...)
end

function Cruise.awake!(n::CRPluginNode{ODApp})
	#InitOutdoor()
end

function Cruise.update!(n::CRPluginNode{ODApp})
	EventLoop(n.obj)
end

function Cruise.shutdown!(n::CRPluginNode{ODApp})
	for (_,win) in n.obj.Windows
		QuitWindow(win)
	end
end

Outdoors.connect(NOTIF_QUIT_EVENT) do
	CruiseApp().ShouldClose = true
end

end # module