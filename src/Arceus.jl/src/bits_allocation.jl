############################################################ Bits Alloc ################################################

"""
    mutable struct PoolDescriptor

Represents a finalized trait pool. Contains bit layout information:

- `isAbstract`: whether this descriptor is a placeholder for an abstract subpool.
- `start`, `finish`: bit range covered by this pool.
- `args`: a dictionary mapping trait/subpool names to either:
    - A bit index (`Int`) for fixed traits,
    - Another `PoolDescriptor` for nested subpools.
"""
mutable struct PoolDescriptor
    isAbstract::Bool
    start::Int
    finish::Int
    args::Dict{Symbol, Union{Int, PoolDescriptor}}
end
PoolDescriptor(x,y,z) = PoolDescriptor(false,x,y,z)

#=
struct IncompletePoolDescriptor
    args::Dict{Symbol, Union{Int, PoolDescriptor,IncompletePoolDescriptor}}
end
=#

"""
    abstract type PoolInformation

Supertype for all pool informations. Used to define traits
"""
abstract type PoolInformation end

"""
    abstract type FixedPosPoolInformation <: PoolInformation

Supertype for all fixed trait. These trait have a static position in the pool.
"""
abstract type FixedPosPoolInformation <: PoolInformation end
is_fixed_pos(::PoolInformation) = false
is_fixed_pos(::FixedPosPoolInformation) = true

"""
    struct TraitInformation <: PoolInformation
        name::Symbol

A new trait for an entity, mainly defined by his name and taking just 1 bit.
"""
struct TraitInformation <: PoolInformation
    name::Symbol
end
getsize(::TraitInformation) = 1

"""
    struct FixedPosTraitInformation <: FixedPosPoolInformation
        name::Symbol
        pos::Int

This define a new trait at a fixed position, allowing faster lookups. 
"""
struct FixedPosTraitInformation <: FixedPosPoolInformation
    name::Symbol
    pos::Int 
end
getsize(::FixedPosTraitInformation) = 1

"""
    mutable struct SubPoolInformation <: PoolInformation
        const name::Symbol
        args::Vector{PoolInformation}

This repreent a subpool, a set of trait represented by a name and a vector of arguments.
"""
mutable struct SubPoolInformation <: PoolInformation
    const name::Symbol
    args::Vector{PoolInformation}
end
function getsize(x::SubPoolInformation)
    return maximum(final_bit(i) for i in x.args)
end
#getsize(x::SubPoolInformation) = sum(getsize(i) for i in x.args) #Assume organized.

"""
    mutable struct FixedPosSubPoolInformation <: FixedPosPoolInformation
        name::Symbol
        start::Int
        finish::Int
        args::Vector{PoolInformation}

Define a fixed size subpool.
"""
mutable struct FixedPosSubPoolInformation <: FixedPosPoolInformation
    name::Symbol
    start::Int
    finish::Int
    args::Vector{PoolInformation}
end
getsize(x::FixedPosSubPoolInformation) = x.finish-x.start+1

"""
    struct AbstractSubPoolInformation <: PoolInformation
        name::Symbol
        size::Int

This define an abstract subpool. It reserve some bits for some trait which will be added later
"""
struct AbstractSubPoolInformation <: PoolInformation
    name::Symbol
    size::Int
end
getsize(x::AbstractSubPoolInformation) = x.size

"""
    struct FixedPosAbstractSubPoolInformation <: FixedPosPoolInformation
        name::Symbol
        start::Int
        finish::Int

Fixed size abstract sub pool. Kind of a reserved pool with undefined traits. It's easier later to fill them.
"""
struct FixedPosAbstractSubPoolInformation <: FixedPosPoolInformation
    name::Symbol
    start::Int
    finish::Int
end
getsize(x::FixedPosAbstractSubPoolInformation) = x.finish-x.start+1

final_bit(x::FixedPosAbstractSubPoolInformation) = x.finish
final_bit(x::FixedPosTraitInformation) = x.pos
final_bit(x::FixedPosSubPoolInformation) = x.finish



###################################################### Helper function ############################################################

# Remove all the irrelevant node in the AST
remove_line_number_node!(x) = nothing
function remove_line_number_node!(x::Expr)
    x.args = [i for i in x.args if !(i isa LineNumberNode)]
    for i in x.args
        remove_line_number_node!(i)
    end
end

# Would have been better if this was in his own file
# Anyways, here goes nothing.
function parsed_trait_args(x)

    # first of all we should be calling a macro
    @assert x.head == :(macrocall) "Error, invalid expression's $(x.head). Data: $(x.args)"
    
    # if we are making a new trait
    if (x.args[1]) == Symbol("@trait")
        if (length(x.args) == 2)
            return TraitInformation(x.args[2])
        elseif x.args[3] == KEYWORDS[:position]
            return FixedPosTraitInformation(x.args[2],x.args[4])
        else
            error("Invalid syntax. Got : $x.\nExpected @trait name or @trait name at bit_pos")
        end
    # If we are creating a subpool
    elseif (x.args[1]) == Symbol("@subpool")
        if (x.args[3] isa Expr) # If we got a block of data (traits or subpools)
            parsed_subpool = parse_traits_first_step(x.args[3]) # We do a little adjustment
            return SubPoolInformation(x.args[2],parsed_subpool)
        elseif x.args[3] == KEYWORDS[:position] # It means the size of the pool was specified, we are creating a fixed size subpool
            Temp = x.args[4] 
            @assert ((Temp.head == :call) && (Temp.args[1] == :(-))) "Invalid argument in @subpool declaration: $Temp"
            parsed_subpool = parse_traits_first_step(x.args[5])
            return FixedPosSubPoolInformation(x.args[2],Temp.args[2],Temp.args[3],parsed_subpool)
        else
            error("Invalid syntax. Got $x.\nExpected @subpool name begin ... end or @subpool name at pos begin ... end")
        end
    elseif (x.args[1]) == Symbol("@abstract_subpool") # Last possibility, we are creating an abstract sub pool
        if x.args[3] == KEYWORDS[:position]
            if (x.args[4] isa Expr)
                Temp = x.args[4]
                @assert ((Temp.head == :call) && (Temp.args[1] == :(-))) "Invalid argument in @subpool declaration: $Temp"
                return FixedPosAbstractSubPoolInformation(x.args[2],Temp.args[2],Temp.args[3])
            else 
                return AbstractSubPoolInformation(x.args[2],x.args[4])
            end
        else
            error("Invalid syntax. Got $x.\nExpected @abstract_subpool name at pos.")
        end
    end
