#######################################################################################################################
################################################## COMMAND BUFFER #####################################################
#######################################################################################################################

export CommandBuffer, CommandAction, RenderCommand, CommandQuery
export add_command!, remove_command!, remove_all_command!

#=

Ok, first what's a command buffer ?
A command buffer represent an order we send too the GPU. We use it to batch processing
We group commands by type then at each end of loop, we update them all in groups.
This serve multiple purpose (like drastically reducing draw call and allowing us to manage more efficiently draw calls)
So what describe a command buffer ?
First the commands.
It's baceknd dependent, for exemple SDL may need a target for each command will OpenGL doesn't
So we need to have a clear style

Who request -> Object requesting the command
What's requested -> the actual command
to apply where -> The target of the command.

So a typicall command may be

Point2D request to be drawn on TextureN
This way we put Point2D on the queue of hte one requesting that.

Ok seems fair, but we then need a basic structure
first commands

a command is 3 point
1 - the caller
2 - the action
3 - the target

next we need priorities
for exemple, I may have a command that is made after a low priority one but I want the first one to execute before
So we need ordering by priorities.

Next We will batch commands or maybe do it in parallel.
Finally we need to clean up. For that we can just reallocate the buffers.

Now our hierarchy

CommandBuffer
└── TargetID (e.g. main framebuffer, offscreen texture)
    └── PriorityLevel (e.g. 0, 1, 2)
        └── List of Commands [DrawSprite, ClearBuffer, CopyTo, etc.]

At each run we set the command, we batch but priorities and target then we clean up.
Seems fair
I think we need to take a brute
=#

"""
    abstract type CommandAction end

Supertype of everu possible action of the rendering engine.
To create a new action, use `@commandaction`
"""
abstract type CommandAction end

const BITBLOCK_SIZE = 32
const BITBLOCK_MASK = (1 << BITBLOCK_SIZE) - 1
const COMMAND_ACTIONS = Type{<:CommandAction}[]

"""
	struct CommandQuery
		mask::UInt128
		ref::UInt128

Represent a query for a command buffer.
Use this whetever you need to get a set command matching a specific pattern.
- `mask`: act as a filter to remove data irrelevant for the query.
- `ref`: Is the actual pattern a render command should match to be taken by the query.

## Constructor

    CommandQuery(;target=0, priority=0, caller=0,commandid=0)

Create a new command query that will match the RenderCommand with the given parameters.
"""
struct CommandQuery
	mask::UInt128
	ref::UInt128

    ## Constructors

    function CommandQuery(;target=0, priority=0, caller=0,commandid=0)
    	mask = UInt128(0)
    	ref = UInt128(0)

    	if target != 0
    		mask |= UInt128(BITBLOCK_MASK) << (BITBLOCK_SIZE*3)
    		ref |= UInt128(target) << (BITBLOCK_SIZE*3)
    	end
    	if priority != 0
    		mask |= UInt128(BITBLOCK_MASK) << (BITBLOCK_SIZE*2)
    		ref |= UInt128(priority) << (BITBLOCK_SIZE*2)
    	end
    	if caller != 0
    		mask |= UInt128(BITBLOCK_MASK) << (BITBLOCK_SIZE)
    		ref |= UInt128(caller) << (BITBLOCK_SIZE)
    	end
    	if commandid != 0
    		mask |= UInt128(BITBLOCK_MASK)
    		ref |= UInt128(commandid)
    	end

    	return new(mask, ref)
    end
end

"""
	struct RenderCommand{T} where T <: CommandAction
		target::Int
		priority::Int
		caller::Int
		command::T

A command that can be executed by a renderer.
When implementing you renderer, You should make it in such way that it can execute as many command as possible.
- `target`: The id of the object on which the command is applied.
- `priority`: Whether the command should be executed before or after another one.
- `caller`: The id of the object requesting the command. `0` usually means there is no caller object.
- `commands`: All the actual command that should be executed.

## Constructors

    RenderCommand(tid::Int, p::Int, cid::Int)

Create a new command for the renderer.
- `tid`: The id of the target.
- `p`: The priority of the command.
- `cid`: The id of the caller object, `0` means no object is calling.
"""
struct RenderCommand{T}
	target::Int
	priority::Int
	caller::Int
	commands::Vector{T}

	## Constructors

	function RenderCommand{T}(tid::Int, p::Int, cid::Int) where T <: CommandAction
	    @assert tid >= 0 && tid <= BITBLOCK_MASK "Target ID out of range"
	    @assert p >= 0 && p <= BITBLOCK_MASK "Priority out of range"
	    @assert cid >= 0 && cid <= BITBLOCK_MASK "Caller ID out of range"
	    new{T}(tid, p, cid, T[])
	end
