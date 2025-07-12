## Event management with SDL ##

const EventRef = Ref{SDL_Event}()

"""
	GetEvents(::Type{SDLStyle})

This function get all the events of the SDL style of Window.

It manage the different inputs and deliver them on the form of notifications.

## Example

```julia
using Outdoors

InitOutdoor(SDLStyle)

const Close = Ref(false)

# This event is emitted when all windows are closed
Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

# This event is emitted when a key on the keyboard is pressed
Outdoors.connect(NOTIF_KEYBOARD_INPUT) do win,key
	obj = key.key

	if key.just_pressed[]
		println("Key '\$obj' just pressed.")
	elseif key.pressed
		println("Key '\$obj' is pressed.")
	elseif key.released
		println("Key '\$obj' have been released.")
	end
end

# This event is emitted when a change on a window happened
Outdoors.connect(NOTIF_WINDOW_EVENT) do win,type,w,h
	if type == Outdoors.WINDOW_RESIZED
		println("Resizing to \$(w)x\$h.")
	elseif type == Outdoors.WINDOW_MOVED
		println("Moving to \$(w),\$h.")
	elseif type == Outdoors.WINDOW_HAVE_FOCUS
		println("The mouse is in the window.")
	elseif type == Outdoors.WINDOW_LOSE_FOCUS
		println("The mouse exit the window.")
	end
end

# This event is emitted when a button of the mouse is pressed.
Outdoors.connect(NOTIF_MOUSE_BUTTON) do _, ev
	if ev.type isa LeftClick{1}
		println("Left click.")
	elseif ev.type isa LeftDoubleClick
		println("Left double click.")
	elseif ev.type isa RightClick{1}
		println("Right click.")
	elseif ev.type isa RightDoubleClick
		println("Right double click.")
	elseif ev.type isa MiddleClick
		println("Wheel click.")
	end
end

win = CreateWindow(SDLStyle,"Outdoor Events",640,480)
while !Close[]
	GetEvents(SDLStyle) # It's better to use EventLoop(SDLStyle) for the events
	yield()
end

QuitWindow(win)
QuitOutdoor(SDLStyle)

```
"""
function GetEvents(::Type{SDLStyle}, app::ODApp)
	event_ref = EventRef
	kb = 0; mm = 0; mw = 0; mb = 0; ev_count = 0

    while Bool(SDL_PollEvent(event_ref))
    	ev_type = SDL_EventType(event_ref[].type)
		HandleWindowEvent(app,event_ref,ev_type)

    	mb += HandleMouseEvents(app,event_ref,ev_type)
    	mm += HandleMouseMotionEvents(app,event_ref,ev_type)
    	mw += HandleMouseWheelEvents(app,event_ref,ev_type)

    	kb += HandleKeyboardInputs(app,event_ref,ev_type)
    	HandleKeyboardTextInputs(app,event_ref,ev_type)

    	IsQuitEvent(event_ref,ev_type)

    	ev_count += 1
    end

    #_UpdateDeviceCount(win,kb,KBState)
    #_UpdateDeviceCount(win,mb,MButton)
    #_UpdateDeviceCount(win,mm,MMotion)
    #_UpdateDeviceCount(win,mw,MWheel)

    #KBState.count[] = win, kb
    #MButton.count[] = win, mb
    #MMotion.count[] = win, mm
    #MWheel.count[] = win, mw

    return ev_count
end

#=@cfunction function EventsFilter(evt::Ref{SDL_Event},add=nothing)
	evt[].type == SDL_TEXTINPUT && return 0
		
	return 1
end=#

