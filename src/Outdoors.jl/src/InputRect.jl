########################################### Input zone for Outdoors #####################################################

#=
    This section is mostly about creating a section with it's own private input handling.
    Coordinates are local to the zone.
    First of all we need a simple wway to create a rect.
=#

include("..\\..\\MathLib.jl\\src\\MathLib.jl")

#=
    Okay, we need to be able to create a zone, manage overlap and priority
    Then we need to handle elements. Since we already have handlers for the window, we will just provide function
    to manage focus
    Next, how do we acces a zone ? 
    Next, how do we handle events ? We just need to get regular event
=#

"""
    struct InputZone
        rect::Rect2D

This struct represent an independent zone for inputs
"""
mutable struct InputZone
	const id::UInt
    rect::Rect2D
    priority::Int
    focus::Bool

    ## Constructors

    InputZone(s, e, p::Int) = new(time_ns(), Rect2D(s,e), p, false)
end

"""
    AttachZoneToWindow(win::ODWindow, zone::InputZone)

This function will attach a new zone to the window, allowing partial event handling
"""
AttachZoneToWindow(win::ODWindow, zone::InputZone)  = (win.zones[zone.id] = zone)

GetZone(win::ODWindow, id::UInt) = win.zones[id]

"""
    EnableFocus(zone::InputZone)

Will enable focus for the InputZone `zone`
"""
EnableFocus(zone::InputZone) = (zone.focus = true)

"""
    DisableFocus(zone::InputZone)

Will disable focus for the InputZone `zone`
"""
DisableFocus(zone::InputZone) = (zone.focus = false)

"""
    SetZoneFocusTo(win::ODWindow, zone::InputZone)

This function will remove the focus on all the other zone and enable it on the InputZone `zone`
"""
function SetZoneFocusTo(win::ODWindow, zone::InputZone)
    RemoveAllZoneFocus(win)
    EnableFocus(zone)
end

"""
    RemoveAllZoneFocus(win::ODWindow)

This function will disable focus on all zones
"""
function RemoveAllZoneFocus(win::ODWindow)
	for k in keys(win.zones)
		DisableFocus(win.zones[k])
	end
end
##################################### Event Handling ######################################

GetMousePosition(win::ODWindow, zone::InputZone) = begin 
    pos = GetMousePosition(win)
    rect = zone.rect

    x = pos[1] - rect.x
    y = pos[2] - rect.y

    if point_in_rect(rect,pos) && zone.focus
        return (x,y)
    end

    return nothing
end

"""
    IsKeyJustPressed(win::ODWindow,zone::InputZone,key::String)

This function return true if a keyboard key `key` have been just pressed, it return false in any
other case.
"""
IsKeyJustPressed(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsKeyJustPressed(win,key) : false

"""
    IsKeyPressed(win::ODWindow,zone::InputZone,key::String)

This function return true if a keyboard key `key` is actually pressed, return false in any
other case
"""
IsKeyPressed(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsKeyPressed(win,key) : false

"""
    IsKeyJustReleased(win::ODWindow,zone::InputZone,key::String)

This function return true if a keyboard key `key` have been just released, return false in any
other case
"""
IsKeyJustReleased(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsKeyJustReleased(win,key) : false

"""
    IsKeyReleased(win::ODWindow,zone::InputZone,key::String)

This function return true if a keyboard key `key` is actually released, return false in any
other case
"""
IsKeyReleased(win::ODWindow,zone::InputZone,key::String) = zone.focus ? !IsKeyPressed(win,key) : false

"""
    IsMouseButtonJustPressed(win::ODWindow,zone::InputZone,key::String)

This function return true if a mouse button have been just pressed, it return false in any
other case.
"""
IsMouseButtonJustPressed(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsMouseButtonJustPressed(win,key) : false

"""
    IsMouseButtonPressed(win::ODWindow,zone::InputZone,key::String)

This function return true if a mouse button is actually pressed, it return false in any
other case.
"""
IsMouseButtonPressed(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsMouseButtonPressed(win,key) : false

"""
    IsMouseButtonJustReleased(win::ODWindow,zone::InputZone,key::String)

This function return true if a mouse button have been just released, it return false in any
other case.
"""
IsMouseButtonJustReleased(win::ODWindow,zone::InputZone,key::String) = zone.focus ? IsMouseButtonJustReleased(win,key) : false

"""
    IsMouseButtonReleased(win::ODWindow,zone::InputZone,key::String)

This function return true if a mouse button is actually released, it return false in any
other case.
"""
IsMouseButtonReleased(win::ODWindow,zone::InputZone,key::String) = zone.focus ? !IsMouseButtonPressed(win,key) : false
