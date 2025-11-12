#######################################################################################################################
###################################################### SCENETREE PLUGIN ###############################################
#######################################################################################################################
include(joinpath("NodeTree.jl", "src", "NodeTree.jl"))
@reexport using .NodeTree

module SceneTreePlugin

export SCENETREEPLUGIN


using Reexport
using ..Cruise
using ..NodeTree

@Notifyer _ON_CHILD_ADDED(n1, n2)
@Notifyer _ON_CHILD_REMOVED(n1, n2)
@Notifyer _EXIT_TREE(n)
@Notifyer _ON_READY(n)
@Notifyer _ENTER_TREE(n)

const SCENETREEPLUGIN = CRPlugin()
const TREE = ObjectTree()
PHASE = :postupdate

const ID = add_system!(SCENETREEPLUGIN, TREE)

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{ObjectTree})
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{ObjectTree})
	nodes = BFS_search(n.obj)
	for node in nodes
		process!(node, dt)
	end
end

function Cruise.shutdown!(n::CRPluginNode{ObjectTree})
	for node in TREE.objects
		destroy!(node)
	end
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

ready!(n::AbstractNode) = nothing
process!(n::AbstractNode) = nothing
destroy!(n::AbstractNode) = nothing
destroy!(::Nothing) = nothing

NodeTree.get_tree() = TREE

function addchild(n1,n2)
	add_child(n1, n2)
	_ENTER_TREE.emit = n2
	ready!(n2)
	_ON_READY.emit = n2
	_ON_CHILD_ADDED.emit = n1,n2
end

function deletenode(n)
	remove_node(TREE, n)
	_EXIT_TREE.emit = n
	destroy!(n)
end

function deletechild(n, n2)
	remove_child(n, n2)
	_ON_CHILD_REMOVED.emit = n, n2
	_EXIT_TREE.emit = n2
	destroy!(n)
end
deletechild(n, i::Int) = deletechild(n, get_children(n)[i])

end # module