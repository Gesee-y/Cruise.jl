## SDL2 Windows##

using SimpleDirectMediaLayer.LibSDL2

export SDLWindow, Delay, SDLStyle

"""
	mutable struct SDLWindow <: AbstractStyle
		window :: Ptr{SDL_Window}
		const id :: Integer
		title :: String

		width :: Integer
		height :: Integer
		xpos :: Integer
		ypos :: Integer

		resizable :: Bool
		borderless :: Bool
		fullscreen :: Bool
		raise :: Bool
		shown :: Bool
		centered :: NTuple{2,Bool}

This struct serve to create an SDL style of window. It's not recommended to use the default
constructor `SDLWindow(win,id,title,...,centered)`. Instead, Outdoor offer the function 
`CreateWindow()`. see CreateWindow()
"""
mutable struct SDLStyle <: AbstractStyle
	window :: Ptr{SDL_Window}
	renderer :: Union{Nothing,Ptr{SDL_Renderer}}
	const id :: Int
	title :: String

	width :: Integer
	height :: Integer
	xpos :: Integer
	ypos :: Integer

	resizable :: Bool
	borderless :: Bool
	fullscreen :: Bool
	raise :: Bool
	shown :: Bool
	centered :: NTuple{2,Bool}
end

const SDLWindow = ODWindow{SDLStyle}

Base.getindex(win::SDLWindow) = getfield(GetStyle(win),:window)

"""
	InitOutdoor(::Type{SDLWindow}) 

Init Outdoor for the SDL style of window. If everything when well, then the notification
`NOTIF_OUTDOOR_INITED` will be emitted.
"""
function InitOutdoor(::Type{SDLStyle}) 
	if _init_SDL()
		NOTIF_OUTDOOR_INITED.emit
	end
end

"""
	CreateWindow(app::ODApp,::Type{SDLStyle},title::String,w,h,x=0,y=0;
			xcentered=true,ycentered=true,shown=true,resizable=true,borderless=false,
			fullscreen=false,desktop=false,minimized=false,maximized=false,raise=false)

This function create an SDL Style window in the ODApp `app`. The first agument is the style 
of the window, `title` is the title of the window, `w` and `h` are respectively the width and height of
the window, `x` and `y` represent the position of the window, `xcentered` indicate that the
window should be centered on the x-axis and `ycentered` do the same for the y-axis, `shown`
indicate that the window should be visible, `resizable` indicate if we can resize the window
`borderless` if the window should have border, `fullscreen` indicate if the window should 
start directly on fullscreen or not, `desktop` is to be use when `fullscreen` is true, it
indicate if the fullscreen should be at the size of the window or at the size of the screen.
`minimized` indicate if the window should be minimized at the creation, `maximized` indicate
if the screen should be maximized at the creation and `raise` indicate if the window should be
on top of other window.

If everything went well then the notification `NOTIF_WINDOW_CREATED` will be emitted with the window created.

If a problem happened during the execution of the function, then the notification `NOTIF_ERROR` 
will be emitted with the informations about the error.

# Example

```julia

using Outdoors

# # Notification that is emitted when a Outdoors have been successfuly inited.
Outdoors.connect(NOTIF_OUTDOOR_INITED) do
	println("Outdoor successfuly inited!")
	println()
end

# Notification that is emitted when a window is created
Outdoors.connect(NOTIF_WINDOW_CREATED) do win
	sl = GetStyle(win)
	println("A new window named '\$(sl.title)' have been created.")
end

# Notification that is emitted when a window is closed
Outdoors.connect(NOTIF_WINDOW_EXITTED) do win
	sl = GetStyle(win)
	println("The window named '\$(sl.title)' have been exitted.")
end

# Use this to handle the error notifyed by Outdoors
Outdoors.connect(NOTIF_ERROR) do msg,err
	error(msg*err)
end

InitOutdoor(SDLStyle)
app = ODApp

win = CreateWindow(app,SDLWindow,"Outdoor Test",640,480)
sleep(4)
QuitWindow(win)

```
"""
function CreateWindow(app::ODApp,::Type{SDLStyle},title::String,w,h,x=0,y=0; parent=nothing,
			xcentered=true,ycentered=true,shown=true,resizable=true,borderless=false,
			fullscreen=false,desktop=false,minimized=false,maximized=false,raise=false,
			opengl=false)
	centerX = xcentered ? SDL_WINDOWPOS_CENTERED : x
	centerY = ycentered ? SDL_WINDOWPOS_CENTERED : y
	show_win = shown ? SDL_WINDOW_SHOWN : SDL_WINDOW_HIDDEN
	
	## Executing the keyword arguments

	minimized ? (show_win = show_win | SDL_WINDOW_MINIMIZED) : nothing
	maximized ? (show_win = show_win | SDL_WINDOW_MAXIMIZED) : nothing
	resizable ? (show_win = show_win | SDL_WINDOW_RESIZABLE) : nothing
	borderless ? (show_win = show_win | SDL_WINDOW_BORDERLESS) : nothing
	fullscreen ? (desktop ? (show_win = show_win | SDL_WINDOW_FULLSCREEN_DESKTOP) : (show_win = show_win | SDL_WINDOW_FULLSCREEN)) : nothing
	opengl ? (show_win = show_win | SDL_WINDOW_OPENGL) : nothing

	win_ptr = SDL_CreateWindow(title,centerX,centerY,w,h,show_win)

	# We check no error happened when creating the window.
	if C_NULL != win_ptr
		id = SDL_GetWindowID(win_ptr)
		style = SDLStyle(win_ptr,nothing, id,title,w,h,x,y,
					resizable,borderless,fullscreen,
					raise,shown,(xcentered,ycentered))
		raise ? RaiseWindow(style) : nothing

		win = ODWindow{SDLStyle}(style)

		add_to_app(app,win)

		NOTIF_WINDOW_CREATED.emit = win
		
		return win
	else
		err = _get_SDL_Error()
		NOTIF_ERROR.emit = ("SDL failed to create window. SDL Error: ", err)
	end

	return nothing