function HandleWindowEvent(app::ODApp,event::Ref{SDL_Event},ev_type) 
	if ev_type == SDL_WINDOWEVENT

		evt = event[]
		id = evt.window.windowID
		win = GetWindowFromStyleID(app,SDLStyle,id)

		# The window has been resized
		if evt.window.event == SDL_WINDOWEVENT_RESIZED
			x,y = evt.window.data1, evt.window.data2

			ResizeWindow(win,x,y)
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_RESIZED,x, y)

		# The window has been moved.
		elseif evt.window.event == SDL_WINDOWEVENT_MOVED
			x,y = evt.window.data1, evt.window.data2

			RepositionWindow(win,x,y)
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_MOVED,x, y)

		# A window is minimized in the taskbar
		elseif evt.window.event == SDL_WINDOWEVENT_MINIMIZED
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_MINIMIZED)
			MinimizeWindow(win)

		# An hidden window is shown
		elseif evt.window.event == SDL_WINDOWEVENT_SHOWN
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_SHOWN)
			ShowWindow(win)

		# A window that was minimized in the taskbar is restored
		elseif evt.window.event == SDL_WINDOWEVENT_RESTORED
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_RESTORED)
			RestoreWindow(win)

		# The mouse enter the window
		elseif evt.window.event == SDL_WINDOWEVENT_ENTER
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_HAVE_FOCUS)

		# The mouse leave the window
		elseif evt.window.event == SDL_WINDOWEVENT_LEAVE
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_LOSE_FOCUS)

		# The window is requested to close
		elseif evt.window.event == SDL_WINDOWEVENT_CLOSE
			NOTIF_WINDOW_EVENT.emit = (win,WINDOW_CLOSE)
		end

		return 1
	end

	return 0
end

function IsQuitEvent(event::Ref{SDL_Event},ev_type)
	if ev_type == SDL_QUIT
		NOTIF_QUIT_EVENT.emit
		return 1
	end

	return 0
end

function HandleKeyboardInputs(app::ODApp,event::Ref{SDL_Event},ev_type)
	if ev_type == SDL_KEYDOWN

		win = GetWindowFromStyleID(app,SDLStyle,event[].key.windowID)

		_update_keyboard_count(get_inputs_state(win))
		return _KeyboardKeyDown(win,event)
	elseif ev_type == SDL_KEYUP

		win = GetWindowFromStyleID(app,SDLStyle,event[].key.windowID)
		_update_keyboard_count(get_inputs_state(win))

		return _KeyboardKeyUp(win,event)
	end

	return 0
end

function HandleKeyboardTextInputs(app::ODApp,event::Ref{SDL_Event},ev_type)
	event_count = 0
	if ev_type == SDL_TEXTINPUT

		winID = event[].text.windowID
		win = GetWindowFromStyleID(app,SDLStyle,winID)

		event_count += 1

		obj = event[].text.text
		character = Char(obj[1])
	elseif ev_type == SDL_TEXTEDITING

		winID = event[].edit.windowID
		win = GetWindowFromStyleID(app,SDLStyle,winID)

		event_count += 1
		
		obj = event[].edit
		character = Char(obj.text[1])
		text = map(x -> x > 0 ? Char(x) : Char(abs(x)) ,obj.text)
	end
end

function HandleMouseEvents(app::ODApp,event::Ref{SDL_Event},ev_type)
	if ev_type == SDL_MOUSEBUTTONDOWN

		win = GetWindowFromStyleID(app,SDLStyle,event[].button.windowID)

		_update_mousebutton_count(get_inputs_state(win))
		return _MouseButtonDown(win,event)
	elseif ev_type == SDL_MOUSEBUTTONUP

		win = GetWindowFromStyleID(app,SDLStyle,event[].button.windowID)
		_update_mousebutton_count(get_inputs_state(win))
		return _MouseButtonUp(win,event)
	end

	return 0
end

function HandleMouseMotionEvents(app::ODApp,event::Ref{SDL_Event},ev_type)
	if ev_type == SDL_MOUSEMOTION

		win = GetWindowFromStyleID(app,SDLStyle,event[].motion.windowID)
		_update_mousemotion_count(get_inputs_state(win))
		return _MouseMotion(win,event)
	end
	return 0
end

function HandleMouseWheelEvents(app::ODApp,event::Ref{SDL_Event},ev_type)
	if ev_type == SDL_MOUSEWHEEL
		win = GetWindowFromStyleID(app,SDLStyle,event[].wheel.windowID)

		_update_mousewheel_count(get_inputs_state(win))
		return _MouseWheel(win,event)
	end

	return 0
end

function ConvertKey(::Type{SDLStyle},key;physical=false)
	key_string :: String = ""
	if physical
		key_string = string(key)
		key_string = uppercase(key_string[14:end])
	else
		key_string = string(SDL_KeyCode(key))
		key_string = uppercase(key_string[6:end])
	end

	return key_string
end 

# ---------- Keyboard Events Helpers ---------- #

