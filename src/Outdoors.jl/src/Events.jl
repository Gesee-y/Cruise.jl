## Some events for the Outdoor module ##

export NOTIF_JOYPAD_INPUT, NOTIF_EVENT_RECEIVED, NOTIF_KEYBOARD_INPUT, NOTIF_MOUSE_MOTION
export NOTIF_QUIT_EVENT, NOTIF_WINDOW_EVENT, NOTIF_MOUSE_BUTTON
export Inputs, Event, ClickEvent, KeyboardEvent, WindowEvents, RightClick, RightDoubleClick
export LeftClick, LeftDoubleClick, MiddleClick
export EventLoop, GetEvents, GetMousePosition, GetAxis
export IsKeyPressed, IsKeyReleased, IsMouseButtonPressed, IsMouseButtonReleased
export IsKeyJustPressed, IsKeyJustReleased, IsMouseButtonJustPressed, IsMouseButtonJustReleased

@Notifyer NOTIF_EVENT_RECEIVED(event,type)
@Notifyer NOTIF_WINDOW_EVENT(win,ev,d1::Integer=0,d2::Integer=0)
@Notifyer NOTIF_KEYBOARD_INPUT(win,keys)
@Notifyer NOTIF_MOUSE_MOTION(win,ev)
@Notifyer NOTIF_MOUSE_WHEEL(win,ev)
@Notifyer NOTIF_MOUSE_BUTTON(win,ev)
@Notifyer NOTIF_JOYPAD_INPUT(win,keys::Tuple)
@Notifyer NOTIF_QUIT_EVENT()

"""
	GetEvents(::Type{AbstractStyle})

This function should be use to get the events gived by the user.
When creating your our window style, you should create a dispatch of it for your type.

This function emit the notification `NOTIF_EVENT_RECEIVED` with the event received and then
you can connect EventHandler on it to act in consequences.
"""
GetEvents(::Type{AbstractStyle}) = nothing

"""
	HandleWindowEvent(::Type{AbstractStyle},event)

This function is to manage the event of the window (resize,move,etc.)
When creating your our window style, you should create a dispatch of it for your type.
"""
function HandleWindowEvent(::Type{AbstractStyle},event) end

"""
	HandleKeyboardInputs(window::AbstractStyle)

A Function to handle the inputs of the keyboard of a window.
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification `NOTIF_KEYBOARD_INPUT` only when inputs have been found with the input found 
"""
HandleKeyboardInputs(window::AbstractStyle) = NOTIF_KEYBOARD_INPUT.emit = (window,())

"""
	HandleMouseEvents(window::AbstractStyle)

A Function to get the mouse events (movement,wheel,buttons,etc).
When creating your own window style, you should create a dispatch of it with the type of your window.

# Note

Don't forget to emit the notification one of the following notification depending on the event
   * `NOTIF_MOUSE_MOTION` if the event found is a movement of the mouse
   * `NOTIF_MOUSE_BUTTON` if the event found is relative to one of the button of the mouse
   * `NOTIF_MOUSE_WHEEL` if the event concern the wheel
"""
HandleMouseEvents(window::AbstractStyle) = NOTIF_MOUSE_MOTION.emit = (window,())

"""
	GetMousePosition(::Type{AbstractStyle})

Return the position of the mouse.
You should create a dispatch of it when you will create your own window style.
"""
GetMousePosition(::Type{AbstractStyle}) = (0,0)

"""
	IsKeyJustPressed(win::ODWindow,key::String)

This function return true if a keyboard key `key` have been just pressed, it return false in any
other case.
"""
IsKeyJustPressed(win::ODWindow,key::String) = begin
	Inputs = get_keyboard_data(get_inputs_data(win))
	!(key in Inputs) && return false

	return Inputs[key].just_pressed[]
end

"""
	IsKeyPressed(win::ODWindow,key::String)

This function return true if a keyboard key `key` is actually pressed, return false in any
other case
"""
IsKeyPressed(win::ODWindow,key::String) = begin
	Inputs = get_keyboard_data(get_inputs_data(win))
	!(key in Inputs) && return false

	return Inputs[key].pressed
end

"""
	IsKeyJustReleased(win::ODWindow,key::String)

This function return true if a keyboard key `key` have been just released, return false in any
other case
"""
IsKeyJustReleased(win::ODWindow,key::String) = begin
	Inputs = get_keyboard_data(get_inputs_data(win))
	!(key in Inputs) && return false

	return Inputs[key].just_released[]
end

"""
	IsKeyReleased(win::ODWindow,key::String)

This function return true if a keyboard key `key` is actually released, return false in any
other case
"""
IsKeyReleased(win::ODWindow,key::String) = !IsKeyPressed(win,key)

"""
	IsMouseButtonJustPressed(win::ODWindow,key::String)

This function return true if a mouse button have been just pressed, it return false in any
other case.
"""
IsMouseButtonJustPressed(win::ODWindow,key::String) = begin
	MouseButtons = get_mousebutton_data(get_inputs_data(win))
	!(key in MouseButtons) && return false

	return MouseButtons[key].just_pressed[]
