#######################################################################################################################
################################################ OUTDOORS PLUGIN ######################################################
#######################################################################################################################

module ODPlugin

export ODPLUGIN

include(joinpath("..", "Outdoors.jl", "src", "Outdoors.jl"))

using Reexport
using ..Cruise
@reexport using .Outdoors

struct ODException <: Exception
	msg::String
end

const ODPLUGIN = CRPlugin()
const APP = ODApp()
PHASE = :preupdate

const ID = add_system!(ODPLUGIN, APP)

Outdoors.connect(NOTIF_ERROR) do msg,err
	node = ODPLUGIN.idtonode[ID]
	setstatus(node, PLUGIN_ERR)
	setlasterr(node, ODException(msg*err))
end

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{ODApp})
	InitOutdoor()
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{ODApp}, dt)
	EventLoop(n.obj)
end

function Cruise.shutdown!(n::CRPluginNode{ODApp})
	QuitOutdoor()
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

function Outdoors.CreateWindow(style::Type{<:AbstractStyle}, args...)
	InitStyle(style)
	return CreateWindow(APP, style, args...)
end

end #module