function _KeyboardKeyUp(win::SDLWindow,event)
	data = get_inputs_data(win)
	Inputs = get_keyboard_data(data)

	id = event[].key.keysym.sym
	key = ConvertKey(SDLStyle,event[].key.keysym.sym)
	Pkey = ConvertKey(SDLStyle,event[].key.keysym.scancode;physical=true)

	just_released = Inputs[key].pressed

	key_ev = KeyboardEvent(id,key,false,false,true,just_released;Pkey=Pkey)
	Inputs[key] = key_ev

	NOTIF_KEYBOARD_INPUT.emit = (win,key_ev)

	return 1
end

function _KeyboardKeyDown(win::SDLWindow,event)
	data = get_inputs_data(win)
	Inputs = get_keyboard_data(data)

	id = event[].key.keysym.sym
	key = ConvertKey(SDLStyle,event[].key.keysym.sym)
	Pkey = ConvertKey(SDLStyle,event[].key.keysym.scancode;physical=true)

	just_pressed = key in Inputs ? (Inputs[key].pressed ? false : true) : true
	
	key_ev = KeyboardEvent(id,key,just_pressed,true,false,false;Pkey=Pkey)
	Inputs[key] = key_ev

	NOTIF_KEYBOARD_INPUT.emit = (win,key_ev)

	return 1
end

# ---------- Mouse Events Helpers ------------ #

function _MouseButtonDown(win::SDLWindow,event)
	evt = event[]
	data = get_inputs_data(win)
	MouseButtons = get_mousebutton_data(data)
	ev = nothing
	name = ""

	if evt.button.button == SDL_BUTTON_LEFT

		name = "LeftClick"
		just_pressed = name in MouseButtons ? (MouseButtons[name].pressed ? false : true) : true
		click_num = Int(evt.button.clicks)
		ev = MouseClickEvent(LeftClick{click_num}(),just_pressed,true,false,false)
	elseif evt.button.button == SDL_BUTTON_RIGHT
		
		name = "RightClick"
		just_pressed = name in MouseButtons ? (MouseButtons[name].pressed ? false : true) : true
		click_num = Int(evt.button.clicks)
		ev = MouseClickEvent(RightClick{click_num}(),just_pressed,true,false,false)
	elseif evt.button.button == SDL_BUTTON_MIDDLE
		
		name = "MiddleClick"
		just_pressed = name in MouseButtons ? (MouseButtons[name].pressed ? false : true) : true
		
		click_num = Int(evt.button.clicks)
		ev = MouseClickEvent(MiddleClick{click_num}(),just_pressed,true,false,false)
	end

	MouseButtons[name] = ev
	NOTIF_MOUSE_BUTTON.emit = (win,ev)

	return 1
end

function _MouseButtonUp(win::SDLWindow,event)
	evt = event[]
	
	data = get_inputs_data(win)
	MouseButtons = get_mousebutton_data(data)
	ev = nothing
	name = ""

	if evt.button.button == SDL_BUTTON_LEFT
		name = "LeftClick"
		just_released = MouseButtons[name].pressed

		ev = MouseClickEvent(LeftClick{evt.button.clicks}(),false,false,just_released,true)
	elseif evt.button.button == SDL_BUTTON_RIGHT
		name = "RightClick"
		just_released = MouseButtons[name].pressed

		ev = MouseClickEvent(RightClick{evt.button.clicks}(),false,false,just_released,true)
	elseif evt.button.button == SDL_BUTTON_MIDDLE
		name = "MiddleClick"
		just_released = MouseButtons[name].pressed

		ev = MouseClickEvent(MiddleClick{evt.button.clicks}(),false,false,true,just_released)
	end

	MouseButtons[name] = ev
	NOTIF_MOUSE_BUTTON.emit = (win,ev)

	return 1
end

function _MouseMotion(win::SDLWindow,event)
	evt = event[]

	data = get_inputs_data(win)
	Axes = get_axes_data(data)

	x = evt.motion.x
	y = evt.motion.y
	xrel = evt.motion.xrel
	yrel = evt.motion.yrel

	ev = MouseMotionEvent(x,y,xrel,yrel)
	Axes["MMotion"] = ev
	NOTIF_MOUSE_MOTION.emit = (win,ev)

	return 1
end

function _MouseWheel(win::SDLWindow,event)
	evt = event[]

	data = get_inputs_data(win)
	Axes = get_axes_data(data)

	x = evt.wheel.x
	y = evt.wheel.y

	ev = MouseWheelEvent(x,y)
	Axes["Wheel"] = ev
	NOTIF_MOUSE_WHEEL.emit = (win,ev)

	return 1
end