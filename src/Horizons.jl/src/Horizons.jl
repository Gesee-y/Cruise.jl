############################################################################################################################
######################################################### HORIZONS #########################################################
############################################################################################################################
## Rendering Engine for the Cruise Engine ##
# But it can be use alone for other things #
##                                        ##

module Horizons

using ..LibSDL2
using ..ModernGL
using ..Crates

export AbstractRenderer
export HORIZON_BACKEND_INITED, HORIZON_BACKEND_DESTROYED
export HORIZON_ERROR, HORIZON_WARNING, HORIZON_INFO
export InitBackend, UpdateRender, DestroyBackend

using ..MathLib
using ..Notifyers
using ..NodeTree

const HDict{N,M} = NodeTree.SimpleDict{N,M}

abstract type AbstractRenderer end
abstract type AbstractResource end

#=
	Now, how will the transition between the backend will be done ?
	I think the best way will be to cast function.
	The thing about casting function is that, is the function does not exist, we just ignore it
	Okay, it's not the best solution, But we need a way to use a different API, without breaking the main app
	But the thing is, API are just Tools, nothing more, they are use depending of the situation
	We don't really need transition between them, we just need Really good abstraction of them
	It's like an horizon, each element of the sky have is importance and each horizons have is 
	own charm, each inspire everyone differently.

	So let's start, With SDLH (Simple Directmedia Layer Horizon).
=#

@Notifyer HORIZON_BACKEND_INITED(win)
@Notifyer HORIZON_BACKEND_DESTROYED(win)

#=
	@Notifyer HORIZON_ERROR(mes::String,error::String)

A notification emitted when Horizon find a severe error that make the program unable to 
continue. It's recommended to connect to it a function to throw the received error or at least
to handle it.
=#
@Notifyer HORIZON_ERROR(mes::String,error::String)

#=
	@Notifyer HORIZON_WARNING(mes::String,warning::String)

A notification emitted when Horizon find a problem but that problem does not make the program 
unable to process.
=#
@Notifyer HORIZON_WARNING(mes::String,warning::String)

#=
	@Notifyer HORIZON_INFO(mes::String,info::String)

A notification emitted when an information should be passed (For example the information about
a driver, etc.).
=#
@Notifyer HORIZON_INFO(mes::String,info::String)

"""
	InitBackend(::Type{AbstractRenderer},win,args...)

This function serve to initialize a backend.
If you are going to create a new backend, you should create a dispatch of this one to initialize
your backend. When everything went well, it emit the notification `NOTIF_BACKEND_INITED` with the
new backend.
"""
InitBackend(::Type{AbstractRenderer},win,args...) = (HORIZON_BACKEND_INITED.emit = win)

include("CommandBuffer.jl")
include("Textures.jl")
include("Objects.jl")
include("viewport.jl")
include("Renderer.jl")
include("Commands.jl")
include("Vertex.jl")

"""
	UpdateRender(backend::AbstractBackend)

Update the screen for a given backend.
If you are going to create a new backend, you should create a dispatch of this one to initialize
your backend.
"""
function UpdateRender(backend::HRenderer)
	ExecuteCommands(backend)
	RenderObject(backend,backend.viewport.screen;viewport=false)
	PresentRender(backend)
	clear!(get_commandbuffer(backend))
end

"""
    PresentRender(::HRenderer)

This present the current render to the screen.
Each backend should overload this method to update their screen.
"""
PresentRender(::HRenderer) = nothing

"""
	DestroyBackend(backend)

This function serve to destroy a backend.
If you are going to create a new backend, you should create a dispatch of this one to initialize
your backend. When everything went well, it emit the notification `NOTIF_BACKEND_INITED` with the
new backend.
"""
DestroyBackend(backend) = (HORIZON_BACKEND_DESTROYED.emit = backend)

include(joinpath("SDLHorizon","SDLH.jl"))
end #module