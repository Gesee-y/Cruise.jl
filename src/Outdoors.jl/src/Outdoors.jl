## A module to manage many kind of windows ##

module Outdoors

include(joinpath("..","..","NodeTree.jl", "src", "NodeTree.jl"))
include(joinpath("..","..","Notifyers.jl", "src", "Notifyers.jl"))

using .Notifyers
using .NodeTree

export NOTIF_WINDOW_CREATED, NOTIF_WINDOW_UPDATED, NOTIF_WINDOW_EXITTED, NOTIF_WINDOW_TITLE_CHANGED
export NOTIF_WINDOW_REPOSITIONED, NOTIF_WINDOW_RESIZED, NOTIF_WINDOW_FULLSCREEN, NOTIF_WINDOW_MINIMIZED
export NOTIF_WINDOW_MAXIMIZED, NOTIF_WINDOW_HIDDEN
export NOTIF_ERROR, NOTIF_WARNING, NOTIF_INFO, NOTIF_OUTDOOR_INITED
export NOTIF_OUTDOOR_QUITTED, NOTIF_WINDOW_RESTORED, NOTIF_WINDOW_RAISED

export ContextType

export AbstractStyle, ODWindow, ODApp

export CreateWindow, ResizeWindow, RepositionWindow, QuitWindow, SetWindowTitle, SetFullscreen
export GetError, UpdateWindow, WindowDelay, InitOutdoor, WindowCount
export QuitStyle, QuitOutdoor, GetStyle

# --------- Notifications ----------- #

#=
	@Notifyer NOTIF_OUTDOOR_QUITTED()

A notification emitted when Outdoors have been quitted for a given window style.
=#
@Notifyer NOTIF_OUTDOOR_QUITTED()

#=
	@Notifyer NOTIF_OUTDOOR_INITED()

A notification emitted when have been initialized for a given window style.
=#
@Notifyer NOTIF_OUTDOOR_INITED()

#=
	@Notifyer NOTIF_OUTDOOR_STYLE_QUITTED(style)

A notification emitted when an outdoor style of window have been quitted
=#
@Notifyer NOTIF_OUTDOOR_STYLE_QUITTED(style)

#=
	@Notifyer NOTIF_CONTEXT_CREATED(win)

A notification emitted when a context have been successfuly intialized in a window `win`.
It return the window in question.
=#
@Notifyer NOTIF_CONTEXT_CREATED(win)

#=
	@Notifyer NOTIF_WINDOW_CREATED(win)

A notification emitted when a window is created, it return the window created.
=#
@Notifyer NOTIF_WINDOW_CREATED(win)

#=
	@Notifyer NOTIF_WINDOW_UPDATED(win)

A notification emitted when a window is updated, it return the window updated.
=#
@Notifyer NOTIF_WINDOW_UPDATED(win)

#=
	@Notifyer NOTIF_WINDOW_EXITTED(win)

A notification emitted when a window is exitted, it return the window closed.
=#
@Notifyer NOTIF_WINDOW_EXITTED(win)

#=
	@Notifyer NOTIF_WINDOW_MINIMIZED(win)

A notification emitted when a window is minimized, it return the window minimized.
=#
@Notifyer NOTIF_WINDOW_MINIMIZED(win)

#=
	@Notifyer NOTIF_WINDOW_MAXIMIZED(win)

A notification emitted when a window is maximized, it return the window maximized.
=#
@Notifyer NOTIF_WINDOW_MAXIMIZED(win)

#=
	@Notifyer NOTIF_WINDOW_RESTORED(win)

A notification emitted when a window is restored, it return the window restored.
=#
@Notifyer NOTIF_WINDOW_RESTORED(win)

#=
	@Notifyer NOTIF_WINDOW_HIDDEN(win)

A notification emitted when a window is hidden, it return the window hidden.
=#
@Notifyer NOTIF_WINDOW_HIDDEN(win)

#=
	@Notifyer NOTIF_WINDOW_SHOWN(win)

A notification emitted when a window is shown, it return the window shown.
=#
@Notifyer NOTIF_WINDOW_SHOWN(win)

#=
	@Notifyer NOTIF_WINDOW_RAISED(win)

A notification emitted when a window is raised, it return the window raised.
=#
@Notifyer NOTIF_WINDOW_RAISED(win)
@Notifyer NOTIF_WINDOW_DELAYING(t)

#=
	@Notifyer NOTIF_WINDOW_TITLE_CHANGED(win,new_title::String)

A notification emitted when the title of a window changed, it return the window and the new
title of the window.
=#
@Notifyer NOTIF_WINDOW_TITLE_CHANGED(win,new_title::String)

#=
	@Notifyer NOTIF_WINDOW_REPOSITIONED(win,x::Integer,y::Integer)

A notification emitted when the position of a window changed, it return the window and the new x 
and y position of the window.
=#
@Notifyer NOTIF_WINDOW_REPOSITIONED(win,x::Integer,y::Integer)