end

function CreateContext(app::SDLWindow,mode::ContextType;vsync=true,hardware=true)
	win = GetStyle(app)

	if mode == SIMPLE_CONTEXT
		flags = SDL_RENDERER_SOFTWARE
		hardware && (flags = SDL_RENDERER_ACCELERATED)
		vsync && (flags = flags | SDL_RENDERER_PRESENTVSYNC)

		ren = SDL_CreateRenderer(win.window, -1, flags)

		if C_NULL == ren
			err = _get_SDL_Error()
			NOTIF_ERROR.emit = ("Failed to initialize simple context for SDL2", err)

			return nothing
		end

		win.renderer = ren

		NOTIF_CONTEXT_CREATED.emit = win
	end
end
"""
	ResizeWindow(window::SDLWindow,width,height)

Resize an SDL style window, `window` is the window to resize, `width` is the new width of 
the window and `height` is the new height of the window.
"""
function ResizeWindow(app::SDLWindow,width,height)
	window = GetStyle(app)

	setfield!(window,:width,width)
	setfield!(window,:height,height)

	SDL_SetWindowSize(window.window,width,height)
	(NOTIF_WINDOW_RESIZED.emit = (window,width,height))
end

"""
	RepositionWindow(window::SDLWindow,x,y)

Set the position of an SDL style window, `window` is the window to reposition, 
`x` is the new position on the x-axis and `y` is the new position on the y-axis.
"""
function RepositionWindow(app::SDLWindow,x,y)
	window = GetStyle(app)

	setfield!(window, :xpos, x)
	setfield!(window, :ypos, y)

	SDL_SetWindowPosition(window.window,x,y)
	NOTIF_WINDOW_REPOSITIONED.emit = (window,x,y)
end

"""
	SetWindowTitle(window::SDLWindow,new_title::String)

Set the title of an SDL style window, `window` is the window we want to set the title,
`new_title` is the new title of the window.
"""
function SetWindowTitle(app::SDLWindow,new_title::String)
	window = GetStyle(app)

	setfield!(window,:title,new_title)

	SDL_SetWindowTitle(window.window,new_title)
	NOTIF_WINDOW_TITLE_CHANGED.emit = (window,new_title)
end

"""
	SetFullscreen(window::SDLWindow,active::Bool;desktop=false)

Active fullscreen on an SDL style window, `window` is the window we want to set the fullscreen 
on, `active` indicate if the window will be set to fullscreen(true) or windowed(false) and 
if `active` is true, `desktop` indicate if the fullscreen should be at the size of the window or 
at the size of the screen.

If everything went well then the notification `NOTIF_WINDOW_FULLSCREEN` will be emitted with
the window info and the parameters passed to the function.
If a problem happened during the execution of the function, then the notification `NOTIF_WARNING` 
will be emitted with the informations about the error.
"""
function SetFullscreen(app::SDLWindow,active::Bool;desktop=false)
	window = GetStyle(app)

	mode = active ? (desktop ? SDL_WINDOW_FULLSCREEN_DESKTOP : SDL_WINDOW_FULLSCREEN) : 0
	
	if 0 != SDL_SetWindowFullscreen(window.window,mode)
		err = _get_SDL_Error()
		NOTIF_WARNING.emit = ("SDL failed to set the window '$(window.title)' to fullscreen", err)
		
		return nothing
	end
	
	window.fullscreen = active
	NOTIF_WINDOW_FULLSCREEN.emit = (window,active,desktop)
