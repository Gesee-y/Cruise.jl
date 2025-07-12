## Structures for the event manager.

"""
	Abstract type Event

The base type for any kind of event a window can receive.
"""
abstract type Event end
abstract type AxisEvent <: Event end

abstract type ClickEvent <: Event end

"""
	mutable struct DeviceState
		count :: Signal{Tuple{Int}}
		updated :: Bool

A structure representing the state of a device, `count` is the number of time the device 
received inputs for a given frame, `updated` is just to remind if we have already update the DeviceState.
"""
mutable struct DeviceState
	updated :: Bool
	cnt::Int

	DeviceState(updated=false) = new(updated, 0)
end

"""
	@enum WindowEvents begin
		WINDOW_RESIZED
		WINDOW_MOVED
		WINDOW_MAXIMIZED
		WINDOW_MINIMIZED
		WINDOW_RESTORED
		WINDOW_SHOWN
		WINDOW_HIDDEN
		WINDOW_HAVE_FOCUS
		WINDOW_LOSE_FOCUS
		WINDOW_CLOSE
	end

Events for the window. To use when you want to emit the signal `NOTIF_WINDOW_EVENT`
"""
@enum WindowEvents begin
	WINDOW_RESIZED
	WINDOW_MOVED
	WINDOW_MAXIMIZED
	WINDOW_MINIMIZED
	WINDOW_RESTORED
	WINDOW_SHOWN
	WINDOW_HIDDEN
	WINDOW_HAVE_FOCUS
	WINDOW_LOSE_FOCUS
	WINDOW_CLOSE
end

"""
	struct KeyboardEvents <: Event
		id :: Int
		key :: String
		Mkey :: String
		Pkey :: String

		just_pressed :: Bool
		pressed :: Bool
		just_released :: Bool
		released :: Bool

A struct to contain keyboard events.
"""
struct KeyboardEvent <: Event
	id :: Int
	key :: String
	Mkey :: String
	Pkey :: String

	just_pressed :: Bool
	pressed :: Bool
	just_released :: Bool
	released :: Bool

	## Constructor ##

	KeyboardEvent(id,key,just_pressed=false,pressed=false,released=false,just_released=false;Mkey="",Pkey="") = new(id,key,Mkey,Pkey,just_pressed,pressed,just_released,released)
	KeyboardEvent(ev::KeyboardEvent,just_pressed=false,just_released=false) = new(ev.id,ev.key,ev.Mkey,ev.Pkey,just_pressed,ev.pressed,just_released,ev.released)
end

"""
	struct LeftClick{N} <: ClickEvent

A struct representing a left click, `N` is the number of click.
"""
struct LeftClick{N} <: ClickEvent end

"""
	struct RightClick{N} <: ClickEvent

A struct representing a right click, `N` is the number of click.
"""
struct RightClick{N} <: ClickEvent end

"""
	struct MiddleClick{N} <: ClickEvent

A struct representing a click on the wheel of the mouse, `N` is the number of click.
"""
struct MiddleClick{N} <: ClickEvent end

"""
	LeftDoubleClick an alias for LeftClick{2}

Representing a double click on left button of the mouse.
"""
const LeftDoubleClick = LeftClick{2}

"""
	RightDoubleClick an alias for RightClick{2}

Representing a double click on right button of the mouse.
"""
const RightDoubleClick = RightClick{2}

"""
	struct MouseClickEvent <: Event
		type :: ClickEvent

		just_pressed :: Bool
		pressed :: Bool
		just_released :: Bool
		realased :: Bool

A struct representing the state of a mouse button.
"""
struct MouseClickEvent <: Event
	type :: ClickEvent

	just_pressed :: Bool
	pressed :: Bool
	just_released :: Bool
	released :: Bool

	MouseClickEvent(type,just_pressed,pressed,just_released,released) = new(type,just_pressed,pressed,just_released,released)
	MouseClickEvent(ev::MouseClickEvent,just_pressed=false,just_released=false) = new(ev.type,just_pressed,ev.pressed,just_released,ev.released)
end

"""
	struct MouseMotionEvent <: AxisEvent
		x :: Integer
		y :: Integer
		xrel :: Integer
		yrel :: Integer

A struct representing the movement of the mouse.
"""
struct MouseMotionEvent <: AxisEvent
	x :: Integer
	y :: Integer
	xrel :: Integer
	yrel :: Integer
end

"""
	struct MouseWheelEvent <: AxisEvent
		xwheel :: Int
		ywheel :: Int

A struct representing an event of the wheel.
"""
struct MouseWheelEvent <: AxisEvent
	xwheel :: Int
	ywheel :: Int
end

struct InputData
	Keyboard::Dict{String,KeyboardEvent}
	MouseButtons :: Dict{String,MouseClickEvent}
	Axes :: Dict{String,AxisEvent}

	## Constructors

	InputData(k=Dict{String,KeyboardEvent}(), 
			m=Dict{String,MouseClickEvent}(),
			a=Dict{String,AxisEvent}()) = new(k,m,a)
end

struct InputState
	data::InputData

	KBState::DeviceState
	MBState::DeviceState
	MMState::DeviceState
	MWState::DeviceState

	## Constructors

	function InputState()
		kb = DeviceState()
		mb = DeviceState()
		mm = DeviceState()
		mw = DeviceState()

		new(InputData() ,kb, mb, mm, mw)
	end
end

Base.reset(inp::InputState) = begin
	_reset_count(inp.KBState)
	_reset_count(inp.MBState)
	_reset_count(inp.MMState)
	_reset_count(inp.MWState)
end

function UpdateInputState(inp::InputState)
	_UpdateDevice(inp,inp.KBState,_UpdateKeyboardEvents)
	_UpdateDevice(inp,inp.MBState,_UpdateMouseButton)
	_UpdateDevice(inp,inp.MMState,_UpdateMouseMotion)
	_UpdateDevice(inp,inp.MWState,_UpdateWheel)
end

function _UpdateDevice(inp::InputState,d::DeviceState,update::Function)
	count = d.cnt

	if count == 0 && !d.updated
		d.updated = true
		update(get_inputs_data(inp))
	else
		d.updated = false
	end
end

_reset_count(d::DeviceState) = setfield!(d,:cnt,0)
_update_count(d::DeviceState) = modifyfield!(d,:cnt,+,1)

_update_keyboard_count(inp::InputState) = _update_count(getfield(inp,:KBState))
_update_mousebutton_count(inp::InputState) = _update_count(getfield(inp,:MBState))
_update_mousemotion_count(inp::InputState) = _update_count(getfield(inp,:MMState))
_update_mousewheel_count(inp::InputState) = _update_count(getfield(inp,:MWState))