#=
	@Notifyer NOTIF_WINDOW_RESIZED(win,width::Integer,height::Integer)

A notification emitted when the size of a window changed, it return the window and the new 
width and height of the window.
=#
@Notifyer NOTIF_WINDOW_RESIZED(win,width::Integer,height::Integer)

#=
	@Notifyer NOTIF_WINDOW_FULLSCREEN(win,active::Bool,desktop_resolution=false)

A notification emitted when a window have been set to fullscreen, it return the window,
`active` indicate if the window have been set to fullscreen(true) or to windowed(false),
`desktop_resolution` indicate if the window on which the fullscreen have been enabled is in
screen resolution(true) or in window resolution(false).
=#
@Notifyer NOTIF_WINDOW_FULLSCREEN(win,active::Bool,desktop_resolution=false)

# Notifications for errors
# Choose one depending on the gravity of the error.
#=
	@Notifyer NOTIF_ERROR(mes::String,error::String)

A notification emitted when Outdoors find a severe error that make the program unable to 
continue. It's recommended to connect to it a function to throw the received error or at least
to handle it.
=#
@Notifyer NOTIF_ERROR(mes::String,error::String)

#=
	@Notifyer NOTIF_WARNING(mes::String,warning::String)

A notification emitted when Outdoors find a problem but that problem does not make the program 
unable to process.
=#
@Notifyer NOTIF_WARNING(mes::String,warning::String)

#=
	@Notifyer NOTIF_INFO(mes::String,info::String)

A notification emitted when an information should be passed (For example the information about
a driver, etc.).
=#
@Notifyer NOTIF_INFO(mes::String,info::String)

# ---------- Enumerations ----------- #

"""
	enum ContextType
		SIMPLE_CONTEXT
		OPENGL_CONTEXT
		DIRECTX_CONTEXT
		UNKNOW_CONTEXT

An enumeration to specify which type of context will be use by a window.
"""
@enum ContextType begin
	SIMPLE_CONTEXT
	OPENGL_CONTEXT
	DIRECTX_CONTEXT
	UNKNOW_CONTEXT
end

# ----------- Functions ------------- #
"""
	abstract type AbstractStyle

An abstract type for the window of an application.
Use it as supertype when you want to add a new type of window.

"""
abstract type AbstractStyle end

include("Errors.jl")
include("Event_structs.jl")

mutable struct ODWindow{T <: AbstractStyle}
	data::T
	active::Bool
	id::UInt
	app::WeakRef
	inputs::InputState
	zones::Dict{Int, Any}

	## Constructors

	ODWindow{T}(data::T) where T <: AbstractStyle = new(data,true, 0, WeakRef(nothing), InputState(), Dict{Int, Any}())
end

struct ODApp
	Windows::Dict{Int,ODWindow}
	WindowTree :: ObjectTree

	ODApp() = new(Dict{Int,ODWindow}(), ObjectTree())
end

include("Events.jl")

"""
	InitOutdoor(::Type{AbstractStyle})

Init an outdoor API.
When creating your own window style, you should create a dispatch of it with the type of your window.
"""
InitOutdoor(::Type{AbstractStyle}) = NOTIF_OUTDOOR_INITED.emit

"""
	CreateContext(app::ODWindow,mode::ContextType)

Create the context `mode` into the window `win`.
When creating your own window style, you should create a dispatch of it with the type of your window.
"""
CreateContext(app::ODWindow,mode::ContextType) = (NOTIF_CONTEXT_CREATED.emit = win)

"""
	CreateWindow(::Type{AbstractStyle},args...)

Function to create a window depending on the type passed in parameters.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_CREATED` when the window have been successfuly
inited.
"""
CreateWindow(::Type{AbstractStyle},args...;kwargs...) = NOTIF_WINDOW_CREATED.emit = window

"""
	ResizeWindow(app::ODWindow,width,heigth)

Function to resize a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_RESIZED` with the new width and heigth
when the window have been successfuly resized.
"""
ResizeWindow(app::ODWindow,width,heigth) = (NOTIF_WINDOW_RESIZED.emit = (window,width,heigth))

"""
	RepositionWindow(app::ODWindow,x,y)

Function to reposition a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_REPOSITIONED` with the new x-position and y-position.
when the window have been successfuly Repositioned.
"""
RepositionWindow(app::ODWindow,x,y) = (NOTIF_WINDOW_REPOSITIONED.emit = (window,x,y))

"""
	SetWindowTitle(app::ODWindow,new_title)

Set the title of a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_TITLE_CHANGED` with the new title
when the window title has been successfully changed.
"""
SetWindowTitle(app::ODWindow,new_title) = (NOTIF_WINDOW_TITLE_CHANGED.emit = (window,new_title))

"""
	MaximizeWindow(app::ODWindow)

A function to maximize a window(set it to the screen size).
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_MAXIMIZED` when the window have been successfuly maximized.
"""
MaximizeWindow(app::ODWindow) = NOTIF_WINDOW_MAXIMIZED.emit = window