end


"""
	mutable struct CommandBufferRoot
		tree::Dict{UInt128, Vector{<:RenderCommand}}

This is the root of a command buffer. The signature of a render command directly match the corresponding set of command

## Constructor

    CommandBufferRoot()

Create a new empty root for a command buffer.
"""
mutable struct CommandBufferRoot
	tree::Dict{Symbol,Dict{UInt128, RenderCommand}}

	## Constructor

	CommandBufferRoot() = new(Dict{Symbol,Dict{UInt128, RenderCommand}}(:render => Dict{UInt128, RenderCommand}(),
		:postprocess => Dict{UInt128, RenderCommand}()))
end

"""
	mutable struct CommandBuffer
		root::CommandBufferRoot

Create a new command buffer. This object is responsible for the management of rendering commands.
"""
mutable struct CommandBuffer
	root::CommandBufferRoot

	## Constructor

	CommandBuffer() = new(CommandBufferRoot())
end

"""
    @commandaction command_name begin
        # fields...
    end

This create a new command action and set all the necessary boilerplates for you.
	After a new command is created, you just show to you renderer how to process it and you are done.
"""
macro commandaction(struct_name, block)
    l = length(COMMAND_ACTIONS)

	# Our struct expression
	struct_ex = Expr(:struct, false, :($struct_name <: CommandAction), block)
	__module__.eval(struct_ex)

    __module__.eval(quote
    	    push!(COMMAND_ACTIONS, $struct_name)
			Horizons.get_commandid(::Type{$struct_name}) = $l + 1
        end
    )
end

####################################################### FUNCTIONS ######################################################

function ExecuteCommands(ren)
	cb = get_commandbuffer(ren)
	
	for pass in pass_order(ren)
		commands = sorted_command_bypriority(cb;pass=pass)
		for (signature, batch) in commands
			targetid = get_cmd_targetid(signature)
			callerid = get_cmd_commandid(signature)

			execute_command(ren, targetid, callerid, batch.commands)
		end
	end
end

"""
    add_command!(cb::CommandBuffer, r::RenderCommand{T}) where T <: CommandAction

This will add the render command `r` to it's correct set in the command buffer `cb`
"""
function add_command!(cb::CommandBuffer,target,priority,caller, r::T;pass=:render) where T <: CommandAction
    key = encode_command(T,target,priority,caller)
    tree = cb.root.tree[pass]
    if !haskey(tree, key)
        tree[key] = RenderCommand{T}(target, priority,caller)
    end
    push!(tree[key].commands, r)
end

"""
    remove_command!(cb::CommandBuffer, r::RenderCommand)

Remove given command from his list list.
"""
function remove_a_command!(r::RenderCommand{T}, c::T;pass=:render) where T <: CommandAction
    deleteat!(r.commands, findfirst(==(c), r.commands))
end

remove_command!(cb::CommandBuffer, r::RenderCommand;pass=:render) = delete!(cb.root.tree[pass], encode_command(r))

"""
    commands_iterator(cb::CommandBuffer, query::CommandQuery)

Return an iterator of commands in the CommandBuffer `cb` matching the given `query`.
"""
function commands_iterator(cb::CommandBuffer, query::CommandQuery)
	results = RenderCommand[]
	for (k, v) in cb.root.tree
		if (k & query.mask) == query.ref
			push!(results, v)
		end
	end

	return results
end

extract_field(key::UInt128, offset) = (key >> (offset * BITBLOCK_SIZE)) & BITBLOCK_MASK 

function field_iterator(cb::CommandBuffer, offset)
    result = UInt32[]
    for key in keys(cb.root.tree)
        push!(result, extract_field(key, offset))
    end
    return unique!(result)
end

function tuple_iterator(cb::CommandBuffer, offsets::Tuple{Vararg{Int}}; pass=:render)
    result = Set{NTuple{length(offsets), UInt32}}()
    for key in keys(cb.root.tree[pass])
        values = ntuple(i -> UInt32(extract_field(key, offsets[i])), length(offsets))
        push!(result, values)
    end
    return collect(result)
