module HZPlugin

using Reexport
@reexport using CRHorizons
using Cruise

export HZPLUGIN

mutable struct HorizonManager
	backends::Dict{HRenderer, WeakRef}
	other::Dict{HRenderer, Any}

	## Constructor

	HorizonManager() = new(Dict{HRenderer, WeakRef}(), Dict{HRenderer, Any}())
end

const HZPLUGIN = CRPlugin()
const MANAGER = HorizonManager()

const HZ_ID = add_system!(HZPLUGIN, MANAGER; mainthread=true)

function CRHorizons.InitBackend(R::Type{<:HRenderer}, win, sizex, sizey, x=0, y=0; bgcol = BLACK)
	backend = InitBackend(R, win)
	CreateViewport(backend, sizex, sizey, x, y)
	MANAGER.backends[backend] = WeakRef(win)
	MANAGER.other[backend] = bgcol

	return backend
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
		col = manager.other[backend]
        SetDrawColor(backend,col)
        ClearViewport(backend)
        UpdateRender(backend)
    end
end

end # module