###########################################################################################################################
#################################################### CRUISE APP ###########################################################
###########################################################################################################################

export CruiseApp
export awake!, run!, shutdown!
export on, off
export init_appstyle, context, instance

####################################################### CORE ##############################################################

mutable struct CRWindow{S,T}
	const win::ODWindow{S}
	backend::T

	## Constructor

	CRWindow{S,T}(win::ODWindow{S}) where {S <: AbstractStyle, T <: AbstractRenderer} = new{S,T}(win)
end

mutable struct CruiseApp
	const inst::ODApp
	const ecs::ECSManager
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
	    app[] = CruiseApp(ODApp(), ECSManager(), CrateManager(), Type{<:AbstractStyle}[], Dict{Int,CRWindow}(), false)
	end
	unlock(app_lock)
	return app[]	
end

##################################################### FUNCTIONS ##########################################################

function awake!(a::CruiseApp) 
	a.running = true
end

function run!(a::CruiseApp)
    awake!(a)
    if !isinteractive()
        while on(a)
            yield()
        end
    end
end

function shutdown!(a::CruiseApp)
    if on(a)
        a.running = false
        DestroyAllCrates!(a.manager)
        QuitStyle.(a.inited_style)
        QuitOutdoor(a.inst)
    end
end

on(a::CruiseApp) = a.running
off(a::CruiseApp) = !a.running

function init_appstyle(app, S::Type{<:AbstractStyle})
	InitOutdoor(S)
	push!(app.inited_style, S)
end
init_appstyle(app, c::Container{Type{<:AbstractStyle}}) = init_appstyle.(app,c)


function Outdoors.CreateWindow(app::CruiseApp, ::Type{S}, ::Type{T}, title, w, h, 
	args...; kwargs...) where {S <: AbstractStyle, T <: AbstractRenderer}
	
	S in app.inited_style || init_appstyle(app, S)
    win = CRWindow{S,T}(CreateWindow(app.inst, S, title, w, h, args...; kwargs...))
    win.backend = InitBackend(T, GetStyle(win.win).window)
    
    app.windows[GetWindowID(win.win)] = win
    CreateViewport(win.backend,w,h)

    return win
end

context(w::CRWindow) = w.backend
instance(w::CRWindow) = w.win
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
