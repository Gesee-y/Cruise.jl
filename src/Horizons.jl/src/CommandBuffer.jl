#######################################################################################################################
################################################## COMMAND BUFFER #####################################################
#######################################################################################################################

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

const BITBLOCK_SIZE = 32
const BITBLOCK_MASK = (1 << BITBLOCK_SIZE) - 1
const COMMAND_ACTIONS = Type{<:CommandAction}[]

"""
    abstract type CommandAction end

Supertype of everu possible action of the rendering engine.
To create a new action, use `@commandaction`
"""
abstract type CommandAction end

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
- `command`: The actual command that should be executed.

## Constructors

    RenderCommand(tid::Int, p::Int, cid::Int, command::T)

Create a new command for the renderer.
- `tid`: The id of the target.
- `p`: The priority of the command.
- `cid`: The id of the caller object, `0` means no object is calling.
- `command`: The instruction that should be executed.
"""
struct RenderCommand{T}
	target::Int
	priority::Int
	caller::Int
	command::T

	## Constructors

	RenderCommand(tid::Int, p::Int, cid::Int, command::T) where T <: CommandAction = new{T}(tid, p, cid, command)
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
	tree::Dict{UInt128, Vector{<:RenderCommand}}

	## Constructor

	CommandBufferRoot() = Dict{UInt128, Vector{RenderCommand}}()
end

"""
	mutable struct CommandBuffer
		root::CommandBufferRoot

Create a new command buffer. This object is responsible for the management of rendering commands.
"""
mutable struct CommandBuffer
	root::CommandBufferRoot
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

"""
    add_command!(cb::CommandBuffer, r::RenderCommand{T}) where T <: CommandAction

This will add the render command `r` to it's correct set in the command buffer `cb`
"""
function add_command!(cb::CommandBuffer, r::RenderCommand{T}) where T <: CommandAction
    key = encode_command(r)
    if haskey(cb.root.tree, key)
        push!(cb.root.tree[key], r)
    else
        cb.root.tree[key] = RenderCommand{T}[r]
    end
end

"""
    remove_command!(cb::CommandBuffer, r::RenderCommand)

Remove given command from his list list.
"""
function remove_command!(cb::CommandBuffer, r::RenderCommand)
    key = encode_command(r)
    if haskey(cb.root.tree, key)
        deleteat!(cb.root.tree[key], findfirst(==(r), cb.root.tree[key]))
        isempty(cb.root.tree[key]) && delete!(cb.root.tree, key)
    end
end

remove_all_command!(cb::CommandBuffer, r::RenderCommand) = delete!(cb.root.tree, encode_command(r))

"""
    commands_iterator(cb::CommandBuffer, query::CommandQuery)

Return an iterator of commands in the CommandBuffer `cb` matching the given `query`.
"""
function commands_iterator(cb::CommandBuffer, query::CommandQuery)
	results = Vector{RenderCommand}[]
	for (k, v) in cb.root.tree
		if (k & query.mask) == query.ref
			push!(results, v)
		end
	end

	return results
end

function clear!(cb::CommandBuffer)
    empty!(cb.root.tree)
end


######################################################## HELPERS #######################################################

get_commandid(T::Type{<:CommandAction}) = error("get_commandid not defined for command type $T")
encode_command(c::RenderCommand{T}) where T <: CommandAction = (c.target << (BITBLOCK_SIZE*3)) |
	(c.priority << (BITBLOCK_SIZE*2)) |
	(c.caller << BITBLOCK_SIZE) |
	get_commandid(T)

function decode_command(v::UInt128)
	commandid = v & BITBLOCK_MASK
	callerid = (v & (BITBLOCK_MASK << BITBLOCK_SIZE)) >> BITBLOCK_SIZE
	priority = (v & (BITBLOCK_MASK << (BITBLOCK_SIZE*2))) >> (BITBLOCK_SIZE*2)
	targetid = (v & (BITBLOCK_MASK << (BITBLOCK_SIZE*3))) >> (BITBLOCK_SIZE*3)

	return (targetid, priority, callerid, commandid)
end
get_command_fromid(i::Int) = COMMAND_ACTIONS[i]