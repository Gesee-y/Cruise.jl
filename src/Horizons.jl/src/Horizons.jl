############################################################################################################################
######################################################### HORIZONS #########################################################
############################################################################################################################
## Rendering Engine for the Cruise Engine ##
# But it can be use alone for other things #
##                                        ##

module Horizons

export AbstractRenderer

export HORIZON_BACKEND_INITED, HORIZON_BACKEND_DESTROYED

export HORIZON_ERROR, HORIZON_WARNING, HORIZON_INFO

export InitBackend, UpdateRender, DestroyBackend

include(joinpath("..","..","NodeTree.jl", "src", "NodeTree.jl"))
include(joinpath("..","..","Notifyers.jl", "src", "Notifyers.jl"))
include(joinpath("..","..","MathLib.jl","src","MathLib.jl"))
include("SimpleMaths.jl")

using .Notifyers
using .NodeTree

const HDict{N,M} = NodeTree.SimpleDict{N,M}

abstract type AbstractRenderer end

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

"""
	UpdateRender(backend::AbstractBackend)

Update the screen for a given backend.
If you are going to create a new backend, you should create a dispatch of this one to initialize
your backend.
"""
function UpdateRender(backend::AbstractRenderer) end

"""
	DestroyBackend(backend)

This function serve to destroy a backend.
If you are going to create a new backend, you should create a dispatch of this one to initialize
your backend. When everything went well, it emit the notification `NOTIF_BACKEND_INITED` with the
new backend.
"""
DestroyBackend(backend) = (HORIZON_BACKEND_DESTROYED.emit = backend)

include("Textures.jl")
include("SDLHorizon\\SDLH.jl")
include("Vertex.jl")
include("GLHorizon\\GLH.jl")

end #module