end

"""
	IsMouseButtonPressed(win::ODWindow,key::String)

This function return true if a mouse button is actually pressed, it return false in any
other case.
"""
IsMouseButtonPressed(win::ODWindow,key::String) = begin
	MouseButtons = get_mousebutton_data(get_inputs_data(win))
	!(key in MouseButtons) && return false

	return MouseButtons[key].pressed
end

"""
	IsMouseButtonJustReleased(win::ODWindow,key::String)

This function return true if a mouse button have been just released, it return false in any
other case.
"""
IsMouseButtonJustReleased(win::ODWindow,key::String) = begin
	MouseButtons = get_mousebutton_data(get_inputs_data(win))
	!(key in MouseButtons) && return false

	return MouseButtons[key].just_released[]
end

"""
	IsMouseButtonReleased(win::ODWindow,key::String)

This function return true if a mouse button is actually released, it return false in any
other case.
"""
IsMouseButtonReleased(win::ODWindow,key::String) = !IsMouseButtonPressed(win,key)

"""
	ConvertKey(::Type{AbstractStyle},key)

This function should be use to transform a key received into an uniform string.
For example in SDL, if the virtual key 'a' is pressed, we will have the key "SDLK_a"
then ConvertKey will transform it into just 'A'. but it was GLFW, then the key would be
"KEY_A" and the ConvertKey function would also convert it into just 'A'
"""
function ConvertKey(::Type{AbstractStyle},key;kwargs...) end

"""
	EventLoop(T::Type{<:AbstractStyle})

To use within a loop. Update the event of the given window style T.

# Example

```julia
using Outdoors

const Close = Ref(false)
InitOutdoor(SDLApp)

Outdoors.connect(NOTIF_QUIT_EVENT) do
	Close[] = true
end

win = CreateWindow(SDLApp,"Outdoor Test",640,480)

while !Close[]
	EventLoop(SDLApp)

	IsKeyJustPressed("Z") && println("pressing Z.")
	IsMouseButtonJustPressed("LeftClick") && println("Pressing LeftClick.")
	IsKeyPressed("RIGHT") && println("Moving to the right.")

	yield()
	sleep(1/90)
end
QuitWindow(win)

QuitOutdoor(SDLApp)
```
"""
function EventLoop(app::ODApp)
	wins = getfield(app.Windows,:vl)

	for win in wins
		state = get_inputs_state(win)
		reset(state)
	end
	
	GetEvents(SDLStyle,app)

	for win in wins
		state = get_inputs_state(win)
		UpdateInputState(state)
	end
end

include("InputMaps.jl")

"""
	GetAxis(win::ODWindow,name::String)

Return the value of an Axis(Mouse movements, wheel, joystick, etc.)
"""
GetAxis(win::ODWindow,name::String) = begin
	Axes = get_axes_data(get_inputs_data(win))
	name in Axes ? Axes[name] : _DefaultAxis(name)
end

get_inputs_state(win::ODWindow) = getfield(win, :inputs)
get_inputs_data(inp::InputState) = getfield(inp, :data)
get_inputs_data(win::ODWindow) = getfield(get_inputs_state(win), :data)
get_keyboard_data(inp::InputData) = getfield(inp, :Keyboard)
get_mousebutton_data(inp::InputData) = getfield(inp, :MouseButtons)
get_axes_data(inp::InputData) = getfield(inp, :Axes)

# ------------------------------------- Helpers ---------------------------------------- #

_DefaultAxis(name) = begin
	if name == "Wheel"
		return MouseWheelEvent(0,0)
	elseif name == "MMotion"
		return MouseMotionEvent(0,0,0,0)
	end
end

function _UpdateMouseButton(data::InputData)
	MouseButtons = get_mousebutton_data(data)
	for input in MouseButtons
		inp = input[2]
		MouseButtons[input[1]] = MouseClickEvent(inp)
	end
end

function _UpdateKeyboardEvents(data::InputData)
	Inputs = get_keyboard_data(data)
	
	for input in Inputs
		inp = input[2]
		Inputs[input[1]] = KeyboardEvent(inp)
	end
end

_UpdateWheel(data::InputData) = begin
	Axes = get_axes_data(data)

	Axes["Wheel"] = MouseWheelEvent(0,0)
end

_UpdateMouseMotion(data::InputData) = begin
	Axes = get_axes_data(data)

	if "MMotion" in Axes
		motion = Axes["MMotion"]
		Axes["MMotion"] = MouseMotionEvent(motion.x,motion.y,0,0)
	end
end

_UpdateDeviceCount(win::ODWindow,cnt::Int,device::DeviceState) = begin
	if (cnt == 0 && !device.updated)
		device.count[] = win,cnt
	else
		device.updated = false
	end
end