end

"""
	MaximizeWindow(window::SDLWindow)

Maximize the SDL Style window `window`
After maximizing the notification `NOTIF_WINDOW_MAXIMIZED` is emitted with the window maximized.
"""
function MaximizeWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_MaximizeWindow(window.window)
	NOTIF_WINDOW_MAXIMIZED.emit = window
end

"""
	MinimizeWindow(window::SDLWindow)

Minimize the SDL Style window `window`
After minimizing the notification `NOTIF_WINDOW_MINIMIZED` is emitted with the window minimized.

"""
function MinimizeWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_MinimizeWindow(window.window)
	NOTIF_WINDOW_MINIMIZED.emit = window
end

"""
	RestoreWindow(window::SDLWindow)

Restore the SDL Style window `window`
After restoring the notification `NOTIF_WINDOW_RESTORED` is emitted with the window restored.

"""
function RestoreWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_RestoreWindow(window.window)
	NOTIF_WINDOW_RESTORED.emit = window
end

"""
	HideWindow(window::SDLWindow)

Hide the SDL Style window `window`
After hidding the notification `NOTIF_WINDOW_HIDDEN` is emitted with the window hidden.
"""
function HideWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_HideWindow(window.window)
	window.shown = false
	NOTIF_WINDOW_HIDDEN.emit = window
end

"""
	ShowWindow(window::SDLWindow)

Show the SDL Style window `window`
After showing the notification `NOTIF_WINDOW_SHOWN` is emitted with the window shown.

"""
function ShowWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_ShowWindow(window.window)
	window.shown = true
	NOTIF_WINDOW_SHOWN.emit = window
end

"""
	RaiseWindow(window::SDLWindow)

Raise the SDL Style window `window`
After raising the notification `NOTIF_WINDOW_RAISED` is emitted with the window raised.

"""
function RaiseWindow(app::SDLWindow)
	window = GetStyle(app)
	SDL_RaiseWindow(window.window)
	window.raise = true
	NOTIF_WINDOW_RAISED.emit = window
end

"""
	GetWindowID(win::SDLWindow)

Retunr the id of the SDL style window `win`
"""
GetWindowID(win::SDLWindow) = getfield(win,:id)

# ------------ Inputs ------------ #

include("SDL_Events.jl")

# ---------- Others ------------ #

"""
	GetMousePosition(::Type{SDLWindow})

Return the position of the mouse relatively to the current active SDL style window.
If you want the position of the mouse relatively to a specific window, see `NOTIF_MOUSE_MOTION`
"""
function GetMousePosition(::Type{SDLWindow})
    x,y = Int[1], Int[1]
    SDL_GetMouseState(pointer(x), pointer(y))
    
    return x[1],y[1]
end

"""
	QuitWindow(window::SDLWindow)

Close the SDL style window `window`.
after closing the window, the notification `NOTIF_WINDOW_EXITTED` is emitted with the window closed.
"""
function QuitWindow(app::SDLWindow)
	window = GetStyle(app)
	DestroyChildWindow(app)
	SDL_DestroyWindow(window.window)

	NOTIF_WINDOW_EXITTED.emit = app
end

"""
	QuitStyle(::Type{SDLWindow})

Exit the SDL style of window, this will close all the window created using the SDL style.
"""
function QuitStyle(::Type{SDLStyle})
	SDL_Quit()
	NOTIF_OUTDOOR_STYLE_QUITTED.emit = SDLStyle
end
# --------- Helpers ---------- #

# Helper function to initialize SDL
function _init_SDL()
	if 0 != SDL_Init(SDL_INIT_VIDEO)
		err = _get_SDL_Error()
		NOTIF_ERROR.emit = ("SDL failed to init video. SDL Error: ",err)
		_quit_SDL()
		return false
	end

	if 0 != SDL_Init(SDL_INIT_AUDIO)
		err = _get_SDL_Error()
		NOTIF_WARNING.emit = ("SDL failed to init audio. SDL Error: ",err)
	end

	return true
end

GetStyleWindowID(win::SDLWindow) = getfield(GetStyle(win), :id)
GetStyleWindowID(style::SDLStyle) = getfield(style, :id)

_quit_SDL() = SDL_Quit()
_get_SDL_Error() = unsafe_string(SDL_GetError())

Delay(t) = SDL_Delay(t)