end

function parse_traits_first_step(traits)
    
    x = [parsed_trait_args(i) for i in traits.args]
    return x
end

# These set of functions are pretty straight forward.
# They fill the occupied vector in a pretty clear way
function fill_occupied!(i::FixedPosTraitInformation, occupied)
    if (occupied[i.pos])
        error("Cannot organize bits as requested.")
    end
    occupied[i.pos] = true
end

function fill_occupied!(i::FixedPosSubPoolInformation,occupied)
    if (any(occupied[i.start:i.finish]))
        error("Cannot organize bits as requested.")
    end
    occupied[i.start:i.finish] .= true
end

function fill_occupied!(i::FixedPosAbstractSubPoolInformation,occupied)
    if (any(occupied[i.start:i.finish]))
        error("Cannot organize bits as requested.")
    end
    occupied[i.start:i.finish] .= true
end

## This is in case we are searching a position for dynamic position trait
# Once a free position is found, we transform it into a fixed position trait
function occupy_slot!(i::TraitInformation, fixed_pos_pool, occupied)
    for pos in 1:length(occupied)
        if (!occupied[pos])
            occupied[pos] = true
            push!(fixed_pos_pool,FixedPosTraitInformation(i.name,pos))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

# The same logic apply on the other
function occupy_slot!(i::AbstractSubPoolInformation, fixed_pos_pool, occupied)
    for start in 1:length(occupied)-i.size+1
        finish = start+i.size-1
        if (!any(occupied[start:finish]))
            occupied[start:finish] .= true
            push!(fixed_pos_pool, FixedPosAbstractSubPoolInformation(i.name,start,finish))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

function occupy_slot!(i::SubPoolInformation, fixed_pos_pool, occupied)
    LENGTH = getsize(i)
    for start in 1:length(occupied)-LENGTH+1
        finish = start+LENGTH-1
        if (!any(occupied[start:finish]))
            occupied[start:finish] .= true
            push!(fixed_pos_pool, FixedPosSubPoolInformation(i.name,start,finish,i.args))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

"""
    organize_traits(traits, max_bit=64)

Organizes parsed traits and subpools into fixed-position form.
Returns a vector of `FixedPosPoolInformation`, with stable bit positions assigned.
"""
function organize_traits(parsed_pool::Vector{<:PoolInformation}, max_bit = 64)
    for i in parsed_pool
        if (i isa SubPoolInformation)
            i.args = organize_traits(i.args)
        elseif (i isa FixedPosSubPoolInformation)
            i.args = organize_traits(i.args,getsize(i))
        end
    end

    fixed_pos_pools::Vector{FixedPosPoolInformation} = [i for i in parsed_pool if is_fixed_pos(i)]
    dynamic_pos_pools::Vector{PoolInformation} = [i for i in parsed_pool if !is_fixed_pos(i)]
    occupied = falses(max_bit)
    for i in fixed_pos_pools
        fill_occupied!(i, occupied) 
    end
    for i in dynamic_pos_pools
        occupy_slot!(i,fixed_pos_pools,occupied)
    end

    return fixed_pos_pools
end

"""
    format_traits(organized_traits, start = 1, finish = 64)

This generate our final `PoolDescriptor` with a vector of `FixedPoolInformation`s.
For a :
- `FixedPosTraitInformation`: it just add a position for it in the descriptor
- `FixedPosSubPoolInformation`: it got formated as a new pool descriptor with some given trait
- `FixedPosAbstractSubPoolInformation`: It got formatted as an empty pool descripto with a given size
"""
function format_traits(organized_traits, start = 1, finish = 64)
    base_pool = PoolDescriptor(start,finish,Dict())
    for i in organized_traits
        if i isa FixedPosTraitInformation
            base_pool.args[i.name] = base_pool.start-1+i.pos
        elseif i isa FixedPosSubPoolInformation
            base_pool.args[i.name] = format_traits(i.args,i.start,i.finish)
        elseif i isa FixedPosAbstractSubPoolInformation
            base_pool.args[i.name] = PoolDescriptor(true,i.start,i.finish,Dict())
        else 
            error("Cannot format trait.")
        end
    end
    return base_pool
end

function parse_traits(traits)
    
    # Case 1: Just traits.
    # Case 2: Trait subpool.
    # Case 3: Traits with position
    # Case 4: Subpools with positions.
    remove_line_number_node!(traits)
    parsed_pool = parse_traits_first_step(traits)
    organized_traits = organize_traits(parsed_pool)
    formatted_traits = format_traits(organized_traits)
    return formatted_traits
end
