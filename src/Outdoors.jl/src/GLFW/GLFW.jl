using GLFW

export GLFWWindow, GLFWStyle

const GLFW_WINDOW_TO_ODWINDOW = IdDict{GLFW.Window,ODWindow}()

function RegisterGLFWWindow(win::GLFWWindow)
	GLFW_WINDOW_TO_ODWINDOW[win[]] = win
end

"""
	mutable struct GLFWWindow <: AbstractStyle
		window :: Ptr{GLFW_Window}
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

This struct serve to create an GLFW style of window. It's not recommended to use the default
constructor `GLFWWindow(win,id,title,...,centered)`. Instead, Outdoor offer the function 
`CreateWindow()`. see CreateWindow()
"""
mutable struct GLFWStyle <: AbstractStyle
	window :: GLFW.Window
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

const GLFWWindow = ODWindow{GLFWStyle}

Base.getindex(win::GLFWWindow) = getfield(GetStyle(win),:window)

"""
	InitOutdoor(::Type{GLFWWindow}) 

Init Outdoor for the GLFW style of window. If everything when well, then the notification
`NOTIF_OUTDOOR_INITED` will be emitted.
"""
function InitOutdoor(S::Type{GLFWStyle}) 
	if _init_GLFW()
		NOTIF_OUTDOOR_INITED.emit = S
	end
end

function CreateWindow(app::ODApp,::Type{GLFWStyle},title::String,w,h,x=0,y=0; parent=nothing,
			xcentered=true,ycentered=true,shown=true,resizable=true,borderless=false,
			fullscreen=false,desktop=false,minimized=false,maximized=false,raise=false,
			monitor=nothing)
	centerX = xcentered ? SDL_WINDOWPOS_CENTERED : x
	centerY = ycentered ? SDL_WINDOWPOS_CENTERED : y
	show_win = shown ? SDL_WINDOW_SHOWN : SDL_WINDOW_HIDDEN
	
	## Executing the keyword arguments
	win_ptr = GLFW.CreateWindow(w,h,title)

	# We check no error happened when creating the window.
	if C_NULL != win_ptr
		id = SDL_GetWindowID(win_ptr)
		style = GLFWStyle(win_ptr,nothing, id,title,w,h,x,y,
					resizable,borderless,fullscreen,
					raise,shown,(xcentered,ycentered))
		raise ? RaiseWindow(style) : nothing
		fullscreen ? GLFW.make_fullscreen!(win_ptr) : GLFW.make_windowed!(win_ptr)
		shown ? 

		win = ODWindow{GLFWStyle}(style)

		add_to_app(app,win)
		RegisterGLFWWindow(win)

		NOTIF_WINDOW_CREATED.emit = win
		
		return win
	else
		NOTIF_ERROR.emit = ("GLFW failed to create window.", "")
	end

	return nothing
end

"""
	ResizeWindow(window::SDLWindow,width,height)

Resize an SDL style window, `window` is the window to resize, `width` is the new width of 
the window and `height` is the new height of the window.
"""
function ResizeWindow(app::GLFWWindow,width,height)
	window = GetStyle(app)

	setfield!(window,:width,width)
	setfield!(window,:height,height)

	GLFW.SetWindowSize(window.window,width,height)
	(NOTIF_WINDOW_RESIZED.emit = (window,width,height))
end

"""
	RepositionWindow(window::GLFWWindow,x,y)

Set the position of an GLFW style window, `window` is the window to reposition, 
`x` is the new position on the x-axis and `y` is the new position on the y-axis.
"""
function RepositionWindow(app::GLFWWindow,x,y)
	window = GetStyle(app)

	setfield!(window, :xpos, x)
	setfield!(window, :ypos, y)

	GLFW.SetWindowPos(window.window,x,y)
	NOTIF_WINDOW_REPOSITIONED.emit = (window,x,y)
end

"""
	SetWindowTitle(window::GLFWWindow,new_title::String)

Set the title of an GLFW style window, `window` is the window we want to set the title,
`new_title` is the new title of the window.
"""
function SetWindowTitle(app::GLFWWindow,new_title::String)
	window = GetStyle(app)

	setfield!(window,:title,new_title)

	GLFW.SetWindowTitle(window.window,new_title)
	NOTIF_WINDOW_TITLE_CHANGED.emit = (window,new_title)
end

