###########################################################################################################################
#################################################### CRUISE APP ###########################################################
###########################################################################################################################

export CruiseApp
export awake!, run!, shutdown!
export on, off
export init_appstyle, context, instance

####################################################### CORE ##############################################################

"""
    mutable struct CRWindow{S}
		const win::ODWindow{S}

Represent a windows for Cruise. S is the style of the window following the Outdoors packages conventions.
"""
mutable struct CRWindow{S}
	const win::ODWindow{S}

	## Constructor

	CRWindow{S}(win::ODWindow{S}) where {S <: AbstractStyle, T <: AbstractRenderer} = new{S,T}(win)
end

"""
    mutable struct CruiseApp
		const inst::ODApp
		const plugins::Dict{Symbol, SysGraph}
		const manager::CrateManager
		inited_style::Vector{Type{<:AbstractStyle}}
		windows::Dict{Int,CRWindow}
		running::Bool

Represent the boss app manager of the whole program.
- inst: The windows manager from Outdoors.jl
- plugins: A Dict that map a loop phase to a system graph.
- manager: Manage the assets. Comes from AssetCrates.jl
- inited_style: The alread initialized window style. They are kept so that we can properly clean everything at the end.
- windows: Maps the windows id to the instance in cruise
- running: Whether the app has already started.

## Constructor

    CruiseApp()

Will create a new global instance of a CruiseApp. Note that a program can only have one Cruise app.
The next call to CruiseApp will return the same object.
"""
mutable struct CruiseApp
	const inst::ODApp
	const plugins::Dict{Symbol, SysGraph}
	const manager::CrateManager
	inited_style::Vector{Type{<:AbstractStyle}}
	windows::Dict{Int,CRWindow}
	running::Bool
end

const app = Ref{CruiseApp}()
const app_lock = ReentrantLock()

## Constructor
function CruiseApp()
	global app
	global app_lock
	lock(app_lock)
	if !isassigned(app)
	    app[] = CruiseApp(ODApp(), Dict{Symbol, SysGraph}(:preupdate => SysGraph(), :postupdate => SysGraph), 
	    	CrateManager(), Type{<:AbstractStyle}[], Dict{Int,CRWindow}(), false)
	end
	unlock(app_lock)
	return app[]	
end

##################################################### FUNCTIONS ##########################################################

"""
    awake!(a::CruiseApp)

Initiliaze the CruiseApp and all his plugins.

    awake!(sg::SysGraph)

Initialize all the systems in the given SysGraph.
"""
function awake!(a::CruiseApp) 
	a.running = true
	for sg in values(a.plugins)
		awake!(sg)
	end
end
awake!(sg::SysGraph) = smap!(awake!, sg)

"""
    shutdown!(a::CruiseApp)

This function will stop Cruise, his plugins and clean up the resources.

	shutdown!(sg::SysGraph)

This will stop the given system graph b topologically calling shutdown! on the systems.
"""
function shutdown!(a::CruiseApp)
    if on(a)
        a.running = false
        for sg in values(a.plugins)
		    shutdown!(sg)
	    end
        DestroyAllCrates!(a.manager)
        QuitStyle.(a.inited_style)
        QuitOutdoor(a.inst)
    end
end
shutdown!(sg::SysGraph) = smap!(shutdown!, sg)

"""
    on(a::CruiseApp)

Rtuens true if the CruiseApp is running.
"""
on(a::CruiseApp) = a.running

"""
    off(a::CruiseApp)

Rtuens true if the CruiseApp isn't running.
"""
off(a::CruiseApp) = !a.running

function init_appstyle(app, S::Type{<:AbstractStyle})
	InitOutdoor(S)
	push!(app.inited_style, S)
end
init_appstyle(app, c::Container{Type{<:AbstractStyle}}) = init_appstyle.(app,c)


function Outdoors.CreateWindow(app::CruiseApp, ::Type{S}, title, w, h, 
	args...; kwargs...) where {S <: AbstractStyle}
	
	S in app.inited_style || init_appstyle(app, S)
    win = CRWindow{S,T}(CreateWindow(app.inst, S, title, w, h, args...; kwargs...))
    app.windows[GetWindowID(win.win)] = win

    return win
end

instance(w::CRWindow) = w.win
preupdate_plugins(a::CruiseApp) = a.plugins[:preupdate]
postupdate_plugins(a::CruiseApp) = a.plugins[:postupdate]
################################################### Event Handling ########################################################

export on_backend_error, on_backend_info, on_backend_warning, on_backend_debug
export on_window_error, on_window_warning, on_window_debug, on_window_info
export on_style_inited, on_style_quitted
export on_app_quit

on_backend_error(msg, err) = error(msg*err)
on_backend_warning(msg, err) = @warn msg*err
on_backend_info(msg, err) = @info msg*err
on_backend_debug(msg, err) = @debug msg*err

on_window_error(msg, err) = error(msg*err)
on_window_warning(msg, err) = @warn msg*err
on_window_info(msg, err) = @info msg*err
on_window_debug(msg, err) = @debug msg*err

on_style_inited(style) = nothing
on_style_quitted(style) = nothing
on_app_quit() = shutdown!(app[])

Horizons.connect(on_backend_error,HORIZON_ERROR)
Horizons.connect(on_backend_warning,HORIZON_WARNING)
Horizons.connect(on_backend_info,HORIZON_INFO)

Outdoors.connect(on_style_inited, NOTIF_OUTDOOR_INITED)
Outdoors.connect(on_style_quitted, NOTIF_OUTDOOR_STYLE_QUITTED)
Outdoors.connect(on_app_quit,NOTIF_QUIT_EVENT)
Outdoors.connect(on_window_error,NOTIF_ERROR)
Outdoors.connect(on_window_warning,NOTIF_WARNING)
Outdoors.connect(on_window_info,NOTIF_INFO)
