#######################################################################################################################
###################################################### RECS PLUGIN ####################################################
#######################################################################################################################

module RECSPlugin

export RECSPLUGIN

include(joinpath("ReactiveECS.jl", "src", "ReactiveECS.jl"))

using Reexport
using ..Cruise
@reexport using .ReactiveECS

struct RECSException <: Exception
	msg::String
end

const RECSPLUGIN = CRPlugin()
const WORLD = ECSManager()
PHASE = :postupdate

const ID = add_system!(RECSPLUGIN, WORLD)

#ReactiveECS.connect(ON_ERROR) do msg,err
#	node = RECSPLUGIN.idtonode[ID]
#	setstatus(node, PLUGIN_ERR)
#	setlasterr(node, RECSException(msg*err))
#end

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{ECSManager})
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{ECSManager}, dt)
	dispatch_data(WORLD)
	blocker(WORLD)
end

function Cruise.shutdown!(n::CRPluginNode{ECSManager})
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

ReactiveECS.register_component!(T::Type) = register_component!(WORLD, T)
ReactiveECS.create_entity!(d::Tuple; parent=-1) = create_entity!(WORLD, d; parent=-1)
ReactiveECS.remove_entity!(entity::Entity) = remove_entity!(WORLD, entity)
ReactiveECS.attach_component(entity, data) = attach_component(WORLD, entity, data)
ReactiveECS.detach_component(e, T) = detach_component(WORLD, e, T)

end #module