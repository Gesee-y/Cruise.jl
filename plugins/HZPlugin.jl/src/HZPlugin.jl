#######################################################################################################################
################################################ HORIZONS PLUGIN ######################################################
#######################################################################################################################

module HZPlugin

export HZPLUGIN, RegisterBackend, GetBackend, CreateBackend

using SimpleDirectMediaLayer.LibSDL2
using ModernGL
using ..NodeTree
using ..EventNotifiers
using ..GDMathLib
using ..AssetCrates

include(joinpath("Horizons.jl", "src", "Horizons.jl"))

using Reexport
using ..Cruise
@reexport using .Horizons

struct HZRegistration
	win::Any
	args::Tuple
end

mutable struct HorizonManager
	data::Dict{Type, HZRegistration}
	backends::Dict{HRenderer, WeakRef}

	## Constructor

	HorizonManager() = new(Dict{Type, HZRegistration}(), Dict{HRenderer, WeakRef}())
end

struct HZException <: Exception
	msg::String
end

const HZPLUGIN = CRPlugin()
const MANAGER = HorizonManager()
PHASE = :preupdate

const ID = add_system!(HZPLUGIN, MANAGER; mainthread=true)

Horizons.connect(HORIZON_ERROR) do msg,err
	node = HZPLUGIN.idtonode[ID]
	setstatus(node, PLUGIN_ERR)
	setlasterr(node, HZException(msg*err))
end

################################################# PLUGIN LIFECYCLE ####################################################

function GetBackend(win)
	for (k,v) in MANAGER.backends
		v.value == win && return k
	end
end

function CreateBackend(R::Type{<:HRenderer}, win, sizex, sizey, x=0, y=0)
	backend = InitBackend(R, win)
	CreateViewport(backend, sizex, sizey, x, y)
	MANAGER.backends[backend] = WeakRef(win)

	return backend
end

function Cruise.awake!(n::CRPluginNode{HorizonManager})
	for (R, data) in MANAGER.data
		win = data.win
		backend = InitBackend(R, win)
		CreateViewport(backend, data.args...)
		MANAGER.backends[backend] = WeakRef(win)
	end

	empty!(MANAGER.data)
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{HorizonManager})
	manager = n.obj
	backends = keys(manager.backends)

	for (backend, winref) in manager.backends
		if isnothing(winref.value)
			# Given that there are a small number of renderers in a game,
			# No need to move memory to delete the deprecated backend, we can just skip them
			#continue
		end
        SetDrawColor(backend,WHITE)
        ClearViewport(backend)
        UpdateRender(backend)
    end
end

function Cruise.shutdown!(n::CRPluginNode{HorizonManager})
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

function RegisterBackend(R::Type, win, args...)
	MANAGER.data[R] = HZRegistration(win,args)
end

end # module