end

"""
    sorted_command_groups(cb::CommandBuffer; by=default_key)

Returns a vector of commands vector `Vector{Vector{RenderCommand}}`,
where each group is an unique signature,
and groups are sorted following the traits given in `by`.

# Arguments
- `cb`: The `CommandBuffer` to analyze
- `by`: A function `UInt128 -> SortKey`, sort by default by `(target, priority, commandid)`

# Example
    `sorted_command_groups(cb)`
    `sorted_command_groups(cb; by = k -> decode_command(k)[1:2])  # sort by (target, priority)`
"""
function sorted_command_groups(cb::CommandBuffer; by = default_key, pass=:render)
    groups = collect(cb.root.tree[pass])
    sort!(groups, by = x -> by(x[1]))
    return groups
end
sorted_command_bypriority(cb::CommandBuffer;pass=:render) = sorted_command_groups(cb; by=get_cmd_priority, pass=pass)

"""
    get_sortkey(::CommandAction)

Return the sort key for a fiven command. Par défaut, retourne `nothing`, ce qui signifie "pas de tri".
"""
function get_sortkey(cmd::CommandAction)
    return nothing
end


default_key(key::UInt128) = decode_command(key)

target_iterator(cb::CommandBuffer)    = field_iterator(cb, 3)
priority_iterator(cb::CommandBuffer)  = field_iterator(cb, 2)
caller_iterator(cb::CommandBuffer)    = field_iterator(cb, 1)
commandid_iterator(cb::CommandBuffer) = field_iterator(cb, 0)

target_priority_iterator(cb::CommandBuffer)    = tuple_iterator(cb, (3, 2))
target_commandid_iterator(cb::CommandBuffer)   = tuple_iterator(cb, (3, 0))
caller_priority_iterator(cb::CommandBuffer)    = tuple_iterator(cb, (1, 2))
target_priority_command_iterator(cb::CommandBuffer) = tuple_iterator(cb, (3, 2, 0))

function clear!(cb::CommandBuffer)
    tree = cb.root.tree
    for key in keys(tree)
    	cmd = tree[key]
    	for c in values(cmd)
    		empty!(c.commands)
    	end
    end
end


######################################################## HELPERS #######################################################

get_commandid(T::Type{<:CommandAction}) = error("get_commandid not defined for command type $T")
encode_command(c::RenderCommand{T}) where T <: CommandAction = (c.target << (BITBLOCK_SIZE*3)) |
	(c.priority << (BITBLOCK_SIZE*2)) |
	(c.caller << BITBLOCK_SIZE) |
	get_commandid(T)
encode_command(::Type{T},target, priority, caller) where T <: CommandAction = (target << (BITBLOCK_SIZE*3)) |
	(priority << (BITBLOCK_SIZE*2)) |
	(caller << BITBLOCK_SIZE) |
	get_commandid(T)


function decode_command(v::UInt128)
	commandid = v & BITBLOCK_MASK
	callerid = (v >> BITBLOCK_SIZE) & BITBLOCK_MASK
	priority = (v >> (BITBLOCK_SIZE*2)) & BITBLOCK_MASK
	targetid = (v >> (BITBLOCK_SIZE*3)) & BITBLOCK_MASK

	return (targetid, priority, callerid, commandid)
end
get_cmd_targetid(v::UInt128) = (v >> (BITBLOCK_SIZE*3)) & BITBLOCK_MASK
get_cmd_priority(v::UInt128) = (v >> (BITBLOCK_SIZE*2)) & BITBLOCK_MASK
get_cmd_callerid(v::UInt128) = (v >> BITBLOCK_SIZE) & BITBLOCK_MASK
get_cmd_commandid(v::UInt128) = v & BITBLOCK_MASK
get_command_fromid(i::Int) = COMMAND_ACTIONS[i]

pass_order(ren) = (:render, :postprocess)
add_pass(cb::CommandBuffer, name::String) = (cb.root.tree[name] = Dict{UInt128, RenderCommand}())

fast_haskey(dict::Dict, key) = begin
    hsh = hash(key)::UInt
    idx = (((hsh % Int) & (length(dict.keys)-1)) + 1)::Int
    
    isdefined(dict.keys, idx) && isequal(dict.keys[idx], key)
end