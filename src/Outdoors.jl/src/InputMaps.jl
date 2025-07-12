## Input maps ##

export InputMap
export @InputMap
export HasKey, AddKey, RemoveKey, GetKeys

"""
	mutable struct InputMap
		keys :: Set{String}
		strength :: Float64

A mutable struct representing a set of keys for a given action.
It's recommended to construct it via `@InputMap Input_name(key1,key2,...,keyN,strength=1.0)`

	InputMap(keys::String...;strength=1.0)

Construct an InputMap from a set of keys and the given `strength`

	InputMap(keys::Union{Tuple,AbstractArray};strength=1.0)

Construct an InputMap from a Tuple or an AbstractArray with the given `strength`
"""
mutable struct InputMap
	keys :: Set{String}
	strength :: Float64

	# Constructors #

	InputMap(keys::String...;strength=1.0) = new(Set{String}(keys),strength)
	InputMap(keys::Union{Tuple,AbstractArray};strength=1.0) = new(Set{String}(keys),strength)
end

"""
	@InputMap Input_name(key1,key2,...,keyN,strength=1.0)

Construct an `InputMap` with the given keys(Strings) and strength as a constant

# Example

```julia-repl

julia> using Outdoors

julia> @InputMap Shoot("S","Z",strength=1.0)

julia> Shoot
InputMap(Set(["S","Z"]), 1.0)

```
"""
macro InputMap(ex)
	name = ex.args[1]
	len = length(ex.args)
	strength = ex.args[len].args[2]

	!(strength isa AbstractFloat) && (strength=1.0;len += 1)
	keys = ex.args[2:len-1]

	_create_inputmap(__module__,name,keys,strength)
end

"""
	AddKey(inp::InputMap,key::String)

Add the key `key` in the InputMap `inp`
"""
AddKey(inp::InputMap,key::String) = push!(inp.keys,key)

"""
	HasKey(inp::InputMap,key::String)

Verify if the InputMap `inp` has the key `key`.
"""
HasKey(inp::InputMap,key::String) = key in inp.keys

"""
	RemoveKey(inp::InputMap,key::String)

Remove the key `key` in the InputMap `inp`
"""
RemoveKey(inp::InputMap,key::String) = delete!(inp.keys,key)

"""
	GetKeys(inp::InputMap)

Return all the keys of the InputMap `inp`
"""
GetKeys(inp::InputMap) = getfield(inp,:keys)

function IsKeyPressed(win::ODWindow, inp::InputMap)
	Inputs = get_keyboard_data(get_inputs_data(win))
	MouseButtons = get_mousebutton_data(get_inputs_data(win))

	for key in GetKeys(inp)
		if key in Inputs
			IsKeyPressed(win,key) ? (return true) : nothing
		elseif key in MouseButtons
			IsMouseButtonPressed(win,key) ? (return true) : nothing
		end
	end

	return false
end

function IsKeyJustPressed(win::ODWindow,inp::InputMap)
	Inputs = get_keyboard_data(get_inputs_data(win))
	MouseButtons = get_mousebutton_data(get_inputs_data(win))

	for key in GetKeys(inp)
		if key in Inputs
			IsKeyJustPressed(win,key) ? (return true) : nothing
		elseif key in MouseButtons
			IsMouseButtonJustPressed(win,key) ? (return true) : nothing
		end
	end

	return false
end

IsKeyReleased(win::ODWindow,inp::InputMap) = !IsKeyPressed(win,inp)

function IsKeyJustReleased(win::ODWindow,inp::InputMap)
	Inputs = get_keyboard_data(get_inputs_data(win))
	MouseButtons = get_mousebutton_data(get_inputs_data(win))

	for key in GetKeys(inp)
		if key in Inputs
			IsKeyJustReleased(win,key) ? (return true) : nothing
		elseif key in MouseButtons
			IsMouseButtonJustReleased(win,key) ? (return true) : nothing
		end
	end

	return false
end

function _create_inputmap(m,name,keys,strength)
	
	eval(Expr(:toplevel, m, :(const $name = InputMap($keys; strength=$strength))))
	eval(Expr(:export, name))
end