"""
	MinimizeWindow(app::ODWindow)

A function to minimize a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_MINIMIZED` when the window have been successfuly minimized.
"""
MinimizeWindow(app::ODWindow) = NOTIF_WINDOW_MINIMIZED.emit = window

"""
	RestoreWindow(app::ODWindow)

A function to restore a window that have been minimized.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_RESTORED` when the window have been successfuly restored.
"""
RestoreWindow(app::ODWindow) = NOTIF_WINDOW_RESTORED.emit = window

"""
	HideWindow(app::ODWindow)

A function to hide a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_HIDDEN` when the window have been successfuly hidden.
"""
HideWindow(app::ODWindow) = NOTIF_WINDOW_HIDDEN.emit = window

"""
	ShowWindow(app::ODWindow)

A function to show a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_SHOWN` when the window have been successfuly shown.
"""
ShowWindow(app::ODWindow) = NOTIF_WINDOW_SHOWN.emit = window

"""
	RaiseWindow(app::ODWindow)

A function to raise a window (set it on top of other window).
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_RAISED` when the window have been successfuly raised.
"""
RaiseWindow(app::ODWindow) = NOTIF_WINDOW_RAISED.emit = window

"""
	SetFullscreen(app::ODWindow,active::Bool)

Fuction to set fullscreen on a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_FULLSCREEN` with a bool to know if it's enabled/disabled
when the window have been successfuly set to fullscreen.
"""
SetFullscreen(app::ODWindow,active::Bool) = (NOTIF_WINDOW_FULLSCREEN.emit = (window,active))

"""
	UpdateWindow(app::ODWindow,args...)

A Function to update a window (render again).
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_UPDATED` when the window have been successfuly updated.
"""
UpdateWindow(app::ODWindow,args...) = NOTIF_WINDOW_UPDATED.emit = window

"""
	GetError(app::ODWindow,args...)

Return the lastest error that happened in the window.
When creating your own window style, you should create a dispatch of it with the type of your window.

After you catch an error with GetError, depending on the severity, you will have to use one of the
following notification:
   * NOTIF_INFO
   * NOTIF_WARNING
   * NOTIF_ERROR
"""
GetError(app::ODWindow,args...) = nothing

"""
	GetWindowID(app::ODWindow)

Return the id of a window, You should create a dispatch of it for your new type.
"""
GetWindowID(app::ODWindow) = getfield(app,:id)

"""
	QuitWindow(app::ODWindow)

A funtion to close a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_WINDOW_EXITTED` when the window have been closed.
"""
QuitWindow(app::ODWindow) = NOTIF_WINDOW_EXITTED.emit = window

QuitStyle(T::Type{AbstractStyle}) = (NOTIF_OUTDOOR_STYLE_QUITTED.emit = T)

"""
	QuitOutdoor(::Type{AbstractStyle})

Initiliatize the current outdoor API
When creating your own window style, you should create a dispatch of it with the type of your window.

"""
QuitOutdoor() = begin
	for (_,win) in Windows
		QuitWindow(win)
	end
	childs = get_children(get_root(WindowTree))

	while length(childs) > 0
		QuitWindow(childs[1])
		pop!(childs)
	end

	NOTIF_OUTDOOR_QUITTED.emit
end

"""
	WindowCount()

Return the number of active Window
"""
WindowCount() = length(Windows)

"""
	GetStyle(app::ODWindow)

return the style data of an ODWindow object.
"""
GetStyle(app::ODWindow) = getfield(app, :data)

function GetWindowFromStyleID(app::ODApp,style::Type{<:AbstractStyle}, id::Integer)
	
   # We iterate on the different windows of the app
	for win in getfield(app.Windows,:vl)
		st = GetStyle(win)

		if st isa style && (GetStyleWindowID(st) == id)
			return win
		end
	end
end

AttribID(id::Integer) = (id,)
AttribID(id1::Tuple,id2::Integer) = tuple(id1...,id2)
AttribID(app::ODWindow,id::Integer) = tuple(GetWindowID(win)...,id)

function add_to_app(app::ODApp, win::ODWindow;name="")
	Windows = getfield(app, :Windows)
	Tree = getfield(app, :WindowTree)
	
	node = Node(win, name)
	add_child(Tree,node)

	new_id = get_nodeidx(node)
	setfield!(win,:id,new_id)

	win.app = WeakRef(app)

	Windows[new_id] = win
end

function DestroyChildWindow(win::ODWindow)
	app = win.app.value

	if app != nothing
		windows = getfield(app, :Windows)
		Tree = getfield(app, :WindowTree)
		node = get_node(get_root(Tree),GetWindowID(win))

		childs = get_children(node)

		while length(childs) > 0
			QuitWindow(childs[])
			remove_node(childs)
			delete!(windows,childs[].id)
		end
	end
end

include("SDL/SDL.jl")

end #module