"""
	SetFullscreen(window::GLFWWindow,active::Bool)

Active fullscreen on an SDL style window, `window` is the window we want to set the fullscreen 
on, `active` indicate if the window will be set to fullscreen(true) or windowed(false) and 
if `active` is true, `desktop` indicate if the fullscreen should be at the size of the window or 
at the size of the screen.

If everything went well then the notification `NOTIF_WINDOW_FULLSCREEN` will be emitted with
the window info and the parameters passed to the function.
If a problem happened during the execution of the function, then the notification `NOTIF_WARNING` 
will be emitted with the informations about the error.
"""
function SetFullscreen(app::GLFWWindow,active::Bool)
	window = GetStyle(app)
	active ? GLFW.make_fullscreen!(window.window) : GLFW.make_windowed!(window.window)

	window.fullscreen = active
	NOTIF_WINDOW_FULLSCREEN.emit = (window,active,true)
end

"""
	MaximizeWindow(window::GLFWWindow)

Maximize the GLFW Style window `window`
After maximizing the notification `NOTIF_WINDOW_MAXIMIZED` is emitted with the window maximized.
"""
function MaximizeWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.MaximizeWindow(window.window)
	NOTIF_WINDOW_MAXIMIZED.emit = window
end

"""
	MinimizeWindow(window::GLFWWindow)

Minimize the GLFW Style window `window`
After minimizing the notification `NOTIF_WINDOW_MINIMIZED` is emitted with the window minimized.

"""
function MinimizeWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.MinimizeWindow(window.window)
	NOTIF_WINDOW_MINIMIZED.emit = window
end

"""
	RestoreWindow(window::GLFWWindow)

Restore the GLFW Style window `window`
After restoring the notification `NOTIF_WINDOW_RESTORED` is emitted with the window restored.

"""
function RestoreWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.RestoreWindow(window.window)
	NOTIF_WINDOW_RESTORED.emit = window
end

"""
	HideWindow(window::GLFWWindow)

Hide the GLFW Style window `window`
After hidding the notification `NOTIF_WINDOW_HIDDEN` is emitted with the window hidden.
"""
function HideWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.HideWindow(window.window)
	window.shown = false
	NOTIF_WINDOW_HIDDEN.emit = window
end

"""
	ShowWindow(window::GLFWWindow)

Show the GLFW Style window `window`
After showing the notification `NOTIF_WINDOW_SHOWN` is emitted with the window shown.

"""
function ShowWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.ShowWindow(window.window)
	window.shown = true
	NOTIF_WINDOW_SHOWN.emit = window
end

"""
	RaiseWindow(window::GLFWWindow)

Raise the GLFW Style window `window`
After raising the notification `NOTIF_WINDOW_RAISED` is emitted with the window raised.

"""
function RaiseWindow(app::GLFWWindow)
	window = GetStyle(app)
	GLFW.RaiseWindow(window.window)
	window.raise = true
	NOTIF_WINDOW_RAISED.emit = window
end

"""
	GetWindowID(win::SDLWindow)

Retunr the id of the SDL style window `win`
"""
GetWindowID(win::SDLWindow) = getfield(win,:id)

# ------------ Inputs ------------ #

include("GLFW_Events.jl")

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
	QuitWindow(window::GLFWWindow)

Close the GLFW style window `window`.
after closing the window, the notification `NOTIF_WINDOW_EXITTED` is emitted with the window closed.
"""
function QuitWindow(app::GLFWWindow)
	window = GetStyle(app)
	DestroyChildWindow(app)
	delete!(GLFW_WINDOW_TO_ODWINDOW, window.window)
	GLFW.DestroyWindow(window.window)

	NOTIF_WINDOW_EXITTED.emit = app
end

"""
	QuitStyle(::Type{GLFWWindow})

Exit the GLFW style of window, this will close all the window created using the GLFW style.
"""
function QuitStyle(::Type{GLFWStyle})
	GLFW.Terminate()
	NOTIF_OUTDOOR_STYLE_QUITTED.emit = GLFWStyle
end

######################################################### HELPERS #####################################################

# Helper function to initialize GLFW
function _init_GLFW()
	if 0 != GLFW.Init()
		NOTIF_ERROR.emit = ("GLFW failed to init","")
		_quit_glfw()
		return false
	end
	return true
end

_quit_glfw() = GLFW.Terminate()